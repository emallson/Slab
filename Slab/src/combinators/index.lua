---@class LibSlab
local Slab = LibStub("Slab")


---@alias ComponentTransform fun(component: ComponentConstructor): ComponentConstructor
---@alias SlabCombinator fun(...: any): ComponentTransform

---Produce a combinator function from a regular component-accepting function.
---@param f fun(component: ComponentConstructor, ...: any): ComponentConstructor
---@return SlabCombinator
function Slab.combinator(f)
    ---@param ... any
    ---@return fun(component: ComponentConstructor): ComponentConstructor
    return function(...)
        local varargs = {...}
        ---@param component ComponentConstructor
        ---@return ComponentConstructor
        return function(component)
            return f(component, unpack(varargs))
        end
    end
end

---Apply a stack of transforms to a component constructor.
---@param component ComponentConstructor
---@param ... ComponentTransform[]
---@return ComponentConstructor
function Slab.apply_combinators(component, ...)
    for i=1,select("#", ...) do
        local transform = select(i, ...)
        component = transform(component)
    end
    return component
end

Slab.combinators = {}