--- Entry point for Challenge Mod initialization
--- This script initializes the base systems before the main mod loads

-- Ensure CpObject is available
if CpObject == nil then
    print("ERROR: CpObject not available in EntryPoint")
    return
end

-- Initialize Logger if not already done
if Logger == nil then
    print("ERROR: Logger is not available")
    return  
end

-- Initialize base managers
if g_pointTypeManager == nil then
    ---@type PointTypeManager
    g_pointTypeManager = PointTypeManager()
end

if g_challengeFarmManager == nil then
    ---@type ChallengeFarmManager
    g_challengeFarmManager = ChallengeFarmManager()
end

-- Log initialization
local logger = Logger("ChallengeModInitialization")
logger:debug("Challenge Mod systems initialized")
