package Sidef::Types::Glob::FileHandle {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef);

    sub new {
        my (undef, %opt) = @_;

        bless {
               fh   => $opt{fh},
               file => $opt{file},
              },
          __PACKAGE__;
    }

    sub get_value {
        $_[0]->{fh};
    }

    sub file {
        $_[0]{file};
    }

    *parent = \&file;

    sub is_on_tty {
        Sidef::Types::Bool::Bool->new(-t $_[0]{fh});
    }

    *isOnTty = \&is_on_tty;

    sub stdout {
        __PACKAGE__->new(fh   => \*STDOUT,
                         file => Sidef::Types::Nil::Nil->new,);
    }

    sub stderr {
        __PACKAGE__->new(fh   => \*STDERR,
                         file => Sidef::Types::Nil::Nil->new,);
    }

    sub stdin {
        __PACKAGE__->new(fh   => \*STDIN,
                         file => Sidef::Types::Nil::Nil->new,);
    }

    sub writeString {
        my ($self, @args) = @_;

        @args <= 3 || do {
            warn "[WARN] FileHandle.writeString(): Too many arguments! Expected: (str, len, offset).";
            return;
        };

        Sidef::Types::Bool::Bool->new(syswrite $self->{fh}, @args);
    }

    *write_string = \&writeString;

    sub print {
        my ($self, @args) = @_;
        Sidef::Types::Bool::Bool->new(print {$self->{fh}} @args);
    }

    sub println {
        my ($self, @args) = @_;
        Sidef::Types::Bool::Bool->new(say {$self->{fh}} @args);
    }

    sub read {
        my ($self, $var_ref, $length, $offset) = @_;

        ref($var_ref) eq 'Sidef::Variable::Ref' || do {
            warn "[WARN] FileHandle.read(): first argument must be a variable reference!\n";
            return;
        };

        $self->_is_number($length) || return;

        my $var   = $var_ref->get_var;
        my $chunk = $var->get_value;

        my $size = Sidef::Types::Number::Number->new(
            defined($offset)
            ? do {
                $self->_is_number($offset) || return;
                CORE::read($self->{fh}, $chunk, $$length, $$offset);
              }
            : CORE::read($self->{fh}, $chunk, $$length)
        );

        $var->set_value(Sidef::Types::String::String->new($chunk));

        return $size;
    }

    sub sysread {
        my ($self, $var_ref, $length, $offset) = @_;

        ref($var_ref) eq 'Sidef::Variable::Ref' || do {
            warn "[WARN] FileHandle.sysread(): first argument must be a variable reference!\n";
            return;
        };

        $self->_is_number($length) || return;

        my $var   = $var_ref->get_var;
        my $chunk = $var->get_value;

        my $size = Sidef::Types::Number::Number->new(
            defined($offset)
            ? do {
                $self->_is_number($offset) || return;
                CORE::sysread($self->{fh}, $chunk, $$length, $$offset);
              }
            : CORE::sysread($self->{fh}, $chunk, $$length)
        );

        $var->set_value(Sidef::Types::String::String->new($chunk));

        return $size;
    }

    *sysRead = \&sysread;

    sub readline {
        my ($self) = @_;

        my $line = CORE::readline $self->{fh};
        defined($line)
          ? Sidef::Types::String::String->new($line)
          : Sidef::Types::Nil::Nil->new();
    }

    *readln   = \&readline;
    *readLine = \&readline;

    sub read_char {
        my ($self) = @_;

        my $char = getc($self->{fh});
        defined($char)
          ? Sidef::Types::Char::Char->new($char)
          : Sidef::Types::Nil::Nil->new();
    }

    *readChar = \&read_char;

    sub read_all {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } CORE::readline($self->{fh}));
    }

    *get_lines = \&read_all;
    *getLines  = \&read_all;

    sub eof {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(eof $self->{fh});
    }

    sub tell {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(tell($self->{fh}));
    }

    sub seek {
        my ($self, $pos, $whence) = @_;

        (not $self->_is_number($pos) or not $self->_is_number($whence))
          && return Sidef::Types::Bool::Bool->false;

        Sidef::Types::Bool::Bool->new(seek($self->{fh}, $$pos, $$whence));
    }

    sub sysseek {
        my ($self, $pos, $whence) = @_;

        (not $self->_is_number($pos) or not $self->_is_number($whence))
          && return Sidef::Types::Bool::Bool->false;

        Sidef::Types::Bool::Bool->new(sysseek($self->{fh}, $$pos, $$whence));
    }

    *sysSeek = \&sysseek;

    sub fileno {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(fileno($self->{fh}));
    }

    sub lock {
        my ($self) = @_;

        require Fcntl;
        $self->flock(Sidef::Types::Number::Number->new(&Fcntl::LOCK_EX));
    }

    sub unlock {
        my ($self) = @_;

        require Fcntl;
        $self->flock(Sidef::Types::Number::Number->new(&Fcntl::LOCK_UN));
    }

    sub flock {
        my ($self, $mode) = @_;
        $self->_is_number($mode) || return;
        Sidef::Types::Bool::Bool->new(CORE::flock($self->{fh}, $$mode));
    }

    sub close {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(close $self->{fh});
    }

    sub stat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->stat($self->{fh}, $self);
    }

    sub lstat {
        my ($self) = @_;
        Sidef::Types::Glob::Stat->lstat($self->{fh}, $self);
    }

    sub truncate {
        my ($self, $length) = @_;
        $self->_is_number($length) || return;
        Sidef::Types::Bool::Bool->new(CORE::truncate($self->{fh}, $length));
    }

    sub separator {
        my ($self, $sep) = @_;
        $self->_is_string($sep) || return;

        my $old_sep = $/;
        $/ = $$sep;

        Sidef::Types::String::String->new($old_sep);
    }

    *sep             = \&separator;
    *input_separator = \&separator;
    *inputSeparator  = \&separator;

};

1
