---@class LibSlab
local Slab = LibStub("Slab")


local frame = CreateFrame("Frame", "Slab")

---@param npcId integer
---@return boolean
local function isSpecialUnit(npcId)
    return npcId == 120651
end

---@alias UnitId string

local state  = {
    ---@type table<string, SlabNameplateSettings>
    settings = {}
}
function state:registerUnit(unitId)
    local npcId = Slab.UnitNpcId(unitId)
    local point

    if isSpecialUnit(npcId) then
        point = Slab.color.special_point
    else
        point = Slab.color.id_to_point(npcId)
    end

    ---@class SlabNameplateSettings
    local setting = {
        ---@type ColorPoint
        point = point,
        ---@type UnitId
        tag = unitId
    }
    self.settings[unitId] = setting
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)

    if nameplate and nameplate.slab then
        --print(string.format("Registered: %s (#%02x%02x%02x)", UnitName(unitId), r * 255, g * 255, b * 255))
        nameplate.slab.settings = self.settings[unitId]
        Slab.ShowNameplate(nameplate)
    end
end
function state:deregisterUnit(unitId)
    self.settings[unitId] = nil
end

function state:initFrame(nameplate)
    if nameplate ~= nil then
        Slab:BuildNameplate(nameplate)
    end
end

function state:updateUnit(unitId, fn)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)
    if nameplate and nameplate.slab then
        fn(nameplate.slab)
    end
end

local function eventHandler(_frame, eventName, param)
    if eventName == "NAME_PLATE_UNIT_ADDED" then
        state:registerUnit(param)
    elseif eventName == "NAME_PLATE_UNIT_REMOVED" then
        state:deregisterUnit(param)
    elseif eventName == "NAME_PLATE_CREATED" then
        state:initFrame(param)
    end
end

frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
frame:RegisterEvent("NAME_PLATE_CREATED")
frame:SetScript("OnEvent", eventHandler)

if NamePlateDriverFrame and NamePlateDriverFrame.AcquireUnitFrame then
    hooksecurefunc(NamePlateDriverFrame,'AcquireUnitFrame', Slab.HookAcquireUnitFrame)
end

Slab.font = "Fonts\\FRIZQT__.TTF"

local relevantCVars = {
    "NamePlateMinAlpha",
    "NamePlateMinAlphaDistance",
    "NamePlateMinScale",
    "NamePlateMinScaleDistance",
    "NamePlateMaxScale",
    "NamePlateMaxScaleDistance"
}

local function ResetCVars()
    for _, cvar in ipairs(relevantCVars) do
        C_CVar.SetCVar(cvar, C_CVar.GetCVarDefault(cvar))
    end
end

ResetCVars()

local function SetCustomCVars()
    -- the NamePlateHorizontalScale setting is important
    -- to make the mouseover target match the visible frame
    C_CVar.SetCVar("NamePlateHorizontalScale", 1.4)
end

SetCustomCVars()