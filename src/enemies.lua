---@class SlabPrivate
local private = select(2, ...)

---@alias EnemyType "boss" | "lieutenant" | "important" | "normal" | "trivial" | "special" | "tapped"

local function isBossUnit(unitToken)
    return UnitIsBossMob(unitToken) or UnitClassification(unitToken) == "worldboss" or UnitClassification(unitToken) == "rareelite" or UnitClassification(unitToken) == "rare" or UnitEffectiveLevel(unitToken) == -1
end

---@param unitToken UnitToken
---@return EnemyType
function private.enemyType(unitToken)
    if UnitIsTapDenied(unitToken) then
        return "tapped"
    end
    if isBossUnit(unitToken) then
        return "boss"
    end
    
    local inInstance, instanceType = IsInInstance()
    local level = UnitEffectiveLevel(unitToken)
    local playerLevel = UnitEffectiveLevel('player')
    local levelDelta = level - playerLevel

    if not inInstance then
        -- different rules for open world
        local cls = UnitClassification(unitToken)
        if cls == 'trivial' or UnitIsTrivial(unitToken) or levelDelta <= -10 then
            return 'trivial'
        end
        if levelDelta > 2 then
            return 'lieutenant'
        end

        return 'normal'
    end

    local lieutenantDelta = instanceType == 'raid' and 2 or 1
    if levelDelta >= lieutenantDelta then
        return 'lieutenant'
    end

    if select(2, UnitClass(unitToken)) == "PALADIN" then
        return "important"
    end

    if UnitClassification(unitToken) == "trivial" or UnitClassification(unitToken) == "minus" or levelDelta < -10 then
        return "trivial"
    end

    return "normal"
end

function private.smallMode(unitToken)
    return private.enemyType(unitToken) == 'trivial'
end
