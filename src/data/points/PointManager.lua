
---@class PointManager
PointManager = CpObject()
function PointManager:init()
    ---@type PointCategory[]
    self._categoryies = {}
end

function PointManager:delete()
    
end

---@return number
function PointManager:getTotalPoints()
    local value = 0
    for _, category in ipairs(self._categoryies) do
        for _, p in ipairs(category:getPoints()) do
            value = value + p:getValue()
        end
    end
    return value
end

function PointManager:calculatePoints(supressValueChange)
    for _, category in ipairs(self._categoryies) do
        for _, p in ipairs(category:getPoints()) do
            p:calculate(supressValueChange)
        end
    end
end

function PointManager:onWriteStream(streamId, connection)
    for _, c in ipairs(self._categoryies) do 
        c:onWriteStream(streamId, connection)
    end
end

function PointManager:onReadStream(streamId, connection)
    for _, c in ipairs(self._categoryies) do 
        c:onReadStream(streamId, connection)
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
    for ix, c in ipairs(self._categoryies) do 
        c:onSaveToXML(xmlFile, baseKey .. ".", ix)
    end
end

function PointManager:onLoadFromXML(xmlFile, baseKey)
    baseKey = baseKey .. "PointManager"
    for _, c in ipairs(self._categoryies) do 
        c:onLoadFromXML(xmlFile, baseKey .. ".")
    end
end
---------------------------------------------------
--- Farm Overview GUI
---------------------------------------------------

function PointManager:getNumberOfSections()
	return #self._categoryies
end

function PointManager:getTitleForSectionHeader(section)
	return self._categoryies[section]:getName()
end


function PointManager:getNumberOfItemsInSection(section)
	return #self._categoryies[section]
end


function PointManager:populateCellForItemInSection(section, index, cell)
    local point = self._categoryies[section]:getPoints()[index]

    cell:getAttribute("title"):setText(tostring(point:getName()))
    cell:getAttribute("value"):setText(tostring(point:getValue()))
end

---------------------------------------------------
--- Debug Setup
---------------------------------------------------

function PointManager.addTestPoints()
    
end