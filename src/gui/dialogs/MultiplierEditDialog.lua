---@class MultiplierEditDialog
MultiplierEditDialog = CpObject()

function MultiplierEditDialog:init(multiplierName, multiplier, onConfirm, onCancel)
    self.multiplierName = multiplierName
    self.multiplier = multiplier or {value = 1, points = 1, mode = "round"}
    self.onConfirmCallback = onConfirm
    self.onCancelCallback = onCancel
    
    self.isOpen = false
    self.currentValue = tostring(self.multiplier.value)
    self.currentPoints = tostring(self.multiplier.points)
    self.currentMode = self.multiplier.mode or "round"
    
    self.logger = Logger("MultiplierEditDialog")
end

function MultiplierEditDialog:delete()
    self.onConfirmCallback = nil
    self.onCancelCallback = nil
end

function MultiplierEditDialog:open()
    self.isOpen = true
    self.currentValue = tostring(self.multiplier.value)
    self.currentPoints = tostring(self.multiplier.points)
    self.currentMode = self.multiplier.mode or "round"
    self.logger:debug("Dialog opened for %s", self.multiplierName)
end

function MultiplierEditDialog:close()
    self.isOpen = false
    self.logger:debug("Dialog closed")
end

---Update value field (only numeric input)
---@param input string
function MultiplierEditDialog:updateValue(input)
    -- Only accept numeric input
    local numValue = tonumber(input)
    if numValue and numValue > 0 then
        self.currentValue = tostring(numValue)
    end
end

---Update points field (only numeric input)
---@param input string
function MultiplierEditDialog:updatePoints(input)
    -- Accept negative and positive numeric input
    local numValue = tonumber(input)
    if numValue then
        self.currentPoints = tostring(numValue)
    end
end

---Set rounding mode
---@param mode string "round", "floor", "ceil"
function MultiplierEditDialog:setMode(mode)
    if mode == "round" or mode == "floor" or mode == "ceil" then
        self.currentMode = mode
    end
end

---Confirm and apply changes
function MultiplierEditDialog:confirm()
    local value = tonumber(self.currentValue) or self.multiplier.value
    local points = tonumber(self.currentPoints) or self.multiplier.points
    
    if value <= 0 then
        self.logger:warning("Value must be greater than 0")
        return false
    end
    
    self.logger:info("Confirmed: %s = %d points (mode: %s)", self.multiplierName, value, points, self.currentMode)
    
    if self.onConfirmCallback then
        self.onConfirmCallback(self.multiplierName, value, points, self.currentMode)
    end
    
    self:close()
    return true
end

---Cancel and discard changes
function MultiplierEditDialog:cancel()
    self.logger:debug("Dialog cancelled, changes discarded")
    
    if self.onCancelCallback then
        self.onCancelCallback()
    end
    
    self:close()
end

---Get formatted display string
---@return string
function MultiplierEditDialog:getDisplayString()
    return string.format("%s: %s = %s points (%s)",
        self.multiplierName, self.currentValue, self.currentPoints, self.currentMode)
end

---Get all current values as table
---@return table
function MultiplierEditDialog:getValues()
    return {
        name = self.multiplierName,
        value = tonumber(self.currentValue) or self.multiplier.value,
        points = tonumber(self.currentPoints) or self.multiplier.points,
        mode = self.currentMode
    }
end
