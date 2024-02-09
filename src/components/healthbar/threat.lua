---@class LibSlab
local Slab = select(2, ...)

local threat = {}

local REQUIRE_RULES = false

---Descriptor for current threat status. "active" means active tank. "other-tank" means another tank has threat. "warning" means you are tanking it but not highest threat, or another is tanking it but you are the highest threat. "danger" means a non-tank is tanking it. "noncombat" is any unit not in combat with you or your party.
---@alias ThreatStatus "active" | "other-tank" | "warning" | "danger" | "noncombat"

---stolen from plater
---@param unit UnitId|string
---@param isGuid boolean?
---@return integer
local function UnitNpcId(unit, isGuid)
  local guid = isGuid and unit or UnitGUID(unit)
  if guid == nil then
    return 0
  end
  local npcID = select(6, strsplit("-", guid))
  return tonumber(npcID or "0") or 0
end

Slab.UnitNpcId = UnitNpcId

---determine if a unit is a tank pet
---@param unit UnitId|string
---@param isGuid boolean?
---@return boolean
local function IsTankPet(unit, isGuid)
  local npcId = UnitNpcId(unit, isGuid)

  return
      npcId == 61146     -- ox statue
      or npcId == 103822 -- trees
      or npcId == 15352  -- earth ele
      or npcId == 95072  -- greater earth ele
      or npcId == 61056  -- primal earth ele
end


local function isFixating(npcId, primaryTarget, rawPct)
  return Slab.utils.enemies.fixateNpcs[npcId] or ((rawPct or 0) > 121 and not primaryTarget)
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

local primaryTargetCache = {}

local function groupMembers()
  if IsInRaid() then
    local i = 0
    return function()
      i = i + 1
      if i > MAX_RAID_MEMBERS then
        return
      end
      return "raid" .. i
    end
  elseif IsInGroup() then
    local i = 0
    return function()
      i = i + 1
      if i == 5 then
        return "player"
      elseif i < 5 then
        return "party" .. i
      else
        return nil
      end
    end
  else
    local i = 0
    return function()
      i = i + 1
      if i <= 1 then
        return "player"
      end
      return nil
    end
  end
end

--- @param mobUnit UnitId
--- @return string?
local function primaryTargetGuid(mobUnit)
  local guid = UnitGUID(mobUnit)
  if guid == nil then return nil end

  local currentTarget = mobUnit .. "target"
  if UnitExists(currentTarget) then
    local status = UnitThreatSituation(currentTarget, mobUnit)
    if status == nil or status == THREAT_WARNING_TANKING or status == THREAT_HIGHEST then
      primaryTargetCache[guid] = UnitGUID(currentTarget)
      return primaryTargetCache[guid]
    end
  end

  local cached = primaryTargetCache[guid]
  if cached ~= nil then
    return cached
  else
    for member in groupMembers() do
      local status = UnitThreatSituation(member, mobUnit)
      if status == THREAT_WARNING_TANKING or status == THREAT_HIGHEST then
        primaryTargetCache[guid] = UnitGUID(member)
        return primaryTargetCache[guid]
      end
    end
  end
  return nil
end

---attempt to convert a player guid into a unitid
---@param guid string
---@return UnitId?
local getPlayerUnitByGuid = UnitTokenFromGUID

local function primaryTargetKind(mobUnit, debug)
  local primaryTarget = primaryTargetGuid(mobUnit)

  if primaryTarget == nil then
    if debug then print("no primary target") end
    return nil
  end

  if IsTankPet(primaryTarget, true) then
    return "pet"
  end

  local playerUnit = getPlayerUnitByGuid(primaryTarget)
  if playerUnit == nil then
    if debug then print("no player unit") end
    return nil
  end

  return IsTankPlayer(playerUnit) and "tank" or nil
end

local function isPrimaryTargetTank(mobUnit)
  return primaryTargetKind(mobUnit) ~= nil
end

local function str_startswith(str, sub)
  return str:sub(1, #sub) == sub
end

local function unitIsGuardianOfGroupMember(unit)
  if not UnitIsFriend('player', unit) then
    return false
  end
  for member in groupMembers() do
    if UnitIsOwnerOrControllerOfUnit(member, unit) then
      return true
    end
  end
end

local function isPrimaryTargetPlayerOrPet(mobUnit)
  local guid = primaryTargetGuid(mobUnit)

  if guid == nil then
    return false
  end

  local unit = UnitTokenFromGUID(guid)
  if unit == nil then
    return false
  end
  return UnitPlayerOrPetInParty(unit) or UnitPlayerOrPetInRaid(unit) or unitIsGuardianOfGroupMember(unit)
end

local frame = CreateFrame("Frame", "SlabThreatInvalidationFrame")
frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
frame:SetScript("OnEvent", function(eventName, unitTarget)
  -- invalidate the primary target cache when the threat situation changes for a unit
  local guid = UnitGUID(unitTarget)
  if guid ~= nil then
    primaryTargetCache[guid] = nil
  end
end)


--- determine the threat status of the mobUnit vs the player
--- @param mobUnit UnitId
--- @return ThreatStatus
function threat.status(mobUnit)
  if not UnitAffectingCombat(mobUnit) then
    return "noncombat"
  end

  local status = UnitThreatSituation("player", mobUnit)

  if IsPlayerTank() then
    if status == THREAT_HIGHEST then
      return "active"
    elseif status == THREAT_WARNING_TANKING or status == THREAT_WARNING_NOT_TANKING then
      return "warning"
    elseif isPrimaryTargetTank(mobUnit) then
      return "other-tank"
    elseif isFixating(mobUnit, false, select(4, UnitDetailedThreatSituation("player", mobUnit))) then
      return "active" -- treat fixates as actively tanked
    elseif isPrimaryTargetPlayerOrPet(mobUnit) then
      return "danger"
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

threat.primaryTargetKind = primaryTargetKind

Slab.threat = threat
