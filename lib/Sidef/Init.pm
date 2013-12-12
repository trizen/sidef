package Sidef::Init;

# This module is used to require all the project modules at once.

# Generated by:
# find . | perl -nE 'chomp; if(s/\.pm\z//){s{^\./}{};s{/}{::}g; next if $_ ~~ ["Variable::Class", "Init", "Types::Regex::Matches", qr/^Types::Number::Number(?:Fast|Int|Rat)\z/]; say "require Sidef::$_ if (caller)[0] ne q{Sidef::$_};"}'

use 5.014;
use strict;
use warnings;

require Sidef::Sys::SIG if (caller)[0] ne q{Sidef::Sys::SIG};
require Sidef::Sys::Sys if (caller)[0] ne q{Sidef::Sys::Sys};
require Sidef::Args::Args if (caller)[0] ne q{Sidef::Args::Args};
require Sidef::Math::Math if (caller)[0] ne q{Sidef::Math::Math};
require Sidef::Time::Localtime if (caller)[0] ne q{Sidef::Time::Localtime};
require Sidef::Time::Time if (caller)[0] ne q{Sidef::Time::Time};
require Sidef::Time::Gmtime if (caller)[0] ne q{Sidef::Time::Gmtime};
require Sidef::Types::Nil::Nil if (caller)[0] ne q{Sidef::Types::Nil::Nil};
require Sidef::Types::Bool::If if (caller)[0] ne q{Sidef::Types::Bool::If};
require Sidef::Types::Bool::While if (caller)[0] ne q{Sidef::Types::Bool::While};
require Sidef::Types::Bool::Bool if (caller)[0] ne q{Sidef::Types::Bool::Bool};
require Sidef::Types::Bool::Ternary if (caller)[0] ne q{Sidef::Types::Bool::Ternary};
require Sidef::Types::Char::Char if (caller)[0] ne q{Sidef::Types::Char::Char};
require Sidef::Types::Char::Chars if (caller)[0] ne q{Sidef::Types::Char::Chars};
require Sidef::Types::Byte::Bytes if (caller)[0] ne q{Sidef::Types::Byte::Bytes};
require Sidef::Types::Byte::Byte if (caller)[0] ne q{Sidef::Types::Byte::Byte};
require Sidef::Types::Glob::Dir if (caller)[0] ne q{Sidef::Types::Glob::Dir};
require Sidef::Types::Glob::Pipe if (caller)[0] ne q{Sidef::Types::Glob::Pipe};
require Sidef::Types::Glob::Fcntl if (caller)[0] ne q{Sidef::Types::Glob::Fcntl};
require Sidef::Types::Glob::DirHandle if (caller)[0] ne q{Sidef::Types::Glob::DirHandle};
require Sidef::Types::Glob::FileHandle if (caller)[0] ne q{Sidef::Types::Glob::FileHandle};
require Sidef::Types::Glob::Backtick if (caller)[0] ne q{Sidef::Types::Glob::Backtick};
require Sidef::Types::Glob::PipeHandle if (caller)[0] ne q{Sidef::Types::Glob::PipeHandle};
require Sidef::Types::Glob::File if (caller)[0] ne q{Sidef::Types::Glob::File};
require Sidef::Types::Glob::Stat if (caller)[0] ne q{Sidef::Types::Glob::Stat};
require Sidef::Types::Hash::Hash if (caller)[0] ne q{Sidef::Types::Hash::Hash};
require Sidef::Types::Array::HCArray if (caller)[0] ne q{Sidef::Types::Array::HCArray};
require Sidef::Types::Array::Array if (caller)[0] ne q{Sidef::Types::Array::Array};
require Sidef::Types::Black::Hole if (caller)[0] ne q{Sidef::Types::Black::Hole};
require Sidef::Types::Block::For if (caller)[0] ne q{Sidef::Types::Block::For};
require Sidef::Types::Block::Do if (caller)[0] ne q{Sidef::Types::Block::Do};
require Sidef::Types::Block::Try if (caller)[0] ne q{Sidef::Types::Block::Try};
require Sidef::Types::Block::Switch if (caller)[0] ne q{Sidef::Types::Block::Switch};
require Sidef::Types::Block::Code if (caller)[0] ne q{Sidef::Types::Block::Code};
require Sidef::Types::Block::Return if (caller)[0] ne q{Sidef::Types::Block::Return};
require Sidef::Types::Block::Given if (caller)[0] ne q{Sidef::Types::Block::Given};
require Sidef::Types::Block::Next if (caller)[0] ne q{Sidef::Types::Block::Next};
require Sidef::Types::Block::Break if (caller)[0] ne q{Sidef::Types::Block::Break};
require Sidef::Types::Block::Continue if (caller)[0] ne q{Sidef::Types::Block::Continue};
require Sidef::Types::Regex::Regex if (caller)[0] ne q{Sidef::Types::Regex::Regex};
require Sidef::Types::Number::Number if (caller)[0] ne q{Sidef::Types::Number::Number};
require Sidef::Types::Number::Unary if (caller)[0] ne q{Sidef::Types::Number::Unary};
require Sidef::Types::String::String if (caller)[0] ne q{Sidef::Types::String::String};
require Sidef::Module::Caller if (caller)[0] ne q{Sidef::Module::Caller};
require Sidef::Module::Require if (caller)[0] ne q{Sidef::Module::Require};
require Sidef::Module::Func if (caller)[0] ne q{Sidef::Module::Func};
require Sidef::Convert::Convert if (caller)[0] ne q{Sidef::Convert::Convert};
require Sidef::Variable::Magic if (caller)[0] ne q{Sidef::Variable::Magic};
require Sidef::Variable::InitMy if (caller)[0] ne q{Sidef::Variable::InitMy};
require Sidef::Variable::My if (caller)[0] ne q{Sidef::Variable::My};
require Sidef::Variable::Ref if (caller)[0] ne q{Sidef::Variable::Ref};
require Sidef::Variable::Init if (caller)[0] ne q{Sidef::Variable::Init};
require Sidef::Variable::ClassInit if (caller)[0] ne q{Sidef::Variable::ClassInit};
require Sidef::Variable::Variable if (caller)[0] ne q{Sidef::Variable::Variable};
require Sidef::Parser if (caller)[0] ne q{Sidef::Parser};
require Sidef::Exec if (caller)[0] ne q{Sidef::Exec};
