---@class LibSlab
local Slab = LibStub("Slab")


---@class BolsterIndicatorComponent:Component
---@field public frame BolsterIndicator
local component = {
    dependencies = {'healthBar'},
}

local function isBolsteringActive(affixes)
    if affixes == nil then
        print("no affixes")
        return false
    end
    for _, affix in ipairs(affixes) do
        if (type(affix) == 'number' and affix == 7) or (type(affix) == "table" and affix.id == 7) then
            return true
        end
    end
    return false
end

function component:build(slab)
    local parent = slab.components.healthBar.frame
    ---@class BolsterIndicator:Frame
    local indicator = CreateFrame('Frame', parent:GetName() .. 'BolsterIndicator', parent)
    indicator:SetPoint('CENTER', parent, "RIGHT", -2, 0)
    indicator:SetSize(Slab.scale(3), Slab.scale(3))
    indicator:SetFrameLevel(1)

    local stackCount = indicator:CreateFontString(indicator:GetName() .. 'StackCountText', 'OVERLAY')
    stackCount:SetPoint('RIGHT', indicator, 'RIGHT', 0, 0)
    stackCount:SetFont(Slab.font, Slab.scale(8), "OUTLINE")

    indicator:Hide()
    indicator.stackCount = stackCount
    return indicator
end

---@param settings SlabNameplateSettings
function component:bind(settings)
    -- if we aren't currently in a bolstering key, don't bind any events.
    -- this avoids spurious, and possibly expensive aura iteration
    local level, affixes, _ = C_ChallengeMode.GetActiveKeystoneInfo()

    if not isBolsteringActive(affixes) then
        return
    end
    self.frame:RegisterUnitEvent("UNIT_AURA", settings.tag)
end

local BOLSTER = 209859

function component:refreshAuras(settings)
    local stackCount = 0
    AuraUtil.ForEachAura(settings.tag, "HELPFUL", nil, function(name, icon, _, _, _, _, _, _, _, spellId, ...)
        if spellId == BOLSTER then
            stackCount = stackCount + 1
        end
    end)

    if stackCount > 0 then
        self.frame.stackCount:SetText(stackCount)
        if not self.frame:IsShown() then self.frame:Show() end
    elseif self.frame:IsShown() then
        self.frame:Hide()
    end
end

function component:update(eventName, unitTarget, isFullUpdate, updatedAuras)
    if not AuraUtil.ShouldSkipAuraUpdate(isFullUpdate, updatedAuras, function(aura)
        return aura.spellId == BOLSTER
    end) then
        self:refreshAuras(self.settings)
    end
end

function component:unbind()
    self.frame:UnregisterAllEvents()
end

function component:refresh(settings)
    self:refreshAuras(settings)
end

-- if it isn't bolstering week, don't register the component at all.
-- this avoids frame creation for the entire login session.
--
-- possible issues if you somehow stay online during the transition
-- from one week to the next, as well as on tournament realms.
local function initialBolsterCheck(tries)
    if IsOnTournamentRealm() then
        Slab.RegisterComponent("bolsterIndicator", component)
        return
    end

    local affixes = C_MythicPlus.GetCurrentAffixes()
    if affixes == nil and tries < 3 then
        C_Timer.After(1, function() initialBolsterCheck(tries + 1) end)
        return
    end

    if isBolsteringActive(affixes) then
        Slab.RegisterComponent("bolsterIndicator", component)
        return
    end
end

initialBolsterCheck(0)