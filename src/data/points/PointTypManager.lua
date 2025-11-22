
---@class PointTypeManager
PointTypeManager = CpObject()
PointTypeManager.XML_KEY = "Points."
function PointTypeManager:init()
    ---@type PointType[]
    self._types = {}
	self._categories = {}
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
    xmlFile:iterate(baseKey .. self.XML_KEY .. PointCategory.XML_KEY, function (i, key)
        local category = PointCategory()
        category:loadFromXMLFile(xmlFile, key)
		table.insert(self._categories, category)
    end)    
end

---------------------------------------------------
--- Compose functions
---------------------------------------------------

---@param type PointType
function PointTypeManager:composeStorage(type)
    local fillTypes = {}
    for _, storage in pairs(g_currentMission.storageSystem:getStorages()) do
		local fillLevels = storage:getFillLevels()
		for fillType, v in pairs(fillLevels) do
			fillTypes[fillType] = true
		end
	end
	local types = {}
	for _, f in pairs(table.toList(fillTypes)) do 
		table.insert(types, Point(type, f))
	end
	return types
end

---@param type PointType
function PointTypeManager:composeProductionStorage(type)
	local fillTypes = {}
    for _, production in pairs(g_currentMission.productionChainManager:getProductionPointsFromString('all')) do
		local storage = production.storage
		for fillType, _ in pairs(production.outputFillTypeIds) do
			local fillLevel = storage:getFillLevel(fillType)

			fillTypes[fillType] = true
		end
	end
	local types = {}
	for _, f in pairs(table.toList(fillTypes)) do 
		table.insert(types, Point(type, f))
	end
	return types
end


---@param type PointType
function PointTypeManager:composeAnimals(type)
	local types = {}
	for _, type in ipairs(g_currentMission.animalSystem:getTypes()) do
		table.insert(types, Point(type, type["name"]))
	end
	return types
end

---------------------------------------------------
--- Calculate functions
---------------------------------------------------

-- ---@param type PointType
-- function PointTypeManager:composeStorage(type)
    
-- end


---------------------------------------------------
--- Callbacks
---------------------------------------------------

function PointTypeManager:raiseCallback(funcName, ...)
    assert(self[funcName] ~= nil)
    return self[funcName](self, ...)
end

function PointTypeManager:gatherFillTypePoint(index)
    
end

---@type PointTypeManager
g_pointTypeManager = PointTypeManager()