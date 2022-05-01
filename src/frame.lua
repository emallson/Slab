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

    frame.healthBar = Slab.BuildComponent('healthBar', frame)

    frame.name = name
    frame.reactionIndicator = reactionIndicator

    frame.castBar = Slab:BuildCastbar(frame)

    parent:HookScript('OnShow', Slab.ShowNameplate)
    parent:HookScript('OnHide', Slab.HideNameplate)

    parent.slab = frame

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
    if frame.settings then
        frame.healthBar:show(frame.settings)
        frame:RefreshName(frame.settings.tag)
        frame:RefreshIndicator(frame.settings.tag)
    end
    Slab:ShowCastbar(frame)
    frame:Show()
end

function Slab.HideNameplate(frame)
    -- print("Hiding nameplate " .. frame:GetName())
    frame.slab:Hide()
    if frame.healthBar then
        frame.healthBar:hide()
    end
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
