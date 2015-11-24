#!/usr/bin/perl6

#
## Boolean type
#
class Sidef::Types::Bool::Bool {
    has Bool $.value;
}

#
## String type + methods
#
class Sidef::Types::String::String {
    has Str $.value;

    method concat(Sidef::Types::String::String $arg) {
        Sidef::Types::String::String.new(value => $.value ~ $arg.value);
    }

    method say() {
        $.concat(Sidef::Types::String::String.new(value => "\n")).print;
    }

    method print() {
        Sidef::Types::Bool::Bool.new(value => print $.value);
    }
}

class Interpreter {

    #
    ## Expression executor
    #
    method execute_expr($statement) {
        defined($statement<self>) or die "Invalid AST!";
        my $self_obj = $statement<self>;

        if $self_obj.isa(Hash) {
            $self_obj = $.execute($self_obj);
        }

        if defined($statement<call>) {
            for @($statement<call>) -> $call {

                my $meth = $call<method>;
                if defined($call<arg>) {
                    my $args = $call<arg>.map({
                        $_.isa(Hash) ?? $.execute($_) !! $_
                    });
                    $self_obj = $self_obj."$meth"(|$args);
                }
                else {
                    $self_obj = $self_obj."$meth"();
                }
            }
        }

        return $self_obj;
    }

    #
    ## Parse-tree executor
    #
    method execute($structure) {
        my $result;
        defined($structure<main>) or die "Invalid AST!";
        for @($structure<main>) -> $statement {
            $result = $.execute_expr($statement);
        }
        return $result;
    }
}

 my $ast =  {
  main => [
    {
      self => {
        main => [
          {
            self => {
              main => [
                {
                  call => [{ method => "print" }],
                  self => {
                            main => [
                              {
                                call => [
                                          {
                                            arg => [
                                              {
                                                main => [
                                                  {
                                                    self => {
                                                      main => [
                                                        { self => Sidef::Types::String::String.bless(value => "llo") },
                                                      ],
                                                    },
                                                  },
                                                ],
                                              },
                                            ],
                                            method => "concat",
                                          },
                                        ],
                                self => Sidef::Types::String::String.bless(value => "He"),
                              },
                            ],
                          },
                },
              ],
            },
          },
        ],
      },
    },
    {
      self => {
        main => [
          {
            self => {
              main => [
                {
                  call => [{ method => "say" }],
                  self => {
                            main => [
                              { self => Sidef::Types::String::String.bless(value => " world!") },
                            ],
                          },
                },
              ],
            },
          },
        ],
      },
    },
  ],
};


#
## Begin execution
#
my $intr = Interpreter.new;
$intr.execute($ast);
