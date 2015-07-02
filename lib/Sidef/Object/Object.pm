package Sidef::Object::Object {

    use parent qw(
      Sidef
      Sidef::Convert::Convert
      );

    # Logical AND
    *{__PACKAGE__ . '::' . '&&'} = sub {
        $_[0]
          ? Sidef::Types::Block::Code->new($_[1])->run
          : $_[0];
    };

    # Logical OR
    *{__PACKAGE__ . '::' . '||'} = sub {
        $_[0]
          ? $_[0]
          : Sidef::Types::Block::Code->new($_[1])->run;
    };

    # Logical XOR
    *{__PACKAGE__ . '::' . '^'} = sub {
        Sidef::Types::Bool::Bool->new($_[0] xor $_[1]);
    };

    # Defined-OR
    *{__PACKAGE__ . '::' . '\\\\'} = sub {
        ref($_[0]) eq 'Sidef::Types::Nil::Nil'
          ? Sidef::Types::Block::Code->new($_[1])->run
          : $_[0];
    };

    # Ternary operator (Obj ? TrueExpr : FalseExpr)
    *{__PACKAGE__ . '::' . '?'} = sub {
        Sidef::Types::Bool::Ternary->new(code => $_[1], bool => !!$_[0]);
    };

    # Smart match operator
    *{__PACKAGE__ . '::' . '~~'} = sub {
        my ($first, $second) = @_;

        my $f_type = ref($first);
        my $s_type = ref($second);

        # First is String
        if (   $f_type eq 'Sidef::Types::String::String'
            or $f_type eq 'Sidef::Types::Char::Char'
            or $f_type eq 'Sidef::Types::Glob::File'
            or $f_type eq 'Sidef::Types::Glob::Dir') {

            # String ~~ Array
            if ($s_type eq 'Sidef::Types::Array::Array') {
                return $second->contains($first);
            }

            # String ~~ Range
            if ($s_type eq 'Sidef::Types::Array::Range') {
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

        # First is Number
        if ($f_type eq 'Sidef::Types::Number::Number') {

            # Number ~~ Range
            if ($s_type eq 'Sidef::Types::Array::Range') {
                return $second->contains($first);
            }
        }

        # First is Array
        if ($f_type eq 'Sidef::Types::Array::Array') {

            # Array ~~ Array
            if ($s_type eq 'Sidef::Types::Array::Array') {
                return $second->contains_all($first);
            }

            # Array ~~ Regex
            if ($s_type eq 'Sidef::Types::Regex::Regex') {
                return $second->match($first)->is_successful;
            }

            # Array ~~ Hash
            if ($s_type eq 'Sidef::Types::Hash::Hash') {
                return $second->keys->contains_all($first);
            }

            # Array ~~ Any
            return $first->contains($second);
        }

        # First is Hash
        if ($f_type eq 'Sidef::Types::Hash::Hash') {

            # Hash ~~ Array
            if ($s_type eq 'Sidef::Types::Array::Array') {
                return $second->contains_all($first->keys);
            }

            # Hash ~~ Hash
            if ($s_type eq 'Sidef::Types::Hash::Hash') {
                return $second->keys->contains_all($first->keys);
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
        use 5.014;
        state $method = '~~';
        $_[0]->$method($_[1])->not;
    };
};

1
