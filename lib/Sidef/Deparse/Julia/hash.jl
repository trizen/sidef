
#
## Hash methods
#

function call(::Type{Sidef_Types_Hash_Hash}, s::Any...)
    d = Dict{Any,Any}()
    for i in 1:2:length(s)
        d[s[i]] = s[i+1]
    end
    Sidef_Types_Hash_Hash(d)
end

function getindex(h::Sidef_Types_Hash_Hash, k::Any)
    (h.value)[k]
end

function setindex!(h::Sidef_Types_Hash_Hash, v::Any, k::Any)
    (h.value)[k] = v
end
