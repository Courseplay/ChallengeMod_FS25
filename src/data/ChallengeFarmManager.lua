
---@class ChallengeFarmManager
ChallengeFarmManager = CpObject()
function ChallengeFarmManager:init()
    ---@type ChallengeFarm[]
    self._farms = {}
    ---@type table<number, ChallengeFarm>
	self._farmIdToFarm = {}

    -- g_meesageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.onFarmChanged, self)
    ---@type Logger
    self.logger = Logger("ChallengeFarmManager")

    self.logger:debug("Num Farms: %d", #g_farmManager.farms)
end

function ChallengeFarmManager:onSetup()
    g_messageCenter:subscribe(MessageType.FARM_CREATED, self.onFarmCreated, self)
	g_messageCenter:subscribe(MessageType.FARM_DELETED, self.onFarmDeleted, self)
end
function ChallengeFarmManager:onUpdate(dt)
    for _, farm in ipairs(self._farms) do 
        farm:onUpdate(dt)
    end
end

---@param farmId number
function ChallengeFarmManager:onFarmCreated(farmId)
   table.insert(self._farms, ChallengeFarm(farmId) )
   self._farmIdToFarm[farmId] = self._farms[#self._farms]
   self.logger:debug("Created farm: %d", farmId)

end

---@param farmId number
function ChallengeFarmManager:onFarmDeleted(farmId)
    local farm = self._farmIdToFarm[farmId]
    if farm then
        farm:delete()
        table.removeElement(self._farms, farm)
        self._farmIdToFarm[farmId] = nil
    end
    self.logger:debug("Deleted farm: %d", farmId)
end

---@return number
function ChallengeFarmManager:getNumFarms()
    return #self._farms
end

---@return number
function ChallengeFarmManager:getNumActiveFarms()
    local count = 0
    for _, farm in ipairs(self._farms) do 
        if farm:getIsActiveFarm() then 
            count = count + 1
        end
    end
    return count
end

---@param index number
---@return ChallengeFarm|nil
function ChallengeFarmManager:getFarmByIndex(index)
    return self._farms[index]
end

---@param index number
---@return ChallengeFarm|nil
function ChallengeFarmManager:getActiveFarmByIndex(index)
    local count = 0
    for _, farm in ipairs(self._farms) do 
        if farm:getIsActiveFarm() then 
            if count == index then 
                return farm
            end
            count = count + 1
        end
    end
end

---@type ChallengeFarmManager
g_challengeFarmManager = ChallengeFarmManager()