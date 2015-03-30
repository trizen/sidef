package Sidef::Types::Glob::File {

    use 5.014;

    use parent qw(
      Sidef::Types::String::String
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
        Sidef::Types::Glob::Fcntl->new;
        Sidef::Types::Glob::Fcntl->$name;
    }

    sub touch {
        my ($self, @args) = @_;
        $self->open('>>', @args);
    }

    *make   = \&touch;
    *mkfile = \&touch;
    *create = \&touch;

    sub size {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Number::Number->new(-s $self->get_value);
    }

    sub compare {
        my ($self, $file) = @_;
        $self->_is_file($file) || return;
        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }
        require File::Compare;
        Sidef::Types::Number::Number->new(File::Compare::compare($self->get_value, $file->get_value));
    }

    *cmp = \&compare;

    sub exists {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-e $self->get_value);
    }

    sub is_empty {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-z $self->get_value);
    }

    *isEmpty = \&is_empty;

    sub is_directory {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-d $self->get_value);
    }

    *is_dir      = \&is_directory;
    *isDir       = \&is_directory;
    *isDirectory = \&is_directory;

    sub is_link {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-l $self->get_value);
    }

    *isLink = \&is_link;

    sub readlink {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::String::String->new(CORE::readlink($self->get_value));
    }

    *readLink = \&readlink;

    sub is_socket {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-S $self->get_value);
    }

    *isSocket = \&is_socket;

    sub is_block {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-b $self->get_value);
    }

    *isBlock = \&is_block;

    sub is_char_device {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-c $self->get_value);
    }

    *isCharDevice = \&is_char_device;

    sub is_readable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-r $self->get_value);
    }

    *isReadable = \&is_readable;

    sub is_writeable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-w $self->get_value);
    }

    *isWriteable = \&is_writeable;

    sub has_setuid_bit {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-u $self->get_value);
    }

    *hasSetuidBit = \&has_setuid;

    sub has_setgid_bit {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(-g $self->get_value);
    }

    *hasSetgidBit = \&has_setgid_bit;

    sub has_sticky_bit {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-k $self->get_value);
    }

    *hasStickyBit = \&has_sticky_bit;

    sub modification_time_days_diff {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-M $self->get_value);
    }

    *modificationTimeDaysDiff = \&modification_time_days_diff;

    sub access_time_days_diff {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-A $self->get_value);
    }

    *accessTimeDaysDiff = \&access_time_days_diff;

    sub change_time_days_diff {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-C $self->get_value);
    }

    *changeTimeDaysDiff = \&change_time_days_diff;

    sub is_executable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-x $self->get_value);
    }

    *isExecutable = \&is_executable;

    sub is_owned {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-o $self->get_value);
    }

    *isOwned = \&is_owned;

    sub is_real_readable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-R $self->get_value);
    }

    *isRealReadable = \&is_real_readable;

    sub is_real_writeable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-W $self->get_value);
    }

    *isRealWriteable = \&is_real_writeable;

    sub is_real_executable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-X $self->get_value);
    }

    *isRealExecutable = \&is_real_executable;

    sub is_real_owned {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-O $self->get_value);
    }

    *isRealOwned = \&is_real_owned;

    sub is_binary {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-B $self->get_value);
    }

    *isBinary = \&is_binary;

    sub is_text {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-T $self->get_value);
    }

    *isText = \&is_text;

    sub is_file {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Bool::Bool->new(-f $self->get_value);
    }

    *isFile = \&is_file;

    sub name {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::String::String->new($self->get_value);
    }

    sub basename {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);

        require File::Basename;
        Sidef::Types::String::String->new(File::Basename::basename($self->get_value));
    }

    *base      = \&basename;
    *base_name = \&basename;
    *baseName  = \&basename;

    sub dirname {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);

        require File::Basename;
        Sidef::Types::Glob::Dir->new(File::Basename::dirname($self->get_value));
    }

    *dir      = \&dirname;
    *dir_name = \&dirname;
    *dirName  = \&dirname;

    sub is_absolute {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        require File::Spec;
        Sidef::Types::Bool::Bool->new(File::Spec->file_name_is_absolute($self->get_value));
    }

    *is_abs = \&is_absolute;

    sub abs_name {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);

        require File::Spec;
        $self->new(File::Spec->rel2abs($self->get_value));
    }

    *abs     = \&abs_name;
    *absname = \&abs_name;
    *absName = \&abs_name;
    *rel2abs = \&abs_name;

    sub rel_name {
        my ($self, $base) = @_;
        require File::Spec;
        $self->new(File::Spec->rel2abs($self->get_value, defined($base) ? $base->get_value : ()));
    }

    *rel     = \&rel_name;
    *relname = \&rel_name;
    *relName = \&rel_name;
    *abs2rel = \&rel_name;

    sub rename {
        my ($self, $file) = @_;

        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }

        Sidef::Types::Bool::Bool->new(CORE::rename($self->get_value, $file->get_value));
    }

    *rename_to = \&rename;
    *renameTo  = \&rename;

    sub move {
        my ($self, $file) = @_;

        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }

        require File::Copy;
        Sidef::Types::Bool::Bool->new(File::Copy::move($self->get_value, $file->get_value));
    }

    *mv      = \&move;
    *move_to = \&move;
    *moveTo  = \&move;

    sub copy {
        my ($self, $file) = @_;

        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }

        require File::Copy;
        Sidef::Types::Bool::Bool->new(File::Copy::copy($self->get_value, $file->get_value));
    }

    *cp = \&copy;

    sub edit {
        my ($self, $code) = @_;

        if (@_ == 3) {
            ($self, $code) = ($code, $_[2]);
        }

        my @lines;
        open(my $fh, '+<:utf8', $self->get_value) || return Sidef::Types::Bool::Bool->false;
        while (defined(my $line = <$fh>)) {
            push @lines, $code->call(Sidef::Types::String::String->new($line));
        }

        truncate($fh, 0) || do {
            warn "[WARN] Can't truncate file `$self->get_value': $!";
            return;
        };

        seek($fh, 0, 0) || do {
            warn "[WARN] Can't seek the begining of file `$self->get_value': $!";
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

        if (ref $mode) {
            $mode = $mode->get_value;
        }

        my $success = CORE::open(my $fh, $mode, $self->get_value);
        my $fh_obj = Sidef::Types::Glob::FileHandle->new(fh => $fh, file => $self);

        if (defined $fh_ref) {
            $fh_ref->get_var->set_value($fh_obj);

            return $success
              ? Sidef::Types::Bool::Bool->true
              : do {
                defined($err_ref) && $err_ref->get_var->set_value(Sidef::Types::String::String->new($!));
                Sidef::Types::Bool::Bool->false;
              };
        }

        $success ? $fh_obj : ();
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
        Sidef::Types::Glob::Dir->new($self->get_value)->open(@rest);
    }

    sub sysopen {
        my ($self, $var_ref, $mode, $perm) = @_;

        my $success = sysopen(my $fh, $self->get_value, $mode->get_value, defined($perm) ? $perm->get_value : 0666);

        if ($success) {
            $var_ref->get_var->set_value(Sidef::Types::Glob::FileHandle->new(fh => $fh, file => $self));
        }

        Sidef::Types::Bool::Bool->new($success);
    }

    *sysOpen = \&sysopen;

    sub stat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->stat($self->get_value, $self);
    }

    sub chown {
        my ($self, $uid, $gid) = @_;
        Sidef::Types::Bool::Bool->new(CORE::chown($uid->get_value, $gid->get_value, $self->get_value));
    }

    sub chmod {
        my ($self, $permission) = @_;
        Sidef::Types::Bool::Bool->new(CORE::chmod($permission->get_value, $self->get_value));
    }

    sub utime {
        my ($self, $atime, $mtime) = @_;
        Sidef::Types::Bool::Bool->new(CORE::utime($atime->get_value, $mtime->get_value, $self->get_value));
    }

    sub unlink {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(CORE::unlink($self->get_value));
    }

    *delete = \&unlink;
    *remove = \&unlink;

    sub lstat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->lstat($self->get_value, $self);
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('File.new(' . ${Sidef::Types::String::String->new($self->get_value)->dump} . ')');
    }

    # Path split
    *split = \&Sidef::Types::Glob::Dir::split;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '<=>'} = \&compare;
    }

};

1
