---@class LibSlab
local Slab = LibStub("Slab")


---@alias EnemyType "boss" | "lieutenant" | "caster" | "normal" | "trivial" | "special"

local enemies = {}

---@param npcId integer
---@return boolean
local function isSpecialUnit(npcId)
    return npcId == 120651 or npcId == 204560
end

---comment
---@param unit UnitId
---@return EnemyType
function enemies.type(unit)
    if UnitIsBossMob(unit) then
        return "boss"
    end
    local npcId = Slab.UnitNpcId(unit)
    if isSpecialUnit(npcId) then
        return "special"
    end

    -- we have a (non?)-boss elite
    local inInstance, instanceType = IsInInstance()

    local cls = UnitClassification(unit)
    if cls == "minus" or cls == "trivial" then
        return "trivial"
    elseif cls == "normal" then
        return inInstance and "trivial" or "normal"
    elseif cls == "rare" then
        return "caster"
    elseif cls == "worldboss" or cls == "rareelite" then
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

    local level = UnitLevel(unit)
    local playerLevel = UnitLevel("player")
    local diff = level - playerLevel + offset
    if inInstance and diff == 3 then
        return "boss"
    elseif diff == 2 or not inInstance then
        return "lieutenant"
    else
        return "normal"
    end

    -- TODO casters
end

Slab.utils.enemies = enemies

-- so the idea is to scan MDT.dungeonEnemies for enemies with the "Silence" tag, then cross reference that with BigWigs to check if a spell is important enough to have a notification. Silence Tag + important spell = caster