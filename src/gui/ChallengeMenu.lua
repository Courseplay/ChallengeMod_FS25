ChallengeMenu = {
	BASE_XML_KEY = "Menu"
}
local ChallengeMenu_mt = Class(ChallengeMenu, TabbedMenu)
function ChallengeMenu.new(target, customMt, messageCenter, l10n, inputManager)
	local self = ChallengeMenu:superClass().new(target, customMt or ChallengeMenu_mt, messageCenter, l10n, inputManager)

	self.messageCenter = messageCenter
	self.l10n = l10n
	self.inputManager = inputManager

	self.defaultMenuButtonInfo = {}
	self.backButtonInfo = {}
	self.currentVehicle = nil

	self.messageCenter:subscribe(MessageType.GUI_CHALLENGE_MOD_MENU_OPEN, function (menu)
		g_gui:showGui("ChallengeMenu")
		self:changeScreen(ChallengeMenu)
		self:updatePages()
		-- local index = self.pagingElement:getPageMappingIndexByElement(self.page)
		-- self.pageSelector:setState(pageAIIndex, true)
	end, self)
	return self
end

-- Lines 135-193
function ChallengeMenu.createFromExistingGui(gui, guiName)
	FarmOverviewFrame.createFromExistingGui(g_gui.frames.challengeModFarmOverview.target, "FarmOverviewFrame")
	SettingsFrame.createFromExistingGui(g_gui.frames.challengeModSettings.target, "SettingsFrame")
	-- CpCourseGeneratorFrame.createFromExistingGui(g_gui.frames.ChallengeMenuCourseGenerator.target, "CpCourseGeneratorFrame")
	-- CpCourseManagerFrame.createFromExistingGui(g_gui.frames.ChallengeMenuCourseManager.target, "CpCourseManagerFrame")
	-- CpHelpFrame.createFromExistingGui(g_gui.frames.ChallengeMenuHelpLine.target, "CpHelpFrame")
	-- CpConstructionFrame.createFromExistingGui(g_gui.frames.ChallengeMenuConstruction.target, "CpConstructionFrame")

	local messageCenter = gui.messageCenter
	local l10n = gui.l10n
	local inputManager = gui.inputManager
	local newGui = ChallengeMenu.new(nil, nil, messageCenter, l10n, inputManager)

	g_gui.guis.ChallengeMenu:delete()
	g_gui.guis.ChallengeMenu.target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)

	g_ChallengeMenu = newGui
	
	return newGui
end

function ChallengeMenu.setupGui()

	MessageType.GUI_CHALLENGE_MOD_MENU_OPEN = nextMessageTypeId()

	FarmOverviewFrame.setupGui()
	SettingsFrame.setupGui()

	g_ChallengeMenu = ChallengeMenu.new(nil, nil, g_messageCenter, g_i18n, g_inputBinding)
	g_gui:loadGui(Utils.getFilename("config/gui/ChallengeMenu.xml",
	g_challengeMod.BASE_DIRECTORY),
		"ChallengeMenu", g_ChallengeMenu)
end

function ChallengeMenu.registerXmlSchema(xmlSchema, xmlKey)
	xmlKey = xmlKey .. ChallengeMenu.BASE_XML_KEY .. "."
	-- CpCourseGeneratorFrame.registerXmlSchema(xmlSchema, xmlKey)
	-- CpGlobalSettingsFrame.registerXmlSchema(xmlSchema, xmlKey)
	-- CpVehicleSettingsFrame.registerXmlSchema(xmlSchema, xmlKey)
	-- CpCourseManagerFrame.registerXmlSchema(xmlSchema, xmlKey)
	-- CpHelpFrame.registerXmlSchema(xmlSchema, xmlKey)
end

function ChallengeMenu:loadFromXMLFile(xmlFile, baseKey)
	baseKey = baseKey .. ChallengeMenu.BASE_XML_KEY .. "."
	-- self.pageCourseGenerator:loadFromXMLFile(xmlFile, baseKey)
	-- self.pageGlobalSettings:loadFromXMLFile(xmlFile, baseKey)
	-- self.pageVehicleSettings:loadFromXMLFile(xmlFile, baseKey)
	-- self.pageCourseManager:loadFromXMLFile(xmlFile, baseKey)
	-- self.pageHelpLine:loadFromXMLFile(xmlFile, baseKey)
	-- self.pageConstruction:loadFromXMLFile(xmlFile, baseKey)
end

function ChallengeMenu:saveToXMLFile(xmlFile, baseKey)
	baseKey = baseKey .. ChallengeMenu.BASE_XML_KEY .. "."
	-- self.pageCourseGenerator:saveToXMLFile(xmlFile, baseKey)
	-- self.pageGlobalSettings:saveToXMLFile(xmlFile, baseKey)
	-- self.pageVehicleSettings:saveToXMLFile(xmlFile, baseKey)
	-- self.pageCourseManager:saveToXMLFile(xmlFile, baseKey)
	-- self.pageHelpLine:saveToXMLFile(xmlFile, baseKey)
	-- self.pageConstruction:saveToXMLFile(xmlFile, baseKey)
end

function ChallengeMenu:initializePages()
	self.clickBackCallback = function ()
		if self.currentPage.onClickBack then 
			--- Force closes the page 
			self.currentPage:onClickBack(true)
		end
		self:exitMenu()
	end
	self.pageFarmOverview:setData(g_challengeFarmManager)

	self.pageFarmOverview:initialize(self)
	self.pageSettings:initialize(self)
end

function ChallengeMenu:setupMenuPages()
	local orderedDefaultPages = {
		{
			self.pageFarmOverview,
			function ()
				return true
			end,
			"gui.icon_options_help2"
		},
		{
			self.pageSettings,
			function ()
				return true
			end,
			"gui.icon_options_help2"
		},
		-- {
		-- 	self.pageHelpLine,
		-- 	function ()
		-- 		return true
		-- 	end,
		-- 	"gui.icon_options_help2"
		-- }
	}
	for i, pageDef in ipairs(orderedDefaultPages) do
		local page, predicate, sliceId = unpack(pageDef)
		if page ~= nil then
			self:registerPage(page, i, predicate)
			self:addPageTab(page, nil, nil, sliceId)
		end
	end
end

function ChallengeMenu:setupMenuButtonInfo()
	ChallengeMenu:superClass().setupMenuButtonInfo(self)
	local onButtonBackFunction = self.clickBackCallback
	local onButtonPagePreviousFunction = self:makeSelfCallback(self.onPagePrevious)
	local onButtonPageNextFunction = self:makeSelfCallback(self.onPageNext)
	self.backButtonInfo = { 
		inputAction = InputAction.MENU_BACK,  
		text = g_i18n:getText(InGameMenu.L10N_SYMBOL.BUTTON_BACK),
		callback = onButtonBackFunction }
	self.nextPageButtonInfo = { 
		inputAction = InputAction.MENU_PAGE_NEXT,
		text = g_i18n:getText("ui_ingameMenuNext"),
		callback = self.onPageNext }
	self.prevPageButtonInfo = { 
		inputAction = InputAction.MENU_PAGE_PREV,
		text = g_i18n:getText("ui_ingameMenuPrev"),
		callback = self.onPagePrevious }

	self.defaultMenuButtonInfo = {
		self.backButtonInfo,
		self.nextPageButtonInfo,
		self.prevPageButtonInfo
	}

	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_NEXT] = self.defaultMenuButtonInfo[2]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_PREV] = self.defaultMenuButtonInfo[3]
	
	self.defaultButtonActionCallbacks = {
		[InputAction.MENU_BACK] = onButtonBackFunction,
		[InputAction.MENU_PAGE_NEXT] = onButtonPageNextFunction,
		[InputAction.MENU_PAGE_PREV] = onButtonPagePreviousFunction}
end

function ChallengeMenu:onGuiSetupFinished()
	ChallengeMenu:superClass().onGuiSetupFinished(self)

	self:initializePages()
	self:setupMenuPages()
end

function ChallengeMenu:reset()
	ChallengeMenu:superClass().reset(self)

end

function ChallengeMenu:onMenuOpened()

end

function ChallengeMenu:onButtonBack()
	if self.currentPage.onClickBack then 
		if not self.currentPage:onClickBack() then 
			return
		end
	end
	if self.currentPage:requestClose(self.clickBackCallback) then
		ChallengeMenu:superClass().onButtonBack(self)
	end
end

function ChallengeMenu:onPageNext()
	if self.currentPage:requestClose(function ()
			TabbedMenu:superClass().onPageNext(self)
		end) then
		TabbedMenu:superClass().onPageNext(self)
	end
end
function ChallengeMenu:onPagePrevious()
	if self.currentPage:requestClose(function ()
			TabbedMenu:superClass().onPagePrevious(self)
		end) then
		TabbedMenu:superClass().onPagePrevious(self)
	end
end

function ChallengeMenu:onClose(element)
	ChallengeMenu:superClass().onClose(self)
end

function ChallengeMenu:onOpen()
	ChallengeMenu:superClass().onOpen(self)

end

function ChallengeMenu:update(dt)

	ChallengeMenu:superClass().update(self, dt)
end

function ChallengeMenu:draw()
	if self.currentPage.drawInGame then 
		self.currentPage:drawInGame()
		new2DLayer()
	end
	ChallengeMenu:superClass().draw(self)
end

function ChallengeMenu:onClickMenu()
	self:exitMenu()

	return true
end

function ChallengeMenu:onPageChange(pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
	ChallengeMenu:superClass().onPageChange(self, pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
	if self.currentPage.categoryHeaderIcon then
		self.currentPage.categoryHeaderIcon:setImageSlice(nil, self.pageTabs[self.currentPage].iconSliceId)
	end
	self.background:setVisible(not self.currentPage.noBackgroundNeeded)
end

function ChallengeMenu:getPageButtonInfo(page)
	local buttonInfo = ChallengeMenu:superClass().getPageButtonInfo(self, page)

	return buttonInfo
end

function ChallengeMenu.openMenu()
	g_messageCenter:publish(MessageType.GUI_CHALLENGE_MOD_MENU_OPEN)
end
