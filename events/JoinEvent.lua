--- Event called on joining a multiplayer from the server to the joining player.
--- Used for synchronizing global value.
local JoinEvent = {}
local JoinEvent_mt = Class(JoinEvent, Event)

InitEventClass(JoinEvent, "JoinEvent")

function JoinEvent.emptyNew()
	return Event.new(JoinEvent_mt)
end

--- Creates a new Event
---@class JoinEvent
function JoinEvent.new()
	local self = JoinEvent.emptyNew()
	
	return self
end

--- Reads the serialized data on the receiving end of the event.
function JoinEvent:readStream(streamId, connection) 
	JoinEvent.debug("readStream")
	g_challengeMod:readStream(streamId, connection)
	
	self:run(connection);
end

--- Writes the serialized data from the sender.
function JoinEvent:writeStream(streamId, connection) 
	JoinEvent.debug("writeStream")
	g_challengeMod:writeStream(streamId, connection)

end

--- Runs the event on the receiving end of the event.
function JoinEvent:run(connection) 

end

function JoinEvent.debug(str, ...)
	CmUtil.debug("JoinEvent: "..str,...)
end

local function sendEvent(baseMission,connection, x, y, z, viewDistanceCoeff)
	-- body
	if connection ~= nil then 
		JoinEvent.debug("send Event")
		connection:sendEvent(JoinEvent.new())
	end
end

FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction(FSBaseMission.onConnectionFinishedLoading,sendEvent)