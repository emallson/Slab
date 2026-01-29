---@class SlabPrivate
local private = select(2, ...)

-- ToD indicator, implemented by anchoring to a status bar.
-- stole this trick from the WoW UI dev discord.
--
-- there's a bit of a wiggle when the nameplate scales, but that is a wow artifact (the underlying status bar that we can't control also wiggles)

do
    ---@param nameplate Nameplate|SlabRootMixin
    ---@param hp StatusBar|SlabFrameMixin
    ---@return Frame|SlabFrameMixin|nil
    function private.frames.todIndicator(nameplate, hp)
        if select(2, UnitClass('player')) ~= 'MONK' then
            return nil
        end

        local todBar = CreateFrame('StatusBar', nameplate.slab:GetName() .. 'ToD', hp)
        todBar:SetAllPoints(hp)
        todBar:Show()
        todBar:SetClipsChildren(true)

        todBar:SetStatusBarTexture('interface/buttons/white8x8')
        todBar:SetStatusBarColor(0, 0, 0, 0)
        todBar:SetMinMaxValues(0, 100)
        todBar:SetValue(100)

        local indicatorFrame = CreateFrame('Frame', nil, todBar)
        PixelUtil.SetWidth(indicatorFrame, 1)
        indicatorFrame:SetPoint('TOP', todBar:GetStatusBarTexture(), 'TOP')
        indicatorFrame:SetPoint('BOTTOM', todBar:GetStatusBarTexture(), 'BOTTOM')
        indicatorFrame:SetPoint('LEFT', todBar:GetStatusBarTexture(), 'RIGHT')

        local indicator = indicatorFrame:CreateTexture(todBar:GetName() .. 'Indicator', 'OVERLAY', nil, 4)
        indicator:SetTexture('interface/buttons/white8x8')
        indicator:SetVertexColor(0, 0, 0, 1)
        indicator:SetAllPoints()
        indicator:Show()

        local function refresh(unitToken)
            todBar:SetMinMaxValues(0, UnitHealthMax(unitToken))
            todBar:SetValue(UnitHealthMax('player'))
        end

        local storedToken = nil
        function todBar:bind(unitToken)
            storedToken = unitToken
            self:RegisterUnitEvent('UNIT_MAXHEALTH', unitToken, 'player')

            refresh(unitToken)
        end

        todBar:SetScript('OnEvent', function(self, eventName, unitToken)
            if eventName == 'UNIT_MAXHEALTH' then
                refresh(storedToken)
            end
        end)

        return todBar
    end
end
