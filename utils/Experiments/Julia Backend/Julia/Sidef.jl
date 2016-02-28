
#
## Sidef base
#

import Base.-,
       Base.+,
       Base.*,
       Base./,
       Base.//,
       Base.%,
       Base.^,
       Base.$,
       Base.&,
       Base.|,
       Base.<=,
       Base.>=,
       Base.<,
       Base.>,
       #Base.==,
       #Base.!=,
       Base.!,
       Base.abs,
       Base.min,
       Base.map,
       Base.sqrt,
       Base.floor,
       Base.print,
       Base.ifelse,
       Base.string,
       Base.println,
       Base.setindex!,
       Base.getindex;

abstract Sidef_Object
abstract Sidef_Types_Number_Complex

immutable Sidef_Types_Nil_Nil <: Sidef_Object
    value::Void
end

immutable Sidef_Types_Bool_Bool <: Sidef_Object
    value::Bool
end

immutable Sidef_Types_Block_Block <: Sidef_Object
    value::Function
end

immutable Sidef_Types_Number_Number <: Sidef_Object
    value::Number
end

immutable Sidef_Types_String_String <: Sidef_Object
    value::AbstractString
end

immutable Sidef_Types_Range_RangeNumber <: Sidef_Object
    value::Range
end

immutable Sidef_Types_Hash_Hash <: Sidef_Object
    value::Dict{Any,Any}
end

immutable Sidef_Types_Array_Array <: Sidef_Object
    value::Array{Any}
end

const NIL = Sidef_Types_Nil_Nil(Void())

const TRUE = Sidef_Types_Bool_Bool(true)
const FALSE = Sidef_Types_Bool_Bool(false)

const MONE = Sidef_Types_Number_Number(-1)
const ZERO = Sidef_Types_Number_Number(0)
const ONE = Sidef_Types_Number_Number(1)

function interpolate(::Type{Sidef_Types_String_String}, a::Any...)
    str = ""
    for item in a
        str *= string(item)
    end
    Sidef_Types_String_String(str)
end

include("object.jl")
include("bool.jl")
include("nil.jl")
include("number.jl")
include("hash.jl")
include("complex.jl")
include("block.jl")
include("range.jl")
include("string.jl")
include("array.jl")
include("convert.jl")
