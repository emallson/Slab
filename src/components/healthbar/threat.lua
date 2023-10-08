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

local any = {}

local ThreatRules = {
    -- isOnThreatTable, isPlayerTank, isPrimaryTarget, isHighestThreat, primaryTargetIsHigherThreat, primaryTargetIsTank, primaryTargetIsPet, noPrimaryTarget
    {false,   any,   any,   any,   any,   any,   any,  any, "noncombat" },

    { true,  true,  true,  true,   any,   any,   any,  any, "active"  },
    { true,  true, false,  true,   any,   any,   any, true, "active"  },
    { true,  true,  true, false,   any,   any,   any,  any, "warning"  },
    { true,  true, false, false,   any,   any,   any, true, "warning"  },
    { true,  true, false, false,   any,  true, false,  any, "offtank" },
    { true,  true, false, false,   any, false,  true,  any, "pet"     },
    { true,  true, false,  true,   any,  true, false,  any, "warning" },
    { true,  true, false,   any,  true, false,   any,  any, "danger"  },
    { true,  true, false,   any, false, false,   any,  any, "warning"  },

    { true, false,  true,   any,   any,   any,   any,  any, "danger"  },
    { true, false, false,  true,   any,   any,   any,  any, "warning"  },
    { true, false, false, false,   any,   any,   any,  any, "active"  },
}

local function applyRules(mobUnit)
    local isPrimaryTarget, threatStatus, scaledPct, rawPct, rawThreatValue = UnitDetailedThreatSituation("player", mobUnit)

    local target = mobUnit .. "target"
    local targetThreat = UnitExists(target) and select(5, UnitDetailedThreatSituation(target, mobUnit))
    local primaryTargetIsHigherThreat = (targetThreat or 0) > (rawThreatValue or 0)
    local noPrimaryTarget = not UnitExists(target) or not UnitIsFriend("player", target)
    local isTargettingFriendly = not noPrimaryTarget and UnitIsUnit("player", target) or UnitPlayerOrPetInParty(target) or UnitPlayerOrPetInRaid(target)
    -- true if the player or any player in the party/raid is on the threat table or the current target
    local isOnThreatTable = isTargettingFriendly or (rawThreatValue ~= nil and rawThreatValue > 0)

    local isHighestThreat = threatStatus == THREAT_WARNING_NOT_TANKING or threatStatus == THREAT_HIGHEST
    local isPlayerTank = IsPlayerTank()
    local primaryTargetIsTank = not noPrimaryTarget and IsTankPlayer(target)
    local primaryTargetIsPet = not noPrimaryTarget and IsTankPet(target)

    local state = {isOnThreatTable, isPlayerTank, isPrimaryTarget, isHighestThreat, primaryTargetIsHigherThreat, primaryTargetIsTank, primaryTargetIsPet, noPrimaryTarget}

    for _, rule in ipairs(ThreatRules) do
        local isMatch = true
        for i, s in ipairs(state) do
            if rule[i] ~= any and rule[i] ~= s then
                isMatch = false
                break
            end
        end

        if isMatch then
            return rule[#rule]
        end
    end

    error("Unable to determine threat from rules")
end

---@param unit UnitId
---@return ThreatStatus
threat.status = applyRules

Slab.threat = threat