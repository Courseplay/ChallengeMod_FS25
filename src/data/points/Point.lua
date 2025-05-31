---@class Point
Point = CpObject()
function Point:init(type)
    self._value = 0
    self._name = ""
    self._linearModifier = 1
    ---@type PointType|nil
    self._type = type
    self._typeIndex = 0
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
    local value = self._type:calculate()
    if value ~= self._value and 
        not supressValueChange then 

        -- g_messageCenter:publish()
    end
    self._value = value
end