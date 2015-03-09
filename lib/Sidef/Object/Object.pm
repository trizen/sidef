package Sidef::Object::Object {

    use parent qw(
      Sidef
      Sidef::Convert::Convert
      );

    my $get_value = sub {
        $_[0]->isa('ARRAY') ? ($#{$_[0]} + 1) : $_[0]->get_value;
    };

    # Logical AND
    *{__PACKAGE__ . '::' . '&&'} = sub {
        my ($self, $code) = @_;
        $get_value->($self)
          ? Sidef::Types::Block::Code->new($code)->run
          : $self;
    };

    # Logical OR
    *{__PACKAGE__ . '::' . '||'} = sub {
        my ($self, $code) = @_;
        $get_value->($self)
          ? $self
          : Sidef::Types::Block::Code->new($code)->run;
    };

    # Logical XOR
    *{__PACKAGE__ . '::' . '^'} = sub {
        my ($self, $val) = @_;
        Sidef::Types::Bool::Bool->new($get_value->($self) xor $get_value->($val));
    };

    # Defined-OR
    *{__PACKAGE__ . '::' . '\\\\'} = sub {
        my ($self, $code) = @_;
        ref($self) eq 'Sidef::Types::Nil::Nil'
          ? Sidef::Types::Block::Code->new($code)->run
          : $self;
    };

    # Ternary operator (Obj ? TrueExpr : FalseExpr)
    *{__PACKAGE__ . '::' . '?'} = sub {
        my ($self, $code) = @_;

      #CORE::say ref $self;
      #$get_value->($self)
      #? Sidef::Types::Block::Code->new($code)->run #Sidef::Types::Black::Hole->new(Sidef::Types::Block::Code->new($code)->run)
        Sidef::Types::Bool::Ternary->new(code => $code, bool => $get_value->($self));
    };

    #
    # *{__PACKAGE__ . '::' . '?'} = \&{__PACKAGE__ . '::' . '&&'};
    # *{__PACKAGE__ . '::' . ':'} = \&{__PACKAGE__ . '::' . '||'};

    # Smart match operator
    *{__PACKAGE__ . '::' . '~~'} = sub {
        my ($first, $second) = @_;

        my $f_type = ref($first);
        my $s_type = ref($second);

        # First is String
        if ($f_type eq 'Sidef::Types::String::String') {

            # String ~~ Array
            if ($s_type eq 'Sidef::Types::Array::Array') {
                return $second->contains($first);
            }

            # String ~~ Hash
            if ($s_type eq 'Sidef::Types::Hash::Hash') {
                return $second->exists($first);
            }

            # String ~~ String
            if ($s_type eq 'Sidef::Types::String::String') {
                return $first->contains($second);
            }

            # String ~~ Regex
            if ($s_type eq 'Sidef::Types::Regex::Regex') {
                return $second->match($first)->is_successful;
            }
        }

        # First is Array
        if ($f_type eq 'Sidef::Types::Array::Array') {

            # Array ~~ Array
            if ($s_type eq 'Sidef::Types::Array::Array') {
                return $first->contains_all($second);
            }

            # Array ~~ Regex
            if ($s_type eq 'Sidef::Types::Regex::Regex') {
                return $second->match($first)->is_successful;
            }

            # Array ~~ Hash
            if ($s_type eq 'Sidef::Types::Hash::Hash') {
                return $second->keys->contains_any($first);
            }

            # Array ~~ Any
            return $first->contains($second);
        }

        # First is Hash
        if ($f_type eq 'Sidef::Types::Hash::Hash') {

            # Hash ~~ Array
            if ($s_type eq 'Sidef::Types::Array::Array') {
                return $first->keys->contains_all($second);
            }

            # Hash ~~ Hash
            if ($s_type eq 'Sidef::Types::Hash::Hash') {
                return $first->keys->contains_all($second->keys);
            }

            # Hash ~~ Any
            return $first->exists($second);
        }

        # First is Regex
        if ($f_type eq 'Sidef::Types::Regex::Regex') {

            # Regex ~~ Array
            if ($s_type eq 'Sidef::Types::Array::Array') {
                return $first->match($second)->is_successful;
            }

            # Regex ~~ Hash
            if ($s_type eq 'Sidef::Types::Hash::Hash') {
                return $first->match($second->keys)->is_successful;
            }

            # Regex ~~ Any
            return $first->match($second)->is_successful;
        }

        # Second is Array
        if ($s_type eq 'Sidef::Types::Array::Array') {

            # Any ~~ Array
            return $second->contains($first);
        }

        Sidef::Types::Bool::Bool->false;
    };

    # Negation of smart match
    *{__PACKAGE__ . '::' . '!~'} = sub {
        my ($first, $second) = @_;
        use 5.014;
        state $method = '~~';
        $first->$method($second)->not;
    };
};

1
