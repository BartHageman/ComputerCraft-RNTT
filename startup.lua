local Broker = require("broker")

local b = Broker.new({})
b:use(require("logger"))
    :use(require("noteblock"))
-- :use(require("slowpoke"))
-- :use(require("printer"))
    :start()
