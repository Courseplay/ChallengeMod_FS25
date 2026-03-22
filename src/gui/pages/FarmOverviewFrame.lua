
#[[
	Challenge Mode Farm Overview Frame
	Displays point statistics, logs, and farm data similar to financial overview
]]#
---@class FarmOverviewFrame
FarmOverviewFrame = {}

FarmOverviewFrame = {
	CATEGORIES = {
		POINTS = 1,
		LOGS = 2
	},
	CATEGORY_TEXTS = {
		"ui_challengemod_points",
		"ui_challengemod_logs"
	},
	
	-- TabList Columns for Points
	COLUMN_POINTS = {
		NAME = 1,
		VALUE = 2,
		SESSION = 3
	}
}
FarmOverviewFrame.NUM_CATEGORIES = #FarmOverviewFrame.CATEGORY_TEXTS

local FarmOverviewFrame_mt = Class(FarmOverviewFrame, TabbedMenuFrameElement)

function FarmOverviewFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or FarmOverviewFrame_mt)
	
	self.pointsList = nil
	self.logsList = nil
	self.playerFarm = nil
	self.logger = Logger("FarmOverviewFrame")
	
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
	local frame = FarmOverviewFrame.new()
	g_gui:loadGui(Utils.getFilename("config/gui/pages/FarmOverviewFrame.xml", 
		g_challengeMod.BASE_DIRECTORY), "FarmOverviewFrame", frame, true)
end

function FarmOverviewFrame:onGuiSetupFinished()
	FarmOverviewFrame:superClass().onGuiSetupFinished(self)
	
	-- Setup pointsList
	self.pointsData = {}
	if self.pointsList ~= nil then
		self.pointsList:setDataSource(self.pointsData)
		self.pointsList:reloadData()
	end
	
	-- Setup logsList
	self.logsData = {}
	if self.logsList ~= nil then
		self.logsList:setDataSource(self.logsData)
		self.logsList:reloadData()
	end
end

function FarmOverviewFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm
	self:updateLists()
end

function FarmOverviewFrame:updateLists()
	if not self.playerFarm then
		return
	end
	
	-- Update points data
	self.pointsData = {}
	if self.playerFarm:getPointManager then
		local pointManager = self.playerFarm:getPointManager()
		for _, category in ipairs(pointManager._categories) do
			for _, point in ipairs(category:getPoints()) do
				local item = {
					columns = {}
				}
				item.columns[self.COLUMN_POINTS.NAME] = {
					text = point:getName(),
					value = point:getName()
				}
				item.columns[self.COLUMN_POINTS.VALUE] = {
					text = string.format("%.0f", point:getValue()),
					value = point:getValue()
				}
				item.columns[self.COLUMN_POINTS.SESSION] = {
					text = tostring(math.floor(point._value)),
					value = point._value
				}
				table.insert(self.pointsData, item)
			end
		end
	end
	
	if self.pointsList ~= nil then
		self.pointsList:reloadData()
	end
	
	-- Update logs data
	self.logsData = {}
	if self.playerFarm:getChangeLog then
		local logs = self.playerFarm:getChangeLogEntries(20)
		for _, entry in ipairs(logs) do
			local item = {
				columns = {}
			}
			item.columns[1] = {
				text = entry:getTimeString(),
				value = entry:getTimestamp()
			}
			item.columns[2] = {
				text = entry:getPointType(),
				value = entry:getPointType()
			}
			item.columns[3] = {
				text = string.format("%+d", entry:getPointsDelta()),
				value = entry:getPointsDelta()
			}
			item.columns[4] = {
				text = entry:getReason(),
				value = entry:getReason()
			}
			item.columns[5] = {
				text = entry:getAdminName(),
				value = entry:getAdminName()
			}
			table.insert(self.logsData, item)
		end
	end
	
	if self.logsList ~= nil then
		self.logsList:reloadData()
	end
end

function FarmOverviewFrame:onFrameOpen()
	FarmOverviewFrame:superClass().onFrameOpen(self)
	
	-- Get current player's farm
	if g_currentMission and g_currentMission.player then
		local farm = g_farmManager:getFarmByUserId(g_currentMission.player.farmId)
		if farm and g_challengeFarmManager then
			local challengeFarm = g_challengeFarmManager:getFarm(farm.farmId)
			self:setPlayerFarm(challengeFarm)
		end
	end
end

function FarmOverviewFrame:onClickListItem(list, section, index)
	-- Handle list item click if needed
end

function FarmOverviewFrame.registerXmlSchema(xmlSchema, xmlKey)
	-- Register list schemas if needed
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