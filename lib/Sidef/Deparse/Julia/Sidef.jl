
#
## Sidef base
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
       Base.abs,
       Base.min,
       Base.sqrt,
       Base.print,
       Base.println,
       Base.setindex!,
       Base.getindex;

abstract Sidef_Object
abstract Sidef_Types_Nil_Nil
abstract Sidef_Types_Number_Complex

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

const NIL = Sidef_Types_Nil_Nil

const MONE = Sidef_Types_Number_Number(-1)
const ZERO = Sidef_Types_Number_Number(0)
const ONE = Sidef_Types_Number_Number(1)

include("object.jl")
include("number.jl")
include("hash.jl")
include("complex.jl")
include("block.jl")
include("range.jl")
include("string.jl")
include("array.jl")
