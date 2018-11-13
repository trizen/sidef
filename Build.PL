
use utf8;
use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

use File::Spec::Functions qw(catfile);
my $sidef_filename = catfile('bin', 'sidef');

if (open my $sidef_fh, '<:utf8', $sidef_filename) {

    my @sidef_bin;
    my @sidef_data;

    while(defined(my $line = <$sidef_fh>)) {

        chomp $line;
        push @sidef_bin, $line;

        if ($line eq '__DATA__') {
            chomp(@sidef_data = <$sidef_fh>);
            last;
        }
    }

    close $sidef_fh;

    if ((-d '.git') and (my $git_version_full = `git describe --always --tags`)) {

        my $git_branch = `git rev-parse --abbrev-ref HEAD`;
        my $dt = gmtime() . ' GMT';

        chomp $git_branch;
        chomp $git_version_full;

        @sidef_data = "$git_version_full\n[$git_branch]\n$dt";
    }

    if (open my $out_fh, '>:utf8', $sidef_filename) {
        print $out_fh join("\n", @sidef_bin, @sidef_data) . "\n";
        close $out_fh;
    }
}

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
                   'File::Find'           => 0,    # for: `sidef -c`
                   'Digest::MD5'          => 0,    # for: File.md5(), Str.md5()
                   'Digest::SHA'          => 0,    # for: File.sha*(), Str.sha*()
                   'MIME::Base64'         => 0,    # for: Str.encode_base64(), Str.decode_base64()
                   'Data::Dump'           => 0,    # for: `sidef -D`
                   'Data::Dump::Filtered' => 0,    # for: Block.ffork()
                  },

    add_to_cleanup     => ['Sidef-*'],
    create_makefile_pl => 'traditional',
);

$builder->script_files([$sidef_filename]);
$builder->create_build_script();
