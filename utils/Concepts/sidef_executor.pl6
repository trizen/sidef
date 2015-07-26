#!/usr/bin/perl6

#
## Boolean type
#
class SBool {
    has Bool $.value;
}

#
## String type + methods
#
class SString {
    has Str $.value;

    method concat(SString $arg) {
        SString.new(value => $.value ~ $arg.value);
    }

    method say() {
        $.concat(SString.new(value => "\n")).print;
    }

    method print() {
        SBool.new(value => print $.value);
    }
}

class Interpreter {

    #
    ## Expression executor
    #
    method execute_expr($statement) {
        "self" ~~ $statement or die "Invalid AST!";
        my $self_obj = $statement<self>;

        if $self_obj.isa(Hash) {
            $self_obj = $.execute($self_obj);
        }

        if "call" ~~ $statement {
            for @($statement<call>) -> $call {

                my $meth = $call<method>;
                if "arg" ~~ $call {
                    my $args = $call<arg>.map({
                        $_.isa(Hash) ?? $.execute_expr($_) !! $_
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
        "main" ~~ $structure or die "Invalid AST!";
        for @($structure<main>) -> $statement {
            $result = $.execute_expr($statement);
        }
        return $result;
    }
}

my $ast = {
    main => [
        {
            call => [{method => "print"}],
            self => {
                main => [
                    {
                        call => [{method => "concat", arg => [{self => SString.new(value => "llo")}]}],
                        self => SString.new(value => "he"),
                    }
                ],
            }
        },
        {
            call => [{method => "say"}],
            self => SString.new(value => " world!");
        },
    ]
};

#
## Begin execution
#
my $intr = Interpreter.new;
$intr.execute($ast);
