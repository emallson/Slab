---@type LibSlab
local Slab = LibStub('Slab')

---@class AbsorbBarComponent:Component
---@field public frame AbsorbBar
local component = {
    dependencies = {'healthBar'}
}

---@param slab Slab
---@return AbsorbBar
function component:build(slab)
    local parent = slab.components.healthBar.frame
    ---@class AbsorbBar:StatusBar
    local absorb = CreateFrame('StatusBar', parent:GetName() .. 'AbsorbBar', parent)
    absorb:SetAllPoints(parent)
    absorb:SetStatusBarTexture('interface/raidframe/raid-bar-hp-fill')
    absorb:SetStatusBarColor(255 / 255, 191 / 255, 45 / 255, 0.75)

    absorb:Hide()

    return absorb
end

---@param settings SlabNameplateSettings
function component:bind(settings)
    self.frame:RegisterUnitEvent("UNIT_MAXHEALTH", settings.tag)
    self.frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", settings.tag)
end

function component:unbind()
    self.frame:UnregisterAllEvents()
    self.frame:Hide()
end

function component:refreshMaxHp()
    local max = UnitHealthMax(self.settings.tag)
    self.frame:SetMinMaxValues(0, max)
end

function component:refreshAbsorb()
    local absorb = UnitGetTotalAbsorbs(self.settings.tag)
    self.frame:SetValue(absorb)
    -- print(absorb)
    if absorb > 0 then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

function component:update(eventName, ...)
    if eventName == 'UNIT_MAXHEALTH' then
        self:refreshMaxHp()
    elseif eventName == 'UNIT_ABSORB_AMOUNT_CHANGED' then
        self:refreshAbsorb()
    end
end

---@param settings SlabNameplateSettings
function component:refresh(settings)
    self:refreshMaxHp()
    self:refreshAbsorb()
end

Slab.RegisterComponent('absorb', component)