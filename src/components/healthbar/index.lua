---@class LibSlab
local Slab = select(2, ...)

local WIDTH = 152
local HEIGHT = 10
local MINOR_SCALE = 0.5


---@class HealthBarComponent:Component
---@field public frame HealthBar
---@field private wasSmallMode? boolean
local component = {
}

---@param unit UnitId
---@return boolean
function component.smallMode(unit)
  return Slab.utils.enemies.isMinor(unit) or Slab.utils.enemies.isTrivial(unit)
end

---@param settings SlabNameplateSettings
function component:refreshName(settings)
  if component.smallMode(settings.tag) then
    self.frame.name:Hide()
  end

  local name = UnitName(settings.tag)
  if name == UNKNOWNOBJECT then
    local tag = settings.tag
    C_Timer.After(0.3, function()
      -- quick check to help avoid race conditions
      if tag ~= settings.tag then
        return
      end
      self.frame.name:SetText(UnitName(settings.tag))
    end)
  else
    self.frame.name:SetText(name)
  end
end

local function playerColor(unitName)
  local classKey = select(2, UnitClass(unitName))
  if classKey ~= nil then
    return C_ClassColor.GetClassColor(classKey)
  end
  return nil
end

---@param settings SlabNameplateSettings
function component:refreshColor(settings)
  local color = nil
  if UnitIsPlayer(settings.tag) then
    color = playerColor(settings.tag)
  end
  if color == nil then
    local enemyType = Slab.utils.enemies.type(settings.tag)
    local threatStatus = Slab.threat.status(settings.tag)

    color = Slab.color.threat[enemyType][threatStatus]
  end
  self.frame:SetStatusBarColor(color.r, color.g, color.b)
end

---@param settings SlabNameplateSettings
function component:refreshHealth(settings)
  local unitId = settings.tag
  self.frame:SetMinMaxValues(0, UnitHealthMax(unitId))
  self.frame:SetValue(UnitHealth(unitId))
end

---@param settings SlabNameplateSettings
function component:refreshTargetMarker(settings)
  local markerId = GetRaidTargetIndex(settings.tag)
  local raidMarker = self.frame.raidMarker
  if markerId == nil then
    raidMarker:Hide()
  else
    local iconTexture = 'Interface\\TargetingFrame\\UI-RaidTargetingIcon_' .. markerId
    raidMarker:SetTexture(iconTexture)
    raidMarker:Show()
  end
end

---@param settings SlabNameplateSettings
function component:refreshReaction(settings)
  local reaction = UnitReaction(settings.tag, 'player')
  local threatStatus = Slab.threat.status(settings.tag)
  if reaction == 4 and threatStatus == "noncombat" then
    self.frame.reactionIndicator:SetText('N')
    -- stolen from plater
    self.frame.reactionIndicator:SetTextColor(0.9254901, 0.8, 0.2666666, 1)
    self.frame.reactionIndicator:Show()
  elseif threatStatus == "pet" then
    self.frame.reactionIndicator:SetText('PET')
    self.frame.reactionIndicator:SetTextColor(0.75, 0.75, 0.5, 1)
    self.frame.reactionIndicator:Show()
  elseif threatStatus == "offtank" then
    self.frame.reactionIndicator:SetText('CO')
    self.frame.reactionIndicator:SetTextColor(0.44, 0.81, 0.37, 1)
    self.frame.reactionIndicator:Show()
  else
    self.frame.reactionIndicator:Hide()
  end
end

---@param settings SlabNameplateSettings
function component:refreshPlayerTargetIndicator(settings)
  if UnitIsUnit('target', settings.tag) then
    self.frame.bg:SetAlpha(0.8)
    for _, pin in ipairs(self.frame.targetPins) do
      pin:Show()
    end
    if component.smallMode(settings.tag) then
      self.frame.name:Show()
    end
  else
    self.frame.bg:SetAlpha(0.5)
    for _, pin in ipairs(self.frame.targetPins) do
      pin:Hide()
    end
    if component.smallMode(settings.tag) then
      self.frame.name:Hide()
    end
  end
end

---@param settings SlabNameplateSettings
function component:refreshClassification(settings, forceFresh)
  if component.smallMode(settings.tag) then
    self.wasSmallMode = true
    if not UnitIsUnit(settings.tag, "target") then
      self.frame.name:Hide()
    end
    self.frame:SetHeight(Slab.scale(HEIGHT * MINOR_SCALE))
    for i, pin in pairs(self.frame.targetPins) do
      pin:SetSize(3, 3)
    end
  elseif self.wasSmallMode or forceFresh then
    self.wasSmallMode = false
    self.frame.name:Show()
    self.frame:SetHeight(Slab.scale(HEIGHT))
    for i, pin in pairs(self.frame.targetPins) do
      pin:SetSize(4, 4)
    end
  end

  self:refreshColor(settings)
end

---@param settings SlabNameplateSettings
function component:refresh(settings)
  self:refreshName(settings)
  self:refreshColor(settings)
  self:refreshHealth(settings)
  self:refreshTargetMarker(settings)
  self:refreshReaction(settings)
  self:refreshPlayerTargetIndicator(settings)
  self:refreshClassification(settings, true)
end

---@param settings SlabNameplateSettings
function component:bind(settings)
  self.frame:RegisterUnitEvent('UNIT_HEALTH', settings.tag)
  self.frame:RegisterUnitEvent('UNIT_THREAT_LIST_UPDATE', settings.tag)
  self.frame:RegisterUnitEvent('UNIT_NAME_UPDATE', settings.tag)
  self.frame:RegisterUnitEvent('UNIT_CLASSIFICATION_CHANGED', settings.tag)
  self.frame:RegisterEvent('RAID_TARGET_UPDATE')
  self.frame:RegisterEvent('PLAYER_TARGET_CHANGED')
end

---@param eventName string
---@vararg any
function component:update(eventName, ...)
  if eventName == 'UNIT_HEALTH' then
    self:refreshHealth(self.settings)
  elseif eventName == 'UNIT_THREAT_LIST_UPDATE' then
    self:refreshColor(self.settings)
    self:refreshReaction(self.settings)
  elseif eventName == 'RAID_TARGET_UPDATE' then
    self:refreshTargetMarker(self.settings)
  elseif eventName == 'PLAYER_TARGET_CHANGED' then
    self:refreshPlayerTargetIndicator(self.settings)
  elseif eventName == 'UNIT_CLASSIFICATION_CHANGED' then
    self:refreshClassification(self.settings)
  elseif eventName == 'UNIT_NAME_UPDATE' then
    self:refreshName(self.settings)
  end
end

local function buildTargetPins(frame)
  -- coords stolen from plater, but i suppose they're just fundamental to the texture
  local coords = { { 145 / 256, 161 / 256, 3 / 256, 19 / 256 }, { 145 / 256, 161 / 256, 19 / 256, 3 / 256 },
    { 161 / 256, 145 / 256, 19 / 256, 3 / 256 }, { 161 / 256, 145 / 256, 3 / 256, 19 / 256 } }
  local positions = { "TOPLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "TOPRIGHT" }
  local offsets = { { -2, 2 }, { -2, -2 }, { 2, -2 }, { 2, 2 } }

  local pins = {}
  for i = 1, 4 do
    local pin = frame:CreateTexture(frame:GetName() .. "TargetPin" .. i, 'OVERLAY')
    pin:SetTexture([[Interface\ITEMSOCKETINGFRAME\UI-ItemSockets]])
    pin:SetTexCoord(unpack(coords[i]))
    pin:SetPoint(positions[i], frame, positions[i], unpack(offsets[i]))
    pin:SetSize(4, 4)
    pin:Hide()
    pins[i] = pin
  end

  return pins
end

---@param parent Frame
---@return HealthBar
function component:build(parent)
  ---@class HealthBar:StatusBar
  local healthBar = CreateFrame('StatusBar', parent:GetName() .. 'HealthBar', parent)

  healthBar:SetStatusBarTexture('interface/addons/Slab/resources/textures/healthbar')
  healthBar:SetStatusBarColor(1, 1, 1, 1)
  healthBar:SetSize(Slab.scale(WIDTH), Slab.scale(HEIGHT))
  healthBar:SetPoint('CENTER')

  local bg = healthBar:CreateTexture(healthBar:GetName() .. 'Background', 'BACKGROUND')
  bg:SetTexture('interface/buttons/white8x8')
  bg:SetVertexColor(0.01, 0, 0, 0.5)
  bg:SetPoint('TOPLEFT', healthBar, 'TOPLEFT', 0, 0)
  bg:SetPoint('BOTTOMRIGHT', healthBar, 'BOTTOMRIGHT', 0, 0)

  local raidMarker = healthBar:CreateTexture(healthBar:GetName() .. 'RaidMarker', 'OVERLAY')
  raidMarker:SetPoint('LEFT', healthBar, 'LEFT', 2, 0)
  raidMarker:SetSize(Slab.scale(HEIGHT) - 2, Slab.scale(HEIGHT) - 2)
  raidMarker:Hide()

  local name = healthBar:CreateFontString(healthBar:GetName() .. 'NameText', 'OVERLAY')
  name:SetPoint('BOTTOM', healthBar, 'TOP', 0, 1)
  name:SetFont(Slab.font, Slab.scale(8), "OUTLINE")

  local reactionIndicator = healthBar:CreateFontString(healthBar:GetName() .. 'IndicatorText', 'OVERLAY')
  reactionIndicator:SetPoint('BOTTOMLEFT', healthBar, 'TOPLEFT', 0, 2)
  reactionIndicator:SetFont(Slab.font, Slab.scale(7), "OUTLINE")
  reactionIndicator:Hide()

  local pins = buildTargetPins(healthBar)

  healthBar.raidMarker = raidMarker
  healthBar.bg = bg
  healthBar.name = name
  healthBar.reactionIndicator = reactionIndicator
  healthBar.targetPins = pins

  return healthBar
end

Slab.RegisterComponent('healthBar', component)
