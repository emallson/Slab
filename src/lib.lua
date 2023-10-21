---@class LibSlab
local ns = select(2, ...)

local Slab = LibStub:NewLibrary("Slab", 0)
setmetatable(Slab, {
  __index = ns
})
