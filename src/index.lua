local Slab = LibStub("Slab")


local frame = CreateFrame("Frame", "Slab")

local state  = {
    settings = {}
}
function state:registerUnit(unitId)
    local point = Slab.color.name_to_point(UnitName(unitId))
    self.settings[unitId] = {
        point = point,
        tag = unitId
    }
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
    elseif eventName == "UNIT_HEALTH" then
        state:updateUnit(param, function(slab) slab:RefreshHealth(param) end)
    elseif eventName == "UNIT_THREAT_LIST_UPDATE" then
        state:updateUnit(param, function(slab) slab:RefreshColor() end)
    elseif eventName == "UNIT_NAME_UPDATE" then
        state:updateUnit(param, function(slab) slab:RefreshName(param) end)
    elseif eventName == "UNIT_SPELLCAST_START" then
        state:updateUnit(param, function(slab) Slab:ShowCastbar(slab) end)
    elseif eventName == "UNIT_SPELLCAST_STOP" or eventName == "UNIT_SPELLCAST_CHANNEL_STOP" then
        state:updateUnit(param, function(slab) Slab:HideCastbar(slab) end)
    elseif eventName == "UNIT_SPELLCAST_CHANNEL_START" then
        state:updateUnit(param, function(slab) Slab:ShowCastbar(slab, true) end)
    elseif eventName == "UNIT_SPELLCAST_DELAYED" or eventName == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        state:updateUnit(param, function(slab) Slab:UpdateCastDuration(slab, eventName == "UNIT_SPELLCAST_CHANNEL_UPDATE") end)
    elseif eventName == "UNIT_SPELLCAST_INTERRUPTIBLE" or eventName == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        state:updateUnit(param, function(slab) Slab:UpdateCastColor(slab, eventName == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE") end)
    end
end

frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
frame:RegisterEvent("NAME_PLATE_CREATED")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
frame:RegisterEvent("UNIT_NAME_UPDATE")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
frame:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
frame:SetScript("OnEvent", eventHandler)

if NamePlateDriverFrame and NamePlateDriverFrame.AcquireUnitFrame then
    hooksecurefunc(NamePlateDriverFrame,'AcquireUnitFrame', Slab.HookAcquireUnitFrame)
end