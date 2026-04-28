-- EditMode.lua

-- Returns the active Edit Mode layout when the current client exposes it.
function MelocoLoadouts:GetCurrentUILayout()
    if not C_EditMode then
        return nil, nil
    end

    if C_EditMode.GetLayouts then
        local layoutInfo = C_EditMode.GetLayouts()

        if type(layoutInfo) == "table" and layoutInfo.activeLayout then
            return layoutInfo.activeLayout, nil
        end
    end

    return nil, nil
end

-- Activates a saved Edit Mode layout when the API is available.
function MelocoLoadouts:ApplyUILayout(layoutID)
    if not layoutID then
        return false
    end

    if C_EditMode and C_EditMode.SetActiveLayout then
        C_EditMode.SetActiveLayout(layoutID)
        print("|cff00ff00MelocoLoadouts: UI layout selected:|r " .. tostring(layoutID))
        return true
    end

    return false
end
