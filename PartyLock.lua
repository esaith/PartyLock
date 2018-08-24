SLASH_PARTYLOCK1 = '/partylock';
SLASH_PARTYLOCK2 = '/pl';

if not LibStub then
	print("Party Lock requires LibStub.")
	return
end

local GuildTable
local ScrollingTable
local totalFontStrings = 1
local CURRENTPLAYER
local BottomTab = {"Party", "Guild"}
local PartyList = {}
local raidList = { }
    raidList[1] = {full = "Atal'Dazar", short = "Atal"}
    raidList[2] = {full = "Freehold", short = "FH"}
    raidList[3] = {full = "Kings' Rest", short = "KR"}
    raidList[4] = {full = "Shrine of the Storm", short = "SotS"}
    raidList[5] = {full = "Siege of Boralus", short = "SoB"}
    raidList[6] = {full = "Temple of Sethraliss", short = "ToS"}
    raidList[7] = {full = "The MOTHERLODE!!", short = "LODE"}
    raidList[8] = {full = "The Underrot", short = "TU"}
    raidList[9] = {full = "Tol Dagor", short = "TD"}
    raidList[10] = {full = "Waycrest Manor", short = "WM"}
    
local diffList = { }
    --diffList[0] = "Normal"
    diffList[1] = "Heroic"   
    diffList[2] = "Mythic"
    --diffList[3] = "10 Player (Heroic)"
    --diffList[4] = "25 Player (Heroic)"
    --diffList[5] = "10 Player (Mythic)"
    --diffList[6] = "25 Player (Mythic)"

    
local function printTable(tb, spacing) 
    if spacing == nil then spacing = "" end
    print(spacing.."Entering table")
    if tb == nil then print("Table is nil") return end
    if type(tb) == 'string' then 
        print("String: "..tb)
        return
    end
    
    if type(tb) == 'number' then 
        print("Number: "..tostring(tb))
        return
    end
    
    for k, v in pairs(tb) do
        print(spacing.."K: "..k..", v: "..tostring(v))
        if type(v) == "table" then
            printTable(v, "   "..spacing)
        end
    end
      
    print(spacing.."Leaving Table")
end
local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end
local function parseTime(time)
    time = math.floor(tonumber(time))
    
    -- time should be a total of 4 digits long, or 0. ie, [0] or [1000, 9999]
    if time < 0 then time = 0 end
    
    if time < 1000 then 
        while time > 0 and time < 1000 do
            time = time * 10
        end
    elseif time > 10000 then
        while time > 0 and time > 10000 do
            time = time / 10
        end
    end
    
    return time
end
local function toggleShowAddon()
    if PartyLock:IsShown() then
		PartyLock:Hide();
	else    
		PartyLock:Show();            
	end
end
local function RequestGuildUpdate()
    C_ChatInfo.SendAddonMessage("PartyLockGuild", "Update" , "GUILD")
end
function SlashCmdList.PARTYLOCK(msg, editbox) 
	
    local command = msg:match("^(%S*)%s*(.-)$")
	if command == "center" then
		PartyLock:ClearAllPoints()
		PartyLock:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		PartyLock:Show()
    elseif command == "request" then
        RequestGuildUpdate()
    else
        toggleShowAddon()
	end
end

local function PrepreToolTip(self)
	local x = self:GetRight();
	if (x >=(GetScreenWidth() / 2)) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
end
local function RequestOnEnter(self, motion)
    PrepreToolTip(self)
	GameTooltip:AddLine("Requests a guild update.")
	GameTooltip:Show()
end
function OnGameToolTipLeave(self, motion)
	GameTooltip:Hide()
end

local function DungeonToInt(d)
    for index, dungeon in pairs(raidList) do
        if d == dungeon.full then
            return index
        end
    end
    
    return -1
end
local function IntToDungeon(int)
    int = tonumber(int)
    if raidList[int] then
        return raidList[int].full
    end
        return "Dungeon Unknown"
end
local function DifficultyToInt(diff)
    for index, difficulty in pairs(diffList) do
        if difficulty == diff then
            return index
        end
    end
    return -1    
end
local function IntToDifficulty(int)
    int = tonumber(int)
   if diffList[int] then
        return diffList[int]
   end
   
   return nil
end

local function isGuildieOnline(member)
    local numGuildMembersOnline = select(2, GetNumGuildMembers())
    if member ==  CURRENTPLAYER then return true end
    
    for index = 1, numGuildMembersOnline do
        -- name is CharName-Server
        name = GetGuildRosterInfo(index);   
        if member == name then             
            return true
        end
    end
    return false
end
local function ParsePlayerRaidInfo()
    local spec, NumOfInstances

    -- Current Player Info
    spec = GetSpecialization() 
    spec = spec and select(2, GetSpecializationInfo(spec)) or PartyLockVar.player[CURRENTPLAYER].stats.spec or '<spec>'
    
	NumOfInstances = GetNumSavedInstances()
    
    for i = 1, NumOfInstances do
		iName, _, iReset, iDifficulty, _, _, _, _, _, iDifficultyName = GetSavedInstanceInfo(i)   
        if iReset > 0 then
            iReset = iReset + time() 
            iReset = math.ceil((iReset / 1000) % 10000)
            PartyLockVar.player[CURRENTPLAYER].savedDungeons[iDifficultyName] = PartyLockVar.player[CURRENTPLAYER].savedDungeons[iDifficultyName] or {}
            PartyLockVar.player[CURRENTPLAYER].savedDungeons[iDifficultyName][iName] = { time = iReset }        
        end
	end    
    
    PartyLockVar.player[CURRENTPLAYER].stats.ilvl = math.floor(GetAverageItemLevel())
    PartyLockVar.player[CURRENTPLAYER].stats.guildie = true
    PartyLockVar.player[CURRENTPLAYER].stats.spec = spec
    
end
local function PrintAvailablePartyMythics(y, fontstringCount)
    --local raids = {}
    --local t = time()
    --
    ---- Starting off all mythics are available to all players
    --for key, value in pairs(raidList) do
    --    raids[value.full] = true
    --end
    --
    ---- Loop through every player
    --for playerName, playerObject in pairs(PartyLockVar.player) do 
    --    if playerObject.savedDungeons.Mythics then
    --        for dungeon, time in pairs(playerObject.savedDungeons.Mythics) do
    --            if raids[dungeon] and time > t then
    --                raids[dungeon] = false
    --            end
    --        end
    --    end
    --end
    --
    --fontstring = _G["PartyLockFontString1"..fontstringCount]
    --fontstring:SetFont("Fonts\\FRIZQT__.TTF", 20)
    --fontstring:SetPoint("CENTER", priorRelativePosition, "CENTER", 0, y + 20)
    --fontstring:SetText("Available Mythics for all players")
    --fontstring:Show()
            
end
local function IsInParty(player)
    if PartyLockVar.Party == nil then return end 
    local index, realmName
    
    -- If any party member is in the same realm as the player the party members name will not include its realm name. 
    -- The realm name needs to be included for table lookup
    realmName = GetRealmName()
    realmName = string.gsub(realmName, " ", '')
    for i, partyMember in pairs(PartyLockVar.Party) do
        index = partyMember:find("-")
        
        if index == nil then 
           partyMember = partyMember.."-"..realmName
        end
        
        if player == partyMember then 
            table.insert(PartyList, player)
            return true
        end
    end    
    
    return false
end

function stageMessage()
    local msg = CURRENTPLAYER
    local diff, dun
    if CURRENTPLAYER == nil or CURRENTPLAYER == "" then return "" end
    
    msg = msg..','..PartyLockVar.player[CURRENTPLAYER].stats.spec
    msg = msg..','..PartyLockVar.player[CURRENTPLAYER].stats.ilvl    
       
    for difficulty, dungeons in pairs(PartyLockVar.player[CURRENTPLAYER].savedDungeons) do           
        for dungeon, stats in pairs(PartyLockVar.player[CURRENTPLAYER].savedDungeons[difficulty]) do 
            local t = math.floor(stats.time)
            if t > 0 then
                diff = DifficultyToInt(difficulty)
                dun = DungeonToInt(dungeon) 
                
                if dun and dun ~= -1 and diff and diff ~= "Dungeon Unknown" then
                    msg = msg..','..diff..','..dun..','..tostring(math.floor(stats.time))       
                end
            end
        end        
    end   
    msg = msg..",,"
    return msg
end
function UpdateGuild()
    -- Verify only update no more than once every 120 seconds
    if PartyLockVar.LastGuildPing + 120 < time() and IsInGuild() then 
        local msg = stageMessage()
        if not msg then return end
        C_ChatInfo.SendAddonMessage("PartyLockGuild", msg , "GUILD")
        PartyLockVar.LastGuildPing = time()
    end
end
function UpdateParty()
    -- Verify only update no more than once every 60 seconds
    if PartyLockVar.LastPartyPing + 60 < time() and IsInGroup() then
        local msg = stageMessage()
        if not msg then return end
        C_ChatInfo.SendAddonMessage("PartyLockParty", msg , "PARTY")
        PartyLockVar.LastPartyPing = time()
    end
end
local function ParseIncomingPlayer(str)    
    local friend, spec, ilvl, temp = string.match(str, "(.-),(.-),(.-),(.+)")
   
    if friend == CURRENTPLAYER or not friend then return end
    PartyLockVar.player[friend] = {
        stats = {
            spec = spec,
            ilvl = ilvl,
            guildie = false
        },
        savedDungeons = {}
    }
   
    local difficulty, dungeon, time, name
    while str ~= nil and str ~= "," do
        difficulty, dungeon, time, str = string.match(str, "(.-),(.-),(.-),(.+)")
        if str and difficulty and dungeon then   
            
            difficulty = IntToDifficulty(difficulty)
            dungeon = IntToDungeon(dungeon)
            time = parseTime(time)
            
            if difficulty and dungeon then
                PartyLockVar.player[friend].savedDungeons[difficulty] = PartyLockVar.player[friend].savedDungeons[difficulty] or {}               
                PartyLockVar.player[friend].savedDungeons[difficulty][dungeon] = { time = time}
            end
        end
    end      
    
    local numGuildMembers = GetNumGuildMembers()
       
    for index = 1, numGuildMembers do
        name = GetGuildRosterInfo(index);         
        if friend == name then 
            PartyLockVar.player[friend].stats.guildie = true           
            break
        end
    end    
end
local function UpdateTableData()
     local rowValue, row, rowColor, cols, t, addText
     local offlineColor = { r = 0.27, g = 0.38, b = 0.43, a = 1.0 }   -- #46626E
     t = math.floor((time() / 1000) % 10000) 
     rowColor = { r = 1, g = 1, b = 1, a = 1}
     rows = {}
          
     if not PartyLockVar then return end
     for player, playerObj in pairs(PartyLockVar.player) do
        
        addText = PartyLockVar.BottomTab == "Guild" and playerObj.stats.guildie or IsInParty(player)
        
        -- Only list players that have mythics saved
        if addText and playerObj.savedDungeons.Mythic then 
            local color = playerObj.stats.guildie and not isGuildieOnline(player) and offlineColor or rowColor
            cols = {
                { ["value"] = playerObj.stats.ilvl, ["color"] = color },
                { ["value"] = player:match("(.*)-.*") or player, ["color"] = color},
                { ["value"] = playerObj.stats.spec, ["color"] = color },                
            }
            
            for key, raid in ipairs(raidList) do   
                local val = ""
                if playerObj.savedDungeons.Mythic[raid.full] ~= nil then                    
                    -- Due to possible parsing issues from older version make sure raid time is at least 5 digits long
                    playerObj.savedDungeons.Mythic[raid.full].time = parseTime(playerObj.savedDungeons.Mythic[raid.full].time)
                    
                    if playerObj.savedDungeons.Mythic[raid.full].time > t then                        
                        val = "X"
                    end
                end      
                table.insert(cols, { ["value"] = val , ["color"] = color})
            end
            
            row = { ["cols"] = cols }            
            table.insert(rows, row) 
        end
     end
     
    GuildTable:SetData(rows)
end
local function CreateTable()
    local evenColor = { r = 0.94, g = 0.98, b = 1.0, a = 1.0 }    
    local evenBgColor = { r = 0.11, g = 0.16, b = 0.18, a = 1.0 }
    local oddColor = { r = 0.94, g = 0.98, b = 1.0, a = 1.0 }       -- #2C3E45 
    local oddBgColor = { r = 0.17, g = 0.24, b = 0.27, a = 1.0 }  
    local isEven = true

    local headers = 
    {    
        {
            ["name"] = "ilvl",
            ["width"] = 40,
            ["align"] = "CENTER",
            ["color"] = oddColor,
            ["colorargs"] = nil,
            ["bgcolor"] = oddBgColor
        },
        {
            ["name"] = "Character",
            ["width"] = 160,
            ["align"] = "CENTER",
            ["color"] = evenColor,
            ["colorargs"] = nil,
            ["bgcolor"] = evenBgColor
        },
        {
            ["name"] = "Specialization",
            ["width"] = 130,
            ["align"] = "CENTER",
            ["color"] = oddColor,
            ["colorargs"] = nil, 
            ["bgcolor"] = oddBgColor   
        }        
    }
    
    local dungeon
    for index, raid in ipairs(raidList) do
        dungeon = 
        {
            ["name"] = raid.short,
            ["width"] = (string.len(raid.short) < 4 and 45) or 50,
            ["align"] = "CENTER",
            ["color"] = oddColor,
            ["colorargs"] = nil,
            ["bgcolor"] = oddBgColor
        }
        
        if isEven then 
            dungeon["color"] = evenColor
            dungeon["bgcolor"] = evenBgColor
        end
        
        isEven = not isEven
        table.insert(headers, dungeon)
    end
    
    local rowHighlight = {r = .93, g = .90, b = .74, a = .5}
    GuildTable = ScrollingTable:CreateST(headers, 20, 22, rowHighlight, PartyLock);
end
local function playerInit() 
    local fontstring, spec
    -- Moved this to the addoninit function
    -- CURRENTPLAYER = UnitName("player").."-"..GetRealmName()
    -- CURRENTPLAYER = string.gsub(CURRENTPLAYER, " ", '')
    
    spec = GetSpecialization() 
    spec = spec and select(2, GetSpecializationInfo(spec)) or '<spec>'
    
    PartyLockVar = PartyLockVar or {}
    PartyLockVar.LastPing = 0
    PartyLockVar.LastGuildPing = 0
    PartyLockVar.LastPartyPing = 0
    PartyLockVar.updateGuild = false
    PartyLockVar.player = PartyLockVar.player or {}
    PartyLockVar.player[CURRENTPLAYER] = {
            stats = {
                class =  UnitClass("player"),
                spec = spec,
                ilvl = 0,
                guildie = true                
            },
            savedDungeons = {}                    
    }
    
    -- If the player logs in and already in a party grab the party members. Regardless if in a group add current player into the group
    PartyLockVar.Party = GetHomePartyInfo() or {}
    table.insert(PartyLockVar.Party, 1, CURRENTPLAYER) 
end
local function addonInit()
    PartyLockTitle:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE, THICKOUTLINE")
    PartyLockTitle:SetPoint("TOP", "$parent", "TOP", 0, 0)    
	PartyLockTitle:SetText("|cff3D86AB Party Lock")
	PartyLockTitle:SetWidth(400)    
    --PartyLockTitle:SetResizable(true) 
    -- Create fontstring to show and hide
    for i = 1, 80 do
        fontstring = PartyLock:CreateFontString("$parentFontString1"..i, "ARTWORK", "GameFontNormal")
        fontstring = PartyLock:CreateFontString("$parentFontString2"..i, "ARTWORK", "GameFontNormal")
    end
    
    ScrollingTable = LibStub("ScrollingTable");
    CreateTable()
    UpdateTableData()


    PartyLockVar = PartyLockVar or {}
    PartyLockVar.version = GetAddOnMetadata("Party Lock", "Version")    

    -- Create short dungeon title list
    fontstring = PartyLock:CreateFontString("$parentFontStringDungeons", "ARTWORK", "GameFontNormal")
    fontstring:SetFont("Fonts\\FRIZQT__.TTF", 15)
    
    PartyLockVar.BottomTabIndex = PartyLockVar.BottomTabIndex or 1
    PartyLockVar.BottomTab = BottomTab[PartyLockVar.BottomTabIndex]
    
    -- Close button
    local btn = CreateFrame("Button", "$parentCloseButton", PartyLock, "UIMenuButtonStretchTemplate")
	btn:SetWidth(100)
    btn:SetHeight(30)
	btn:SetPoint("BOTTOM", "$parent", "BOTTOM", 0, 15)
	btn:SetText("Close")
    btn:SetScript("OnClick", toggleShowAddon)
    btn:SetScript("OnLeave", OnGameToolTipLeave)
	btn:Show()
    
    -- Hiding Request Update button for now. Making an easter egg for later on
    btn = CreateFrame("Button", "$parentRequestButton", PartyLock, "UIMenuButtonStretchTemplate")
	btn:SetWidth(100)
    btn:SetHeight(30)
	btn:SetPoint("BOTTOMRIGHT", "$parent", "BOTTOMRIGHT", -25, 15)
	btn:SetText("Request Update")
    btn:SetScript("OnEnter", RequestOnEnter)
    btn:SetScript("OnLeave", OnGameToolTipLeave)
    btn:SetScript("OnClick", RequestGuildUpdate)
	btn:Show()
      
    -- Hide AddOn with <Esc> key
    tinsert(UISpecialFrames, "PartyLock") 
end

function PartyLock_OnLoad(self, event, ...) 
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("UPDATE_INSTANCE_INFO")
    self:RegisterEvent("PLAYER_LOGOUT")
    self:RegisterEvent("CHAT_MSG_ADDON") 
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("GUILD_ROSTER_UPDATE")
    self:RegisterForDrag("LeftButton")       
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end
function PartyLock_OnEvent(self, event, arg1, arg2) 
    if event == "ADDON_LOADED" and arg1 == "PartyLock" then
	    self:UnregisterEvent("ADDON_LOADED")
        local success
        
        if not LibStub then
            print("BugSack requires LibStub.")
            return
        end

        CURRENTPLAYER = UnitName("player").."-"..GetRealmName()
        CURRENTPLAYER = string.gsub(CURRENTPLAYER, " ", '')

        success = C_ChatInfo.RegisterAddonMessagePrefix("PartyLockParty")
        success = C_ChatInfo.RegisterAddonMessagePrefix("PartyLockGuild")
        addonInit()
        
        -- Update party when logging in if player is current grouped    
        if GetNumGroupMembers() > 0 and PartyLockVar then UpdateParty() end 
        
    elseif event == "UPDATE_INSTANCE_INFO" then
        ParsePlayerRaidInfo()
        UpdateParty()
        
        -- When first logging in and after getting the updated raid info send a message to the guild for everyone else to be updated
        -- This is to help for those players who do not open use this AddOn often
        if not PartyLockVar.updateGuild then
            UpdateGuild()
            PartyLockVar.updateGuild = true
        end
            
    elseif event == "PLAYER_ENTERING_WORLD" then 
       -- initialize basic variables. Wait until player enters world before calling basic player info
        playerInit()
        
         -- Requests info from server then continue to "UPDATE_INSTANCE_INFO" when server responds 
        RequestRaidInfo()
        
    elseif event == "CHAT_MSG_ADDON" then
    
        -- Only listen to incoming messages from this AddOn
        if (arg1 == "PartyLockParty" or arg1 == "PartyLockGuild") and arg2 ~= nil then   

            if (arg2 == "Update") then
                UpdateGuild()
            
             -- Allow additional verbs like Update, Check, etc to take place without breaking future versions
            elseif string.len(arg2) > 10 then
                ParseIncomingPlayer(arg2)
            end
        end   
    
    elseif event == "GROUP_ROSTER_UPDATE" then        
        -- Anytime a group member comes or goes immediately update the party list
        PartyLockVar.Party = GetHomePartyInfo() or {}
        table.insert(PartyLockVar.Party, 1, CURRENTPLAYER) 
        PartyLock_BottomTab_Click()
        
    elseif event == "GUILD_ROSTER_UPDATE" then
        GuildTable:Refresh()
    end
end
function PartyLock_OnShow(self, event, ...) 
    PanelTemplates_SetTab(PartyLock_BottomTabs, PartyLockVar.BottomTabIndex)
    
    -- Get players info no more than every 2 min
    if PartyLockVar.LastPing + 120 < time() then  
        PartyLockVar.LastPing = time()
        RequestRaidInfo()  
    end    
    
    UpdateGuild()    
    UpdateTableData()
end
function PartyLock_BottomTab_Click(self, event, ... )

    if self then 
        PartyLockVar.BottomTabIndex = self:GetID()                
        PartyLockVar.BottomTab = BottomTab[self:GetID()] or 1       
    end
    
    UpdateTableData()
end


--[[
 Todo
 Add mythic+ achievement/rank
 
 
 Completed
 Stopped sending messages to guild if the player does not belong to one
 Should only show players capable of doing mythics. This should filter out lower level players from being added
 Significant UI upgrade. Now in better table format. Player may sort by column
 Able to close the AddOn with the <Esc> Key
 Added request button to update all guild and party members. A lockout of only once every 2 minutes is in place.
]]--



















