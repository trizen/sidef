
use utf8;
use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(

    module_name        => 'Sidef',
    license            => 'artistic_2',
    dist_author        => [
                            q{Daniel Șuteu   (<trizen@protonmail.com>)},
                            q{Ioana Fălcușan (<ioanaflavia@gmail.com>)},
                          ],
    dist_version_from  => 'lib/Sidef.pm',
    dist_abstract      => 'The Sidef Programming Language',
    release_status     => 'stable',
    configure_requires => {
                           'Module::Build' => 0,
                          },
    build_requires => {
                       'Test::More' => 0,
                      },

    extra_manify_args => { utf8 => 1 },

    meta_merge => {
                   resources => {
                                 bugtracker => "https://github.com/trizen/sidef/issues",
                                 homepage   => "https://github.com/trizen/sidef",
                                 repository => "https://github.com/trizen/sidef",
                                },
                  },

    requires => {
                 'perl'                     => '5.18.0',
                 'utf8'                     => 0,
                 'parent'                   => 0,
                 'Memoize'                  => 0,
                 'Cwd'                      => 0,
                 'File::Spec'               => 0,
                 'File::Path'               => 0,
                 'File::Copy'               => 0,
                 'File::Basename'           => 0,
                 'List::Util'               => 1.33,
                 'Math::MPFR'               => 3.36,
                 'Math::MPC'                => 0,
                 'Math::GMPq'               => 0.45,
                 'Math::GMPz'               => 0.39,
                 'Socket'                   => 0,
                 'Fcntl'                    => 0,
                 'Encode'                   => 0,
                 'Scalar::Util'             => 0,
                 'Time::HiRes'              => 0,
                 'Getopt::Std'              => 0,
                 'Term::ReadLine'           => 0,
                 'Math::Prime::Util::GMP'   => 0.44,
                 'Algorithm::Combinatorics' => 0,
                 'Algorithm::Loops'         => 0,
                },

    recommends => {
                   'File::Find'           => 0,    # `sidef -c`
                   'Digest::MD5'          => 0,    # File.md5(), Str.md5()
                   'Digest::SHA'          => 0,    # File.sha*(), Str.sha*()
                   'MIME::Base64'         => 0,    # Str.encode_base64(), Str.decode_base64()
                   'Data::Dump'           => 0,    # `sidef -D`
                   'Data::Dump::Filtered' => 0,    # Block.ffork()
                   'Math::Prime::Util'    => 0.73, # used in some Number methods, if available
                  },

    add_to_cleanup     => ['Sidef-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
