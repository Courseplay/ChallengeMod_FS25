AddPointsDialog = {}

AddPointsDialog_mt = Class(AddPointsDialog, YesNoDialog)
AddPointsDialog.CONTROLS = {
    DIALOG_ELEMENT = "dialogElement",
    POINTS_INPUT = "pointsInput",
    REASON_INPUT = "reasonInput"
}

local function NO_CALLBACK() end

function AddPointsDialog.new(target, custom_mt)
    local self = YesNoDialog.new(target, custom_mt or AddPointsDialog_mt)

    self:registerControls(AddPointsDialog.CONTROLS)

    self.onTextEntered = NO_CALLBACK
    self.extraInputDisableTime = 0

    return self
end

function AddPointsDialog:onOpen()
    AddPointsDialog:superClass().onOpen(self)

    self.extraInputDisableTime = 100
    self.pointsInput.blockTime = 0
    self:focusPointsInput()

    if self.pointsInput.imeActive or self.reasonInput.imeActive then
        if self.yesButton ~= nil then
            self.yesButton:setVisible(false)
        end

        if self.noButton ~= nil then
            self.noButton:setVisible(false)
        end
    end
end

function AddPointsDialog:onClose()
    AddPointsDialog:superClass().onClose(self)

    self.pointsInput:setForcePressed(false)
    self.reasonInput:setForcePressed(false)

    self:updateButtonVisibility()
end

function AddPointsDialog:setCallback(onTextEntered, target, callbackArgs, defaultPointsText, defaultReasonText, dialogPrompt)
    self.onTextEntered = onTextEntered or NO_CALLBACK
    self.target = target
    self.callbackArgs = callbackArgs

    self.pointsInput:setText(defaultPointsText or "")
    self.reasonInput:setText(defaultReasonText or "")

    if dialogPrompt ~= nil then
        self.dialogTextElement:setText(dialogPrompt)
    end
end

function AddPointsDialog:sendCallback(clickOk)
    local points = tonumber(self.pointsInput:getText())
    local reason = self.reasonInput:getText()

    if clickOk then
        local function enterPoints(self)
            self:focusPointsInput()
            self.pointsInput:setForcePressed(true)
        end
        if reason == "" then
            g_gui:showInfoDialog({
                text = ScoreBoardFrame.translations.dialogs.errors.missingReason,
                dialogType = DialogElement.TYPE_WARNING,
                target = self,
                callback = self.onPointsEnterPressed,
            })
            return
        elseif points == 0 then
            g_gui:showInfoDialog({
                text = ScoreBoardFrame.translations.dialogs.errors.zeroPoints,
                dialogType = DialogElement.TYPE_WARNING,
                target = self,
                callback = enterPoints
            })
            return
        elseif points == nil then
            g_gui:showInfoDialog({
                text = ScoreBoardFrame.translations.dialogs.errors.notANumber,
                dialogType = DialogElement.TYPE_WARNING,
                target = self,
                callback = enterPoints
            })
            return
        end
    end

    self:close()

    if self.target ~= nil then
        self.onTextEntered(self.target, points, reason, clickOk, self.callbackArgs)
    end
end

function AddPointsDialog:isInputDisabled()
	return self.extraInputDisableTime > 0
end

function AddPointsDialog:updateButtonVisibility()
    local showButtons = not self.pointsInput.imeActive or not self.reasonInput.imeActive

    if self.yesButton ~= nil then
		self.yesButton:setVisible(showButtons)
	end

	if self.noButton ~= nil then
		self.noButton:setVisible(showButtons)
	end
end

function AddPointsDialog:update(dt)
    AddPointsDialog:superClass().update(self, dt)

    if self.extraInputDisableTime > 0 then
        self.extraInputDisableTime = self.extraInputDisableTime - dt
    end
end

function AddPointsDialog:onPointsEnterPressed()
    self:focusReasonInput()
    self.reasonInput:setForcePressed(true)
end

function AddPointsDialog:onReasonEnterPressed()
    return self:onClickOk()
end

function AddPointsDialog:onEscPressed()
    printCallstack()
    return self:onClickBack()
end

function AddPointsDialog:onClickOk()
    if not self:isInputDisabled() then
        self:sendCallback(true)

        return false
    else
        return true
    end
end

function AddPointsDialog:onClickBack()
    if not self:isInputDisabled() then
        self:sendCallback(false)

        return false
    else
        return true
    end
end

function AddPointsDialog:focusPointsInput()
    FocusManager:setFocus(self.pointsInput)
    self.pointsInput:onFocusActivate()
end

function AddPointsDialog:focusReasonInput()
    FocusManager:setFocus(self.reasonInput)
    self.reasonInput:onFocusActivate()
end