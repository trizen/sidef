#!/usr/bin/perl

use utf8;
use 5.010;
use strict;
use autodie;
use warnings;

use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);

my $sidef = 'sidef';    # command or path to sidef

binmode(STDOUT, ':utf8');
print header(-charset => 'UTF-8'),
  start_html(
             -lang   => 'en',
             -title  => 'Sidef Programming Language',
             -author => 'trizenx@gmail.com',
             -base   => 'true',
             -meta   => {
                       'keywords'  => 'sidef programming language web interface',
                       'copyright' => 'Copyright © 2015 Daniel "Trizen" Șuteu'
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

if (param) {
    if (defined(my $code = param('code'))) {
        local (*CHLD_OUT, *CHLD_ERR);

        require IPC::Open3;
        my $pid = IPC::Open3::open3(undef, \*CHLD_OUT, \*CHLD_ERR, $sidef, '-E', $code);
        waitpid($pid, 0);

        my $stderr = do { local $/; <CHLD_ERR> };
        my $stdout = do { local $/; <CHLD_OUT> };

        chomp($stderr);
        chomp($stdout);

        if ($stderr ne "") {
            print pre($stderr);
            print hr;
        }

        print pre($stdout);
    }
}

print start_form(
                 -method => 'POST',
                 -action => 'index.cgi',
                ),
  textarea(
           -name    => 'code',
           -default => 'Write your code here...',
           -rows    => 10,
           -columns => 80,
           -onfocus => 'clearContents(this);',
          ),
  br, submit(-name => "Run!"), end_form;

print end_html;
