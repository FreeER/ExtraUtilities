require "defines"
require "debug-functions" -- eu
require "unit-tests"

local BRADIUS = 20

game.oninit(function()
  glob.search = {}
  glob.ghosts = {}
  runUnittests()
end)

game.onevent(defines.events.onputitem, function(event)
  local item = game.player.cursorstack
  if not item then return end-- if there's no item in player's hand we have no idea what happened...
  if item.name == "blueprint" then
    item = {name="blueprint", type="blueprint", position=event.position}
  else
    item = game.itemprototypes[item.name].placeresult
  end
  if item then
    table.insert(glob.search, {name=item.name, type=item.type, position=event.position})
    --game.player.print("inserted " .. tostring(item.name) .. " at " .. tostring(event.position))
  end
end)

game.onevent(defines.events.ontick, function(event)
  for i, entity in ipairs(glob.search) do
    local ghosts = search(entity.name, entity.position)
    if ghosts[1] then
      for i, ghost in ipairs(ghosts) do
        table.insert(glob.ghosts, {name=entity.name, position=ghost.position, entity=ghost})
      end
    end
  end
  glob.search = {} -- no longer need access
  
  local removeGhosts = {}
  for i, ghost in ipairs(glob.ghosts) do
    if not ghost.entity.valid then
      local found = nil
      if ghost.name == "blueprint" then
        found = game.findentities(eu.getBoundingBox(ghost.position, 1)) -- since built entities won't actually be named 'blueprint'...
      else
        found = game.findentitiesfiltered{name=ghost.name, area=eu.getBoundingBox(ghost.position, 1)}
      end
      
      local nonbuilt = {}
      for i, entity in ipairs(found) do
        if entity.type == "smoke" or entity.type == "decorative" or entity.type == "construction-robot" or entity.type == "logistic-robot" then
          table.insert(nonbuilt, i)
        end
      end
      removefromTable(found, nonbuilt)
      if found[1] then
        raiseOnBuiltEntity(found[1])
      end
      table.insert(removeGhosts, i)
    end
  end
  removefromTable(glob.ghosts, removeGhosts) -- still need 'valid' ghosts so can't reset entire table
end)

function search(name, position)
  local radius = (name == "blueprint" and BRADIUS) or 1 -- large radius for blueprints
  return game.findentitiesfiltered{name="ghost", area=eu.getBoundingBox(position, radius)}
end

function raiseOnBuiltEntity(entity)
  game.raiseevent(defines.events.onbuiltentity, {
    name=defines.events.onbuiltentity,
    tick=game.tick,
    createdentity=eu.fakeEntity(entity), -- can't pass 'rich' data, same as interfaces
    mod="ExtraUtilities"
  })
end

function removefromTable(fromTable, removeTable, mixed)
  if not removeTable or not (type(removeTable) == "table" or type(removeTable) == "number" or type(removeTable) == "string") then
    error("improper entries to remove!", 2)
  end
  if type(fromTable) ~= "table" then error("No table given!") end
  if type(removeTable) ~= "table" then
    if type(removeTable) == "string" then
      fromTable[removeTable] = nil
    elseif type(removeTable) == "number" then
      table.remove(fromTable, removeTable)
    end
  end
  if mixed then
    for i, index in ipairs(removeTable) do
      -- subtract i because the positions will be adjusted 'down' when an entry is removed (+1 since i starts at 1)
      if type(index) == "number" then -- array index
        table.remove(fromTable, index-i+1)
      else -- hash index
        fromTable[index]=nil
      end
    end
  else
    if type(removeTable[1]) == "number" then -- array type table
      for i, index in ipairs(removeTable) do
        table.remove(fromTable, index-i+1)
      end
    else -- hash table
      for _, index in ipairs(removeTable) do
        fromTable[index]=nil
      end
    end
  end
  return fromTable
end
