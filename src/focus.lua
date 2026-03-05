---@class SlabPrivate
local private = select(2, ...)

do
    local cooldownSpells = {
        116705, -- Spear Hand Strike (Monk)
        47528, -- Mind Freeze (DK)
        183752, -- Disrupt (DH)
        78675, -- Solar Beam (Balance Druid)
        106839, -- Skull Bash (Feral/Guardian Druid)
        351338, -- Quell (Evoker)
        187707, -- Muzzle (SV Hunter)
        147362, -- Counter Shot (MM/BM Hunter)
        2139, -- Counterspell (Mage)
        96231, -- Rebuke (Paladin)
        15487, -- Silence (Priest)
        1766, -- Kick (Rogue)
        57994, -- Wind Shear (Shaman)
        6552, -- Pummel (Warrior)
    }

    local petCooldownSpells = {
        19647, -- Spell Lock (Warlock Felhound)
        89766, -- Axe Toss (Warlock Felguard)
    }

    function private.frames.focusIndicator(nameplate, parent)
        local currentSpellId

        local frame = CreateFrame('Frame', parent:GetName() .. 'Focus', parent)
        frame:SetPoint('LEFT', parent, 'RIGHT', 3, 0)
        PixelUtil.SetSize(frame, 27, 27)

        local cd = CreateFrame('Cooldown', frame:GetName() .. 'Cooldown', frame)
        cd:SetAllPoints(frame)
        cd:SetHideCountdownNumbers(true)
        cd:SetDrawSwipe(true)
        local cooldownColor = private.color.DANGER_COLOR
        cd:SetSwipeTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", cooldownColor.r, cooldownColor.g, cooldownColor.b, 1)
        cd:SetSwipeColor(cooldownColor.r, cooldownColor.g, cooldownColor.b, 1)

        local bg = frame:CreateTexture()
        bg:SetDrawLayer("BACKGROUND", -8)
        bg:SetPoint('CENTER', frame, 'CENTER', 0, 0)
        PixelUtil.SetSize(bg, 26, 26)
        bg:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask")
        bg:SetVertexColor(0, 0, 0, 0.8)
        bg:Hide()

        local iconFrame = CreateFrame('Frame', nil, frame)
        iconFrame:SetAllPoints(frame)
        
        local bg2 = iconFrame:CreateTexture()
        bg2:SetDrawLayer('OVERLAY', 4)
        bg2:SetPoint('CENTER', frame, 'CENTER', 0, 0)
        PixelUtil.SetSize(bg2, 22, 22)
        bg2:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", nil, nil, "TRILINEAR")
        bg2:SetVertexColor(0, 0, 0, 0.8)

        local icon = iconFrame:CreateTexture()
        icon:SetAtlas('Bonus-Objective-Star', false, 'TRILINEAR')
        icon:SetPoint('CENTER', frame, 'CENTER', 0, 0)
        PixelUtil.SetSize(icon, 20, 20)
        icon:SetDrawLayer('OVERLAY', 5)

        local mask = iconFrame:CreateMaskTexture()
        mask:SetPoint('CENTER', frame, 'CENTER', 0, 0)
        PixelUtil.SetSize(mask, 20, 20)
        mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "TRILINEAR")
        icon:AddMaskTexture(mask)

        local function refresh(unitToken)
            if not UnitExists('focus') or not UnitIsUnit(unitToken, 'focus') then
                frame:Hide()
            else
                frame:Show()
            end
        end

        local function updateCooldownDisplay(spellId)
            if not spellId then
                icon:SetAtlas('Bonus-Objective-Star', false, "TRILINEAR")
                PixelUtil.SetSize(icon, 20, 20)
                bg:Hide()
                cd:Hide()
            else
                local spellinfo = C_Spell.GetSpellInfo(spellId)
                if spellinfo == nil then
                    updateCooldownDisplay(nil)
                    return
                end

                bg:Show()
                icon:SetTexture(spellinfo.iconID, nil, nil, 'TRILINEAR')
                PixelUtil.SetSize(icon, 22, 22)
                local duration = C_Spell.GetSpellCooldownDuration(spellId)
                cd:SetCooldownFromDurationObject(duration, true)
            end
        end

        local function updateCooldownSpell()
            if currentSpellId and not C_SpellBook.IsSpellInSpellBook(currentSpellId, Enum.SpellBookSpellBank.Player, false) and not C_SpellBook.IsSpellInSpellBook(currentSpellId, Enum.SpellBookSpellBank.Pet, false) then
                currentSpellId = nil
            end
            if currentSpellId == nil then
                for _, spellId in ipairs(cooldownSpells) do
                    if C_SpellBook.IsSpellInSpellBook(spellId, Enum.SpellBookSpellBank.Player, false) then
                        currentSpellId = spellId
                        break
                    end
                end
                for _, spellId in ipairs(petCooldownSpells) do
                    if C_SpellBook.IsSpellInSpellBook(spellId, Enum.SpellBookSpellBank.Pet, false) then
                        currentSpellId = spellId
                        break
                    end
                end
            end

            updateCooldownDisplay(currentSpellId)
        end

        local storedToken

        function frame:bind(unitToken)
            storedToken = unitToken
            frame:RegisterEvent('PLAYER_FOCUS_CHANGED')
            frame:RegisterEvent('SPELL_UPDATE_COOLDOWN')
            frame:RegisterEvent('SPELLS_CHANGED')

            updateCooldownSpell()
            refresh(unitToken)
        end

        function frame:unbind()
        end

        frame:SetScript('OnEvent', function(frame, eventType, ...)
            if eventType == 'PLAYER_FOCUS_CHANGED' then
                refresh(storedToken)
            elseif eventType == 'SPELL_UPDATE_COOLDOWN' and currentSpellId ~= nil and select(1, ...) == currentSpellId then
                local duration = C_Spell.GetSpellCooldownDuration(currentSpellId)
                cd:SetCooldownFromDurationObject(duration, true)
            elseif eventType == 'SPELLS_CHANGED' then
                updateCooldownSpell()
            end
        end)

        return frame
    end
end