---@class LibSlab
local Slab = LibStub('Slab')

local function mustOverride()
    error('Method must be overridden')
end

---@class Component
---@field public settings SlabNameplateSettings|nil
---@field public frame Frame
---@field public dependencies table<string>
local baseComponent = {
    ---Construct the frames to be used for the component. They are not bound to any particular unit at this point.
    ---@param parent Frame
    ---@return Frame
    build = mustOverride,
    dependencies = {},
}

---Refresh the component's state using the provided settings, including the unit id.
---@param settings SlabNameplateSettings
function baseComponent:refresh(settings)
end

---Set up any event handlers necessary for the component to function.
---@param settings SlabNameplateSettings
function baseComponent:bind(settings)
end

local function unbind(component)
    if component.frame then
        component.frame:UnregisterAllEvents()
    end
end

---Remove all event handlers used by the component. This is enforced.
function baseComponent:unbind()
end
---Update component state based on an event.
---@param eventName string
---@vararg any event details
function baseComponent:update(eventName, ...)
end

---Produce a component constructor from a component.
---@param table Component
---@return ComponentConstructor
function Slab.Component(table)
    ---@class ComponentConstructor : Component
    local table = table
    setmetatable(table, { __index = baseComponent })

    local mt = {
        __index = table
    }

    ---Construct the component
    ---@param parent Frame
    ---@return Component
    function table.construct(parent)
        local self = {}
        setmetatable(self, mt)
        self.frame = self:build(parent)
        if self.frame == nil then return nil end
        self.frame:SetScript('OnEvent', function(frame, eventName, ...)
            self:update(eventName, ...)
        end)
        return self
    end

    ---Show the component, binding it and refreshing it.
    ---@param settings SlabNameplateSettings
    function table:show(settings)
        self.settings = settings
        self:bind(settings)
        self:refresh(settings)
    end

    ---Hide the component, unbinding it.
    function table:hide()
        self:unbind()
        unbind(self)
    end
    return table
end

---@type table<string, ComponentConstructor>
local registry = {}

---Register a component
---@param key string
---@param component Component
function Slab.RegisterComponent(key, component)
    registry[key] = Slab.Component(component)
end

---@alias ComponentConstructed ComponentConstructor

---Construct a component.
---@param key string
---@param parent Slab
---@return ComponentConstructed
function Slab.BuildComponent(key, parent)
    local component = registry[key]

    if component == nil then
        error('No component exists: ' .. key)
        return nil
    else
        for _, dep in ipairs(component.dependencies) do
            if parent.components[dep] == nil then
                -- dependency not present, skip
                return nil
            end
        end
    end

    return component.construct(parent)
end

local buildList = nil
local function generateBuildList()
    if buildList ~= nil then return end
    -- topo sort the components
    buildList = {}
    local temp = {}
    local perm = {}

    local function visit(key)
        if perm[key] then return end
        if temp[key] then
            buildList = {}
            error('Slab: circular component dependency. Bailing. Key:' .. key)
            return
        end

        temp[key] = true
        for _, dep in ipairs(registry[key].dependencies) do
            visit(dep)
        end

        temp[key] = false
        perm[key] = true
        table.insert(buildList, key)
    end

    for key, _ in pairs(registry) do
        visit(key)
    end
end

---Builds the `component` table for a Slab from registered components.
---@param slab Slab
function Slab.BuildComponentTable(slab)
    generateBuildList()

    slab.components = {}
    for _, key in ipairs(buildList) do
        local c = Slab.BuildComponent(key, slab)
        if c ~= nil then
            slab.components[key] = c
        end
    end
end