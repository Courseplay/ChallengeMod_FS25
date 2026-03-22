---@class VehicleTracker
VehicleTracker = CpObject()

function VehicleTracker:init()
    ---@type table<number, boolean> vehicle_id -> isStarterVehicle
    self._starterVehicles = {}
    ---@type Logger
    self.logger = Logger("VehicleTracker")
end

function VehicleTracker:delete()
    self._starterVehicles = {}
end

---Mark a vehicle as starter (won't count to points)
---@param vehicleId number
function VehicleTracker:markAsStarterVehicle(vehicleId)
    self._starterVehicles[vehicleId] = true
    self.logger:debug("Marked vehicle %d as starter", vehicleId)
end

---Unmark a vehicle as starter (will count to points)
---@param vehicleId number
function VehicleTracker:unmarkAsStarterVehicle(vehicleId)
    self._starterVehicles[vehicleId] = nil
    self.logger:debug("Unmarked vehicle %d as starter", vehicleId)
end

---Check if vehicle is marked as starter
---@param vehicleId number
---@return boolean
function VehicleTracker:isStarterVehicle(vehicleId)
    return self._starterVehicles[vehicleId] or false
end

---Toggle starter status of a vehicle
---@param vehicleId number
---@return boolean new state
function VehicleTracker:toggleStarterVehicle(vehicleId)
    if self:isStarterVehicle(vehicleId) then
        self:unmarkAsStarterVehicle(vehicleId)
        return false
    else
        self:markAsStarterVehicle(vehicleId)
        return true
    end
end

---Calculate total vehicle value (only non-starter vehicles)
---@return number total selling value
function VehicleTracker:calculateTotalVehicleValue()
    local totalValue = 0
    
    if not g_currentMission or not g_currentMission:getVehicles() then
        return 0
    end
    
    -- Iterate all vehicles in the mission
    for _, vehicle in pairs(g_currentMission:getVehicles()) do
        if vehicle and vehicle.sellPrice then
            -- Skip starter vehicles
            if not self:isStarterVehicle(vehicle.id) then
                totalValue = totalValue + vehicle.sellPrice
            end
        end
    end
    
    return totalValue
end

---Calculate total implement value (only non-starter tools)
---@return number total selling value
function VehicleTracker:calculateTotalImplementValue()
    local totalValue = 0
    
    if not g_currentMission or not g_currentMission:getImplements() then
        return 0
    end
    
    -- Iterate all implements in the mission
    for _, implement in pairs(g_currentMission:getImplements()) do
        if implement and implement.sellPrice then
            -- Skip starter implements
            if not self:isStarterVehicle(implement.id) then
                totalValue = totalValue + implement.sellPrice
            end
        end
    end
    
    return totalValue
end

---Get all starter vehicle IDs
---@return number[]
function VehicleTracker:getStarterVehicleIds()
    local starterIds = {}
    for vehicleId, isStarter in pairs(self._starterVehicles) do
        if isStarter then
            table.insert(starterIds, vehicleId)
        end
    end
    return starterIds
end

---Get count of marked starter vehicles
---@return number
function VehicleTracker:getStarterVehicleCount()
    local count = 0
    for _, isStarter in pairs(self._starterVehicles) do
        if isStarter then
            count = count + 1
        end
    end
    return count
end

---XML Persistence
function VehicleTracker.registerXmlSchema(xmlSchema, baseKey)
    local key = baseKey .. "VehicleTracker.StarterVehicle(?)"
    xmlSchema:register(XMLValueType.INT, key .. "#vehicleId", "Vehicle ID")
end

function VehicleTracker:saveToXML(xmlFile, baseKey)
    local counterIdx = 0
    for vehicleId, isStarter in pairs(self._starterVehicles) do
        if isStarter then
            counterIdx = counterIdx + 1
            local key = baseKey .. "VehicleTracker.StarterVehicle(" .. counterIdx .. ")"
            xmlFile:setValue(key .. "#vehicleId", vehicleId)
        end
    end
end

function VehicleTracker:loadFromXML(xmlFile, baseKey)
    self._starterVehicles = {}
    xmlFile:iterate(baseKey .. "VehicleTracker.StarterVehicle", function(ix, key)
        local vehicleId = xmlFile:getValue(key .. "#vehicleId")
        if vehicleId then
            self._starterVehicles[vehicleId] = true
            self.logger:debug("Loaded starter vehicle: %d", vehicleId)
        end
    end)
end

---Network streaming
function VehicleTracker:onWriteStream(streamId, connection)
    local starterIds = self:getStarterVehicleIds()
    streamWriteUInt16(streamId, #starterIds)
    for _, vehicleId in ipairs(starterIds) do
        streamWriteInt32(streamId, vehicleId)
    end
end

function VehicleTracker:onReadStream(streamId, connection)
    self._starterVehicles = {}
    local count = streamReadUInt16(streamId)
    for _ = 1, count do
        local vehicleId = streamReadInt32(streamId)
        self._starterVehicles[vehicleId] = true
    end
end

---@type VehicleTracker (will be created per farm)
