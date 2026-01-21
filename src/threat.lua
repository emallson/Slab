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


---@param unitToken UnitToken
---@return ThreatStatus
function private.threatStatus(unitToken)
    if not UnitAffectingCombat(unitToken) then
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
        elseif (select(4, UnitDetailedThreatSituation("player", unitToken)) or 0) > 110 then
            return "active" -- treat fixates as actively tanked
        elseif UnitPlayerOrPetInParty(unitToken .. 'target') or UnitPlayerOrPetInRaid(unitToken .. 'target') or UnitIsOwnerOrControllerOfUnit('player', unitToken .. 'target') then
            return UnitIsPlayer(unitToken .. 'target') and "danger" or 'other-tank'
        else
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
