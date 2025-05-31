ChangeDurationEvent = {}

ChangeDurationEvent_mt = Class(ChangeDurationEvent, Event)

InitEventClass(ChangeDurationEvent, "ChangeDurationEvent")

function ChangeDurationEvent.emptyNew()
    return Event.new(ChangeDurationEvent_mt)
end

function ChangeDurationEvent.new(duration)
    local self = ChangeDurationEvent.emptyNew()

    self.duration = duration

    return self
end

function ChangeDurationEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.duration)
end

function ChangeDurationEvent:readStream(streamId, connection)
    self.duration = streamReadInt32(streamId)

    self:run(connection)
end

function ChangeDurationEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(ChangeDurationEvent.new(self.duration), nil, connection)
    end

    g_challengeMod:setDuration(self.duration, true)
end

function ChangeDurationEvent.sendEvent(...)
    if g_server ~= nil then
        g_server:broadcastEvent(ChangeDurationEvent.new(...))
    else
        g_client:getServerConnection():sendEvent(ChangeDurationEvent.new(...))
    end
end