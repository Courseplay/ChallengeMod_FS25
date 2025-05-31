
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
    self._type = ChallengeFarmType.DISABLED
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
    cell:getAttribute("title"):setText(tostring(self._farmId)) 
end

---@return boolean
function ChallengeFarm:getIsActiveFarm()
    return self._type == ChallengeFarmType.NORMAL
end

---@return PointManager
function ChallengeFarm:getPointManager()
    return self._pointManager
end