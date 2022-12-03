SLASH_PARTYLOCK1 = "/partylock"
SLASH_PARTYLOCK2 = "/pl"

if not LibStub then
    print("Party Lock requires LibStub.")
    return
end

local GuildTable
local playerInGuild
local ScrollingTable
local CURRENTPLAYER
local Tabs = {"Mythic Party", "Heroic Party", "Mythic Guild", "Heroic Guild"}
local BottomTab
local BottomTabIndex
local PartyList

local allDungeons = {
    SL = {
        ExpansionName = 'ShadowLands',
        xpac = 'SL',
        dungeons = {
            [1] = {fullName = "The Necrotic Wake", short = "NW"},
            [2] = {fullName = "Plaguefall", short = "PF"},
            [3] = {fullName = "Mists of Tirna Scithe", short = "MoTS"},
            [4] = {fullName = "Halls of Atonement", short = "HoA"},
            [5] = {fullName = "Theater of Pain", short = "ToP"},
            [6] = {fullName = "De Other Side", short = "DoS"},
            [7] = {fullName = "Spires of Ascension", short = "SoA"},
            [8] = {fullName = "Sanguine Depths", short = "SD"},
            [9] = {fullName = "Tazavesh, The Veiled Market", short = "TM"}
        }
    },
    DF = {
        ExpansionName = 'DragonFlight',
        xpac = 'DF',
        dungeons = {
            [1] = {fullName = "Algeth'ar Academy", shortName = "AA"},
            [2] = {fullName = "Brackenhide Hollow", shortName = "BH"},
            [3] = {fullName = "Halls of Infusion", shortName = "HoI"},
            [4] = {fullName = "Neltharus", shortName = "N"},
            [5] = {fullName = "Ruby Life Pools", shortName = "RLP"},
            [6] = {fullName = "The Azure Vault", shortName = "AV"},
            [7] = {fullName = "The Nokhud Offensive", shortName = "NO"},
            [8] = {fullName = "Uldaman: Legacy of Tyr", shortName = "ULT"}
        }
    }
}

local selectedXpac = allDungeons.DF

local diffList = {}
diffList[1] = "Heroic"
diffList[2] = "Mythic"

local function printTable(tb, spacing)
    if spacing == nil then
        spacing = ""
    end
    print(spacing .. "Entering table")
    if tb == nil then
        print("Table is nil")
        return
    end
    if type(tb) == "string" then
        print("String: " .. tb)
        return
    end

    if type(tb) == "number" then
        print("Number: " .. tostring(tb))
        return
    end

    for k, v in pairs(tb) do
        print(spacing .. "K: " .. k .. ", v: " .. tostring(v))
        if type(v) == "table" then
            printTable(v, "   " .. spacing)
        end
    end

    print(spacing .. "Leaving Table")
end
local function parseTime(time)
    time = math.floor(tonumber(time))

    -- time should be a total of 4 digits long, or 0. ie, [0] or [1000, 9999]
    if time < 0 then
        time = 0
    end

    if time < 1000 then
        while time < 1000 do
            time = time * 10
        end
    elseif time > 10000 then
        while time > 10000 do
            time = time / 10
        end
    end

    return time
end
local function PrepreToolTip(self)
    local x = self:GetRight()
    if (x >= (GetScreenWidth() / 2)) then
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    else
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    end
end
function OnGameToolTipLeave(self, motion)
    GameTooltip:Hide()
end
local function toggleShowAddon()
    if PartyLock:IsShown() then
        PartyLock:Hide()
    else
        PartyLock:Show()
    end
end
local function onRequestButtonOnHoverOver(self, motion)
    PrepreToolTip(self)
    GameTooltip:AddLine("Manually update with online guild and party members on their mythics lock outs")
    GameTooltip:Show()
end
local function dungeonNameToInt(dungeonName, dungeonList)
    for index, dungeon in pairs(dungeonList) do
        if dungeonName == dungeon.fullName then
            return index
        end
    end
    return -1
end
local function intToDungeonName(int, dungeonList)
    int = tonumber(int)
    if dungeonList[int] then
        return dungeonList[int].fullName
    end
    return "Dungeon Unknown"
end
local function difficultyToInt(diff)
    for index, difficulty in pairs(diffList) do
        if difficulty == diff then
            return index
        end
    end
    return -1
end
local function intToDifficulty(val)
    if val == nil then return nil end
    val = tonumber(val)

    if diffList[val] ~= nil then
        return diffList[val]
    end

    return nil
end
local numberGuildMembersOnlineTime
local numberGuildMembersOnline = 0
local function getNumberGuildMembersOnline()
    if numberGuildMembersOnlineTime == nil or numberGuildMembersOnlineTime + 5 < time() then
        numberGuildMembersOnlineTime = time()
        numberGuildMembersOnline = select(3, GetNumGuildMembers())
    end

    return numberGuildMembersOnline
end
local function isGuildMemberOnline(member)
    local onlineCount = getNumberGuildMembersOnline()
    if onlineCount < 1 then
        return false
    end

    for index = 1, onlineCount do
        name = GetGuildRosterInfo(index) -- name is CharName-Server
        if member == name then
            return true
        end
    end

    return false
end
local function getCurrentPlayer()
    if not CURRENTPLAYER then
        CURRENTPLAYER = UnitName("player") .. "-" .. GetRealmName()
        CURRENTPLAYER = string.gsub(CURRENTPLAYER, " ", "")
    end

    return CURRENTPLAYER
end
local function getExpansionIdByDungeonName(dungeonName)
    for xpId, xpacTable in pairs(allDungeons) do
        for index, dungeonData in ipairs(xpacTable.dungeons) do
            if dungeonName == dungeonData.fullName then
                return xpId
            end
        end
    end

    return nil
end
local updatePlayerInfoTime
local function updatePlayerInfo()
    if not updatePlayerInfoTime or updatePlayerInfoTime + 30 < time() then
        updatePlayerInfoTime = time()

        local spec = GetSpecialization()
        spec = spec and select(2, GetSpecializationInfo(spec)) or PartyLockVar.player[player].stats.spec or "<spec>"

        local instanceCount = GetNumSavedInstances()
        local player = getCurrentPlayer()
        PartyLockVar.player[player].savedDungeons[allDungeons.DF.xpac] = {}

        for i = 1, instanceCount do
            local name, _, reset, _, _, _, _, _, _, difficulty = GetSavedInstanceInfo(i)
            if reset > 0 and (difficulty == 'Mythic' or difficulty == 'Heroic') then
                local xpac = getExpansionIdByDungeonName(name)
                
                if xpac ~= nil then
                    reset = reset + time()
                    reset = math.ceil((reset / 1000) % 10000)
                    
                    if PartyLockVar.player[player].savedDungeons[xpac][difficulty] == nil then
                        PartyLockVar.player[player].savedDungeons[xpac][difficulty] = {}
                    end

                    PartyLockVar.player[player].savedDungeons[xpac][difficulty][name] = {time = reset}
                end
            end
        end

        PartyLockVar.player[player].stats.ilvl = math.floor(GetAverageItemLevel())
        PartyLockVar.player[player].stats.guild = GetGuildInfo("player")
        PartyLockVar.player[player].stats.spec = spec
    end
end
local function updatePartyMemberList()
    local realmName = string.gsub(GetRealmName(), " ", "")
    local party = GetHomePartyInfo() or {}

    PartyList = {}
    table.insert(PartyList, getCurrentPlayer())
    for i, partyMember in pairs(party) do
        local index = partyMember:find("-")

        if index == nil then
            partyMember = partyMember .. "-" .. realmName
        end

        table.insert(PartyList, partyMember)
    end
end
local function getPartyMembers()
    if not PartyList then
        updatePartyMemberList()
    end

    return PartyList
end
local function isInParty(player, party)
    for i, partyMember in pairs(party) do
        if player == partyMember then
            return true
        end
    end

    return false
end
local function stageMessage()
    local player = getCurrentPlayer()
    if player == nil or player == "" then
        return ""
    end

    local stats = player .. "," .. PartyLockVar.player[player].stats.spec
    stats = stats .. "," .. PartyLockVar.player[player].stats.ilvl..','

    local dungeonStr = ''
    --PartyLockVar.player[player].savedDungeons[xpac][difficulty][name] = {time = reset}

    for xpac, xpacData in pairs(PartyLockVar.player[player].savedDungeons) do
        for difficulty, dungeons in pairs(xpacData) do
            for dungeonName, stats in pairs(dungeons) do
                local t = math.floor(stats.time)
                if t > 0 then
                    local difficultyIndex = difficultyToInt(difficulty)
                    local dungeonIndex = dungeonNameToInt(dungeonName, allDungeons[xpac].dungeons)

                    if dungeonIndex > -1 and difficultyIndex > -1 then
                        dungeonStr = dungeonStr .. xpac .. ",".. difficultyIndex .. "," .. dungeonIndex .. "," .. tostring(math.floor(stats.time)) .. ","
                    end
                end
            end
        end
    end

    local result = stats..dungeonStr
    
    return result
end
local lastIsInGuildCheck
local function isInGuild()
    if not lastIsInGuildCheck or lastIsInGuildCheck + 30 < time() then
        lastIsInGuildCheck = time()
        playerInGuild = IsInGuild()
    end

    return playerInGuild
end
local updateGuildTime
function updateGuild()
    if (not updateGuildTime or updateGuildTime + 10 < time()) and isInGuild() then
        updateGuildTime = time()

        local msg = stageMessage()
        if not msg then
            return
        end
        C_ChatInfo.SendAddonMessage("PartyLockGuild", msg, "GUILD")
    end
end
local updatePartyTime
function updateParty()
    if not updatePartyTime or updatePartyTime + 5 < time() and IsInGroup() then
        updatePartyTime = time()
        local msg = stageMessage()
        if not msg then
            return
        end
        C_ChatInfo.SendAddonMessage("PartyLockParty", msg, "PARTY")
    end
end
function requestGuildUpdate()
    if (not PartyLockVar.requestGuildUpdateTime or PartyLockVar.requestGuildUpdateTime + 15 < time()) and isInGuild() then
        PartyLockVar.requestGuildUpdateTime = time()
        C_ChatInfo.SendAddonMessage("PartyLockGuild", "UpdateRequest", "GUILD")
    end
end
function requestPartyUpdate()
    if not PartyLockVar.requestPartyUpdateTime or PartyLockVar.requestPartyUpdateTime + 5 < time() and IsInGroup() then
        PartyLockVar.requestPartyUpdateTime = time()
        C_ChatInfo.SendAddonMessage("PartyLockParty", "UpdateRequest", "PARTY")
    end
end
local function parseIncomingPlayer(str)
    local friend, spec, ilvl, str = string.match(str, "(.-),(.-),(.-),(.*)")
    
    
    if friend == getCurrentPlayer() or not friend then
        return
    end
 
    PartyLockVar.player[friend] = {
        stats = {
            spec = spec,
            ilvl = ilvl,
            guild = nil
        },
        savedDungeons = {}
    }

    if str == nil then
        return
    end

    --PartyLockVar.player[player].savedDungeons[xpac][difficulty][name] = {time = reset}
    PartyLockVar.player[friend].savedDungeons = {}

    local temp
    while str ~= nil and strlen(str) > 1 do
        
        
        local xpac, difficultyIndex, dungeonIndex, resetTime, temp = string.match(str, "(.-),(.-),(.-),(.-),(.*)")
        str = temp
        local difficulty = intToDifficulty(difficultyIndex)
        local dungeon = intToDungeonName(dungeonIndex, allDungeons[xpac].dungeons)
       
        if xpac and allDungeons[xpac].dungeons and difficulty and dungeon then
            if PartyLockVar.player[friend].savedDungeons[xpac] == nil then                        
                PartyLockVar.player[friend].savedDungeons[xpac] = {}
            end

            if PartyLockVar.player[friend].savedDungeons[xpac][difficulty] == nil then                        
                PartyLockVar.player[friend].savedDungeons[xpac][difficulty] = {}
            end

            PartyLockVar.player[friend].savedDungeons[xpac][difficulty][dungeon] = { time = tonumber(resetTime) }            
        end
    end

    local numGuildMembers = GetNumGuildMembers()
    local guildName = GetGuildInfo("player")

    for index = 1, numGuildMembers do
        name = GetGuildRosterInfo(index)
        if friend == name then
            PartyLockVar.player[friend].stats.guild = guildName
            break
        end
    end
end
local function isAGuildMember(playerObj, guildName)
    return guildName ~= nil and playerObj.stats.guild == guildName
end
local function updateTableData(tabId)
    local difficulty

    if tabId == 1 or tabId == 3 then
        difficulty = "Mythic"
    else
        difficulty = "Heroic"
    end

    if not PartyLockVar or not PartyLockVar.player then
        return
    end

    local guildName = GetGuildInfo("player")
    local offlineColor = {r = 0.27, g = 0.38, b = 0.43, a = 1.0} -- #46626E
    local t = math.floor((time() / 1000) % 10000)
    local rowColor = {r = 1, g = 1, b = 1, a = 1}
    local rows = {}

    for player, playerObj in pairs(PartyLockVar.player) do
        local shouldShowPlayer =
        BottomTab == "Mythic Guild" and isAGuildMember(playerObj, guildName) or
        BottomTab == "Heroic Guild" and isAGuildMember(playerObj, guildName) or
        BottomTab == "Mythic Party" and isInParty(player, getPartyMembers()) or
        BottomTab == "Heroic Party" and isInParty(player, getPartyMembers()) or
        player == getCurrentPlayer()

        if shouldShowPlayer then
            local color =
                isAGuildMember(playerObj, guildName) and not isGuildMemberOnline(player) and offlineColor or rowColor

            local online = ""
            if color == rowColor then
                online = "y"
            end

            local cols = {
                {["value"] = online, ["color"] = color},
                {["value"] = playerObj.stats.ilvl, ["color"] = color},
                {["value"] = player:match("(.*)-.*") or player, ["color"] = color},
                {["value"] = playerObj.stats.spec, ["color"] = color}
            }

            for index, dungeonTable in ipairs(selectedXpac.dungeons) do
                local val = ""
                if playerObj.savedDungeons 
                and playerObj.savedDungeons[selectedXpac.xpac] 
                and playerObj.savedDungeons[selectedXpac.xpac][difficulty] 
                and playerObj.savedDungeons[selectedXpac.xpac][difficulty][dungeonTable.fullName] ~= nil
            then
                    playerObj.savedDungeons[selectedXpac.xpac][difficulty][dungeonTable.fullName].time =
                        parseTime(playerObj.savedDungeons[selectedXpac.xpac][difficulty][dungeonTable.fullName].time)

                    if playerObj.savedDungeons[selectedXpac.xpac][difficulty][dungeonTable.fullName].time > t then
                        val = "X"
                    end
                end
                table.insert(cols, {["value"] = val, ["color"] = color})
            end

            local row = {["cols"] = cols}
            table.insert(rows, row)
        end
    end

    if GuildTable ~= nil then
        GuildTable:SetData(rows)
    end
end
local function createTable()
    ScrollingTable = LibStub("ScrollingTable")
    local evenColor = {r = 0.94, g = 0.98, b = 1.0, a = 1.0}
    local evenBgColor = {r = 0.11, g = 0.16, b = 0.18, a = 1.0}
    local oddColor = {r = 0.94, g = 0.98, b = 1.0, a = 1.0} -- #2C3E45
    local oddBgColor = {r = 0.17, g = 0.24, b = 0.27, a = 1.0}
    local isEven = true

    local headers = {
        {
            ["name"] = "online",
            ["width"] = 45,
            ["align"] = "CENTER",
            ["color"] = evenColor,
            ["colorargs"] = nil,
            ["bgcolor"] = evenBgColor
        },
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
    for index, dungeonTable in ipairs(selectedXpac.dungeons) do
        dungeon = {
            ["name"] = dungeonTable.shortName,
            ["width"] = (string.len(dungeonTable.shortName) < 4 and 45) or 50,
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
    GuildTable = ScrollingTable:CreateST(headers, 20, 22, rowHighlight, PartyLock)

    if ScrollTable2 ~= nil then
        ScrollTable2:SetPoint("TOP", PartyLock, "TOP", 0, -50)
    end
end
local function playerInit()
    local fontstring, spec

    spec = GetSpecialization()
    spec = spec and select(2, GetSpecializationInfo(spec)) or "<spec>"

    PartyLockVar = PartyLockVar or {}
    PartyLockVar.player = PartyLockVar.player or {}
    PartyLockVar.player[getCurrentPlayer()] = {
        stats = {
            class = UnitClass("player"),
            spec = spec,
            ilvl = 0,
            guild = ""
        },
        savedDungeons = {}
    }

    updatePartyMemberList()
end
local function createTitle()
    local title = PartyLock:CreateFontString("$parentTitle", "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", "$parent", "TOP", 0, -2)
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE, THICKOUTLINE")
    title:SetText("|cff3D86AB Party Lock")
    title:SetWidth(400)
    title:Show()
end
local function createCloseButton()
    local btn = CreateFrame("Button", "$parentCloseButton", PartyLock, "UIMenuButtonStretchTemplate")
    btn:SetWidth(100)
    btn:SetHeight(30)
    btn:SetPoint("BOTTOM", "$parent", "BOTTOM", 0, 15)
    btn:SetText("Close")
    btn:SetScript("OnClick", toggleShowAddon)
    btn:SetScript("OnLeave", OnGameToolTipLeave)
    btn:Show()
end
local function registerMessaging()
    C_ChatInfo.RegisterAddonMessagePrefix("PartyLockParty")
    C_ChatInfo.RegisterAddonMessagePrefix("PartyLockGuild")
end
local function initGlobalVars()
    PartyLockVar = PartyLockVar or {}
    BottomTabIndex = BottomTabIndex or 1
    BottomTab = Tabs[BottomTabIndex]

    -- Hide AddOn with <Esc> key
    tinsert(UISpecialFrames, "PartyLock")
end
local function requestRaidInfo()
    if not PartyLockVar.RequestRaidInfoTime or PartyLockVar.RequestRaidInfoTime + 1 < time() then
        PartyLockVar.RequestRaidInfoTime = time()
        
        -- Requests info from server then continue to "UPDATE_INSTANCE_INFO" when server responds
        RequestRaidInfo()    
    end
end
local function onRequestButtonClick()
    requestRaidInfo()
    requestGuildUpdate()
    requestPartyUpdate()
end
local function createRequestButton()
    local btn = CreateFrame("Button", "$parentRequestButton", PartyLock, "UIMenuButtonStretchTemplate")
    btn:SetWidth(100)
    btn:SetHeight(30)
    btn:SetPoint("BOTTOMRIGHT", "$parent", "BOTTOMRIGHT", -25, 15)
    btn:SetText("Request Update")
    btn:SetScript("OnEnter", onRequestButtonOnHoverOver)
    btn:SetScript("OnLeave", OnGameToolTipLeave)
    btn:SetScript("OnClick", onRequestButtonClick)
    btn:Show()
end
local function addonInit()
    initGlobalVars()
    registerMessaging()

    createTitle()
    createCloseButton()
    createRequestButton()

    createTable()
    updateTableData(BottomTabIndex)
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

    local backdropFrame =
        CreateFrame("Frame", "PartyLockBackdrop", PartyLock, BackdropTemplateMixin and "BackdropTemplate")
    backdropFrame:SetPoint("CENTER")
    backdropFrame:SetAllPoints()
    backdropFrame:SetFrameLevel(0)
    backdropFrame:SetBackdrop(
        {
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            edgeSize = 32,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        }
    )

    backdropFrame:Show()
end
local function receiveUpdate(arg1, arg2)
    if (arg1 == "PartyLockParty" or arg1 == "PartyLockGuild") and arg2 ~= nil then
        if (arg2 == "UpdateRequest") then
            updateGuild()
            updateParty()
        elseif arg2 ~= nil and string.len(arg2) > 5 then
            parseIncomingPlayer(arg2)
            updateTableData(BottomTabIndex)
        end
    end
end
function PartyLock_OnEvent(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "PartyLock" then
        self:UnregisterEvent("ADDON_LOADED")
        addonInit()
    elseif event == "PLAYER_ENTERING_WORLD" then
        playerInit()
        requestRaidInfo()
    elseif event == "UPDATE_INSTANCE_INFO" then
        -- Called after RequestRaidInfo has been returned with data
        updatePlayerInfo()
        updateParty()
        updateGuild()
        updateTableData(BottomTabIndex)
    elseif event == "CHAT_MSG_ADDON" then
        receiveUpdate(arg1, arg2)
    elseif event == "GROUP_ROSTER_UPDATE" then
        updatePartyMemberList()
        PartyLock_BottomTab_Click()
    elseif event == "GUILD_ROSTER_UPDATE" and GuildTable ~= nil then
        GuildTable:Refresh()
    end
end
function PartyLock_OnShow(self, event, ...)
    if BottomTabIndex == nil then
        BottomTabIndex = 1
    end
    
    BottomTab = Tabs[BottomTabIndex]
    
    PanelTemplates_SetTab(PartyLock_BottomTabs, BottomTabIndex);
    updateTableData(BottomTabIndex)
end
function PartyLock_BottomTab_Click(self, event, ...)
    local id = self and self:GetID()
    if id then
        BottomTabIndex = id
        BottomTab = Tabs[id]
    end

    PanelTemplates_SetTab(PartyLock_BottomTabs, BottomTabIndex);
    updateTableData(BottomTabIndex)
end
function SlashCmdList.PARTYLOCK(msg, editbox)
    local command = msg:match("^(%S*)%s*(.-)$")
    if command == "center" then
        PartyLock:ClearAllPoints()
        PartyLock:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        PartyLock:Show()
    elseif command == "request" then
        onRequestButtonClick()
    else
        toggleShowAddon()
    end
end