---@class LibSlab
local Slab = LibStub("Slab")

---@param component ComponentConstructor
---@param name string
---@param class_name string
function Slab.combinators.load_for(component, name, class_name)
    if select(2, UnitClass('player')) == class_name then
        Slab.RegisterComponent(name, component)
    end
end