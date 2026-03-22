
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
    self._type = ChallengeFarmType.NORMAL
    ---@type Logger
    self.logger = Logger("ChallengeFarm[" .. farmId .. "]")
end

function ChallengeFarm:delete()
    self._pointManager:delete()
end

function ChallengeFarm:onUpdate(dt)
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