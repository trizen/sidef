
#
## String methods
#

function +(a::Sidef_Types_String_String, b::Sidef_Types_String_String)
    Sidef_Types_String_String(a.value * b.value)
end

function *(a::Sidef_Types_String_String, b::Sidef_Types_Number_Number)
    Sidef_Types_String_String(repeat(a.value, Int(b.value)))
end

function eq(a::Sidef_Types_String_String, b::Sidef_Types_String_String)
    (a.value == b.value) ? TRUE : FALSE
end

function eq(::Sidef_Types_String_String, ::Sidef_Object)
    FALSE
end

function ne(a::Sidef_Types_String_String, b::Sidef_Types_String_String)
    (a.value != b.value) ? TRUE : FALSE
end

function ne(::Sidef_Types_String_String, ::Sidef_Object)
    TRUE
end

function string(s::Sidef_Types_String_String)
    s.value
end
