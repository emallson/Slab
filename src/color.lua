local hash = LibStub("LibHash-1.0")
-- methods to convert from CIE L*a*b to XYZ and from XYZ to sRGB.
-- the L*a*b methods are shamelessly taken from emacs' color.el, while the XYZ->sRGB is from easyrgb.com
local cie_epsilon = 216 / 24389
local cie_kappa = 24389 / 27

local function cielab_xyz_rescale(var)
  if var ^ 3 > cie_epsilon then
    return var ^ 3
  else
    return (var * 116 - 16) / cie_kappa
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
  local yr
  if l > cie_kappa * cie_epsilon then
    yr = ((l + 16) / 116) ^ 3
  else
    yr = l / cie_kappa
  end
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
  local var_g = xyz_srgb_rescale(var_x * -0.9689 + var_y * 1.8758 + var_z * 0.0415)
  local var_b = xyz_srgb_rescale(var_x * 0.0557 + var_y * -0.2040 + var_z * 1.0570)

  return var_r, var_g, var_b 
end

local cfg = {
    hash_bytes = 8,
    num_colors = 256 * 256 * 256,
    saturation = 15,
    lightness = 75
}

local function hash_text(text)
    if text == nil then
      return nil
    end
  
    local bytes = hash.sha256(text)
    local result = 0
    for i=0, cfg.hash_bytes do
        local ix = #bytes - 2 * (i + 1)
        local byte = tonumber(string.sub(bytes, ix, ix+1), 16)
        result = result * 256 + byte
    end
  
    return result
end

local function name_to_point(name)
  local hash = hash_text(name)
  local bucket = hash % cfg.num_colors
  local angle = 2 * math.pi * (bucket / cfg.num_colors)
  return angle
end

local function point_to_color(angle, saturationMultiplier)
    local saturation = cfg.saturation * (saturationMultiplier or 1)
    local a = saturation * math.cos(angle)
    local b = saturation * math.sin(angle)
    local x, y, z = cielab_to_xyz(cfg.lightness, a, b)
    local sr, sg, sb = xyz_to_srgb(x, y, z)

    return {r = sr, g = sg, b = sb}
end

local Slab = LibStub("Slab")

Slab.color = {
    xyz_to_srgb = xyz_to_srgb,
    cielab_to_xyz = cielab_to_xyz,
    name_to_point = name_to_point,
    point_to_color = point_to_color
}