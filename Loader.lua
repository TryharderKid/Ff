-- Whitelist System Loader with Enhanced Security

-- Configuration
local githubUser = "TryharderKid"
local githubRepo = "Ff"
local branch = "main"

-- URLs for the whitelist files
local whitelistSystemUrl = string.format("https://raw.githubusercontent.com/%s/%s/%s/Whitelist.lua", githubUser, githubRepo, branch)
local whitelistDataUrl = string.format("https://raw.githubusercontent.com/%s/%s/%s/whitelist_Data.lua", githubUser, githubRepo, branch)

-- Function to fetch content from GitHub with retry
local function fetchFromGitHub(url, retries)
    retries = retries or 3
    local success, content
    
    for i = 1, retries do
        success, content = pcall(function()
            return game:HttpGet(url)
        end)
        
        if success and content and #content > 100 then
            return content
        end
        
        -- Wait before retrying
        wait(1)
    end
    
    return nil
end

-- Anti-tamper protection
local function secureLoad(code)
    local env = getfenv(0)
    local secureEnv = setmetatable({}, {
        __index = function(_, key)
            return env[key]
        end
    })
    
    local func, err = loadstring(code)
    if not func then
        error("Failed to load code: " .. tostring(err))
    end
    
    setfenv(func, secureEnv)
    return func()
end

-- Load the whitelist system
local whitelistSystemCode = fetchFromGitHub(whitelistSystemUrl)
if not whitelistSystemCode then
    error("Failed to fetch whitelist system. Please check your internet connection.")
end

local WhitelistSystem = secureLoad(whitelistSystemCode)

-- Load the whitelist data
local whitelistDataCode = fetchFromGitHub(whitelistDataUrl)
if not whitelistDataCode then
    error("Failed to fetch whitelist data. Please check your internet connection.")
end

local whitelistData = secureLoad(whitelistDataCode)

-- Verify the user's access
local hasAccess = WhitelistSystem:VerifyAccess(whitelistData)

if hasAccess then
    -- User is whitelisted, load the main script
    print("Whitelist verification successful! Loading main script...")
    
    -- Load your main script here
    local mainScriptUrl = string.format("https://raw.githubusercontent.com/%s/%s/%s/main.lua", githubUser, githubRepo, branch)
    local mainScriptCode = fetchFromGitHub(mainScriptUrl)
    
    if mainScriptCode then
        secureLoad(mainScriptCode)
    else
        error("Failed to load main script. Please try again later.")
    end
else
    -- User is not whitelisted
    print("Whitelist verification failed. Access denied.")
end
