use utf8;
use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(

    module_name => 'Sidef',
    license     => 'Artistic_2_0',
    dist_author => q{
                     Daniel Șuteu   (trizenx@gmail.com)
                     Ioana Fălcușan (ioanaflavia@gmail.com)
                    },

    dist_version_from  => 'lib/Sidef.pm',
    dist_abstract      => 'Sidef Programming Language',
    release_status     => 'unstable',
    configure_requires => {
                           'Module::Build' => 0,
                          },
    build_requires => {
                       'Test::More' => 0,
                      },

    requires => {
                 'perl'           => 5.014,
                 'utf8'           => 0,
                 'Cwd'            => 0,
                 'File::Spec'     => 0,
                 'File::Path'     => 0,
                 'File::Copy'     => 0,
                 'File::Basename' => 0,
                 'List::Util'     => 0,
                 'Math::BigInt'   => 0,
                 'Math::BigFloat' => 0,
                 'Fcntl'          => 0,
                 'Encode'         => 0,
                 'POSIX'          => 0,
                 'Time::HiRes'    => 0,
                 'Getopt::Std'    => 0,
                 'Term::ReadLine' => 0,
                },

    recommends => {
                   'Math::BigInt::GMP'       => 0,
                   'Term::ReadLine::Gnu::XS' => 0,
                  },

    auto_features => {
                      dump_support => {
                                       description => "Dump the structure of the parsed source code.",
                                       requires    => {
                                                    'Data::Dump' => 0,
                                                   },
                                      },
                     },

    add_to_cleanup     => ['Sidef-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
