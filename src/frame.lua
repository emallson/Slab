local Slab = LibStub("Slab")

local WIDTH = 150
local HEIGHT = 15

local function IsTank(unit)
    local role = UnitGroupRolesAssigned(unit)
    return role == "TANK"
end

local function threatSaturation(target, source)
    local threatStatus = UnitThreatSituation(target, source)
    if threatStatus == nil then return 1 end
    if IsTank("player") then
        if threatStatus == 1 or threatStatus == 2 then
            return 2
        elseif threatStatus == 0 and IsTank(source .. "target") then
            return 6
        end
    else
        if threatStatus == 1 then
            return 2
        elseif threatStatus > 1 then
            return 6
        end
    end
end

function Slab:GetSlab(unitId)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)

    if nameplate == nil then return nil end
    return nameplate.slab
end

function Slab:BuildNameplate(parent)
    -- print("building nameplate for " .. parent:GetName())
    local frame = CreateFrame('Frame', 'Slab' .. parent:GetName(), parent)
    frame.iSlab = true

    frame:Hide()
    frame:SetAllPoints()
    frame:SetFrameStrata('BACKGROUND')
    frame:SetFrameLevel(0)

    local bg = frame:CreateTexture(frame:GetName() .. 'Background', 'BACKGROUND')
    bg:SetTexture('interface/buttons/white8x8')
    bg:SetSize(WIDTH, HEIGHT)
    bg:SetVertexColor(0.01, 0, 0, .5)
    bg:SetPoint('CENTER')

    local healthBar = CreateFrame('StatusBar', frame:GetName() .. 'HealthBar', parent)
    healthBar:SetStatusBarTexture('interface/raidframe/raid-bar-hp-fill')
    healthBar:SetStatusBarColor(1, 1, 1, 1)
    healthBar:SetSize(WIDTH, HEIGHT)
    healthBar:SetPoint('TOPLEFT', bg)
    healthBar:SetPoint('BOTTOMRIGHT', bg)
    healthBar:SetFrameLevel(0)

    local name = frame:CreateFontString(frame:GetName() .. 'NameText', 'OVERLAY')
    name:SetPoint('BOTTOM', bg, 'TOP', 0, 2)
    name:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")

    local reactionIndicator = frame:CreateFontString(frame:GetName() .. 'IndicatorText', 'OVERLAY')
    reactionIndicator:SetPoint('BOTTOMLEFT', bg, 'TOPLEFT', 0, 2)
    reactionIndicator:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    reactionIndicator:Hide()

    frame.name = name
    frame.reactionIndicator = reactionIndicator
    frame.healthBar = healthBar
    frame.bg = bg

    frame.castBar = Slab:BuildCastbar(frame)

    parent:HookScript('OnShow', Slab.ShowNameplate)
    parent:HookScript('OnHide', Slab.HideNameplate)

    parent.slab = frame

    function frame:RefreshColor()
        if frame.settings then
            local saturation = threatSaturation('player', frame.settings.tag)
            local color = Slab.color.point_to_color(frame.settings.point, saturation)
            frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
        else
            print("Settings missing for frame")
        end
    end

    function frame:RefreshHealth(unitId)
        frame.healthBar:SetMinMaxValues(0, UnitHealthMax(unitId))
        frame.healthBar:SetValue(UnitHealth(unitId))
    end

    function frame:RefreshName(unitId)
        local content = UnitName(unitId)
        name:SetText(content)
    end

    function frame:RefreshIndicator(unitId)
        local reaction = UnitReaction(unitId, 'player')
        if reaction == 4 then
            reactionIndicator:SetText('N')
            -- stolen from plater
            reactionIndicator:SetTextColor(0.9254901, 0.8, 0.2666666, 1)
            reactionIndicator:Show()
        else
            reactionIndicator:Hide()
        end
    end
end

function Slab.ShowNameplate(parent)
    local frame = parent.slab
    --print("Showing nameplate")
    frame:RefreshColor()
    if frame.settings then
        frame:RefreshHealth(frame.settings.tag)
        frame:RefreshName(frame.settings.tag)
        frame:RefreshIndicator(frame.settings.tag)
    end
    Slab:ShowCastbar(frame)
    frame:Show()
end

function Slab.HideNameplate(frame)
    -- print("Hiding nameplate " .. frame:GetName())
    frame.slab:Hide()
    Slab:HideCastbar(frame.slab)
end

local function HideChildFrame(frame)
    if frame:GetParent().slab and not frame.isSlab then
        frame:Hide()
    end
end

-- cribbed from KuiNameplates
function Slab.HookAcquireUnitFrame(_, frame)
    if not frame.UnitFrame:IsForbidden() and not frame.slabHooked then
        frame.slabHooked = true
        frame.UnitFrame:HookScript('OnShow', HideChildFrame)
    end
end
