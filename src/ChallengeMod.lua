--- Global class
---@class ChallengeMod
ChallengeMod = CpObject()
ChallengeMod.MOD_NAME = g_currentModName
ChallengeMod.BASE_DIRECTORY = g_currentModDirectory
ChallengeMod.configXmlKey = "ChallengeConfig"
ChallengeMod.savegameXmlKey = "ChallengeMod"
--- Makes sure other mods can access the ChallengeMod mod,
--- if they are accessing this after this call.
-- g_modManager.ChallengeMod_MOD_NAME = g_currentModNam

function ChallengeMod:init()
    self.isServer = g_server ~= nil
    self.isClient = g_client ~= nil
    self.isAdminModeActive = false
    self.xmlFile = nil
    self.xmlSchemaConfig = nil
    self.xmlSchemaSavegame = nil
    
    -- g_messageCenter:subscribe(MessageType.FARM_CREATED, self.newFarmCreated, self)
    -- g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
    -- g_messageCenter:subscribe(MessageType.SAVEGAME_LOADED, self.onSavegameLoaded, self)
end


function ChallengeMod:registerXmlSchema()
    self.xmlSchemaConfig = XMLSchema.new("ChallengeModConfig")
    PointTypeManager.registerConfigXmlSchema(
        self.xmlSchemaConfig, self.configXmlKey .. ".")
    self.xmlSchemaSavegame = XMLSchema.new("ChallengeModSavegame")
    
    -- Register savegame schema for ChangeLog and VehicleTracker
    ChangeLog.registerXmlSchema(self.xmlSchemaSavegame, self.savegameXmlKey .. ".")
    VehicleTracker.registerXmlSchema(self.xmlSchemaSavegame, self.savegameXmlKey .. ".")
    AdminManager.registerXmlSchema(self.xmlSchemaSavegame, self.savegameXmlKey .. ".")
end

function ChallengeMod:loadMap(filename)
    self:registerXmlSchema()
    local logger = Logger("ChallengeMod.loadMap")
    
    local configPath = Utils.getFilename('config/ChallengeConfig.xml', ChallengeMod.BASE_DIRECTORY)
    local xmlFile = XMLFile.loadIfExists("cpXmlFile", configPath, self.xmlSchemaConfig)
	if xmlFile then
        g_pointTypeManager:loadFromXMLFile(xmlFile, self.configXmlKey .. ".")
        xmlFile:delete()
        logger:debug("Loaded config from %s", configPath)
    else
        logger:warning("Could not load config from %s", configPath)
    end
    
    -- Load settings from savegame if available
    if g_currentMission.missionInfo.savegameDirectory ~= nil then
        local savegamePath = g_currentMission.missionInfo.savegameDirectory .. "/"
        
        -- Load Challenge.xml for farm data
        if g_server ~= nil then
            local filePath = savegamePath .. "Challenge.xml"
            self.xmlFile = XMLFile.loadIfExists("challengeXml", filePath, self.xmlSchemaSavegame)
            if self.xmlFile then 
                logger:debug("Loaded savegame from %s", filePath)
                self.xmlFile:delete()
            end
        end
        
        -- Load Challenge_Settings.xml for multiplier/admin settings
        if g_challengeSettings then
            local settingsLoaded = g_challengeSettings:loadFromSavegame(savegamePath)
            if settingsLoaded and g_adminManager then
                g_adminManager:setPassword(g_challengeSettings.adminPassword)
            end
        end
    end
    
    g_challengeFarmManager:onSetup()
    
    if g_gui then
        print("[ChallengeMod] Calling ChallengeMenu.setupGui()")
        ChallengeMenu.setupGui()
        logger:debug("Challenge menu GUI setup complete")
        print("[ChallengeMod] g_ChallengeMenu=" .. tostring(g_ChallengeMenu))
    else
        logger:warning("g_gui not available, GUI setup deferred")
        print("[ChallengeMod] ERROR: g_gui not available")
    end
end

function ChallengeMod:deleteMap()

end

function ChallengeMod.saveToXMLFile(missionInfo)
	if missionInfo.isValid then 
		local saveGamePath = missionInfo.savegameDirectory .."/"
		
		-- Save Challenge.xml (farm data)
		local xmlFile = XMLFile.create(
            "challengeXml", saveGamePath.. "Challenge.xml", 
			g_challengeMod.savegameXmlKey, 
            g_challengeMod.xmlSchemaSavegame)
		if xmlFile then	
            xmlFile:save()
			xmlFile:delete()
		end
		
		-- Save Challenge_Settings.xml (multipliers, admin password)
		if g_challengeSettings then
			g_challengeSettings:saveToSavegame(saveGamePath)
		end
	end
end
FSCareerMissionInfo.saveToXMLFile = Utils.prependedFunction(
    FSCareerMissionInfo.saveToXMLFile, ChallengeMod.saveToXMLFile)

function ChallengeMod:update(dt)
    g_challengeFarmManager:onUpdate(dt)
end

function ChallengeMod:draw()

end

---@param posX number
---@param posY number
---@param isDown boolean
---@param isUp boolean
---@param button number
function ChallengeMod:mouseEvent(posX, posY, isDown, isUp, button)

end

---@param unicode number
---@param sym number
---@param modifier number
---@param isDown boolean
function ChallengeMod:keyEvent(unicode, sym, modifier, isDown)
    if isDown then
        if g_inputBinding:hasEvent("CHALLENGE_OPEN_INGAME_MENU") then
            print("[ChallengeMod] CHALLENGE_OPEN_INGAME_MENU triggered (keyEvent)")
            if g_gui and g_ChallengeMenu then
                ChallengeMenu.openMenu()
            else
                print("[ChallengeMod] ERROR: g_gui=" .. tostring(g_gui) .. " g_ChallengeMenu=" .. tostring(g_ChallengeMenu))
            end
        end
    end
end

---@param actionName string
---@param keyStatus number
function ChallengeMod:onInputEvent(actionName, keyStatus)
    if actionName == "CHALLENGE_OPEN_INGAME_MENU" and keyStatus == InputAction.STATE_PRESSED then
        if g_gui and g_ChallengeMenu then
            ChallengeMenu.openMenu()
        end
    end
end

---@type ChallengeMod
g_challengeMod = ChallengeMod()
---@type PointTypeManager
g_pointTypeManager = PointTypeManager()
addModEventListener(g_challengeMod)

-- Hook into InGameMenu to add Challenge Mode tab
local originalInGameMenuInit = InGameMenu.new
function InGameMenu.new(messageCenter, l10n, inputManager, ...)
    local self = originalInGameMenuInit(messageCenter, l10n, inputManager, ...)
    
    -- This will be called when the InGameMenu is fully set up
    local originalOnGuiSetupFinished = self.onGuiSetupFinished
    function self:onGuiSetupFinished()
        originalOnGuiSetupFinished(self)
        
        -- Add Challenge Mode tab to the menu
        if self.menuButtonInfo then
            print("[ChallengeMod] Adding Challenge Mode button to InGameMenu")
            
            table.insert(self.menuButtonInfo, {
                label = g_i18n:getText("ui_challengeMode"),
                action = function()
                    print("[ChallengeMod] Challenge Mode button pressed")
                    if g_ChallengeMenu then
                        ChallengeMenu.openMenu()
                    end
                end
            })
        end
    end
    
    return self
end