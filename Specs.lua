-- Specs.lua

function Melocoloadouts:GetCurrentSpecialization()
    return GetSpecialization()
end

function Melocoloadouts:IsCurrentSpecialization(specIndex)
    return specIndex and GetSpecialization() == specIndex
end

function Melocoloadouts:ApplySpecialization(specIndex)
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

    print("|cffffaa00Melocoloadouts: Specialization switching is not available through the current API.|r")
    return false
end