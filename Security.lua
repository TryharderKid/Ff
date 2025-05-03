local Security = {}

-- Store original functions to restore them if they're hooked
local originalFunctions = {}

-- Function to capture and store original functions
function Security:CaptureOriginalFunctions()
    -- Store original functions that might be hooked
    originalFunctions = {
        kick = game.Players.LocalPlayer.Kick,
        httpGet = game.HttpGet,
        httpGetAsync = game.HttpGetAsync,
        destroy = game.Destroy,
        shutdown = game:GetService("RunService").Close,
        teleport = game:GetService("TeleportService").TeleportToPlaceInstance,
        fireServer = Instance.new("RemoteEvent").FireServer,
        invokeServer = Instance.new("RemoteFunction").InvokeServer,
        newIndex = getrawmetatable(game).__newindex,
        namecall = getrawmetatable(game).__namecall,
        index = getrawmetatable(game).__index
    }
    
    -- Store original metatable functions
    pcall(function()
        local mt = getrawmetatable(game)
        if mt and typeof(mt) == "table" then
            setreadonly(mt, false)
            originalFunctions.namecall = mt.__namecall
            originalFunctions.index = mt.__index
            originalFunctions.newindex = mt.__newindex
            setreadonly(mt, true)
        end
    end)
    
    return self
end

-- Function to restore original functions if they've been modified
function Security:RestoreFunction(funcName)
    if originalFunctions[funcName] then
        -- Handle metatable functions differently
        if funcName == "namecall" or funcName == "index" or funcName == "newindex" then
            pcall(function()
                local mt = getrawmetatable(game)
                if mt and typeof(mt) == "table" then
                    setreadonly(mt, false)
                    mt["__" .. funcName] = originalFunctions[funcName]
                    setreadonly(mt, true)
                end
            end)
        else
            -- For regular functions
            local parts = funcName:split(".")
            local obj = game
            
            -- Navigate to the parent object
            for i = 1, #parts - 1 do
                obj = obj[parts[i]]
            end
            
            -- Restore the function
            obj[parts[#parts]] = originalFunctions[funcName]
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
    
    -- Check if metatable functions have been tampered with
    local mt = getrawmetatable(game)
    if mt and typeof(mt) == "table" then
        if mt.__namecall ~= originalFunctions.namecall or 
           mt.__index ~= originalFunctions.index or 
           mt.__newindex ~= originalFunctions.newindex then
            return true
        end
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
    
    -- Detect tampering
    if self:DetectTampering() then
        -- Restore original functions
        self:RestoreAllFunctions()
        self:PunishUser("Tampering with security functions detected")
        return false
    end
    
    -- Set up anti-tampering hooks
    self:SetupAntiTamperingHooks()
    
    return true
end

-- Function to set up anti-tampering hooks
function Security:SetupAntiTamperingHooks()
    -- Create a thread that periodically checks for tampering
    coroutine.wrap(function()
        while wait(1) do
            if self:DetectTampering() then
                self:RestoreAllFunctions()
                self:PunishUser("Ongoing tampering with security functions detected")
                break
            end
        end
    end)()
    
    -- Hook the metatable to prevent function replacement
    pcall(function()
        local mt = getrawmetatable(game)
        if mt and typeof(mt) == "table" then
            setreadonly(mt, false)
            
            -- Store original functions
            local oldNamecall = mt.__namecall
            local oldNewindex = mt.__newindex
            
            -- Hook __namecall to prevent kick function from being bypassed
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                -- Protect kick function
                if method == "Kick" and self == game.Players.LocalPlayer then
                    return oldNamecall(self, ...)
                end
                
                -- Protect HttpGet function
                if (method == "HttpGet" or method == "HttpGetAsync") and self == game then
                    local url = args[1]
                    if url and typeof(url) == "string" then
                        -- Check if the URL is allowed
                        if not Security:VerifyGitHubUrls({url}, allowedGitHubUser, allowedGitHubRepo) then
                            Security:PunishUser("Unauthorized HTTP request detected")
                            return nil
                        end
                    end
                end
                
                return oldNamecall(self, ...)
            end)
            
            -- Hook __newindex to prevent function replacement
            mt.__newindex = newcclosure(function(self, key, value)
                -- Prevent modification of critical functions
                if (self == game.Players.LocalPlayer and key == "Kick") or
                   (self == game and (key == "HttpGet" or key == "HttpGetAsync")) then
                    Security:PunishUser("Attempt to modify protected function detected")
                    return
                end
                
                return oldNewindex(self, key, value)
            end)
            
            setreadonly(mt, true)
        end
    end)
    
    return self
end

-- Function to punish users who try to bypass security
function Security:PunishUser(reason)
    -- Log the violation
    warn("SECURITY VIOLATION: " .. reason)
    
    -- Create a list of punishment functions
    local punishments = {
        -- Kick the player
        function()
            self:RestoreFunction("kick")
            game.Players.LocalPlayer:Kick("\n\nSECURITY VIOLATION\n" .. reason .. "\n\nYour attempt to bypass security has been logged.")
        end,
        
        -- Crash the game
        function()
            -- Method 1: Infinite recursion
            local function crashRecursion(depth)
                if depth > 1000 then return end
                crashRecursion(depth + 1)
            end
            crashRecursion(1)
        end,
        
        -- Method 2: Memory exhaustion
        function()
            local data = {}
            for i = 1, 1000000 do
                data[i] = string.rep("crash", 1000)
            end
        end,
        
        -- Method 3: Infinite loop
        function()
            while true do end
        end,
        
        -- Method 4: Break the game's UI
        function()
            for i = 1, 100 do
                for _, v in pairs(game:GetDescendants()) do
                    pcall(function()
                        v:Destroy()
                    end)
                end
            end
        end,
        
        -- Method 5: Teleport to invalid place
        function()
            game:GetService("TeleportService"):Teleport(0, game.Players.LocalPlayer)
        end
    }
    
    -- Execute all punishments in separate threads
    for _, punishment in ipairs(punishments) do
        coroutine.wrap(function()
            pcall(punishment)
        end)()
    end
    
    -- As a last resort, try to shut down the game
    pcall(function()
        game:Shutdown()
    end)
end

-- Initialize security system
function Security:Initialize(allowedGitHubUser, allowedGitHubRepo, urls)
    self:CaptureOriginalFunctions()
    return self:EnforceSecurity(allowedGitHubUser, allowedGitHubRepo, urls)
end

return Security
