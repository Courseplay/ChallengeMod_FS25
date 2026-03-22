
---@class PointManager
PointManager = CpObject()
function PointManager:init()
    ---@type PointCategory[]
    self._categories = {}
    self:setupCategories()
end

function PointManager:setupCategories()
    -- Clone categories from the global PointTypeManager
    if g_pointTypeManager and g_pointTypeManager._categories then
        for _, category in ipairs(g_pointTypeManager._categories) do
            local newCategory = PointCategory()
            newCategory._name = category._name
            for _, point in ipairs(category._points) do
                local newPoint = Point(point._type, point._name)
                newPoint._linearModifier = point._linearModifier
                table.insert(newCategory._points, newPoint)
            end
            table.insert(self._categories, newCategory)
        end
    end
end

function PointManager:delete()
    
end

---@return number
function PointManager:getTotalPoints()
    local value = 0
    for _, category in ipairs(self._categories) do
        for _, p in ipairs(category:getPoints()) do
            value = value + p:getValue()
        end
    end
    return value
end

function PointManager:calculatePoints(suppressValueChange)
    for _, category in ipairs(self._categories) do
        for _, p in ipairs(category:getPoints()) do
            p:calculate(suppressValueChange)
        end
    end
end

function PointManager:onWriteStream(streamId, connection)
    local totalPoints = self:getTotalPoints()
    streamWriteInt32(streamId, math.floor(totalPoints))
    
    streamWriteUInt8(streamId, #self._categories)
    for _, c in ipairs(self._categories) do 
        c:onWriteStream(streamId, connection)
    end
end

function PointManager:onReadStream(streamId, connection)
    local totalPoints = streamReadInt32(streamId)
    
    local categoryCount = streamReadUInt8(streamId)
    for i = 1, categoryCount do
        if self._categories[i] then
            self._categories[i]:onReadStream(streamId, connection)
        end
    end
end

function PointManager.registerXmlSchema(xmlSchema, baseKey)
    baseKey = baseKey .. "PointManager"
    xmlSchema:register(XMLValueType.STRING, baseKey .. "Point(?)#name", 
		"Point name", nil, true)
    xmlSchema:register(XMLValueType.FLOAT, baseKey .. "Point(?)#value", 
		"Point value", nil, true)
end

function PointManager:onSaveToXML(xmlFile, baseKey)
    baseKey = baseKey .. "PointManager"
    for ix, c in ipairs(self._categories) do 
        c:onSaveToXML(xmlFile, baseKey .. ".", ix)
    end
end

function PointManager:onLoadFromXML(xmlFile, baseKey)
    baseKey = baseKey .. "PointManager"
    for _, c in ipairs(self._categories) do 
        c:onLoadFromXML(xmlFile, baseKey .. ".")
    end
end
---------------------------------------------------
--- Farm Overview GUI
---------------------------------------------------

function PointManager:getNumberOfSections()
	return #self._categories
end

function PointManager:getTitleForSectionHeader(section)
	return self._categories[section]:getName()
end


function PointManager:getNumberOfItemsInSection(section)
	return #self._categories[section]
end


function PointManager:populateCellForItemInSection(section, index, cell)
    local point = self._categories[section]:getPoints()[index]

    cell:getAttribute("title"):setText(tostring(point:getName()))
    cell:getAttribute("value"):setText(tostring(point:getValue()))
end

---------------------------------------------------
--- Debug Setup
---------------------------------------------------

function PointManager.addTestPoints()
    
end