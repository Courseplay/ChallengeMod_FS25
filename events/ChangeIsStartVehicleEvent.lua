ChangeIsStartVehicleEvent = {}
ChangeIsStartVehicleEvent_mt = Class(ChangeIsStartVehicleEvent, Event)

InitEventClass(ChangeIsStartVehicleEvent, "ChangeIsStartVehicleEvent")

function ChangeIsStartVehicleEvent.emptyNew()
    return Event.new(ChangeIsStartVehicleEvent_mt)
end

function ChangeIsStartVehicleEvent.new(vehicle, isStartVehicle)
    local self = ChangeIsStartVehicleEvent.emptyNew()

    self.vehicle = vehicle
    --self.isStartVehicle = isStartVehicle

    return self
end

function ChangeIsStartVehicleEvent:writeStream(streamId, connection)
    --streamWriteInt32(streamId, self.vehicleId)
    --streamWriteBool(streamId, self.isStartVehicle)

    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    self.vehicle:writeStream(streamId, connection)
end

function ChangeIsStartVehicleEvent:readStream(streamId, connection)
    --self.vehicleId = streamReadInt32(streamId)
    --self.isStartVehicle = streamReadBool(streamId)
    self.vehicle = NetworkUtil.readNodeObject(streamId, self.vehicle)
    self.vehicle:readStream(streamId, connection)

    self:run(connection)
end

function ChangeIsStartVehicleEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(ChangeIsStartVehicleEvent.new(self.vehicle), nil, connection)
    end

    --[[for _, vehicle in pairs(g_currentMission.vehicles) do
        if vehicle.id == self.vehicleId then
            vehicle.isStartVehicle = self.isStartVehicle

            break
        end
    end]]
end

function ChangeIsStartVehicleEvent.sendEvent(...)
    if g_server ~= nil then
        g_server:broadcastEvent(ChangeIsStartVehicleEvent.new(...))
    else
        g_client:getServerConnection():sendEvent(ChangeIsStartVehicleEvent.new(...))
    end
end