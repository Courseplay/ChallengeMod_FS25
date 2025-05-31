---@class ChUtil
ChUtil = {}

--- Executes a function and throws a callstack, when an error appeared.
--- Additionally the first return value is a status, if the function was executed correctly.
---@param func function function to be executed.
---@param ... any parameters for the function, for class function the first parameter needs to be self.
---@return boolean was the code execution successfully and no error appeared.
---@return any returnValues if the code was successfully run, then all return values will be normally returned, else only a error message is returned.
function ChUtil.try(func, ...)
	local data = {xpcall(func, function(err) printCallstack(); return err end, ...)}
	local status = data[1]
	if not status then
		print(data[2])
		return status, tostring(data[2])
	end
	return unpack(data)
end

--- (Safely) get the name of a vehicle or implement.
---@param object table vehicle or implement
function ChUtil.getName(object)
	if object == nil then 
		return 'Unknown'
	end
	if object == ChUtil then
		return 'ERROR, calling ChUtil.getName with : !'
	end
	local helperName = '-'
	if object == object.rootVehicle then
		helperName = object.id
	end
	return object.getName and object:getName() .. '/' .. helperName or 'Unknown'
end
