-- Core.lua

local ADDON_NAME = ... or "MelocoLoadouts"
local ADDON_DISPLAY_NAME = "MelocoLoadouts"
local ADDON_ICON = "Interface\\AddOns\\MelocoLoadouts\\Media\\Icon"

MelocoLoadouts = MelocoLoadouts or {}
MelocoLoadouts.name = ADDON_DISPLAY_NAME
MelocoLoadouts.addonName = ADDON_NAME or ADDON_DISPLAY_NAME

local addon = MelocoLoadouts
local eventFrame = CreateFrame("Frame")

local LDB = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

local minimapIcon = LDB:NewDataObject(ADDON_DISPLAY_NAME, {
    type = "launcher",
    text = ADDON_DISPLAY_NAME,
    icon = ADDON_ICON,

    OnClick = function(_, button)
        if button == "LeftButton" then
            addon:ToggleUI()
        end
    end,

    OnTooltipShow = function(tooltip)
        tooltip:AddLine(ADDON_DISPLAY_NAME)
        tooltip:AddLine("Left Click: Open")
    end,
})

-- Ensures the saved-variable table always has the expected shape.
function addon:InitializeDatabase()
    MelocoLoadoutsDB = MelocoLoadoutsDB or {}
    MelocoLoadoutsDB.profiles = MelocoLoadoutsDB.profiles or {}
    MelocoLoadoutsDB.collapsedSpecs = MelocoLoadoutsDB.collapsedSpecs or {}
    MelocoLoadoutsDB.minimap = MelocoLoadoutsDB.minimap or {}

    if self.MigrateProfilesToCharacterStore then
        self:MigrateProfilesToCharacterStore()
    end
end

-- Registers the minimap launcher once the saved variables are available.
function addon:InitializeMinimap()
    if self.minimapRegistered then
        return
    end

    DBIcon:Register(ADDON_DISPLAY_NAME, minimapIcon, MelocoLoadoutsDB.minimap)
    self.minimapRegistered = true
end

-- Handles addon startup and deferred profile application after spec changes.
function addon:OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == self.addonName then
        self:InitializeDatabase()
        self:InitializeMinimap()

        print("|cff00ffcc" .. ADDON_DISPLAY_NAME .. " loaded.|r Type /mcl")
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player" then
        if self.pendingProfile then
            local profile = self.pendingProfile
            self.pendingProfile = nil

            self:WaitForTalentLoadoutThenApply(profile, 0)
        end
        return
    end

    if event == "TRAIT_CONFIG_UPDATED" then
        if self.pendingPostTalentProfile then
            local profile = self.pendingPostTalentProfile
            self.pendingPostTalentProfile = nil

            self:ApplyProfileEquipmentAndFinalUI(profile)
        end
        return
    end

    if event == "CONFIG_COMMIT_FAILED" then
        if self.pendingPostTalentProfile then
            self.pendingPostTalentProfile = nil
            print("|cffff4444" .. ADDON_DISPLAY_NAME .. ": Profile cancelled. Talent loadout commit failed.|r")
        end
    end
end

-- Reports whether WoW currently blocks protected loadout changes.
function addon:IsInCombat()
    return InCombatLockdown()
end

-- Guards profile application against combat lockdown.
function addon:CanApply()
    if self:IsInCombat() then
        print("|cffff4444" .. ADDON_DISPLAY_NAME .. ": You cannot switch loadouts while in combat.|r")
        return false
    end

    return true
end

-- Applies a named profile for the current character.
function addon:ApplyProfile(profileName)
    if not self:CanApply() then
        return
    end

    local profile = self:GetProfile(profileName)

    if not profile then
        print("|cffff4444" .. ADDON_DISPLAY_NAME .. ": Profile not found.|r")
        return
    end

    self.pendingProfile = nil
    self.pendingPostTalentProfile = nil

    if profile.uiLayoutID then
        local uiApplied = self:ApplyUILayout(profile.uiLayoutID)

        if uiApplied == false then
            print("|cffff4444" .. ADDON_DISPLAY_NAME .. ": Profile cancelled. UI layout could not be applied.|r")
            return
        end
    end

    local currentSpecIndex = GetSpecialization()

    if profile.specIndex and profile.specIndex ~= currentSpecIndex then
        local specApplied = self:ApplySpecialization(profile.specIndex)

        if specApplied == false then
            print("|cffff4444" .. ADDON_DISPLAY_NAME .. ": Profile cancelled. Specialization could not be applied.|r")
            return
        end

        self.pendingProfile = profile
        print("|cffffaa00" .. ADDON_DISPLAY_NAME .. ": Waiting for specialization change...|r")
        return
    end

    self:ApplyProfileAfterSpec(profile)
end

-- Applies the talent loadout once the target specialization is active.
function addon:ApplyProfileAfterSpec(profile, attempts)
    if not profile then
        return
    end

    if not self:CanApply() then
        return
    end

    attempts = attempts or 0

    if profile.talentLoadoutID or profile.talentLoadoutName then
        local talentsApplied, talentStatus = self:ApplyTalentLoadout(profile.talentLoadoutID, profile.talentLoadoutName)

        if talentsApplied == false then
            if attempts < 20 and talentStatus ~= "notFound" then
                C_Timer.After(0.25, function()
                    addon:ApplyProfileAfterSpec(profile, attempts + 1)
                end)
                return
            end

            print("|cffff4444" .. ADDON_DISPLAY_NAME .. ": Profile cancelled. Talent loadout could not be applied.|r")
            return
        end

        if talentStatus == "inProgress" then
            self.pendingPostTalentProfile = profile
            C_Timer.After(8, function()
                if addon.pendingPostTalentProfile == profile then
                    addon.pendingPostTalentProfile = nil
                    addon:ApplyProfileEquipmentAndFinalUI(profile)
                end
            end)
            return
        end
    end

    self:ApplyProfileEquipmentAndFinalUI(profile)
end

-- Applies the final profile steps after talents are already settled.
function addon:ApplyProfileEquipmentAndFinalUI(profile)
    if not profile then
        return
    end

    if not self:CanApply() then
        return
    end

    if profile.equipmentSetID then
        local equipmentApplied = self:ApplyEquipmentSet(profile.equipmentSetID)

        if equipmentApplied == false then
            print("|cffffaa00" .. ADDON_DISPLAY_NAME .. ": Equipment set could not be applied, but profile application continued.|r")
        end
    end

    if profile.uiLayoutID then
        local uiApplied = self:ApplyUILayout(profile.uiLayoutID)

        if uiApplied == false then
            print("|cffffaa00" .. ADDON_DISPLAY_NAME .. ": Final UI layout retry could not be applied.|r")
        end
    end

    print("|cff00ff00" .. ADDON_DISPLAY_NAME .. ": Profile applied:|r " .. profile.name)

    if MelocoLoadoutsMainFrame and MelocoLoadoutsMainFrame:IsShown() then
        self:RefreshProfileList()
    end
end

-- Waits briefly for specialization-specific talent loadouts to become available.
function addon:WaitForTalentLoadoutThenApply(profile, attempts)
    attempts = attempts or 0

    if attempts > 20 then
        print("|cffff4444" .. ADDON_DISPLAY_NAME .. ": Profile cancelled. Talent loadout was not ready after spec change.|r")
        return
    end

    local currentSpecIndex = GetSpecialization()

    if currentSpecIndex ~= profile.specIndex then
        C_Timer.After(0.25, function()
            addon:WaitForTalentLoadoutThenApply(profile, attempts + 1)
        end)
        return
    end

    local currentSpecID = select(1, GetSpecializationInfo(currentSpecIndex))

    if profile.talentLoadoutName and not self:IsTalentLoadoutAvailable(profile.talentLoadoutName, currentSpecID) then
        C_Timer.After(0.25, function()
            addon:WaitForTalentLoadoutThenApply(profile, attempts + 1)
        end)
        return
    end

    self:ApplyProfileAfterSpec(profile)
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("CONFIG_COMMIT_FAILED")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    addon:OnEvent(event, arg1)
end)

SLASH_MelocoLoadouts1 = "/mcl"
SLASH_MelocoLoadouts2 = "/meloco"
SLASH_MelocoLoadouts3 = "/MelocoLoadouts"

SlashCmdList["MelocoLoadouts"] = function()
    addon:ToggleUI()
end
