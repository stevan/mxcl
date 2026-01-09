

use v5.42;
use experimental qw[ class ];

use importer 'Carp' => qw[ confess ];

use IO::Scalar;

use Opal::Term;
use Opal::Term::Parser;

class Opal::Tokenizer {
    field $source :param :reader;

    method tokenize {
        my @tokens;
        my $line_no = 0;
        my $line_at = 0;
        my $char_at = 0;
        while ($source =~ m/(\'|\%\{|\{|\}|\@\[|\[|\]|\(|\)|\;|"(?:[^"\\]|\\.)*"|\s|[^\s\(\)\'\;\{\}\[\]]+)/g) {
            my $match = $1;
            if ($match eq "\n") {
                $line_no++;
                $char_at = $line_at = pos($source);
            }
            elsif ($match eq " ") {
                $char_at = pos($source);
            }
            else {
                my $start = $char_at - $line_at;
                $char_at = pos($source);

                push @tokens => Opal::Term::Parser::Token->new(
                    value    => $match,
                    location => Opal::Term::Parser::Location->new(
                        start => $start,
                        end   => $char_at - $line_at,
                        line  => $line_no,
                        pos   => pos($source)
                    )
                );
            }
        }
        return @tokens;
    }
}
