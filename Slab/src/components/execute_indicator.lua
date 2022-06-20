---@class LibSlab
local Slab = LibStub("Slab")

---@class ExecuteIndicatorComponent:Component
---@field public frame ExecuteIndicator
---@field public executeThreshold number|nil
local component = {
    dependencies = {'healthBar'},
    executeThreshold = nil
}

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
end

function component:unbind()
    self.frame:UnregisterAllEvents()
    self.frame:Hide()
end

---@param settings SlabNameplateSettings
function component:updateLocation(settings)
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

function component:update(eventName)
    if eventName == "UNIT_MAXHEALTH" then
        self:updateLocation(self.settings)
    end
end

function component:refresh(settings)
    self:updateLocation(settings)
end

searingTouchComponent = Slab.combinators.enable_when_spell(component, 269644, nil, function(self, settings)
    self.executeThreshold = 0.3
    self:updateLocation(settings)
end)
Slab.combinators.load_for(searingTouchComponent, 'executeIndicator', 'MAGE')

firestarterComponent = Slab.combinators.enable_when_spell(component, 205026, nil, function(self, settings)
    self.executeThreshold = 0.9
    self:updateLocation(settings)
end)
Slab.combinators.load_for(firestarterComponent, 'firestarterIndicator', 'MAGE')