ChangeFarmVisibilityEvent = {
}
local ChangeFarmVisibilityEvent_mt = Class(ChangeFarmVisibilityEvent, Event)

InitEventClass(ChangeFarmVisibilityEvent, "ChangeFarmVisibilityEvent")

function ChangeFarmVisibilityEvent.emptyNew()
	return Event.new(ChangeFarmVisibilityEvent_mt)
end
---@class ChangeFarmVisibilityEvent
function ChangeFarmVisibilityEvent.new(farmId, visible)
	local self = ChangeFarmVisibilityEvent.emptyNew()
	self.visible = visible
	self.farmId = farmId
	return self
end

function ChangeFarmVisibilityEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.visible = streamReadBool(streamId)
	self:run(connection)
end

function ChangeFarmVisibilityEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteBool(streamId, self.visible)
end

function ChangeFarmVisibilityEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(ChangeFarmVisibilityEvent.new(self.farmId, self.visible), nil, connection)
	end
	g_challengeMod:changeFarmVisibility(self.farmId, self.visible, true)
end

function ChangeFarmVisibilityEvent.sendEvent(...)
	if g_server ~= nil then
		g_server:broadcastEvent(ChangeFarmVisibilityEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(ChangeFarmVisibilityEvent.new(...))
	end
end
