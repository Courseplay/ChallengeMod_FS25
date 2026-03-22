
---@class PointTypeManager
PointTypeManager = CpObject()
PointTypeManager.XML_KEY = "Points."
function PointTypeManager:init()
    ---@type PointType[]
    self._types = {}
	self._categories = {}
    ---@type Logger
    self.logger = Logger("PointTypeManager")
end

---@param index number
---@return PointType
function PointTypeManager:getTypeByIndex(index)
    return self._types[index]
end

function PointTypeManager.registerConfigXmlSchema(xmlSchema, baseKey)
    local key = baseKey .. PointTypeManager.XML_KEY
    PointCategory.registerXmlSchema(xmlSchema, key)
end

function PointTypeManager:loadFromXMLFile(xmlFile, baseKey)
    self._categories = {}
    xmlFile:iterate(baseKey .. self.XML_KEY .. PointCategory.XML_KEY, function (i, key)
        local category = PointCategory()
        category:loadFromXMLFile(xmlFile, key)
		table.insert(self._categories, category)
        self.logger:debug("Loaded category: %s with %d points", category:getName(), #category:getPoints())
    end)    
end

---------------------------------------------------
--- Compose functions
---------------------------------------------------

---@param type PointType
function PointTypeManager:composeStorage(type)
    local fillTypes = {}
    if g_currentMission and g_currentMission.storageSystem then
        for _, storage in pairs(g_currentMission.storageSystem:getStorages()) do
            local fillLevels = storage:getFillLevels()
            for fillType, v in pairs(fillLevels) do
                fillTypes[fillType] = true
            end
        end
    end
	local types = {}
	for _, f in pairs(table.toList(fillTypes)) do 
		table.insert(types, Point(type, tostring(f)))
	end
	return types
end

---@param type PointType
function PointTypeManager:composeProductionStorage(type)
    local fillTypes = {}
    if g_currentMission and g_currentMission.productionChainManager then
        for _, production in pairs(g_currentMission.productionChainManager:getProductionPointsFromString('all')) do
            local storage = production.storage
            for fillType, _ in pairs(production.outputFillTypeIds) do
                local fillLevel = storage:getFillLevel(fillType)
                fillTypes[fillType] = true
            end
        end
    end
	local types = {}
	for _, f in pairs(table.toList(fillTypes)) do 
		table.insert(types, Point(type, tostring(f)))
	end
	return types
end

---@param type PointType
function PointTypeManager:composeAnimals(type)
	local types = {}
    if g_currentMission and g_currentMission.animalSystem then
        for _, aType in ipairs(g_currentMission.animalSystem:getTypes()) do
            table.insert(types, Point(type, aType["name"]))
        end
    end
	return types
end

---------------------------------------------------
--- Calculate functions
---------------------------------------------------

function PointTypeManager:CalculateArea(type)
    -- TODO: Implement area calculation
    return 0
end

function PointTypeManager:calculateMoney(type)
    -- TODO: Implement money calculation
    return 0
end

function PointTypeManager:calculateLoan(type)
    -- TODO: Implement loan calculation  
    return 0
end

---------------------------------------------------
--- Callbacks
---------------------------------------------------

function PointTypeManager:raiseCallback(funcName, ...)
    if self[funcName] == nil then
        self.logger:warning("Callback function '%s' not found", funcName)
        return 0
    end
    return self[funcName](self, ...)
end

function PointTypeManager:gatherFillTypePoint(index)
    
end

---@type PointTypeManager
g_pointTypeManager = PointTypeManager()