AddPointsEvent = {}
AddPointsEvent_mt = Class(AddPointsEvent, Event)

InitEventClass(AddPointsEvent, "AddPointsEvent")

function AddPointsEvent.emptyNew()
    return Event.new(AddPointsEvent_mt)
end

function AddPointsEvent.new(farmId, point)
    local self = AddPointsEvent.emptyNew()

    self.farmId = farmId
    self.points = point.points
    self.addedBy = point.addedBy
    self.date = point.date
    self.reason = point.reason

    return self
end

function AddPointsEvent:writeStream(streamId, connection)
    streamWriteInt8(streamId, self.farmId)
    streamWriteInt32(streamId, self.points)
    streamWriteString(streamId, self.addedBy)
    streamWriteString(streamId, self.date)
    streamWriteString(streamId, self.reason)
end

function AddPointsEvent:readStream(streamId, connection)
    self.farmId = streamReadInt8(streamId)
    self.points = streamReadInt32(streamId)
    self.addedBy = streamReadString(streamId)
    self.date = streamReadString(streamId)
    self.reason = streamReadString(streamId)

    self:run(connection)
end

function AddPointsEvent:run(connection)
    local point = CmUtil.packPointData(self.points, self.addedBy, self.date, self.reason)

    if not connection:getIsServer() then
        g_server:broadcastEvent(AddPointsEvent.new(self.farmId, point), nil, connection)
    end
    g_victoryPointManager:addAdditionalPoint(self.farmId, point, true)
end

function AddPointsEvent.sendEvent(...)
    if g_server ~= nil then
        g_server:broadcastEvent(AddPointsEvent.new(...))
    else
        g_client:getServerConnection():sendEvent(AddPointsEvent.new(...))
    end
end