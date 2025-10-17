local Client = {
  broker_id = nil,
  connected = false,
  subscriptions = {}
}
Client.__index = Client

function Client.new(config)
  local instance = {
    broker_id = nil,
    connected = false,
    subscriptions = {},
    rednet_side = config.rednet_side or "back"
  }

  rednet.open(instance.rednet_side)
  setmetatable(instance, Client)

  return instance
end

function Client:discover_broker()
  print("Discovering brokers...")
  rednet.broadcast("DISCOVER", "DBCP")

  local sender, message, protocol = rednet.receive("DBCP", 5)

  if sender and message and message.type == "OFFER" then
    print("Found broker: " .. (message.id or "unnamed") .. " at ID " .. sender)
    return sender, message
  else
    print("No broker found")
    return nil
  end
end

function Client:connect(broker_id)
  if not broker_id then
    broker_id = self:discover_broker()
    if not broker_id then
      return false, "No broker available"
    end
  end

  self.broker_id = broker_id
  rednet.send(self.broker_id, { type = "CONNECT" }, "RNTT")

  local sender, message = rednet.receive("RNTT", 5)
  if sender == self.broker_id and message and message.type == "CONNACK" then
    self.connected = true
    print("Connected to broker " .. self.broker_id)
    return true
  else
    print("Connection failed")
    return false, "Connection timeout or failed"
  end
end

function Client:disconnect()
  if not self.connected then
    return false, "Not connected"
  end

  rednet.send(self.broker_id, { type = "DISCONNECT" }, "RNTT")
  self.connected = false
  self.broker_id = nil
  print("Disconnected from broker")
  return true
end

function Client:publish(topic, payload)
  if not self.connected then
    return false, "Not connected to broker"
  end

  rednet.send(self.broker_id, {
    type = "PUBLISH",
    topic = topic,
    payload = payload
  }, "RNTT")

  local sender, message = rednet.receive("RNTT", 5)
  if sender == self.broker_id and message and message.type == "PUBACK" then
    print("Published to topic: " .. topic)
    return true
  else
    print("Publish failed or timed out")
    return false, "Publish acknowledgment failed"
  end
end

function Client:subscribe(topic)
  if not self.connected then
    return false, "Not connected to broker"
  end

  rednet.send(self.broker_id, {
    type = "SUBSCRIBE",
    topic = topic
  }, "RNTT")

  local sender, message = rednet.receive("RNTT", 5)
  if sender == self.broker_id and message and message.type == "SUBACK" then
    self.subscriptions[topic] = true
    print("Subscribed to topic: " .. topic)
    return true
  else
    print("Subscribe failed or timed out")
    return false, "Subscribe acknowledgment failed"
  end
end

function Client:unsubscribe(topic)
  if not self.connected then
    return false, "Not connected to broker"
  end

  rednet.send(self.broker_id, {
    type = "UNSUBSCRIBE",
    topic = topic
  }, "RNTT")

  local sender, message = rednet.receive("RNTT", 5)
  if sender == self.broker_id and message and message.type == "UNSUBACK" then
    self.subscriptions[topic] = nil
    print("Unsubscribed from topic: " .. topic)
    return true
  else
    print("Unsubscribe failed or timed out")
    return false, "Unsubscribe acknowledgment failed"
  end
end

function Client:listen()
  if not self.connected then
    print("Not connected to broker")
    return
  end

  print("Listening for messages (Ctrl+T to stop)...")
  print("Type commands: publish [topic] [message] | subscribe [topic] | unsubscribe [topic] | disconnect | quit")
  print()

  while self.connected do
    local event, p1, p2, p3 = os.pullEvent()

    if event == "rednet_message" then
      local sender, message, protocol = p1, p2, p3

      if sender == self.broker_id and protocol == "RNTT" then
        if message.type == "PUBLISH" then
          print("[" .. message.topic .. "] " .. tostring(message.payload))
        elseif message.type == "ERROR" then
          print("ERROR: " .. (message.message or "Unknown error"))
        end
      end

    elseif event == "char" or event == "key" then
      -- Start reading user input
      write("> ")
      local input = read()

      if input then
        local parts = {}
        for word in input:gmatch("%S+") do
          table.insert(parts, word)
        end

        local command = parts[1]

        if command == "publish" and #parts >= 3 then
          local topic = parts[2]
          local message = table.concat(parts, " ", 3)
          self:publish(topic, message)

        elseif command == "subscribe" and #parts >= 2 then
          local topic = parts[2]
          self:subscribe(topic)

        elseif command == "unsubscribe" and #parts >= 2 then
          local topic = parts[2]
          self:unsubscribe(topic)

        elseif command == "disconnect" or command == "quit" then
          self:disconnect()
          break

        elseif command == "help" then
          print("Commands:")
          print("  publish [topic] [message] - Publish a message")
          print("  subscribe [topic] - Subscribe to a topic")
          print("  unsubscribe [topic] - Unsubscribe from a topic")
          print("  disconnect | quit - Disconnect and exit")

        else
          print("Unknown command. Type 'help' for commands.")
        end
      end
    end
  end

  print("Stopped listening")
end

-- Convenience function to run a simple client
function Client.run(config)
  config = config or {}
  local client = Client.new(config)

  if client:connect() then
    client:listen()
  else
    print("Failed to connect to broker")
  end
end

return Client
