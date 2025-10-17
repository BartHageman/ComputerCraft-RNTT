local Broker = {
  clients = {},
  subscriptions = {},
  capabilities = {},
  middleware = {},
  name = ""
}
Broker.__index = Broker -- When looking up missing keys, check Broker table

-- Constructor
function Broker.new(config)
  print("New broker!")
  local instance = {
    grid_id = config.grid_id,
    middleware = {},
    clients = {},
    subscriptions = {},
    capabilities = config.capabilities or {},
    name = config.name or ""
  }

  rednet.open(config.rednet_side or "back")
  setmetatable(instance, Broker) -- Make instance inherit from Broker

  -- Add core broker functionality as the first middleware
  instance:use(require("broker_core"))

  -- Add user middleware through use() to ensure metatables are set
  local mw_list = config.middleware or {}
  for _, mw in ipairs(mw_list) do
    instance:use(mw)
  end

  return instance
end

--------------------------------------------------------------------------------
-- MIDDLEWARE
--------------------------------------------------------------------------------

-- Identity middleware for missing hooks
local middleware_meta = {
  __index = function(t, k)
    return function(self, sender, message, next)
      return next(sender, message) -- Just pass through
    end
  end
}

function Broker:use(middleware_obj)
  if getmetatable(middleware_obj) == nil then
    setmetatable(middleware_obj, middleware_meta) -- Unless we already have a default handler, we should add a transparent handler.
  end
  middleware_obj.broker = self                    -- Give middleware access to broker
  table.insert(self.middleware, 1, middleware_obj)
  return self
end

-- Abstract chain building
--
-- middleware_3(s, m, middleware_2)
--    --pre 3 stuff
--    local result_m2 = middleware_2(s, m, middleware_1)
--                  --pre 2 stuff
--                  local result_m1 = middleware_1(s, m, core_middleware)
--                      -- pre 1 stuff
--                      result_core = core(s, m, nil)
--                      -- post 1 stuff
--                      return result_core
--                  --post 2 stuff
--                  return result_m1
--    --post 3 stuff
--    return result_m2

function Broker:build_middleware_chain(hook_name)
  local chain = nil
  -- Build the chain by wrapping each middleware in forward order
  -- First middleware added (broker_core) should execute LAST

  for i = #self.middleware, 1, -1 do -- Walk backward. Starting with core functionality (last in the list)
    local mw = self.middleware[i]
    local previous = chain
    chain = function(s, m)
      return mw[hook_name](mw, s, m, previous)
    end
  end

  return chain
end

--------------------------------------------------------------------------------
-- SENDING
--------------------------------------------------------------------------------

-- Now sending is simple
function Broker:send_rntt_message(sender, message)
  local chain = self:build_middleware_chain("send_rntt")
  return chain(sender, message)
end

function Broker:send_dbcp_message(sender, message)
  local chain = self:build_middleware_chain("send_dbcp")
  return chain(sender, message)
end

--------------------------------------------------------------------------------
-- RECEIVING
--------------------------------------------------------------------------------

function Broker:recv_rednet_message(sender, message, protocol)
  if protocol == "DBCP" then
    self:recv_dbcp_message(sender, message)
  elseif protocol == "RNTT" then
    self:recv_rntt_message(sender, message)
  end
end

function Broker:recv_dbcp_message(sender, message)
  local chain = self:build_middleware_chain("recv_dbcp")
  return chain(sender, message)
end

function Broker:recv_rntt_message(sender, message)
  local chain = self:build_middleware_chain("recv_rntt")
  return chain(sender, message)
end

--------------------------------------------------------------------------------
-- STARTUP
--------------------------------------------------------------------------------

function Broker:start()
  print("starting loop")
  while true do
    local event, p1, p2, p3 = os.pullEvent()
    if event == "rednet_message" then
      local sender, message, protocol = p1, p2, p3
      self:recv_rednet_message(sender, message, protocol)
      -- elseif event == "timer" then
      --   -- handle heartbeat timeout checking
      -- elseif event == "key" then
      --   -- handle shutdown command
    end
  end
end

return Broker
