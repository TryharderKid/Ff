local WhitelistSystem = {}

function WhitelistSystem:GenerateWhitelistString()
    local function safecall(func, ...)
        if type(func) == "function" then
            local success, result = pcall(func, ...)
            if success then return result end
        end
        return nil
    end
    
    local hwid = nil
    hwid = safecall(function() return getexecutorhwid() end)
    if not hwid then hwid = safecall(function() return gethwid() end) end
    if not hwid then hwid = safecall(function() return get_hwid() end) end
    if not hwid then hwid = safecall(function() return getexecutoridentifier() end) end
    if not hwid then hwid = "UNKNOWN_HWID" end
    
    local function sha256(str)
        local result = ""
        for i = 1, #str do
            local byte = string.byte(str, i)
            result = result .. string.format("%02x", byte)
        end
        while #result < 64 do
            result = result .. "0"
        end
        return result:sub(1, 64)
    end
    
    local userId = game:GetService("Players").LocalPlayer.UserId
    
    local function getPersistentID()
        local HttpService = game:GetService("HttpService")
        local filename = "persistent_id.dat"
        
        local existingID = nil
        pcall(function()
            if readfile then existingID = readfile(filename) end
        end)
        
        if existingID and #existingID > 10 then
            return existingID
        end
        
        local newID = HttpService:GenerateGUID(false)
        pcall(function()
            if writefile then writefile(filename, newID) end
        end)
        
        return newID
    end
    
    local persistentID = getPersistentID()
    local placeID = game.PlaceId
    local clientID = game:GetService("RbxAnalyticsService"):GetClientId()
    
    local UserInputService = game:GetService("UserInputService")
    local isPc = UserInputService.KeyboardEnabled and 500 or 0
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and 1000 or 0
    
    local playerName = game:GetService("Players").LocalPlayer.Name
    
    local executorName = "Unknown"
    pcall(function()
        if identifyexecutor then executorName = identifyexecutor() end
        if executorName == "Unknown" and getexecutorname then executorName = getexecutorname() end
    end)
    
    local obfuscatedHWID = sha256(hwid)
    
    local whitelistString = string.format(
        "%s_%s_%s_%s_%s_%s_%s_%s_%s",
        obfuscatedHWID,
        tostring(userId),
        tostring(persistentID),
        tostring(placeID),
        tostring(clientID),
        tostring(isPc),
        tostring(isMobile),
        playerName,
        executorName
    )
    
    -- Fixed pattern insertion (as requested)
    local function obfuscateWithFixedPattern(str)
        local result = "Lurnai_On_Top_You_Kids_"
        
        for i = 1, #str do
            local char = string.sub(str, i, i)
            
            if string.match(char, "%d") then
                result = result .. char .. "_1_"
            elseif string.match(char, "%a") then
                result = result .. char .. "_a_"
            else
                result = result .. char .. "_"
            end
        end
        
        result = result .. "Lurnai_On_Top_You_Kids_"
        return result
    end
    
    local obfuscatedString = obfuscateWithFixedPattern(whitelistString)
    
    return obfuscatedString
end

function WhitelistSystem:CheckWhitelist(whitelistData)
    local userWhitelistString = self:GenerateWhitelistString()
    
    for _, whitelistedString in ipairs(whitelistData) do
        if whitelistedString == userWhitelistString then
            return true
        end
    end
    
    return false
end

function WhitelistSystem:VerifyAccess(whitelistData)
    local isWhitelisted = self:CheckWhitelist(whitelistData)
    
    if isWhitelisted then
        print("Access granted! You are whitelisted.")
        return true
    else
        print("Access denied! You are not whitelisted.")
        pcall(function()
            local userString = self:GenerateWhitelistString()
            if setclipboard then
                setclipboard(userString)
                print("Your whitelist string has been copied to clipboard. Contact the developer to get whitelisted.")
            elseif writeclipboard then
                writeclipboard(userString)
                print("Your whitelist string has been copied to clipboard. Contact the developer to get whitelisted.")
            else
                print("Your whitelist string: " .. userString)
                print("Contact the developer with this string to get whitelisted.")
            end
        end)
        
        pcall(function()
            game.Players.LocalPlayer:Kick("You are not whitelisted. Please contact the developer.")
        end)
        
        return false
    end
end

return WhitelistSystem

