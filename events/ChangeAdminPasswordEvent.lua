ChangeAdminPasswordEvent = {
}
local ChangeAdminPasswordEvent_mt = Class(ChangeAdminPasswordEvent, Event)

InitEventClass(ChangeAdminPasswordEvent, "ChangeAdminPasswordEvent")

function ChangeAdminPasswordEvent.emptyNew()
	return Event.new(ChangeAdminPasswordEvent_mt)
end
---@class ChangeAdminPasswordEvent
function ChangeAdminPasswordEvent.new(password)
	local self = ChangeAdminPasswordEvent.emptyNew()
	self.password = password
	return self
end

function ChangeAdminPasswordEvent:readStream(streamId, connection)
	self.password = streamReadString(streamId)
	self:run(connection)
end

function ChangeAdminPasswordEvent:writeStream(streamId, connection)
	streamWriteString(streamId, self.password)
end

function ChangeAdminPasswordEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(ChangeAdminPasswordEvent.new(self.password), nil, connection)
	end
	g_challengeMod:changeAdminPassword(self.password, true)
end

function ChangeAdminPasswordEvent.sendEvent(...)
	if g_server ~= nil then
		g_server:broadcastEvent(ChangeAdminPasswordEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(ChangeAdminPasswordEvent.new(...))
	end
end
