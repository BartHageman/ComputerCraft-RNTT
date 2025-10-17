local slowpoke = {}


function slowpoke:recv_dbcp(s, m, next)
  -- print("play noteblock?")
  os.sleep(1)
  return next(s, m)
end

function slowpoke:recv_rntt(s, m, next)
  -- print("play noteblock 2?")
  os.sleep(1)
  return next(s, m)
end

return slowpoke
