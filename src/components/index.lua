local Slab = LibStub('Slab')

local function mustOverride()
    error('Method must be overridden')
end

local baseComponent = {
    build = mustOverride,
}

function baseComponent:refresh(self, settings)
end

function baseComponent:bind(self, settings)
end

local function unbind(component)
    if component.frame then
        component.frame:UnregisterAllEvents()
    end
end

function baseComponent:unbind(self)
end
function baseComponent:update(self)
end

function Slab.Component(table)
    setmetatable(table, baseComponent)

    local mt = {
        __index = table
    }

    function table.construct(parent)
        local self = {}
        setmetatable(self, mt)
        self.frame = self:build(parent)
        self.frame:SetScript('OnEvent', function(frame, eventName, ...)
            self:update(eventName, ...)
        end)
        return self
    end

    function table:show(settings)
        self.settings = settings
        self:bind(settings)
        self:refresh(settings)
    end

    function table:hide()
        self:unbind()
        unbind(self)
    end
    return table
end

local registry = {}

function Slab.RegisterComponent(key, component)
    registry[key] = Slab.Component(component)
end

function Slab.BuildComponent(key, parent)
    local component = registry[key]

    if component == nil then
        error('No component exists: ' .. key)
        return nil
    end

    return component.construct(parent)
end