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

say 3**4;
say 3^5;

var (x, z) = (42, 32)
say x-2;
say z;

say sqrt(2)
=#

#
## Manually defined types
#


import Base.-,
       Base.+,
       Base.*,
       Base./,
       Base.//,
       Base.^,
       Base.$,
       Base.&,
       Base.|,
       Base.<=,
       Base.>=,
       Base.<,
       Base.>,
       Base.==,
       Base.!=,
       Base.sqrt,
       Base.print,
       Base.println;

abstract Sidef_Object

immutable Sidef_Types_Bool_Bool <: Sidef_Object
    value::Bool
end

immutable Sidef_Types_String_String <: Sidef_Object
    value::AbstractString
end

immutable Sidef_Types_Number_Number <: Sidef_Object
    value::Number
end

immutable Sidef_Types_Block_Block <: Sidef_Object
    value::Function
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
    Sidef_Types_String_String(a.value * b.value)
end

#
## Number methods
#
for sym in Symbol[:+, :-, :*, :/, ://, :|, :&, :^, :$]
    @eval function $sym(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
        Sidef_Types_Number_Number($sym(a.value, b.value))
    end
end

for sym in Symbol[:<=, :>=, :<, :>]
    @eval function $sym(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
        $sym(a.value, b.value) ? TRUE : FALSE
    end
end

function ==(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    (a.value == b.value) ? TRUE : FALSE
end

function !=(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    (a.value == b.value) ? FALSE : TRUE
end

function sqrt(a::Sidef_Types_Number_Number)
    Sidef_Types_Number_Number(sqrt(a.value))
end

#
## Block methods
#
function call(a::Sidef_Types_Block_Block, args...)
    (a.value)(args...)
end

#
## Auto-generated Julia code from the AST
#

const Number249590641 = Sidef_Types_Number_Number(big"1");
const Number293127921 = Sidef_Types_Number_Number(big"2");
const Number292568401 = Sidef_Types_Number_Number(big"12");
const Number292550161 = Sidef_Types_Number_Number(big"0");
const Number292180321 = Sidef_Types_Number_Number(big"5");
const Number292166401 = Sidef_Types_Number_Number(big"3");
const Number291823281 = Sidef_Types_Number_Number(big"4");
const Number291809601 = Sidef_Types_Number_Number(big"42");
const Number291594241 = Sidef_Types_Number_Number(big"32");

fib28129352 = Function
fac29254320 = Function

(x29180312, z29178800) = (Any,Any)


fib28129352 = Sidef_Types_Block_Block(function(n)
    n28721656 = n
    (<=((n28721656),((Number249590641))) == TRUE ?begin n28721656 end:begin +((call((fib28129352),(-((n28721656),((Number249590641)))))),(call((fib28129352),(-((n28721656),((Number293127921))))))) end)end);
say(call((fib28129352),((Number292568401))));
fac29254320 = Sidef_Types_Block_Block(function(n)
    n29218704 = n
    (==((n29218704),((Number292550161))) == TRUE ?begin (Number249590641) end:begin *((n29218704),(call((fac29254320),(-((n29218704),((Number249590641))))))) end)end);
say(call((fac29254320),((Number292180321))));
say(^(((Number292166401)),((Number291823281))));
say(((Number292166401))$((Number292180321)));
(x29180312, z29178800)=((Number291809601), (Number291594241));
say(-((x29180312),((Number293127921))));
say(z29178800);
say(sqrt(((Number293127921)),));
