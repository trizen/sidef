package Sidef::Sys::Sys {

    use 5.014;
    our @ISA = qw(Sidef);

    sub new {
        CORE::bless {}, __PACKAGE__;
    }

    sub exit {
        my ($self, $code) = @_;
        exit($code // 0);
    }

    sub alarm {
        my ($self, $sec) = @_;
        $self->_is_number($sec) || return;
        Sidef::Types::Bool::Bool->new(CORE::alarm($$sec));
    }

    sub ualarm {
        my ($self, $sec) = @_;

        $self->_is_number($sec) || return;

        require Time::HiRes;
        Sidef::Types::Bool::Bool->new(Time::HiRes::ualarm($$sec));
    }

    sub sleep {
        my ($self, $sec) = @_;
        $self->_is_number($sec) || return;
        Sidef::Types::Bool::Bool->new(CORE::sleep($$sec));
    }

    sub nanosleep {
        my ($self, $sec) = @_;

        $self->_is_number($sec) || return;

        require Time::HiRes;
        Sidef::Types::Bool::Bool->new(Time::HiRes::nanosleep($$sec));
    }

    *nanoSleep = \&nanosleep;

    sub usleep {
        my ($self, $sec) = @_;

        $self->_is_number($sec) || return;

        require Time::HiRes;
        Sidef::Types::Bool::Bool->new(Time::HiRes::usleep($$sec));
    }

    sub osname {
        my ($self) = @_;
        Sidef::Types::String::String->new($^O);
    }

    *osName = \&osname;

    sub user {
        my ($self) = @_;
        Sidef::Types::String::String->new(getlogin);
    }

    sub umask {
        my ($self, $mode) = @_;

        if (defined($mode)) {
            $self->_is_number($mode) || return;
            return Sidef::Types::Number::Number->new(CORE::umask($$mode));
        }

        Sidef::Types::Number::Number->new(CORE::umask);
    }

    sub ref {
        my ($self, $obj) = @_;
        Sidef::Types::String::String->new(CORE::ref $obj);
    }

    sub sidef {
        my ($self) = @_;

        require File::Spec;
        Sidef::Types::String::String->new(File::Spec->rel2abs($0));
    }

    sub die {
        my ($self, @args) = @_;
        CORE::die(@args);
    }

    sub warn {
        my ($self, @args) = @_;
        CORE::warn(@args);
    }

    sub print {
        my ($self, @args) = @_;
        Sidef::Types::Bool::Bool->new(print @args);
    }

    sub printf {
        my ($self, @args) = @_;
        Sidef::Types::Bool::Bool->new(printf @args);
    }

    sub printh {
        my ($self, $fh, @args) = @_;

        if (CORE::ref($fh) eq 'GLOB') {
            return Sidef::Types::Bool::Bool->new(print {$fh} @args);
        }
        elsif (eval { $fh->can('print') || $fh->can('AUTOLOAD') }) {
            return $fh->print(@args);
        }

        CORE::warn "[WARN] Sys.printh(): invalid object handle: `$fh'\n";
        return;
    }

    sub println {
        my ($self, @args) = @_;
        Sidef::Types::Bool::Bool->new(say @args);
    }

    *say = \&println;

    sub scanln {
        my ($self, $text) = @_;

        if (defined($text)) {
            $self->_is_string($text) || return;
            $text->print;
        }

        Sidef::Types::String::String->new(scalar unpack("A*", scalar <STDIN>));
    }

    sub open {
        my ($self, $var, $mode, $filename) = @_;
        $filename->to_file->open($mode, $var);
    }

    sub opendir {
        my ($self, $var, $dirname) = @_;
        $dirname->to_dir->open($var);
    }

    sub eval {
        my ($self, $perl_code) = @_;
        $self->_is_string($perl_code);

        my $result = eval $perl_code;

        my $guess_type;
        $guess_type = sub {
            my ($val) = @_;

            my $ref = CORE::ref($val);
            if ($ref eq 'ARRAY') {
                my $array = Sidef::Types::Array::Array->new;
                foreach my $item (@{$val}) {
                    $array->push($guess_type->($item));
                }
                return $array;
            }
            elsif ($ref eq 'HASH') {
                my $hash = Sidef::Types::Hash::Hash->new;
                while (my ($key, $value) = each %{$val}) {
                    $hash->append($key, $guess_type->($value));
                }
                return $hash;
            }
            elsif ($ref eq 'Regexp') {
                return Sidef::Types::Regex::Regex->new($val);
            }
            elsif ($ref eq '') {
                require Scalar::Util;

                if (Scalar::Util::looks_like_number($val)) {
                    return Sidef::Types::Number::Number->new($val);
                }
            }

            return CORE::ref($val) ? $val : Sidef::Types::String::String->new($val);
        };

        $guess_type->($result);
    }

    sub bless {
        my ($self, $obj, $class) = @_;
        CORE::bless $obj, $class;
    }

    sub system {
        my ($self, @args) = @_;

        foreach my $cmd (@args) {
            $self->_is_string($cmd) || return;
        }

        Sidef::Types::Number::Number->new(CORE::system(@args));
    }

    *run = \&system;

    sub exec {
        my ($self, $command) = @_;
        $self->_is_string($command) || return;
        CORE::exec($$command);
    }

};

1
