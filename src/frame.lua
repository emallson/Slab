local Slab = LibStub("Slab")


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
    frame:SetIgnoreParentScale(true)
    frame:SetScale(1 / UIParent:GetScale())

    local healthBar = Slab.BuildComponent('healthBar', frame)

    frame.components = {
        healthBar = healthBar,
        castBar = Slab.BuildComponent('castBar', healthBar.frame)
    }

    parent:HookScript('OnShow', Slab.ShowNameplate)
    parent:HookScript('OnHide', Slab.HideNameplate)

    parent.slab = frame
end

function Slab.ShowNameplate(parent)
    local frame = parent.slab
    --print("Showing nameplate")
    if frame.settings then
        for _, component in pairs(frame.components) do
            component:show(frame.settings)
        end
    end
    frame:Show()
end

function Slab.HideNameplate(frame)
    -- print("Hiding nameplate " .. frame:GetName())
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
