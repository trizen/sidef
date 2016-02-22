
#
## Block methods
#

function call(b::Sidef_Types_Block_Block, args...)
    (b.value)(args...)
end

function *(b::Sidef_Types_Block_Block, n::Sidef_Types_Number_Number)
    b = b.value
    for i = 1:Int(n.value)
        b(Sidef_Types_Number_Number(i))
    end
end
