-- Specs.lua

-- Returns the current specialization index reported by WoW.
function MelocoLoadouts:GetCurrentSpecialization()
    return GetSpecialization()
end

-- Checks whether the requested specialization index is already active.
function MelocoLoadouts:IsCurrentSpecialization(specIndex)
    return specIndex and self:GetCurrentSpecialization() == specIndex
end

-- Switches specialization when the current WoW API allows it.
function MelocoLoadouts:ApplySpecialization(specIndex)
    if not specIndex then
        return false
    end

    if self:IsCurrentSpecialization(specIndex) then
        return true
    end

    if C_SpecializationInfo and C_SpecializationInfo.SetSpecialization then
        C_SpecializationInfo.SetSpecialization(specIndex)
        return true
    end

    if SetSpecialization then
        SetSpecialization(specIndex)
        return true
    end

    print("|cffffaa00MelocoLoadouts: Specialization switching is not available through the current API.|r")
    return false
end
