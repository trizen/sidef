
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
        $sym(a.value, b.value)
    end
end

function ==(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    a.value == b.value
end

function !=(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    a.value != b.value
end

function sqrt(a::Sidef_Types_Number_Number)
    Sidef_Types_Number_Number(sqrt(a.value))
end

function abs(a::Sidef_Types_Number_Number)
    Sidef_Types_Number_Number(abs(a.value))
end

function min(a::Sidef_Types_Number_Number...)
    Sidef_Types_Number_Number(min(map((x) -> x.value, a)...))
end

function range(from::Sidef_Types_Number_Number, to::Sidef_Types_Number_Number)
    Sidef_Types_Range_RangeNumber(from, to)
end

function range(from::Sidef_Types_Number_Number, to::Sidef_Types_Number_Number, step::Sidef_Types_Number_Number)
    Sidef_Types_Range_RangeNumber(from, to, step)
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
