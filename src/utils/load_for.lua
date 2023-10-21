---@class LibSlab
local Slab = select(2, ...)

Slab.utils = {}

---@param name string
---@param classes table<string, ComponentConstructor>
function Slab.utils.load_for(name, classes)
  local component = classes[select(2, UnitClass('player'))]
  if component ~= nil then
    Slab.RegisterComponent(name, component)
  end
end

