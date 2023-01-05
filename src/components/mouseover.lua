---@class LibSlab
local Slab = LibStub("Slab")

---@class MouseoverComponent:Component
---@field public frame MouseoverFrame
local component = {
    dependencies = {'healthBar'}
}

local WIDTH = 6

---@param slab Slab
---@return MouseoverFrame
function component:build(slab)
    local parent = slab.components.healthBar.frame
    ---@class MouseoverFrame:Frame
    local frame = CreateFrame('Frame', parent:GetName() .. 'Mouseover', parent)

    frame:SetAllPoints(slab)
    frame:EnableMouse(true)
    frame:SetMouseClickEnabled(false)

    local bottom = frame:CreateTexture(nil, "HIGHLIGHT", nil, -8)
    bottom:SetPoint("BOTTOMRIGHT", parent, -0.5, 0)
    bottom:SetPoint("BOTTOMLEFT", parent, 0.5, 0)
    bottom:SetHeight(Slab.scale(WIDTH))
    bottom:SetTexture([[Interface\COMMON\talent-blue-glow]])

    local top = frame:CreateTexture(nil, "HIGHLIGHT", nil, -8)
    top:SetPoint("TOPRIGHT", parent, -0.5, 0)
    top:SetPoint("TOPLEFT", parent, 0.5, 0)
    top:SetHeight(Slab.scale(WIDTH))
    top:SetTexture([[Interface\COMMON\talent-blue-glow]])
    top:SetRotation(math.pi)

    return frame
end

---@param settings SlabNameplateSettings
function component:bind(settings)
end

function component:unbind()
end

---@param settings SlabNameplateSettings
function component:refresh(settings)
end

function component:update()
end

Slab.RegisterComponent('mousoverHighlight', component)