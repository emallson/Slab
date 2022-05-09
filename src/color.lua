-- cielab -> ciexyz from wikipedia
-- ciexyz -> srgb from https://www.image-engineering.de/library/technotes/958-how-to-convert-between-srgb-and-ciexyz
local cie_delta = 6/29


local function cielab_xyz_rescale(var)
  if var > cie_delta then
    return var ^ 3
  else
    return 3 * cie_delta ^ 2 * (var - 4/29)
  end
end

-- D65 white point in CIE XYZ. taken from emacs color.el
local cielab_ref = { 0.950455, 1.0, 1.088753 }

local function cielab_to_xyz(l, a, b)
  local ref_x, ref_y, ref_z = unpack(cielab_ref)
  local fy = (l + 16) / 116
  local fz = fy - b / 200
  local fx = (a / 500) + fy

  local xr = cielab_xyz_rescale(fx)
  local yr = cielab_xyz_rescale(fy)
  local zr = cielab_xyz_rescale(fz)

  return ref_x * xr, ref_y * yr, ref_z * zr
end

local function xyz_srgb_rescale(var)
  if var > 0.0031308 then
    return 1.055 * var ^ (1 / 2.4) - 0.055
  else
    return var * 12.92
  end
end

local function xyz_to_srgb(x, y, z)
  local var_x = x
  local var_y = y
  local var_z = z

  local var_r = xyz_srgb_rescale(var_x * 3.2406 + var_y * -1.5372 + var_z * -0.4986)
  local var_g = xyz_srgb_rescale(var_x * -0.96926 + var_y * 1.87601 + var_z * 0.04155)
  local var_b = xyz_srgb_rescale(var_x * 0.05564 + var_y * -0.2040259 + var_z * 1.0572252)

  return var_r, var_g, var_b 
end

local cfg = {
    hash_bytes = 8,
    num_colors = 23,
    angles = {0.9565217391304348, 0.43478260869565216, 0.6521739130434783, 0.2608695652173913, 0.8695652173913043, 0.17391304347826086, 0.7391304347826086, 0.4782608695652174, 0.08695652173913043, 0.9130434782608695, 0.391304347826087, 0.6086956521739131, 0.21739130434782608, 0.8260869565217391, 0.043478260869565216, 0.5652173913043478, 0.34782608695652173, 0.782608695652174, 0.13043478260869565, 0.6956521739130435, 0.30434782608695654, 0.5217391304347826, 0.0},
    saturation = 20,
    lightness = 75
}

local function to_angle(val)
  return 2 * math.pi * val
end

---@alias ColorPoint number

---comment
---@param id integer
---@return ColorPoint
local function id_to_point(id)
  local a = cfg.angles[id % cfg.num_colors + 1]
  return to_angle(a)
end

---comment
---@param angle ColorPoint
---@param saturationMultiplier number
---@return RGB
local function point_to_color(angle, saturationMultiplier)
    local saturation = cfg.saturation * (saturationMultiplier or 1)
    local a = saturation * math.cos(angle)
    local b = saturation * math.sin(angle)
    local x, y, z = cielab_to_xyz(cfg.lightness, a, b)
    local sr, sg, sb = xyz_to_srgb(x, y, z)

    ---@class RGB
    return {r = sr, g = sg, b = sb}
end

---@class LibSlab
local Slab = LibStub("Slab")

Slab.color = {
    xyz_to_srgb = xyz_to_srgb,
    cielab_to_xyz = cielab_to_xyz,
    id_to_point = id_to_point,
    point_to_color = point_to_color,
    test_color = function(name) return point_to_color(id_to_point(name), 1) end
}