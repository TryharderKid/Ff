local WhitelistSystem = {}

-- Function to generate the whitelist string with fixed pattern insertion
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
    
    -- Create a persistent ID
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
    
    -- Get player name
    local playerName = game:GetService("Players").LocalPlayer.Name
    
    -- Get executor name
    local executorName = "Unknown"
    pcall(function()
        if identifyexecutor then executorName = identifyexecutor() end
        if executorName == "Unknown" and getexecutorname then executorName = getexecutorname() end
    end)
    
    -- Format the whitelist string
    local whitelistString = string.format("%s_%s_%s_%s_%s", hwid, tostring(userId), persistentID, "0", executorName)
    
    -- Fixed pattern insertion
    local function obfuscateWithFixedPattern(str)
        local result = "Lurnai_On_Top_You_Kids_"
        
        for i = 1, #str do
            local char = string.sub(str, i, i)
            
            -- If it's a number, add "1" after it
            if string.match(char, "%d") then
                result = result .. char .. "_1_"
            -- If it's a letter, add "a" after it
            elseif string.match(char, "%a") then
                result = result .. char .. "_a_"
            -- For any other character, just add it
            else
                result = result .. char .. "_"
            end
        end
        
        result = result .. "Lurnai_On_Top_You_Kids_"
        return result
    end
    
    -- Apply the obfuscation to the entire string
    local obfuscatedString = obfuscateWithFixedPattern(whitelistString)
    
    return obfuscatedString
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
        
        -- Kick the player
        pcall(function()
            game.Players.LocalPlayer:Kick("You are not whitelisted. Please contact the developer.")
        end)
        
        return false
    end
end

return WhitelistSystem
