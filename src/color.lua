-- source: http://wiki.nuaj.net/index.php/Color_Transforms#HSL_.E2.86.92_RGB
local function hue_to_rgb_component(v1, v2, vH)
  if vH < 0 then
    vH = vH + 1
  end
  if vH > 1 then
    vH = vH - 1
  end

  if 6 * vH < 1 then return v1 + (v2 - v1) * 6 * vH end
  if 2 * vH < 1 then return v2 end
  if 3 * vH < 2 then return v1 + (v2 - v1) * (2 / 3 - vH) * 6 end

  return v1
end

---Convert from HSL to sRGB
-- source: http://wiki.nuaj.net/index.php/Color_Transforms#HSL_.E2.86.92_RGB
---@param hue number degrees
---@param saturation number 0-100
---@param lightness number 0-100
---@return RGB
local function hsl_to_srgb(hue, saturation, lightness)
  saturation = saturation / 100
  hue = hue / 360
  lightness = lightness / 100
  if saturation == 0 then
    return { r = lightness, g = lightness, b = lightness }
  end

  local var1, var2
  if lightness < 0.5 then
    var2 = lightness * (1 + saturation)
  else
    var2 = lightness + saturation - saturation * lightness
  end

  var1 = 2 * lightness - var2

  ---@class RGB
  return {
    r = hue_to_rgb_component(var1, var2, hue + 1 / 3),
    g = hue_to_rgb_component(var1, var2, hue),
    b = hue_to_rgb_component(var1, var2, hue - 1 / 3),
  }
end
---@class SlabPrivate
local private = select(2, ...)

private.color = {
  hsl_to_srgb = hsl_to_srgb,
}
