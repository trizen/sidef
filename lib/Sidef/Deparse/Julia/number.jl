
#
## Number methods
#

for sym in Symbol[:+, :-, :*, :/, ://, :%, :|, :&, :^, :$]
    @eval function $sym(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
        Sidef_Types_Number_Number($sym(a.value, b.value))
    end
end

for sym in Symbol[:<=, :>=, :<, :>]
    @eval function $sym(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
        ($sym(a.value, b.value)) ? TRUE : FALSE
    end
end

function eq(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    (a.value == b.value) ? TRUE : FALSE
end

function eq(::Sidef_Types_Number_Number, ::Sidef_Object)
    FALSE
end

function ne(a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    (a.value != b.value) ? TRUE : FALSE
end

function ne(::Sidef_Types_Number_Number, ::Sidef_Object)
    TRUE
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

function floor(n::Sidef_Types_Number_Number)
    Sidef_Types_Number_Number(floor(n.value))
end

function range(to::Sidef_Types_Number_Number)
    Sidef_Types_Range_RangeNumber(ZERO, dec(to))
end

function range(from::Sidef_Types_Number_Number, to::Sidef_Types_Number_Number)
    Sidef_Types_Range_RangeNumber(from, to)
end

function range(from::Sidef_Types_Number_Number, to::Sidef_Types_Number_Number, step::Sidef_Types_Number_Number)
    Sidef_Types_Range_RangeNumber(from, to, step)
end

function inc(n::Sidef_Types_Number_Number)
    Sidef_Types_Number_Number(n.value+1)
end

function dec(n::Sidef_Types_Number_Number)
    Sidef_Types_Number_Number(n.value-1)
end

function ..(from::Sidef_Types_Number_Number, to::Sidef_Types_Number_Number)
    arr = Any[]
    for i in from.value:to.value
        push!(arr, Sidef_Types_Number_Number(i))
    end
    Sidef_Types_Array_Array(arr)
end

function of(n::Sidef_Types_Number_Number, block::Sidef_Types_Block_Block)
    arr = Any[]
    block = block.value
    for i in 1:n.value
        push!(arr, block(Sidef_Types_Number_Number(i)))
    end
    Sidef_Types_Array_Array(arr)
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

function excl(a::Sidef_Types_Number_Number)
    (a.value == 0) ? TRUE : FALSE
end

function string(a::Sidef_Types_Number_Number)
    string(a.value)
end
