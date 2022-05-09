---@type LibSlab
local Slab = LibStub('Slab')

local BenchFrame = CreateFrame('Frame', 'BenchFrame', UIParent)
BenchFrame:SetPoint('CENTER')
BenchFrame:SetSize(100, 100)

BenchFrame:Show()

local SIXTY_FPS = 1000 / 60

---Run the closure `iters` times, measuring total time taken.
---@param iters integer
---@param closure fun()
---@return ProfileResult
local function profile(iters, closure)
    local startTime = debugprofilestop()
    for i=0, iters do
        closure()
    end
    local endTime = debugprofilestop()

    local duration = (endTime - startTime) / iters

    ---@class ProfileResult
    return {
        startTime = startTime,
        endTime = endTime,
        iterDuration = duration,
        frameRatio = duration / SIXTY_FPS
    }
end

local function componentProfile(method)
    local results = {}
    for key, component in pairs(Slab.componentRegistry) do
        local total, count = GetFunctionCPUUsage(component[method])
        results[key] = total / count
    end
    return results
end

ResetCPUUsage()


local stats = {
    profiles = {}
}

stats.profiles.build = profile(10000, function ()
    BenchFrame.slab = nil
    Slab:BuildNameplate(BenchFrame)

    BenchFrame.slab:Hide()
end)
stats.build = componentProfile('build')

stats.profiles.showhide = profile(10000, function()
    BenchFrame.slab.settings = {
        tag = 'player',
        point = 0
    }
    Slab.ShowNameplate(BenchFrame)
    Slab.HideNameplate(BenchFrame)
end)

stats.refresh = componentProfile('refresh')
stats.bind = componentProfile('bind')
stats.unbind = componentProfile('unbind')

stats.profiles.fastrandom = profile(10000, function()
    fastrandom(0, 256^3)
end)
stats.profiles.color = profile(10000, function()
    Slab.color.id_to_point(fastrandom(0, 256^3))
end)

stats.profiles.npcId = profile(10000, function()
    Slab.UnitNpcId('target')
end)

DevTools_Dump(stats)

local frame = CreateFrame('Frame')

frame:SetScript('OnEvent', function()
    Slab_Bench = {
        stats = stats
    }
end)

frame:RegisterEvent('ADDON_LOADED')