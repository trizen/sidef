

#
## Conversion methods
#

function convert(::Type{Bool}, ::Sidef_Types_Nil_Nil)
    false
end

function convert(::Type{Bool}, v::Sidef_Types_Bool_Bool)
    v.value
end

function convert(::Type{Bool}, v::Sidef_Types_Number_Number)
    v.value != 0
end

function convert(::Type{Bool}, v::Bool)
    v
end

function convert(::Type{Bool}, v::Any)
    println("Unimplemented conversion of Any $v to Bool")
    false
end
