---@class ChallengeSettings
ChallengeSettings = CpObject()

function ChallengeSettings:init()
    self.multipliers = {}
    self.adminPassword = "admin123"
    self.logger = Logger("ChallengeSettings")
end

function ChallengeSettings:delete()
    self.multipliers = {}
end

---Load settings from Savegame settings.xml file
---@param savegameDirectory string Path to savegame folder
---@return boolean success
function ChallengeSettings:loadFromSavegame(savegameDirectory)
    local filePath = savegameDirectory .. "/Challenge_Settings.xml"
    
    if not fileExists(filePath) then
        self.logger:debug("No settings file found at %s, using defaults", filePath)
        return false
    end
    
    local xmlSchema = XMLSchema.new("ChallengeSettings")
    ChallengeSettings.registerXmlSchema(xmlSchema, "")
    
    local xmlFile = XMLFile.loadIfExists("challengeSettings", filePath, xmlSchema)
    if xmlFile then
        self:loadFromXML(xmlFile, "")
        xmlFile:delete()
        self.logger:info("Settings loaded from %s", filePath)
        return true
    else
        self.logger:warning("Could not load settings from %s", filePath)
        return false
    end
end

---Save settings to Savegame settings.xml file
---@param savegameDirectory string Path to savegame folder
---@return boolean success
function ChallengeSettings:saveToSavegame(savegameDirectory)
    local filePath = savegameDirectory .. "/Challenge_Settings.xml"
    
    local xmlSchema = XMLSchema.new("ChallengeSettings")
    ChallengeSettings.registerXmlSchema(xmlSchema, "")
    
    local xmlFile = XMLFile.create("challengeSettings", filePath, "ChallengeSettings", xmlSchema)
    if xmlFile then
        self:saveToXML(xmlFile, "")
        xmlFile:save()
        xmlFile:delete()
        self.logger:info("Settings saved to %s", filePath)
        return true
    else
        self.logger:warning("Could not save settings to %s", filePath)
        return false
    end
end

---Register XML schema
function ChallengeSettings.registerXmlSchema(xmlSchema, baseKey)
    baseKey = baseKey .. "ChallengeSettings"
    
    -- Admin Password
    xmlSchema:register(XMLValueType.STRING, baseKey .. "#adminPassword", "Admin password")
    
    -- Multipliers
    xmlSchema:register(XMLValueType.INT, baseKey .. ".Multiplier(?)#name", "Multiplier name")
    xmlSchema:register(XMLValueType.INT, baseKey .. ".Multiplier(?)#value", "Multiplier value")
    xmlSchema:register(XMLValueType.INT, baseKey .. ".Multiplier(?)#points", "Points for multiplier")
    xmlSchema:register(XMLValueType.STRING, baseKey .. ".Multiplier(?)#mode", "Rounding mode")
end

---Save settings to XML
function ChallengeSettings:saveToXML(xmlFile, baseKey)
    baseKey = baseKey .. "ChallengeSettings"
    
    -- Save admin password
    xmlFile:setValue(baseKey .. "#adminPassword", self.adminPassword)
    
    -- Save multipliers
    if g_pointTypeManager then
        local counter = 0
        for multiplierName, multiplier in pairs(g_pointTypeManager._multipliers) do
            counter = counter + 1
            local key = baseKey .. ".Multiplier(" .. counter .. ")"
            xmlFile:setValue(key .. "#name", multiplierName)
            xmlFile:setValue(key .. "#value", multiplier.value)
            xmlFile:setValue(key .. "#points", multiplier.points)
            xmlFile:setValue(key .. "#mode", multiplier.mode or "round")
        end
    end
end

---Load settings from XML
function ChallengeSettings:loadFromXML(xmlFile, baseKey)
    baseKey = baseKey .. "ChallengeSettings"
    
    -- Load admin password
    self.adminPassword = xmlFile:getValue(baseKey .. "#adminPassword", "admin123")
    
    -- Load multipliers into temporary table
    self.multipliers = {}
    xmlFile:iterate(baseKey .. ".Multiplier", function(ix, key)
        local name = xmlFile:getValue(key .. "#name")
        local value = xmlFile:getValue(key .. "#value", 1)
        local points = xmlFile:getValue(key .. "#points", 1)
        local mode = xmlFile:getValue(key .. "#mode", "round")
        
        if name then
            self.multipliers[name] = {
                value = value,
                points = points,
                mode = mode
            }
        end
    end)
    
    -- Apply loaded multipliers to PointTypeManager
    if g_pointTypeManager and next(self.multipliers) then
        for name, mult in pairs(self.multipliers) do
            g_pointTypeManager:setMultiplier(name, mult.value, mult.points, mult.mode)
        end
    end
end

---Get multiplier settings
---@param name string
---@return table|nil
function ChallengeSettings:getMultiplier(name)
    if g_pointTypeManager then
        return g_pointTypeManager:getMultiplier(name)
    end
    return self.multipliers[name]
end

---Set admin password
---@param password string
function ChallengeSettings:setAdminPassword(password)
    self.adminPassword = password
    if g_adminManager then
        g_adminManager:setPassword(password)
    end
end

---@type ChallengeSettings
g_challengeSettings = ChallengeSettings()
