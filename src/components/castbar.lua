---@class LibSlab
local Slab = LibStub("Slab")

---@class CastBarComponent:Component
---@field public frame CastBar
local component = {
    dependencies = {'healthBar'}
}

---@param slab Slab
---@return CastBar
function component:build(slab)
    local parent = slab.components.healthBar.frame
    ---@class CastBar:Frame
    local frame = CreateFrame('Frame', parent:GetName() .. 'CastBarContainer', parent)

    frame:Hide()
    frame:SetAllPoints(parent.bg) -- not ideal
    frame:SetFrameStrata('BACKGROUND')
    frame:SetFrameLevel(0)

    local castBg = frame:CreateTexture(frame:GetName() .. 'BarBackground', 'BACKGROUND')
    castBg:SetTexture('interface/buttons/white8x8')
    castBg:SetSize(Slab.scale(120), Slab.scale(4))
    castBg:SetVertexColor(0, 0, 0, .5)
    castBg:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 12, -1)
    castBg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, -5)

    local castBar = frame:CreateTexture(nil, 'OVERLAY')
    castBar:SetTexture('interface/raidframe/raid-bar-hp-fill')
    castBar:SetAllPoints(castBg)

    local castAnimGroup = castBar:CreateAnimationGroup()
    castAnimGroup:SetLooping('NONE')
    local castAnim = castAnimGroup:CreateAnimation('Scale')
    castAnim:SetOrigin('LEFT', 0, 0)
    castAnim:SetEndDelay(1)

    local icon = frame:CreateTexture(frame:GetName() .. 'SpellIcon', 'BACKGROUND', nil, 2)
    icon:SetSize(Slab.scale(12), Slab.scale(12))
    icon:SetPoint("TOPRIGHT", castBar, 'TOPLEFT', -1, 0)

    local targetName = frame:CreateFontString(frame:GetName() .. 'TargetText', 'OVERLAY')
    targetName:SetFont(Slab.font, Slab.scale(8), "OUTLINE")
    targetName:SetPoint('TOPRIGHT', castBar, 'BOTTOMRIGHT', 0, 1)

    local spellName = frame:CreateFontString(frame:GetName() .. 'TargetText', 'OVERLAY')
    spellName:SetFont(Slab.font, Slab.scale(8), "OUTLINE")
    spellName:SetPoint('TOPLEFT', castBar, 'BOTTOMLEFT', 0, 1)

    frame.icon = icon
    frame.castBar = castBar
    frame.castAnimGroup = castAnimGroup
    frame.castAnim = castAnim
    frame.targetName = targetName
    frame.spellName = spellName

    return frame
end

---@param castBar CastBar
---@param startTime number
---@param endTime number
local function displayCast(castBar, startTime, endTime)
    local duration = endTime / 1000 - GetTime()
    local totalDuration = (endTime - startTime) / 1000
    local initialScale = (GetTime() - startTime / 1000) / totalDuration

    castBar.castAnimGroup:Stop()
    castBar.castAnim:SetDuration(duration)
    castBar.castAnim:SetScaleFrom(initialScale, 1)
    castBar.castAnim:SetScaleTo(1, 1)
    castBar.castAnimGroup:Restart()
    castBar.castAnimGroup:Play()
end

---@param castBar CastBar
---@param startTime number
---@param endTime number
local function displayChannel(castBar, startTime, endTime)
    local duration = endTime / 1000 - GetTime()
    local totalDuration = (endTime - startTime) / 1000
    local initialScale = 1 - (GetTime() - startTime / 1000) / totalDuration

    castBar.castAnimGroup:Stop()
    castBar.castAnim:SetDuration(duration)
    castBar.castAnim:SetScaleFrom(initialScale, 1)
    castBar.castAnim:SetScaleTo(0, 1)
    castBar.castAnimGroup:Restart()
    castBar.castAnimGroup:Play()
end

---@param unit UnitId
---@param isChannel boolean
local function getCastInfo(unit, isChannel)
    if isChannel then
        local spellName, displayName, spellIcon, startTimeMS, endTimeMS, isTrade, uninterruptible = UnitChannelInfo(unit)
        return spellName, displayName, spellIcon, startTimeMS, endTimeMS, isTrade, uninterruptible
    else
        local spellName, displayName, spellIcon, startTimeMS, endTimeMS, isTrade, _castId, uninterruptible = UnitCastingInfo(unit)
        return spellName, displayName, spellIcon, startTimeMS, endTimeMS, isTrade, uninterruptible
    end
end

---@param castBar CastBar
---@param uninterruptible boolean
local function setCastbarColor(castBar, uninterruptible)
    if uninterruptible then
        castBar.castBar:SetColorTexture(0.78, 0.82, 0.86, 1)
    else
        castBar.castBar:SetColorTexture(255 / 255, 191 / 255, 45 / 255, 1)
    end
end

---@param settings SlabNameplateSettings
function component:bind(settings)
    self:hideCastbar()
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_START", settings.tag)
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", settings.tag)
    -- maybe these help with the cast -> kick + channel heisenbug?
    -- leaving SUCCEEDED off because that breaks cast -> channel kicks unless i make this stateful
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", settings.tag)
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", settings.tag)
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", settings.tag)
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", settings.tag)
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", settings.tag)
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", settings.tag)
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", settings.tag)
    self.frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", settings.tag)
    self.frame:RegisterUnitEvent("UNIT_TARGET", settings.tag)
end

function component:unbind()
    self:hideCastbar()
end

---@param settings SlabNameplateSettings
function component:refresh(settings)
    if UnitChannelInfo(settings.tag) then
        self:showCastbar(settings, true)
    elseif UnitCastingInfo(settings.tag) then
        self:showCastbar(settings)
    end
end

---@param settings SlabNameplateSettings
---@param isChannel boolean
function component:updateCastDuration(settings, isChannel)
    local unitId = settings.tag
    local spellName, displayName, spellIcon, startTimeMS, endTimeMS = getCastInfo(unitId, isChannel)
    if isChannel then
        displayChannel(self.frame, startTimeMS, endTimeMS)
    else
        displayCast(self.frame, startTimeMS, endTimeMS)
    end
end

---@param settings SlabNameplateSettings
---@param uninterruptible boolean
function component:updateCastColor(settings, uninterruptible)
    setCastbarColor(self.frame, uninterruptible)
end

---@param targetUnit UnitId
---@param frame FontString
local function updateTargetName(targetUnit, frame)
    if targetUnit == nil then return end

    local targetName = UnitName(targetUnit)
    if targetName ~= nil and UnitIsPlayer(targetUnit) then
        frame:SetText(targetName)
        local classColor = C_ClassColor.GetClassColor(select(2, UnitClass(targetUnit)))

        if classColor ~= nil then
            frame:SetTextColor(classColor.r, classColor.g, classColor.b)
        else
            frame:SetTextColor(1, 1, 1)
        end
        frame:Show()
    else
        frame:Hide()
    end
end

---@param eventName string
---@vararg any
function component:update(eventName, ...)
    if eventName == "UNIT_SPELLCAST_START" then
        self:showCastbar(self.settings)
    elseif eventName == "UNIT_SPELLCAST_STOP" or eventName == "UNIT_SPELLCAST_CHANNEL_STOP"
        or eventName == "UNIT_SPELLCAST_FAILED" or eventName == "UNIT_SPELLCAST_INTERRUPTED" then
        self:hideCastbar()
    elseif eventName == "UNIT_SPELLCAST_CHANNEL_START" then
        self:showCastbar(self.settings, true)
    elseif eventName == "UNIT_SPELLCAST_DELAYED" or eventName == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        self:updateCastDuration(self.settings, eventName == "UNIT_SPELLCAST_CHANNEL_UPDATE")
    elseif eventName == "UNIT_SPELLCAST_INTERRUPTIBLE" or eventName == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        self:updateCastColor(self.settings, eventName == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    elseif eventName == "UNIT_TARGET" then
        updateTargetName(self.settings.tag .. "target", self.frame.targetName)
    end
end

---@param settings SlabNameplateSettings
---@param spellName string
---@param spellIcon string
---@param startTimeMS number
---@param endTimeMS number
---@param isChannel boolean
---@param uninterruptible boolean
function component:showCastbarDetails(settings, spellName, spellIcon, startTimeMS, endTimeMS, isChannel, uninterruptible)
    setCastbarColor(self.frame, uninterruptible)
    self.frame.icon:SetTexture(spellIcon)

    self.frame.spellName:SetText(string.sub(spellName, 0, 15))

    if isChannel then
        displayChannel(self.frame, startTimeMS, endTimeMS)
    else
        displayCast(self.frame, startTimeMS, endTimeMS)
    end

    local targetUnit = settings.tag .. 'target'
    updateTargetName(targetUnit, self.frame.targetName)
    -- self.frame.targetName:Hide()

    -- C_Timer.After(0.3, function() updateTargetName(targetUnit, self.frame.targetName) end)

    self.frame:Raise()
    self.frame:Show()
end

---@param settings SlabNameplateSettings
---@param isChannel? boolean
function component:showCastbar(settings, isChannel)
    local unitId = settings.tag
    local spellName, displayName, spellIcon, startTimeMS, endTimeMS, _isTrade, uninterruptible = getCastInfo(unitId, isChannel)

    if spellName == nil then
        return
    end
    self:showCastbarDetails(settings, spellName, spellIcon, startTimeMS, endTimeMS, isChannel, uninterruptible)
end

function component:hideCastbar()
    self.frame.castAnimGroup:Stop()
    self.frame:Hide()
end

Slab.RegisterComponent('castBar', Slab.apply_combinators(component, Slab.combinators.disable_minimal()))