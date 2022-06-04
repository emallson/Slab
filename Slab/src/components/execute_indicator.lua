---@class LibSlab
local Slab = LibStub("Slab")

---@class ExecuteIndicatorComponent:Component
---@field public frame ExecuteIndicator
---@field public executeThreshold number|nil
local component = {
    dependencies = {'healthBar'},
    executeThreshold = nil
}

local playerClass = select(2, UnitClass('player'))

local executeThresholds = {
    MAGE = function() if IsPlayerSpell(269644) then return 0.3 else return nil end end
};

---@param slab Slab
---@return ExecuteIndicator
function component:build(slab)
    local parent = slab.components.healthBar.frame
    ---@class ExecuteIndicator:Frame
    local indicator = CreateFrame('Frame', parent:GetName() .. 'ExecuteIndicator', parent)
    indicator:SetPoint('LEFT', parent, 'LEFT', 0, 0)
    indicator:SetSize(Slab.scale(1), parent:GetHeight())
    indicator:SetFrameLevel(1)

    local tex = indicator:CreateTexture(nil, 'OVERLAY')
    tex:SetTexture('interface/buttons/white8x8')
    tex:SetVertexColor(1, 1, 1, 0.3)
    tex:SetAllPoints(indicator)

    indicator:Hide()

    indicator.texture = tex
    indicator.baseWidth = parent:GetWidth()

    return indicator
end

---@param settings SlabNameplateSettings
function component:bind(settings)
    self.frame:RegisterUnitEvent("UNIT_MAXHEALTH", settings.tag)
    self.frame:RegisterEvent("PLAYER_TALENT_UPDATE")
end

function component:unbind()
    self.frame:UnregisterAllEvents()
    self.frame:Hide()
end

---@param settings SlabNameplateSettings
function component:updateLocation(settings)
    local targetMax = UnitHealthMax(settings.tag)

    local ratio = self.executeThreshold

    if ratio == nil or ratio < 0.05 then
        self.frame:Hide()
        return
    end

    local offset = math.floor(ratio * self.frame.baseWidth) + 1

    self.frame:SetPoint('LEFT', self.frame:GetParent(), 'LEFT', offset, 0)

    self.frame:Raise()
    self.frame:Show()
end

---@param settings SlabNameplateSettings
function component:updateThreshold(settings, forceRefresh)
    local current = self.executeThreshold

    local nextFn = executeThresholds[playerClass]

    if nextFn then
        local next = nextFn()

        if next ~= current or forceRefresh then
            self.executeThreshold = next
            self:updateLocation(settings)
        end
    end
end

function component:update(eventName)
    if eventName == "UNIT_MAXHEALTH" then
        self:updateLocation(self.settings)
    elseif eventName == 'PLAYER_TALENT_UPDATE' then
        self:updateThreshold(self.settings)
    end
end

function component:refresh(settings)
    self:updateThreshold(settings, true)
end


if executeThresholds[playerClass] ~= nil then
    Slab.RegisterComponent('executeIndicator', component)
end