package Sidef::Types::Glob::FileHandle {

    use utf8;
    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use Sidef::Types::Bool::Bool;

    sub new {
        my (undef, %opt) = @_;

        bless {
               fh   => $opt{fh},
               self => $opt{self},
              },
          __PACKAGE__;
    }

    sub get_value {
        $_[0]->{fh};
    }

    sub parent {
        $_[0]{self};
    }

    *self = \&parent;

    sub is_on_tty {
        (-t $_[0]{fh}) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *isatty = \&is_on_tty;

    sub stdout {
        __PACKAGE__->new(fh => \*STDOUT);
    }

    sub stderr {
        __PACKAGE__->new(fh => \*STDERR);
    }

    sub stdin {
        __PACKAGE__->new(fh => \*STDIN);
    }

    sub autoflush {
        my ($self, $bool) = @_;
        select((select($self->{fh}), $| = $bool->get_value)[0]);
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

    sub read {
        my ($self, $var_ref, $length, $offset) = @_;

        my $chunk = "$$var_ref";
        my $size = Sidef::Types::Number::Number->new(
            defined($offset)
            ? CORE::read(
                $self->{fh},
                $chunk,
                do {
                    local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                    $length->get_value;
                },
                do {
                    local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                    $offset->get_value;
                  }
              )
            : CORE::read(
                $self->{fh},
                $chunk,
                do {
                    local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                    $length->get_value;
                  }
            )
        );

        $$var_ref = Sidef::Types::String::String->new($chunk);

        return $size;
    }

    sub sysread {
        my ($self, $var_ref, $length, $offset) = @_;

        my $chunk = "$$var_ref";
        my $size = Sidef::Types::Number::Number->new(
            defined($offset)
            ? CORE::sysread(
                $self->{fh},
                $chunk,
                do {
                    local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                    $length->get_value;
                },
                do {
                    local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                    $offset->get_value;
                  }
              )
            : CORE::sysread(
                $self->{fh},
                $chunk,
                do {
                    local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                    $length->get_value;
                  }
            )
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

    sub readline {
        my ($self, $var_ref) = @_;

        if (defined $var_ref) {
            ${$var_ref} =
              (Sidef::Types::String::String->new(CORE::readline($self->{fh}) // return (Sidef::Types::Bool::Bool::FALSE)));
            return (Sidef::Types::Bool::Bool::TRUE);
        }

        Sidef::Types::String::String->new(CORE::readline($self->{fh}) // return);
    }

    *readln    = \&readline;
    *read_line = \&readline;
    *get       = \&readline;
    *line      = \&readline;

    sub read_char {
        my ($self) = @_;

        my $char = getc($self->{fh});
        defined($char)
          ? Sidef::Types::String::String->new($char)
          : ();
    }

    *char = \&read_char;
    *getc = \&read_char;

    sub read_lines {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { chomp($_); Sidef::Types::String::String->new($_) } CORE::readline($self->{fh}));
    }

    *readlines = \&read_lines;
    *lines     = \&read_lines;

    sub grep {
        my ($self, $obj) = @_;

        my $array = Sidef::Types::Array::Array->new;

        if (ref($obj) eq 'Sidef::Types::Regex::Regex') {
            my $re = $obj->{regex};
            while (defined(my $line = CORE::readline($self->{fh}))) {
                chomp($line);
                if ($line =~ $re) {
                    push @{$array}, Sidef::Types::String::String->new($line);
                }
            }
        }
        else {
            while (defined(my $line = CORE::readline($self->{fh}))) {
                chomp($line);
                my $string = Sidef::Types::String::String->new($line);
                push @{$array}, $string if $obj->run($line);
            }
        }

        $array;
    }

    sub map {
        my ($self, $block) = @_;

        my $array = Sidef::Types::Array::Array->new;
        while (defined(my $line = CORE::readline($self->{fh}))) {
            chomp($line);
            push @{$array}, $block->run(Sidef::Types::String::String->new($line));
        }
        $array;
    }

    sub words {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
            map {
                map    { Sidef::Types::String::String->new($_) }
                  grep { $_ ne '' }
                  split(' ', $_)
              } CORE::readline($self->{fh})
        );
    }

    sub chars {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
            map { Sidef::Types::String::String->new($_) } do {
                local $/;
                split(//, scalar CORE::readline($self->{fh}));
              }
        );
    }

    sub each {
        my ($self, $code) = @_;

        while (defined(my $line = CORE::readline($self->{fh}))) {
            if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new($line)))) {
                return $res;
            }
        }

        $self;
    }

    *each_line = \&each;

    sub eof {
        my ($self) = @_;
        (eof $self->{fh}) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub tell {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(tell($self->{fh}));
    }

    sub seek {
        my ($self, $pos, $whence) = @_;
        (
         seek(
             $self->{fh},
             do {
                 local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                 $pos->get_value;
             },
             do {
                 local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                 $whence->get_value;
               }
             )
        )
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub sysseek {
        my ($self, $pos, $whence) = @_;
        (
         sysseek(
             $self->{fh},
             do {
                 local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                 $pos->get_value;
             },
             do {
                 local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                 $whence->get_value;
               }
         )
        )
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub fileno {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(fileno($self->{fh}));
    }

    sub lock {
        my ($self) = @_;

        state $x = require Fcntl;
        $self->flock(Sidef::Types::Number::Number->new(&Fcntl::LOCK_EX));
    }

    sub unlock {
        my ($self) = @_;

        state $x = require Fcntl;
        $self->flock(Sidef::Types::Number::Number->new(&Fcntl::LOCK_UN));
    }

    sub flock {
        my ($self, $mode) = @_;
        (CORE::flock($self->{fh}, $mode->get_value)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub close {
        my ($self) = @_;
        (close $self->{fh}) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
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
        my $len = defined($length)
          ? do {
            local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
            $length->get_value;
          }
          : 0;
        (CORE::truncate($self->{fh}, $len)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    # File copy
    *copy = \&Sidef::Types::Glob::File::copy;
    *cp   = \&copy;

    # File compare
    *compare = \&File::Types::Glob::File::compare;

    sub read_to {
        my ($self, $var_ref) = @_;
        ${$var_ref} = Sidef::Types::String::String->new(
            do {
                chomp(my $line = CORE::readline($self->{fh}));
                $line;
              }
        );
        $self;
    }

    sub write_from {
        my ($self, $string) = @_;
        CORE::print {$self->{fh}} $string;
        $self;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '>>'}  = \&read_to;
        *{__PACKAGE__ . '::' . '»'}  = \&read_to;
        *{__PACKAGE__ . '::' . '<<'}  = \&write_from;
        *{__PACKAGE__ . '::' . '«'}  = \&write_from;
        *{__PACKAGE__ . '::' . '<=>'} = \&compare;
    }

};

1
