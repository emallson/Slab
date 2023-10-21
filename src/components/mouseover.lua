---@class LibSlab
local Slab = select(2, ...)

---@class MouseoverComponent:Component
---@field public frame MouseoverFrame
local component = {
  dependencies = { 'healthBar' }
}

local WIDTH = 6

---@param slab Slab
---@return MouseoverFrame
function component:build(slab)
  local parent = slab.components.healthBar.frame
  ---@class MouseoverFrame:Frame
  local frame = CreateFrame('Frame', parent:GetName() .. 'Mouseover', parent)

  frame:SetAllPoints(slab)

  local bottom = frame:CreateTexture(nil, "OVERLAY", nil, -8)
  bottom:SetPoint("BOTTOMRIGHT", parent, -0.5, 0)
  bottom:SetPoint("BOTTOMLEFT", parent, 0.5, 0)
  bottom:SetHeight(Slab.scale(WIDTH))
  bottom:SetTexture([[Interface\COMMON\talent-blue-glow]])

  local top = frame:CreateTexture(nil, "OVERLAY", nil, -8)
  top:SetPoint("TOPRIGHT", parent, -0.5, 0)
  top:SetPoint("TOPLEFT", parent, 0.5, 0)
  top:SetHeight(Slab.scale(WIDTH))
  top:SetTexture([[Interface\COMMON\talent-blue-glow]])
  top:SetRotation(math.pi)

  frame:Hide()
  return frame
end

---@param settings SlabNameplateSettings
function component:bind(settings)
  self.frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
end

function component:unbind()
  self.frame:SetScript("OnUpdate", nil)
end

---@param settings SlabNameplateSettings
function component:refresh(settings)
  self:update()
end

function component:waitForMouseOut()
  local frame = self.frame
  local tag = self.settings.tag
  -- i hate it, but UPDATE_MOUSEOVER_UNIT doesn't trigger on nils
  self.frame:SetScript("OnUpdate", function()
    if not UnitExists("mouseover") or not UnitIsUnit("mouseover", tag) then
      frame:Hide()
      frame:SetScript("OnUpdate", nil)
    end
  end)
end

function component:update()
  if UnitIsUnit("mouseover", self.settings.tag) then
    self.frame:Show()
    self:waitForMouseOut()
  else
    self.frame:Hide()
  end
end

Slab.RegisterComponent('mousoverHighlight', component)

