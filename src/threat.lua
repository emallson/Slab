---@class SlabPrivate
local private = select(2, ...)

---Descriptor for current threat status. "active" means active tank. "other-tank" means another tank has threat. "warning" means you are tanking it but not highest threat, or another is tanking it but you are the highest threat. "danger" means a non-tank is tanking it. "noncombat" is any unit not in combat with you or your party.
---@alias ThreatStatus "active" | "other-tank" | "warning" | "danger" | "noncombat"


---determine if the player is a tank spec
---@return boolean
local function IsPlayerTank()
    return GetSpecializationRole(GetSpecialization()) == "TANK"
end

---@param unit UnitToken
---@return boolean
local function IsTankPlayer(unit)
    local role = UnitGroupRolesAssigned(unit)
    return role == "TANK"
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


local function UnitAffectingGroupCombat(unitToken)
    for playerUnit in groupMembers() do
        if UnitThreatSituation(playerUnit, unitToken) ~= nil then
            return true
        end
    end

    return UnitAffectingCombat(unitToken)
end

---@param unitToken UnitToken
---@return ThreatStatus, UnitToken|nil
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
        elseif IsTankPlayer(unitToken .. "target") then
            return "other-tank"
        elseif (UnitThreatLeadSituation("player", unitToken) or 3) < 2 then
            return "active" -- threat lead but not tanking and no warning. assume fixate. treat fixates as actively tanked
        elseif UnitPlayerOrPetInParty(unitToken .. 'target') or UnitPlayerOrPetInRaid(unitToken .. 'target') or UnitIsOwnerOrControllerOfUnit('player', unitToken .. 'target') then
            return UnitIsPlayer(unitToken .. 'target') and "danger" or 'other-tank'
        else
            for groupUnit in groupMembers() do
                if (UnitThreatSituation(groupUnit, unitToken) or 0) > 0 then
                    if UnitIsUnit("player", groupUnit) then
                        return "active" -- should never happen
                    elseif IsTankPlayer(groupUnit) then
                        return "other-tank", groupUnit
                    else
                        return "danger"
                    end
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
