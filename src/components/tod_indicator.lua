---@class LibSlab
local Slab = LibStub("Slab")

---@class ThresholdIndicatorComponent:Component
---@field public frame ThresholdIndicator
local component = {
    dependencies = {'healthBar'}
}

---@param slab Slab
---@return ThresholdIndicator|nil
function component:build(slab)
    local parent = slab.components.healthBar.frame
    ---@class ThresholdIndicator:Frame
    local indicator = CreateFrame('Frame', parent:GetName() .. 'ToDIndicator', parent)
    indicator:SetPoint('LEFT', parent, 'LEFT', 0, 0)
    indicator:SetSize(Slab.scale(1), parent:GetHeight())
    indicator:SetFrameLevel(1)

    local tex = indicator:CreateTexture(nil, 'OVERLAY')
    tex:SetTexture('interface/buttons/white8x8')
    tex:SetVertexColor(1, 1, 1, 0.3)
    tex:SetAllPoints(indicator)

    indicator:Hide()

    indicator.texture = tex
    indicator.baseWidth = parent:GetWidth()

    return indicator
end

---@param settings SlabNameplateSettings
function component:bind(settings)
    self.frame:RegisterUnitEvent("UNIT_MAXHEALTH", settings.tag, 'player')
end

function component:unbind()
    self.frame:UnregisterAllEvents()
    self.frame:Hide()
end

---@param settings SlabNameplateSettings
function component:refresh(settings)
    local targetMax = UnitHealthMax(settings.tag)
    local playerMax = UnitHealthMax('player')

    local ratio = math.min(1, playerMax / targetMax)

    if ratio == 1 or ratio < 0.025 then
        self.frame:Hide()
        return
    end

    local offset = math.floor(ratio * self.frame.baseWidth) + 1

    self.frame:SetPoint('LEFT', self.frame:GetParent(), 'LEFT', offset, 0)

    self.frame:Raise()
    self.frame:Show()
end

function component:update()
    self:refresh(self.settings)
end


if select(2, UnitClass('player')) == 'MONK' then
    Slab.RegisterComponent('todIndicator', component)
end