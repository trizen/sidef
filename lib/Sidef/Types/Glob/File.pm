package Sidef::Types::Glob::File {

    use 5.014;

    use parent qw(
      Sidef::Convert::Convert
      Sidef::Types::String::String
      );

    sub new {
        my (undef, $file) = @_;
        if (@_ > 2) {
            state $x = require File::Spec;
            $file = File::Spec->catfile(map { ref($_) ? "${$_->to_file}" : $_ } @_[1 .. $#_]);
        }
        elsif (ref($file) && ref($file) ne 'SCALAR') {
            return $file->to_file;
        }
        bless \$file, __PACKAGE__;
    }

    *call = \&new;

    sub get_value { ${$_[0]} }
    sub to_file   { $_[0] }

    sub get_constant {
        my ($self, $str) = @_;

        my $name = "$str";
        state $CACHE = {};

        if (exists $CACHE->{$name}) {
            return $CACHE->{$name};
        }

        state $x = require Fcntl;
        my $call = \&{'Fcntl' . '::' . $name};

        if (defined(&$call)) {
            return $CACHE->{$name} = Sidef::Types::Number::Number->new($call->());
        }

        die qq{[ERROR] Inexistent File constant "$name"!\n};
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
        Sidef::Types::Number::Number->new(-s $$self);
    }

    sub compare {
        my ($self, $file) = @_;
        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }
        state $x = require File::Compare;
        Sidef::Types::Number::Number->new(File::Compare::compare($$self, "$file"));
    }

    sub exists {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-e $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_empty {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-z $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_directory {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-d $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *is_dir = \&is_directory;

    sub is_link {
        my ($self) = @_;
        (-l $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub readlink {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::String::String->new(CORE::readlink($$self));
    }

    *read_link = \&readlink;

    sub is_socket {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-S $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_block {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-b $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_char_device {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-c $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_readable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-r $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_writeable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-w $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub has_setuid_bit {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-u $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub has_setgid_bit {
        my ($self) = @_;
        (-g $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub has_sticky_bit {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-k $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub modification_time_days_diff {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-M $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub access_time_days_diff {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-A $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub change_time_days_diff {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-C $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_executable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-x $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_owned {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-o $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_real_readable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-R $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_real_writeable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-W $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_real_executable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-X $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_real_owned {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-O $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_binary {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-B $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_text {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-T $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_file {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        (-f $$self) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub name {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::String::String->new($$self);
    }

    sub basename {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);

        state $x = require File::Basename;
        Sidef::Types::String::String->new(File::Basename::basename($$self));
    }

    *base      = \&basename;
    *base_name = \&basename;

    sub dirname {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);

        state $x = require File::Basename;
        Sidef::Types::Glob::Dir->new(File::Basename::dirname($$self));
    }

    *dir      = \&dirname;
    *dir_name = \&dirname;

    sub is_absolute {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        state $x = require File::Spec;
        (File::Spec->file_name_is_absolute($$self)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *is_abs = \&is_absolute;

    sub abs_name {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);

        state $x = require File::Spec;
        $self->new(File::Spec->rel2abs($$self));
    }

    *abs     = \&abs_name;
    *absname = \&abs_name;
    *rel2abs = \&abs_name;

    sub rel_name {
        my ($self, $base) = @_;
        state $x = require File::Spec;
        $self->new(File::Spec->rel2abs($$self, defined($base) ? "$base" : ()));
    }

    *rel     = \&rel_name;
    *relname = \&rel_name;
    *abs2rel = \&rel_name;

    sub rename {
        my ($self, $file) = @_;

        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }

        (CORE::rename($$self, "$file")) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub move {
        my ($self, $file) = @_;

        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }

        state $x = require File::Copy;
        (File::Copy::move($$self, "$file")) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *mv = \&move;

    sub copy {
        my ($self, $file) = @_;

        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }

        state $x = require File::Copy;
        (File::Copy::copy($$self, "$file")) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *cp = \&copy;

    sub edit {
        my ($self, $code) = @_;

        if (@_ == 3) {
            ($self, $code) = ($code, $_[2]);
        }

        my @lines;
        open(my $fh, '+<:utf8', $$self) || return (Sidef::Types::Bool::Bool::FALSE);
        while (defined(my $line = <$fh>)) {
            push @lines, $code->run(Sidef::Types::String::String->new($line));
        }

        truncate($fh, 0) || do {
            warn "[WARN] Can't truncate file `$$self': $!";
            return;
        };

        seek($fh, 0, 0) || do {
            warn "[WARN] Can't seek the begining of file `$$self': $!";
            return;
        };

        do {
            local $, = q{};
            local $\ = q{};
            print $fh @lines;
            close $fh;
          }
          ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub open {
        my ($self, $mode, $fh_ref, $err_ref) = @_;

        $mode = "$mode" if (ref $mode);

        my $success = CORE::open(my $fh, $mode, $$self);
        my $error   = $!;
        my $fh_obj  = Sidef::Types::Glob::FileHandle->new(fh => $fh, self => $self);

        if (defined $fh_ref) {
            ${$fh_ref} = $fh_obj;

            return $success
              ? (Sidef::Types::Bool::Bool::TRUE)
              : do {
                defined($err_ref) && do { ${$err_ref} = Sidef::Types::String::String->new($error) };
                (Sidef::Types::Bool::Bool::FALSE);
              };
        }

        $success ? $fh_obj : ();
    }

    sub open_r {
        my ($self, @rest) = @_;
        $self->open('<:utf8', @rest);
    }

    *open_read = \&open_r;

    sub open_w {
        my ($self, @rest) = @_;
        $self->open('>:utf8', @rest);
    }

    *open_write = \&open_w;

    sub open_a {
        my ($self, @rest) = @_;
        $self->open('>>:utf8', @rest);
    }

    *open_append = \&open_a;

    sub open_rw {
        my ($self, @rest) = @_;
        $self->open('+<:utf8', @rest);
    }

    *open_read_write = \&open_rw;

    sub opendir {
        my ($self, @rest) = @_;
        Sidef::Types::Glob::Dir->new($$self)->open(@rest);
    }

    sub sysopen {
        my ($self, $var_ref, $mode, $perm) = @_;

        my $success = sysopen(
            my $fh,
            $$self, "$mode",
            defined($perm)
            ? do {
                local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                $perm->get_value;
              }
            : 0666
        );

        if ($success) {
            ${$var_ref} = Sidef::Types::Glob::FileHandle->new(fh => $fh, self => $self);
        }

        ($success) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub stat {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Glob::Stat->stat($$self, $self);
    }

    sub lstat {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Sidef::Types::Glob::Stat->lstat($$self, $self);
    }

    sub chown {
        my ($self, $uid, $gid) = @_;

        if (@_ == 4) {
            ($self, $uid, $gid) = ($uid, $gid, $_[3]);
        }

        (
         CORE::chown(
             do {
                 local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                 $uid->get_value;
             },
             do {
                 local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                 $gid->get_value;
             },
             $$self
                    )
        )
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub chmod {
        my ($self, $permission) = @_;

        if (@_ == 3) {
            ($self, $permission) = ($permission, $_[2]);
        }

        (
         CORE::chmod(
             do {
                 local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                 $permission->get_value;
             },
             $$self
                    )
        ) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub utime {
        my ($self, $atime, $mtime) = @_;

        if (@_ == 4) {
            ($self, $atime, $mtime) = ($atime, $mtime, $_[3]);
        }

        (
         CORE::utime(
             do {
                 local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                 $atime->get_value;
             },
             do {
                 local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                 $mtime->get_value;
             },
             $$self
                    )
        )
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub truncate {
        my ($self, $length) = @_;

        if (@_ == 3) {
            ($self, $length) = ($length, $_[2]);
        }

        my $len = defined($length)
          ? do {
            local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
            $length->get_value;
          }
          : 0;
        (CORE::truncate($$self, $len)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub unlink {
        my ($self, @args) = @_;
        @args                      ? Sidef::Types::Number::Number->new(CORE::unlink(@args))
          : (CORE::unlink($$self)) ? (Sidef::Types::Bool::Bool::TRUE)
          :                          (Sidef::Types::Bool::Bool::FALSE);
    }

    *delete = \&unlink;
    *remove = \&unlink;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('File(' . ${Sidef::Types::String::String->new($$self)->dump} . ')');
    }

    # Path split
    *split = \&Sidef::Types::Glob::Dir::split;

};

1
