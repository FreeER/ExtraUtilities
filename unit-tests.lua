-- unit tests for Extra Utilities 'mod', requires data and eu-sounds-data for experimental sound testing
require "defines"
require "debug-functions" -- eu
require "eusounds" -- eusounds

local run = false

function runUnittests()
  run = true
  --  checkPos
  do -- do blocks for collapsing only
    msga = "checkPos failed with "
    test = game.createentity{name="wooden-chest", position=eu.getPlaceablePosition("wooden-chest", game.player.position)} 
    a = eu.checkPos(test.position)
    assert(a, msga.."Lua/entity position!") -- should pass, note a is the valid position!
    a = eu.checkPos(test)
    assert(a, msga.."Lua/entity!") -- should pass since it was designed to!
    a = eu.checkPos({x=test.position.x, y=test.position.y})
    assert(a, msga.."created position!") -- should pass since it's a valid position
    a = eu.checkPos({X=2, Y=3})
    assert(a, msga.."nonstandard created position") -- X and Y are valid indexes to Factorio so this should work!

    -- false checks
    test.destroy()
    a = eu.checkPos(test) -- should not cause an error! :)
    assert(not a) -- should be false since lua/entity position is no longer accessible
    a = eu.checkPos(2)
    assert(not a)
    a = eu.checkPos("a")
    assert(not a)
    a = eu.checkPos(a)
    assert(not a)
    a = eu.checkPos({})
    assert(not a)

    -- cleanup
    test = nil
    a = nil
  end


  do
  --  getBoundingBox
    -- none done yet

    
  --  getPlaceablePosition
    -- none done yet
    
    
  --  writeDebug
    -- none done yet
    
    
  --  removefromTable
    -- none done yet
    
    
  --  findfirstentityfiltered
    -- none done yet
  end
    

  --  checkItemstack
  if game.entityprototypes["wooden-chest"] and game.itemprototypes["iron-ore"] then 
    test = game.createentity{name="wooden-chest", position=eu.getPlaceablePosition("wooden-chest", game.player.position)} 
    test.insert{name="iron-ore", count=100} -- goes in first slot since it's empty
    a = eu.checkItemstack(test.getinventory(defines.inventory.chest)[1])
    assert(a)
    a = eu.checkItemstack({name="iron-ore", count=1})
    assert(a)
    
    -- false checks
    a = eu.checkItemstack({name="iasdfasdgfdfnsfsfe", count=1})
    assert(not a) -- a is nil since name is not an item... 'true and nil' evaluates to nil and not false for some reason
    a = eu.checkItemstack({name=nil, count=1}) 
    assert(not a) -- again nil
    a = eu.checkItemstack({count=1})
    assert(not a) -- again nil
    a = eu.checkItemstack({})
    assert(not a) -- again nil
    a = eu.checkItemstack(3)
    assert(not a)
    a = eu.checkItemstack("")
    assert(not a)
    a = eu.checkItemstack(a)
    assert(not a)
    
    -- cleanup
    test.destroy()
    test = nil
    a = nil
    
  else
    assert(false, "Cannot perform checkItemstack test because wooden-chest entity does not exist or iron-ore item does not exist!") 
  end


  --  maxInsertable
  if game.entityprototypes["wooden-chest"] and game.itemprototypes["iron-ore"] then 
    msga = "maxInsertable failed test " 
    msgb = "!, did the size of the wooden chests inventory change?" 
    total = game.itemprototypes["iron-ore"].stacksize * 16 
    test = game.createentity{name="wooden-chest", position=eu.getPlaceablePosition("wooden-chest", game.player.position)} 
    a = eu.maxInsertable({name="iron-ore", count=total}, test) 
    assert(a==total, msga.."1"..msgb) -- should be equal to total since the chest was empty!
    assert(test.getitemcount() == 0, "maxInsertable left items in chest!") -- should be 0 since maxInsertable should not leave items in chest!
    
    test.insert{name="iron-ore", count=total}
    a = eu.maxInsertable({name="iron-ore", count=1}, test, defines.inventory.chest) 
    assert(a==0, msga.."2"..msgb) -- should be 0 since it's full!
    test.getinventory(1).clear()
    
    a = eu.maxInsertable({name="iron-ore", count=total}, test, defines.inventory.chest, true) -- true for resultIsAll
    assert(a==true, msga.."3"..msgb) -- should be able to insert the entire stack since the inventory is empty
    test.getinventory(1).insert{name="iron-ore", count=(total/2)}
    a = eu.maxInsertable({name="iron-ore", count=total}, test, nil, true) -- nil can be passed for default inventory value
    assert(a==false, msga.."4"..msgb) -- should be false since it can not insert the entire stack
    
    
    -- invalid input tests
    local status, msg = pcall(eu.maxInsertable)
    assert(not status)
    status, msg = pcall(eu.maxInsertable, 1)
    assert(not status)
    status, msg = pcall(eu.maxInsertable, "")
    assert(not status)
    status, msg = pcall(eu.maxInsertable, 1)
    assert(not status)
    status, msg = pcall(eu.maxInsertable, {name="iron-ore", count=total}, a)
    assert(not status)
    status, msg = pcall(eu.maxInsertable, {name="iron-ore", count=total}, "a")
    assert(not status)
    status, msg = pcall(eu.maxInsertable, {name="iron-ore", count=total}, 1)
    assert(not status)
    status, msg = pcall(eu.maxInsertable, {name="iron-ore", count=total}, test, -1)
    assert(not status)
    status, msg = pcall(eu.maxInsertable, {name="iron-ore", count=total}, test, 11)
    assert(not status)
    status, msg = pcall(eu.maxInsertable, {name="iron-ore", count=total}, {name="fake_entity", valid=true, position=nil})
    assert(not status)
    
    -- cleanup
    msga = nil
    msgb = nil
    total = nil
    test.destroy()
    a = nil
    status = nil
    msg = nil
  else 
    assert(false, "Cannot perform maxInsertable test because wooden-chest entity does not exist or iron-ore item does not exist!") 
  end 


  --  escapeString
  do
  string.escaped = eu.escapeString
  test = "t^es$t(.+*)-?+]a%ds[r   *?\\//"
  a, b = test:find(test:escaped()) -- if this does not match the entire string then it failed to escape properly
  assert(a==1 and b==#test, "escapeString failed!")

  -- cleanup
  string.escaped = nil
  test = nil
  a = nil
  b = nil
  end

  
  --  setupSound (registered via eu-data)
  do
  glob.soundTest = eusounds.createSound("EU-unit-tests", "soundTest", game.player.position)
  glob.soundTestTwo = eusounds.createSound("EU-unit-tests", "soundTestTwo", game.player.position)
  
  --  fake player building a stone-furnace
  do
    -- create entity
    local entity = game.createentity{name="stone-furnace", position=eu.getPlaceablePosition("stone-furnace", game.player.position)}
    --  raised events can not pass 'rich' objects, just like interfaces can not (causes crash), so fake it with a regular table.
    entity = eu.fakeEntity(entity)
    game.raiseevent(defines.events.onbuiltentity, {
      name=defines.events.onbuiltentity,
      tick=game.tick,
      createdentity=entity,
      mod="EU-unit-tests"
    })
  end
  
  
  --  fake player picking up 8 iron-plates
  do
  game.raiseevent(defines.events.onpickedupitem, {
    name=defines.events.onpickedupitem,
    tick=game.tick,
    itemstack={name="iron-plate", count=8},
    mod="EU-unit-tests"
  })
  end
  
  --[[ 
  --  obviously would have been simpler to use a custom event since
  --  you have to worry about other mods using current ones and thus 
  --  need to replicate the expected event properly to at least try
  --  and prevent errors due to expected properties not existing
  --]]
  end
end

game.onevent(defines.events.onpickedupitem, function(event)
  if run then 
    if not glob.soundTest:move(game.player.position) then error("failed to move soundTest!") end
    glob.soundTest:play()
    glob.soundTest:stop() -- happens too soon for soundTest to actually play...
    glob.soundTest:play()
  end
end)

game.onevent(defines.events.onbuiltentity, function(event)
  if run then
    if not glob.soundTestTwo:move(game.player.position) then error("failed to move soundTestTwo!") end
    glob.soundTestTwo:play(2)
    if event.mod then 
      -- if this existed then we know it can't be a standard lua entity! Instead
      -- to get the actual entity we'd need to use findentities(filtered)
      -- with the fake entity's postion and a small bounding box.
      -- However, since soundTestTwo was created by our code and not a player we
      -- already have a reference
    end
  end
end)
