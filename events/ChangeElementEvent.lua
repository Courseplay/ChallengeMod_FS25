ChangeElementEvent = {
	TYPES = {
		VictoryPoint,
		Rule,
	},
	SEND_NUM_BITS = 2,
	POINT = 1,
	RULE = 2
}
local ChangeElementEvent_mt = Class(ChangeElementEvent, Event)

InitEventClass(ChangeElementEvent, "ChangeElementEvent")

function ChangeElementEvent.emptyNew()
	return Event.new(ChangeElementEvent_mt)
end
---@class ChangeElementEvent
function ChangeElementEvent.new(element, type)
	local self = ChangeElementEvent.emptyNew()
	self.element = element
	self.type = type
	return self
end

function ChangeElementEvent:readStream(streamId, connection)
	local type = streamReadUIntN(streamId, self.SEND_NUM_BITS)
	CmUtil.debug("ChangeElementEvent readStream type: %s", type)

	local categoryName = streamReadString(streamId)
	local categoryId = streamReadUInt8(streamId)
	local name = streamReadString(streamId)
	local value = streamReadFloat32(streamId)
	local ix
	if type == 2 then
		ix = streamReadUInt8(streamId)
	end
	local element = self.TYPES[type].readStream(categoryName, categoryId, name, value, ix)

	self:run(connection, element, type)
end

function ChangeElementEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.type, self.SEND_NUM_BITS)
	CmUtil.debug("ChangeElementEvent writeStream type: %s ", self.type)

	streamWriteString(streamId, self.element:getParent():getName())
	streamWriteUInt8(streamId, self.element:getParent().id)
	streamWriteString(streamId, self.element.name)
	streamWriteFloat32(streamId, self.element:getFactor())
	if self.type == 2 then
		streamWriteUInt8(streamId, self.element.currentIx)
	end

end

function ChangeElementEvent:run(connection, element, type)
	if not connection:getIsServer() then
		g_server:broadcastEvent(ChangeElementEvent.new(element, type), nil, connection)
	end
	g_challengeMod.frame:updateLists()
end

function ChangeElementEvent.sendEvent(element, type)
	if g_server ~= nil then
		g_server:broadcastEvent(ChangeElementEvent.new(element, type))
	else
		g_client:getServerConnection():sendEvent(ChangeElementEvent.new(element, type))
	end
end
