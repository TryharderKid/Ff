local Security = {}

-- Store original functions to restore them if they're hooked
local originalFunctions = {}

-- Function to capture and store original functions
function Security:CaptureOriginalFunctions()
    -- Store original functions that might be hooked
    pcall(function()
        originalFunctions = {
            kick = game.Players.LocalPlayer.Kick,
            httpGet = game.HttpGet,
            httpGetAsync = game.HttpGetAsync
        }
    end)
    
    return self
end

-- Function to restore original functions if they've been modified
function Security:RestoreFunction(funcName)
    if originalFunctions[funcName] then
        -- For regular functions
        if funcName == "kick" then
            game.Players.LocalPlayer.Kick = originalFunctions.kick
        elseif funcName == "httpGet" then
            game.HttpGet = originalFunctions.httpGet
        elseif funcName == "httpGetAsync" then
            game.HttpGetAsync = originalFunctions.httpGetAsync
        end
    end
    
    return self
end

-- Function to restore all original functions
function Security:RestoreAllFunctions()
    for funcName, _ in pairs(originalFunctions) do
        self:RestoreFunction(funcName)
    end
    
    return self
end

-- Function to verify GitHub URLs
function Security:VerifyGitHubUrls(urls, allowedUser, allowedRepo)
    for _, url in pairs(urls) do
        -- Check if the URL is from GitHub
        if not string.match(url, "https://raw%.githubusercontent%.com/") then
            return false
        end
        
        -- Check if the URL is from the allowed user and repo
        local pattern = string.format("https://raw%.githubusercontent%.com/%s/%s/", allowedUser, allowedRepo)
        if not string.match(url, pattern) then
            return false
        end
    end
    
    return true
end

-- Function to detect tampering with the whitelist system
function Security:DetectTampering()
    -- Check if kick function has been tampered with
    local kickFunction = game.Players.LocalPlayer.Kick
    if kickFunction ~= originalFunctions.kick then
        return true
    end
    
    -- Check if HTTP functions have been tampered with
    if game.HttpGet ~= originalFunctions.httpGet or game.HttpGetAsync ~= originalFunctions.httpGetAsync then
        return true
    end
    
    return false
end

-- Function to enforce security measures
function Security:EnforceSecurity(allowedGitHubUser, allowedGitHubRepo, urls)
    -- Verify GitHub URLs
    if not self:VerifyGitHubUrls(urls, allowedGitHubUser, allowedGitHubRepo) then
        self:PunishUser("Unauthorized GitHub repository detected")
        return false
    end
    
    return true
end

-- Function to punish users who try to bypass security
function Security:PunishUser(reason)
    -- Log the violation
    warn("SECURITY VIOLATION: " .. reason)
    
    -- Kick the player
    pcall(function()
        self:RestoreFunction("kick")
        game.Players.LocalPlayer:Kick("\n\nSECURITY VIOLATION\n" .. reason .. "\n\nYour attempt to bypass security has been logged.")
    end)
end

-- Initialize security system
function Security:Initialize(allowedGitHubUser, allowedGitHubRepo, urls)
    self:CaptureOriginalFunctions()
    return self:EnforceSecurity(allowedGitHubUser, allowedGitHubRepo, urls)
end

return Security
