-- UI.lua

function Melocoloadouts:RefreshProfileList()
    if not MelocoloadoutsMainFrame or not MelocoloadoutsMainFrame.profileList then
        return
    end

    local list = MelocoloadoutsMainFrame.profileList

    for _, child in ipairs({ list:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    if not MelocoloadoutsDB or not MelocoloadoutsDB.profiles then
        return
    end

    local index = 0

    for profileName, profile in pairs(MelocoloadoutsDB.profiles) do
        index = index + 1

        local row = CreateFrame("Frame", nil, list, "BackdropTemplate")
        row:SetSize(380, 70)
        row:SetPoint("TOP", 0, -((index - 1) * 72))

        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
        })

        local isActive = Melocoloadouts:IsProfileActive(profile)

        if isActive then
            row:SetBackdropColor(0.05, 0.16, 0.08, 0.95)
        else
            row:SetBackdropColor(0.08, 0.08, 0.10, 0.85)
        end

        local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("LEFT", 10, 8)
        
        if isActive then
            title:SetText(profileName .. " |cff00ff00ACTIVE|r")
        else
            title:SetText(profileName)
        end

        local subtitle = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        subtitle:SetPoint("LEFT", 10, -10)

        local specText = profile.specName or "Unknown spec"
        local gearText = profile.equipmentSetName or "No gear set"
        local talentText = profile.talentLoadoutName or "No talent loadout"

        subtitle:SetText(specText .. " · " .. gearText .. " · " .. talentText)

        local applyButton = CreateFrame("Button", nil, row, "GameMenuButtonTemplate")
        applyButton:SetSize(62, 24)
        applyButton:SetPoint("TOPRIGHT", row, "TOPRIGHT", -132, -6)
        applyButton:SetText("Apply")

        applyButton:SetScript("OnClick", function()
            Melocoloadouts:ApplyProfile(profileName)
        end)

        local updateButton = CreateFrame("Button", nil, row, "GameMenuButtonTemplate")
        updateButton:SetSize(62, 24)
        updateButton:SetPoint("TOPRIGHT", row, "TOPRIGHT", -68, -6)
        updateButton:SetText("Update")

        updateButton:SetScript("OnClick", function()
            StaticPopupDialogs["MELOCO_CONFIRM_UPDATE"] = {
                text = "Update profile '" .. profileName .. "' with your current setup?",
                button1 = "Update",
                button2 = "Cancel",
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,

                OnAccept = function()
                    Melocoloadouts:SaveProfile(profileName)
                    Melocoloadouts:RefreshProfileList()
                end,
            }

            StaticPopup_Show("MELOCO_CONFIRM_UPDATE")
        end)

        local deleteButton = CreateFrame("Button", nil, row, "GameMenuButtonTemplate")
        deleteButton:SetSize(62, 24)
        deleteButton:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -6)
        deleteButton:SetText("Delete")

        deleteButton:SetScript("OnClick", function()
            StaticPopupDialogs["MELOCO_CONFIRM_DELETE"] = {
                text = "Delete profile '" .. profileName .. "'?",
                button1 = "Delete",
                button2 = "Cancel",
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,

                OnAccept = function()
                    Melocoloadouts:DeleteProfile(profileName)
                    Melocoloadouts:RefreshProfileList()
                end,
            }

            StaticPopup_Show("MELOCO_CONFIRM_DELETE")
        end)
    end
end

function Melocoloadouts:ToggleUI()
    if not MelocoloadoutsMainFrame then
        local frame = CreateFrame("Frame", "MelocoloadoutsMainFrame", UIParent, "BackdropTemplate")
        frame:SetSize(430, 520)
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
                bottom = 4
            }
        })

        frame:SetBackdropColor(0.03, 0.03, 0.045, 0.96)
        frame:SetBackdropBorderColor(0.25, 0.25, 0.32, 1)

        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -18)
        title:SetText("Melocoloadouts")

        local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", -6, -6)

        local saveButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        saveButton:SetSize(180, 32)
        saveButton:SetPoint("TOP", 0, -56)
        saveButton:SetText("Save Current Profile")

        saveButton:SetScript("OnClick", function()
            StaticPopupDialogs["MELOCO_SAVE_PROFILE"] = {
                text = "Enter profile name:",
                button1 = "Save",
                button2 = "Cancel",
                hasEditBox = true,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,

                OnAccept = function(dialog)
                    local editBox = dialog.editBox or dialog.EditBox

                    if not editBox and dialog.GetEditBox then
                        editBox = dialog:GetEditBox()
                    end

                    if not editBox then
                        print("|cffff4444Melocoloadouts: Could not find popup edit box.|r")
                        return
                    end

                    local text = editBox:GetText()

                    if not text or text == "" then
                        print("|cffff4444Melocoloadouts: Profile name cannot be empty.|r")
                        return
                    end

                    Melocoloadouts:SaveProfile(text)
                    Melocoloadouts:RefreshProfileList()
                end,
            }

            StaticPopup_Show("MELOCO_SAVE_PROFILE")
        end)

        local listTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        listTitle:SetPoint("TOPLEFT", 32, -105)
        listTitle:SetText("Saved Profiles")

        local list = CreateFrame("Frame", nil, frame)
        list:SetSize(360, 350)
        list:SetPoint("TOP", 0, -130)

        frame.profileList = list

        frame:Hide()
    end

    if MelocoloadoutsMainFrame:IsShown() then
        MelocoloadoutsMainFrame:Hide()
    else
        MelocoloadoutsMainFrame:Show()
        Melocoloadouts:RefreshProfileList()
    end
end
