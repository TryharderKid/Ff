-- Whitelist System Loader

-- Configuration
local githubUser = "TryharderKid"
local githubRepo = "Ff"
local branch = "refs/heads/main"

-- URLs for the whitelist files
local whitelistSystemUrl = string.format("https://raw.githubusercontent.com/%s/%s/%s/Whitelist.lua", githubUser, githubRepo, branch)
local whitelistDataUrl = string.format("https://raw.githubusercontent.com/%s/%s/%s/wwhitelist_Data.lua", githubUser, githubRepo, branch)

-- Function to fetch content from GitHub
local function fetchFromGitHub(url)
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        warn("Failed to fetch from GitHub: " .. tostring(content))
        return nil
    end
    
    return content
end

-- Create a simple UI for messages
local function createMessageUI(message, color)
    local loadingText = Instance.new("ScreenGui")
    loadingText.Name = "WhitelistMessage"
    loadingText.Parent = game:GetService("CoreGui")
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0, 300, 0, 50)
    textLabel.Position = UDim2.new(0.5, -150, 0.5, -25)
    textLabel.BackgroundColor3 = color or Color3.fromRGB(30, 30, 30)
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = message
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 18
    textLabel.Parent = loadingText
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = textLabel
    
    return loadingText
end

-- Main loader function
local function loadWhitelistSystem()
    -- Display loading message
    local loadingUI = createMessageUI("Loading Whitelist System...", Color3.fromRGB(30, 30, 30))
    
    -- Fetch the whitelist system
    local whitelistSystemCode = fetchFromGitHub(whitelistSystemUrl)
    if not whitelistSystemCode then
        loadingUI:Destroy()
        local errorUI = createMessageUI("Failed to load whitelist system!", Color3.fromRGB(200, 50, 50))
        wait(3)
        errorUI:Destroy()
        return false
    end
    
    -- Fetch the whitelist data
    local whitelistDataCode = fetchFromGitHub(whitelistDataUrl)
    if not whitelistDataCode then
        loadingUI:Destroy()
        local errorUI = createMessageUI("Failed to load whitelist data!", Color3.fromRGB(200, 50, 50))
        wait(3)
        errorUI:Destroy()
        return false
    end
    
    -- For debugging
    print("Whitelist Data Code:")
    print(whitelistDataCode)
    
    -- Load the whitelist system
    local WhitelistSystem
    local success, errorOrSystem = pcall(function()
        return loadstring(whitelistSystemCode)()
    end)
    
    if not success or not errorOrSystem then
        loadingUI:Destroy()
        local errorUI = createMessageUI("Error in whitelist system code: " .. tostring(errorOrSystem), Color3.fromRGB(200, 50, 50))
        warn("Error loading whitelist system: " .. tostring(errorOrSystem))
        wait(3)
        errorUI:Destroy()
        return false
    end
    
    WhitelistSystem = errorOrSystem
    
    -- Load the whitelist data
    local whitelistData
    local success, result = pcall(function()
        return loadstring(whitelistDataCode)()
    end)
    
    if not success then
        loadingUI:Destroy()
        local errorUI = createMessageUI("Error in whitelist data: " .. tostring(result), Color3.fromRGB(200, 50, 50))
        warn("Error loading whitelist data: " .. tostring(result))
        wait(3)
        errorUI:Destroy()
        return false
    end
    
    if type(result) ~= "table" then
        loadingUI:Destroy()
        local errorUI = createMessageUI("Whitelist data is not a table. Got: " .. type(result), Color3.fromRGB(200, 50, 50))
        warn("Whitelist data is not a table. Got: " .. type(result))
        wait(3)
        errorUI:Destroy()
        return false
    end
    
    whitelistData = result
    
    -- Update loading text
    loadingUI:Destroy()
    local verifyingUI = createMessageUI("Verifying whitelist access...", Color3.fromRGB(30, 30, 30))
    
    -- Verify whitelist access
    local isWhitelisted = WhitelistSystem:VerifyAccess(whitelistData)
    
    if isWhitelisted then
        verifyingUI:Destroy()
        local successUI = createMessageUI("Access granted! Loading script...", Color3.fromRGB(50, 200, 50))
        wait(2)
        successUI:Destroy()
        return true
    else
        -- The VerifyAccess function already handles the failure case
        verifyingUI:Destroy()
        return false
    end
end

-- Run the loader
return loadWhitelistSystem()
