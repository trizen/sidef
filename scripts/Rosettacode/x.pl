#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use File::Find qw(find);
use File::Spec::Functions qw(catfile splitdir);

my %interactive;
@interactive{qw(
    24_game.md
    24_game_Solve.md
    A_B.md
    Bulls_and_cows.md
    Bulls_and_cows_Player.md
    Conway's_Game_of_Life.md
)} = ();

find {
    wanted => sub {
        -f or return;

        my @path = splitdir($_);

        if ($path[-1] eq 'README.md') {
            return;
        }

        my $name;
        if (length($path[-2]) != 1) {
            $name = $path[-2] . '_' . $path[-1];
        }
        else {
            $name = $path[-1];
        }

        if (exists $interactive{$name}) {
            my $dir = 'Interactive';
            if (not -d $dir) {
                mkdir $dir;
            }
            $name = catfile($dir, $name);
        }

        my $content = do {
            open my $fh, '<:utf8', $_;
            local $/;
            <$fh>;
        };

        my ($url) = $content =~ /^\[\d+\]: (.+)/;

        my $files = 1;
        while ($content =~ /^```ruby\h*\n(.*?)\n```$/gms) {
            my $code = $1;

            my $sf_name = $name =~ s/\.md\z/\.sf/ir;

            if (-e $sf_name) {
                $sf_name = $sf_name = $name =~ s/\.md\z/_$files\.sf/ir;
                ++$files;
            }

            open my $fh, '>:utf8', $sf_name;
            print {$fh} "#!/usr/bin/ruby\n\n" .
                "#\n## $url\n#\n\n" .
            $code . "\n";
            close $fh;
        }
    },
    no_chdir => 1,
} => @ARGV;


__END__

Math.pi.say;
Math.pi say;
say Math.pi;
say pi Math;

#say Sys;
#say("x");

__END__
 class Example {
    method say {
        CORE::say "hi";
    }
};

say Example.new;

 #       Example == "test" -> say;      # false
 #       Example == Example -> say ;     # true
#

__END__
var say = 42;

"a" say;
say say;


#say "hi";

#int(23);
#say match(/^t/,"test");
