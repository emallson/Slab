---@class LibSlab
local Slab = LibStub("Slab")

---@class SlabContainer:Frame
---@field public slab Slab|nil

---Scale the provider number based on the current UI scale.
---@param value number
---@return integer
function Slab.scale(value)
    return math.ceil(value * UIParent:GetScale())
end

---Get the current Slab for a unit
---@param unitId UnitId
---@return Slab|nil
function Slab:GetSlab(unitId)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)

    if nameplate == nil then return nil end
    return nameplate.slab
end

---Build a new nameplate from scratch
---@param parent Frame
function Slab:BuildNameplate(parent)
    ---@class Slab:Frame
    ---@field public settings SlabNameplateSettings|nil
    ---@field public components table<string, ComponentConstructed>
    local frame = CreateFrame('Frame', 'Slab' .. parent:GetName(), parent)
    frame.isSlab = true

    frame:Hide()
    frame:SetAllPoints()
    frame:SetFrameStrata('BACKGROUND')
    frame:SetFrameLevel(0)
    frame:SetScale(1 / UIParent:GetScale())

    Slab.BuildComponentTable(frame)

    parent:HookScript('OnShow', Slab.ShowNameplate)
    parent:HookScript('OnHide', Slab.HideNameplate)

    parent.slab = frame
end

---Show the nameplate.
---@param parent SlabContainer
function Slab.ShowNameplate(parent)
    local frame = parent.slab
    if frame ~= nil and frame.settings then
        for _, component in pairs(frame.components) do
            component:show(frame.settings)
        end
    end
    if frame ~= nil then
        frame:Show()
    end
end

---@param frame SlabContainer
function Slab.HideNameplate(frame)
    frame.slab:Hide()
    for _, component in pairs(frame.slab.components) do
        component:hide()
    end
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
