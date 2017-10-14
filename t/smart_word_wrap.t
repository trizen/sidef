#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use Sidef;

my $code = <<'EOT';

class SmartWordWrap {

    has width = 80

    method prepare_words(array, depth=0, callback) {

        var root = []
        var len = 0

        for (var(i, limit) = (0, array.end); i <= limit; ++i) {
            len += (var word_len = array[i].len)

            if (len > width) {
                if (word_len > width) {
                    len -= word_len
                    array.splice(i, 1, array[i].split(width)...)
                    limit = array.end
                    --i; next
                }
                break
            }

            root << [
                array.first(i+1).join(' '),
                self.prepare_words(array.ft(i+1), depth+1, callback)
            ]

            if (depth.is_zero) {
                callback(root[0])
                root = []
            }

            break if (++len >= width)
        }

        root
    }

    method combine(root, path, callback) {
        var key = path.shift
        path.each { |value|
            root << key
            if (value.is_empty) {
                callback(root)
            }
            else {
                value.each { |item|
                    self.combine(root, item, callback)
                }
            }
            root.pop
        }
    }

    method smart_wrap(text, width) {

        self.width = width
        var words = (text.kind_of(Array) ? text : text.words)

        var best = Hash(
            score => Inf,
            value => [],
        )

        self.prepare_words(words, callback: { |path|
            self.combine([], path, { |combination|
                var score = 0
                combination.ft(0, -2).each { |line|
                    score += (width - line.len -> sqr)
                }

                if (score < best{:score}) {
                    best{:score} = score
                    best{:value} = []+combination
                }
            })
        })

        best{:value}.join("\n")
    }
}

EOT

my $sidef = Sidef->new(name => 'smart_word_wrap');
my $class = $sidef->execute_code($code);

my $sww   = $class->call;
my $text  = Sidef::Types::String::String->new('Lorem ipsum dolor sit amet, consectetur adipiscing elit.');
my $width = Sidef::Types::Number::Number->new(20);

my $wrapped = $sww->smart_wrap($text, $width);

my $expected = 'Lorem ipsum
dolor sit amet,
consectetur
adipiscing elit.';

is("$wrapped", $expected);
