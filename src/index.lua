---@class SlabPrivate
local private = select(2, ...)


---@class SlabFrameMixin
---@field bind fun(self, unitToken: UnitToken)

private.frames = {}

---@class SlabRoot:Frame
---@field frames table<string, Frame|SlabFrameMixin>
---@field bind fun(self, unitToken:UnitToken)
---@field unbind fun(self)

---@class SlabRootMixin
---@field slab SlabRoot

---@param self SlabRoot
---@param unitToken UnitToken
local function bind(self, unitToken)
    for key, frame in pairs(self.frames) do
        frame:bind(unitToken)
    end
end

---@param self SlabRoot
local function unbind(self)
    for key, frame in pairs(self.frames) do
        frame:UnregisterAllEvents()
    end
end

---@param nameplate Nameplate
---@return Nameplate|SlabRootMixin
function private.createNameplate(nameplate)
    ---@type Nameplate|SlabRootMixin
    local nameplate_ = nameplate
    nameplate_.slab = CreateFrame('Frame', nameplate:GetName() .. 'Slab', nameplate)
    nameplate_.slab:SetAllPoints()
    nameplate_.slab:SetIgnoreParentScale(true)
    nameplate_.slab:SetScale(0.5)
    
    nameplate_.slab.frames = {}

    nameplate_.slab.frames.hp = private.frames.health(nameplate_)
    nameplate_.slab.frames.castbar = private.frames.castbar(nameplate_, nameplate_.slab.frames.hp)

    nameplate_.slab.bind = bind
    nameplate_.slab.unbind = unbind

    return nameplate_
end

private.font = [[Interface\addons\Slab\resources\fonts\FiraSans-Regular.otf]]