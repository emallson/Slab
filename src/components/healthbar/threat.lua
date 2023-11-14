---@class LibSlab
local Slab = select(2, ...)

local threat = {}

local REQUIRE_RULES = true

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
  local npcID = select(6, strsplit("-", guid))
  return tonumber(npcID or "0") or 0
end

Slab.UnitNpcId = UnitNpcId

---determine if a unit is a tank pet
---@param unit UnitId
---@return boolean
local function IsTankPet(unit)
  local npcId = UnitNpcId(unit)

  return
      npcId == 61146     -- ox statue
      or npcId == 103822 -- trees
      or npcId == 15352  -- earth ele
      or npcId == 95072  -- greater earth ele
      or npcId == 61056  -- primal earth ele
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
  { false, any,   any,   any,   any,   any,   any,   any,  "noncombat" }, -- 1

  { true,  true,  true,  true,  any,   any,   any,   any,  "active" },    -- 4 done
  { true,  true,  false, true,  any,   any,   any,   true, "active" },    -- 5 done
  { true,  true,  true,  false, any,   any,   any,   any,  "warning" },   -- 4 done
  { true,  true,  false, false, any,   any,   any,   true, "warning" },   -- 5 done
  { true,  true,  false, false, any,   true,  false, any,  "offtank" },   -- 6
  { true,  true,  false, false, any,   false, true,  any,  "pet" },       -- 6
  { true,  true,  false, true,  any,   true,  false, any,  "warning" },   -- 6 done
  { true,  true,  false, any,   true,  false, any,   any,  "danger" },    -- 5 done
  { true,  true,  false, any,   false, false, any,   any,  "warning" },   -- 5 done

  { true,  false, true,  any,   any,   any,   any,   any,  "danger" },    -- 3 done
  { true,  false, false, true,  any,   any,   any,   any,  "warning" },   -- 4 done
  { true,  false, false, false, any,   any,   any,   any,  "active" },    -- 4 done
}

---determine the threat status for the `mobUnit`
---@param mobUnit UnitId
---@return ThreatStatus
local function applyRulesInline(mobUnit)
  local isPrimaryTarget, threatStatus, scaledPct, rawPct, rawThreatValue = UnitDetailedThreatSituation("player", mobUnit)
  local target = mobUnit .. "target"
  local targetThreat = UnitExists(target) and select(5, UnitDetailedThreatSituation(target, mobUnit))
  local primaryTargetIsHigherThreat = (targetThreat or 0) > (rawThreatValue or 0)
  local noPrimaryTarget = not UnitExists(target) or not UnitIsFriend("player", target)
  local isTargettingFriendly = not noPrimaryTarget and UnitIsUnit("player", target) or UnitPlayerOrPetInParty(target) or
      UnitPlayerOrPetInRaid(target)
  -- true if the player or any player in the party/raid is on the threat table or the current target
  local isOnThreatTable = isTargettingFriendly or (rawThreatValue ~= nil and rawThreatValue > 0)

  local isHighestThreat = threatStatus == THREAT_WARNING_NOT_TANKING or threatStatus == THREAT_HIGHEST
  local isPlayerTank = IsPlayerTank()
  local primaryTargetIsTank = not noPrimaryTarget and IsTankPlayer(target)
  local primaryTargetIsPet = not noPrimaryTarget and IsTankPet(target)

  -- this is translated from a truth table, so its a bit awkward to structure

  if not isOnThreatTable then
    return "noncombat"
  end

  if not isPlayerTank then
    if isPrimaryTarget then
      return "danger"
    else
      if isHighestThreat then
        return "warning"
      else
        return "active"
      end
    end
  else
    if isPrimaryTarget then
      if isHighestThreat then
        return "active"
      else
        return "warning"
      end
    elseif noPrimaryTarget then
      -- handle RP / AoE casts that bosses often do
      -- ex: Sark Fire Breath clears target, don't warn if we're definitely still tanking
      if threatStatus == THREAT_HIGHEST or rawPct >= 110 then
        return "active"
      else
        return "warning"
      end
    else
      if isHighestThreat and primaryTargetIsTank and not primaryTargetIsPet then
        -- not primary target, but highest threat
        -- don't warn on pets because many have fixate rules that ignore threat (e.g. treants, earth ele both taunt)
        return "warning"
      elseif not primaryTargetIsTank then
        -- handle non-tank primary targets
        return primaryTargetIsHigherThreat and "danger" or "warning"
      elseif primaryTargetIsTank then
        return "offtank"
      elseif primaryTargetIsPet then
        return "pet"
      else
        -- catchall.
        if REQUIRE_RULES then error("Unable to determine threat from rules") end
        return "warning"
      end
    end
  end
end

local function applyRules(mobUnit)
  local isPrimaryTarget, threatStatus, scaledPct, rawPct, rawThreatValue = UnitDetailedThreatSituation("player", mobUnit)

  local target = mobUnit .. "target"
  local targetThreat = UnitExists(target) and select(5, UnitDetailedThreatSituation(target, mobUnit))
  local primaryTargetIsHigherThreat = (targetThreat or 0) > (rawThreatValue or 0)
  local noPrimaryTarget = not UnitExists(target) or not UnitIsFriend("player", target)
  local isTargettingFriendly = not noPrimaryTarget and UnitIsUnit("player", target) or UnitPlayerOrPetInParty(target) or
      UnitPlayerOrPetInRaid(target)
  -- true if the player or any player in the party/raid is on the threat table or the current target
  local isOnThreatTable = isTargettingFriendly or (rawThreatValue ~= nil and rawThreatValue > 0)

  local isHighestThreat = threatStatus == THREAT_WARNING_NOT_TANKING or threatStatus == THREAT_HIGHEST
  local isPlayerTank = IsPlayerTank()
  local primaryTargetIsTank = not noPrimaryTarget and IsTankPlayer(target)
  local primaryTargetIsPet = not noPrimaryTarget and IsTankPet(target)

  local state = { isOnThreatTable, isPlayerTank, isPrimaryTarget, isHighestThreat, primaryTargetIsHigherThreat,
    primaryTargetIsTank, primaryTargetIsPet, noPrimaryTarget }

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

threat.status = applyRulesInline

Slab.threat = threat
