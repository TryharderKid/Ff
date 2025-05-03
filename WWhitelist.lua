local WhitelistSystem = {}

-- Simple string hashing function compatible with Lua 5.1
local function simpleHash(str)
    local hash = 5381
    for i = 1, #str do
        hash = ((hash * 33) + string.byte(str, i)) % 2147483647
    end
    return hash
end

-- Function to generate a unique identifier
function WhitelistSystem:GenerateWhitelistString()
    -- Safe function caller
    local function safecall(func, ...)
        if type(func) == "function" then
            local success, result = pcall(func, ...)
            if success then return result end
        end
        return nil
    end
    
    -- Get HWID with multiple fallbacks
    local hwid = nil
    hwid = safecall(function() return getexecutorhwid() end)
    if not hwid then hwid = safecall(function() return gethwid() end) end
    if not hwid then hwid = safecall(function() return get_hwid() end) end
    if not hwid then hwid = safecall(function() return getexecutoridentifier() end) end
    if not hwid then hwid = "UNKNOWN_HWID" end
    
    -- Get user data
    local userId = game:GetService("Players").LocalPlayer.UserId
    
    -- Get client ID
    local clientID = "UNKNOWN_CLIENT_ID"
    pcall(function()
        clientID = game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    
    -- Create a persistent ID
    local function getPersistentID()
        local HttpService = game:GetService("HttpService")
        local filename = "lurnai_persistent_id.dat"
        
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
    
    -- Get player name
    local playerName = game:GetService("Players").LocalPlayer.Name
    
    -- Get executor name
    local executorName = "Unknown"
    pcall(function()
        if identifyexecutor then executorName = identifyexecutor() end
        if executorName == "Unknown" and getexecutorname then executorName = getexecutorname() end
    end)
    
    -- Format the whitelist string with all identifiers
    local whitelistString = string.format("%s_%s_%s_%s_%s_%s", 
        hwid, 
        tostring(userId), 
        tostring(persistentID),
        tostring(clientID),
        playerName,
        executorName
    )
    
    -- Apply a simple obfuscation
    local function obfuscate(str)
        local result = "Lurnai_"
        local hash = simpleHash(str)
        result = result .. tostring(hash) .. "_"
        
        for i = 1, #str do
            local char = string.sub(str, i, i)
            local byte = string.byte(char)
            result = result .. tostring(byte) .. "_"
        end
        
        result = result .. "Lurnai"
        return result
    end
    
    return obfuscate(whitelistString)
end

-- Function to check if the user is whitelisted
function WhitelistSystem:CheckWhitelist(whitelistData)
    -- Generate the user's whitelist string
    local userWhitelistString = self:GenerateWhitelistString()
    
    -- Print for debugging
    print("Generated whitelist string:", userWhitelistString)
    
    -- Check if the user's whitelist string is in the whitelist
    for _, whitelistedString in ipairs(whitelistData) do
        if whitelistedString == userWhitelistString then
            return true
        end
    end
    
    return false
end

-- Function to handle whitelist verification
function WhitelistSystem:VerifyAccess(whitelistData)
    local isWhitelisted = self:CheckWhitelist(whitelistData)
    
    if isWhitelisted then
        print("Access granted! You are whitelisted.")
        return true
    else
        print("Access denied! You are not whitelisted.")
        -- Copy the user's whitelist string to clipboard for easy whitelisting
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
        
        -- Kick the player with a delay to allow seeing debug info
        pcall(function()
            wait(5) -- Wait 5 seconds to see debug output
            game.Players.LocalPlayer:Kick("You are not whitelisted. Please contact the developer.")
        end)
        
        return false
    end
end

return WhitelistSystem
