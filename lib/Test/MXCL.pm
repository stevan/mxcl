package Test::MXCL;

use v5.42;
use Exporter 'import';

use MXCL::Strand;
use MXCL::Effect;

our @EXPORT_OK = qw( eval_mxcl eval_ok eval_throws );
our @EXPORT = @EXPORT_OK;

# Evaluate MXCL source and return the result Term (or undef on error)
sub eval_mxcl ($source) {
    my $kont = MXCL::Strand->new->load($source)->run;
    return undef unless $kont->effect isa MXCL::Effect::Halt;
    my ($result) = $kont->stack->splice(0);
    return $result;
}

# Evaluate and return true if it completed successfully
sub eval_ok ($source) {
    my $kont = MXCL::Strand->new->load($source)->run;
    return $kont->effect isa MXCL::Effect::Halt;
}

# Evaluate and return true if it threw an error
sub eval_throws ($source) {
    try {
        my $kont = MXCL::Strand->new->load($source)->run;
        return $kont->effect isa MXCL::Effect::Error;
    } catch ($e) {
        return !!$e;
    }
}

1;
