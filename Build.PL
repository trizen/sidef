#!/usr/bin/env perl
use utf8;
use 5.006;
use strict;
use warnings;
use Module::Build;

# Sidef Programming Language - Build Configuration

my $class = Module::Build->subclass(
    class => 'Sidef::Builder',
    code  => q{
        sub ACTION_test {
            my $self = shift;
            $self->SUPER::ACTION_test(@_);
            $self->notes('test_results' => 'passed');
        }

        sub ACTION_authortest {
            my $self = shift;
            local $ENV{AUTHOR_TESTING} = 1;
            $self->depends_on('test');
        }
    },
);

my $builder = $class->new(

    # Core Module Information
    module_name       => 'Sidef',
    dist_version_from => 'lib/Sidef.pm',
    dist_abstract     => 'The Sidef Programming Language - A modern, high-level programming language',
    license           => 'artistic_2',
    release_status    => 'stable',

    # Author Information
    dist_author => [
        'Daniel Șuteu <trizen@cpan.org>',
        'Ioana Fălcușan <ioanaflavia@gmail.com>',
    ],

    # Build Configuration
    configure_requires => {
                           'Module::Build' => '0.4224',
                          },

    build_requires => {
                       'Test::More' => '1.0',
                      },

    test_requires => {
                      'Test::More'      => '1.0',
                     },

    # Runtime Dependencies - Core Perl Modules
    requires => {
        'perl'           => '5.018000',
        'utf8'           => 0,
        'strict'         => 0,
        'warnings'       => 0,
        'parent'         => 0,
        'Memoize'        => 0,
        'Cwd'            => 0,
        'File::Spec'     => 0,
        'File::Path'     => '2.09',
        'File::Copy'     => 0,
        'File::Basename' => 0,
        'List::Util'     => '1.45',
        'Scalar::Util'   => '1.45',
        'Socket'         => 0,
        'Fcntl'          => 0,
        'Encode'         => 0,
        'Time::Piece'    => 0,
        'Time::HiRes'    => 0,
        'Getopt::Std'    => 0,
        'Term::ReadLine' => 0,

        # Math Libraries (Required)
        'Math::MPFR'             => '3.36',
        'Math::MPC'              => '1.09',
        'Math::GMPq'             => '0.45',
        'Math::GMPz'             => '0.48',
        'Math::Prime::Util::GMP' => '0.52',

        # Algorithm Libraries (Required)
        'Algorithm::Combinatorics' => '0.27',
        'Algorithm::Loops'         => '1.032',

        # Data Handling (Required)
        'Data::Dump'           => '1.00',
        'Data::Dump::Filtered' => '0',
                },

    # Optional but Recommended Dependencies
    recommends => {

        # Enhanced Threading Support
        'forks' => '0.36',

        # File Operations
        'File::Find' => 0,

        # Cryptographic Functions
        'Digest::MD5' => '2.0',
        'Digest::SHA' => '5.0',

        # Encoding/Decoding
        'MIME::Base64' => '3.00',

        # Enhanced Math Support
        'Math::Prime::Util' => '0.73',

        # Terminal Enhancement
        'Term::ReadLine::Gnu' => '1.36',

        # Text Processing
        'Text::Balanced'   => '2.00',
        'Text::ParseWords' => '3.00',
                  },

    # Metadata and Resources
    meta_merge => {
        'meta-spec' => {
                        version => 2,
                        url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
                       },

        dynamic_config => 0,

        resources => {
                      homepage   => 'https://github.com/trizen/sidef',
                      repository => {
                                     type => 'git',
                                     url  => 'https://github.com/trizen/sidef.git',
                                     web  => 'https://github.com/trizen/sidef',
                                    },
                      bugtracker => {
                                     web => 'https://github.com/trizen/sidef/issues',
                                    },
                     },

        keywords => ['sidef', 'programming language', 'scripting', 'interpreter', 'dynamic language', 'high-level language',],

        prereqs => {
                    runtime => {
                                suggests => {
                                             'JSON::PP'           => 0,
                                             'LWP::UserAgent'     => 0,
                                             'HTTP::Tiny'         => 0,
                                             'DBD::SQLite'        => 0,
                                             'DBI'                => 0,
                                             'Regexp::Common'     => 0,
                                             'DateTime'           => 0,
                                             'File::Slurp'        => 0,
                                             'IO::Compress::Gzip' => 0,
                                            },
                               },
                   },

        no_index => {
                     directory => [qw(t inc examples share)],
                     file      => [qw(README.md)],
                    },

        x_contributors => [
            'Daniel Șuteu <trizen@cpan.org>',
            'Ioana Fălcușan <ioanaflavia@gmail.com>',
        ],

        x_authority => 'cpan:TRIZEN',
    },

    # Additional Configuration
    sign               => 1,
    dynamic_config     => 0,
    extra_manify_args  => {utf8 => 1},
    add_to_cleanup     => ['Sidef-*', '_build', 'Build', 'MYMETA.*'],
    create_makefile_pl => 'traditional',

    # Script Installation
    script_files => ['bin/sidef'],
);

# Platform-specific checks
if ($^O eq 'MSWin32') {
    print STDERR "\nWarning: Some features may have limited support on Windows.\n";
    print STDERR "Consider using WSL (Windows Subsystem for Linux) for the best experience.\n\n";
}

# Verify critical dependencies are installable
eval {
    require Math::MPFR;
    require Math::GMPz;
    require Math::GMPq;
    1;
} or do {
    print STDERR "\n" . ("=" x 70) . "\n";
    print STDERR "IMPORTANT: Sidef requires GMP, MPFR, and MPC libraries.\n";
    print STDERR "\nOn Debian/Ubuntu, install with:\n";
    print STDERR "  sudo apt-get install libgmp-dev libmpfr-dev libmpc-dev\n";
    print STDERR "\nOn Red Hat/Fedora/CentOS, install with:\n";
    print STDERR "  sudo yum install gmp-devel mpfr-devel libmpc-devel\n";
    print STDERR "\nOn macOS with Homebrew, install with:\n";
    print STDERR "  brew install gmp mpfr libmpc\n";
    print STDERR "=" x 70 . "\n\n";
};

$builder->create_build_script();

print "\nBuild.PL completed successfully.\n";
print "Run './Build' to build, './Build test' to test, and './Build install' to install.\n\n";

__END__

=encoding utf8

=head1 NAME

Build.PL - Build script for the Sidef Programming Language

=head1 DESCRIPTION

This is the build script for Sidef, a modern, high-level programming language.
It uses Module::Build to handle the installation process.

=head1 SYSTEM REQUIREMENTS

=over 4

=item * Perl 5.18.0 or higher

=item * GMP library (for Math::GMPz and Math::GMPq)

=item * MPFR library (for Math::MPFR)

=item * MPC library (for Math::MPC)

=back

=head1 INSTALLATION

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=head1 AUTHORS

Daniel Șuteu <trizen@cpan.org>

Ioana Fălcușan <ioanaflavia@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.

=cut
