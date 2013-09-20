package Sidef::Types::Glob::File {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $file) = @_;
        ref($file) && return $file->to_file;
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

    sub readlink {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::readlink($$self));
    }

    *readLink = \&readlink;

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

        require File::Spec;
        __PACKAGE__->new(File::Spec->rel2abs($$self));
    }

    sub rename {
        my ($self, $file) = @_;

        ref($file) eq __PACKAGE__
          || $self->_is_string($file)
          || return;

        Sidef::Types::Bool::Bool->new(rename($$self, $$file));
    }

    sub move {
        my ($self, $file) = @_;

        ref($file) eq __PACKAGE__
          || $self->_is_string($file)
          || return;

        require File::Copy;
        Sidef::Types::Bool::Bool->new(File::Copy::move($$self, $$file));
    }

    *mv = \&move;

    sub copy {
        my ($self, $file) = @_;

             ref($file) eq 'Sidef::Types::Glob::FileHandle'
          || ref($file) eq __PACKAGE__
          || $self->_is_string($file)
          || return;

        require File::Copy;
        Sidef::Types::Bool::Bool->new(
                       File::Copy::copy($$self, ref($file) eq 'Sidef::Types::Glob::FileHandle' ? $file->{fh} : $$file));
    }

    *cp = \&copy;

    sub open {
        my ($self, $mode, $var_ref) = @_;

        ref($mode)
          ? $self->is_string($mode, 1)
              ? do { $mode = $$mode }
              : return
          : ();

        my $success = open(my $fh, $mode, $$self);
        my $fh_obj = Sidef::Types::Glob::FileHandle->new(fh => $fh, file => $self);

        if (ref($var_ref) eq 'Sidef::Variable::Ref') {
            $var_ref->get_var->set_value($fh_obj);

            return $success
              ? Sidef::Types::Bool::Bool->true
              : Sidef::Types::Bool::Bool->false;
        }
        elsif ($success) {
            return $fh_obj;
        }

        return;
    }

    sub open_r {
        my ($self, $var_ref) = @_;
        $self->open('<', $var_ref);
    }

    *openR     = \&open_r;
    *openRead  = \&open_r;
    *open_read = \&open_r;

    sub open_w {
        my ($self, $var_ref) = @_;
        $self->open('>', $var_ref);
    }

    *openW      = \&open_w;
    *openWrite  = \&open_w;
    *open_write = \&open_w;

    sub open_a {
        my ($self, $var_ref) = @_;
        $self->open('>>', $var_ref);
    }

    *openA       = \&open_a;
    *openAppend  = \&open_a;
    *open_append = \&open_a;

    sub sysopen {
        my ($self, $var_ref, $mode, $perm) = @_;

        $self->_is_var_ref($var_ref) || return;
        $self->_is_number($mode)     || return;

        my $success = sysopen(my $fh, $$self, $$mode, defined($perm) ? $self->_is_number($perm) ? ($$perm) : return : 0666);

        if ($success) {
            $var_ref->get_var->set_value(Sidef::Types::Glob::FileHandle->new(fh => $fh, file => $self));
        }

        Sidef::Types::Bool::Bool->new($success);
    }

    *sysOpen = \&sysopen;

    sub stat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->stat($$self, $self);
    }

    sub chown {
        my ($self, $uid, $gid) = @_;
        $self->_is_number($uid) || do { warn "[WARN] File.chown(): 'uid' is not numeric!\n"; return };
        $self->_is_number($gid) || do { warn "[WARN] File.chown(): 'gid' is not numeric!\n"; return };
        Sidef::Types::Bool::Bool->new(CORE::chown($$uid, $$gid, $$self));
    }

    sub chmod {
        my ($self, $permission) = @_;
        $self->_is_number($permission) || return;
        Sidef::Types::Bool::Bool->new(CORE::chmod($$permission, $$self));
    }

    sub utime {
        my ($self, $atime, $mtime) = @_;

        ref($atime) eq 'Sidef::Time::Time' || $self->_is_number($atime) || return;
        ref($mtime) eq 'Sidef::Time::Time' || $self->_is_number($mtime) || return;

        Sidef::Types::Bool::Bool->new(CORE::utime($$atime, $$mtime, $$self));
    }

    sub unlink {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(CORE::unlink($$self));
    }

    sub touch {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(CORE::open(my $fh, '>>', $$self));
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
