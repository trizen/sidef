
#
## String methods
#

function +(a::Sidef_Types_String_String, b::Sidef_Types_String_String)
    Sidef_Types_String_String(a.value * b.value)
end

function *(a::Sidef_Types_String_String, b::Sidef_Types_Number_Number)
    Sidef_Types_String_String(repeat(a.value, Int(b.value)))
end

function ==(a::Sidef_Types_String_String, b::Sidef_Types_String_String)
    a.value == b.value
end
