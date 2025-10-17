local pprint = require("pprint")
local logger = {}

function logger:send_rntt(s, m, next)
  term.setTextColor(colors.blue)
  print(("[RNTT] Sending to %d:"):format(s))
  term.setTextColor(colors.white)
  pprint(m)
  local result = next(s, m)

  term.setTextColor(colors.blue)
  print(("[RNTT] message sent!"):format(s))
  term.setTextColor(colors.white)
  return result
end

function logger:send_dbcp(s, m, next)
  term.setTextColor(colors.blue)
  print(("[DBCP] Sending to %d:"):format(s))
  term.setTextColor(colors.white)
  pprint(m)

  local result = next(s, m)

  term.setTextColor(colors.blue)
  print(("[DBCP] message sent!"):format(s))
  term.setTextColor(colors.white)
  return result
end

function logger:recv_dbcp(s, m, next)
  term.setTextColor(colors.lime)
  print(("[DBCP] Received from %d:"):format(s))
  term.setTextColor(colors.white)
  pprint(m)
  return next(s, m)
end

function logger:recv_rntt(s, m, next)
  term.setTextColor(colors.lime)
  print(("[RNTT] Received from %d:"):format(s))
  term.setTextColor(colors.white)
  pprint(m)
  return next(s, m)
end

return logger
