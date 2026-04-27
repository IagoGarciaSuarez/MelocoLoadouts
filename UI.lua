-- UI.lua

local FRAME_WIDTH = 430
local FRAME_HEIGHT = 520
local LIST_WIDTH = 380
local LIST_HEIGHT = 350
local ROW_HEIGHT = 70
local ROW_SPACING = 72

-- Removes all dynamic child frames from a container before rebuilding it.
local function ClearChildren(frame)
    for _, child in ipairs({ frame:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
end

-- Handles edit-box API differences between WoW popup implementations.
local function GetPopupEditBox(dialog)
    local editBox = dialog.editBox or dialog.EditBox

    if not editBox and dialog.GetEditBox then
        editBox = dialog:GetEditBox()
    end

    return editBox
end

-- Opens the save dialog and persists the current character's loadout snapshot.
function MelocoLoadouts:ShowSaveProfilePopup()
    StaticPopupDialogs["MELOCO_SAVE_PROFILE"] = {
        text = "Enter profile name:",
        button1 = "Save",
        button2 = "Cancel",
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,

        OnAccept = function(dialog)
            local editBox = GetPopupEditBox(dialog)

            if not editBox then
                print("|cffff4444MelocoLoadouts: Could not find popup edit box.|r")
                return
            end

            local profileName = editBox:GetText()

            if not profileName or profileName == "" then
                print("|cffff4444MelocoLoadouts: Profile name cannot be empty.|r")
                return
            end

            MelocoLoadouts:SaveProfile(profileName)
            MelocoLoadouts:RefreshProfileList()
        end,
    }

    StaticPopup_Show("MELOCO_SAVE_PROFILE")
end

-- Confirms replacing a saved profile with the current character state.
function MelocoLoadouts:ShowUpdateProfilePopup(profileName)
    StaticPopupDialogs["MELOCO_CONFIRM_UPDATE"] = {
        text = "Update profile '" .. profileName .. "' with your current setup?",
        button1 = "Update",
        button2 = "Cancel",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,

        OnAccept = function()
            MelocoLoadouts:SaveProfile(profileName)
            MelocoLoadouts:RefreshProfileList()
        end,
    }

    StaticPopup_Show("MELOCO_CONFIRM_UPDATE")
end

-- Confirms deleting a profile for the current character.
function MelocoLoadouts:ShowDeleteProfilePopup(profileName)
    StaticPopupDialogs["MELOCO_CONFIRM_DELETE"] = {
        text = "Delete profile '" .. profileName .. "'?",
        button1 = "Delete",
        button2 = "Cancel",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,

        OnAccept = function()
            MelocoLoadouts:DeleteProfile(profileName)
            MelocoLoadouts:RefreshProfileList()
        end,
    }

    StaticPopup_Show("MELOCO_CONFIRM_DELETE")
end

-- Creates a single row for a saved profile.
function MelocoLoadouts:CreateProfileRow(parent, profileName, profile, index)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(LIST_WIDTH, ROW_HEIGHT)
    row:SetPoint("TOP", 0, -((index - 1) * ROW_SPACING))

    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })

    local isActive = self:IsProfileActive(profile)

    if isActive then
        row:SetBackdropColor(0.05, 0.16, 0.08, 0.95)
    else
        row:SetBackdropColor(0.08, 0.08, 0.10, 0.85)
    end

    local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", 10, 8)
    title:SetWidth(170)
    title:SetJustifyH("LEFT")

    if isActive then
        title:SetText(profileName .. " |cff00ff00ACTIVE|r")
    else
        title:SetText(profileName)
    end

    local subtitle = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("LEFT", 10, -10)
    subtitle:SetWidth(360)
    subtitle:SetJustifyH("LEFT")

    local specText = profile.specName or "Unknown spec"
    local gearText = profile.equipmentSetName or "No gear set"
    local talentText = profile.talentLoadoutName or "No talent loadout"

    subtitle:SetText(specText .. " - " .. gearText .. " - " .. talentText)

    local applyButton = CreateFrame("Button", nil, row, "GameMenuButtonTemplate")
    applyButton:SetSize(62, 24)
    applyButton:SetPoint("TOPRIGHT", row, "TOPRIGHT", -132, -6)
    applyButton:SetText("Apply")
    applyButton:SetScript("OnClick", function()
        MelocoLoadouts:ApplyProfile(profileName)
    end)

    local updateButton = CreateFrame("Button", nil, row, "GameMenuButtonTemplate")
    updateButton:SetSize(62, 24)
    updateButton:SetPoint("TOPRIGHT", row, "TOPRIGHT", -68, -6)
    updateButton:SetText("Update")
    updateButton:SetScript("OnClick", function()
        MelocoLoadouts:ShowUpdateProfilePopup(profileName)
    end)

    local deleteButton = CreateFrame("Button", nil, row, "GameMenuButtonTemplate")
    deleteButton:SetSize(62, 24)
    deleteButton:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -6)
    deleteButton:SetText("Delete")
    deleteButton:SetScript("OnClick", function()
        MelocoLoadouts:ShowDeleteProfilePopup(profileName)
    end)

    return row
end

-- Rebuilds the visible profile list for the current character.
function MelocoLoadouts:RefreshProfileList()
    if not MelocoLoadoutsMainFrame or not MelocoLoadoutsMainFrame.profileList then
        return
    end

    local list = MelocoLoadoutsMainFrame.profileList
    ClearChildren(list)

    if MelocoLoadoutsMainFrame.profileListTitle then
        MelocoLoadoutsMainFrame.profileListTitle:SetText(
            "Saved Profiles - " .. self:GetCurrentCharacterDisplayName()
        )
    end

    local profileStore = self:GetCurrentCharacterProfileStore()
    local profileNames = self:GetCurrentCharacterProfileNames()

    for index, profileName in ipairs(profileNames) do
        self:CreateProfileRow(list, profileName, profileStore[profileName], index)
    end

    if #profileNames == 0 then
        local emptyText = list:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        emptyText:SetPoint("TOP", 0, -18)
        emptyText:SetText("No profiles saved for this character.")
    end
end

-- Creates the main addon frame the first time the UI is opened.
function MelocoLoadouts:CreateMainFrame()
    local frame = CreateFrame("Frame", "MelocoLoadoutsMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4,
        },
    })

    frame:SetBackdropColor(0.03, 0.03, 0.045, 0.96)
    frame:SetBackdropBorderColor(0.25, 0.25, 0.32, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText("MelocoLoadouts")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -6, -6)

    local saveButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    saveButton:SetSize(180, 32)
    saveButton:SetPoint("TOP", 0, -56)
    saveButton:SetText("Save Current Profile")
    saveButton:SetScript("OnClick", function()
        MelocoLoadouts:ShowSaveProfilePopup()
    end)

    local listTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    listTitle:SetPoint("TOPLEFT", 32, -105)
    listTitle:SetWidth(366)
    listTitle:SetJustifyH("LEFT")
    listTitle:SetText("Saved Profiles")
    frame.profileListTitle = listTitle

    local list = CreateFrame("Frame", nil, frame)
    list:SetSize(LIST_WIDTH, LIST_HEIGHT)
    list:SetPoint("TOP", 0, -130)
    frame.profileList = list

    frame:Hide()
    return frame
end

-- Toggles the main window and refreshes profile state when shown.
function MelocoLoadouts:ToggleUI()
    if not MelocoLoadoutsMainFrame then
        self:CreateMainFrame()
    end

    if MelocoLoadoutsMainFrame:IsShown() then
        MelocoLoadoutsMainFrame:Hide()
    else
        MelocoLoadoutsMainFrame:Show()
        self:RefreshProfileList()
    end
end
