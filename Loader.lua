-- Whitelist System Loader with Enhanced Security

-- Configuration
local githubUser = "TryharderKid"
local githubRepo = "Ff"
local branch = "refs/heads/main"

-- URLs for the whitelist files
local securityUrl = string.format("https://raw.githubusercontent.com/%s/%s/%s/Security.lua", githubUser, githubRepo, branch)
local whitelistSystemUrl = string.format("https://raw.githubusercontent.com/%s/%s/%s/Whitelist.lua", githubUser, githubRepo, branch)
local whitelistDataUrl = string.format("https://raw.githubusercontent.com/%s/%s/%s/whitelist_Data.lua", githubUser, githubRepo, branch)

-- List of all URLs that will be accessed
local allUrls = {securityUrl, whitelistSystemUrl, whitelistDataUrl}

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
    local loadingUI = createMessageUI("Loading Security System...", Color3.fromRGB(30, 30, 30))
    
    -- First, fetch and initialize the security system
    local securityCode = fetchFromGitHub(securityUrl)
    if not securityCode then
        loadingUI:Destroy()
        local errorUI = createMessageUI("Failed to load security system!", Color3.fromRGB(200, 50, 50))
        wait(3)
        errorUI:Destroy()
        
        -- Attempt to kick the player as a fallback
        pcall(function()
            game.Players.LocalPlayer:Kick("Failed to load security system. Please try again later.")
        end)
        
        return false
    end
    
    -- Load the security system
    local Security
    local success, errorOrSecurity = pcall(function()
        return loadstring(securityCode)()
    end)
    
    if not success or not errorOrSecurity then
        loadingUI:Destroy()
        local errorUI = createMessageUI("Error in security system code: " .. tostring(errorOrSecurity), Color3.fromRGB(200, 50, 50))
        warn("Error loading security system: " .. tostring(errorOrSecurity))
        wait(3)
        errorUI:Destroy()
        
        -- Attempt to kick the player as a fallback
        pcall(function()
            game.Players.LocalPlayer:Kick("Error in security system. Please try again later.")
        end)
        
        return false
    end
    
    Security = errorOrSecurity
    
    -- Initialize the security system
    if not Security:Initialize(githubUser, githubRepo, allUrls) then
        loadingUI:Destroy()
        -- Security system will handle the punishment
        return false
    end
    
    loadingUI:Destroy()
    loadingUI = createMessageUI("Loading Whitelist System...", Color3.fromRGB(30, 30, 30))
    
    -- Fetch the whitelist system
    local whitelistSystemCode = fetchFromGitHub(whitelistSystemUrl)
    if not whitelistSystemCode then
        loadingUI:Destroy()
        Security:PunishUser("Failed to load whitelist system")
        return false
    end
    
    -- Fetch the whitelist data
    local whitelistDataCode = fetchFromGitHub(whitelistDataUrl)
    if not whitelistDataCode then
        loadingUI:Destroy()
        Security:PunishUser("Failed to load whitelist data")
        return false
    end
    
    -- Load the whitelist system
    local WhitelistSystem
    local success, errorOrSystem = pcall(function()
        return loadstring(whitelistSystemCode)()
    end)
    
    if not success or not errorOrSystem then
        loadingUI:Destroy()
        Security:PunishUser("Error in whitelist system code: " .. tostring(errorOrSystem))
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
        Security:PunishUser("Error in whitelist data: " .. tostring(result))
        return false
    end
    
    if type(result) ~= "table" then
        loadingUI:Destroy()
        Security:PunishUser("Whitelist data is not a table. Got: " .. type(result))
        return false
    end
    
    whitelistData = result
    
    -- Update loading text
    loadingUI:Destroy()
    local verifyingUI = createMessageUI("Verifying whitelist access...", Color3.fromRGB(30, 30, 30))
    
    -- Set up a watchdog to detect if the verification process is taking too long
    local verificationComplete = false
    coroutine.wrap(function()
        wait(10) -- Wait 10 seconds
        if not verificationComplete then
            Security:PunishUser("Whitelist verification timeout - possible tampering")
        end
    end)()
    
    -- Verify whitelist access
    local isWhitelisted = WhitelistSystem:VerifyAccess(whitelistData)
    verificationComplete = true
    
    if isWhitelisted then
        verifyingUI:Destroy()
        local successUI = createMessageUI("Access granted! Loading script...", Color3.fromRGB(50, 200, 50))
        wait(2)
        successUI:Destroy()
        
        -- Set up continuous security monitoring
        coroutine.wrap(function()
            while wait(5) do
                if Security:DetectTampering() then
                    Security:RestoreAllFunctions()
                    Security:PunishUser("Ongoing tampering with security functions detected")
                    break
                end
            end
        end)()
        
        return true
    else
        -- The VerifyAccess function already handles the failure case
        verifyingUI:Destroy()
        
        -- Additional security measures for non-whitelisted users
        Security:PunishUser("Not whitelisted")
        return false
    end
end

-- Run the loader with error handling
local success, result = pcall(loadWhitelistSystem)
if not success then
    -- If the loader itself errors, attempt to kick the player
    warn("Critical error in whitelist loader: " .. tostring(result))
    pcall(function()
        game.Players.LocalPlayer:Kick("Critical error in whitelist system. Please try again later.")
    end)
    return false
end

return result
