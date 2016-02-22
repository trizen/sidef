
#
## Object methods
#

function say(s::Sidef_Object...)
    for item in s
        print(string(item))
    end
    println()
end

function say(b::Bool)
    println(b ? "true" : "false")
end

function print(s::Sidef_Object)
    print(s.value)
end
