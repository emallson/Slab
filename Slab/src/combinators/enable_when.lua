---@class LibSlab
local Slab = LibStub("Slab")

local function defaultSelector(component)
    return component.frame
end

---@param baseComponent ComponentConstructor
---@param condition function
---@param updateEvent? WowEvent
---@param selector? function
---@param onUpdate? function
---@return ComponentConstructor
local function enable_when(baseComponent, condition, updateEvent, selector, onUpdate)
    if selector == nil then
        selector = defaultSelector
    end

    local component = {}
    setmetatable(component, { __index = baseComponent })
    
    function component:build(slab)
        local frame = baseComponent.build(self, slab)
        frame.disabled = true
        return frame
    end

    function component:disabled()
        return self.frame.disabled
    end
    
    local function refreshCondition(self, settings)
        if condition(component, settings) then
            self.frame.disabled = false
            if onUpdate ~= nil then
                onUpdate(self, settings)
            end
            local frame = selector(self)
            frame:Show()
        elseif not self:disabled() then
            self.frame.disabled = true
            local frame = selector(self)
            frame:Hide()
        end
    end

    function component:refresh(settings)
        refreshCondition(self, settings)
        if not self:disabled() then
            baseComponent.refresh(self, settings)
        end
    end

    function component:update(eventName, ...)
        if eventName == updateEvent then
            refreshCondition(self, self.settings)
        elseif not self:disabled() then
            baseComponent.update(self, eventName, ...)
        end
    end

    function component:bind(settings)
        if updateEvent then
            self.frame:RegisterEvent(updateEvent)
        end
        baseComponent.bind(self, settings)
    end

    return component
end

---@param component ComponentConstructor
---@param spellId integer
---@param onUpdate? function
---@param selector? function
---@return ComponentConstructor
local function enable_when_spell(component, spellId, onUpdate, selector)
    return enable_when(
        component, 
        function() return IsPlayerSpell(spellId) end,
        "PLAYER_TALENT_UPDATE",
        selector,
        onUpdate
    )
end

Slab.combinators.enable_when = Slab.combinator(enable_when)
Slab.combinators.enable_when_spell = Slab.combinator(enable_when_spell)