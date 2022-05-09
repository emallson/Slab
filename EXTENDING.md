It is possible to extend Slab by registering a component. Components have a very basic lifecycle that will be reminescent of React (if you've worked with that). The core is:

- `build` - Create any frames that you will need. This generally happens once. You do not have a unit to pull data from yet. Should return a `Frame`. May return `nil` to prevent construction.
- `refresh` - Set the values of your component based on the values in `settings`. (`settings.tag` is the unit id)
- `bind` - Install any event handlers that are required. Do not set an `OnEvent` script.
- `unbind` - Remove all event handlers. Note that Slab calls `UnregisterAllEvents` on your frame whether you like it or not.
- `update` - Called by Slab's `OnEvent` script with the `eventName` and parameters.

Additionally, you can specify dependencies on your component's table to build your component after certain other components have been built.

Once defined, use `Slab.RegisterComponent` to register your component. Registered components are always applied to every nameplate.

Once a component has been bound, it will have `frame` and `settings` properties that can be used to access the component's frame and Slab settings, respectively.

The [`absorb`](./Slab/src/components/absorb.lua) component is a good example of a minimal but useful component that uses all of these.

## Component Template

```lua
---@type LibSlab
local Slab = LibStub("Slab")

---@class AbsorbBarComponent:Component
---@field public frame AbsorbBar
local component = {
    dependencies = {'healthBar'}
}

function component:build()
    -- create frames
end

function component:bind(settings)
    -- register for events
end

function component:unbind()
    -- unregister for all events
end

function component:refresh(settings)
    -- apply state from settings
end

function component:update(eventName, ...)
    -- handle an event
end

Slab.RegisterComponent('example', component)
```

The use of EmmyLua annotations is highly recommended, as it will make autocompletions *much* better.