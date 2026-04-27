-- EditMode.lua

-- Returns the active Edit Mode layout when the current client exposes it.
function MelocoLoadouts:GetCurrentUILayout()
    if not C_EditMode then
        return nil, nil
    end

    if C_EditMode.GetActiveLayout then
        local layoutID, layoutName = C_EditMode.GetActiveLayout()
        return layoutID, layoutName
    end

    if C_EditMode.GetLayouts then
        local activeLayout = C_EditMode.GetLayouts()

        if type(activeLayout) == "number" then
            return activeLayout, nil
        end

        if type(activeLayout) == "table" then
            return activeLayout.layoutID or activeLayout.layoutIndex, activeLayout.layoutName or activeLayout.name
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
        return true
    end

    return false
end
