--[[
	This frame is a page for all global settings in the in game menu.
	All the layout, gui elements are cloned from the general settings page of the in game menu.
]]--

SettingsFrame = {
	CATEGRORIES = {
		POINT_OVERVIEW = 1
	},
	CATEGRORY_TEXTS = {
		"points",
	}
}
SettingsFrame.NUM_CATEGORIES = #SettingsFrame.CATEGRORY_TEXTS

local SettingsFrame_mt = Class(SettingsFrame, TabbedMenuFrameElement)

function SettingsFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsFrame_mt)
	self.subCategoryPages = {}
	self.subCategoryTabs = {}
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

function SettingsFrame.registerXmlSchema(xmlSchema, xmlKey)
	
end

function SettingsFrame:loadFromXMLFile(xmlFile, baseKey)
   
end

function SettingsFrame:saveToXMLFile(xmlFile, baseKey)
   
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
