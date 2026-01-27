
use v5.42;
use experimental qw[ class ];

use MXCL::Compiler;
use MXCL::Machine;
use MXCL::Capabilities;

use MXCL::Effect;
use MXCL::Effect::TTY;
use MXCL::Effect::REPL;
use MXCL::Effect::Require;
use MXCL::Effect::Fork;

class MXCL::Strand {
    field $capabilities :reader :param = undef;
    field $compiler     :reader;

    field %machines; # PID to machine mapping
    field @ready;    # ready queue

    our $PID_SEQ = 0;

    ADJUST {
        $compiler = MXCL::Compiler->new;

        $capabilities //= MXCL::Capabilities->new(
            effects => [
                MXCL::Effect::TTY->new,
                MXCL::Effect::REPL->new,
                MXCL::Effect::Require->new,
                MXCL::Effect::Fork->new,
            ]
        );
    }

    # ...

    method compile_program ($source, $env) {
        $compiler->compile($source, $env)
    }

    method create_exit_kont ($env) {
        return MXCL::Term::Kontinue::Host->new(
            effect => MXCL::Effect::Halt->new,
            env => $env
        )
    }

    method create_error_kont ($env) {
        return MXCL::Term::Kontinue::Host->new(
            effect => MXCL::Effect::Error->new,
            env => $env
        )
    }

    # ...

    method next_pid { MXCL::Term::Num->CREATE( ++$PID_SEQ ) }

    method create_new_environment {
        my $pid = $self->next_pid;
        my $env = $capabilities->new_environment;
        $env->define( MXCL::Term::Sym->CREATE('$PID'), $pid );
        return ($env, $pid);
    }

    method fork_environment ($env) {
        my $pid    = $self->next_pid;
        my $forked = $env->derive( '$PID', $pid, '$PPID', $env->get('$PID') );
        return ($forked, $pid);
    }

    # ...

    method initialize_machine ($source) {
        my ($env, $pid) = $self->create_new_environment;

        my $program = $self->compile_program( $source, $env );
        my $machine = MXCL::Machine->new(
            program  => $program,
            env      => $env,
            on_exit  => $self->create_exit_kont( $env ),
            on_error => $self->create_error_kont( $env ),
        );

        $machines{ $pid->value } = $machine;
        push @ready => $machine;

        return $pid;
    }

    method fork_machine ($expr, $env) {
        my ($forked, $pid) = $self->fork_environment( $env );

        my $machine = MXCL::Machine->new(
            env      => $forked,
            on_exit  => $self->create_exit_kont( $forked ),
            on_error => $self->create_error_kont( $forked ),
            program  => [
                MXCL::Term::Kontinue::Eval::Expr->new(
                    expr => $expr,
                    env  => $forked,
                )
            ],
        );

        $machines{ $pid->value } = $machine;
        push @ready => $machine;

        return $pid;
    }

    # ...

    # NOTE: the load->run pattern is kinda ick, it needs
    # some work, especially since we no longer have just
    # one machine. But this is all a WIP, so I will let it
    # shake out as it goes.

    method load ($source) {
        $self->initialize_machine( $source );
        $self;
    }

    method run {
        my @results;
        while (@ready) {
            my $m = shift @ready;
            my $host = $m->run_until_host;
            if (defined( my $kont = $host->effect->handles( $host, $self ) )) {
                push @ready => $m->prepare(@$kont);
            } else {
                push @results => $host;
            }
        }

        # FIXME: this is totally wrong
        # but too many bits to change
        # for now, so meh, I will get
        # a round to it.
        return $results[0];
    }
}

