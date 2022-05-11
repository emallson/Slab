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
    angles = {0.9411764705882353, 0.4117647058823529, 0.6470588235294118, 0.17647058823529413, 0.8235294117647058, 0.35294117647058826, 0.5882352941176471, 0.11764705882352941, 0.8823529411764706, 0.47058823529411764, 0.23529411764705882, 0.7647058823529411, 0.058823529411764705, 0.7058823529411765, 0.29411764705882354, 0.5294117647058824, 0.0},
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