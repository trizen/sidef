#!/usr/bin/julia

#
## Sidef translated to Julia
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
       Base.!,
       Base.sqrt,
       Base.print,
       Base.println,
       Base.setindex!,
       Base.getindex;

abstract Sidef_Object
abstract Sidef_Types_Nil_Nil
abstract Sidef_Types_Bool_True
abstract Sidef_Types_Bool_False

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

immutable Sidef_Types_Array_Array <: Sidef_Object
    value::Array{Any}
end

immutable Sidef_Types_Hash_Hash <: Sidef_Object
    value::Dict{Any,Any}
end

const NIL = Sidef_Types_Nil_Nil
const TRUE = Sidef_Types_Bool_True
const FALSE = Sidef_Types_Bool_False

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

function *(a::Sidef_Types_String_String, b::Sidef_Types_Number_Number)
    Sidef_Types_String_String(repeat(a.value, Int(b.value)))
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

for p in Dict{Symbol, Symbol}(
    :+ => :add,
    :- => :sub,
    :* => :mul,
    :/ => :div,
    :^ => :pow,
)
    @eval function $(p.second)(a::Sidef_Types_Number_Number...)
        Sidef_Types_Number_Number(mapreduce((x) -> x.value, $(p.first), a))
    end
end

function !(a::Sidef_Types_Number_Number)
    Sidef_Types_Number_Number(factorial(a.value))
end

#
## Array methods
#

# TODO: Change "Sidef_Types_Array_Array" to "Type{Sidef_Types_Array_Array}"
function call(h::Sidef_Types_Array_Array, v::Any...)
    Sidef_Types_Array_Array(Any[v...])
end

function getindex(a::Sidef_Types_Array_Array, i::Sidef_Types_Number_Number)
    (a.value)[i.value+1]
end

function setindex!(a::Sidef_Types_Array_Array, v::Any, i::Sidef_Types_Number_Number)
    #setindex!(a.value, v, i.value)
    (a.value)[i.value+1] = v
end

#
## Hash methods
#

function call(h::Type{Sidef_Types_Hash_Hash}, s::Any...)
    d = Dict{Any,Any}()
    for i in 1:2:length(s)
        d[s[i]] = s[i+1]
    end
    Sidef_Types_Hash_Hash(d)
end

function getindex(h::Sidef_Types_Hash_Hash, k::Any)
    (h.value)[k]
end

function setindex!(h::Sidef_Types_Hash_Hash, v::Any, k::Any)
    (h.value)[k] = v
end

#
## Block methods
#
function call(b::Sidef_Types_Block_Block, args...)
    (b.value)(args...)
end

function *(b::Sidef_Types_Block_Block, n::Sidef_Types_Number_Number)
    for i = 1:Int(n.value)
        (b.value)(Sidef_Types_Number_Number(i))
    end
end

const Number345121681 = Sidef_Types_Number_Number(big"1");
const Number388550481 = Sidef_Types_Number_Number(big"2");
const Number387990241 = Sidef_Types_Number_Number(big"12");
const Number387972001 = Sidef_Types_Number_Number(big"0");
const Number387602161 = Sidef_Types_Number_Number(big"5");
const Number387588241 = Sidef_Types_Number_Number(big"3");
const Number387245121 = Sidef_Types_Number_Number(big"4");
const Number387231441 = Sidef_Types_Number_Number(big"42");
const Number387016081 = Sidef_Types_Number_Number(big"32");
const Number387002401 = Sidef_Types_Number_Number(big"1"//big"2");
const Number386991841 = Sidef_Types_Number_Number(big"10");
const String386054321 = Sidef_Types_String_String("a");
const String386056001 = Sidef_Types_String_String("b");
const String431397441 = Sidef_Types_String_String("");
const Number429418641 = Sidef_Types_Number_Number(big"123");
const Number417909201 = Sidef_Types_Number_Number(big"99");
const Number428219841 = Sidef_Types_Number_Number(big"7");
const Hash428257680 = Sidef_Types_Hash_Hash
const String433191281 = Sidef_Types_String_String("c");
const String438638641 = Sidef_Types_String_String(" ");
const String438653681 = Sidef_Types_String_String("+");
const String438637441 = Sidef_Types_String_String("-");
const String438667361 = Sidef_Types_String_String("|");
const String438672401 = Sidef_Types_String_String("/");
const Number455838401 = Sidef_Types_Number_Number(big"6");
const true316266241 = Sidef_Types_Bool_Bool(1);
const false316266001 = Sidef_Types_Bool_Bool(0);

fib37669136 = Function
fac38796504 = Function
cuboid43862520 = Function

(x38722496, z38720984) = (Any,Any)
(x38628888) = (Any)
(arr43140128) = (Any)
(h42824928) = (Any)
(a43321864) = (Any)


fib37669136 = Sidef_Types_Block_Block(function(_38260232::Any...)
_anys38260232 = Any[]
for i in 1:(1 - length(_38260232)) push!(_anys38260232, NIL); end
_38260232 = (_38260232..., _anys38260232...)
    n38260952, = _38260232
    (<=((n38260952),(Number345121681)) == TRUE ?begin n38260952 end:begin +((call((fib37669136),-((n38260952),(Number345121681)))),call((fib37669136),-((n38260952),(Number388550481)))) end)end);
say(call((fib37669136),(Number387990241)));
fac38796504 = Sidef_Types_Block_Block(function(_37719184::Any...)
_anys37719184 = Any[]
for i in 1:(1 - length(_37719184)) push!(_anys37719184, NIL); end
_37719184 = (_37719184..., _anys37719184...)
    n38760864, = _37719184
    (==((n38760864),(Number387972001)) == TRUE ?begin (Number345121681) end:begin *((n38760864),call((fac38796504),-((n38760864),(Number345121681)))) end)end);
say(call((fac38796504),(Number387602161)));
say(^(((Number387588241)),(Number387245121)));
say(((Number387588241))$(Number387602161));
(x38722496, z38720984)=((Number387231441), (Number387016081));
say(-((x38722496),(Number388550481)));
say(z38720984);
say(sqrt(((Number388550481)),));
say((Number387002401));
say(/(((Number386991841)),(Number387588241)));
say(add(((Number345121681)),(Number388550481),(Number387588241)));
say(mul(((Number388550481)),(Number387588241),(Number387245121)));
say(pow(((Number388550481)),(Number387588241)));
say(!(((Number387602161)),));
(x38628888)=((Number387231441));
say(x38628888);
(x38628888) += ((Number388550481));
say(x38628888);
(x38628888) //= ((Number387602161));
say(x38628888);
print((String386054321));
print((String386056001));
say((String431397441));
(x38628888) ^= ((Number388550481));
say(x38628888);
(arr43140128)=(Sidef_Types_Array_Array(Any[(Number429418641), (Number417909201), (Number387231441)]));
say(arr43140128[(Number388550481)]);
((arr43140128[(Number388550481)])=((Number428219841)));
say(arr43140128[(Number345121681)]);
say(arr43140128[(Number388550481)]);
(h42824928)=(call(((Hash428257680)),(String386054321),(Number345121681),(String386056001),(Number388550481)));
say(h42824928[(String386054321)]);
say(h42824928[(String386056001)]);
((h42824928[(String433191281)])=((Number387231441)));
say(h42824928[(String433191281)]);
(a43321864)=(call((Sidef_Types_Array_Array(Any[])),(Number345121681),(Number388550481),(Number387588241)));
say(a43321864);
say(a43321864[(Number345121681)]);
((a43321864[(Number388550481)])=((Number387231441)));
cuboid43862520 = Sidef_Types_Block_Block(function(_43864648::Any...)
_anys43864648 = Any[]
for i in 1:(8 - length(_43864648)) push!(_anys43864648, NIL); end
_43864648 = (_43864648..., _anys43864648...)
    x43864056, y43865848, z43866376, s43863288, c43864936, h38760576, v43866664, d43867168, = _43864648
    (x43864056 == NIL) && (x43864056 = (Number345121681));
    (y43865848 == NIL) && (y43865848 = (Number345121681));
    (z43866376 == NIL) && (z43866376 = (Number345121681));
    (s43863288 == NIL) && (s43863288 = (String438638641));
    (c43864936 == NIL) && (c43864936 = (String438653681));
    (h38760576 == NIL) && (h38760576 = (String438637441));
    (v43866664 == NIL) && (v43866664 = (String438667361));
    (d43867168 == NIL) && (d43867168 = (String438672401));
    say((+((+((+((*(((String438638641)),+((z43866376),(Number345121681)))),c43864936)),*((h38760576),x43864056))),c43864936)),);
    *((Sidef_Types_Block_Block(    function(_45086384::Any...)
_anys45086384 = Any[]
for i in 1:(1 - length(_45086384)) push!(_anys45086384, NIL); end
_45086384 = (_45086384..., _anys45086384...)
        i45086528, = _45086384
        say((+((+((+((+((+((*(((String438638641)),+((-((z43866376),i45086528)),(Number345121681)))),d43867168)),*((s43863288),x43864056))),d43867168)),*((s43863288),-((i45086528),(>((i45086528),y43865848) == TRUE ?begin -((i45086528),y43865848) end:begin (Number345121681) end))))),(==((-((i45086528),(Number345121681))),y43865848) == TRUE ?begin c43864936 end:begin (>((i45086528),y43865848) == TRUE ?begin d43867168 end:begin v43866664 end) end))),)    end)),z43866376);
    say((+((+((+((c43864936),*((h38760576),x43864056))),c43864936)),+((*((s43863288),(<((z43866376),y43865848) == TRUE ?begin z43866376 end:begin y43865848 end))),(<((z43866376),y43865848) == TRUE ?begin v43866664 end:begin (==((z43866376),y43865848) == TRUE ?begin c43864936 end:begin d43867168 end) end)))),);
    *((Sidef_Types_Block_Block(    function(_45523240::Any...)
_anys45523240 = Any[]
for i in 1:(1 - length(_45523240)) push!(_anys45523240, NIL); end
_45523240 = (_45523240..., _anys45523240...)
        i45523384, = _45523240
        say((+((+((+((v43866664),*((s43863288),x43864056))),v43866664)),(>((z43866376),y43865848) == TRUE ?begin (>=((i45523384),z43866376) == TRUE ?begin +((*((s43863288),x43864056)),c43864936) end:begin +((*((s43863288),-((y43865848),i45523384))),d43867168) end) end:begin (>((-((y43865848),i45523384)),z43866376) == TRUE ?begin +((*((s43863288),z43866376)),v43866664) end:begin +((*((s43863288),-((y43865848),i45523384))),(==((-((y43865848),i45523384)),z43866376) == TRUE ?begin c43864936 end:begin d43867168 end)) end) end))),)    end)),y43865848);
    say((+((+((c43864936),*((h38760576),x43864056))),c43864936)),)end);
call((cuboid43862520),(Number388550481),(Number387588241),(Number387245121));
call((cuboid43862520),(Number345121681),(Number345121681),(Number345121681));
call((cuboid43862520),(Number455838401),(Number388550481),(Number345121681));
call((cuboid43862520),(Number388550481),(Number387245121),(Number345121681));
say((true316266241));
say((false316266001));
