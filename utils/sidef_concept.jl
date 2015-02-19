#!/usr/bin/julia

# Sidef concept expressed in Julia

import Base.int
import Base.sqrt

type S_Number
    value::Number;

    function S_Number(x::Number)
        this = new();
        this.value = x;
        return this;
    end
end

# S_number / S_Number
function /(x::S_Number, y::S_Number)
    S_Number(x.value / y.value);
end

# int(S_Number)
function int(x::S_Number)
    S_Number(int(x.value));
end

# sqrt(S_Number)
function sqrt(x::S_Number)
    S_Number(sqrt(x.value));
end

{
    n1 = S_Number(42);
    n2 = S_Number(2);

    println(n1);
    println(n2);

    println(n1 / n2);

    method = symbol("/");
    println(eval(:($method(n1, n2))));
}

#########################################

{
    div = symbol("/");
    x   = S_Number(12);
    y   = S_Number(4);
    println("$x / $y == ", eval(:($div(x, y))));
}

code = "25.3->int->sqrt";

if (m = match(r"\G(\d+(?:\.\d+)?)", code)) != nothing
    str = m.captures[1];
    num = S_Number(float(str));
    pos = length(str)+1;

    while (m = match(r"\G(->|\.)", code, pos)) != nothing
        pos += length(m.captures[1]);
        if (m = match(r"\G(\w+)", code, pos)) != nothing
            cap = m.captures[1];
            pos += length(cap);
            method = symbol(cap);
            print(num, "->", cap);
            num = eval(:($method(num)));
            println(" == ", num);
        end
    end

end

#=
__END__

abstract Animal

type Horse <: Animal
  name::String
end

run(::Animal) = println("Run, animal, run")

function //(z::Horse)
    println("Run horse, run")
    println(z.name)
end

foo = Horse("Horsie");
//(foo);
=#
