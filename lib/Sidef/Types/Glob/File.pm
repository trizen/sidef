package Sidef::Types::Glob::File {

    use 5.014;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $file) = @_;
        ref($file) && ref($file) ne 'SCALAR' && return $file->to_file;
        bless \$file, __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        ${$_[0]};
    }

    sub get_constant {
        my ($self, $name) = @_;
        Sidef::Types::Glob::Fcntl->$name;
    }

    sub touch {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(CORE::open(my $fh, '>>', $$self));
    }

    *make   = \&touch;
    *mkfile = \&touch;
    *create = \&touch;

    sub size {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(-s $$self);
    }

    sub compare {
        my ($self, $file) = @_;
        $self->_is_file($file) || return;
        if (@_ == 3) {
            $self->_is_file($_[-1]) || return;
            ($self, $file) = ($file, $_[-1]);
        }
        require File::Compare;
        Sidef::Types::Number::Number->new(File::Compare::compare($$self, $$file));
    }

    *cmp = \&compare;

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

    *base      = \&basename;
    *base_name = \&basename;
    *baseName  = \&basename;

    sub dirname {
        my ($self) = @_;

        require File::Basename;
        Sidef::Types::Glob::Dir->new(File::Basename::dirname($$self));
    }

    *dir      = \&dirname;
    *dir_name = \&dirname;
    *dirName  = \&dirname;

    sub is_absolute {
        my ($self) = @_;
        require File::Spec;
        Sidef::Types::Bool::Bool->new(File::Spec->file_name_is_absolute($$self));
    }

    *is_abs = \&is_absolute;

    sub abs_name {
        my ($self) = @_;

        require File::Spec;
        $self->new(File::Spec->rel2abs($$self));
    }

    *abs     = \&abs_name;
    *absname = \&abs_name;
    *absName = \&abs_name;
    *rel2abs = \&abs_name;

    sub rel_name {
        my ($self, $base) = @_;
        require File::Spec;
        $self->new(
               File::Spec->rel2abs(
                    $$self,
                    defined($base) ? ref($base) eq 'Sidef::Types::Glob::Dir' || $self->_is_string($base) ? $$base : return : ()
               )
        );
    }

    *rel     = \&rel_name;
    *relname = \&rel_name;
    *relName = \&rel_name;
    *abs2rel = \&rel_name;

    sub rename {
        my ($self, $file) = @_;

        ref($file) eq ref($self)
          || $self->_is_string($file)
          || return;

        if (@_ == 3) {
            ref($_[-1]) eq ref($self)
              || $self->_is_string($_[-1])
              || return;
            ($self, $file) = ($file, $_[-1]);
        }

        Sidef::Types::Bool::Bool->new(CORE::rename($$self, $$file));
    }

    *rename_to = \&rename;
    *renameTo  = \&rename;

    sub move {
        my ($self, $file) = @_;

        ref($file) eq ref($self)
          || $self->_is_string($file)
          || return;

        if (@_ == 3) {
            ref($_[-1]) eq ref($self)
              || $self->_is_string($_[-1])
              || return;
            ($self, $file) = ($file, $_[-1]);
        }

        require File::Copy;
        Sidef::Types::Bool::Bool->new(File::Copy::move($$self, $$file));
    }

    *mv      = \&move;
    *move_to = \&move;
    *moveTo  = \&move;

    sub copy {
        my ($self, $file) = @_;

             ref($file) eq 'Sidef::Types::Glob::FileHandle'
          || ref($file) eq ref($self)
          || $self->_is_string($file)
          || return;

        if (@_ == 3) {
                 ref($_[-1]) eq 'Sidef::Types::Glob::FileHandle'
              || ref($_[-1]) eq ref($self)
              || $self->_is_string($_[-1])
              || return;
            ($self, $file) = ($file, $_[-1]);
        }

        require File::Copy;
        Sidef::Types::Bool::Bool->new(
                          File::Copy::copy(map { ref($_) eq 'Sidef::Types::Glob::FileHandle' ? $_->{fh} : $$_ } $self, $file));
    }

    *cp = \&copy;

    sub edit {
        my ($self, $code) = @_;
        $self->_is_code($code) || return;

        my @lines;
        open(my $fh, '+<:utf8', $$self) || return Sidef::Types::Bool::Bool->false;
        while (defined(my $line = <$fh>)) {
            push @lines, $code->call(Sidef::Types::String::String->new($line));
        }

        truncate($fh, 0) || do {
            warn "[WARN] Can't truncate file `$$self': $!";
            return;
        };

        seek($fh, 0, 0) || do {
            warn "[WARN] Can't seek the begining of file `$$self': $!";
            return;
        };

        Sidef::Types::Bool::Bool->new(
            do {
                local $, = q{};
                local $\ = q{};
                print $fh @lines;
                close $fh;
              }
        );
    }

    sub open {
        my ($self, $mode, $fh_ref, $err_ref) = @_;

        ref($mode)
          ? $self->_is_string($mode, 1)
              ? do { $mode = $$mode }
              : return
          : ();

        my $success = CORE::open(my $fh, $mode, $$self);
        my $fh_obj = Sidef::Types::Glob::FileHandle->new(fh => $fh, file => $self);

        if (defined $fh_ref) {
            $self->_is_var_ref($fh_ref) || return;
            $fh_ref->get_var->set_value($fh_obj);

            return $success
              ? Sidef::Types::Bool::Bool->true
              : do {
                defined($err_ref) && do {
                    $self->_is_var_ref($err_ref) || return;
                    $err_ref->get_var->set_value(Sidef::Types::String::String->new($!));
                };
                Sidef::Types::Bool::Bool->false;
              };
        }
        elsif ($success) {
            return $fh_obj;
        }

        ();
    }

    sub open_r {
        my ($self, @rest) = @_;
        $self->open('<:utf8', @rest);
    }

    *openR     = \&open_r;
    *openRead  = \&open_r;
    *open_read = \&open_r;

    sub open_w {
        my ($self, @rest) = @_;
        $self->open('>:utf8', @rest);
    }

    *openW      = \&open_w;
    *openWrite  = \&open_w;
    *open_write = \&open_w;

    sub open_a {
        my ($self, @rest) = @_;
        $self->open('>>:utf8', @rest);
    }

    *openA       = \&open_a;
    *openAppend  = \&open_a;
    *open_append = \&open_a;

    sub open_rw {
        my ($self, @rest) = @_;
        $self->open('+<:utf8', @rest);
    }

    *openRW          = \&open_rw;
    *openReadWrite   = \&open_rw;
    *open_read_write = \&open_rw;

    sub opendir {
        my ($self, @rest) = @_;
        Sidef::Types::Glob::Dir->new($$self)->open(@rest);
    }

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
        $self->_is_number($uid) || return;
        $self->_is_number($gid) || return;
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

    *delete = \&unlink;
    *remove = \&unlink;

    sub lstat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->lstat($$self, $self);
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('File.new(' . ${Sidef::Types::String::String->new($$self)->dump} . ')');
    }

    # Path split
    *split = \&Sidef::Types::Glob::Dir::split;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '<=>'} = \&compare;
    }

};

1
