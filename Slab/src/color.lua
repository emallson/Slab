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
    num_colors = 17,
    angles = {0.9444444444444444, 0.5, 0.2777777777777778, 0.7777777777777778, 0.16666666666666666, 0.6666666666666666, 0.3888888888888889, 0.8888888888888888, 0.1111111111111111, 0.6111111111111112, 0.3333333333333333, 0.8333333333333334, 0.05555555555555555, 0.5555555555555556, 0.2222222222222222, 0.7222222222222222, 0.4444444444444444},
    special_angle = 0.0,
    saturation = 20,
    lightness = 75
}

local function to_angle(val)
  return 2 * math.pi * val
end

---@alias ColorPoint number

---@param id integer
---@return ColorPoint
local function id_to_point(id)
  local a = cfg.angles[id % cfg.num_colors + 1]
  return to_angle(a)
end

---Color used for special enemies like Explosive Orbs
local special_point = to_angle(cfg.special_angle)

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
    special_point = special_point,
    point_to_color = point_to_color,
    test_color = function(name) return point_to_color(id_to_point(name), 1) end
}
