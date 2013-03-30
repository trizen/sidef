use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Sidef',
    license             => 'Artistic_2_0',
    dist_author         => q{Daniel Șuteu, Ioana Fălcușan},
    dist_version_from   => 'lib/Sidef.pm',
    release_status      => 'unstable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'parent' => 0,
    },
    add_to_cleanup     => [ 'Sidef-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
