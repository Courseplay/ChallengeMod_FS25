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
    self.isServer = g_server
    self.isAdminModeActive = false

    -- g_messageCenter:subscribe(MessageType.FARM_CREATED, self.newFarmCreated, self)
    -- g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
    -- g_messageCenter:subscribe(MessageType.SAVEGAME_LOADED, self.onSavegameLoaded, self)
end


function ChallengeMod:registerXmlSchema()
    self.xmlSchemaConfig = XMLSchema.new("ChallengeModConfig")
    PointTypeManager.registerConfigXmlSchema(
        self.xmlSchemaConfig, self.configXmlKey .. ".")
    self.xmlSchemaSavegame = XMLSchema.new("ChallengeModSavegame")
end

function ChallengeMod:loadMap(filename)
    self:registerXmlSchema()
    local xmlFile = XMLFile.loadIfExists("cpXmlFile", 
        Utils.getFilename('config/ChallengeConfig.xml', 
            ChallengeMod.BASE_DIRECTORY), self.xmlSchemaConfig)
	if xmlFile then
        g_pointTypeManager:loadFromXMLFile(xmlFile, self.configXmlKey .. ".")
        xmlFile:delete()
    end
    if g_server ~= nil and g_currentMission.missionInfo.savegameDirectory ~= nil then
		local savegamePath = g_currentMission.missionInfo.savegameDirectory .."/"
		local filePath = savegamePath .. "Challenge.xml"
		self.xmlFile = XMLFile.loadIfExists("challengeXml", filePath , self.xmlSchemaSavegame)
        if self.xmlFile then 

            self.xmlFile:delete()
        end
	end
    g_challengeFarmManager:onSetup()
    ChallengeMenu.setupGui()
end

function ChallengeMod:deleteMap()

end

function ChallengeMod.saveToXMLFile(missionInfo)
	if missionInfo.isValid then 
		local saveGamePath = missionInfo.savegameDirectory .."/"
		local xmlFile = XMLFile.create(
            "challengeXml", saveGamePath.. "Challenge.xml", 
			g_challengeMod.savegameXmlKey, 
            g_challengeMod.xmlSchemaSavegame)
		if xmlFile then	
            
			xmlFile:save()
			xmlFile:delete()
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

end

---@type ChallengeMod
g_challengeMod = ChallengeMod()
addModEventListener(g_challengeMod)