

#
## Boolean methods
#

function excl(b::Sidef_Types_Bool_Bool)
    b.value ? FALSE : TRUE
end

function !(b::Sidef_Types_Bool_Bool)
    b.value ? FALSE : TRUE
end
