ChallengeOverEvent = {}

ChallengeOverEvent_mt = Class(ChallengeOverEvent, Event)

InitEventClass(ChallengeOverEvent, "ChallengeOverEvent")

function ChallengeOverEvent.emptyNew()
    return Event.new(ChallengeOverEvent_mt)
end

function ChallengeOverEvent.new(finalPoints, farmId)
    local self = ChallengeOverEvent.emptyNew()

    self.finalPoints = finalPoints
    self.farmId = farmId

    return self
end

function ChallengeOverEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.finalPoints)
    streamWriteInt8(streamId, self.farmId)
end

function ChallengeOverEvent:readStream(streamId, connection)
    self.finalPoints = streamReadInt32(streamId)
    self.farmId = streamReadInt8(streamId)

    self:run(connection)
end

function ChallengeOverEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(ChallengeOverEvent.new(self.finalPoints, self.farmId), nil, connection)
    end
    g_challengeMod:setFinalPointsForFarm(self.finalPoints, self.farmId, true)
end

function ChallengeOverEvent.sendEvent(...)
    if g_server ~= nil then
        g_server:broadcastEvent(ChallengeOverEvent.new(...))
    else
        g_client:getServerConnection():sendEvent(ChallengeOverEvent.new(...))
    end
end