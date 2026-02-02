package Test::MXCL;

use v5.42;
use Exporter 'import';

use IO::Scalar;
use MXCL::Machine;
use MXCL::Effect;
use MXCL::Effect::TTY;
use MXCL::Effect::REPL;
use MXCL::Effect::Require;
use MXCL::Capabilities;
use MXCL::Builtins;

our @EXPORT_OK = qw( eval_mxcl eval_ok eval_throws eval_with_output );
our @EXPORT = @EXPORT_OK;

# Evaluate MXCL source and return the result Term (or undef on error)
sub eval_mxcl ($source) {
    my $kont = MXCL::Machine->new->load($source)->run;
    return undef unless $kont->effect isa MXCL::Effect::Halt;
    my ($result) = $kont->stack->splice(0);
    return $result;
}

# Evaluate and return true if it completed successfully
sub eval_ok ($source) {
    my $kont = MXCL::Machine->new->load($source)->run;
    return $kont->effect isa MXCL::Effect::Halt;
}

# Evaluate and return true if it threw an error
sub eval_throws ($source) {
    try {
        my $kont = MXCL::Machine->new->load($source)->run;
        return $kont->effect isa MXCL::Effect::Error;
    } catch ($e) {
        return !!$e;
    }
}

# Evaluate MXCL source and capture TTY output
sub eval_with_output ($source) {
    my $output = '';
    my $output_fh = IO::Scalar->new(\$output);

    # Create custom TTY effect with captured output
    my $tty = MXCL::Effect::TTY->new(output => $output_fh);
    my $caps = MXCL::Capabilities->new(
        effects => [
            $tty,
            MXCL::Effect::REPL->new,
            MXCL::Effect::Require->new,
        ]
    );

    my $machine = MXCL::Machine->new(capabilities => $caps);
    my $kont = $machine->load($source)->run;

    return {
        kont   => $kont,
        output => $output,
        ok     => $kont->effect isa MXCL::Effect::Halt,
    };
}

1;
