-- Profiles.lua

local UNKNOWN_VALUE = "Unknown"

-- Detects old flat saved-profile records during database migration.
local function IsProfileRecord(value)
    return type(value) == "table"
        and (
            type(value.name) == "string"
            or type(value.specIndex) == "number"
            or type(value.specID) == "number"
            or type(value.equipmentSetID) == "number"
            or type(value.talentLoadoutID) == "number"
            or type(value.uiLayoutID) == "number"
        )
end

-- Builds the stable saved-variable key for the active character.
function MelocoLoadouts:GetCurrentCharacterKey()
    local name, realm = UnitFullName("player")

    name = name or UnitName("player") or UNKNOWN_VALUE
    realm = realm or GetRealmName() or UNKNOWN_VALUE

    return name .. "-" .. realm
end

-- Builds a readable label for the active character.
function MelocoLoadouts:GetCurrentCharacterDisplayName()
    local name, realm = UnitFullName("player")

    name = name or UnitName("player") or UNKNOWN_VALUE
    realm = realm or GetRealmName() or UNKNOWN_VALUE

    return name .. " - " .. realm
end

-- Moves legacy flat profiles into the current character bucket.
function MelocoLoadouts:MigrateProfilesToCharacterStore()
    MelocoLoadoutsDB = MelocoLoadoutsDB or {}
    MelocoLoadoutsDB.profiles = MelocoLoadoutsDB.profiles or {}

    local currentCharacterKey = self:GetCurrentCharacterKey()
    local currentCharacterName = self:GetCurrentCharacterDisplayName()
    local legacyProfiles = {}
    local foundLegacyProfile = false

    for profileName, profile in pairs(MelocoLoadoutsDB.profiles) do
        if IsProfileRecord(profile) then
            foundLegacyProfile = true
            profile.characterKey = profile.characterKey or currentCharacterKey
            profile.characterName = profile.characterName or currentCharacterName
            legacyProfiles[profileName] = profile
        end
    end

    if not foundLegacyProfile then
        return
    end

    local characterStores = {}

    for key, value in pairs(MelocoLoadoutsDB.profiles) do
        if not IsProfileRecord(value) then
            characterStores[key] = value
        end
    end

    characterStores[currentCharacterKey] = characterStores[currentCharacterKey] or {}

    for profileName, profile in pairs(legacyProfiles) do
        characterStores[currentCharacterKey][profileName] = profile
    end

    MelocoLoadoutsDB.profiles = characterStores
end

-- Returns the profile table scoped to the active character.
function MelocoLoadouts:GetCurrentCharacterProfileStore()
    self:MigrateProfilesToCharacterStore()

    local characterKey = self:GetCurrentCharacterKey()
    MelocoLoadoutsDB.profiles[characterKey] = MelocoLoadoutsDB.profiles[characterKey] or {}

    return MelocoLoadoutsDB.profiles[characterKey]
end

-- Returns sorted profile names for stable UI rendering.
function MelocoLoadouts:GetCurrentCharacterProfileNames()
    local profileStore = self:GetCurrentCharacterProfileStore()
    local profileNames = {}

    for profileName in pairs(profileStore) do
        table.insert(profileNames, profileName)
    end

    table.sort(profileNames)
    return profileNames
end

-- Captures the current spec, talent, equipment, and UI state.
function MelocoLoadouts:GetCurrentProfileSnapshot()
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
        uiLayoutName = nil,
    }
end

-- Saves or replaces a profile for the active character.
function MelocoLoadouts:SaveProfile(profileName)
    if not profileName or profileName == "" then
        print("|cffff4444MelocoLoadouts: Invalid profile name.|r")
        return
    end

    local profileStore = self:GetCurrentCharacterProfileStore()
    local snapshot = self:GetCurrentProfileSnapshot()

    snapshot.name = profileName
    snapshot.characterKey = self:GetCurrentCharacterKey()
    snapshot.characterName = self:GetCurrentCharacterDisplayName()

    profileStore[profileName] = snapshot

    print("|cff00ff00MelocoLoadouts: Profile saved:|r " .. profileName)
end

-- Finds a profile by name for the active character.
function MelocoLoadouts:GetProfile(profileName)
    local profileStore = self:GetCurrentCharacterProfileStore()

    return profileStore[profileName]
end

-- Deletes a profile from the active character.
function MelocoLoadouts:DeleteProfile(profileName)
    local profileStore = self:GetCurrentCharacterProfileStore()

    if profileStore[profileName] then
        profileStore[profileName] = nil
        print("|cffffaa00MelocoLoadouts: Profile deleted:|r " .. profileName)
    end
end

-- Compares a saved profile with the current in-game state.
function MelocoLoadouts:IsProfileActive(profile)
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
