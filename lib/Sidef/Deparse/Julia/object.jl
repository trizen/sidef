
#
## Object methods
#

function say(s::Sidef_Object)
    println(s.value)
end

function say(b::Bool)
    println(b ? "true" : "false")
end

function print(s::Sidef_Object)
    print(s.value)
end
