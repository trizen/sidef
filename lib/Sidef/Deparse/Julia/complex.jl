
#
## Complex methods
#

function call(::Type{Sidef_Types_Number_Complex}, a::Sidef_Types_Number_Number, b::Sidef_Types_Number_Number)
    Sidef_Types_Number_Number(Complex(a.value, b.value))
end
