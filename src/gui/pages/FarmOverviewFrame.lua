

--[[
	This frame is a page for the course manager.
]]--
---@class FarmOverview
---@field leftList table
---@field rightList table
FarmOverviewFrame = {}

FarmOverviewFrame = {
	CATEGRORIES = {
		POINT_OVERVIEW = 1,
		SETTINGS = 2
	},
	CATEGRORY_TEXTS = {
		"points",
		"settings"
	}
}
FarmOverviewFrame.NUM_CATEGORIES = #FarmOverviewFrame.CATEGRORY_TEXTS

local FarmOverviewFrame_mt = Class(FarmOverviewFrame, TabbedMenuFrameElement)

function FarmOverviewFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or FarmOverviewFrame_mt)

	return self
end

function FarmOverviewFrame.createFromExistingGui(gui, guiName)
	local newGui = FarmOverviewFrame.new(nil, nil)

	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)

	return newGui
end

function FarmOverviewFrame.setupGui()
	local courseManagerFrame = FarmOverviewFrame.new()
	g_gui:loadGui(Utils.getFilename("config/gui/pages/FarmOverviewFrame.xml", 
		g_challengeMod.BASE_DIRECTORY), "FarmOverviewFrame", courseManagerFrame, true)
end

function FarmOverviewFrame.registerXmlSchema(xmlSchema, xmlKey)
	
end

---@param farmManager ChallengeFarmManager
function FarmOverviewFrame:setData(farmManager)
	self.farmManager = farmManager
end

function FarmOverviewFrame:loadFromXMLFile(xmlFile, baseKey)
   
end

function FarmOverviewFrame:saveToXMLFile(xmlFile, baseKey)
   
end
function FarmOverviewFrame:getCurrentEntry()
	local layout = FocusManager:getFocusedElement()
	if not layout then 
		return
	end
	if layout.getSelectedElement then
		local element = layout:getSelectedElement()
		return element and element.viewEntry
	end
end

function FarmOverviewFrame:initialize(menu)	
	self.menu = menu
	---@type Logger
	self.logger = Logger("FarmOverview")

	self.leftList:setDataSource(self)
	self.rightList:setDataSource(self)
end
function FarmOverviewFrame:onFrameOpen()
	self:superClass().onFrameOpen(self)
	-- self.curMode = self.minMode
	-- self.actionState = self.actionStates.disabled
	self.selectedEntry = nil
	self:setSoundSuppressed(true)
	FocusManager:loadElementFromCustomValues(self.leftList)
	FocusManager:loadElementFromCustomValues(self.rightList)
	FocusManager:linkElements(self.leftList, FocusManager.RIGHT, self.rightList)
	FocusManager:linkElements(self.rightList, FocusManager.LEFT, self.leftList)
	self:updateLists()
	FocusManager:setFocus(self.leftList)
	self:setSoundSuppressed(false)
	self.initialized = true
end
	
function FarmOverviewFrame:onFrameClose()
	self:superClass().onFrameClose(self)
	if self.moveElementSelected then
		self.moveElementSelected.element:setAlternating(false)
	end
	self.initialized = false
end

function FarmOverviewFrame:updateLists()
	self.leftColumnHeader:setText("...")
	self.leftList:reloadData()
	self.rightList:reloadData()
	self:updateMenuButtons()
end

function FarmOverviewFrame:getNumberOfSections(list)
	if list == self.leftList then
		return 1
	end
	local ix = self.leftList:getSelectedIndexInSection()
	local farm = self.farmManager:getActiveFarmByIndex(ix)
	return farm and farm:getPointManager():getNumberOfSections() or 0
end

function FarmOverviewFrame:getTitleForSectionHeader(list, section)
	if list == self.leftList then
		return ""
	end
	local ix = self.leftList:getSelectedIndexInSection()
	local farm = self.farmManager:getActiveFarmByIndex(ix)
	return farm and farm:getPointManager():getTitleForSectionHeader(section) or ""
end


function FarmOverviewFrame:getNumberOfItemsInSection(list, section)
	local numFarms = self.farmManager:getNumActiveFarms()
	if list == self.leftList then
		return numFarms
	else
		if numFarms <=0 then 
			return 0
		end
		local ix = self.leftList:getSelectedIndexInSection()
		local farm = self.farmManager:getActiveFarmByIndex(ix)
		assert(farm)
		return farm:getPointManager():getNumberOfItemsInSection(section)
	end
end


function FarmOverviewFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.leftList then 
		local farm = self.farmManager:getActiveFarmByIndex(index)
		assert(farm)
		farm:populateCell(cell)
		return
	end

	local ix = self.leftList:getSelectedIndexInSection()
	local farm = self.farmManager:getActiveFarmByIndex(ix)
	assert(farm)
	farm:getPointManager():populateCellForItemInSection(section, index, cell)

	-- if list == self.leftList then
	-- 	local entry =  self.courseStorage:getEntryByIndex(index)
	-- 	cell.viewEntry = entry
	-- 	if entry:isDirectory() then
	-- 		self.setFolderIcon(cell:getAttribute("icon"))
	-- 	else 
	-- 		self.setCourseIcon(cell:getAttribute("icon"))
	-- 	end
	-- 	cell:getAttribute("icon"):setVisible(true)
	-- 	cell:getAttribute("title"):setText(entry and entry:getName() or "unknown: "..index)
	-- 	cell.target = self
	-- 	cell:setCallback("onClickCallback", "onClickLeftItem")
	-- else
	-- --	cell.alternateBackgroundColor =  FarmOverviewFrame.colors.move
	-- 	local ix = self.leftList:getSelectedIndexInSection()
	-- 	local entry = self.courseStorage:getSubEntryByIndex(ix, index)
	-- 	cell.viewEntry = entry
	-- 	if entry:isDirectory() then
	-- 		self.setFolderIcon(cell:getAttribute("icon"))
	-- 	else 
	-- 		self.setCourseIcon(cell:getAttribute("icon"))
	-- 	end
	-- 	cell:getAttribute("icon"):setVisible(true)

	-- 	cell:getAttribute("title"):setText(entry and entry:getName() or "unknown: "..index)
	-- 	cell.target = self
	-- 	cell:setCallback("onClickCallback", "onClickRightItem")
	-- end
end

function FarmOverviewFrame:onListSelectionChanged(list, section, index)
-- 	if list == self.leftList then 
-- 		self.rightList:reloadData()
-- --		CpUtil.debugFormat(CpUtil.DBG_HUD, "leftList -> onListSelectionChanged")
-- 	else
-- --		CpUtil.debugFormat(CpUtil.DBG_HUD, "rightList -> onListSelectionChanged")
-- 	end
-- 	self:updateMenuButtons()
end

--- Updates the button at the bottom, which depends on the current select mode.
function FarmOverviewFrame:updateMenuButtons()

end

---------------------------------------------------
--- Gui dialogs
---------------------------------------------------


function FarmOverviewFrame:showInputTextDialog(title, callbackFunc, viewEntry, defaultText)
	TextInputDialog.show(
		function (self, text, clickOk, viewEntry)
			text = CpUtil.cleanFilePath(text)
			callbackFunc(self, text, clickOk, viewEntry)
			self:updateLists()
		end,
		self, defaultText or "",  
		string.format(g_i18n:getText(title), viewEntry and viewEntry:getName()),
		g_i18n:getText(title), 50, g_i18n:getText("button_ok"), viewEntry)
end

function FarmOverviewFrame:showYesNoDialog(title, callbackFunc, viewEntry)
	YesNoDialog.show(
		function (self, clickOk, viewEntry)
			callbackFunc(self, clickOk, viewEntry)
			self:updateLists()
		end,
		self, string.format(g_i18n:getText(title), viewEntry:getName()),
		nil, nil, nil, nil,
		nil, nil, viewEntry)
end

function FarmOverviewFrame.showInfoDialog(title, viewEntry)
	InfoDialog.show(string.format(g_i18n:getText(title), viewEntry:getName()))
end