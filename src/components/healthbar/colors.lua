---@class LibSlab
local Slab = LibStub("Slab")


local WARNING_COLOR = Slab.color.hsl_to_srgb(57, 100, 60)
local DANGER_COLOR = Slab.color.hsl_to_srgb(1, 100, 55)

---@param hue number
---@param saturation number
---@param lightness number
---@param otSaturation number?
---@param otLightness number?
---@return table<ThreatStatus, RGB>
local function colorTable(hue, saturation, lightness, otSaturation, otLightness)
    local active = Slab.color.hsl_to_srgb(hue, saturation, lightness)
    local offtank = Slab.color.hsl_to_srgb(hue, otSaturation or 15, otLightness or 80)

    return {
        ["active"] = active,
        ["noncombat"] = active,
        ["offtank"] = offtank,
        ["pet"] = offtank,
        ["warning"] = WARNING_COLOR,
        ["danger"] = DANGER_COLOR
    }
end

---@type table<EnemyType, table<ThreatStatus, RGB>>
local colors = {
    ["boss"] = colorTable(90, 4, 40, 1, 90),
    ["lieutenant"] = colorTable(194, 25, 65),
    ["caster"] = colorTable(259, 60, 65),
    ["normal"] = colorTable(117, 60, 65),
    ["trivial"] = colorTable(47, 25, 80),
    ["special"] = colorTable(22, 100, 65, 55, 80),
}

Slab.color.threat = colors