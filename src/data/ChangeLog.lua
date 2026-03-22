---@class ChangeLogEntry
ChangeLogEntry = CpObject()

function ChangeLogEntry:init(pointsDelta, reason, adminName, pointType)
    self.timestamp = g_currentMission:getGameTime() or 0
    self.realTimestamp = os.date("%Y-%m-%d %H:%M:%S")
    self.pointsDelta = pointsDelta or 0
    self.reason = reason or "No reason provided"
    self.adminName = adminName or "System"
    self.pointType = pointType or "unknown"
end

function ChangeLogEntry:toString()
    return string.format("[%s] %s: %+d points (%s) - Reason: %s (Admin: %s)", 
        self.realTimestamp, self.pointType, self.pointsDelta, 
        self.reason, self.adminName)
end

function ChangeLogEntry:getFormatted()
    return {
        timestamp = self.timestamp,
        realTime = self.realTimestamp,
        points = self.pointsDelta,
        reason = self.reason,
        admin = self.adminName,
        type = self.pointType
    }
end

---@class ChangeLog
ChangeLog = CpObject()

function ChangeLog:init()
    ---@type ChangeLogEntry[]
    self._entries = {}
    ---@type Logger
    self.logger = Logger("ChangeLog")
end

function ChangeLog:delete()
    self._entries = {}
end

---@param pointsDelta number
---@param reason string
---@param adminName string
---@param pointType string
function ChangeLog:addEntry(pointsDelta, reason, adminName, pointType)
    local entry = ChangeLogEntry(pointsDelta, reason, adminName, pointType)
    table.insert(self._entries, entry)
    self.logger:debug(entry:toString())
    return entry
end

---@return number
function ChangeLog:getNumEntries()
    return #self._entries
end

---@param index number
---@return ChangeLogEntry|nil
function ChangeLog:getEntry(index)
    if index < 1 or index > #self._entries then
        return nil
    end
    return self._entries[index]
end

---@return ChangeLogEntry[]
function ChangeLog:getAllEntries()
    return self._entries
end

---@param count number
---@return ChangeLogEntry[]
function ChangeLog:getLastEntries(count)
    count = count or 10
    local result = {}
    local startIdx = math.max(1, #self._entries - count + 1)
    for i = startIdx, #self._entries do
        table.insert(result, self._entries[i])
    end
    return result
end

---@param adminName string
---@return ChangeLogEntry[]
function ChangeLog:getEntriesByAdmin(adminName)
    local result = {}
    for _, entry in ipairs(self._entries) do
        if entry.adminName == adminName then
            table.insert(result, entry)
        end
    end
    return result
end

---@param pointType string
---@return ChangeLogEntry[]
function ChangeLog:getEntriesByPointType(pointType)
    local result = {}
    for _, entry in ipairs(self._entries) do
        if entry.pointType == pointType then
            table.insert(result, entry)
        end
    end
    return result
end

---@return number
function ChangeLog:getTotalPointsAdjustment()
    local total = 0
    for _, entry in ipairs(self._entries) do
        total = total + entry.pointsDelta
    end
    return total
end

---Will clear all entries
function ChangeLog:clear()
    self._entries = {}
    self.logger:info("ChangeLog cleared")
end

---XML Persistence
function ChangeLog.registerXmlSchema(xmlSchema, baseKey)
    local key = baseKey .. "ChangeLog.Entry(?)"
    xmlSchema:register(XMLValueType.INT, key .. "#timestamp", "Game time")
    xmlSchema:register(XMLValueType.STRING, key .. "#realTime", "Real timestamp")
    xmlSchema:register(XMLValueType.INT, key .. "#points", "Points delta")
    xmlSchema:register(XMLValueType.STRING, key .. "#reason", "Change reason")
    xmlSchema:register(XMLValueType.STRING, key .. "#admin", "Admin name")
    xmlSchema:register(XMLValueType.STRING, key .. "#type", "Point type")
end

function ChangeLog:saveToXML(xmlFile, baseKey)
    for ix, entry in ipairs(self._entries) do
        local key = baseKey .. "ChangeLog.Entry(" .. ix .. ")"
        xmlFile:setValue(key .. "#timestamp", entry.timestamp)
        xmlFile:setValue(key .. "#realTime", entry.realTimestamp)
        xmlFile:setValue(key .. "#points", entry.pointsDelta)
        xmlFile:setValue(key .. "#reason", entry.reason)
        xmlFile:setValue(key .. "#admin", entry.adminName)
        xmlFile:setValue(key .. "#type", entry.pointType)
    end
end

function ChangeLog:loadFromXML(xmlFile, baseKey)
    self._entries = {}
    xmlFile:iterate(baseKey .. "ChangeLog.Entry", function(ix, key)
        local entry = ChangeLogEntry()
        entry.timestamp = xmlFile:getValue(key .. "#timestamp", 0)
        entry.realTimestamp = xmlFile:getValue(key .. "#realTime", "unknown")
        entry.pointsDelta = xmlFile:getValue(key .. "#points", 0)
        entry.reason = xmlFile:getValue(key .. "#reason", "No reason")
        entry.adminName = xmlFile:getValue(key .. "#admin", "System")
        entry.pointType = xmlFile:getValue(key .. "#type", "unknown")
        table.insert(self._entries, entry)
    end)
    self.logger:debug("Loaded %d changelog entries", #self._entries)
end

---Network streaming
function ChangeLog:onWriteStream(streamId, connection)
    local count = math.min(#self._entries, 50)  -- Sync last 50 entries
    streamWriteUInt16(streamId, count)
    for i = math.max(1, #self._entries - 49), #self._entries do
        local entry = self._entries[i]
        streamWriteInt32(streamId, entry.pointsDelta)
        streamWriteString(streamId, entry.pointType)
        streamWriteString(streamId, entry.reason)
        streamWriteString(streamId, entry.adminName)
        streamWriteUInt32(streamId, entry.timestamp)
    end
end

function ChangeLog:onReadStream(streamId, connection)
    local count = streamReadUInt16(streamId)
    for _ = 1, count do
        local entry = ChangeLogEntry(0, "", "", "")
        entry.pointsDelta = streamReadInt32(streamId)
        entry.pointType = streamReadString(streamId)
        entry.reason = streamReadString(streamId)
        entry.adminName = streamReadString(streamId)
        entry.timestamp = streamReadUInt32(streamId)
        table.insert(self._entries, entry)
    end
end

---@return string
function ChangeLogEntry:getTimeString()
    return self.realTimestamp
end

---@return number
function ChangeLogEntry:getTimestamp()
    return self.timestamp
end

---@return number
function ChangeLogEntry:getPointsDelta()
    return self.pointsDelta
end

---@return string
function ChangeLogEntry:getPointType()
    return self.pointType
end

---@return string
function ChangeLogEntry:getReason()
    return self.reason
end

---@return string
function ChangeLogEntry:getAdminName()
    return self.adminName
