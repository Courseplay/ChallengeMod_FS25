
---@class PointTypeManager
PointTypeManager = CpObject()
PointTypeManager.XML_KEY = "Points."
function PointTypeManager:init()
    ---@type PointType[]
    self._types = {}
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
    end)    
end

---------------------------------------------------
--- Compose functions
---------------------------------------------------

---@param type PointType
function PointTypeManager:composeStorage(type)
    local fillTypes = {}
    for _, storage in pairs(g_currentMission.storageSystem:getStorages()) do
		if usedStorages[storage] == nil and storage:getOwnerFarmId() == farmId and not storage.foreignSilo then
			usedStorages[storage] = true
			local fillLevels = storage:getFillLevels()
			for fillType, v in pairs(fillLevels) do
				CmUtil.debug("Storage fillType(%s) found.", g_fillTypeManager:getFillTypeNameByIndex(fillType))
				totalFillLevel = totalFillLevel + v
				if totalFillLevels[fillType] == nil then
					totalFillLevels[fillType] = 0
				end
				totalFillLevels[fillType] = math.min(totalFillLevels[fillType] + v, maxFillLevel)
			end
		end
	end

end

---@param type PointType
function PointTypeManager:composeProductionStorage(type)
    for _, production in pairs(g_currentMission.productionChainManager:getProductionPointsForFarmId(farmId)) do
		local storage = production.storage

		for fillType, _ in pairs(production.outputFillTypeIds) do
			local fillLevel = storage:getFillLevel(fillType)

			if totalFillLevels[fillType] == nil then
				totalFillLevels[fillType] = 0
			end
			totalFillLevels[fillType] = math.min(totalFillLevels[fillType] + fillLevel, maxFillLevel)
		end
	end
end


---@param type PointType
function PointTypeManager:composeAnimals(type)
    
end

---------------------------------------------------
--- Calculate functions
---------------------------------------------------

---@param type PointType
function PointTypeManager:composeStorage(type)
    
end


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