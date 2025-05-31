
---@class PointType
PointType = CpObject()
PointType.XML_KEY = "Type"
function PointType:init()
    self._name = ""
    self._composeFunc = nil
    self._calculateFunc = nil
end

function PointType:getName()
    return self._name
end

function PointType:calculate(index)
    assert(self._calculateFunc ~= nil)
    return g_pointTypeManager:raiseCallback(index)
end

function PointType:compose()
    if self._composeFunc ~= nil then 
        return g_pointTypeManager:raiseCallback(self._composeFunc)
    end
    return {Point(self)}
end

function PointType.registerXmlSchema(xmlSchema, baseKey)
    local key = baseKey .. PointType.XML_KEY .. "(?)"
    xmlSchema:register(XMLValueType.STRING, key .. "#name", "Type name")
    xmlSchema:register(XMLValueType.STRING, key .. "#composeFunc", "Compose func")
    xmlSchema:register(XMLValueType.STRING, key .. "#calculateFunc", "Calculate func")
end

function PointType:loadFromXMLFile(xmlFile, baseKey)
    self._name = xmlFile:getValue(baseKey .. "#name")
    self._composeFunc = xmlFile:getValue(baseKey .. "#composeFunc")
    self._calculateFunc = xmlFile:getValue(baseKey .. "#calculateFunc")
end

---@class PointCategory
PointCategory = CpObject()
PointCategory.XML_KEY = "Category"
function PointCategory:init()
    self._name = ""
    ---@type Point[]
    self._points = {}
end

function PointCategory:getName()
    return self._name
end

function PointCategory:getPoints()
    return self._points
end

function PointCategory.registerXmlSchema(xmlSchema, baseKey)
    local key = baseKey .. PointCategory.XML_KEY .. "(?)"
    xmlSchema:register(XMLValueType.STRING, key .. "#name", "Category name")
    PointType.registerXmlSchema(xmlSchema, key .. ".")
end

function PointCategory:loadFromXMLFile(xmlFile, baseKey)
    self._name = xmlFile:getValue(baseKey .. "#name")
    xmlFile:iterate(baseKey .. ".Type", function(_, key)
        ---@type PointType
        local type = PointType()
        type:loadFromXMLFile(xmlFile, key)
        for _, point in ipairs(type:compose()) do 
            table.insert(self._points, point)
        end
    end)
end