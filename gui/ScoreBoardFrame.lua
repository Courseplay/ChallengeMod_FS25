ScoreBoardFrame = {
	CONTROLS = {
		HEADER = "header",
		HEADER_DURATION = "headerDuration",
		MAIN_BOC = "mainBox",
		LEFT_COLUMN = "leftColumn",
		RIGHT_COLUMN = "rightColumn",
		CHANGELOG_COLUMN = "changelogColumn",
		LEFT_LIST = "leftList",
		RIGHT_LIST = "rightList",
		CHANGELOG_LIST = "changelogList",
		LEFT_COLUMN_HEADER = "leftColumnHeader",
		RIGHT_COLUMN_HEADER = "rightColumnHeader",
		GOAL = "goal",
		RIGHT_LIST_MIDDLE_TITLE = "rightList_middleTitle",
		RIGHT_LIST_RIGHT_TITLE = "rightList_rightTitle",
		CHANGELOG_LEFT_TITLE = "changelogList_leftTitle",
		CHANGELOG_MIDDLE_TITLE = "changelogList_middleTitle",
		CHANGELOG_RIGHT_TITLE = "changelogList_rightTitle"
	},
	COLOR = {
		GREEN = {
			0, 1, 0, 1
		},
		WHITE = {
			1, 1, 1, 1
		}
	},
	LEFT_SECTIONS = {
		POINTS = 1,
		SETTINGS = 2
	},
	NUM_SETTINGS = 1,
	NUM_SETTINGS_ADMIN = 2,
	NUM_LEFT_SECTIONS = 2
}

ScoreBoardFrame.translations = {
	goal = function(goal) return string.format(g_i18n:getText("CM_rightList_leftTitle"), goal) end,
	headerDuration = function (timePassed, duration) return string.format(g_i18n:getText("CM_title_duration"), timePassed, duration) end,

	ruleTitle = g_i18n:getText("CM_leftList_ruleTitle"),
	adminPointsTitle = g_i18n:getText("CM_leftList_adminPointsTitle"),
	menuButtons = {
		adminLogin = g_i18n:getText("CM_menuBtn_admin_login"),
		adminLogout = g_i18n:getText("CM_menuBtn_admin_logout"),
		adminChangePassword = g_i18n:getText("CM_menuBtn_admin_changePassword"),
		change = g_i18n:getText("CM_menuBtn_change"),
		changeFarmVisibility = g_i18n:getText("CM_menuBtn_changeFarmVisibility"),
		showChangelog = g_i18n:getText("CM_menuBtn_showChangelog"),
		hideChangelog = g_i18n:getText("CM_menuBtn_hideChangelog"),
		addPoints = g_i18n:getText("CM_menuBtn_addPoints")
	},
	dialogs = {
		admin = g_i18n:getText("CM_dialog_adminTitle"),
		adminChangePassword = g_i18n:getText("CM_dialog_adminChangePasswordTitle"),
		adminWrongPassword = g_i18n:getText("CM_dialog_adminWrongPassword"),
		value = g_i18n:getText("CM_dialog_changeTitle"),
		newGoal = g_i18n:getText("CM_dialog_newGoal"),
		newDuration = g_i18n:getText("CM_dialog_newDuration"),
		dataDeleted = g_i18n:getText("CM_dialog_dataDeleted"),
		spyOnOtherTeams = g_i18n:getText("CM_dialog_spyOnOtherTeams"),
		errors = {
			missingReason = g_i18n:getText("CM_dialog_addPoints_error_missingReason"),
			zeroPoints = g_i18n:getText("CM_dialog_addPoints_error_zeroPoints"),
			notANumber = g_i18n:getText("CM_dialog_addPoints_error_notANumber"),
			invalidGoal = g_i18n:getText("CM_dialog_setGoal_error_invalidGoal"),
			invalidDuration = g_i18n:getText("CM_dialog_setDuration_error_invalidDuration")
		}
	},
	leftSections = {
		"",
		g_i18n:getText("CM_leftList_section_two"),
	},
	changelogSections = {
		""
	}
}

ScoreBoardFrame.refreshRate = 1000

local ScoreBoardFrame_mt = Class(ScoreBoardFrame, TabbedMenuFrameElement)
---@class ScoreBoardFrame
---@field private rightList SmoothListElement
---@field private leftList SmoothListElement
function ScoreBoardFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or ScoreBoardFrame_mt)
	-- self:registerControls(ScoreBoardFrame.CONTROLS)
	self.farmManager = g_farmManager
	self.challengeMod = g_challengeMod
	self.victoryPointManager = g_victoryPointManager
	self.ruleManager = g_ruleManager
	self.farms = {}
	self.showChangelog = false
	self.selectedList = self.leftList
	
	return self
end

function ScoreBoardFrame:onGuiSetupFinished()
	ScoreBoardFrame:superClass().onGuiSetupFinished(self)

	self.leftList:setDataSource(self)
	self.rightList:setDataSource(self)
	self.changelogList:setDataSource(self)

	-- Save the current selected list to decide which buttons will be shown and which not
	local orig = self.leftList.onFocusEnter
	function self.leftList.onFocusEnter(...)
		orig(...)

		self:onFocusEnterList(self.leftList)
	end

	orig = self.rightList.onFocusEnter
	function self.rightList.onFocusEnter(...)
		orig(...)

		self:onFocusEnterList(self.rightList)
	end

	orig = self.changelogList.onFocusEnter
	function self.changelogList.onFocusEnter(...)
		orig(...)

		self:onFocusEnterList(self.changelogList)
	end

	self.menuButtons = {
		{
			inputAction = InputAction.MENU_BACK,
		},
		--- Login as admin button.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_ACCEPT,
			text = self.translations.menuButtons.adminLogin,
			callback = function()
				self:onClickAdminLogin()
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackEnabled = self.isAdminLogoutButtonDisabled,
		},
		--- Logout admin button.
		{
			profile = "buttonSelect",
			inputAction = InputAction.MENU_ACCEPT,
			text = self.translations.menuButtons.adminLogout,
			callback = function()
				self:onClickAdminLogout()
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackEnabled = self.isAdminLoginButtonDisabled,
		},
		--- Change admin password.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_EXTRA_2,
			text = self.translations.menuButtons.adminChangePassword,
			callback = function()
				self:onClickAdminChangePassword()
				self:updateMenuButtons()
			end,
			callbackEnabled = self.isAdminChangePasswordButtonEnabled,
		},
		--- Changes a value button.
		{
			profile = "buttonSelect",
			inputAction = InputAction.MENU_ACTIVATE,
			text = self.translations.menuButtons.change,
			callback = function()
				CmUtil.try(self.onClickChange, self)
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackEnabled = self.isChangeButtonEnabled,
		},
		--- Shows dialog to add points to selected farm
		{
			profile = "buttonSelect",
			inputAction = InputAction.MENU_ACTIVATE,
			text = self.translations.menuButtons.addPoints,
			callback = function()
				CmUtil.try(self.onClickAddPoints, self)
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackEnabled = self.isAddPointsButtonEnabled,
		},
		--- Changes farm visibility.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_EXTRA_1,
			text = self.translations.menuButtons.changeFarmVisibility,
			callback = function()
				self:onClickChangeFarmVisibility()
				self:updateMenuButtons()
			end,
			callbackEnabled = self.isAddPointsButtonEnabled,
		},
		--- Show all point changes for the selected farm.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_CANCEL,
			text = self.translations.menuButtons.showChangelog,
			callback = function ()
				self:onClickShowChangelog()
				self:updateMenuButtons()
			end,
			callbackEnabled = self.isShowChangelogButtonEnabled
		},
		--- Hide point changes for selected farm
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_CANCEL,
			text = self.translations.menuButtons.hideChangelog,
			callback = function ()
				self:onClickHideChangelog()
				self:updateMenuButtons()
			end,
			callbackEnabled = self.isHideChangelogButtonEnabled
		}
	}
	self.managers = {
		function(...)
			return self.victoryPointManager:getList(...)
		end,
		function(...)
			local sx, ix = self.leftList:getSelectedPath()
			return ix == 1 and self.ruleManager:getList() or self.victoryPointManager:getList()
		end,
	}

	self.numSections = {
		[self.leftList] = function() return self.NUM_LEFT_SECTIONS end,
		[self.rightList] = function()
			local sx, ix = self.leftList:getSelectedPath()
			return self.managers[sx]():getNumberOfElements()
		end,
		[self.changelogList] = function ()
			return 1
		end
	}
	self.sectionTitles = {
		[self.leftList] = function(sx)
			return self.translations.leftSections[sx]
		end,
		[self.rightList] = function(rsx)
			local sx, ix = self.leftList:getSelectedPath()
			return self.managers[sx]():getElement(rsx):getTitle()
		end,
		[self.changelogList] = function (sx)
			return self.translations.changelogSections[sx]
		end
	}
end

function ScoreBoardFrame:onFrameOpen()
	self:updateFrame()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.leftList)
	self:setSoundSuppressed(false)
	ScoreBoardFrame:superClass().onFrameOpen(self)
	self.timerRefresh = 0
	g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChanged, self)
end

function ScoreBoardFrame:onFrameClose()
	ScoreBoardFrame:superClass().onFrameClose(self)

	self.showChangelog = false
	self:updateRightColumn()
	self:updateFrame()
	g_challengeMod:resetSpyingForFarm(g_currentMission.player.farmId)
	g_messageCenter:unsubscribe(MessageType.MONEY_CHANGED, self)
end

function ScoreBoardFrame:update(dt)
	ScoreBoardFrame:superClass().update(self, dt)

	self.timerRefresh = self.timerRefresh + dt

	if self.timerRefresh > self.refreshRate then
		self:updateLists()
		self.timerRefresh = 0
	end
end

function ScoreBoardFrame:updateFrame()
	self:updateLists()
	self:updateTitles()
	self:updateMenuButtons()
end

function ScoreBoardFrame:updateLists()
	self.victoryPointManager:update()
	self.farms = self:getValidFarms()
	self.leftList:reloadData()
	self.rightList:reloadData()
	self.changelogList:reloadData()
	self.goal:setText(self.translations.goal(self.victoryPointManager:getGoal()))
end

function ScoreBoardFrame:updateTitles()
	local sx, ix = self.leftList:getSelectedPath()
	local titles = self.managers[sx]():getTitles()
	self.goal:setText(self.translations.goal(self.victoryPointManager:getGoal()))
	self.headerDuration:setText(self.translations.headerDuration(g_challengeMod:getTimePassed(), g_challengeMod:getDuration()))
	self.rightList_middleTitle:setText(titles[2])
	self.rightList_rightTitle:setText(titles[3])

	self.goal.overlay.alpha = 0
	self.goal.textDisabledColor = self.goal.textColor
	self.headerDuration.overlay.alpha = 0
	self.headerDuration.textDisabledColor = self.headerDuration.textColor
	self.headerDuration:setVisible(g_challengeMod.isAdminModeActive or g_challengeMod:isTimeTracked())
end

function ScoreBoardFrame:updateMenuButtons()
	self.menuButtonInfo = {}
	for i, btn in pairs(self.menuButtons) do
		if btn.callbackEnabled == nil or btn.callbackEnabled(self) then
			table.insert(self.menuButtonInfo, btn)
		end
	end
	self:setMenuButtonInfoDirty()

	self.goal:setDisabled(not g_challengeMod.isAdminModeActive, false)
end

function ScoreBoardFrame:getNumberOfSections(list)
	return self.numSections[list]()
end

function ScoreBoardFrame:getTitleForSectionHeader(list, s)
	local text = self.sectionTitles[list](s)
	if text == "" then
		return nil
	end
	return text
end

function ScoreBoardFrame:getNumberOfItemsInSection(list, section)
	if list == self.leftList then
		if section == self.LEFT_SECTIONS.POINTS then
			return #self.farms
		else
			return g_challengeMod.isAdminModeActive and self.NUM_SETTINGS_ADMIN or self.NUM_SETTINGS
		end
	elseif list == self.rightList then
		if list:getIsVisible() then
			local farmId = self:getSelectedFarmId()
			local sx, ix = self.leftList:getSelectedPath()
			local l = self.managers[sx](farmId)

			if l == nil then
				CmUtil.debug("Categories for not found %d", section)
				printCallstack()

				return 0
			end

			return l:getNumberOfElements(section)
		else
			return 0
		end
	else
		if list:getIsVisible() then
			local farmId = self:getSelectedFarmId()
			local points = g_victoryPointManager:getAdditionalPointsForFarm(farmId) or {}

			return #points or 0
		else
			return 0
		end
	end
end

function ScoreBoardFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.leftList then
		if section == self.LEFT_SECTIONS.POINTS then
			if self.farms[index] then -- and self.farms[index].farmId == g_currentMission.player.farmId then
				if self.farms[index]:getIconUVs() ~= nil then
					cell:getAttribute("icon"):setImageUVs(nil, unpack(GuiUtils.getUVs(self.farms[index]:getIconUVs())))
				end
				if self.farms[index]:getColor() ~= nil then
					cell:getAttribute("icon"):setImageColor(nil, unpack(self.farms[index]:getColor()))
				end
				cell:getAttribute("title"):setText(self.farms[index].name)
				cell:getAttribute("value"):setText(string.format("%.1f",
					self.victoryPointManager:getTotalPoints(self.farms[index].farmId)))
				if self.victoryPointManager:isVictoryGoalReached(self.farms[index].farmId) then
					cell:getAttribute("value"):setTextColor(unpack(self.COLOR.GREEN))
				else
					cell:getAttribute("value"):setTextColor(unpack(self.COLOR.WHITE))
				end
			end
		elseif index == 1 then
			cell:getAttribute("title"):setText(self.translations.ruleTitle)
			cell:getAttribute("icon"):setVisible(false)
		else
			cell:getAttribute("title"):setText(self.translations.adminPointsTitle)
			cell:getAttribute("icon"):setVisible(false)
		end
	elseif list == self.rightList then
		if not self.showChangelog then
			local element = self:getElement(section, index)
			if element then
				cell:getAttribute("title"):setText(element:getTitle())

				local pointsText = element:getText()
				local sx, ix = self.leftList:getSelectedPath()
				local playerFarmId = g_currentMission.player.farmId
				local selectedFarmId = self:getSelectedFarmId()

				if selectedFarmId ~= playerFarmId and sx == self.LEFT_SECTIONS.POINTS and not g_challengeMod:getIsFarmAllowedToSpyFarm(playerFarmId, selectedFarmId)then
					local spyingRule = g_ruleManager:getGeneralRuleValue("spyOnOtherTeams")
					if spyingRule == 0 then
						pointsText = "X"
					elseif spyingRule == 1 then
						if not g_challengeMod:getIsFarmAllowedToSpyFarm(playerFarmId, selectedFarmId) then
							pointsText = "X"
						end
					end
				end

				cell:getAttribute("value"):setText(pointsText)

				cell:getAttribute("conversionValue"):setText(element:getFactorText())
			end
		end
	else
		local farmId = self:getSelectedFarmId()
		local points = g_victoryPointManager:getAdditionalPointsForFarm(farmId)
		local point = points[index]

		cell:getAttribute("userName"):setText(point.addedBy)
		cell:getAttribute("date"):setText(point.date)
		cell:getAttribute("addedPoints"):setText(point.points)
	end
end

function ScoreBoardFrame:onListSelectionChanged(list, section, index)
	if list == self.leftList then
		if not self.showChangelog then
			self.rightList:reloadData()
		else
			self.changelogList:reloadData()
		end
	end
	self:updateMenuButtons()
	self:updateTitles()
end

function ScoreBoardFrame:onFocusEnterList(list)
	if self.selectedList ~= nil then
		self.selectedList:clearElementSelection()
	end

	self.selectedList = list
	self:updateMenuButtons()
end

function ScoreBoardFrame:getValidFarms()
	local farms, farmsById = {}, {}
	for i, farm in pairs(self.farmManager:getFarms()) do
		if CmUtil.isValidFarm(farm.farmId, farm) then
			if g_challengeMod.isAdminModeActive or self.challengeMod:getIsFarmVisible(farm.farmId) then
				table.insert(farms, farm)
				farmsById[farm.farmId] = farm
			end
		end
	end
	table.sort(farms, function(a, b)
		return self.victoryPointManager:getTotalPoints(a.farmId) > self.victoryPointManager:getTotalPoints(b.farmId)
	end)
	return farms, farmsById
end

function ScoreBoardFrame:getSelectedFarmId()
	local sx, ix = self.leftList:getSelectedPath()
	if sx ~= self.LEFT_SECTIONS.POINTS then
		return
	end
	if sx == 1 and ix and self.farms[ix] then
		return self.farms[ix].farmId
	else
		CmUtil.debug("Current farm id not found for %s.", tostring(ix))
		printCallstack()
	end
end

function ScoreBoardFrame:getSelectedIndexByFarmId(farmId)
	for idx, farm in pairs(self.farms) do
		if farm.farmId ==farmId then
			return idx
		end
	end

	return 1
end

function ScoreBoardFrame:getElement(section, index)
	if section == nil or index == nil then
		CmUtil.debug("Index or section is nil (%s|%s).", tostring(section), tostring(index))
		printCallstack()
		return
	end
	local sx, ix = self.leftList:getSelectedPath()
	local farmId = self:getSelectedFarmId()
	local list = self.managers[sx](farmId)
	if list == nil then
		CmUtil.debug("Element not found for (%s|%s).", tostring(section), tostring(index))
		printCallstack()
		return
	end

	return list:getElement(section, index)
end

function ScoreBoardFrame:updateRightColumn()
	self.rightColumn:setVisible(not self.showChangelog)
	self.changelogColumn:setVisible(self.showChangelog)
end

----------------------------------------------------
--- Button callbacks
----------------------------------------------------

function ScoreBoardFrame:onClickAdminLogin()
	self:openPasswortDialog(self.onTextInputAdminPassword, nil, self.translations.dialogs.admin,
		self.challengeMod:getDefaultAdminPassword())
end

function ScoreBoardFrame:onClickAdminLogout()
	g_challengeMod.isAdminModeActive = false
end

function ScoreBoardFrame:onClickAdminChangePassword()
	self:openTextInputDialog(self.onTextInputChangeAdminPassword, nil, self.translations.dialogs.adminChangePassword,
		self.challengeMod:getAdminPassword())
end

function ScoreBoardFrame:onClickChangeFarmVisibility()
	local farmId = self:getSelectedFarmId()
	if farmId == nil then
		CmUtil.debug("No farm is selected!")
		return
	end
	self.challengeMod:changeFarmVisibility(farmId)
end

function ScoreBoardFrame:onClickChange()
	local sec, ix = self.rightList:getSelectedPath()
	local element = self:getElement(sec, ix)
	CmUtil.debug("ScoreBoardFrame onClickChange")
	if element then
		if element:isTextInputAllowed() then
			self:openTextInputDialog(self.onTextInputChangeValue, element, element:getInputText())
		end
		element:onClick()
		self:updateLists()
	end
end

function ScoreBoardFrame:onClickAddPoints()
	if self.selectedList ~= self.leftList or self.selectedList:getSelectedSection() ~= self.LEFT_SECTIONS.POINTS then
		Logging.error("Can't change points of no farm")
		return
	end

	local farmId = self:getSelectedFarmId()
	self:showAddPointsDialog(farmId)
end

function ScoreBoardFrame:onClickSetGoal()
	self:openTextInputDialog(self.onTextInputChangeGoal, nil, self.translations.dialogs.newGoal)
end

function ScoreBoardFrame:onClickSetDuration()
	self:openTextInputDialog(self.onTextInputChangeDuration, nil, self.translations.dialogs.newDuration)
end

function ScoreBoardFrame:onClickShowChangelog()
	self.showChangelog = true

	self:updateRightColumn()
	self:updateFrame()
end

function ScoreBoardFrame:onClickHideChangelog()
	self.showChangelog = false

	self:updateRightColumn()
	self:updateFrame()
end

function ScoreBoardFrame:onDoubleClickPoint(list, section, index, cell)
	if self.selectedList == self.changelogList then
		local farmId = self:getSelectedFarmId()
		local point = g_victoryPointManager:getAdditionalPointsForFarm(farmId)[index]

		g_gui:showInfoDialog({
			dialogType = DialogElement.TYPE_INFO,
			text = point.reason
		})
	end
end

function ScoreBoardFrame:onDoubleClickFarm(list, section, index, cell)
	if section == self.LEFT_SECTIONS.POINTS and g_challengeMod.isAdminModeActive then
		self:onClickAddPoints()
	end
end

function ScoreBoardFrame:onDoubleClickValue(list, section, index, cell)
	if g_challengeMod.isAdminModeActive then
		self:onClickChange()
	end
end

function ScoreBoardFrame:onClickLeftListCallback(list, section, index, cell)
	self.selectedList = self.leftList

	if self.leftList:getSelectedSection() ~= self.LEFT_SECTIONS.POINTS then
		self.showChangelog = false

		self:updateRightColumn()
		self:updateFrame()
	else
		local spyingCostText = g_i18n:formatMoney(g_ruleManager:getGeneralRuleValue("spyingCost"))
		local farm = g_farmManager:getFarmById(self:getSelectedFarmId()).name
		local text = string.format(ScoreBoardFrame.translations.dialogs.spyOnOtherTeams, spyingCostText, farm)
		local playerFarmId = g_currentMission.player.farmId
		local selectedFarmId = self:getSelectedFarmId()
		local spyingRule = g_ruleManager:getGeneralRuleValue("spyOnOtherTeams")

		if spyingRule == 1 and
			playerFarmId ~= 0 and
			selectedFarmId ~= playerFarmId and
			not g_challengeMod:getIsFarmAllowedToSpyFarm(playerFarmId, selectedFarmId)
		then
			g_gui:showYesNoDialog({
				text = text,
				callback = self.onPayToSpy,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		end
	end

	self:updateMenuButtons()
end

function ScoreBoardFrame:onClickRightListCallback(list, section, index, cell)
	self.selectedList = self.rightList
	self:updateMenuButtons()
end

function ScoreBoardFrame:onClickChangelogListCallback(list, section, index, cell)
	self.selectedList = self.changelogList
	self:updateMenuButtons()
end

function ScoreBoardFrame:isAdminLoginButtonDisabled()
	return g_challengeMod.isAdminModeActive
end

function ScoreBoardFrame:isAdminLogoutButtonDisabled()
	return not g_challengeMod.isAdminModeActive
end

function ScoreBoardFrame:isAdminChangePasswordButtonEnabled()
	local isMasterUser = false
	local user = g_currentMission.userManager:getUserByUserId(g_currentMission.player.userId)
	if user ~= nil then
		isMasterUser = user:getIsMasterUser()
	end
	return g_challengeMod.isAdminModeActive and isMasterUser
end

function ScoreBoardFrame:isChangeButtonEnabled()
	return g_challengeMod.isAdminModeActive and self.selectedList == self.rightList
end

function ScoreBoardFrame:isAddPointsButtonEnabled()
	return g_challengeMod.isAdminModeActive and self.selectedList == self.leftList and self.selectedList:getSelectedSection() == self.LEFT_SECTIONS.POINTS
end

function ScoreBoardFrame:isShowChangelogButtonEnabled()
	return not self.showChangelog and self.selectedList == self.leftList and self.selectedList:getSelectedSection() == self.LEFT_SECTIONS.POINTS
end

function ScoreBoardFrame:isHideChangelogButtonEnabled()
	return self.showChangelog
end

function ScoreBoardFrame:onMoneyChanged(farmId, money)
	self:updateFrame()
end

----------------------------------------------------
--- Dialogs
----------------------------------------------------

function ScoreBoardFrame:openTextInputDialog(callbackFunc, args, title, ...)
	if ... ~= nil then
		title = string.format(title, ...)
	end
	g_gui:showTextInputDialog({
		disableFilter = true,
		callback = callbackFunc,
		target = self,
		defaultText = "",
		dialogPrompt = title,
		imePrompt = title,
		maxCharacters = 50,
		confirmText = g_i18n:getText("button_ok"),
		args = args
	})
end

function ScoreBoardFrame:openPasswortDialog(callbackFunc, args, title, defaultPassword, ...)
	title = string.format(title, defaultPassword)
	if ... ~= nil then
		title = string.format(title, ...)
	end

	g_gui:showPasswordDialog({
		text = title,
		callback = callbackFunc,
		target = self,
		args = args,
		defaultPassword = defaultPassword
	})
end

function ScoreBoardFrame:showAddPointsDialog(farmId)
	local dialog = g_gui.guis.AddPointsDialog

	if dialog ~= nil then
		dialog.target:setCallback(self.onTextInputAddPoints, self, farmId)

		g_gui:showDialog("AddPointsDialog")
	end
end

function ScoreBoardFrame:onTextInputAdminPassword(text, clickOk)
	if clickOk then
		if text == self.challengeMod:getAdminPassword() then
			g_challengeMod.isAdminModeActive = true
			self:updateMenuButtons()
			self:updateLists()
		else
			g_gui:showInfoDialog({
				text = string.format(self.translations.dialogs.adminWrongPassword, text)
			})
		end
	end
end

function ScoreBoardFrame:onTextInputChangeAdminPassword(text, clickOk)
	if clickOk then
		self.challengeMod:changeAdminPassword(text)
	end
end

function ScoreBoardFrame:onTextInputChangeValue(text, clickOk, element)
	if clickOk then
		if text ~= nil and element ~= nil then
			local sx, ix = self.leftList:getSelectedPath()
			local list = self.managers[sx]()
			for _, category in pairs(list:getElements()) do
				local elementToUpdate = category:getElementByName(element:getName())
				if elementToUpdate ~= nil then
					elementToUpdate:onTextInput(text)
				end
			end
			self:updateLists()
		end
	end
end

function ScoreBoardFrame:onTextInputAddPoints(points, reason, clickOk, farmId)
	if clickOk then
		local point = CmUtil.createAdditionalPoint(points, g_currentMission.playerNickname, reason)

		g_victoryPointManager:addAdditionalPoint(farmId, point)
		self:updateLists()
	end
end

function ScoreBoardFrame:onTextInputChangeGoal(text, clickOk)
	if clickOk then
		local newGoal = tonumber(text)
		if newGoal ~= nil then
			self.victoryPointManager:setGoal(newGoal)
			self:updateFrame()
			self.goal.overlayState = GuiOverlay.STATE_NORMAL
		else
			g_gui:showInfoDialog({
				dialogType = DialogElement.TYPE_WARNING,
				text = self.translations.dialogs.errors.invalidGoal,
				callback = self.onClickSetGoal,
				target = self
			})
		end
	end
end

function ScoreBoardFrame:onTextInputChangeDuration(text, clickOk)
	if clickOk then
		local newDuration = tonumber(text)

		if newDuration == nil or newDuration < -1 then
			g_gui:showInfoDialog({
				dialogType = DialogElement.TYPE_WARNING,
				text = self.translations.dialogs.errors.invalidDuration,
				callback = self.onClickSetDuration,
				target = self
			})
		else
			if newDuration == -1 then
				g_gui:showYesNoDialog({
					text = self.translations.dialogs.dataDeleted,
					callback = function (yes)
						--if the user does not want to delete all data dont set the duration. to avoid boiler plate code we just set the new duration to the current duration so no changes are applied.
						if not yes then
							newDuration = g_challengeMod:getDuration()
						end
					end
				})

			end
			g_challengeMod:setDuration(newDuration)
			self:updateFrame()
			self.headerDuration.overlayState = GuiOverlay.STATE_NORMAL
		end
	end
end

function ScoreBoardFrame:onPayToSpy(yes)
	if yes then
		local price = g_ruleManager:getGeneralRuleValue("spyingCost")
		local playerFarmId = g_currentMission.player.farmId
		local getSelectedFarmId = self:getSelectedFarmId()
		g_challengeMod:setFarmAllowedToSpyFarm(playerFarmId, getSelectedFarmId)
		g_client:getServerConnection():sendEvent(PayToSpyEvent.new(-price, playerFarmId, getSelectedFarmId))
		self:updateFrame()
	end
end