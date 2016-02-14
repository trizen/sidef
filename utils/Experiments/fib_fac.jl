#!/usr/bin/julia

#
## Sidef translated to Julia
#

# Original code:
#=
func fib(n) {
    n <= 1 ? n : fib(n-1)+fib(n-2)
}

say fib(12)

func fac(n) {
    n == 0 ? 1 : n*fac(n-1)
}

say fac(5)
=#

#
## Manually defined types
#

import Base.-;
import Base.+;
import Base.*;
import Base./;
import Base.<=;
import Base.==;
import Base.print;
import Base.println;

abstract Sidef_Object

type Sidef_Types_Bool_Bool <: Sidef_Object
    value::Bool;

    function Sidef_Types_Bool_Bool(b::Bool)
        this = new();
        this.value = b;
        return this;
    end
end

type Sidef_Types_String_String <: Sidef_Object
    value::AbstractString;

    function Sidef_Types_String_String(s::AbstractString)
        this = new();
        this.value = s;
        return this;
    end
end

type Sidef_Types_Number_Number <: Sidef_Object
    value::Number;

    function Sidef_Types_Number_Number(s::Number)
        this = new();
        this.value = s;
        return this;
    end
end

type Sidef_Types_Block_Block <: Sidef_Object
    value::Function;

    function Sidef_Types_Block_Block(s::Function)
        this = new();
        this.value = s;
        return this;
    end
end

const TRUE = Sidef_Types_Bool_Bool(true)
const FALSE = Sidef_Types_Bool_Bool(false)

#
## Object methods
#
function say(s::Sidef_Object)
    println(s.value)
    TRUE
end

function print(s::Sidef_Object)
    print(s.value)
    TRUE
end

#
## String methods
#
function +(a::Sidef_Types_String_String, b::Sidef_Types_String_String)
    Sidef_Types_String_String(a.value * b.value);
end

#
## Number methods
#
function +(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    Sidef_Types_Number_Number(a.value + b.value);
end

function -(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    Sidef_Types_Number_Number(a.value - b.value);
end

function *(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    Sidef_Types_Number_Number(a.value * b.value);
end

function /(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    Sidef_Types_Number_Number(a.value / b.value);
end

function <=(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    a.value <= b.value ? TRUE : FALSE
end

function ==(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    a.value == b.value ? TRUE : FALSE
end

#
## Block methods
#
function call(a::Sidef_Types_Block_Block, args...)
    (a.value)(args...)
end


#
## Auto-generated code from the AST
#

const Number400107361 = Sidef_Types_Number_Number(1);
const Number443686001 = Sidef_Types_Number_Number(2);
const Number443126481 = Sidef_Types_Number_Number(12);
const Number443108241 = Sidef_Types_Number_Number(0);
const Number442738401 = Sidef_Types_Number_Number(5);

fib43182416 = Function
fac44310128 = Function

fib43182416 = Sidef_Types_Block_Block(function(n)
    n43774744 = n
    (<=((n43774744),((Number400107361))) == TRUE ?begin n43774744 end:begin +((call((fib43182416),(-((n43774744),((Number400107361)))))),(call((fib43182416),(-((n43774744),((Number443686001))))))) end)end);
say(call((fib43182416),((Number443126481))));
fac44310128 = Sidef_Types_Block_Block(function(n)
    n44274512 = n
    (==((n44274512),((Number443108241))) == TRUE ?begin (Number400107361) end:begin *((n44274512),(call((fac44310128),(-((n44274512),((Number400107361))))))) end)end);
say(call((fac44310128),((Number442738401))));
