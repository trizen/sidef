package Sidef::Types::Glob::File {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef::Convert::Convert);

    sub new {
        my (undef, $file) = @_;
        $file = $$file if ref $file;
        bless \$file, __PACKAGE__;
    }

    *split = \&Sidef::Types::Glob::Dir::split;

    sub get_value {
        ${$_[0]};
    }

    sub size {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(-s $$self);
    }

    sub exists {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-e $$self);
    }

    sub is_empty {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-z $$self);
    }

    *isEmpty = \&is_empty;

    sub is_directory {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-d $$self);
    }

    *is_dir      = \&is_directory;
    *isDir       = \&is_directory;
    *isDirectory = \&is_directory;

    sub is_link {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-l $$self);
    }

    *isLink = \&is_link;

    sub is_socket {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-S $$self);
    }

    *isSocket = \&is_socket;

    sub is_block {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-b $$self);
    }

    *isBlock = \&is_block;

    sub is_char_device {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-c $$self);
    }

    *isCharDevice = \&is_char_device;

    sub is_readable {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-r $$self);
    }

    *isReadable = \&is_readable;

    sub is_writeable {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-w $$self);
    }

    *isWriteable = \&is_writeable;

    sub has_setuid_bit {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-u $$self);
    }

    *hasSetuidBit = \&has_setuid;

    sub has_setgid_bit {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-g $$self);
    }

    *hasSetgidBit = \&has_setgid_bit;

    sub has_sticky_bit {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-k $$self);
    }

    *hasStickyBit = \&has_sticky_bit;

    sub modification_time_days_diff {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-M $$self);
    }

    *modificationTimeDaysDiff = \&modification_time_days_diff;

    sub access_time_days_diff {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-A $$self);
    }

    *accessTimeDaysDiff = \&access_time_days_diff;

    sub change_time_days_diff {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-C $$self);
    }

    *changeTimeDaysDiff = \&change_time_days_diff;

    sub is_executable {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-x $$self);
    }

    *isExecutable = \&is_executable;

    sub is_owned {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-o $$self);
    }

    *isOwned = \&is_owned;

    sub is_real_readable {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-R $$self);
    }

    *isRealReadable = \&is_real_readable;

    sub is_real_writeable {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-W $$self);
    }

    *isRealWriteable = \&is_real_writeable;

    sub is_real_executable {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-X $$self);
    }

    *isRealExecutable = \&is_real_executable;

    sub is_real_owned {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-O $$self);
    }

    *isRealOwned = \&is_real_owned;

    sub is_binary {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-B $$self);
    }

    *isBinary = \&is_binary;

    sub is_text {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-T $$self);
    }

    *isText = \&is_text;

    sub is_file {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-f $$self);
    }

    *isFile = \&is_file;

    sub name {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }

    sub basename {
        my ($self) = @_;

        require File::Basename;
        Sidef::Types::String::String->new(File::Basename::basename($$self));
    }

    sub dirname {
        my ($self) = @_;

        require File::Basename;
        Sidef::Types::Glob::Dir->new(File::Basename::dirname($$self));
    }

    sub abs_name {
        my ($self) = @_;

        require Cwd;
        __PACKAGE__->new(Cwd::abs_path($$self));
    }

    sub open {
        my ($self, $mode) = @_;
        $mode = ${$mode} if ref $mode;

        open(my $fh, $mode, $$self) || return;
        Sidef::Types::Glob::FileHandle->new(fh => $fh, file => $self);
    }

    sub open_r {
        my ($self) = @_;
        $self->open('<');
    }

    sub open_w {
        my ($self) = @_;
        $self->open('>');
    }

    sub open_a {
        my ($self) = @_;
        $self->open('>>');
    }

    sub stat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->stat($$self, $self);
    }

    sub lstat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->lstat($$self, $self);
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('File.new(' . ${Sidef::Types::String::String->new($$self)->dump} . ')');
    }
}
