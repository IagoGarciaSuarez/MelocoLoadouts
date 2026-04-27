-- Equipment.lua

-- Returns the equipped equipment set ID and name, when one is active.
function MelocoLoadouts:GetCurrentEquipmentSet()
    if not C_EquipmentSet or not C_EquipmentSet.GetEquipmentSetIDs then
        return nil, nil
    end

    local equipmentSetIDs = C_EquipmentSet.GetEquipmentSetIDs()

    if not equipmentSetIDs then
        return nil, nil
    end

    for _, setID in ipairs(equipmentSetIDs) do
        local name, _, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(setID)

        if isEquipped then
            return setID, name
        end
    end

    return nil, nil
end

-- Equips a saved equipment set by ID.
function MelocoLoadouts:ApplyEquipmentSet(setID)
    if not setID then
        return false
    end

    if not C_EquipmentSet or not C_EquipmentSet.UseEquipmentSet then
        return false
    end

    C_EquipmentSet.UseEquipmentSet(setID)
    return true
end
