---@class LibSlab
local Slab = LibStub("Slab")

local threat = {}

---Descriptor for current threat status. "active" means active tank. "offtank" means another tank has threat. "warning" means you are tanking it but not highest threat. "danger" means a non-tank is tanking it. "noncombat" is any unit not in combat with you or your party.
---@alias ThreatStatus "active" | "offtank" | "pet" | "warning" | "danger" | "noncombat"


---stolen from plater
---@param unit UnitId
---@return integer
local function UnitNpcId(unit)
    local guid = UnitGUID(unit)
    if guid == nil then
        return 0
    end
    local npcID = select (6, strsplit ("-", guid))
    return tonumber (npcID or "0") or 0
end

Slab.UnitNpcId = UnitNpcId

---determine if a unit is a tank pet
---@param unit UnitId
---@return boolean
local function IsTankPet(unit)
    local npcId = UnitNpcId(unit)

    return
        npcId == 61146 -- ox statue
        or npcId == 103822 -- trees
        or npcId == 15352 -- earth ele
        or npcId == 95072 -- greater earth ele
        or npcId == 61056 -- primal earth ele
end

---@param unit UnitId
---@return boolean
local function IsTankPlayer(unit)
    local role = UnitGroupRolesAssigned(unit)
    return role == "TANK"
end

---determine if a unit is a tank player or pet
---@param unit UnitId
---@return boolean
local function IsTank(unit)
    return IsTankPlayer(unit) or IsTankPet(unit)
end

---determine if the player is a tank spec
---@return boolean
local function IsPlayerTank()
    return GetSpecializationRole(GetSpecialization()) == "TANK"
end

local THREAT_HIGHEST = 3
local THREAT_WARNING_TANKING = 2
local THREAT_WARNING_NOT_TANKING = 1
local THREAT_NOT_TANKING = 0

---comment
---@param unit UnitId
---@return ThreatStatus
function threat.status(unit)
    local threatStatus = UnitThreatSituation("player", unit)

    local target = unit .. "target"
    local isPlayerTank = IsPlayerTank()
    if not UnitExists(target) then
        return "noncombat"
    end
    if threatStatus == nil then
        -- we are not on the threat table. check if it is targetting an ally
        -- assuming that targetting => combat
        if UnitIsUnit("player", target) then
            return isPlayerTank and "active" or "danger" -- this can occur when you get targeted but are not on the threat table
        elseif UnitIsPlayer(target) and (UnitInParty(target) or UnitInRaid(target)) then
            if IsTankPlayer(target) then
                return isPlayerTank and "offtank" or "active"
            elseif isPlayerTank then
                return "danger"
            else
                return "noncombat"
            end
        elseif IsInInstance() and UnitPlayerControlled(target) and IsTankPet(target) then
            return "pet"
        else
            return "noncombat"
        end
    end

    if IsPlayerTank() then
        -- we tank. we want threat. or want OT to have threat.
        if threatStatus == THREAT_HIGHEST or not UnitIsFriend("player", target) then
            return "active"
        elseif threatStatus == THREAT_NOT_TANKING and UnitIsUnit("player", target) then
            -- blizzard bug
            return "active"
        elseif threatStatus == THREAT_NOT_TANKING and IsTank(target) then
            return IsTankPet(target) and "pet" or "offtank"
        elseif threatStatus == THREAT_NOT_TANKING then
            return "danger"
        else
            return "warning"
        end
    else
        if threatStatus == THREAT_NOT_TANKING then
            return "active"
        elseif threatStatus == THREAT_WARNING_NOT_TANKING then
            return "warning"
        else
            return "danger"
        end
    end
end

Slab.threat = threat