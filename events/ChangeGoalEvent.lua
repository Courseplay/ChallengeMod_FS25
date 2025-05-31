ChangeGoalEvent = {}

ChangeGoalEvent_mt = Class(ChangeGoalEvent, Event)

InitEventClass(ChangeGoalEvent, "ChangeGoalEvent")

function ChangeGoalEvent.emptyNew()
    return Event.new(ChangeGoalEvent_mt)
end

function ChangeGoalEvent.new(goal)
    local self = ChangeGoalEvent.emptyNew()
    self.goal = goal

    return self
end

function ChangeGoalEvent:readStream(streamId, connection)
    self.goal = streamReadInt32(streamId)

    self:run(connection)
end

function ChangeGoalEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.goal)
end

function ChangeGoalEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(ChangeGoalEvent.new(self.goal), nil, connection)
    end
    g_victoryPointManager:setGoal(self.goal, true)
end

function ChangeGoalEvent.sendEvent(...)
    if g_server ~= nil then
        g_server:broadcastEvent(ChangeGoalEvent.new(...))
    else
        g_client:getServerConnection():sendEvent(ChangeGoalEvent.new(...))
    end
end