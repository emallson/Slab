---@class LibSlab
local Slab = LibStub("Slab")


---@class DebuffIndicatorComponent:Component
---@field public frame DebuffIndicator
local component = {
    dependencies = {'healthBar'},
}

function component:build(slab)
    local parent = slab.components.healthBar.frame
    ---@class DebuffIndicator:Frame
    local indicator = CreateFrame('Frame', parent:GetName() .. 'ExecuteIndicator', parent)
    indicator:SetPoint('CENTER', parent, 'TOPRIGHT', 0, 0)
    indicator:SetSize(Slab.scale(3), Slab.scale(3))
    indicator:SetFrameLevel(1)

    local tex = indicator:CreateTexture(nil, 'OVERLAY')
    -- TODO: don't use WA texture
    tex:SetTexture('Interface\\addons\\weakauras\\media\\textures\\circle_white')
    tex:SetVertexColor(1, 145 / 255, 0, 1)
    tex:SetAllPoints(indicator)

    indicator:Hide()
    indicator.texture = tex
    indicator.disabled = true
    return indicator
end

---@param settings SlabNameplateSettings
function component:bind(settings)
    self.frame:RegisterUnitEvent("UNIT_AURA", settings.tag)
    self.frame:RegisterEvent("PLAYER_TALENT_UPDATE")
end

function component:disabled()
    return self.frame.disabled
end

function component:refreshTalents()
    if IsPlayerSpell(115636) then
        if self:disabled() then
            self.frame:Show()
            self.frame.disabled = false
        end
    else
        if not self:disabled() then
            self.frame:Hide()
            self.frame.disabled = true
        end
    end
end

function component:refreshAuras(settings)
    local found = false
    AuraUtil.ForEachAura(settings.tag, "PLAYER|HARMFUL", nil, function(name, icon, _, _, _, _, _, _, _, spellId, ...)
        if spellId == 228287 then
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
    if eventName == "PLAYER_TALENT_UPDATE" then
        self:refreshTalents()
    elseif not self:disabled() and not AuraUtil.ShouldSkipAuraUpdate(isFullUpdate, updatedAuras, function(aura)
        return aura.spellId == 228287 and aura.isFromPlayerOrPlayerPet
    end) then
        self:refreshAuras(self.settings)
    end
end

function component:unbind()
    self.frame:UnregisterAllEvents()
end

function component:refresh(settings)
    self:refreshTalents()
    if not self:disabled() then
        self:refreshAuras(settings)
    end
end

if select(2, UnitClass('player')) == 'MONK' then
    Slab.RegisterComponent('debuffIndicator', component)
end