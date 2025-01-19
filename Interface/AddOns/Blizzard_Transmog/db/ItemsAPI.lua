local addon, ns = ...
local items = ns.items


local function getIndex(array, value)
    for i = 1, #array do
        if array[i] == value then
            return i
        end
    end
    return nil
end


-- Returns all the appearances for the given slot/subclass.
function ns.GetSubclassRecords(whatSlot, whatSubclass)
    assert(type(whatSlot) == "string", "'slot' is mandatroy and must be 'string'.")
    assert(type(whatSubclass) == "string", "'subclass' is mandatroy and must be 'string' but given `"..tostring(whatSubclass).."`.")

    return ItemEx_GetSubclassList(whatSlot, whatSubclass);
end