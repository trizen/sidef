

#
## Nil methods
#

function excl(::Sidef_Types_Nil_Nil)
    TRUE
end

function eq(::Sidef_Types_Nil_Nil, ::Sidef_Types_Nil_Nil)
    TRUE
end

function ne(::Sidef_Types_Nil_Nil, ::Sidef_Types_Nil_Nil)
    FALSE
end
