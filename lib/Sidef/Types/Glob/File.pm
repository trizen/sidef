package Sidef::Types::Glob::File {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::String::String
      );

    require File::Spec;
    use Sidef::Types::Number::Number;

    sub new {
        my (undef, $file) = @_;
        if (@_ > 2) {
            shift(@_);
            $file = File::Spec->catfile(map { "$_" } @_);
        }
        elsif (ref($file) && ref($file) ne 'SCALAR') {
            $file = "$file";
        }
        bless \$file, __PACKAGE__;
    }

    *call = \&new;

    sub get_value { ${$_[0]} }
    sub to_file   { $_[0] }

    {
        no strict 'refs';
        require Fcntl;

        my %cache;
        foreach my $name (@Fcntl::EXPORT, @Fcntl::EXPORT_OK) {
            ($name =~ /^[A-Z]/ and defined(&{'Fcntl::' . $name})) or next;
            *{__PACKAGE__ . '::' . $name} = sub {
                $cache{$name} //= Sidef::Types::Number::Number->_set_uint(&{'Fcntl::' . $name});
            };
        }
    }

    sub size {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        Sidef::Types::Number::Number->new(-s "$self");
    }

    sub md5 {
        ref($_[0]) || shift(@_);
        state $x = require Digest::MD5;
        open my $fh, '<:raw', "$_[0]" or return undef;
        my $o = Digest::MD5->new;
        $o->addfile($fh);
        Sidef::Types::String::String->new(scalar $o->hexdigest);
    }

    sub sha1 {
        ref($_[0]) || shift(@_);
        state $x = require Digest::SHA;
        open my $fh, '<:raw', "$_[0]" or return undef;
        my $o = Digest::SHA->new(1);
        $o->addfile($fh);
        Sidef::Types::String::String->new(scalar $o->hexdigest);
    }

    sub sha256 {
        ref($_[0]) || shift(@_);
        state $x = require Digest::SHA;
        open my $fh, '<:raw', "$_[0]" or return undef;
        my $o = Digest::SHA->new(256);
        $o->addfile($fh);
        Sidef::Types::String::String->new(scalar $o->hexdigest);
    }

    sub sha512 {
        ref($_[0]) || shift(@_);
        state $x = require Digest::SHA;
        open my $fh, '<:raw', "$_[0]" or return undef;
        my $o = Digest::SHA->new(512);
        $o->addfile($fh);
        Sidef::Types::String::String->new(scalar $o->hexdigest);
    }

    sub compare {
        ref($_[0]) || shift(@_);
        my ($self, $file) = @_;
        state $x = require File::Compare;
        my $cmp = File::Compare::compare("$self", "$file");

            $cmp < 0 ? Sidef::Types::Number::Number::MONE
          : $cmp > 0 ? Sidef::Types::Number::Number::ONE
          :            Sidef::Types::Number::Number::ZERO;
    }

    sub exists {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-e "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_empty {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-z "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_directory {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-d "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *is_dir = \&is_directory;

    sub is_link {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-l "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub readlink {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        my $link   = "$self";
        my $class  = (-d $link) ? 'Sidef::Types::Glob::Dir' : __PACKAGE__;
        $class->new(CORE::readlink($link));
    }

    *read_link = \&readlink;

    sub is_socket {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-S "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_block {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-b "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_char_device {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-c "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_readable {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-r "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_writeable {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-w "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub has_setuid_bit {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-u "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub has_setgid_bit {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-g "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub has_sticky_bit {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-k "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub modification_time_days_diff {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-M "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub access_time_days_diff {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-A "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub change_time_days_diff {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-C "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_executable {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-x "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_owned {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-o "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_real_readable {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-R "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_real_writeable {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-W "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_real_executable {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-X "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_real_owned {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-O "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_binary {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-B "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_text {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-T "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_file {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        (-f "$self") ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub name {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        Sidef::Types::String::String->new("$self");
    }

    sub basename {
        ref($_[0]) || shift(@_);
        my ($self) = @_;

        state $x = require File::Basename;
        Sidef::Types::String::String->new(File::Basename::basename("$self"));
    }

    *base      = \&basename;
    *base_name = \&basename;

    sub dirname {
        ref($_[0]) || shift(@_);
        my ($self) = @_;

        state $x = require File::Basename;
        Sidef::Types::Glob::Dir->new(File::Basename::dirname("$self"));
    }

    *dir      = \&dirname;
    *dir_name = \&dirname;

    sub is_absolute {
        ref($_[0]) || shift(@_);
        my ($self) = @_;

        File::Spec->file_name_is_absolute("$self")
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *is_abs = \&is_absolute;

    sub abs_name {
        my $class = ref($_[0]) || shift(@_);
        my ($self, $base) = @_;
        $class->new(File::Spec->rel2abs("$self", defined($base) ? "$base" : ()));
    }

    *abs     = \&abs_name;
    *absname = \&abs_name;
    *rel2abs = \&abs_name;

    sub rel_name {
        my $class = ref($_[0]) || shift(@_);
        my ($self, $base) = @_;
        $class->new(File::Spec->rel2abs("$self", defined($base) ? "$base" : ()));
    }

    *rel     = \&rel_name;
    *relname = \&rel_name;
    *abs2rel = \&rel_name;

    sub abs_path {
        my $class = ref($_[0]) || shift(@_);
        my ($self) = @_;

        state $x = require Cwd;
        $class->new(Cwd::abs_path("$self"));
    }

    *realpath = \&abs_path;

    sub rename {
        ref($_[0]) || shift(@_);
        my ($self, $file) = @_;

        CORE::rename("$self", "$file")
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub move {
        ref($_[0]) || shift(@_);
        my ($self, $file) = @_;

        state $x = require File::Copy;
        File::Copy::move("$self", "$file")
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *mv = \&move;

    sub copy {
        ref($_[0]) || shift(@_);
        my ($self, $file) = @_;

        state $x = require File::Copy;
        File::Copy::copy("$self", "$file")
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *cp = \&copy;

    sub edit {
        ref($_[0]) || shift(@_);
        my ($self, $code) = @_;

        my @lines;
        open(my $fh, '+<:utf8', "$self") || return (Sidef::Types::Bool::Bool::FALSE);
        while (defined(my $line = <$fh>)) {
            push @lines, $code->run(Sidef::Types::String::String->new($line));
        }

        truncate($fh, 0) || do {
            warn "[WARNING] Can't truncate file `$self`: $!";
            return undef;
        };

        seek($fh, 0, 0) || do {
            warn "[WARNING] Can't seek the begining of file `$self`: $!";
            return undef;
        };

        do {
            local $, = q{};
            local $\ = q{};
            (print $fh @lines) || do {
                warn "[WARNING] Can't write to file `$self`: $!";
                return undef;
            };
            close $fh;
          }
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub read {
        ref($_[0]) || shift(@_);
        my ($self, $mode) = @_;

        $mode = defined($mode) ? "$mode" : 'utf8';

        open(my $fh, "<:$mode", "$self") || do {
            warn "[WARNING] Can't open file `$self` for reading: $!";
            return undef;
        };

        local $/;
        Sidef::Types::String::String->new(<$fh>);
    }

    sub write {
        ref($_[0]) || shift(@_);
        my ($self, $string, $mode) = @_;

        $mode = defined($mode) ? "$mode" : 'utf8';

        open(my $fh, ">:$mode", "$self") || do {
            warn "[WARNING] Can't open file `$self` for writing: $!";
            return undef;
        };

        (print $fh "$string") || do {
            warn "[WARNING] Can't write to file `$self`: $!";
            return undef;
        };

        (close $fh)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub append {
        ref($_[0]) || shift(@_);
        my ($self, $string, $mode) = @_;

        $mode = defined($mode) ? "$mode" : 'utf8';

        open(my $fh, ">>:$mode", "$self") || do {
            warn "[WARNING] Can't open file `$self` for appending: $!";
            return undef;
        };

        (print $fh "$string") || do {
            warn "[WARNING] Can't append to file `$self`: $!";
            return undef;
        };

        (close $fh)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub open {
        ref($_[0]) || shift(@_);
        my ($self, $mode, $fh_ref, $err_ref) = @_;

        $mode = "$mode" if (ref $mode);

        my $success = CORE::open(my $fh, $mode, ref($self) eq __PACKAGE__ ? $$self : "$self");
        my $error   = $!;
        my $fh_obj  = Sidef::Types::Glob::FileHandle->new($fh, $self);

        if (defined $fh_ref) {
            ${$fh_ref} = $fh_obj;

            return $success
              ? (Sidef::Types::Bool::Bool::TRUE)
              : do {
                defined($err_ref) && do { ${$err_ref} = Sidef::Types::String::String->new($error) };
                (Sidef::Types::Bool::Bool::FALSE);
              };
        }

        $success ? $fh_obj : undef;
    }

    sub touch {
        ref($_[0]) || shift(@_);
        my ($self, @args) = @_;
        Sidef::Types::Glob::File::open($self, '>>', @args);
    }

    *make   = \&touch;
    *mkfile = \&touch;
    *create = \&touch;

    sub open_r {
        ref($_[0]) || shift(@_);
        my ($self, @args) = @_;
        Sidef::Types::Glob::File::open($self, '<:utf8', @args);
    }

    *open_read = \&open_r;

    sub open_w {
        ref($_[0]) || shift(@_);
        my ($self, @args) = @_;
        Sidef::Types::Glob::File::open($self, '>:utf8', @args);
    }

    *open_write = \&open_w;

    sub open_a {
        ref($_[0]) || shift(@_);
        my ($self, @args) = @_;
        Sidef::Types::Glob::File::open($self, '>>:utf8', @args);
    }

    *open_append = \&open_a;

    sub open_rw {
        ref($_[0]) || shift(@_);
        my ($self, @args) = @_;
        Sidef::Types::Glob::File::open($self, '+<:utf8', @args);
    }

    *open_read_write = \&open_rw;

    sub opendir {
        ref($_[0]) || shift(@_);
        my ($self, @args) = @_;
        Sidef::Types::Glob::Dir->new("$self")->open(@args);
    }

    sub sysopen {
        ref($_[0]) || shift(@_);
        my ($self, $var_ref, $mode, $perm) = @_;

        my $success = sysopen(my $fh, "$self", "$mode", $perm // 0666);

        if ($success) {
            $$var_ref = Sidef::Types::Glob::FileHandle->new($fh, $self);
        }

        $success
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub stat {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        Sidef::Types::Glob::Stat->stat("$self", $self);
    }

    sub lstat {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        Sidef::Types::Glob::Stat->lstat("$self", $self);
    }

    sub chown {
        ref($_[0]) || shift(@_);
        my ($self, $uid, $gid) = @_;
        CORE::chown($uid, $gid, "$self")
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub chmod {
        ref($_[0]) || shift(@_);
        my ($self, $permission) = @_;
        CORE::chmod($permission, "$self")
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub utime {
        ref($_[0]) || shift(@_);
        my ($self, $atime, $mtime) = @_;
        CORE::utime($atime, $mtime, "$self")
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub truncate {
        ref($_[0]) || shift(@_);
        my ($self, $length) = @_;
        CORE::truncate("$self", $length // 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub unlink {
        my ($self, @args) = @_;

        if (ref($self)) {
            CORE::unlink("$self")
              ? (Sidef::Types::Bool::Bool::TRUE)
              : (Sidef::Types::Bool::Bool::FALSE);
        }
        else {
            Sidef::Types::Number::Number->_set_uint(CORE::unlink(@args));
        }
    }

    sub delete {
        my ($self, @args) = @_;

        if (ref($self)) {
            my $file = "$self";
            CORE::unlink($file) || return Sidef::Types::Bool::Bool::FALSE;
            1 while CORE::unlink($file);
            return Sidef::Types::Bool::Bool::TRUE;
        }
        else {
            my $count = 0;

            foreach my $arg (@args) {
                my $file = "$arg";
                CORE::unlink($file) || next;
                1 while CORE::unlink($file);
                ++$count;
            }

            Sidef::Types::Number::Number->_set_uint($count);
        }
    }

    *remove = \&delete;

    sub split {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { Sidef::Types::String::String->new($_) } File::Spec->splitdir("$self")]);
    }

    sub splitpath {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { Sidef::Types::String::String->new($_) } File::Spec->splitpath("$self")]);
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('File(' . ${Sidef::Types::String::String->new("$self")->dump} . ')');
    }

    sub to_str {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }

    *to_s = \&to_str;
};

1
