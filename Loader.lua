-- Whitelist System Loader

-- Configuration
local githubUser = "TryharderKid"
local githubRepo = "Ff"
local branch = "refs/heads/main"

-- URLs for the whitelist files
local whitelistSystemUrl = string.format("https://raw.githubusercontent.com/%s/%s/%s/Whitelist.lua", githubUser, githubRepo, branch)
local whitelistDataUrl = string.format("https://raw.githubusercontent.com/%s/%s/%s/Whitelist_data.lua", githubUser, githubRepo, branch)

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

-- Main loader function
local function loadWhitelistSystem()
    -- Display loading message
    local loadingText = Instance.new("ScreenGui")
    loadingText.Name = "LoadingWhitelist"
    loadingText.Parent = game:GetService("CoreGui")
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0, 300, 0, 50)
    textLabel.Position = UDim2.new(0.5, -150, 0.5, -25)
    textLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = "Loading Whitelist System..."
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 18
    textLabel.Parent = loadingText
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = textLabel
    
    -- Fetch the whitelist system
    local whitelistSystemCode = fetchFromGitHub(whitelistSystemUrl)
    if not whitelistSystemCode then
        textLabel.Text = "Failed to load whitelist system!"
        textLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        wait(3)
        loadingText:Destroy()
        return false
    end
    
    -- Fetch the whitelist data
    local whitelistDataCode = fetchFromGitHub(whitelistDataUrl)
    if not whitelistDataCode then
        textLabel.Text = "Failed to load whitelist data!"
        textLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        wait(3)
        loadingText:Destroy()
        return false
    end
    
    -- Load the whitelist system
    local WhitelistSystem
    local success, errorOrSystem = pcall(function()
        return loadstring(whitelistSystemCode)()
    end)
    
    if not success or not errorOrSystem then
        textLabel.Text = "Error in whitelist system code!"
        textLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        warn("Error loading whitelist system: " .. tostring(errorOrSystem))
        wait(3)
        loadingText:Destroy()
        return false
    end
    
    WhitelistSystem = errorOrSystem
    
    -- Load the whitelist data
    local whitelistData
    local success, errorOrData = pcall(function()
        return loadstring(whitelistDataCode)()
    end)
    
    if not success or not errorOrData then
        textLabel.Text = "Error in whitelist data code!"
        textLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        warn("Error loading whitelist data: " .. tostring(errorOrData))
        wait(3)
        loadingText:Destroy()
        return false
    end
    
    whitelistData = errorOrData
    
    -- Update loading text
    textLabel.Text = "Verifying whitelist access..."
    
    -- Verify whitelist access
    local isWhitelisted = WhitelistSystem:VerifyAccess(whitelistData)
    
    if isWhitelisted then
        textLabel.Text = "Access granted! Loading script..."
        textLabel.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        wait(2)
        loadingText:Destroy()
        return true
    else
        -- The VerifyAccess function already handles the failure case
        -- (copying whitelist string to clipboard, kicking player, etc.)
        loadingText:Destroy()
        return false
    end
end

-- Run the loader
return loadWhitelistSystem()
