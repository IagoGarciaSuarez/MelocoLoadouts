-- Profiles.lua

function Melocoloadouts:SaveProfile(profileName)
    if not profileName or profileName == "" then
        print("|cffff4444Melocoloadouts: Invalid profile name.|r")
        return
    end

    MelocoloadoutsDB.profiles = MelocoloadoutsDB.profiles or {}

    local currentSpecIndex = GetSpecialization()
    local currentSpecID = nil
    local currentSpecName = nil

    if currentSpecIndex then
        currentSpecID, currentSpecName = GetSpecializationInfo(currentSpecIndex)
    end

    local equipmentSetID, equipmentSetName = nil, nil
    if self.GetCurrentEquipmentSet then
        equipmentSetID, equipmentSetName = self:GetCurrentEquipmentSet()
    end

    local talentLoadoutID, talentLoadoutName = nil, nil
    if self.GetCurrentTalentLoadout then
        talentLoadoutID, talentLoadoutName = self:GetCurrentTalentLoadout()
    end

    local uiLayoutID = nil
    if self.GetCurrentUILayout then
        uiLayoutID = self:GetCurrentUILayout()
    end

    local profile = {
        name = profileName,

        specIndex = currentSpecIndex,
        specID = currentSpecID,
        specName = currentSpecName,

        equipmentSetID = equipmentSetID,
        equipmentSetName = equipmentSetName,

        talentLoadoutID = talentLoadoutID,
        talentLoadoutName = talentLoadoutName,

        uiLayoutID = uiLayoutID,
    }

    MelocoloadoutsDB.profiles[profileName] = profile

    print("|cff00ff00Melocoloadouts: Profile saved:|r " .. profileName)
end

function Melocoloadouts:GetProfile(profileName)
    if not MelocoloadoutsDB or not MelocoloadoutsDB.profiles then
        return nil
    end

    return MelocoloadoutsDB.profiles[profileName]
end

function Melocoloadouts:DeleteProfile(profileName)
    if not MelocoloadoutsDB or not MelocoloadoutsDB.profiles then
        return
    end

    MelocoloadoutsDB.profiles[profileName] = nil
    print("|cffffaa00Melocoloadouts: Profile deleted:|r " .. profileName)
end

function Melocoloadouts:GetCurrentProfileSnapshot()
    local currentSpecIndex = GetSpecialization()
    local currentSpecID, currentSpecName = nil, nil

    if currentSpecIndex then
        currentSpecID, currentSpecName = GetSpecializationInfo(currentSpecIndex)
    end

    local equipmentSetID, equipmentSetName = nil, nil
    if self.GetCurrentEquipmentSet then
        equipmentSetID, equipmentSetName = self:GetCurrentEquipmentSet()
    end

    local talentLoadoutID, talentLoadoutName = nil, nil
    if self.GetCurrentTalentLoadout then
        talentLoadoutID, talentLoadoutName = self:GetCurrentTalentLoadout()
    end

    local uiLayoutID = nil
    if self.GetCurrentUILayout then
        uiLayoutID = self:GetCurrentUILayout()
    end

    return {
        specIndex = currentSpecIndex,
        specID = currentSpecID,
        specName = currentSpecName,
        equipmentSetID = equipmentSetID,
        equipmentSetName = equipmentSetName,
        talentLoadoutID = talentLoadoutID,
        talentLoadoutName = talentLoadoutName,
        uiLayoutID = uiLayoutID,
    }
end

function Melocoloadouts:IsProfileActive(profile)
    if not profile then
        return false
    end

    local current = self:GetCurrentProfileSnapshot()

    if profile.specIndex and profile.specIndex ~= current.specIndex then
        return false
    end

    if profile.talentLoadoutName and profile.talentLoadoutName ~= current.talentLoadoutName then
        return false
    end

    if profile.equipmentSetName and profile.equipmentSetName ~= current.equipmentSetName then
        return false
    end

    if profile.uiLayoutID and profile.uiLayoutID ~= current.uiLayoutID then
        return false
    end

    return true
end