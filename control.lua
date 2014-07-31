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
      
      local exclude = {}
      for i, entity in ipairs(found) do
        if entity.type == "smoke" or entity.type == "decorative" or entity.type == "construction-robot" or entity.type == "logistic-robot" or entity.type == "ghost" then
          table.insert(exclude, i)
        end
      end
      eu.removeFromTable(found, exclude)
      if found[1] then
        raiseOnBuiltEntity(found[1])
      end
      table.insert(removeGhosts, i)
    end
  end
  eu.removeFromTable(glob.ghosts, removeGhosts) -- still need 'valid' ghosts so can't reset entire table
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
