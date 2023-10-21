---@class LibSlab
local Slab = select(2, ...)

local silenceable = {}
local casters = {}

local function buildMDTSilenceTable()
  for id, dungeon in pairs(MDT.dungeonEnemies) do
    for mobindex, mob in pairs(dungeon) do
      if not mob["isBoss"] then
        if mob['characteristics'] and mob['characteristics']['Silence'] then
          if mob['spells'] then
            for spellId, obj in pairs(mob['spells']) do
              if not silenceable[spellId] then
                silenceable[spellId] = {}
              end
              local tbl = silenceable[spellId]
              table.insert(tbl, mob['id'])
            end
          end
        end
      end
    end
  end
end

local function buildEJSilenceTable()
  -- TODO this is LOD so we DO need to watch for ADDON_LOADED
end


local function addCastersFromBigWigsModule(_msg, _moduleName, module)
  if module then
    local options = module:GetOptions()
    for ix, option in pairs(options) do
      local targets = nil
      if type(option) == 'number' and silenceable[option] then
        targets = silenceable[option]
      elseif type(option) == 'table' and silenceable[option[1]] then
        targets = silenceable[option[1]]
      end

      if targets ~= nil then
        for _, mobId in pairs(targets) do
          casters[mobId] = true
        end
      end
    end
  end
end

-- try to identify enemies that are kickable
-- MDT is an optional dep that can't be lazy loaded so we don't need ADDON_LOADED stuff here
if MDT then
  buildMDTSilenceTable()
end

-- handle already loaded boss modules
if BigWigs then
  for key, module in BigWigs:IterateBossModules() do
    addCastersFromBigWigsModule(nil, key, module)
  end
end

if BigWigsLoader then
  BigWigsLoader.RegisterMessage({}, "BigWigs_BossModuleRegistered", addCastersFromBigWigsModule)
end


Slab.utils.enemies.isCaster = function(id)
  return casters[id] or false
end

