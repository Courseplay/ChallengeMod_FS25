PayToSpyEvent = {}
PayToSpyEvent_mt = Class(PayToSpyEvent, Event)

InitEventClass(PayToSpyEvent, "PayToSpyEvent")

function PayToSpyEvent.emptyNew()
    return Event.new(PayToSpyEvent_mt)
end

function PayToSpyEvent.new(money, ownFarmId, farmToSpy)
    local self = PayToSpyEvent.emptyNew()

    self.money = money
    self.ownFarmId = ownFarmId
    self.farmToSpy = farmToSpy

    return self
end

function PayToSpyEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.money)
    streamWriteInt8(streamId, self.ownFarmId)
    streamWriteInt8(streamId, self.farmToSpy)
end

function PayToSpyEvent:readStream(streamId, connection)
    self.money = streamReadInt32(streamId)
    self.ownFarmId = streamReadInt8(streamId)
    self.farmToSpy = streamReadInt8(streamId)

    self:run(connection)
end

function PayToSpyEvent:run(connection)
    if not connection:getIsServer() then
        g_currentMission:addMoney(self.money, self.ownFarmId, MoneyType.OTHER, true, true)

        g_server:broadcastEvent(self, true)
    end
end