
use v5.42;
use experimental qw[ class ];

use importer 'Carp' => qw[ confess ];

class Opal::Parser::Tools::CharBuffer {
    use constant MAX_BUFFER_SIZE => 512;

    field $handle :param;
    field $size   :param = MAX_BUFFER_SIZE;
    field $buffer = '';
    field $done   = 1; # we are done, when this is undef

    ADJUST {
        $handle isa IO::Handle || confess 'The `$handle` must be an IO::Handle';
    }

    method current_position { $handle->tell - length $buffer }

    method is_done { not defined $done } # when done is undef, we are done

    method get {
        $done // return;
        $buffer ne ''
            ? substr( $buffer, 0, 1, '' )
            : $handle->read( $buffer, $size )
                ? substr( $buffer, 0, 1, '' )
                : undef $done;
    }

    method peek {
        $done // return;
        $buffer ne ''
            ? substr( $buffer, 0, 1 )
            : $handle->read( $buffer, $size )
                ? substr( $buffer, 0, 1 )
                : undef $done;
    }

    method skip ($n=1) {

        $done // return;

        my $len = length $buffer;
        if ( $n == $len ) {
            $buffer = '';
        }
        elsif ( $n < $len ) {
            substr( $buffer, 0, $n, '' )
        }
        elsif ( $n > $len ) {
            $buffer = '';
            $handle->read( my $x, ($n - $len) );
        }
    }

    method discard_whitespace_and_peek {
        $done // return;

        do {
            if ( length $buffer == 0 ) {
                $handle->read( $buffer, $size )
                    or undef $done;
            }
        } while ( $buffer =~ s/^\s+// );

        return defined $done ? substr( $buffer, 0, 1 ) : undef;
    }

}

