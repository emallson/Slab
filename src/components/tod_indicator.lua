---@class LibSlab
local Slab = select(2, ...)

---@class ThresholdIndicatorComponent:Component
---@field public frame ThresholdIndicator
local component = {
  dependencies = { 'healthBar' }
}

---@param slab Slab
---@return ThresholdIndicator|nil
function component:build(slab)
  local parent = slab.components.healthBar.frame
  ---@class ThresholdIndicator:Frame
  local indicator = CreateFrame('Frame', parent:GetName() .. 'ToDIndicator', parent)

  indicator:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
  indicator:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', 0, 0)
  indicator:SetWidth(Slab.scale(1))
  indicator:SetFrameLevel(1)

  local tex = indicator:CreateTexture(nil, 'OVERLAY')
  tex:SetTexture('interface/addons/Slab/resources/textures/vertical_line')
  tex:SetVertexColor(1, 1, 1, 0.5)
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

  local ratio = math.min(1, playerMax / math.max(targetMax, 1))

  if ratio == 1 or ratio < 0.025 then
    self.frame:Hide()
    return
  end

  local offset = math.floor(ratio * self.frame.baseWidth) + 1

  self.frame:SetPoint('TOPLEFT', self.frame:GetParent(), 'TOPLEFT', offset, 0)
  self.frame:SetPoint('BOTTOMLEFT', self.frame:GetParent(), 'BOTTOMLEFT', offset, 0)

  self.frame:Raise()
  self.frame:Show()
end

function component:update()
  self:refresh(self.settings)
end

Slab.utils.load_for('todIndicator', { MONK = component })

