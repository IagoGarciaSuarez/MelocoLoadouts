-- Talents.lua

-- Returns the active specialization ID, which talent APIs use for lookups.
function MelocoLoadouts:GetCurrentSpecializationID()
    local currentSpecIndex = GetSpecialization()

    if not currentSpecIndex then
        return nil
    end

    return GetSpecializationInfo(currentSpecIndex)
end

-- Returns the currently selected class talent loadout ID and name.
function MelocoLoadouts:GetCurrentTalentLoadout()
    if not C_ClassTalents or not C_ClassTalents.GetLastSelectedSavedConfigID or not C_Traits then
        return nil, nil
    end

    local specID = self:GetCurrentSpecializationID()

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

-- Finds a saved talent loadout in the requested specialization by name.
function MelocoLoadouts:FindTalentLoadoutByName(loadoutName, specID)
    if not loadoutName or loadoutName == "" then
        return nil
    end

    if not C_ClassTalents or not C_ClassTalents.GetConfigIDsBySpecID or not C_Traits then
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

-- Checks whether a talent config ID belongs to the requested specialization.
function MelocoLoadouts:IsTalentLoadoutIDAvailable(loadoutID, specID)
    if not loadoutID or not specID then
        return false
    end

    if not C_ClassTalents or not C_ClassTalents.GetConfigIDsBySpecID then
        return false
    end

    for _, configID in ipairs(C_ClassTalents.GetConfigIDsBySpecID(specID) or {}) do
        if configID == loadoutID then
            return true
        end
    end

    return false
end

-- Updates WoW's remembered selected loadout for the current specialization.
function MelocoLoadouts:SetSelectedTalentLoadout(specID, configID)
    if not specID or not configID then
        return
    end

    if C_ClassTalents and C_ClassTalents.UpdateLastSelectedSavedConfigID then
        C_ClassTalents.UpdateLastSelectedSavedConfigID(specID, configID)
    end
end

-- Loads a talent profile, preferring the saved name and falling back to ID.
function MelocoLoadouts:ApplyTalentLoadout(loadoutID, loadoutName)
    if not C_ClassTalents or not C_ClassTalents.LoadConfig then
        return false, "notReady"
    end

    local currentSpecID = self:GetCurrentSpecializationID()

    if not currentSpecID then
        return false, "notReady"
    end

    local configID = self:FindTalentLoadoutByName(loadoutName, currentSpecID)

    if not configID and self:IsTalentLoadoutIDAvailable(loadoutID, currentSpecID) then
        configID = loadoutID
    end

    if not configID then
        print("|cffff4444MelocoLoadouts: Talent loadout not found:|r " .. tostring(loadoutName or loadoutID))
        return false, "notFound"
    end

    local result = C_ClassTalents.LoadConfig(configID, true)

    if Enum and Enum.LoadConfigResult and result == Enum.LoadConfigResult.Error then
        return false, "error"
    end

    self:SetSelectedTalentLoadout(currentSpecID, configID)

    if Enum and Enum.LoadConfigResult and result == Enum.LoadConfigResult.LoadInProgress then
        print("|cffffaa00MelocoLoadouts: Talent loadout change in progress...|r")
        return true, "inProgress"
    end

    print("|cff00ff00MelocoLoadouts: Talent loadout selected:|r " .. tostring(loadoutName or configID))
    return true, "applied"
end

-- Prints talent loadouts for manual debugging in-game.
function MelocoLoadouts:DebugTalentLoadouts()
    if not C_ClassTalents or not C_Traits then
        print("|cffffaa00MelocoLoadouts: Talent APIs are not available.|r")
        return
    end

    local currentSpecIndex = GetSpecialization()
    local specID, specName = GetSpecializationInfo(currentSpecIndex)

    print("Current spec:", tostring(specName), tostring(specID))

    local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)

    for _, configID in ipairs(configIDs or {}) do
        local info = C_Traits.GetConfigInfo(configID)
        print("Talent loadout:", tostring(configID), info and info.name or "unknown")
    end
end

-- Checks whether a named talent loadout is available for a specialization.
function MelocoLoadouts:IsTalentLoadoutAvailable(loadoutName, specID)
    return self:FindTalentLoadoutByName(loadoutName, specID) ~= nil
end
