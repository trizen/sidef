
#
## Object methods
#

function say(s::Sidef_Object...)
    for item in s
        print(string(item))
    end
    println()
end

function print(s::Sidef_Object)
    print(s.value)
end

function ifelse(b::Sidef_Types_Bool_Bool, x::Any, y::Any)
    b.value ? x : y
end
