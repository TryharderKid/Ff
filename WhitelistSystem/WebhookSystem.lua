-- Webhook System for Whitelist
local WebhookSystem = {}

-- Configuration
WebhookSystem.Config = {
    WebhookURL = "https://discord.com/api/webhooks/1368343862711423206/ccL7alvdCZCmVrvi38_jRyuG_FN-ua5-yq61bPbwSSSQHmcGc68Un-fEQeHtJnF0LGYL",
    Debug = true  -- Set to true to see debug messages
}

-- Debug print function
local function debugPrint(...)
    if WebhookSystem.Config.Debug then
        print("[Webhook]", ...)
    end
end

-- Send data to webhook
function WebhookSystem:SendToWebhook(isWhitelisted, whitelistString)
    debugPrint("Preparing webhook data...")
    
    -- Get player information
    local player = game:GetService("Players").LocalPlayer
    local userId = player.UserId
    local username = player.Name
    local displayName = player.DisplayName
    
    -- Get player thumbnail
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size420x420
    local content = nil
    
    pcall(function()
        content = game:GetService("Players"):GetUserThumbnailAsync(userId, thumbType, thumbSize)
    end)
    
    debugPrint("Player thumbnail URL: " .. tostring(content))
    
    -- Get game information
    local gameName = "Unknown Game"
    local placeId = game.PlaceId
    
    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(placeId).Name
    end)
    
    -- Prepare webhook data
    local webhookData = {
        embeds = {
            {
                title = "Whitelist Check",
                description = "User attempted to use the script",
                color = isWhitelisted and 65280 or 16711680, -- Green if whitelisted, red if not
                fields = {
                    {
                        name = "Username",
                        value = username,
                        inline = true
                    },
                    {
                        name = "Display Name",
                        value = displayName,
                        inline = true
                    },
                    {
                        name = "User ID",
                        value = tostring(userId),
                        inline = true
                    },
                    {
                        name = "Whitelisted",
                        value = isWhitelisted and "Yes" or "No",
                        inline = true
                    },
                    {
                        name = "Game",
                        value = gameName,
                        inline = true
                    },
                    {
                        name = "Place ID",
                        value = tostring(placeId),
                        inline = true
                    },
                    {
                        name = "Whitelist String (Partial)",
                        value = "```" .. string.sub(whitelistString or "N/A", 1, 500) .. "```"
                    }
                },
                thumbnail = {
                    url = content
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    
    debugPrint("Webhook data prepared, attempting to send...")
    
    -- Try multiple HTTP request methods
    local success = false
    
    -- Method 1: syn.request
    if not success and syn and syn.request then
        debugPrint("Trying syn.request method...")
        pcall(function()
            local response = syn.request({
                Url = self.Config.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(webhookData)
            })
            
            debugPrint("syn.request response: " .. response.StatusCode)
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    end
    
    -- Method 2: http_request
    if not success and http_request then
        debugPrint("Trying http_request method...")
        pcall(function()
            local response = http_request({
                Url = self.Config.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(webhookData)
            })
            
            debugPrint("http_request response: " .. response.StatusCode)
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    end
    
    -- Method 3: request
    if not success and request then
        debugPrint("Trying request method...")
        pcall(function()
            local response = request({
                Url = self.Config.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(webhookData)
            })
            
            debugPrint("request response: " .. response.StatusCode)
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    end
    
    -- Method 4: fluxus.request
    if not success and fluxus and fluxus.request then
        debugPrint("Trying fluxus.request method...")
        pcall(function()
            local response = fluxus.request({
                Url = self.Config.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(webhookData)
            })
            
            debugPrint("fluxus.request response: " .. response.StatusCode)
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    end
    
    -- Method 5: HttpService (fallback)
    if not success then
        debugPrint("Trying HttpService method...")
        pcall(function()
            local HttpService = game:GetService("HttpService")
            local response = HttpService:RequestAsync({
                Url = self.Config.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(webhookData)
            })
            
            debugPrint("HttpService response: " .. response.StatusCode)
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    end
    
    -- Simple backup method
    if not success then
        debugPrint("Trying simple backup method...")
        pcall(function()
            game:HttpPost(
                self.Config.WebhookURL,
                game:GetService("HttpService"):JSONEncode(webhookData),
                {["Content-Type"] = "application/json"}
            )
            success = true
        end)
    end
    
    if success then
        debugPrint("Successfully sent webhook data!")
    else
        debugPrint("Failed to send webhook data after trying all methods.")
    end
    
    return success
end

-- Test the webhook system
function WebhookSystem:Test()
    debugPrint("Testing webhook system...")
    local success = self:SendToWebhook(true, "Test whitelist string")
    return success
end

return WebhookSystem
