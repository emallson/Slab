---@class LibSlab
local Slab = select(2, ...)

local threat = {}

local REQUIRE_RULES = false

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

local WELL_KNOWN_FIXATES = {
  [174773] = true, -- Spiteful
  [201756] = true, -- Morchie (Familiar Face)
}

local function isFixating(npcId, primaryTarget, rawPct)
  return WELL_KNOWN_FIXATES[npcId] or ((rawPct or 0) > 121 and not primaryTarget)
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
  -- TODO target != primaryTarget. how do we determine the primary target without enumerating the raid/party?
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
      if isFixating(UnitNpcId(mobUnit), false, rawPct) then
        return "active"
      elseif isHighestThreat and primaryTargetIsTank and not primaryTargetIsPet then
        -- not primary target, but highest threat
        -- don't warn on pets because many have fixate rules that ignore threat (e.g. treants, earth ele both taunt)
        return "warning"
      elseif not primaryTargetIsTank then
        -- handle non-tank primary targets
        return primaryTargetIsHigherThreat and "danger" or "warning"
      elseif primaryTargetIsTank and not UnitIsUnit(target, "player") then
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

threat.status = applyRulesInline

Slab.threat = threat
