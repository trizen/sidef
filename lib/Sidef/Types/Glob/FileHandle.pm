package Sidef::Types::Glob::FileHandle {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Object::Object
      );

    use Sidef::Types::Bool::Bool;

    sub new {
        my (undef, $fh, $file) = @_;

        bless {
               fh     => $fh,
               parent => $file,
              },
          __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        $_[0]{fh};
    }

    sub parent {
        $_[0]{parent};
    }

    *file = \&parent;

    sub is_on_tty {
        (-t $_[0]{fh}) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *isatty = \&is_on_tty;

    sub stdout {
        __PACKAGE__->new(\*STDOUT);
    }

    sub stderr {
        __PACKAGE__->new(\*STDERR);
    }

    sub stdin {
        __PACKAGE__->new(\*STDIN);
    }

    sub autoflush {
        my ($self, $bool) = @_;
        select((select($self->{fh}), $| = $bool ? 1 : 0)[0]);
        $bool;
    }

    sub binmode {
        my ($self, $encoding) = @_;
        CORE::binmode($self->{fh}, "$encoding");
    }

    sub syswrite {
        my ($self, @args) = @_;
        (CORE::syswrite $self->{fh}, @args) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub print {
        my ($self, @args) = @_;
        (CORE::print {$self->{fh}} @args) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *write = \&print;
    *spurt = \&print;

    sub println {
        my ($self, @args) = @_;
        (CORE::say {$self->{fh}} @args) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *say = \&println;

    sub printf {
        my ($self, @args) = @_;
        (CORE::printf {$self->{fh}} @args) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub iter {
        my ($self) = @_;
        Sidef::Types::Block::Block->new(
            code => sub {
                my $line = CORE::readline($self->{fh}) // return undef;
                chomp($line);
                Sidef::Types::String::String->new($line);
            }
        );
    }

    sub fcntl {
        my ($self, $func, $flags) = @_;
        CORE::fcntl($self->{fh}, CORE::int($func), CORE::int($flags))
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub read {
        my ($self, $var_ref, $length, $offset) = @_;

        my $chunk = "$$var_ref";
        my $size = Sidef::Types::Number::Number->new(
                                                     defined($offset)
                                                     ? CORE::read($self->{fh}, $chunk, $length, $offset)
                                                     : CORE::read($self->{fh}, $chunk, $length)
                                                    );

        $$var_ref = Sidef::Types::String::String->new($chunk);

        return $size;
    }

    sub sysread {
        my ($self, $var_ref, $length, $offset) = @_;

        my $chunk = "$$var_ref";
        my $size = Sidef::Types::Number::Number->new(
                                                     defined($offset)
                                                     ? CORE::sysread($self->{fh}, $chunk, $length, $offset)
                                                     : CORE::sysread($self->{fh}, $chunk, $length)
                                                    );

        $$var_ref = Sidef::Types::String::String->new($chunk);

        return $size;
    }

    sub slurp {
        my ($self) = @_;
        Sidef::Types::String::String->new(
            do {
                local $/;
                CORE::readline($self->{fh});
            }
        );
    }

    sub read_line {
        my ($self, $var_ref) = @_;

        my $line = CORE::readline($self->{fh});

        if (defined $var_ref) {
            $line // return Sidef::Types::Bool::Bool::FALSE;
            chomp($line);
            $$var_ref = Sidef::Types::String::String->new($line);
            return Sidef::Types::Bool::Bool::TRUE;
        }

        $line // return undef;
        chomp($line);
        Sidef::Types::String::String->new($line);
    }

    *readln   = \&read_line;
    *readline = \&read_line;
    *get      = \&read_line;
    *line     = \&read_line;

    sub read_char {
        my ($self, $var_ref) = @_;

        my $char = CORE::getc($self->{fh});

        if (defined $var_ref) {
            $$var_ref = Sidef::Types::String::String->new($char // return Sidef::Types::Bool::Bool::FALSE);
            return Sidef::Types::Bool::Bool::TRUE;
        }

        Sidef::Types::String::String->new($char // return undef);
    }

    *char = \&read_char;
    *getc = \&read_char;

    sub read_lines {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
                                       [map { chomp($_); Sidef::Types::String::String->new($_) } CORE::readline($self->{fh})]);
    }

    *readlines = \&read_lines;
    *lines     = \&read_lines;

    sub grep {
        my ($self, $obj) = @_;

        my @array;

        while (defined(my $line = CORE::readline($self->{fh}))) {
            chomp($line);
            my $string = Sidef::Types::String::String->new($line);
            push @array, $string if $obj->run($string);
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    *select = \&grep;

    sub map {
        my ($self, $block) = @_;

        my @array;
        while (defined(my $line = CORE::readline($self->{fh}))) {
            chomp($line);
            push @array, $block->run(Sidef::Types::String::String->new($line));
        }
        Sidef::Types::Array::Array->new(\@array);
    }

    *collect = \&map;

    sub words {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
            [
             map {
                 map    { Sidef::Types::String::String->new($_) }
                   grep { $_ ne '' }
                   split(' ', $_)
             } CORE::readline($self->{fh})
            ]
        );
    }

    sub chars {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
            [
             map { Sidef::Types::String::String->new($_) } do {
                 local $/;
                 split(//, scalar CORE::readline($self->{fh}));
             }
            ]
        );
    }

    sub each {
        my ($self, $code) = @_;

        while (defined(my $line = CORE::readline($self->{fh}))) {
            chomp($line);
            $code->run(Sidef::Types::String::String->new($line));
        }

        $self;
    }

    *each_line = \&each;

    sub each_char {
        my ($self, $code) = @_;

        while (defined(my $char = CORE::getc($self->{fh}))) {
            $code->run(Sidef::Types::String::String->new($char));
        }

        $self;
    }

    sub eof {
        my ($self) = @_;
        CORE::eof($self->{fh})
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub tell {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::tell($self->{fh}));
    }

    sub seek {
        my ($self, $pos, $whence) = @_;
        CORE::seek($self->{fh}, $pos, $whence)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub sysseek {
        my ($self, $pos, $whence) = @_;
        CORE::sysseek($self->{fh}, $pos, $whence)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub fileno {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::fileno($self->{fh}));
    }

    sub lock {
        my ($self) = @_;

        state $x = require Fcntl;
        $self->flock(&Fcntl::LOCK_EX);
    }

    sub unlock {
        my ($self) = @_;

        state $x = require Fcntl;
        $self->flock(&Fcntl::LOCK_UN);
    }

    sub flock {
        my ($self, $mode) = @_;
        CORE::flock($self->{fh}, $mode)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub close {
        my ($self) = @_;
        CORE::close($self->{fh})
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
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
        CORE::truncate($self->{fh}, $length // 0)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub read_to {
        my ($self, $var_ref) = @_;

        my $line = CORE::readline($self->{fh});

        if (defined($line)) {
            chomp($line);
            $$var_ref = Sidef::Types::String::String->new($line);
        }
        else {
            undef $$var_ref;
        }

        $self;
    }

    sub write_from {
        my ($self, $string) = @_;
        CORE::print {$self->{fh}} $string;
        $self;
    }

    sub copy {
        my ($self, $fh) = @_;

        if (ref($fh) ne __PACKAGE__) {
            return;
        }

        state $x = require File::Copy;
        File::Copy::copy($self->{fh}, $fh->{fh})
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *cp = \&copy;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '>>'} = \&read_to;
        *{__PACKAGE__ . '::' . '»'}  = \&read_to;
        *{__PACKAGE__ . '::' . '<<'} = \&write_from;
        *{__PACKAGE__ . '::' . '«'}  = \&write_from;
    }

};

1
