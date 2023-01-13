---@class LibSlab
local Slab = LibStub("Slab")



local function shouldShow(tbl)
    for _, v in pairs(tbl) do
        if v then return true end
    end
    return false
end


local MAGIC = 'Magic'
local ENRAGE = ''

local ARCANE_TORRENT = { 28730, 155145, 25046, 69179, 202719, 232633, 129597, 50613, 80483 }

local function hasArcaneTorrent()
    for _, id in ipairs(ARCANE_TORRENT) do
        if IsPlayerSpell(id) then
            return true
        end
    end
    return false
end

local function dispelIndicator(types)
    local typeMap = {}
    for _, type in ipairs(types) do
        typeMap[type] = true
    end

    if hasArcaneTorrent() then
        typeMap[MAGIC] = true
    end

    ---@class DispelIndicatorComponent:Component
    ---@field public frame DispelIndicator
    local component = {
        dependencies = {'healthBar'}
    }
    
    ---@param slab Slab
    ---@return DispelIndicator
    function component:build(slab)
        local parent = slab.components.healthBar.frame
        ---@class DispelIndicator:Frame
        local indicator = CreateFrame('Frame', parent:GetName() .. 'DispelIndicator', parent)
        indicator:SetPoint('CENTER', parent, 'RIGHT', -5, 0)
        indicator:SetSize(Slab.scale(3), Slab.scale(3))
        indicator:SetFrameLevel(1)

        local tex = indicator:CreateTexture(nil, 'OVERLAY')
        tex:SetTexture('Interface/addons/Slab/resources/textures/Circle_White')
        tex:SetVertexColor(1, 1, 1, 1)
        tex:SetAllPoints(indicator)

        indicator:Hide()
        indicator.texture = tex
        return indicator
    end

    ---@param settings SlabNameplateSettings
    function component:bind(settings)
        self.frame:RegisterUnitEvent("UNIT_AURA", settings.tag)
        self.dispellableAuraIds = {}
    end

    function component:unbind()
        self.frame:UnregisterAllEvents()
        self.frame:Hide()
    end

    function component:auraMatches(aura)
        return typeMap[aura.dispelName] and aura.isStealable and aura.isHelpful
    end

    ---@param settings SlabNameplateSettings
    function component:refresh(settings)
        self.dispellableAuraIds = {}
        AuraUtil.ForEachAura(settings.tag, "HELPFUL", nil, function(aura)
            if self:auraMatches(aura) then
                self.dispellableAuraIds[aura.auraInstanceID] = true
            end
        end)

        if shouldShow(self.dispellableAuraIds) then
            self.frame:Show()
        else
            self.frame:Hide()
        end
    end

    function component:update(eventName, unitTarget, updatedAuras)
        if updatedAuras == nil or updatedAuras.isFullUpdate then
            self:refresh(self.settings)
        else
            local changed = false
            if updatedAuras.removedAuraInstanceIDs ~= nil then
                for _, id in ipairs(updatedAuras.removedAuraInstanceIDs) do
                    if self.dispellableAuraIds[id] then
                        self.dispellableAuraIds[id] = false
                        changed = true
                    end
                end
            end
            if updatedAuras.addedAuras ~= nil then
                for _, aura in ipairs(updatedAuras.addedAuras) do
                    if self:auraMatches(aura) then
                        self.dispellableAuraIds[aura.auraInstanceID] = true
                        changed = true
                    end
                end
            end

            if not changed then return end

            if shouldShow(self.dispellableAuraIds) then
                self.frame:Show()
            else
                self.frame:Hide()
            end
        end
    end

    local outer_component = Slab.apply_combinators(
        component,
        Slab.combinators.disable_minimal()
    )

    return outer_component
end


local magicDispel = dispelIndicator({ MAGIC })
local enrageDispel = dispelIndicator({ ENRAGE })
local magicEnrageDispel = dispelIndicator({ MAGIC, ENRAGE })

Slab.utils.load_for('dispelIndicator', {
    MAGE = magicDispel,
    SHAMAN = magicDispel,
    HUNTER = magicEnrageDispel,
    ROGUE = magicEnrageDispel,
    DRUID = enrageDispel,
    EVOKER = Slab.apply_combinators(
        enrageDispel,
        Slab.combinators.enable_when_spell(374346)
    ),
})