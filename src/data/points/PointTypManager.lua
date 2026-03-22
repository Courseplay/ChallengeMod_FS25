
---@class PointTypeManager
PointTypeManager = CpObject()
PointTypeManager.XML_KEY = "Points."
PointTypeManager.MULTIPLIERS_KEY = "Multipliers."

function PointTypeManager:init()
    ---@type PointType[]
    self._types = {}
	self._categories = {}
    
    -- Rounding modes
    self._roundingMode = "round" -- round, floor, ceil
    
    -- Multipliers for point calculations (loaded from XML)
    self._multipliers = {
        storageLiter = {value = 1000, points = 1, mode = "round"},
        paletteCount = {value = 1, points = 1, mode = "round"},
        baleCount = {value = 1, points = 1, mode = "round"},
        money = {value = 1, points = 1, mode = "round"},
        loan = {value = 1, points = -1, mode = "round"},
        fieldArea = {value = 1, points = 1, mode = "round"},
        vehicleValue = {value = 1, points = 1, mode = "round"},
        toolValue = {value = 1, points = 1, mode = "round"},
        buildingValue = {value = 1, points = 1, mode = "round"},
        animalCount = {value = 1, points = 1, mode = "round"},
        soldFish = {value = 1, points = 1, mode = "round"},
    }
    
    -- Current farm context for calculation functions
    self._currentFarmId = nil
    
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
    
    -- Register multipliers schema
    local multKey = baseKey .. PointTypeManager.MULTIPLIERS_KEY
    xmlSchema:register(XMLValueType.INT, multKey .. "StorageLiter#value", "Storage liter multiplier")
    xmlSchema:register(XMLValueType.INT, multKey .. "StorageLiter#points", "Points for storage")
    xmlSchema:register(XMLValueType.STRING, multKey .. "StorageLiter#roundingMode", "Rounding mode")
    
    -- Register other multipliers similarly
    for mulKey, _ in pairs({
        PaletteCount = true, BaleCount = true, Money = true, Loan = true,
        FieldArea = true, VehicleValue = true, ToolValue = true, BuildingValue = true, AnimalCount = true
    }) do
        xmlSchema:register(XMLValueType.INT, multKey .. mulKey .. "#value", mulKey .. " multiplier")
        xmlSchema:register(XMLValueType.INT, multKey .. mulKey .. "#points", "Points for " .. mulKey)
        xmlSchema:register(XMLValueType.STRING, multKey .. mulKey .. "#roundingMode", "Rounding mode")
    end
end

function PointTypeManager:loadFromXMLFile(xmlFile, baseKey)
    self._categories = {}
    
    -- Load multipliers
    xmlFile:iterate(baseKey .. self.MULTIPLIERS_KEY, function(i, key)
        local multiplierType = key:match("([^%.]+)$")
        if multiplierType then
            local value = xmlFile:getValue(key .. "#value", 1)
            local points = xmlFile:getValue(key .. "#points", 1)
            local mode = xmlFile:getValue(key .. "#roundingMode", "round")
            
            -- Convert type name to camelCase for _multipliers table
            local typeKey = multiplierType:sub(1, 1):lower() .. multiplierType:sub(2)
            
            self._multipliers[typeKey] = {
                value = value,
                points = points,
                mode = mode
            }
            self.logger:debug("Loaded multiplier %s: %d = %d points", typeKey, value, points)
        end
    end)
    
    -- Load point categories
    xmlFile:iterate(baseKey .. self.XML_KEY .. PointCategory.XML_KEY, function (i, key)
        local category = PointCategory()
        category:loadFromXMLFile(xmlFile, key)
		table.insert(self._categories, category)
        self.logger:debug("Loaded category: %s with %d points", category:getName(), #category:getPoints())
    end)    
end

---------------------------------------------------
--- Rounding helper functions
---------------------------------------------------

---@param value number
---@param mode string "round", "floor", "ceil"
---@return number
function PointTypeManager:round(value, mode)
    mode = mode or "round"
    if mode == "ceil" then
        return math.ceil(value)
    elseif mode == "floor" then
        return math.floor(value)
    else -- default: round
        return math.floor(value + 0.5)
    end
end

---@param actualValue number
---@param multiplier table {value, points, mode}
---@return number points
function PointTypeManager:calculatePointsFromMultiplier(actualValue, multiplier)
    if not multiplier or not multiplier.value or multiplier.value == 0 then
        return 0
    end
    
    local ratio = actualValue / multiplier.value
    local roundedRatio = self:round(ratio, multiplier.mode)
    local calculatedPoints = roundedRatio * multiplier.points
    
    return self:round(calculatedPoints, multiplier.mode)
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
function PointTypeManager:composePalettes(type)
    -- TODO: Implement palette system detection
    return {Point(type, "palettes")}
end

---@param type PointType
function PointTypeManager:composeBales(type)
    -- TODO: Implement bale system detection
    return {Point(type, "bales")}
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

---@return number
function PointTypeManager:calculateFieldArea(type)
    if not self._currentFarmId then
        return 0
    end
    
    local totalArea = 0
    if g_fieldManager then
        local fields = g_fieldManager:getFields()
        if fields then
            for _, field in pairs(fields) do
                if field and field:getOwner and field:getOwner() == self._currentFarmId then
                    totalArea = totalArea + (field:getAreaHa() or 0)
                end
            end
        end
    end
    
    return self:calculatePointsFromMultiplier(totalArea, self._multipliers.fieldArea)
end

---@return number
function PointTypeManager:calculateBuildingValue(type)
    if not self._currentFarmId then
        return 0
    end
    
    local totalValue = 0
    if g_currentMission and g_currentMission.placeableSystem then
        local placeables = g_currentMission.placeableSystem.placeables
        if placeables then
            for _, placeable in pairs(placeables) do
                if placeable and placeable:getOwnerFarmId and placeable:getOwnerFarmId() == self._currentFarmId then
                    local monetaryValue = placeable:getMonetaryValue and placeable:getMonetaryValue() or 0
                    totalValue = totalValue + monetaryValue
                end
            end
        end
    end
    
    return self:calculatePointsFromMultiplier(totalValue, self._multipliers.buildingValue)
end

---@return number
function PointTypeManager:calculateVehicleValue(type)
    if not self._currentFarmId then
        return 0
    end
    
    -- Get farm and use its VehicleTracker if available
    if g_challengeFarmManager then
        local farm = g_challengeFarmManager:getFarm(self._currentFarmId)
        if farm and farm:getTotalVehicleValue then
            local value = farm:getTotalVehicleValue()
            return self:calculatePointsFromMultiplier(value, self._multipliers.vehicleValue)
        end
    end
    
    return 0
end

---@return number
function PointTypeManager:calculateToolValue(type)
    if not self._currentFarmId then
        return 0
    end
    
    -- Get farm and use its VehicleTracker if available
    if g_challengeFarmManager then
        local farm = g_challengeFarmManager:getFarm(self._currentFarmId)
        if farm and farm:getTotalImplementValue then
            local value = farm:getTotalImplementValue()
            return self:calculatePointsFromMultiplier(value, self._multipliers.toolValue)
        end
    end
    
    return 0
end

---@return number
function PointTypeManager:calculateMoney(type)
    if not self._currentFarmId then
        return 0
    end
    
    if g_currentMission then
        local farm = g_currentMission:getFarmById(self._currentFarmId)
        if farm then
            local balance = farm:getBalance() or farm.money or 0
            return self:calculatePointsFromMultiplier(balance, self._multipliers.money)
        end
    end
    
    return 0
end

---@return number
function PointTypeManager:calculateLoan(type)
    if not self._currentFarmId then
        return 0
    end
    
    if g_currentMission then
        local farm = g_currentMission:getFarmById(self._currentFarmId)
        if farm then
            local loan = farm:getLoan() or farm.loan or 0
            -- Loan is typically a penalty, so negate it
            return self:calculatePointsFromMultiplier(loan, self._multipliers.loan)
        end
    end
    
    return 0
end

---@return number
function PointTypeManager:calculateStorageLiter(type)
    -- TODO: Calculate storage liter with multiplier
    if not g_currentMission or not g_currentMission.storageSystem then
        return 0
    end
    
    local totalLiter = 0
    for _, storage in pairs(g_currentMission.storageSystem:getStorages()) do
        local fillLevels = storage:getFillLevels()
        for fillType, amount in pairs(fillLevels) do
            totalLiter = totalLiter + amount
        end
    end
    
    return self:calculatePointsFromMultiplier(totalLiter, self._multipliers.storageLiter)
end

---@return number
function PointTypeManager:calculatePaletteCount(type)
    -- TODO: Calculate palette count with multiplier
    return 0
end

---@return number
function PointTypeManager:calculateBaleCount(type)
    -- TODO: Calculate bale count with multiplier
    return 0
end

---@return number
function PointTypeManager:calculateAnimalCount(type)
    -- TODO: Calculate animal count with multiplier
    return 0
end

---@return number
function PointTypeManager:calculateSoldFish(type)
    -- Get sold fish count from FarmStats (requires Highlands Fishing Pack)
    if not self._currentFarmId then
        self.logger:warning("calculateSoldFish: No farm context set")
        return 0
    end
    
    if not g_currentMission or not g_currentMission.farmStats then
        self.logger:debug("calculateSoldFish: Mission or farmStats not available")
        return 0
    end
    
    local stats = g_currentMission:farmStats(self._currentFarmId)
    if not stats then
        self.logger:debug("calculateSoldFish: FarmStats not found for farm %d", self._currentFarmId)
        return 0
    end
    
    -- Get the count of sold fish from the FarmStats object
    local soldFishCount = stats:getTotalValue("numSoldFish") or 0
    
    return self:calculatePointsFromMultiplier(soldFishCount, self._multipliers.soldFish)
end

---@param name string
---@return table|nil
function PointTypeManager:getMultiplier(name)
    return self._multipliers[name]
end

---Set the current farm context for calculate functions
---@param farmId number|nil
function PointTypeManager:setCurrentFarmContext(farmId)
    self._currentFarmId = farmId
end

---@return number|nil
function PointTypeManager:getCurrentFarmContext()
    return self._currentFarmId
end

---@param name string
---@param value number
---@param points number
---@param mode string
function PointTypeManager:setMultiplier(name, value, points, mode)
    if not self._multipliers[name] then
        self._multipliers[name] = {}
    end
    self._multipliers[name].value = value
    self._multipliers[name].points = points
    self._multipliers[name].mode = mode or "round"
    self.logger:debug("Updated multiplier %s: %d = %d points (mode: %s)", name, value, points, mode)
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