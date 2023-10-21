---@class LibSlab
local Slab = select(2, ...)

---Create a debuff indicator component
---@param debuffSpellId integer
---@param anchor AnchorPoint
---@return ComponentConstructor
local function debuffIndicator(debuffSpellId, anchor)
  ---@class DebuffIndicatorComponent:Component
  ---@field public frame DebuffIndicator
  local component = {
    dependencies = { 'healthBar' },
  }

  function component:build(slab)
    local parent = slab.components.healthBar.frame
    ---@class DebuffIndicator:Frame
    local indicator = CreateFrame('Frame', parent:GetName() .. 'DebuffIndicator' .. debuffSpellId, parent)
    indicator:SetPoint('CENTER', parent, anchor, -6, 0)
    indicator:SetSize(Slab.scale(4.5), Slab.scale(4.5))
    indicator:SetFrameLevel(1)

    local tex = indicator:CreateTexture(nil, 'OVERLAY')
    tex:SetTexture('Interface/addons/Slab/resources/textures/Circle_White_Border')
    tex:SetVertexColor(0.6, 1, 0.3, 1)
    tex:SetAllPoints(indicator)

    indicator:Hide()
    indicator.texture = tex
    return indicator
  end

  ---@param settings SlabNameplateSettings
  function component:bind(settings)
    self.frame:RegisterUnitEvent("UNIT_AURA", settings.tag)
    self.auraInstanceId = nil
  end

  function component:fullRefresh(settings)
    local found = nil
    AuraUtil.ForEachAura(settings.tag, "PLAYER|HARMFUL", nil, function(aura)
      if aura.spellId == debuffSpellId then
        found = aura
        return true
      end
    end, true)

    if found == nil then
      self.frame:Show()
    else
      self.auraInstanceId = found.auraInstanceId
      self.frame:Hide()
    end
  end

  local function containsId(table, id)
    if table == nil then
      return false
    end
    for _, v in ipairs(table) do
      if v == id then
        return true
      end
    end
    return false
  end

  function component:update(eventName, unitTarget, updatedAuras)
    if updatedAuras == nil or updatedAuras.isFullUpdate then
      self:fullRefresh(self.settings)
    elseif containsId(updatedAuras.removedAuraInstanceIDs, self.auraInstanceId) then
      self.auraInstanceId = nil
      self.frame:Show()
    elseif updatedAuras.addedAuras ~= nil then
      local aura = nil
      for _, v in ipairs(updatedAuras.addedAuras) do
        if v.spellId == debuffSpellId then
          aura = v
          break
        end
      end

      if aura ~= nil then
        self.auraInstanceId = aura.auraInstanceID
        self.frame:Hide()
      end
    end
  end

  function component:unbind()
    self.frame:UnregisterAllEvents()
  end

  function component:refresh(settings)
    self:fullRefresh(settings)
  end

  return component
end


local ww_motc_debuff = Slab.apply_combinators(
  debuffIndicator(228287, 'RIGHT'),
  Slab.combinators.enable_when_spell(115636)
)

Slab.utils.load_for('debuffIndicator', {
  MONK = ww_motc_debuff
})

