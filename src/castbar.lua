local Slab = LibStub("Slab")

function Slab:BuildCastbar(slab)
    local frame = CreateFrame('Frame', slab:GetName() .. 'CastBarContainer', slab)

    frame:Hide()
    frame:SetAllPoints(slab.bg)
    frame:SetFrameStrata('BACKGROUND')
    frame:SetFrameLevel(0)

    local castBg = frame:CreateTexture(frame:GetName() .. 'BarBackground', 'BACKGROUND')
    castBg:SetTexture('interface/buttons/white8x8')
    castBg:SetSize(120, 4)
    castBg:SetVertexColor(0, 0, 0, .5)
    castBg:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 12, -1)
    castBg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, -5)

    local castBar = CreateFrame('StatusBar', frame:GetName() .. 'Bar', frame)
    castBar:SetStatusBarTexture('interface/raidframe/raid-bar-hp-fill')
    castBar:SetSize(120, 4)
    castBar:SetFrameLevel(0)
    castBar:SetAllPoints(castBg)

    local icon = frame:CreateTexture(slab:GetName() .. 'SpellIcon', 'BACKGROUND', nil, 2)
    icon:SetSize(12, 12)
    icon:SetPoint("TOPRIGHT", castBar, 'TOPLEFT', -1, 0)

    local targetName = frame:CreateFontString(frame:GetName() .. 'TargetText', 'OVERLAY')
    targetName:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    targetName:SetPoint('TOPRIGHT', castBar, 'BOTTOMRIGHT', 0, 1)

    local spellName = frame:CreateFontString(frame:GetName() .. 'TargetText', 'OVERLAY')
    spellName:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    spellName:SetPoint('TOPLEFT', castBar, 'BOTTOMLEFT', 0, 1)

    frame.icon = icon
    frame.castBar = castBar
    frame.targetName = targetName
    frame.spellName = spellName
    frame.updateFrame = CreateFrame('Frame', frame:GetName() .. 'Update', frame)

    return frame
end

local function displayCast(castBar, startTime, endTime)
    castBar.castBar:SetMinMaxValues(startTime / 1000, endTime / 1000)

    local duration = startTime / 1000
    castBar.castBar:SetValue(duration)

    castBar:SetScript('OnUpdate', function(_, elap)
        duration = duration + elap
        castBar.castBar:SetValue(duration)
    end)
end

local function displayChannel(castBar, startTime, endTime)
    local duration = endTime / 1000
    castBar.castBar:SetMinMaxValues(startTime / 1000, duration)
    castBar.castBar:SetValue(duration)

    castBar:SetScript('OnUpdate', function(_, elap)
        duration = duration - elap
        castBar.castBar:SetValue(duration)
    end)
end

local function getCastInfo(unit, isChannel)
    if isChannel then
        local spellName, displayName, spellIcon, startTimeMS, endTimeMS, isTrade, uninterruptible = UnitChannelInfo(unit)
        return spellName, displayName, spellIcon, startTimeMS, endTimeMS, isTrade, uninterruptible
    else
        local spellName, displayName, spellIcon, startTimeMS, endTimeMS, isTrade, _castId, uninterruptible = UnitCastingInfo(unit)
        return spellName, displayName, spellIcon, startTimeMS, endTimeMS, isTrade, uninterruptible
    end
end

local function setCastbarColor(castBar, uninterruptible)
    if uninterruptible then
        castBar.castBar:SetStatusBarColor(0.78, 0.82, 0.86, 1)
    else
        castBar.castBar:SetStatusBarColor(0.4, 0.6, 0.8, 1)
    end
end

function Slab:ShowCastbar(slab, isChannel)
    local unitId = slab.settings.tag
    local spellName, displayName, spellIcon, startTimeMS, endTimeMS, _isTrade, uninterruptible = getCastInfo(unitId, isChannel)
    local targetName = UnitName(unitId .. 'target')

    if spellName == nil then
        return
    end

    -- print('Showing cast of ' .. spellName, startTimeMS, endTimeMS)

    setCastbarColor(slab.castBar, uninterruptible)
    slab.castBar.icon:SetTexture(spellIcon)

    slab.castBar.spellName:SetText(string.sub(spellName, 0, 15))

    if isChannel then
        displayChannel(slab.castBar, startTimeMS, endTimeMS)
    else
        displayCast(slab.castBar, startTimeMS, endTimeMS)
    end

    if targetName ~= nil then
        slab.castBar.targetName:SetText(targetName)
        local classColor = C_ClassColor.GetClassColor(UnitClass(unitId .. 'target'))

        if classColor ~= nil then
            slab.castBar.targetName:SetTextColor(classColor.r, classColor.g, classColor.b)
        else
            slab.castBar.targetName:SetTextColor(1, 1, 1)
        end
    end

    slab.castBar:Raise()
    slab.castBar:Show()
end

function Slab:HideCastbar(slab)
    -- print('Hiding castbar')
    slab.castBar:SetScript('OnUpdate', nil)
    slab.castBar:Hide()
end

function Slab:UpdateCastDuration(slab, isChannel)
    local unitId = slab.settings.tag
    local spellName, displayName, spellIcon, startTimeMS, endTimeMS = getCastInfo(unitId, isChannel)
    slab.castBar.castBar:SetMinMaxValues(startTimeMS / 1000, endTimeMS / 1000)
end

function Slab:UpdateCastColor(slab, uninterruptible)
    setCastbarColor(slab.castBar, uninterruptible)
end