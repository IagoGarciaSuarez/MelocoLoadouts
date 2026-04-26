-- Equipment.lua

function Melocoloadouts:GetCurrentEquipmentSet()
    if not C_EquipmentSet or not C_EquipmentSet.GetEquipmentSetIDs then
        return nil, nil
    end

    local equipmentSetIDs = C_EquipmentSet.GetEquipmentSetIDs()

    if not equipmentSetIDs then
        return nil, nil
    end

    for _, setID in ipairs(equipmentSetIDs) do
        local name, iconFileID, setIDFromInfo, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(setID)

        if isEquipped then
            return setID, name
        end
    end

    return nil, nil
end

function Melocoloadouts:ApplyEquipmentSet(setID)
    if not setID then
        return false
    end

    if C_EquipmentSet and C_EquipmentSet.UseEquipmentSet then
        C_EquipmentSet.UseEquipmentSet(setID)
        return true
    end

    return false
end