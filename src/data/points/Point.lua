---@class Point
Point = CpObject()
function Point:init(type)
    self._value = 0
    self._name = ""
    self._linearModifier = 1
    ---@type PointType|nil
    self._type = type
    self._typeIndex = 0
    self._isDirty = false
end

function Point:getName()
    return self._name
end

function Point:getValue()
    return self._value * self._linearModifier
end

function Point:getModifier()
    return self._linearModifier
end

function Point:calculate(supressValueChange)
    assert(self._type)
    self._lastValue = self._value
    local value = self._type:calculate()
    if value ~= self._value and 
        not supressValueChange then 

        -- g_messageCenter:publish()
    end
    self._value = value
    self._isDirty = self._isDirty and self._value ~= self._lastValue
end

function Point:onWriteStream(streamId, connection)
    streamWriteFloat32(streamId, self._value)
end

function Point:onReadStream(streamId, connection)
    self._value = streamReadFloat32(streamId)
end

function Point.registerXmlSchema(xmlSchema, baseKey)
    xmlSchema:register(XMLValueType.STRING, baseKey .. "Point(?)#name", 
		"Point name", nil, true)
    xmlSchema:register(XMLValueType.FLOAT, baseKey .. "Point(?)#value", 
		"Point value", nil, true)
end

function Point:onSaveToXML(xmlFile, baseKey)
    xmlFile:setValue(baseKey .. "#name", self._name)
    xmlFile:setValue(baseKey .. "#value", self._value)
end

function Point:onLoadFromXML(xmlFile, baseKey)
    self._value = xmlFile:getValue(baseKey .. "#value", 0)
end