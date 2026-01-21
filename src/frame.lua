---@class SlabPrivate
local private = select(2, ...)

do
    local WARNING_COLOR = private.color.hsl_to_srgb(57, 100, 60)
    local DANGER_COLOR = private.color.hsl_to_srgb(1, 100, 55)

    local function colorTable(hue, saturation, lightness, otSaturation, otLightness)
        local active = private.color.hsl_to_srgb(hue, saturation, lightness)
        local offtank = private.color.hsl_to_srgb(hue, otSaturation or 15, otLightness or 80)

        return {
            ["active"] = active,
            ["noncombat"] = active,
            ["other-tank"] = offtank,
            ["warning"] = WARNING_COLOR,
            ["danger"] = DANGER_COLOR
        }
    end


    local function trivialTable(hue, saturation, lightness)
        local color = private.color.hsl_to_srgb(hue, saturation, lightness)
        return {
            active = color,
            noncombat = color,
            ["other-tank"] = color,
            warning = color,
            danger = color,
        }
    end

    ---@type table<EnemyType, table<ThreatStatus, RGB>>
    local colors = {
        ["boss"] = colorTable(90, 10, 45, 1, 90),
        ["lieutenant"] = colorTable(194, 25, 65, 10, 90),
        ["important"] = colorTable(259, 60, 65),
        ["normal"] = colorTable(130, 60, 65),
        ["minor"] = colorTable(130, 60, 65),
        ["trivial"] = colorTable(47, 25, 80),
        ["special"] = colorTable(22, 100, 65, 55, 80),
        ["tapped"] = trivialTable(47, 11, 64)
    }


    ---@param nameplate Nameplate|SlabRootMixin
    ---@param hp Frame|SlabFrameMixin
    ---@return FontString
    local function tagText(nameplate, hp)
        local label = hp:CreateFontString(hp:GetName() .. 'TagText')
        label:SetFont([[Interface\addons\Slab\resources\fonts\FiraSans-Regular.otf]], 14, "OUTLINE")
        PixelUtil.SetPoint(label, 'BOTTOMLEFT', hp, 'TOPLEFT', 0, 2)
        label:Hide()

        local function refresh(unitToken)
            if private.smallMode(unitToken) and not UnitIsUnit('target', unitToken) then
                label:Hide()
                return
            end

            local reaction = UnitReaction(unitToken, 'player')
            local threatStatus = private.threatStatus(unitToken)
            if reaction == 4 and threatStatus == "noncombat" then
                label:SetText('N')
                -- stolen from plater
                label:SetTextColor(0.9254901, 0.8, 0.2666666, 1)
                label:Show()
            elseif threatStatus == "other-tank" and not UnitIsPlayer(unitToken .. 'target') then
                label:SetText('PET')
                label:SetTextColor(0.75, 0.75, 0.5, 1)
                label:Show()
            elseif threatStatus == "other-tank" then
                label:SetText('CO')
                label:SetTextColor(0.44, 0.81, 0.37, 1)
                label:Show()
            else
                label:Hide()
            end
        end

        local storedToken = nil
        function label:bind(unitToken)
            storedToken = unitToken
            self:GetParent():RegisterEvent('PLAYER_REGEN_DISABLED')
            self:GetParent():RegisterUnitEvent('UNIT_THREAT_LIST_UPDATE', unitToken)

            refresh(unitToken)
        end

        hp:HookScript('OnEvent', function(parent, eventType, unitToken)
            if eventType == 'PLAYER_REGEN_DISABLED' then
                refresh(storedToken)
            elseif eventType == 'UNIT_THREAT_LIST_UPDATE' then
                refresh(unitToken)
            elseif eventType == 'UNIT_CLASSIFICATION_CHANGED' or eventType == 'PLAYER_TARGET_CHANGED' then
                refresh(unitToken or storedToken)
            end
        end)

        return label
    end

    ---@param nameplate Nameplate|SlabRootMixin
    ---@param hp Frame|SlabFrameMixin
    ---@return FontString
    local function name(nameplate, hp)
        local label = hp:CreateFontString(hp:GetName() .. 'Name')
        label:SetFont(private.font, 16, 'OUTLINE')
        PixelUtil.SetPoint(label, 'BOTTOM', hp, 'TOP', 0, 2)
        label:SetWidth(150)
        label:SetMaxLines(1)
        label:SetWordWrap(false)

        local function refresh(unitToken)
            label:SetText(UnitName(unitToken))
            if private.smallMode(unitToken) and not UnitIsUnit('target', unitToken) then
                label:Hide()
            else
                label:Show()
            end
        end

        local storedToken = nil
        function label:bind(unitToken)
            storedToken = unitToken
            self:GetParent():RegisterUnitEvent('UNIT_NAME_UPDATE')
            refresh(unitToken)
        end

        hp:HookScript('OnEvent', function(parent, eventType, unitToken)
            if eventType == 'UNIT_NAME_UPDATE' then
                refresh(unitToken)
            elseif eventType == 'UNIT_CLASSIFICATION_CHANGED' or eventType == 'PLAYER_TARGET_CHANGED' then
                refresh(unitToken or storedToken)
            end
        end)

        return label
    end

    local function targetPins(frame)
        -- coords stolen from plater, but i suppose they're just fundamental to the texture
        local coords = { { 145 / 256, 161 / 256, 3 / 256, 19 / 256 }, { 145 / 256, 161 / 256, 19 / 256, 3 / 256 },
            { 161 / 256, 145 / 256, 19 / 256, 3 / 256 }, { 161 / 256, 145 / 256, 3 / 256, 19 / 256 } }
        local positions = { "TOPLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "TOPRIGHT" }
        local x = 5
        local offsets = { { -x, x }, { -x, -x }, { x, -x }, { x, x } }

        local pins = {}
        for i = 1, 4 do
            local pin = frame:CreateTexture(frame:GetName() .. "TargetPin" .. i, 'OVERLAY', nil, 4)
            pin:SetTexture([[Interface\ITEMSOCKETINGFRAME\UI-ItemSockets]])
            pin:SetTexCoord(unpack(coords[i]))
            PixelUtil.SetPoint(pin, positions[i], frame, positions[i], unpack(offsets[i]))
            PixelUtil.SetSize(pin, 8, 8)
            pin:Hide()
            pins[i] = pin
        end

        local unitToken = nil

        function pins:bind(token)
            unitToken = token
            if UnitIsUnit('target', unitToken) then
                for _, pin in ipairs(pins) do
                    pin:Show()
                end
            end
        end

        frame:HookScript('OnEvent', function(parent, eventType)
            if unitToken and eventType == 'PLAYER_TARGET_CHANGED' then
                if UnitIsUnit('target', unitToken) then
                    for _, pin in ipairs(pins) do
                        pin:Show()
                    end
                else
                    for _, pin in ipairs(pins) do
                        pin:Hide()
                    end
                end
            end
        end)

        return pins
    end

    ---@param nameplate Nameplate|SlabRootMixin
    ---@return Frame|SlabFrameMixin
    function private.frames.health(nameplate)
        ---@type StatusBar|SlabFrameMixin
        local hp = CreateFrame('StatusBar', nameplate.slab:GetName() .. 'Health', nameplate.slab)
        PixelUtil.SetPoint(hp, 'LEFT', nameplate.slab, 'LEFT', 1, 0, 1, 0)
        PixelUtil.SetPoint(hp, 'RIGHT', nameplate.slab, 'RIGHT', -1, 0, 1, 0)
        PixelUtil.SetPoint(hp, 'TOP', nameplate.slab, 'TOP', 0, -30, 0, 10)
        PixelUtil.SetPoint(hp, 'BOTTOM', nameplate.slab, 'TOP', 0, -48, 0, 20)

        -- hp:SetStatusBarTexture('interface/addons/Slab/resources/textures/healthbar.tga')
        hp:SetStatusBarTexture('interface/buttons/white8x8')
        hp:SetStatusBarColor(1, 1, 1, 1)
        hp:SetMinMaxValues(0, 100)
        hp:SetValue(100)

        local bg = hp:CreateTexture(hp:GetName() .. 'Background', 'BACKGROUND')
        bg:SetTexture('interface/buttons/white8x8')
        PixelUtil.SetPoint(bg, 'TOPLEFT', hp, 'TOPLEFT', -1, 1, 1, 1)
        PixelUtil.SetPoint(bg, 'BOTTOMRIGHT', hp, 'BOTTOMRIGHT', 1, -1, 1, 1)
        bg:SetVertexColor(0, 0, 0, 1)

        local function updateSize(unitToken)
            if private.smallMode(unitToken) and not UnitIsUnit('target', unitToken) then
                PixelUtil.SetPoint(hp, 'BOTTOM', nameplate.slab, 'TOP', 0, -38)
            else
                PixelUtil.SetPoint(hp, 'BOTTOM', nameplate.slab, 'TOP', 0, -48, 0, 20)
            end
        end

        local storedToken = nil
        function hp:bind(unitToken)
            storedToken = unitToken
            self:RegisterUnitEvent('UNIT_HEALTH', unitToken)
            self:RegisterUnitEvent('UNIT_MAXHEALTH', unitToken)
            self:RegisterUnitEvent('UNIT_THREAT_LIST_UPDATE', unitToken)
            self:RegisterUnitEvent('UNIT_CLASSIFICATION_CHANGED', unitToken)
            self:RegisterEvent('PLAYER_TARGET_CHANGED')

            self:SetMinMaxValues(0, UnitHealthMax(unitToken))
            self:SetValue(UnitHealth(unitToken, false))

            local enemyType = private.enemyType(unitToken)
            local threat = private.threatStatus(unitToken)
            local color = colors[enemyType][threat]
            self:SetStatusBarColor(color.r, color.g, color.b)

            self.tagText:bind(unitToken)
            self.name:bind(unitToken)
            self.pins:bind(unitToken)


            updateSize(unitToken)
        end

        hp:SetScript('OnEvent', function(self, eventName, unitToken)
            if eventName == 'UNIT_MAXHEALTH' then
                hp:SetMinMaxValues(0, UnitHealthMax(unitToken))
            elseif eventName == 'UNIT_HEALTH' then
                hp:SetValue(UnitHealth(unitToken, false))
            elseif eventName == 'UNIT_THREAT_LIST_UPDATE' or eventName == 'UNIT_CLASSIFICATION_CHANGED' then
                local enemyType = private.enemyType(unitToken)
                local threat = private.threatStatus(unitToken)
                local color = colors[enemyType][threat]
                hp:SetStatusBarColor(color.r, color.g, color.b)

                updateSize(unitToken)
            elseif eventName == 'PLAYER_TARGET_CHANGED' then
                updateSize(storedToken)
            end
        end)

        hp.tagText = tagText(nameplate, hp)
        hp.name = name(nameplate, hp)
        hp.pins = targetPins(hp)

        return hp
    end
end
