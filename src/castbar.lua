---@class SlabPrivate
local private = select(2, ...)

do
    local colors = {
        interruptible = CreateColor(1, 191 / 255, 45 / 255, 1),
        notInterruptible = CreateColor(0.78, 0.82, 0.86, 1),
        bgNormal = CreateColor(0, 0, 0, 1),
        bgImportant = CreateColor(1, 0, 0, 1),
    }

    local function colorBar(castBar, notInterruptible)
        local color = C_CurveUtil.EvaluateColorFromBoolean(notInterruptible, colors.notInterruptible, colors.interruptible)
        castBar:GetStatusBarTexture():SetVertexColor(color:GetRGBA())
    end

    local function showSpellTarget(targetName, casterToken)
        if not UnitShouldDisplaySpellTargetName(casterToken) then
            targetName:Hide()
            return
        end

        targetName:SetText(UnitSpellTargetName(casterToken))
        local classColor = C_ClassColor.GetClassColor(UnitSpellTargetClass(casterToken))
        targetName:SetTextColor(classColor.r, classColor.g, classColor.b, classColor.a)
        targetName:Show()
    end

    ---@param nameplate Nameplate|SlabRootMixin
    ---@param health Frame|SlabFrameMixin
    ---@return Frame|SlabFrameMixin
    function private.frames.castbar(nameplate, health)
        local frame = CreateFrame('Frame', health:GetName() .. 'CastBarContainer', health)
        frame:Hide()
        frame:SetFrameStrata("BACKGROUND")
        frame:SetAllPoints(health)
        frame:SetFrameLevel(0)

        local castBar = CreateFrame('StatusBar', frame:GetName() .. 'CastBar', frame)
        castBar:SetFrameStrata("HIGH")
        PixelUtil.SetSize(castBar, 100, 10)
        PixelUtil.SetPoint(castBar, 'TOPLEFT', frame, 'BOTTOMLEFT', 32, -3)
        PixelUtil.SetPoint(castBar, 'BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, -13)
        castBar:SetStatusBarTexture('interface/buttons/white8x8')
        castBar:SetStatusBarColor(1, 1, 1, 1)

        local bg = castBar:CreateTexture(castBar:GetName() .. 'Background', 'BACKGROUND')
        bg:SetTexture('interface/buttons/white8x8')
        PixelUtil.SetPoint(bg, 'TOPLEFT', castBar, 'TOPLEFT', -1, 1, 1, 1)
        PixelUtil.SetPoint(bg, 'BOTTOMRIGHT', castBar, 'BOTTOMRIGHT', 1, -1, 1, 1)
        bg:SetVertexColor(0, 0, 0, 1)

        local icon = castBar:CreateTexture(castBar:GetName() .. 'Icon', 'BACKGROUND', nil, 2)
        PixelUtil.SetSize(icon, 20, 20)
        PixelUtil.SetPoint(icon, 'TOPRIGHT', castBar, 'TOPLEFT', -2, 0)

        local spellName = castBar:CreateFontString(castBar:GetName() .. 'SpellName', 'OVERLAY')
        spellName:SetFont(private.font, 16, 'OUTLINE')
        spellName:SetWidth(100)
        spellName:SetMaxLines(1)
        PixelUtil.SetPoint(spellName, 'TOPLEFT', castBar, 'BOTTOMLEFT', 0, 2)
        spellName:SetJustifyH('LEFT')

        local targetName = castBar:CreateFontString(castBar:GetName() .. 'TargetName', 'OVERLAY')
        targetName:SetFont(private.font, 16, 'OUTLINE')
        targetName:SetMaxLines(1)
        PixelUtil.SetPoint(targetName, 'TOPRIGHT', castBar, 'BOTTOMRIGHT', 0, 2)
        targetName:SetJustifyH('RIGHT')

        function frame:endCast()
            self:Hide()
        end

        function frame:showCast(casterToken, duration, notInterruptible, displayName, textureId)
            castBar:SetTimerDuration(
                duration,
                Enum.StatusBarInterpolation.Immediate,
                Enum.StatusBarTimerDirection.ElapsedTime
            )

            colorBar(castBar, notInterruptible)
            icon:SetTexture(textureId)
            spellName:SetText(displayName)

            showSpellTarget(targetName, casterToken)

            self:Raise()
            self:Show()
        end

        function frame:showChannel(casterToken, duration, notInterruptible, displayName, textureId)
            castBar:SetTimerDuration(
                duration,
                Enum.StatusBarInterpolation.Immediate,
                Enum.StatusBarTimerDirection.RemainingTime
            )

            colorBar(castBar, notInterruptible)
            icon:SetTexture(textureId)
            spellName:SetText(displayName)

            showSpellTarget(targetName, casterToken)

            self:Raise()
            self:Show()
        end

        function frame:refresh(kind, unitToken)
            if kind == 'unknown' or kind == 'channel' then
                local _name, displayName, textureId, _startTimeMs, _endTimeMs, _isTradeskill, notInterruptible, _spellId, _isEmpowered, _numEmpoweredStages, castBarId = UnitChannelInfo(unitToken)
                if castBarId == nil then
                    -- in the unknown cast, we fall back to the cast check
                    if kind ~= 'unknown' then
                        frame:endCast()
                        return
                    end
                else
                    local duration = UnitChannelDuration(unitToken)
                    frame:showChannel(unitToken, duration, notInterruptible, displayName, textureId)
                    return
                end
            end

            if kind == 'unknown' or kind == 'cast' then
                local name, displayName, textureID, startTimeMs, endTimeMs, isTradeskill, castID, notInterruptible, castingSpellID, castBarId = UnitCastingInfo(unitToken)
                if castBarId == nil then
                    frame:endCast()
                else
                    local duration = UnitCastingDuration(unitToken)
                    frame:showCast(unitToken, duration, notInterruptible, displayName, textureID)
                end
            end
        end

        function frame:bind(unitToken)
            self:RegisterUnitEvent('UNIT_SPELLCAST_START', unitToken)
            self:RegisterUnitEvent('UNIT_SPELLCAST_STOP', unitToken)
            self:RegisterUnitEvent('UNIT_SPELLCAST_DELAYED', unitToken)
            self:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_START', unitToken)
            self:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_STOP', unitToken)
            self:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_UPDATE', unitToken)
            self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", unitToken)
            self:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", unitToken)

            self:refresh('unknown', unitToken)
        end

        frame:SetScript('OnEvent', function(frame, eventName, ...)
            local unitToken = select(1, ...)

            if eventName == 'UNIT_SPELLCAST_CHANNEL_START' or eventName == 'UNIT_SPELLCAST_CHANNEL_STOP' or eventName == 'UNIT_SPELLCAST_CHANNEL_UPDATE' then
                frame:refresh('channel', unitToken)
            elseif eventName == 'UNIT_SPELLCAST_START' or eventName == 'UNIT_SPELLCAST_STOP' or eventName == 'UNIT_SPELLCAST_DELAYED' then
                frame:refresh('cast', unitToken)
            elseif eventName == 'UNIT_SPELLCAST_INTERRUPTIBLE' then
                colorBar(castBar, false)
            elseif eventName == 'UNIT_SPELLCAST_NOT_INTERRUPTIBLE' then
                colorBar(castBar, true)
            end
        end)

        return frame
    end
end