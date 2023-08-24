#!/bin/bash

# Package Sidef as a binary executable
# Requires: App::Packer::PAR

/usr/bin/site_perl/pp --compile --execute --lib=../lib -M Sidef::Types::Bool::Bool -M Sidef -M Sidef::Parser -M Sidef::Optimizer -M Sidef::Object::Object -M Sidef::Types::Number::Number -M Sidef::Deparse::Perl -M Sidef::Types::Block::Block -M Memoize -M Sidef::Types::Number::Complex -M Sidef::Types::Number::Mod -M Sidef::Types::Number::Gauss -M Sidef::Types::Number::Quadratic -M Sidef::Types::Number::Quaternion -M Sidef::Types::Number::Polynomial -M Sidef::Types::Number::Fraction -M Sidef::Types::Array::Array -M Sidef::Types::Hash::Hash -M Sidef::Types::Perl::Perl -M Sidef::Sys::Sys -M Sidef::Math::Math -M Sidef::Types::String::String -M Sidef::Types::Range::RangeNumber -M Sidef::Types::Range::RangeString -M Sidef::Types::Glob::File -M Sidef::Types::Glob::Dir -M Sidef::Types::Glob::FileHandle -M Sidef::Types::Glob::DirHandle -M Sidef -M Sidef::Types::Regex::Regex -M Sidef::Types::Regex::Match -M Sidef::Module::Func -M Sidef::Module::OO -M Sidef::Sys::Sig -M Sidef::Time::Time -M Sidef::Time::Date -M Sidef::Object::LazyMethod -M Sidef::Variable::NamedParam -M Sidef::Variable::GetOpt -M Sidef::Object::Convert -M Sidef::Types::Null::Null -M Sidef::Types::Glob::Backtick -M Sidef::Types::Glob::Pipe -M Sidef::Types::Glob::Socket -M Sidef::Types::Glob::SocketHandle -M Sidef::Types::Glob::Stat -M Sidef::Types::Block::Fork -M Sidef::Types::Block::Try -M Sidef::Types::Array::Pair -M Sidef::Deparse::Sidef -M experimental -M base -M File::Spec::Unix -M File::Spec -M File::Temp -M File::Basename -M File::Compare -M Cwd -M Time::HiRes -M Scalar::Util -M Socket -M Encode -M Fcntl -M File::Find -M File::Copy -M File::Path -M utf8 -M List::Util -M Math::MPFR -M Math::GMPz -M Math::GMPq -M Math::MPC -M Sidef::Object::Lazy -M Sidef::Object::Enumerator -M charnames -M bytes -M Data::Dump -M Data::Dump::Filtered -M Sidef::Types::Range::Range -M Sidef::Types::Array::Matrix -M Sidef::Types::Array::Vector -M Math::Prime::Util::GMP -M Getopt::Long -M Digest::MD5 -M Digest::SHA -M Algorithm::Combinatorics -M Algorithm::Loops -M MIME::Base64 -M File::HomeDir -M IO -M Encode::Encoding -M Encode::Unicode -M Exporter -M Exporter::Heavy -M Config -M Encode::Alias -M Encode::MIME::Name -M File::Glob -M IO::Handle -M DynaLoader -M re -M POSIX -M SelectSaver -M SelfLoader -M Term::Cap -M Term::ReadKey -M Term::ReadLine -M Tie::Hash -M Tie::Hash::NamedCapture -M XSLoader -M Symbol -M Storable -M overload -M overloading -M parent -M Sidef::Types::Set::Set -M Sidef::Types::Set::Bag -M Data::Dump -M Carp -M base -M constant -M charnames -M _charnames -M integer -M unicore::Name -M vars -M warnings -M warnings::register -M subs -M DB_File -M Math::Prime::Util -M PerlIO::encoding -M PerlIO::scalar -M locale -M _charnames -M unicore::Name -M Time::Piece -M Config_git.pl -M Config_heavy.pl -M Encode::Config -M Exporter -M Exporter::Heavy -M File::Glob -M Math::GMPq::Random -M Math::GMPz::Random -M Math::MPFR::Prec -M Math::Prime::Util::MemFree -M Storable -M Tie::Hash -M Tie::Hash::NamedCapture -M base -M constant -M integer -M overload -M overloading -M strict -M warnings -M warnings::register -M Time::Local -M Getopt::Std -M Time::Seconds -M _charnames -M charnames -M unicore::Name -M Text::Balanced -M ntheory -M HTTP::Tiny -M JSON::PP -M IO::Compress::RawDeflate -M IO::Uncompress::RawInflate -M IO::Compress::Gzip -M IO::Uncompress::Gunzip -M Text::ParseWords -o sidef.out -z 0 -c ../bin/sidef
