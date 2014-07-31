module("eusoundsdata", package.seeall)
require "util"

--[[
--  Highly experimental way of playing arbitrary sounds ingame
--  used in combination with control.lua playSound function
--]]
registerSound = function(modName, soundName, soundPath, length, volume)
  if not modName or not soundName or type(modName) ~= "string" or type(soundName) ~= "string" then error("Invalid modName or soundName!", 2) end
  if not soundPath or not checkFilePath(soundPath) then error("Invalid path to sound file!", 2) end
  local newSoundMaker = util.table.deepcopy(soundMaker)
  newSoundMaker.name = newSoundMaker.name .. modName .. "-" .. soundName
  if data.raw["ammo-turret"][newSoundMaker.name] then error("Duplicate names!", 2) end
  newSoundMaker.order = newSoundMaker.name
  newSoundMaker.attack_parameters.sound[1].filename = soundPath
  if length then
    newSoundMaker.attack_parameters.cooldown = length * 60
  end
  if volume then
    newSoundMaker.attack_parameters.sound[1].volume = volume
  end
  data:extend({newSoundMaker})
  return newSoundMaker.name
end

--  I think this will work ok... if I knew exactly which files Factorio could load
--  I'd have a table and check the extensions properly. But I don't want to leave
--  out a valid file path and cause accidental false negative returns
--  returns false or nil for invalid paths and 1 or true on valid paths.
checkFilePath = function(path, ext)
  if not path or type(path) ~= "string" then return false end
  if ext and type(ext) ~= "string" then return false end
  local res = path:find("__.+__[/].+%.%w+")
  if ext then res = res and (ext == path:sub(-#ext, #path)) end
  return res
end

soundTrigger = {
    type = "ammo",
    name = "soundTrigger",
    icon = "__core__/graphics/transparent.png",
    flags = {"goes-to-main-inventory"},
    ammo_type =
    {
      category = "bullet",
      --[[action =
      {
        {
          type = "direct",
          action_delivery =
          {
            {
              type = "instant",
              source_effects =
              {
                {
                  type = "create-entity",
                  entity_name = "explosion-gunshot"
                }
              },
              target_effects =
              {
                {
                  type = "create-entity",
                  entity_name = "explosion-gunshot"
                },
                {
                  type = "damage",
                  damage = { amount = 2 , type = "physical"}
                }
              }
            }
          }
        }
      }--]]
    },
    magazine_size = 1,
    subgroup = "ammo",
    order = "a[basic-clips]-a[basic-bullet-magazine]",
    stack_size = 100
  }

gun_turret_extension = {
  filename = "__core__/graphics/transparent.png",
  priority = "medium",
  frame_width = 1,
  frame_height = 1,
  direction_count = 1,
  frame_count = 1,
  axially_symmetrical = false,
  --shift = {1.34375, -0.5 + 0.6}
}

soundMaker = {
    type = "ammo-turret",
    name = "soundMaker-",
    icon = "__core__/graphics/transparent.png",
    flags = {"placeable-player", "player-creation"},
    --minable = {mining_time = 0.5, result = "soundMaker"},
    max_health = 1,
    order = "soundMaker-",
    --corpse = "small-remnants",
    --collision_box = {{-0.4, -0.9 }, {0.4, 0.9}},
    --selection_box = {{-0.5, -1 }, {0.5, 1}},
    rotation_speed = 0.015,
    preparing_speed = 0.08,
    folding_speed = 0.08,
    --dying_explosion = "huge-explosion",
    inventory_size = 1,
    automated_ammo_count = 10,
    folded_animation = (function()
                          local res = util.table.deepcopy(gun_turret_extension)
                          res.frame_count = 1
                          res.line_length = 1
                          return res
                       end)(),
    preparing_animation = gun_turret_extension,
    prepared_animation =
    {
      filename = "__core__/graphics/transparent.png",
      priority = "medium",
      frame_width = 1,
      frame_height = 1,
      direction_count = 1,
      frame_count = 1,
      line_length = 1,
      axially_symmetrical = false,
      --shift = {1.34375, -0.46875 + 0.6}
    },
    folding_animation = (function()
                          local res = util.table.deepcopy(gun_turret_extension)
                          res.run_mode = "backward"
                          return res
                       end)(),
    base_picture =
    {
      filename = "__core__/graphics/transparent.png",
      priority = "high",
      width = 1,
      height = 1,
      --shift = { 0, -0.125 + 0.6 }
    },
    attack_parameters =
    {
      ammo_category = "bullet",
      cooldown = 6,
      projectile_center = {0, 0.6},
      projectile_creation_distance = 12, -- should make it miss
      --[[shell_particle = 
      {
        name = "shell-particle",
        direction_deviation = 0.1,
        speed = 0.1,
        speed_deviation = 0.03,
        center = {0, 0.6},
        creation_distance = 0.6,
        starting_frame_speed = 0.2,
        starting_frame_speed_deviation = 0.1
      },--]]
      range = 1,
      sound =
      {
        {
          filename = "__base__/sound/gunshot.ogg",
          volume = 0
        }
      }
    }
  }
function make_unit_melee_ammo_type(damagevalue)
  return
  {
    category = "melee",
    target_type = "entity",
    action =
    {
      type = "direct",
      action_delivery =
      {
        type = "instant",
        target_effects =
        {
          type = "damage",
          damage = { amount = damagevalue , type = "physical"}
        }
      }
    }
  }
end
  
soundTarget = {
  type = "unit",
  name = "soundTarget",
  icon = "__core__/graphics/transparent.png",
  flags = {"placeable-player", "placeable-enemy", "placeable-off-grid"},
  max_health = 1,
  order = "b-b-a",
  subgroup="enemies",
  healing_per_tick = 0.01,
  --collision_box = {{-0.2, -0.2}, {0.2, 0.2}},
  --selection_box = {{-0.4, -0.7}, {0.7, 0.4}},
  attack_parameters =
  {
    range = 0,
    cooldown = 2000000,
    ammo_category = "melee",
    ammo_type = make_unit_melee_ammo_type(0),
    sound =
    {
      {
        filename = "__base__/sound/creatures/biter-roar-short-1.ogg",
        volume = 0
      },
      {
        filename = "__base__/sound/creatures/biter-roar-short-2.ogg",
        volume = 0
      },
      {
        filename = "__base__/sound/creatures/biter-roar-short-3.ogg",
        volume = 0
      }
    },
    animation =
    {
      filename = "__core__/graphics/transparent.png",
      frame_width = 1,
      frame_height = 1,
      frame_count = 1,
      direction_count = 1,
      -- axially_symmetrical = false,
      -- shift = {0.84375, -0.3125}
    }
  },
  vision_distance = 0,
  movement_speed = 0.0,
  distance_per_frame = 0.0,
  pollution_to_join_attack = 2000000,
  distraction_cooldown = 2000000,
  --corpse = "small-biter-corpse",
  --[[dying_sound =
  {
    {
      filename = "__base__/sound/creatures/creeper-death-1.ogg",
      volume = 0.7
    },
    {
      filename = "__base__/sound/creatures/creeper-death-2.ogg",
      volume = 0.7
    },
    {
      filename = "__base__/sound/creatures/creeper-death-3.ogg",
      volume = 0.7
    },
    {
      filename = "__base__/sound/creatures/creeper-death-4.ogg",
      volume = 0.7
    }
  },--]]
  run_animation =
  {
    filename = "__core__/graphics/transparent.png",
    still_frame = 1,
    frame_width = 1,
    frame_height = 1,
    frame_count = 1,
    direction_count = 1,
    --shift = {0.359375, -0.15625},
    --axially_symmetrical = false
  }
}
  
data:extend({soundTrigger, soundMaker, soundTarget})
