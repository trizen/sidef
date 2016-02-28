
#
## Range methods
#

function call(::Type{Sidef_Types_Range_RangeNumber}, from::Sidef_Types_Number_Number, to::Sidef_Types_Number_Number, step::Sidef_Types_Number_Number=ONE)
    Sidef_Types_Range_RangeNumber(from.value:step.value:to.value)
end

function each(r::Sidef_Types_Range_RangeNumber, b::Sidef_Types_Block_Block)
    code = b.value
    for i in r.value
        (code)(Sidef_Types_Number_Number(i))
    end
end
