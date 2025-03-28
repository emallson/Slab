---@class LibSlab
local Slab = select(2, ...)

---@alias EnemyType "boss" | "lieutenant" | "important" | "normal" | "trivial" | "special" | "tapped"

local enemies = {}


local WELL_KNOWN_FIXATES = {
  [174773] = true, -- Spiteful
  [201756] = true, -- Morchie (Familiar Face)
}

enemies.fixateNpcs = WELL_KNOWN_FIXATES

---@param npcId integer
---@return boolean
local function isSpecialUnit(npcId)
  return npcId == 120651 -- Explosive
      or npcId == 204560 -- Incorporeal
      or npcId == 174773 -- Spiteful
end

local function isTrivialUnit(npcId)
  return npcId == 137458 -- Rotting Spore in Underrot
      or npcId == 210231 -- Lashers on Gnarlroot
      or npcId == 211306 -- Fiery Vines on Tindral
      or npcId == 220626 -- Parasites, Ovinax
      or npcId == 223674 -- Caustic Skitterer, Ansurek
      or npcId == 221344 -- Gloom Hatchling, Ansurek
      or npcId == 219746 -- Silken Tomb, Ansurek
end

---@param unit UnitId
---@return boolean
function enemies.isTrivial(unit)
  return unit and (isTrivialUnit(Slab.UnitNpcId(unit)) or UnitClassification(unit) == "trivial" or (UnitLevel(unit) > 0 and UnitEffectiveLevel("player") - UnitLevel(unit) >= 3))
end

---@param unit UnitId
---@return boolean
function enemies.isMinor(unit)
  return unit and UnitClassification(unit) == "minus"
end

local importantNpcIds = {}

---comment
---@param unit UnitId
---@return EnemyType
function enemies.type(unit)
  if UnitIsBossMob(unit) then
    return "boss"
  end
  if UnitIsTapDenied(unit) then
    return "tapped"
  end
  local npcId = Slab.UnitNpcId(unit)
  if importantNpcIds[npcId] ~= nil then
    return "important"
  elseif isSpecialUnit(npcId) then
    return "special"
  elseif isTrivialUnit(npcId) then
    return "trivial"
  end

  -- we have a (non?)-boss elite
  local inInstance, instanceType = IsInInstance()

  local playerLevel = UnitLevel("player")
  local level = UnitLevel(unit)
  local cls = UnitClassification(unit)
  if cls == "trivial" then
    return "trivial"
  elseif cls == "normal" then
    return (inInstance or level < playerLevel - 10) and "trivial" or "normal"
  elseif cls == "worldboss" or cls == "rareelite" or cls == "rare" then
    return "boss"
  end

  -- dungeon conventions are:
  -- level + 0 = normal
  -- level + 1 = lieutenant
  -- level + 2 = boss

  -- raid conventions are:
  -- level + 1 = normal (e.g. Null Glimmer)
  -- level + 2 = special enemy (e.g. Empty Recollection)
  -- level + 3 = boss (e.g. Sarkareth)
  local offset = 1
  if instanceType == "raid" then
    offset = 0
  end

  local diff = level - playerLevel + offset
  if inInstance and diff == 3 then
    return "boss"
  elseif diff == 2 or not inInstance then
    return "lieutenant"
  else
    return "normal"
  end
end

function enemies.addImportantNpc(npcId)
  importantNpcIds[npcId] = true
end

function enemies.removeImportantNpc(npcId)
  importantNpcIds[npcId] = nil
end

Slab.utils.enemies = enemies

-- so the idea is to scan MDT.dungeonEnemies for enemies with the "Silence" tag, then cross reference that with BigWigs to check if a spell is important enough to have a notification. Silence Tag + important spell = caster
