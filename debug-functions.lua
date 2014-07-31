module("eu", package.seeall)
require("defines")

--[[
--  Checks if position is a valid position or lua entity with a position
--  If position is valid then the position is returned, else false is returned
--]]
function checkPos(position) 
  if not position or type(position) ~= "table" then return false end 
  -- check for lua entity first to avoid error on accessing invalid entity.x 
  if type(position.valid) == "boolean" then 
    if position.valid then 
      return checkPos(position.position) 
    end
  elseif position.x and type(position.x)=="number" and position.y and type(position.y)=="number" then 
    return position 
  elseif position.X and type(position.X)=="number" and position.Y and type(position.Y)=="number" then 
    return {x=position.X, y=position.Y} -- X and Y is valid to Factorio, return new table with 'standard' format
  end 
  return false 
end 

--[[
--  position is the central position or central lua entity
--  radius is the length of the bounding box side divided by 2
--  radius defaults to 1 if not provided
--]]
function getBoundingBox(position, radius) 
  realposition = checkPos(position)
  if not realposition then error("Invalid position!", 2) end
  if not radius then local radius = 1 end
  return {{realposition.x-radius, realposition.y-radius}, {realposition.x+radius, realposition.y+radius}} 
end 

--[[ bb def that can be pasted into factorio console --]]
function getbb(position, radius) 
  return {{position.x-radius, position.y-radius}, {position.x+radius, position.y+radius}} 
end 

--[[
--  uses findnoncollidingposition in a loop to attempt to find a valid building position
--  name is entity name to place, position is central position, radius is the length of 
--  a bounding box side divided by 2, precision is whatever precision means for 
--  findnoncollidingposition, and max_tries is max number of iterations
--  Default Values: radius=10, precision=1, max_tries=7
--]]
function getPlaceablePosition(name, position, radius, precision, max_tries) 
  if not name or not game.entityprototypes[name] then error("entity name not found in game prototypes!", 2) end 
  start_position = checkPos(position) 
  if not start_position then error("Unusable position provided!", 2) end 
  radius = radius or 10 
  precision = precision or 1 
  max_tries = max_tries or 7 
  
  repeat 
    res_position = game.findnoncollidingposition(name, start_position, radius, precision) 
    max_tries = max_tries - 1 
  until res_position or max_tries == 0 
  
  return res_position 
end 

--[[
--  message is the message to be printed, conditions allows providing a boolean or a table
--  of booleans to check prior to printing, assumes glob.release as release state variable.
--]]
function writeDebug(message, conditions) 
  local conditionsMet = true 
  if conditions then 
    if type(conditions) == "boolean" then 
      conditionsMet = conditions 
    elseif type(conditions) == "table" then 
      for _, condition in pairs(conditions) do 
        if type(condition) == "boolean" and not condition then conditionsMet = false end 
      end 
    end 
  end 
  if not glob.release and conditionsMet then game.player.print(serpent.block(message)) end 
end 

--[[
--  fromTable is the table you will remove entries from, removeTable is an array-type table
--  containing the indexes to remove, and mixed signifies whether fromTable has both array and hash indexes.
--  mixed is purely for optimization, if it's not mixed removefromTable determines which type
--  it is based on if fromTable[1] exists instead of performing a type check on each index in removeTable
--]]
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
    if fromTable[1] then -- array type table
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

--[[
--  returns the first entity from findentityfiltered
--  filterType is the type of filter "name" or "type"
--  name is the value for filterType
--  bounding box is the area to search
--]]
function findfirstentityfiltered(filterType, name, boundingbox)
  if not boundingbox then
    error("no bounding box provided!", 2)
  elseif type(boundingbox) ~= "table" then
    error("provided boundingbox is not a table!")
  elseif not boundingbox[1] or not boundingbox[2] or not checkPos(boundingbox[1]) or not checkPos(boundingbox[2]) then
    error("Provided boundingbox is not a valid boundingbox!", 2)
  elseif not filterType then
    error("type parameter not provided!", 2)
  elseif type(filterType) ~= "string" or filterType ~= "type" or filterType ~= "name" then
    error("The filterType parameter must be \"type\" or \"name\"!", 2)
  elseif not name or not type(name) == "string" then
    error("You didn't give a string for the"..filterType, 2)
  elseif not game.entityprototypes[name] then
    error(name.."is not a valid entity name!", 2)
  end
  
  local params = {}
  params[filterType] = name
  params["area"] = boundingbox
  
  return game.findentitiesfiltered(params)[1]
end

--[[
--  Checks if an itemstack is valid position
--  if game.itemprototypes[itemstack.name] is nil returns nil...
--]]
function checkItemstack(itemstack) 
  return itemstack and type(itemstack) == "table" and itemstack.name and 
    game.itemprototypes[itemstack.name] and 
    type(itemstack.name) == "string" and itemstack.count and 
    type(itemstack.count) == "number" and itemstack.count > 0 
    -- perhaps also check if itemstack.count has a fractional component using math.modf?
    -- does not cause an 'error' but fails to insert if it does.
end 

--[[
--  returns amount of items insertable into entity based on passed itemstack unless
--  resultIsAll is true, in which case it returns if the entire itemstack can be inserted
--  the inventory is required for non-chest entities because entity.removeitem does not seem to work well...
--  and remove is only defined for inventories, if not specified will default to defines.inventory.chest
--]]
function maxInsertable(itemstack, entity, inventory, resultIsAll) 
  if not itemstack or not checkItemstack(itemstack) then 
    error("Invalid itemstack!", 2) 
  elseif not entity or not entity.valid or not entity.position then 
    error("Invalid lua entity!", 2) 
  elseif inventory and (inventory > 10 or inventory < 1) then
    error("There is no way that's a valid inventory!")
  end 
  inventory = inventory or defines.inventory.chest 
  
  if not entity.caninsert(itemstack) then 
    if resultIsAll then return false else return 0 end 
  end 
  
  local activestate = entity.active 
  entity.active = false -- prevent entities that use items from using these
  
  local insertable = entity.getinventory(inventory).getitemcount(itemstack.name) 
  entity.getinventory(inventory).insert(itemstack) 
  insertable = entity.getinventory(inventory).getitemcount(itemstack.name) - insertable 
  entity.getinventory(inventory).remove{name=itemstack.name, count=insertable} 
  
  entity.active = activestate -- restore active state
  
  if resultIsAll then 
    return (insertable == itemstack.count ) 
  else 
    return insertable 
  end 
end 

--[[
--  escapes special characters for use in lua pattern matching
--  feel free to use string.escaped = eu.escapeString
--  which allows local str = "some string"; str = str:escaped()
--  taken from: https://stackoverflow.com/questions/6705872/how-to-escape-a-variable-in-lua
--]]
function escapeString(s)
  return (s:gsub(".", {
    ["^"] = "%^",
    ["$"] = "%$",
    ["("] = "%(",
    [")"] = "%)",
    ["%"] = "%%",
    ["."] = "%.",
    ["["] = "%[",
    ["]"] = "%]",
    ["*"] = "%*",
    ["+"] = "%+",
    ["-"] = "%-",
    ["?"] = "%?",
  }))
end

--[[
--  Takes Lua/Entity and returns a lua table with typically indexed entity values
--  can be converted back to Lua/Entity using game.findentitiesfiltered{name=fakeentity.name area=getBoundingBox(fakeentity.position, 1)}[1]
--]]
function fakeEntity(entity)
  if not entity or not entity.valid or not (entity.position and checkPos(entity.position)) then 
    error("Invalid lua entity!", 2)
  end
  return {valid=entity.valid, name=entity.name, type=entity.type, position=entity.position}
end
