-- part of unit tests
require "eu-sounds-data" -- eusoundsdata
local eusd = eusoundsdata -- shorter name
eusd.registerSound("EU-unit-tests", "soundTest", "__ExtraUtilities__/sound/Hiei.ogg", 3+1, 1) -- 3 second sound, +1 for delay
eusd.registerSound("EU-unit-tests", "soundTestTwo", "__ExtraUtilities__/sound/MozartEineKleineNachtmusik.I.Allegro.ogg", 4*60+1, 1) -- 4 minute song
