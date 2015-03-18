#!/usr/bin/julia

import Base.print;

#
## Boolean type
#
type SBool
    value::Bool;

    function SBool(b::Bool)
        this = new();
        this.value = b;
        return this;
    end
end

#
## String type
#
type SString
    value::String;

    function SString(s::String)
        this = new();
        this.value = s;
        return this;
    end
end

#
## String methods
#
function say(s::SString)
    println(s.value);
    SBool(true);
end

function print(s::SString)
    print(s.value);
    SBool(true);
end

function +(a::SString, b::SString)
    SString(a.value * b.value);
end

#
## Expression executor
#
function execute_expr(statement)
    if haskey(statement, :self)
        self = statement[:self];

        if isa(self, Dict)
            self = execute(self);
        end

        if haskey(statement, :call)
            for call in statement[:call]
                method = symbol(call[:method]);

                if haskey(call, :arg)

                    # Evaluate and collect the arguments
                    args = Any[];
                    for arg in call[:arg]
                        if isa(arg, Dict)
                            push!(args, execute_expr(arg))
                        else
                            push!(args, arg);
                        end
                    end

                    # Call method with arguments
                    self = eval(:($method($self, $args...)));
                else
                    # Call method without arguments
                    self = eval(:($method($self)));
                end
            end
        end

        return(self);
    end
end

#
## Parse-tree executor
#
function execute(structure)
    results = Any[];
    for statement in structure[:main]
        push!(results, execute_expr(statement));
    end
    results[end];
end


#
## The AST
#
structure = {
    :main => [
        {
            :call => [{:method => "print"}],
            :self => {
                :main => [
                    {
                        :call => [{:method => "+", :arg => [{:self => SString("llo")}]}],
                        :self => SString("he"),
                    }
                ],
            }
        },
        {
            :call => [{:method => "say"}],
            :self => SString(" world!");
        },
    ]
};

#
## Begin execution
#
execute(structure);
