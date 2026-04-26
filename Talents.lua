-- Talents.lua

function Melocoloadouts:GetCurrentTalentLoadout()
    local currentSpecIndex = GetSpecialization()
    if not currentSpecIndex then
        return nil, nil
    end

    local specID = GetSpecializationInfo(currentSpecIndex)
    if not specID then
        return nil, nil
    end

    local configID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
    if not configID then
        return nil, nil
    end

    local configInfo = C_Traits.GetConfigInfo(configID)
    local configName = configInfo and configInfo.name or nil

    return configID, configName
end

function Melocoloadouts:FindTalentLoadoutByName(loadoutName, specID)
    if not loadoutName or loadoutName == "" then
        return nil
    end

    local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)
    if not configIDs then
        return nil
    end

    for _, configID in ipairs(configIDs) do
        local configInfo = C_Traits.GetConfigInfo(configID)

        if configInfo and configInfo.name == loadoutName then
            return configID
        end
    end

    return nil
end

function Melocoloadouts:ApplyTalentLoadout(loadoutID, loadoutName)
    if not C_ClassTalents or not C_ClassTalents.LoadConfig then
        return false
    end

    local currentSpecIndex = GetSpecialization()
    local currentSpecID = currentSpecIndex and GetSpecializationInfo(currentSpecIndex) or nil

    if not currentSpecID then
        return false
    end

    local configID = self:FindTalentLoadoutByName(loadoutName, currentSpecID)

    if not configID then
        print("|cffff4444Melocoloadouts: Talent loadout not found:|r " .. tostring(loadoutName))
        return false
    end

    local result = C_ClassTalents.LoadConfig(configID, true)

    if result == Enum.LoadConfigResult.Error then
        print("|cffff4444Melocoloadouts: LoadConfig returned Error.|r")
        return false
    end

    if result == Enum.LoadConfigResult.LoadInProgress then
        print("|cffffaa00Melocoloadouts: Talent loadout change in progress...|r")
        return true
    end

    print("|cff00ff00Melocoloadouts: Talent loadout selected:|r " .. tostring(loadoutName))
    return true
end

function Melocoloadouts:DebugTalentLoadouts()
    local currentSpecIndex = GetSpecialization()
    local specID, specName = GetSpecializationInfo(currentSpecIndex)

    print("Current spec:", tostring(specName), tostring(specID))

    local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)

    for _, configID in ipairs(configIDs or {}) do
        local info = C_Traits.GetConfigInfo(configID)
        print("Talent loadout:", tostring(configID), info and info.name or "unknown")
    end
end

function Melocoloadouts:IsTalentLoadoutAvailable(loadoutName, specID)
    if not loadoutName or not specID then
        return false
    end

    local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)

    for _, configID in ipairs(configIDs or {}) do
        local info = C_Traits.GetConfigInfo(configID)

        if info and info.name == loadoutName then
            return true
        end
    end

    return false
end