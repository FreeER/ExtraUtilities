module("eutimer", package.seeall)

timer = { -- entirely untested with Factorio
  hasFinished = nil,
  work = nil, -- for creators function
  runsLeft = nil, -- non-number value makes an endless timer (and not false/nil which become 1)
  delay = nil,
  callback = nil, -- called after last run for number runsLeft, or after EVERY run for non-number runsLeft.
  run = function(self, ...) -- apparently var args are accessed with select?
    if self.hasFinished then return nil end -- not sure if there should be an error here or not...
    -- skip this run if not event.tick % delay == 0, with checks to prevent errors.
    if self.delay and select(1, ...) and type(select(1, ...)) == "table" and select(1, ...).tick and type(select(1, ...).tick) == "number" and not (select(1, ...).tick % self.delay == 0) then return nil end
    local status, result = nil, nil
    status, result = pcall(self.work, ...)
    if not status then
      error("work function failed with: " .. tostring(result), 2)
    end
    if type(runsLeft) == "number" then
      self.runsLeft = self.runsLeft - 1
      -- callback is called prior to the last result being returned...
      if self.runsLeft <= 0 then self.hasFinished = true if self.callback then pcall(self.callback) end end
    else
      if self.callback then pcall(self.callback) end
    end
    return result
  end,
  new = function(work, runsLeft, delay, callback) -- create and return a new timer object
    if not work or type(work) ~= "function" then error("A function was not provided for work!", 2) end
    if runsLeft and type(runsLeft) == "number" and runsLeft < 1 then error("invalid run times!", 2) end
    if delay and type(delay) ~= "number" then error("invalid tick argument!", 2) end
    if callback and type(callback) ~= "function" then error("callback is used for functions!", 2) end
    local ret = {__index=timer, hasFinished=false, work=work, runsLeftLeft=runsLeft or 1, delay=delay, callback=callback}
    setmetatable(ret, ret) -- avoids creating a new table for the metatable by setting __index in the timer object itself
    return ret
  end
}


-- Lua testing
status, result = pcall()
assert(not status) -- should be false since timers need at least a work function
status, result = pcall(timer.new, function() end, 0)
assert(not status) -- should be false since timers can not have a run count of less than 1


work = function(msga, msgb) print("running1") if msga and msgb then return msga..msgb else return "I ran!" end end
callback = function() print("In callback: I'm done!") end
test = timer.new(work, 5, nil, callback) -- no delay
for i=1, 4 do
  print("result: " .. tostring(test:run("msg ", i))) -- only possible do to variable arguments, otherwise would require a table for args
end
print("result: " .. tostring(test:run())) -- call work with no args, thus receive "I ran!"
print("result: " .. tostring(test:run())) -- immediately returns since test hasFinished, tostring required since result of test:run() is nil

print("\ntimer2 test- delays and event(s)")
work2 = function(event, msga, msgb) print("running2, event.stuff is: "..tostring(event.stuff)) if msga and msgb then return msga..msgb else return "II ran!" end end
test2 = timer.new(work2, 2, 60, callback) -- delay with event
print("tick 30")
print("result: " .. tostring(test2:run({tick = 30}, "a", "b")))
print("tick 60")
print("result: " .. tostring(test2:run({tick = 60, stuff=30}, "b", "c")))
print("tick 120")
print("result: " .. tostring(test2:run({tick = 120}, "c", "d")))
-- test2 has now finished
print("tick 160")
print("result: " .. tostring(test2:run({tick = 160}, "c", "d")))
print("tick 180")
print("result: " .. tostring(test2:run({tick = 180}, "c", "d")))

print("\ntimer3 test- delays and no event(s)")
work3 = function(event, msga, msgb) print("running3, event.stuff is: "..tostring(event.stuff)) if msga and msgb then return msga..msgb else return "III ran!" end end
test3 = timer.new(work3, 2, 60, callback)
print("result: " .. tostring(test3:run("a", "b")))
print("result: " .. tostring(test3:run("a", "b")))
print("test3 has finished: "..tostring(test3.hasFinished))
print("result: " .. tostring(test3:run("a", "b")))

