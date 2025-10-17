local broker_core = {}


function broker_core:recv_dbcp(s, m)
  if m == "DISCOVER" then
    self.broker:send_dbcp_message(s, { type = "OFFER", id = self.broker.name, capabilities = self.broker.capabilities })
  end
  return s, m -- Core terminates the chain
end

function broker_core:on_connect(s, m)
  if self.broker.clients[s] == nil then
    self.broker.clients[s] = { capabilities = {} }
    self.broker:send_rntt_message(s, { type = "CONNACK" })
  end
end

function broker_core:on_disconnect(s, m)
  self.broker.clients[s] = nil
end

function broker_core:on_capabilities(s, m)
  self.broker.clients[s] = m.capabilities
  self.broker:send_rntt_message(s, { type = "CAPABILITIESACK" })
end

function broker_core:on_publish(s, m)
  if (self.broker.subscriptions[m.topic] == nil) then
    return
  end
  for _, v in ipairs(self.broker.subscriptions[m.topic]) do
    if s ~= v then
      self.broker:send_rntt_message(v, m)
    end
  end
  self.broker:send_rntt_message(s, { type = "PUBACK" })
end

function broker_core:on_subscribe(s, m)
  if self.broker.subscriptions[m.topic] == nil then
    self.broker.subscriptions[m.topic] = {}
  end
  table.insert(self.broker.subscriptions[m.topic], s)
  self.broker:send_rntt_message(s, { type = "SUBACK" })
end

function broker_core:on_unsubscribe(s, m)
  table.remove(self.broker.subscriptions[m.topic], s)
  self.broker:send_rntt_message(s, { type = "UNSUBACK" })
end

function broker_core:on_premature_msg(s, _, _)
  self.broker:send_rntt_message(s,
    { type = "ERROR", message = "Not connected. Please connect with CONNECT packet first." })
end

function broker_core:recv_rntt(s, m, _)
  if m.type ~= "CONNECT" and self.broker.clients[s] == nil then
    self:on_premature_msg(s, m)
    return s, m -- Core terminates the chain
  end

  if m.type == "CONNECT" then
    self:on_connect(s, m)
  elseif m.type == "DISCONNECT" then
    self:on_disconnect(s, m)
  elseif m.type == "CAPABILITIES" then
    self:on_capabilities(s, m)
  elseif m.type == "PUBLISH" then
    self:on_publish(s, m)
  elseif m.type == "SUBSCRIBE" then
    self:on_subscribe(s, m)
  elseif m.type == "UNSUBSCRIBE" then
    self:on_unsubscribe(s, m)
  end

  return s, m -- Core terminates the chain
end

function broker_core:send_rntt(s, m, next)
  rednet.send(s, m, "RNTT")
  return s, m
end

function broker_core:send_dbcp(s, m, next)
  rednet.send(s, m, "DBCP")
  return s, m
end

return broker_core
