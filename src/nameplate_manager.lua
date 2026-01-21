---@class SlabPrivate
local private = select(2, ...)

local mgr = CreateFrame("Frame", 'SlabNameplateManager')

mgr:RegisterEvent('NAME_PLATE_CREATED')
mgr:RegisterEvent('NAME_PLATE_UNIT_ADDED')
mgr:RegisterEvent('NAME_PLATE_UNIT_REMOVED')

C_NamePlate.SetNamePlateSize(300, 40)
C_CVar.SetCVar('nameplateMinScale', 1)
C_CVar.SetCVar('nameplateSelectedScale', 1.1)

---@param nameplate Nameplate
---@return boolean
local function isWidgetNameplate(nameplate)
    local unitToken = nameplate.namePlateUnitToken or nameplate.unitToken
    return unitToken ~= nil and UnitNameplateShowsWidgetsOnly(unitToken)
end

-- these hacks are based on the Platynator ones. once we finally get HitRect APIs that are actually usable, it should all go away (i hope)

local hookedUnitFrames = {}

---@param nameplate Nameplate
local function hideBlizzardFrame(nameplate)
    if isWidgetNameplate(nameplate) then
        return -- we're not touching these
    end
    
    if nameplate.UnitFrame then
        nameplate.UnitFrame:SetAlpha(0)
        if not hookedUnitFrames[nameplate.UnitFrame] then
            hookedUnitFrames[nameplate.UnitFrame] = true
            local oldSetAlpha = nameplate.UnitFrame.SetAlpha
            hooksecurefunc(nameplate.UnitFrame, 'SetAlpha', function(frame)
                if frame:IsForbidden() then return end
                oldSetAlpha(frame, 0)
            end)
        end

        nameplate.UnitFrame:UnregisterAllEvents()
        if nameplate.UnitFrame.castBar then
            nameplate.UnitFrame.castBar:UnregisterAllEvents()
        end
    end
end

local function unhideBlizzardFrame(nameplate)
    if isWidgetNameplate(nameplate) then
        return
    end

    -- not sure we actually need to do anything right now?
end

mgr:SetScript('OnEvent', function (self, eventType, ...)
    if eventType == 'NAME_PLATE_CREATED' then
        ---@type Nameplate
        local nameplate = ...
        hideBlizzardFrame(nameplate)
        nameplate = private.createNameplate(nameplate)
    elseif eventType == 'NAME_PLATE_UNIT_ADDED' then
        local nameplateToken = ...
        ---@type Nameplate|SlabRootMixin|nil
        local nameplate = C_NamePlate.GetNamePlateForUnit(nameplateToken, false)
        if nameplate == nil then return end
        if isWidgetNameplate(nameplate) then return end

        hideBlizzardFrame(nameplate)

        nameplate.slab:bind(nameplateToken)
        nameplate.slab:Show()
    elseif eventType == 'NAME_PLATE_UNIT_REMOVED' then
        local nameplateToken = ...
        ---@type Nameplate|SlabRootMixin|nil
        local nameplate = C_NamePlate.GetNamePlateForUnit(nameplateToken, false)
        if nameplate == nil then return end

        nameplate.slab:unbind()
        nameplate.slab:Hide()

        unhideBlizzardFrame(nameplate)
    end
end)