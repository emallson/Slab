local Slab = LibStub("Slab")

local WIDTH = 150
local HEIGHT = 15

function Slab:BuildNameplate(parent)
    print("building nameplate for " .. parent:GetName())
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

    frame.healthBar = healthBar
    frame.bg = bg

    parent:HookScript('OnShow', Slab.ShowNameplate)
    parent:HookScript('OnHide', Slab.HideNameplate)

    parent.slab = frame

    function frame:RefreshColor()
        if frame.settings then
            local color = frame.settings.color
            frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
        else
            print("Settings missing for frame")
        end
    end

    function frame:RefreshHealth(unitId)
        frame.healthBar:SetMinMaxValues(0, UnitHealthMax(unitId))
        frame.healthBar:SetValue(UnitHealth(unitId))
    end
end

function Slab.ShowNameplate(parent)
    local frame = parent.slab
    print("Showing nameplate")
    frame:RefreshColor()
    frame:Show()
end

function Slab.HideNameplate(frame)
    --print("Hiding nameplate")
    frame:Hide()
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
