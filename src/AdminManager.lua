---@class AdminManager
AdminManager = CpObject()

function AdminManager:init()
    self._isAdminActive = false
    self._adminPassword = "admin123"  -- Default, wird von settings.xml überschrieben
    self._currentAdminName = nil
    self._sessionStartTime = nil
    self.logger = Logger("AdminManager")
end

function AdminManager:delete()
    self._isAdminActive = false
    self._currentAdminName = nil
    self._sessionStartTime = nil
end

---Check if admin mode is currently active
---@return boolean
function AdminManager:isAdminActive()
    return self._isAdminActive
end

---Get current admin name
---@return string|nil
function AdminManager:getAdminName()
    return self._currentAdminName
end

---Try to login with password
---@param password string
---@param playerName string
---@return boolean success
function AdminManager:login(password, playerName)
    if self._isAdminActive then
        self.logger:warning("Admin already logged in as %s", self._currentAdminName)
        return false
    end
    
    if password == self._adminPassword then
        self._isAdminActive = true
        self._currentAdminName = playerName or "Admin"
        self._sessionStartTime = g_currentMission:getGameTime() or 0
        self.logger:info("Admin login successful: %s", self._currentAdminName)
        return true
    else
        self.logger:warning("Admin login failed - wrong password")
        return false
    end
end

---Logout from admin mode
function AdminManager:logout()
    if self._isAdminActive then
        self.logger:info("Admin logout: %s", self._currentAdminName)
    end
    self._isAdminActive = false
    self._currentAdminName = nil
    self._sessionStartTime = nil
end

---Check if player can perform admin action
---@param playerFarmId number|nil
---@return boolean canPerformAction
function AdminManager:canPerformAdminAction(playerFarmId)
    -- Farm 1 is always allowed (host), or if admin is active
    if playerFarmId == 1 then
        return true
    end
    
    if self._isAdminActive then
        return true
    end
    
    return false
end

---Set admin password (only in singleplayer setup)
---@param newPassword string
function AdminManager:setPassword(newPassword)
    if newPassword and newPassword ~= "" then
        self._adminPassword = newPassword
        self.logger:info("Admin password changed")
    end
end

---Get session duration in minutes
---@return number
function AdminManager:getSessionDurationMinutes()
    if not self._sessionStartTime then
        return 0
    end
    
    local currentTime = g_currentMission:getGameTime() or 0
    local deltaMs = currentTime - self._sessionStartTime
    return math.floor(deltaMs / 60000)  -- Convert to minutes
end

---XML Persistence
function AdminManager.registerXmlSchema(xmlSchema, baseKey)
    xmlSchema:register(XMLValueType.STRING, baseKey .. "AdminManager#password", "Admin password")
end

function AdminManager:saveToXML(xmlFile, baseKey)
    xmlFile:setValue(baseKey .. "AdminManager#password", self._adminPassword)
end

function AdminManager:loadFromXML(xmlFile, baseKey)
    self._adminPassword = xmlFile:getValue(baseKey .. "AdminManager#password", "admin123")
end

---@type AdminManager
g_adminManager = AdminManager()
