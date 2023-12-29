---@class LibSlab
local Slab = select(2, ...)

local function executeIndicator(executeThreshold)
  ---@class ExecuteIndicatorComponent:Component
  ---@field public frame ExecuteIndicator
  ---@field public executeThreshold number|nil
  local component = {
    dependencies = { 'healthBar' },
    executeThreshold = executeThreshold
  }

  ---@param slab Slab
  ---@return ExecuteIndicator
  function component:build(slab)
    local parent = slab.components.healthBar.frame
    ---@class ExecuteIndicator:Frame
    local indicator = CreateFrame('Frame', parent:GetName() .. 'ExecuteIndicator', parent)
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
    self.frame:RegisterUnitEvent("UNIT_MAXHEALTH", settings.tag)
  end

  function component:unbind()
    self.frame:UnregisterAllEvents()
    self.frame:Hide()
  end

  ---@param settings SlabNameplateSettings
  function component:updateLocation(settings)
    local ratio = self.executeThreshold

    if ratio == nil or ratio < 0.05 then
      self.frame:Hide()
      return
    end

    local offset = math.floor(ratio * self.frame.baseWidth) + 1
    self.frame:SetPoint('TOPLEFT', self.frame:GetParent(), 'TOPLEFT', offset, 0)
    self.frame:SetPoint('BOTTOMLEFT', self.frame:GetParent(), 'BOTTOMLEFT', offset, 0)

    self.frame:Raise()
    self.frame:Show()
  end

  function component:update(eventName)
    if eventName == "UNIT_MAXHEALTH" then
      self:updateLocation(self.settings)
    end
  end

  function component:refresh(settings)
    self:updateLocation(settings)
  end

  return component
end

local function onSpellLearned(self, settings)
  self:updateLocation(settings)
end

Slab.utils.load_for('executeIndicator', {
  MAGE = Slab.apply_combinators(
    executeIndicator(0.3),
    Slab.combinators.enable_when_spell(269644, onSpellLearned)
  ),
  PALADIN = executeIndicator(0.2),
  WARRIOR = executeIndicator(0.2),
  DEATHKNIGHT = Slab.apply_combinators(
    executeIndicator(0.35),
    Slab.combinators.enable_when_spell(343294, onSpellLearned)
  ),
  HUNTER = Slab.apply_combinators(
    executeIndicator(0.2),
    Slab.combinators.enable_when_spell(53351, onSpellLearned)
  ),
  PRIEST = Slab.apply_combinators(
    executeIndicator(0.2),
    Slab.combinators.enable_when_spell(32379, onSpellLearned)
  ),
})

Slab.utils.load_for('antiExecuteIndicator', {
  MAGE = Slab.apply_combinators(
    executeIndicator(0.9),
    Slab.combinators.enable_when_spell(205026, onSpellLearned)
  ),
  WARRIOR = Slab.apply_combinators(
    executeIndicator(0.8),
    Slab.combinators.enable_when_spell(317349, onSpellLearned)
  )
})
