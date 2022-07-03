---@class LibSlab
local Slab = LibStub("Slab")

---Create a debuff indicator component
---@param debuffSpellId integer
---@param anchor AnchorPoint
---@return ComponentConstructor
local function debuffIndicator(debuffSpellId, anchor)
    ---@class DebuffIndicatorComponent:Component
    ---@field public frame DebuffIndicator
    local component = {
        dependencies = {'healthBar'},
    }
    
    function component:build(slab)
        local parent = slab.components.healthBar.frame
        ---@class DebuffIndicator:Frame
        local indicator = CreateFrame('Frame', parent:GetName() .. 'DebuffIndicator' .. debuffSpellId, parent)
        indicator:SetPoint('CENTER', parent, anchor, 0, 0)
        indicator:SetSize(Slab.scale(3), Slab.scale(3))
        indicator:SetFrameLevel(1)
    
        local tex = indicator:CreateTexture(nil, 'OVERLAY')
        tex:SetTexture('Interface/addons/Slab/resources/textures/Circle_White')
        tex:SetVertexColor(1, 145 / 255, 0, 1)
        tex:SetAllPoints(indicator)
    
        indicator:Hide()
        indicator.texture = tex
        return indicator
    end
    
    ---@param settings SlabNameplateSettings
    function component:bind(settings)
        self.frame:RegisterUnitEvent("UNIT_AURA", settings.tag)
    end
    
    function component:refreshAuras(settings)
        local found = false
        AuraUtil.ForEachAura(settings.tag, "PLAYER|HARMFUL", nil, function(name, icon, _, _, _, _, _, _, _, spellId, ...)
            if spellId == debuffSpellId then
                self.frame:Hide()
                found = true
                return true
            end
        end)
    
        if not found then
            self.frame:Show()
        end
    end
    
    function component:update(eventName, unitTarget, isFullUpdate, updatedAuras)
        if not AuraUtil.ShouldSkipAuraUpdate(isFullUpdate, updatedAuras, function(aura)
            return aura.spellId == debuffSpellId and aura.isFromPlayerOrPlayerPet
        end) then
            self:refreshAuras(self.settings)
        end
    end
    
    function component:unbind()
        self.frame:UnregisterAllEvents()
    end
    
    function component:refresh(settings)
        self:refreshAuras(settings)
    end

    return component
end


local ww_motc_debuff = Slab.apply_combinators(
    debuffIndicator(228287, 'TOPRIGHT'),
    Slab.combinators.enable_when_spell(115636)
)

Slab.utils.load_for('debuffIndicator', {
    MONK = ww_motc_debuff
})