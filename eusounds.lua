module("eusounds", package.seeall)
require "debug-functions" -- eu

local sounds = nil

--[[
--  highly experimental method of playing arbitrary sound files
--  requires registering the sound via eud.registerSound function during data extensions (require eu-data)
--  Returns a soundMaker 'object' with sm.player (being the gun turret), sm.target (being the enemy it shoots at)
--  and methods sm:hasFinished, sm:stop, sm:pause, and sm:play functions
--  play will work after calling stop, but is more costly than after pause since it recreates the entities!
--  note: getPlaceablePosition is probably unnecessary since the soundMaker should have no collision...leaving it for safety right now :)
--]]
function createSound(modName, soundName, position)
  if not modName or type(modName) ~= "string" then error("invalid mod name!", 2) end
  if not soundName or type(soundName) ~= "string" then error("invalid sound name!", 2) end
  if not position or not eu.checkPos(position) then error("invalid position!", 2) end
  if not sounds then getSounds() end
  if not sounds[modName] then error("Mod name not found!", 2) end
  if not sounds[modName][soundName] then error("Sound " .. modName .. "-" .. soundName .. " not found!", 2) end
  local pos = eu.getPlaceablePosition("soundMaker-", position)
  if not pos then return false end
  if times then
    if type(times) == "string" then
      if times ~= "max" then
        error("Invalid times value: "..times, 2)
      else
        times = game.itemprototypes["soundTrigger"].stacksize
      end
    elseif type(times) ~= "number" then
      error("Invalid times "..tostring(times), 2)
    end
  end
  local player = game.createentity{name=sounds[modName][soundName], position=pos, force=game.player.force}
  local target = game.createentity{name="soundTarget", position=pos, force=game.forces.enemy}
  target.active = false
  --  eu.getPlaceablePosition seems to be nil after save/load...
  local ret = {player=player, target=target, position=pos,
              play=function(self, times)
                require "debug-functions" -- eu
                if not self:recreate() then return false end
                self.player.insert{name="soundTrigger", count=times or 1}
                return true
              end,
              pause=function(self)
                require "debug-functions" -- eu
                if not self:recreate() then return false end
                self.player.getinventory(1).clear()
                return true
              end,
              stop=function(self)
                require "debug-functions" -- eu
                if self.player.valid then self.player.destroy() end
                if self.target.valid then self.target.destroy() end
                return true
              end,
              hasFinished = function(self)
                require "debug-functions" -- eu
                if not self:recreate() then return false end
                return self.player.getitemcount("soundTrigger") == 0
              end,
              move=function(self, position)
                require "debug-functions" -- eu
                local pos = eu.getPlaceablePosition("soundMaker-", position)
                if not pos or not self:recreate() then return false end
                self.player.teleport(pos)
                self.target.teleport(pos)
                self.position = pos
                return true
              end,
              recreate=function(self) -- using upvalue sounds makes this a closure...
                require "debug-functions" -- eu
                if not self.position then return false end
                self.position = eu.getPlaceablePosition("soundMaker-", self.position)
                if not self.player.valid then
                  self.player = game.createentity{name=sounds[modName][soundName], position=self.position, force=game.player.force}
                end
                if not self.target.valid then
                  self.target = game.createentity{name="soundTarget", position=self.position, force=game.forces.enemy}
                  self.target.active = false
                end
                return true
              end
              }
  return ret
end

--[[
--  gathers sound entities from prototypes into sounds table for future use.
--]]
function getSounds()
  sounds = sounds or {} -- sounds is an upvalue here apparently...
  for name, prototype in pairs(game.entityprototypes) do
    if name:find("soundMaker%-.+") then -- .+ required due to generic soundMaker template used with getPlaceablePosition
      local modAndSound = name:sub(#"soundMaker%-")
      local modName = modAndSound:match("(.+)%-.+")
      local soundName = modAndSound:sub(#modName+2)
      sounds[modName] = sounds[modName] or {}
      sounds[modName][soundName] = name
    end
  end
  --error(serpent.block(sounds)) -- debugging line :)
end
