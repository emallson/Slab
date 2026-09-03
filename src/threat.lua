---@class SlabPrivate
local private = select(2, ...)

---Descriptor for current threat status. "active" means active tank. "other-tank" means another tank has threat. "warning" means you are tanking it but not highest threat, or another is tanking it but you are the highest threat. "danger" means a non-tank is tanking it. "noncombat" is any unit not in combat with you or your party.
---@alias ThreatStatus "active" | "other-tank" | "warning" | "danger" | "noncombat"

---determine if the player is a tank spec
---@return boolean
local function IsPlayerTank()
    return GetSpecializationRole(GetSpecialization()) == "TANK"
end


local THREAT_HIGHEST = 3
local THREAT_WARNING_TANKING = 2
local THREAT_WARNING_NOT_TANKING = 1
local THREAT_NOT_TANKING = 0

local function groupMembers()
    if IsInRaid() then
        local i = 0
        return function()
            while i < 40 do
                i = i + 1
                if UnitExists("raid" .. i) then
                    return "raid" .. i
                end
            end
            return nil
        end
    elseif IsInGroup() then
        local i = 0
        return function()
            while i < 5 do
                i = i + 1
                if UnitExists("party" .. i) then
                    return "party" .. i
                end
            end
            return nil
        end
    else
        local i = 0
        return function()
            if i == 0 then
                i = 1
                return "player"
            end
            return nil
        end
    end
end

local function groupPets()
    if IsInRaid() then
        local i = 0
        return function()
            while i < 40 do
                i = i + 1
                if UnitExists("raidpet" .. i) then
                    return "raidpet" .. i
                end
            end
            return nil
        end
    elseif IsInGroup() then
        local i = 0
        return function()
            while i < 5 do
                i = i + 1
                if UnitExists("partypet" .. i) then
                    return "partypet" .. i
                end
            end
            return nil
        end
    else
        local i = 0
        return function()
            if i == 0 then
                i = 1
                return "player"
            end
            return nil
        end
    end
end

local knownTankUnits = {}
local knownPetUnits = {}

local groupMonitorFrame = CreateFrame('Frame')
groupMonitorFrame:RegisterEvent('GROUP_ROSTER_UPDATE')
groupMonitorFrame:RegisterEvent('UNIT_PET')
groupMonitorFrame:SetScript('OnEvent', function(frame, event, ...)
    if event == 'GROUP_ROSTER_UPDATE' then
        knownTankUnits = {}
        for playerUnit in groupMembers() do
            if UnitGroupRolesAssigned(playerUnit) == 'TANK' then
                table.insert(knownTankUnits, playerUnit)
            end
        end

        knownPetUnits = {}
        for petUnit in groupPets() do
            knownPetUnits[petUnit] = true
        end
    elseif event == 'UNIT_PET' then
        local ownerToken = ...
        if ownerToken == 'player' then
            knownPetUnits['pet'] = UnitExists('pet')
        elseif ownerToken:match('^raid') then
            local petToken = ownerToken:gsub('raid', 'raidpet')
            knownPetUnits[petToken] = UnitExists(petToken)
        elseif ownerToken:match('^party') then
            local petToken = ownerToken:gsub('party', 'partypet')
            knownPetUnits[petToken] = UnitExists(petToken)
        end
    end
end)

local function IsOtherTankPlayerActiveTank(targetToken)
    for _, unit in ipairs(knownTankUnits) do
        if UnitThreatSituation(unit, targetToken) == THREAT_HIGHEST or UnitThreatSituation(unit, targetToken) == THREAT_WARNING_TANKING then
            return true
        end
    end

    return false
end

local function IsGroupPetActiveTank(targetToken)
    for unit, exists in pairs(knownPetUnits) do
        if exists and (UnitThreatSituation(unit, targetToken) == THREAT_HIGHEST or UnitThreatSituation(unit, targetToken) == THREAT_WARNING_TANKING) then
            return true
        end
    end

    return false
end

local function UnitAffectingGroupCombat(unitToken)
    for playerUnit in groupMembers() do
        if UnitThreatSituation(playerUnit, unitToken) ~= nil then
            return true
        end
    end

    return UnitAffectingCombat(unitToken)
end

---@param unitToken UnitToken
---@return ThreatStatus, boolean|nil
function private.threatStatus(unitToken)
    if not UnitAffectingGroupCombat(unitToken) then
        return "noncombat"
    end

    local status = UnitThreatSituation("player", unitToken)

    if IsPlayerTank() then
        if status == THREAT_HIGHEST then
            return "active"
        elseif status == THREAT_WARNING_TANKING or status == THREAT_WARNING_NOT_TANKING then
            return "warning"
        elseif IsOtherTankPlayerActiveTank(unitToken) then
            return "other-tank"
        elseif (UnitThreatLeadSituation("player", unitToken) or 3) < 2 then
            return "active" -- threat lead but not tanking and no warning. assume fixate. treat fixates as actively tanked
        elseif IsGroupPetActiveTank(unitToken) then
            return 'other-tank', true
        else
            for groupUnit in groupMembers() do
                if (UnitThreatSituation(groupUnit, unitToken) or 0) > 0 then
                    return "danger"
                end
            end
            return "noncombat"
        end
    else
        if status == THREAT_HIGHEST or status == THREAT_WARNING_TANKING then
            return "danger"
        elseif status == THREAT_WARNING_NOT_TANKING then
            return "warning"
        else
            return "active"
        end
    end
end
