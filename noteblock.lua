local noteblock = {}

local nb = peripheral.find("speaker")

local function startup_sound()
  nb.playNote("bit", 1, 4)
  os.sleep(0.1)
  nb.playNote("bit", 1, 8)
  os.sleep(0.1)
  nb.playNote("bit", 1, 16)
end

local function error_sound()
  nb.playNote("bit", 1, 12)
  nb.playNote("bit", 1, 11)
  os.sleep(0.2)
  nb.playNote("bit", 1, 8)
  nb.playNote("bit", 1, 7)
  os.sleep(0.2)
  nb.playNote("bit", 1, 2)
  nb.playNote("bit", 1, 1)
end

local function sound1()
  nb.playNote("bell", 1.0, 6)
  sleep(0.05)
  nb.playNote("bell", 1.0, 10)
  sleep(0.05)
  nb.playNote("bell", 1.0, 13)
end

local function sound2()
  nb.playNote("chime", 1.0, 0)
  sleep(0.05)
  nb.playNote("chime", 1.0, 4)
  sleep(0.05)
  nb.playNote("chime", 1.0, 7)
end

if nb then
  startup_sound()
end

function noteblock:recv_dbcp(s, m, next)
  if nb then
    --recv_sound()
  end
  return next(s, m)
end

function noteblock:recv_rntt(s, m, next)
  --recv_sound()
  return next(s, m)
end

function noteblock:send_rntt(s, m, next)
  if nb then
    if m.type == "ERROR" then
      error_sound()
    elseif string.find(m.type, "ACK") then
      sound2()
    else
      --send_sound()
      --nb.playNote("bit", 1, 10)
    end
  end
  return next(s, m)
end

return noteblock
