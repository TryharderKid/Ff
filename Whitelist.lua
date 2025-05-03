local WhitelistSystem = {}

-- SHA256 implementation (pure Lua)
-- Credit: Roberto Ierusalimschy
local function sha256(msg)
    local function band(x, y) return x & y end
    local function rshift(x, y) return x >> y end
    local function bxor(x, y) return x ~ y end
    local function bnot(x) return ~x end
    local function rrotate(x, y) return rshift(x, y) | ((x) << (32 - y)) end
    
    local k = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
        0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
        0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
        0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
        0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
        0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
        0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
        0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
        0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    }
    
    local function preprocess(msg)
        local len = #msg
        local bits = len * 8
        msg = msg .. string.char(0x80)
        
        while (#msg % 64) ~= 56 do
            msg = msg .. string.char(0)
        end
        
        local hi, lo = math.floor(bits / 0x100000000), bits % 0x100000000
        msg = msg .. string.char(
            rshift(hi, 24) % 256, rshift(hi, 16) % 256, rshift(hi, 8) % 256, hi % 256,
            rshift(lo, 24) % 256, rshift(lo, 16) % 256, rshift(lo, 8) % 256, lo % 256
        )
        
        return msg
    end
    
    local function bytes_to_w32(a, b, c, d)
        return (a * 0x1000000) + (b * 0x10000) + (c * 0x100) + d
    end
    
    local function w32_to_bytes(i)
        return math.floor(i / 0x1000000) % 0x100,
               math.floor(i / 0x10000) % 0x100,
               math.floor(i / 0x100) % 0x100,
               i % 0x100
    end
    
    local function bytes_to_string(bytes)
        local result = ""
        for i = 1, #bytes do
            result = result .. string.char(bytes[i])
        end
        return result
    end
    
    local function digest(msg)
        msg = preprocess(msg)
        
        local h0 = 0x6a09e667
        local h1 = 0xbb67ae85
        local h2 = 0x3c6ef372
        local h3 = 0xa54ff53a
        local h4 = 0x510e527f
        local h5 = 0x9b05688c
        local h6 = 0x1f83d9ab
        local h7 = 0x5be0cd19
        
        local w = {}
        
        for i = 1, #msg, 64 do
            for j = 1, 16 do
                local offset = i + (j - 1) * 4 - 1
                w[j] = bytes_to_w32(msg:byte(offset + 1, offset + 4))
            end
            
            for j = 17, 64 do
                local s0 = bxor(bxor(rrotate(w[j - 15], 7), rrotate(w[j - 15], 18)), rshift(w[j - 15], 3))
                local s1 = bxor(bxor(rrotate(w[j - 2], 17), rrotate(w[j - 2], 19)), rshift(w[j - 2], 10))
                w[j] = (w[j - 16] + s0 + w[j - 7] + s1) % 0x100000000
            end
            
            local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7
            
            for j = 1, 64 do
                local S1 = bxor(bxor(rrotate(e, 6), rrotate(e, 11)), rrotate(e, 25))
                local ch = bxor(band(e, f), band(bnot(e), g))
                local temp1 = (h + S1 + ch + k[j] + w[j]) % 0x100000000
                local S0 = bxor(bxor(rrotate(a, 2), rrotate(a, 13)), rrotate(a, 22))
                local maj = bxor(bxor(band(a, b), band(a, c)), band(b, c))
                local temp2 = (S0 + maj) % 0x100000000
                
                h = g
                g = f
                f = e
                e = (d + temp1) % 0x100000000
                d = c
                c = b
                b = a
                a = (temp1 + temp2) % 0x100000000
            end
            
            h0 = (h0 + a) % 0x100000000
            h1 = (h1 + b) % 0x100000000
            h2 = (h2 + c) % 0x100000000
            h3 = (h3 + d) % 0x100000000
            h4 = (h4 + e) % 0x100000000
            h5 = (h5 + f) % 0x100000000
            h6 = (h6 + g) % 0x100000000
            h7 = (h7 + h) % 0x100000000
        end
        
        local result = ""
        for _, h in ipairs({h0, h1, h2, h3, h4, h5, h6, h7}) do
            result = result .. string.format("%08x", h)
        end
        
        return result
    end
    
    return digest(msg)
end

-- Anti-tamper protection
local function protectFunction(func)
    -- Check if newcclosure is available
    if newcclosure then
        return newcclosure(func)
    end
    return func
end

-- Salt for additional security
local SALT = "Lurnai_Security_Salt_8372648"

-- Function to generate the whitelist hash
WhitelistSystem.GenerateWhitelistHash = protectFunction(function()
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
    
    -- Combine all identifiers with salt
    local identifierString = string.format("%s|%s|%s|%s|%s|%s|%s", 
        hwid, 
        tostring(userId), 
        tostring(persistentID),
        tostring(clientID),
        playerName,
        executorName,
        SALT
    )
    
    -- Hash the identifier string
    local hashedIdentifier = sha256(identifierString)
    
    -- Add a prefix for verification
    return "LURNAI_" .. hashedIdentifier
end)

-- Function to check if the user is whitelisted
WhitelistSystem.CheckWhitelist = protectFunction(function(self, whitelistData)
    -- Generate the user's whitelist hash
    local userHash = self.GenerateWhitelistHash()
    
    -- Print for debugging
    print("Generated whitelist hash:", userHash)
    
    -- Check if the user's hash is in the whitelist
    for _, whitelistedHash in ipairs(whitelistData) do
        if whitelistedHash == userHash then
            return true
        end
    end
    
    return false
end)

-- Function to handle whitelist verification
WhitelistSystem.VerifyAccess = protectFunction(function(self, whitelistData)
    local isWhitelisted = self:CheckWhitelist(whitelistData)
    
    if isWhitelisted then
        print("Access granted! You are whitelisted.")
        return true
    else
        print("Access denied! You are not whitelisted.")
        -- Copy the user's whitelist hash to clipboard for easy whitelisting
        pcall(function()
            local userHash = self.GenerateWhitelistHash()
            if setclipboard then
                setclipboard(userHash)
                print("Your whitelist hash has been copied to clipboard. Contact the developer to get whitelisted.")
            elseif writeclipboard then
                writeclipboard(userHash)
                print("Your whitelist hash has been copied to clipboard. Contact the developer to get whitelisted.")
            else
                print("Your whitelist hash: " .. userHash)
                print("Contact the developer with this hash to get whitelisted.")
            end
        end)
        
        -- Kick the player with a delay to allow seeing debug info
        pcall(function()
            wait(5) -- Wait 5 seconds to see debug output
            game.Players.LocalPlayer:Kick("You are not whitelisted. Please contact the developer.")
        end)
        
        return false
    end
end)

-- Anti-tamper check
local originalFunctions = {
    GenerateWhitelistHash = WhitelistSystem.GenerateWhitelistHash,
    CheckWhitelist = WhitelistSystem.CheckWhitelist,
    VerifyAccess = WhitelistSystem.VerifyAccess
}

-- Set up a metatable to prevent modification
setmetatable(WhitelistSystem, {
    __index = function(t, k)
        local value = rawget(t, k)
        if value == nil and originalFunctions[k] then
            error("Attempt to access tampered function: " .. k)
        end
        return value
    end,
    __newindex = function(t, k, v)
        if originalFunctions[k] then
            error("Attempt to modify whitelist system")
        end
        rawset(t, k, v)
    end
})

return WhitelistSystem
