--[[
	Challenge Mode Settings Frame
	Displays and allows editing of multiplier settings
]]--

SettingsFrame = {
	CATEGORIES = {
		POINT_MULTIPLIERS = 1
	},
	CATEGORY_TEXTS = {
		"ui_challengemod_multipliers"
	},
	
	-- Multiplier Options
	MULTIPLIERS = {
		"storageLiter",
		"money",
		"loan",
		"fieldArea",
		"vehicleValue",
		"toolValue",
		"buildingValue",
		"animalCount",
		"soldFish",
	}
}
SettingsFrame.NUM_CATEGORIES = #SettingsFrame.CATEGORY_TEXTS

local SettingsFrame_mt = Class(SettingsFrame, TabbedMenuFrameElement)

function SettingsFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsFrame_mt)
	
	self.settingsList = nil
	self.settingOptions = {}
	self.logger = Logger("SettingsFrame")
	
	return self
end

function SettingsFrame.setupGui()
	local frame = SettingsFrame.new()
	g_gui:loadGui(Utils.getFilename("config/gui/pages/SettingsFrame.xml", 
		g_challengeMod.BASE_DIRECTORY),
		"SettingsFrame", frame, true)
end

function SettingsFrame.createFromExistingGui(gui, guiName)
	local newGui = SettingsFrame.new(nil, nil)

	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)

	return newGui
end

function SettingsFrame:onGuiSetupFinished()
	SettingsFrame:superClass().onGuiSetupFinished(self)
	
	self.settingOptions = {}
	self.editDialog = nil
	self.selectedMultiplierIndex = nil
	
	-- Create multiplier options
	if g_pointTypeManager then
		for _, multiplierName in ipairs(SettingsFrame.MULTIPLIERS) do
			local multiplier = g_pointTypeManager:getMultiplier(multiplierName)
			if multiplier then
				local option = self:createMultiplierOption(multiplierName, multiplier)
				if option then
					table.insert(self.settingOptions, option)
				end
			end
		end
	end
	
	-- Add options to list or container
	if self.settingsList then
		self.settingsList:setDataSource(self.settingOptions)
		self.settingsList:reloadData()
	end
end

function SettingsFrame:createMultiplierOption(multiplierName, multiplier)
	local option = {
		name = multiplierName,
		value = multiplier.value,
		points = multiplier.points,
		mode = multiplier.mode or "round"
	}
	return option
end

function SettingsFrame:onFrameOpen()
	SettingsFrame:superClass().onFrameOpen(self)
	
	-- Check if player is admin or host
	local isAdmin = false
	if g_adminManager then
		isAdmin = g_adminManager:isAdminActive()
	end
	
	if g_currentMission and g_currentMission.player then
		isAdmin = isAdmin or (g_currentMission.player.farmId == 1)
	end
	
	if not isAdmin then
		self.logger:warning("Player is not admin, hiding multiplier settings")
		-- Disable editing if not admin
		if self.settingsList then
			self.settingsList:setDisabled(true)
		end
	end
end

function SettingsFrame:updateMultiplier(multiplierName, value, points, mode)
	if g_pointTypeManager then
		g_pointTypeManager:setMultiplier(multiplierName, value, points, mode)
		self.logger:info("Updated multiplier %s: %d = %d points", multiplierName, value, points)
		
		-- Broadcast to other players (network sync)
		if g_server then
			self:updateMultiplierNetwork(multiplierName, value, points, mode)
		end
	end
end

function SettingsFrame:updateMultiplierNetwork(multiplierName, value, points, mode)
	-- Send multiplier update to all clients via network
	-- This will be used for multiplayer synchronization
	if g_server ~= nil and g_currentMission:getFarmById(1) then
		g_server:broadcastEvent(MultiplierUpdateEvent.new(multiplierName, value, points, mode))
	end
end

function SettingsFrame:onClickListItem(list, section, index)
	if not g_adminManager or not g_adminManager:isAdminActive() then
		self.logger:warning("Only admin can edit multipliers")
		return
	end
	
	local item = self.settingOptions[index]
	if item then
		self:openMultiplierEditDialog(item, index)
	end
end

function SettingsFrame:openMultiplierEditDialog(multiplierOption, index)
	self.selectedMultiplierIndex = index
	
	local multiplier = g_pointTypeManager:getMultiplier(multiplierOption.name)
	if not multiplier then
		return
	end
	
	-- Create dialog
	self.editDialog = MultiplierEditDialog(
		multiplierOption.name,
		multiplier,
		function(name, value, points, mode)
			self:updateMultiplier(name, value, points, mode)
		end,
		function()
			self.logger:debug("Edit dialog cancelled")
		end
	)
	
	self.editDialog:open()
	
	-- In a real implementation, this would show a dialog UI
	-- For now, we'll just log it and call confirm with dummy values
	-- In the actual GUI, this would be a text input dialog
	self.logger:info("Multiplier edit dialog opened for: %s", multiplierOption.name)
end

function SettingsFrame.registerXmlSchema(xmlSchema, xmlKey)
	-- Register schemas for settings if needed
end
   
end

function SettingsFrame:initialize(menu)
	self.cpMenu = menu
	self.booleanPrefab:unlinkElement()
	FocusManager:removeElement(self.booleanPrefab)
	self.multiTextPrefab:unlinkElement()
	FocusManager:removeElement(self.multiTextPrefab)
	self.sectionHeaderPrefab:unlinkElement()
	FocusManager:removeElement(self.sectionHeaderPrefab)
	self.selectorPrefab:unlinkElement()
	FocusManager:removeElement(self.selectorPrefab)
	self.containerPrefab:unlinkElement()
	FocusManager:removeElement(self.containerPrefab)

	for key = 1, SettingsFrame.NUM_CATEGORIES do 
		self.subCategoryPaging:addText(tostring(key))
		self.subCategoryPages[key] = self.containerPrefab:clone(self)
		self.subCategoryPages[key]:getDescendantByName("layout").scrollDirection = "vertical"
		FocusManager:loadElementFromCustomValues(self.subCategoryPages[key])
		self.subCategoryTabs[key] = self.selectorPrefab:clone(self.subCategoryBox)
		FocusManager:loadElementFromCustomValues(self.subCategoryTabs[key])

		self.subCategoryTabs[key]:setText(g_i18n:getText(self.CATEGRORY_TEXTS[key]))
		self.subCategoryTabs[key]:getDescendantByName("background"):setSize(
			self.subCategoryTabs[key].size[1], self.subCategoryTabs[key].size[2])
		self.subCategoryTabs[key].onClickCallback = function ()
			self:updateSubCategoryPages(key)
		end
	end
	self.subCategoryBox:invalidateLayout()
	self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)
end


function SettingsFrame:delete()
	self.booleanPrefab:delete()
	self.multiTextPrefab:delete()
	self.sectionHeaderPrefab:delete()
	self.selectorPrefab:delete()
	self.containerPrefab:delete()
	SettingsFrame:superClass().delete(self)
end

function SettingsFrame:onFrameOpen()
	SettingsFrame:superClass().onFrameOpen(self)

end

function SettingsFrame:onClickCpMultiTextOption(_, guiElement)
	
end

function SettingsFrame:updateSubCategoryPages(state)
	for i, _ in ipairs(self.subCategoryPages) do
		self.subCategoryPages[i]:setVisible(false)
		self.subCategoryTabs[i]:setSelected(false)
	end
	self.subCategoryPages[state]:setVisible(true)
	self.subCategoryTabs[state]:setSelected(true)
	self.settingsSlider:setDataElement(self.subCategoryPages[state]:getDescendantByName("layout"))
end
