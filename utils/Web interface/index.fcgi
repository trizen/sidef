#!/usr/bin/perl

# Run Sidef code inside the browser (using FastCGI)

use utf8;
use 5.018;
use strict;
#use autodie;

use CGI::Fast;
use CGI qw(:standard -utf8);
#use CGI::Carp qw(fatalsToBrowser);
use Capture::Tiny qw(capture);
use HTML::Entities qw(encode_entities);

# Path where Sidef exists (when not installed)
#use lib qw(/home/user/Sidef/lib);

# Limit the size of Sidef scripts to 500KB
$CGI::POST_MAX = 1024 * 500;

use Sidef;

binmode(STDOUT, ':utf8');

sub compile {
    my ($sidef, $code) = @_;

    my $errors = '';

    local $SIG{__WARN__} = sub {
        $errors .= join("\n", @_);
    };

    local $SIG{__DIE__} = sub {
        $errors .= join("\n", @_);
    };

    my $ccode = eval { $sidef->compile_code($code, 'Perl') };
    return ($ccode, $errors);
}

sub execute {
    my ($sidef, $ccode) = @_;

    my $errors = '';

    local $SIG{__WARN__} = sub {
        $errors .= join("\n", @_);
    };

    local $SIG{__DIE__} = sub {
        $errors .= join("\n", @_);
    };

    my ($stdout, $stderr) = capture {
        alarm 5;
        $sidef->execute_perl($ccode);
        alarm(0);
    };

    return ($stdout, $errors . $stderr);
}

while (my $c = CGI::Fast->new) {

    print header(
                 -charset                 => 'UTF-8',
                 'Referrer-Policy'        => 'no-referrer',
                 'X-Frame-Options'        => 'DENY',
                 'X-Xss-Protection'       => '1; mode=block',
                 'X-Content-Type-Options' => 'nosniff',
                ),
      start_html(
                 -lang  => 'en',
                 -title => 'Sidef Programming Language',
                 -base  => 'true',
                 -meta  => {
                           'keywords' => 'sidef programming language web interface',
                           'viewport' => 'width=device-width, initial-scale=1.0',
                          },
                 -style  => [{-src => 'css/main.css'}],
                 -script => [
                             {
                              -src => 'js/jquery-3.6.0.min.js',
                             },
                             {
                              -src => 'js/tabby.js',
                             },
                             {
                              -src => 'js/main.js',
                             },
                            ],
                );

    print h1("Sidef");

    print start_form(
                     -method          => 'POST',
                     -action          => $ENV{SCRIPT_NAME},
                     'accept-charset' => "UTF-8",
                    ),
      textarea(
               -name    => 'code',
               -default => 'Write your code here...',
               -rows    => 10,
               -columns => 80,
               -onfocus => 'clearContents(this);',
              ),
      br, submit(-name => "Run!"), end_form;

    if (defined(my $code = $c->param('code'))) {

        # Replace any newline characters with "\n"
        $code =~ s/\R/\n/g;

        my $sidef = Sidef->new(name => '-');
        my ($ccode, $errors) = compile($sidef, $code);

        if ($errors ne '') {
            chomp($errors);
            print pre(encode_entities($errors));
            print hr;
            $errors = '';
        }

        if (defined($ccode)) {
            my ($output, $errors) = execute($sidef, $ccode);

            if ($errors ne "") {
                chomp($errors);
                print pre(encode_entities($errors));
                print hr;
            }

            if (defined $output and $output ne '') {
                print pre(encode_entities($output));
            }
        }
    }

    print end_html;
}
