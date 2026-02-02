
use v5.42;
use experimental qw[ class ];

use MXCL::Strand;
use MXCL::Capabilities;

use Time::HiRes ();

class MXCL::Machine {
    field $capabilities :reader :param = undef;

    # strands ...
    field %strands; # PID to strand mapping
    field @ready;   # ready queue

    # Timers ...
    field $time;     # last checked time
    field @timers;   # pending timers

    # Watchers
    field %watchers;

    our $TIMER_SEQ = 0;
    our $PID_SEQ   = -1;
    our $INIT_PID  = MXCL::Term::PID->CREATE($PID_SEQ++, undef);

    ADJUST {
        $capabilities //= MXCL::Capabilities->new;
    }

    # ...

    # --------------------------------------------------------------------------
    # Process management, it's fairly simple and probably needs a lot added
    # to it to make it robust. But this works for now.
    # --------------------------------------------------------------------------

    method next_pid ($parent = undef) {
        MXCL::Term::PID->CREATE(
            ++$PID_SEQ,
            $parent // $INIT_PID
        )
    }

    # ... initializing seed machine

    method initialize_environment {
        my $pid = $self->next_pid;
        my $env = $capabilities->new_environment;
        $env->define('$PID', $pid);
        $env->define('$PPID', $INIT_PID);
        return ($env, $pid);
    }

    method initialize_strand ($source) {
        my ($env, $pid) = $self->initialize_environment;

        my $program = $capabilities->compile($source, $env);
        my $strand = MXCL::Strand->new(
            program  => $program,
            env      => $env,
            on_exit  => MXCL::Term::Kontinue::Host->new(
                effect => MXCL::Effect::Halt->new,
                env => $env
            ),
            on_error => MXCL::Term::Kontinue::Host->new(
                effect => MXCL::Effect::Error->new,
                env => $env
            ),
        );

        $strands{ $pid->value } = $strand;
        push @ready => [ $pid, $strand ];

        return ($env, $pid);
    }

    # ... forking strands

    method fork_environment ($ppid, $env) {
        my $pid    = $self->next_pid( $ppid );
        my $forked = $env->derive(
            '$PID'  => $pid,
            '$PPID' => $ppid,
        );
        return ($forked, $pid);
    }

    method fork_strand ($pid, $expr, $env) {
        my ($forked, $new_pid) = $self->fork_environment( $pid, $env );

        my $strand = MXCL::Strand->new(
            env      => $forked,
            program  => [
                MXCL::Term::Kontinue::Eval::Expr->new(
                    expr => $expr,
                    env  => $forked,
                )
            ],
            # ------------------------------------------
            # HMMMM
            # ------------------------------------------
            # These should actually return to the parent
            # process, and trigger anyone waiting on the
            # pid. Hmm ... need to ponder this.
            # ------------------------------------------
            on_exit  => MXCL::Term::Kontinue::Host->new(
                effect => MXCL::Effect::Halt->new,
                env => $forked
            ),
            on_error => MXCL::Term::Kontinue::Host->new(
                effect => MXCL::Effect::Error->new,
                env => $forked
            ),
        );

        $strands{ $new_pid->value } = $strand;
        push @ready => [ $new_pid, $strand ];

        return ($forked, $new_pid);
    }

    # --------------------------------------------------------------------------
    # NOTE: the load->run pattern is kinda ick, it needs
    # some work, especially since we no longer have just
    # one strand. But this is all a WIP, so I will let it
    # shake out as it goes.
    # --------------------------------------------------------------------------

    method load ($source) {
        $self->initialize_strand( $source );
        $self;
    }

    method run {
        # Install cleanup signal handlers
        local $SIG{INT} = sub {
            $ENV{STRAND_DEBUG} && say "SIGINT received, cleaning up...";
            $capabilities->cleanup;
            exit(130);  # Standard exit code for SIGINT
        };
        local $SIG{QUIT} = sub {
            $ENV{STRAND_DEBUG} && say "SIGQUIT received, cleaning up...";
            $capabilities->cleanup;
            exit(131);  # Standard exit code for SIGQUIT
        };
        local $SIG{TERM} = sub {
            $ENV{STRAND_DEBUG} && say "SIGTERM received, cleaning up...";
            $capabilities->cleanup;
            exit(143);  # Standard exit code for SIGTERM
        };

        my @results;
        my $error;

        eval {
            $ENV{STRAND_DEBUG} && say "BEGIN";
            while (@ready || @timers) {
                my ($pid, $m) = @{ shift @ready };
                $ENV{STRAND_DEBUG} && say "RUN ${pid} START";
                my $host = $m->run_until_host;
                $ENV{STRAND_DEBUG} && say "RUN ${pid} GOT ", $host->pprint;
                if (defined( my $kont = $host->effect->handles( $host, $self, $pid ) )) {
                    $ENV{STRAND_DEBUG} && say "RUN ${pid} NEXT ", join "\n" => map $_->pprint, @$kont;
                    push @ready => [ $pid, $m->prepare(@$kont) ];
                } else {
                    $ENV{STRAND_DEBUG} && say "RUN ${pid} HALT!";
                    if ($host->effect isa MXCL::Effect::Halt) {
                        if (exists $watchers{ $pid->value }) {
                            my $watchers = delete $watchers{ $pid->value };
                            foreach my $watcher (@$watchers) {
                                push @ready => [ $watcher, $strands{ $watcher->value } ];
                            }
                        }
                    }
                    push @results => $host;
                }

                # don't wait if we have work to do
                unless (@ready) {
                    $ENV{STRAND_DEBUG} && say "...NO PENDING WORK, CHECK WAIT!";
                    my $wait_duration = $self->should_wait;
                    if ($wait_duration > 0) {
                        $ENV{STRAND_DEBUG} && say "[TIMER] Waiting ${wait_duration}s for next timer";
                        $self->wait($wait_duration);
                        $ENV{STRAND_DEBUG} && say "[TIMER] done waiting"
                    } else {
                        $ENV{STRAND_DEBUG} && say "[TIMER] to short to wait ... "
                    }
                }

                # process timers
                my @to_run = $self->get_pending_timers;
                $ENV{STRAND_DEBUG} && say ">> GOT TIMERS TO RUN: ", scalar @to_run;
                foreach my $timer (@to_run) {
                    #say join ', ' => @$timer;
                    my $pid = $timer->[ 2 ];
                    my $_m  = $strands{ $pid->value };
                    push @ready => [ $pid, $_m ];
                }

                $ENV{STRAND_DEBUG} && say ">> GOT WORK TO BE DONE: ", scalar @ready;
            }
        };

        $error = $@;

        # Always cleanup effects, even on error
        $ENV{STRAND_DEBUG} && say "Cleaning up effects...";
        $capabilities->cleanup;

        # Re-throw error after cleanup
        die $error if $error;

        # FIXME: this is totally wrong
        # but too many bits to change
        # for now, so meh, I will get
        # a round to it.
        return $results[-1];
    }

    method schedule_watcher ( $to_watch, $to_notify ) {
        push @{ $watchers{ $to_watch->value } //= [] } => $to_notify;
    }

    # --------------------------------------------------------------------------
    # FIXME:
    # I copied the below scheduler functions from an older project, and they
    # pretty much work, but they really should be a seperate module, and not
    # in the core Strand namespace.
    # --------------------------------------------------------------------------

    use constant TIMER_PRECISION_DECIMAL => 0.001;
    use constant TIMER_PRECISION_INT     => 1000;

    method now {
        state $MONOTONIC = Time::HiRes::CLOCK_MONOTONIC();
        $time = Time::HiRes::clock_gettime($MONOTONIC);
        return $time;
    }

    method wait ($duration) {
        Time::HiRes::sleep($duration) if $duration > 0;
    }

    method _calculate_end_time ($delay_ms) {
        my $now      = $self->now;
        my $end_time = $now + ($delay_ms / 1000.0);  # Convert ms to seconds
        # Round to millisecond precision
        $end_time = int($end_time * TIMER_PRECISION_INT) * TIMER_PRECISION_DECIMAL;
        return $end_time;
    }

    method schedule_alarm ($pid, $ms) {
        my $timer_id = ++$TIMER_SEQ;
        my $end_time = $self->_calculate_end_time($ms < 1 ? 1 : $ms);

        my $timer = [$end_time, $timer_id, $pid, 0];  # [end_time, id, pid, cancelled]

        if (@timers == 0) {
            # Fast path: first timer
            push @timers, $timer;
        }
        elsif ($timers[-1][0] == $end_time) {
            # Same time as last timer - append
            push @timers, $timer;
        }
        elsif ($timers[-1][0] < $end_time) {
            # Fast path: append to end (common case)
            push @timers, $timer;
        }
        elsif ($timers[-1][0] > $end_time) {
            # Need to sort - insert in correct position
            @timers = sort { $a->[0] <=> $b->[0] } @timers, $timer;
        }

        return $timer_id;
    }

    # Cancel scheduled callback
    method cancel_scheduled ($timer_id) {
        # Mark as cancelled (lazy deletion)
        for my $timer (@timers) {
            if ($timer->[1] == $timer_id) {
                $timer->[-1] = 1;  # Set cancelled flag
                return 1;
            }
        }
        return 0;
    }

    # Get next timer, cleaning up cancelled ones
    method _get_next_timer {
        while (my $next_timer = $timers[0]) {
            # If we have timers
            if (@{$next_timer}) {
                # Check if all are cancelled
                my @active = grep { !$_->[-1] } @timers;
                if (@active == 0) {
                    # All cancelled, clear and continue
                    shift @timers;
                    next;
                }
                else {
                    last;
                }
            }
            else {
                shift @timers;
            }
        }

        return $timers[0];
    }

    # Calculate how long to wait for next timer
    method should_wait {
        my $wait = 0;

        if (my $next_timer = $self->_get_next_timer) {
            $wait = $next_timer->[0] - $time;
        }

        # Do not wait for negative values
        if ($wait < TIMER_PRECISION_DECIMAL) {
            $wait = 0;
        }

        return $wait;
    }

    method get_pending_timers {
        return unless @timers;

        my $now = $self->now;

        my @timers_to_run;
        while (@timers && $timers[0][0] <= $now) {
            push @timers_to_run, shift @timers;
        }

        return grep { !$_->[-1] } @timers_to_run;
    }
}

