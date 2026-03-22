
ChallengeFarmType = {}
ChallengeFarmType.DISABLED      = 1
ChallengeFarmType.NORMAL        = 2
ChallengeFarmType.CONTRACTOR    = 3

---@class ChallengeFarm
ChallengeFarm = CpObject()
function ChallengeFarm:init(farmId)
    ---@type number
    self._farmId = farmId
    ---@type PointManager
    self._pointManager = PointManager()
    ---@type ChangeLog
    self._changeLog = ChangeLog()
    ---@type VehicleTracker
    self._vehicleTracker = VehicleTracker()
    self._type = ChallengeFarmType.NORMAL
    self._totalPointsCache = 0
    ---@type Logger
    self.logger = Logger("ChallengeFarm[" .. farmId .. "]")
end

function ChallengeFarm:delete()
    self._pointManager:delete()
    self._changeLog:delete()
    self._vehicleTracker:delete()
end

function ChallengeFarm:onUpdate(dt)
    -- Set farm context so calculation functions can access farm-specific data
    if g_pointTypeManager then
        g_pointTypeManager:setCurrentFarmContext(self._farmId)
    end
    
    self._pointManager:calculatePoints()
end

---@return number
function ChallengeFarm:getFarmId()
    return self._farmId
end

function ChallengeFarm:populateCell(cell)
    if cell and cell:getAttribute then
        local titleAttr = cell:getAttribute("title")
        if titleAttr then
            titleAttr:setText(tostring(self._farmId))
        end
    end
end

---@return boolean
function ChallengeFarm:getIsActiveFarm()
    return self._type == ChallengeFarmType.NORMAL
end

function ChallengeFarm:setType(type)
    self._type = type
end

function ChallengeFarm:getType()
    return self._type
end

---@return PointManager
function ChallengeFarm:getPointManager()
    return self._pointManager
end

function ChallengeFarm:getTotalPoints()
    return self._pointManager:getTotalPoints()
end

---@param points number
---@param reason string
---@param adminName string
function ChallengeFarm:addPointsManual(points, reason, adminName)
    adminName = adminName or "Admin"
    reason = reason or "Manual adjustment"
    
    self._changeLog:addEntry(points, reason, adminName, "manual")
    self.logger:info("Manual points adjustment: %+d (Reason: %s)", points, reason)
    
    return self:getTotalPoints()
end

---@param reason string
---@param adminName string
function ChallengeFarm:subtractPointsManual(points, reason, adminName)
    return self:addPointsManual(-points, reason, adminName)
end

---@return ChangeLog
function ChallengeFarm:getChangeLog()
    return self._changeLog
end

---@return ChangeLogEntry[]
function ChallengeFarm:getChangeLogEntries(count)
    return self._changeLog:getLastEntries(count or 10)
end

---Vehicle management
---@param vehicleId number
function ChallengeFarm:markVehicleAsStarter(vehicleId)
    self._vehicleTracker:markAsStarterVehicle(vehicleId)
    self._changeLog:addEntry(0, "Vehicle " .. vehicleId .. " marked as starter", "System", "vehicle")
end

---@param vehicleId number
function ChallengeFarm:unmarkVehicleAsStarter(vehicleId)
    self._vehicleTracker:unmarkAsStarterVehicle(vehicleId)
    self._changeLog:addEntry(0, "Vehicle " .. vehicleId .. " unmarked as starter", "System", "vehicle")
end

---@param vehicleId number
---@return boolean new state
function ChallengeFarm:toggleVehicleStarter(vehicleId)
    return self._vehicleTracker:toggleStarterVehicle(vehicleId)
end

---@param vehicleId number
---@return boolean
function ChallengeFarm:isVehicleStarter(vehicleId)
    return self._vehicleTracker:isStarterVehicle(vehicleId)
end

---@return VehicleTracker
function ChallengeFarm:getVehicleTracker()
    return self._vehicleTracker
end

---@return number total vehicle value (excluding starters)
function ChallengeFarm:getTotalVehicleValue()
    return self._vehicleTracker:calculateTotalVehicleValue()
end

---@return number total implement value (excluding starters)
function ChallengeFarm:getTotalImplementValue()
    return self._vehicleTracker:calculateTotalImplementValue()
end

---Network streaming for multiplayer
function ChallengeFarm:onWriteStream(streamId, connection)
    self._pointManager:onWriteStream(streamId, connection)
    self._changeLog:onWriteStream(streamId, connection)
    self._vehicleTracker:onWriteStream(streamId, connection)
end

function ChallengeFarm:onReadStream(streamId, connection)
    self._pointManager:onReadStream(streamId, connection)
    self._changeLog:onReadStream(streamId, connection)
    self._vehicleTracker:onReadStream(streamId, connection)
end
end

---XML Persistence
function ChallengeFarm.registerXmlSchema(xmlSchema, baseKey)
    ChangeLog.registerXmlSchema(xmlSchema, baseKey)
    VehicleTracker.registerXmlSchema(xmlSchema, baseKey)
end

function ChallengeFarm:saveToXML(xmlFile, baseKey)
    local key = baseKey .. "Farm(" .. self._farmId .. ")"
    xmlFile:setValue(key .. "#id", self._farmId)
    xmlFile:setValue(key .. "#type", self._type)
    
    -- Save changelog
    self._changeLog:saveToXML(xmlFile, key .. ".")
    
    -- Save vehicle tracker
    self._vehicleTracker:saveToXML(xmlFile, key .. ".")
end

function ChallengeFarm:loadFromXML(xmlFile, baseKey)
    -- Load changelog
    self._changeLog:loadFromXML(xmlFile, baseKey)
    
    -- Load vehicle tracker
    self._vehicleTracker:loadFromXML(xmlFile, baseKey)
end
end
end