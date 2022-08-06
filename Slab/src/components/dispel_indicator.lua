---@class LibSlab
local Slab = LibStub("Slab")

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
end

function component:unbind()
    self.frame:UnregisterAllEvents()
    self.frame:Hide()
end

---@param settings SlabNameplateSettings
function component:refresh(settings)
    local found = false
    AuraUtil.ForEachAura(settings.tag, "HELPFUL", nil, function(...)
        local isSpellstealable = select(8, ...)
        if isSpellstealable then
            found = true
            return true
        end
    end)

    if found then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

function component:update(eventName, unitTarget, isFullUpdate, updatedAuras)
    if not AuraUtil.ShouldSkipAuraUpdate(isFullUpdate, updatedAuras, function(aura)
        return aura.isHelpful and aura.debuffType == 'Magic'
    end) then
        self:refresh(self.settings)
    end
end

Slab.utils.load_for('dispelIndicator', {
    MAGE = component
})