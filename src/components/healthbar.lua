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

local component = {}

function component:refreshName(settings, recomputeColor)
    local name = UnitName(settings.tag)
    self.frame.name:SetText(name)

    if recomputeColor then
        settings.point = Slab.color.name_to_point(name)
        self:refreshColor(settings)
    end
end

function component:refreshColor(settings)
    local saturation = threatSaturation('player', settings.tag)
    local color = Slab.color.point_to_color(settings.point, saturation)
    self.frame:SetStatusBarColor(color.r, color.g, color.b)
end

function component:refreshHealth(settings)
    local unitId = settings.tag
    self.frame:SetMinMaxValues(0, UnitHealthMax(unitId))
    self.frame:SetValue(UnitHealth(unitId))
end

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


function component:refresh(settings)
    self:refreshName(settings, false)
    self:refreshColor(settings)
    self:refreshHealth(settings)
    self:refreshTargetMarker(settings)
end

function component:bind(settings)
    self.frame:RegisterUnitEvent('UNIT_HEALTH', settings.tag)
    self.frame:RegisterUnitEvent('UNIT_THREAT_LIST_UPDATE', settings.tag)
    self.frame:RegisterEvent('RAID_TARGET_UPDATE')
    self.frame:RegisterUnitEvent("UNIT_NAME_UPDATE", settings.tag)
end

function component:update(eventName, ...)
    if eventName == 'UNIT_NAME_UPDATE' then
        self:refreshName(self.settings, true)
    elseif eventName == 'UNIT_HEALTH' then
        self:refreshHealth(self.settings)
    elseif eventName == 'UNIT_THREAT_LIST_UPDATE' then
        self:refreshColor(self.settings)
    elseif eventName == 'RAID_TARGET_UPDATE' then
        self:refreshTargetMarker(self.settings)
    end
end

function component:build(parent)
    local healthBar = CreateFrame('StatusBar', parent:GetName() .. 'HealthBar', parent)

    local bg = healthBar:CreateTexture(healthBar:GetName() .. 'Background', 'BACKGROUND')
    bg:SetTexture('interface/buttons/white8x8')
    bg:SetSize(WIDTH, HEIGHT)
    bg:SetVertexColor(0.01, 0, 0, .5)
    bg:SetPoint('CENTER')

    healthBar:SetStatusBarTexture('interface/raidframe/raid-bar-hp-fill')
    healthBar:SetStatusBarColor(1, 1, 1, 1)
    healthBar:SetSize(WIDTH, HEIGHT)
    healthBar:SetPoint('CENTER')

    local raidMarker = healthBar:CreateTexture(healthBar:GetName() .. 'RaidMarker', 'OVERLAY')
    raidMarker:SetPoint('LEFT', bg, 'LEFT', 2, 0)
    raidMarker:SetSize(HEIGHT - 2, HEIGHT - 2)
    raidMarker:Hide()

    local name = healthBar:CreateFontString(healthBar:GetName() .. 'NameText', 'OVERLAY')
    name:SetPoint('BOTTOM', bg, 'TOP', 0, 2)
    name:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")

    local reactionIndicator = healthBar:CreateFontString(healthBar:GetName() .. 'IndicatorText', 'OVERLAY')
    reactionIndicator:SetPoint('BOTTOMLEFT', bg, 'TOPLEFT', 0, 2)
    reactionIndicator:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    reactionIndicator:Hide()

    healthBar.raidMarker = raidMarker
    healthBar.bg = bg
    healthBar.name = name
    healthBar.reactionIndicator = reactionIndicator

    return healthBar
end

Slab.RegisterComponent('healthBar', component)