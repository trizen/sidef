# Note: this file was auto-generated by Module::Build::Compat version 0.4234
require 5.018000;
use ExtUtils::MakeMaker;
WriteMakefile
(
  'NAME' => 'Sidef',
  'VERSION_FROM' => 'lib/Sidef.pm',
  'PREREQ_PM' => {
                   'Algorithm::Combinatorics' => 0,
                   'Algorithm::Loops' => 0,
                   'Cwd' => 0,
                   'Data::Dump' => 0,
                   'Data::Dump::Filtered' => 0,
                   'Encode' => 0,
                   'Fcntl' => 0,
                   'File::Basename' => 0,
                   'File::Copy' => 0,
                   'File::Path' => 0,
                   'File::Spec' => 0,
                   'Getopt::Std' => 0,
                   'List::Util' => '1.45',
                   'Math::GMPq' => '0.45',
                   'Math::GMPz' => '0.48',
                   'Math::MPC' => 0,
                   'Math::MPFR' => '3.36',
                   'Math::Prime::Util::GMP' => '0.52',
                   'Memoize' => 0,
                   'Scalar::Util' => 0,
                   'Socket' => 0,
                   'Term::ReadLine' => 0,
                   'Test::More' => 0,
                   'Time::HiRes' => 0,
                   'Time::Piece' => 0,
                   'parent' => 0,
                   'utf8' => 0
                 },
  'INSTALLDIRS' => 'site',
  'EXE_FILES' => [
                   'bin/sidef'
                 ],
  'PL_FILES' => {}
)
;
