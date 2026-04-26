function Melocoloadouts:ApplyUILayout(layoutID)
    if not layoutID then
        return false
    end

    if C_EditMode and C_EditMode.SetActiveLayout then
        C_EditMode.SetActiveLayout(layoutID)
        return true
    end

    return false
end