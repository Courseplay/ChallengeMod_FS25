CustomBinaryOptionElement = {}
local CustomBinaryOptionElement_mt = Class(CustomBinaryOptionElement, BinaryOptionElement)

function CustomBinaryOptionElement.new(target, custom_mt)
	local self = BinaryOptionElement.new(target, custom_mt or CustomBinaryOptionElement_mt)
	self.dataSource = nil
	self.toolTipElement = nil
	return self
end

function CustomBinaryOptionElement:delete()
	self.dataSource = nil

	CustomBinaryOptionElement:superClass().delete(self)
end

function CustomBinaryOptionElement:setDataSource(dataSource)
	self.dataSource = dataSource
	self.useYesNoTexts = false
	self:setTexts({self.dataSource.texts[1], self.dataSource.texts[2]})
	if self.dataSource:getValue() then 
		self:setState(BinaryOptionElement.STATE_RIGHT, true)
	else 
		self:setState(BinaryOptionElement.STATE_LEFT, true)
	end	
end
function CustomBinaryOptionElement:updateTitle()
	if self.labelElement then 
		self.labelElement:setText(self.dataSource:getTitle())
	end
	self.toolTipElement = self:getDescendantByName("tooltip")
	if self.toolTipElement then 
		self.toolTipText = self.dataSource:getTooltip()
	end
end

function CustomBinaryOptionElement:setState(state, ...)
	if state == BinaryOptionElement.STATE_RIGHT then 
		self.dataSource:setValue(true)
	else 
		self.dataSource:setValue(false)
	end
	self:updateTitle()
	if self.dataSource:getValue() then 
		CustomBinaryOptionElement:superClass().setState(self, BinaryOptionElement.STATE_RIGHT, true)
	else
		CustomBinaryOptionElement:superClass().setState(self, BinaryOptionElement.STATE_LEFT, true)
	end
end

Gui.registerGuiElement("CustomBinaryyOption", CustomBinaryOptionElement)
