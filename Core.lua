-- Core.lua
Melocoloadouts = {}
Melocoloadouts.name = "Melocoloadouts"

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Melocoloadouts" then
        MelocoloadoutsDB = MelocoloadoutsDB or {
            profiles = {}
        }

        print("|cff00ffccMelocoloadouts loaded.|r Type /mcl")
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player" then
        if Melocoloadouts.pendingProfile then
            local profile = Melocoloadouts.pendingProfile
            Melocoloadouts.pendingProfile = nil

            Melocoloadouts:WaitForTalentLoadoutThenApply(profile, 0)
        end
    end
end)

function Melocoloadouts:IsInCombat()
    return InCombatLockdown()
end

function Melocoloadouts:CanApply()
    if self:IsInCombat() then
        print("|cffff4444Melocoloadouts: You cannot switch loadouts while in combat.|r")
        return false
    end

    return true
end

SLASH_MELOCOLOADOUTS1 = "/mcl"
SLASH_MELOCOLOADOUTS2 = "/meloco"
SLASH_MELOCOLOADOUTS3 = "/melocoloadouts"

SlashCmdList["MELOCOLOADOUTS"] = function()
    Melocoloadouts:ToggleUI()
end

function Melocoloadouts:ApplyProfile(profileName)
    if not self:CanApply() then
        return
    end

    local profile = self:GetProfile(profileName)

    if not profile then
        print("|cffff4444Profile not found.|r")
        return
    end

    self:ApplySpecialization(profile.specID)
    self:ApplyTalentLoadout(profile.talentLoadoutID)
    self:ApplyEquipmentSet(profile.equipmentSetID)
    self:ApplyUILayout(profile.uiLayoutID)

    print("|cff00ff00Profile applied:|r " .. profileName)
end

Melocoloadouts = {}
Melocoloadouts.name = "Melocoloadouts"

local LDB = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

local icon = LDB:NewDataObject("Melocoloadouts", {
    type = "launcher",
    text = "Melocoloadouts",
    icon = "Interface\\Icons\\INV_Misc_Gear_01",

    OnClick = function(_, button)
        if button == "LeftButton" then
            Melocoloadouts:ToggleUI()
        end
    end,

    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Melocoloadouts")
        tooltip:AddLine("Left Click: Open")
    end,
})

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, addonName)
    if addonName ~= "Melocoloadouts" then return end

    MelocoloadoutsDB = MelocoloadoutsDB or {}
    MelocoloadoutsDB.minimap = MelocoloadoutsDB.minimap or {}

    DBIcon:Register("Melocoloadouts", icon, MelocoloadoutsDB.minimap)

    print("Melocoloadouts loaded.")
end)

function Melocoloadouts:ApplyProfile(profileName)
    if self.CanApply and not self:CanApply() then
        return
    end

    local profile = self:GetProfile(profileName)

    if not profile then
        print("|cffff4444Melocoloadouts: Profile not found.|r")
        return
    end

    self.pendingProfile = nil

    local currentSpecIndex = GetSpecialization()

    if profile.specIndex and profile.specIndex ~= currentSpecIndex then
        if not self.ApplySpecialization then
            print("|cffff4444Melocoloadouts: Cannot apply specialization.|r")
            return
        end

        local specApplied = self:ApplySpecialization(profile.specIndex)

        if specApplied == false then
            print("|cffff4444Melocoloadouts: Profile cancelled. Specialization could not be applied.|r")
            return
        end

        self.pendingProfile = profile
        print("|cffffaa00Melocoloadouts: Waiting for specialization change...|r")
        return
    end

    self:ApplyProfileAfterSpec(profile)
end

function Melocoloadouts:ApplyProfileAfterSpec(profile)
    if not profile then
        return
    end

    if profile.talentLoadoutID or profile.talentLoadoutName then
        if not self.ApplyTalentLoadout then
            print("|cffff4444Melocoloadouts: Cannot apply talent loadout.|r")
            return
        end

        local talentsApplied = self:ApplyTalentLoadout(
            profile.talentLoadoutID,
            profile.talentLoadoutName
        )

        if talentsApplied == false then
            print("|cffff4444Melocoloadouts: Profile cancelled. Talent loadout could not be applied.|r")
            return
        end
    end

    if profile.uiLayoutID then
        if not self.ApplyUILayout then
            print("|cffff4444Melocoloadouts: Cannot apply UI layout.|r")
            return
        end

        local uiApplied = self:ApplyUILayout(profile.uiLayoutID)

        if uiApplied == false then
            print("|cffff4444Melocoloadouts: Profile cancelled. UI layout could not be applied.|r")
            return
        end
    end

    if profile.equipmentSetID then
        if not self.ApplyEquipmentSet then
            print("|cffffaa00Melocoloadouts: Equipment set could not be applied.|r")
        else
            local equipmentApplied = self:ApplyEquipmentSet(profile.equipmentSetID)

            if equipmentApplied == false then
                print("|cffffaa00Melocoloadouts: Equipment set could not be applied, but profile application continued.|r")
            end
        end
    end

    print("|cff00ff00Melocoloadouts: Profile applied:|r " .. profile.name)
end

function Melocoloadouts:WaitForTalentLoadoutThenApply(profile, attempts)
    attempts = attempts or 0

    if attempts > 20 then
        print("|cffff4444Melocoloadouts: Profile cancelled. Talent loadout was not ready after spec change.|r")
        return
    end

    local currentSpecIndex = GetSpecialization()

    if currentSpecIndex ~= profile.specIndex then
        C_Timer.After(0.25, function()
            Melocoloadouts:WaitForTalentLoadoutThenApply(profile, attempts + 1)
        end)
        return
    end

    local currentSpecID = select(1, GetSpecializationInfo(currentSpecIndex))

    if profile.talentLoadoutName and not self:IsTalentLoadoutAvailable(profile.talentLoadoutName, currentSpecID) then
        C_Timer.After(0.25, function()
            Melocoloadouts:WaitForTalentLoadoutThenApply(profile, attempts + 1)
        end)
        return
    end

    self:ApplyProfileAfterSpec(profile)
end