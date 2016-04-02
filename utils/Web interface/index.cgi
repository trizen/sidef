#!/usr/bin/perl

# Run Sidef code inside the browser

use utf8;
use 5.018;
use strict;
use autodie;

use CGI qw(:standard -utf8);
use CGI::Carp qw(fatalsToBrowser);
use Capture::Tiny qw(capture);

# Path where Sidef exists (when not installed)
use lib qw(/home/swampyx/Other/Programare/Sidef/lib);

# Limit the size of Sidef scripts to 500KB
$CGI::POST_MAX = 1024 * 500;

use Sidef;

binmode(STDOUT, ':utf8');
print header(-charset => 'UTF-8'),
  start_html(
             -lang   => 'en',
             -title  => 'Sidef Programming Language',
             -author => 'trizenx@gmail.com',
             -base   => 'true',
             -meta   => {
                       'keywords'  => 'sidef programming language web interface',
                       'copyright' => 'Copyright © 2015-2016 Daniel "Trizen" Șuteu'
                      },
             -style  => [{-src => 'css/main.css'}],
             -script => [
                         {
                          -src => 'js/jquery-2.1.3.min.js',
                         },
                         {-src => 'js/jquery.autosize.min.js'},
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
                 -action          => 'index.cgi',
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

sub parse {
    my ($code) = @_;

    @Sidef::NAMESPACES = ();
    %Sidef::INCLUDED   = ();

    my $errors = '';

    local $SIG{__WARN__} = sub {
        $errors .= join("\n", @_);
    };

    local $SIG{__DIE__} = sub {
        $errors .= join("\n", @_);
    };

    my $parser = Sidef::Parser->new(file_name   => '-',
                                    script_name => '-',);

    my $struct = eval { $parser->parse_script(code => \$code) };

    ($struct, $errors);
}

sub execute {
    my ($struct) = @_;

    state $count = 0;

    my $environment_name = 'Sidef::Runtime' . CORE::abs(++$count);
    my $deparser = Sidef::Deparse::Perl->new(namespaces       => [@Sidef::NAMESPACES],
                                             environment_name => $environment_name,);

    my $errors = '';

    local $SIG{__WARN__} = sub {
        $errors .= join("\n", @_);
    };

    local $SIG{__DIE__} = sub {
        $errors .= join("\n", @_);
    };

    local $Sidef::DEPARSER = $deparser;
    my $code = "package $environment_name {" . $deparser->deparse($struct) . "}";

    my ($stdout, $stderr) = capture {
        alarm 5;
        eval($code);
        alarm(0);
    };

    ($stdout, $errors . $stderr);
}

if (param) {
    if (defined(my $code = param('code'))) {

        # Replace any newline characters with "\n"
        $code =~ s/\R/\n/g;

        my ($struct, $errors) = parse($code);

        if ($errors ne '') {
            chomp($errors);
            print pre($errors);
            print hr;
            $errors = '';
        }

        if (ref($struct) eq 'HASH') {
            my ($output, $errors) = execute($struct);

            if ($errors ne "") {
                chomp($errors);
                print pre($errors);
                print hr;
            }

            if (defined $output and $output ne '') {
                print pre($output);
            }
        }
    }
}

print end_html;
