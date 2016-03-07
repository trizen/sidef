package Sidef::Types::Glob::Fcntl {

    require Fcntl;

    my %cache;
    foreach my $name (@Fcntl::EXPORT, @Fcntl::EXPORT_OK) {
        $name =~ /^[a-z]/i or next;
        *{__PACKAGE__ . '::' . $name} = sub {
            $cache{$name} //= Sidef::Types::Number::Number->new(&{'Fcntl::' . $name});
        };
    }
}

1;
