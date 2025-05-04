-- Webhook System
local WebhookSystem = {}

-- Configuration
WebhookSystem.Config = {
    WebhookURL = "https://discord.com/api/webhooks/1368393336183849085/hd-r2quKsj1_nw5YK1JEBHlpktkTVlGJH_hIB4W5aBJyL_Ik3WdtW16mZ_kU-avGYKkI",
    PingUserID = "1342535168002359419",
    Debug = true
}

-- Debug print function
local function webhookDebugPrint(...)
    if WebhookSystem.Config.Debug then
        print("[Webhook]", ...)
    end
end

-- Function to send a simple webhook message
function WebhookSystem:SendSimpleMessage(message)
    webhookDebugPrint("Sending simple message: " .. message)
    
    local webhookData = {
        content = message
    }
    
    local success = false
    
    -- Method 1: http_request
    if not success and http_request then
        webhookDebugPrint("Trying http_request method...")
        pcall(function()
            local response = http_request({
                Url = self.Config.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(webhookData)
            })
            
            webhookDebugPrint("http_request response: " .. response.StatusCode)
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    end
    
    -- Method 2: syn.request
    if not success and syn and syn.request then
        webhookDebugPrint("Trying syn.request method...")
        pcall(function()
            local response = syn.request({
                Url = self.Config.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(webhookData)
            })
            
            webhookDebugPrint("syn.request response: " .. response.StatusCode)
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    end
    
    -- Method 3: request
    if not success and request then
        webhookDebugPrint("Trying request method...")
        pcall(function()
            local response = request({
                Url = self.Config.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(webhookData)
            })
            
            webhookDebugPrint("request response: " .. response.StatusCode)
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    end
    
    -- Method 4: HttpService (fallback)
    if not success then
        webhookDebugPrint("Trying HttpService method...")
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
            
            webhookDebugPrint("HttpService response: " .. response.StatusCode)
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    end
    
    return success
end

-- Send data to webhook step by step
function WebhookSystem:SendToWebhook(isWhitelisted, whitelistString, executorName)
    webhookDebugPrint("Starting step-by-step webhook process...")
    
    -- Get player information
    local player = game:GetService("Players").LocalPlayer
    local userId = player.UserId
    local username = player.Name
    local displayName = player.DisplayName
    
    -- Get game information
    local gameName = "Unknown Game"
    local placeId = game.PlaceId
    
    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(placeId).Name
    end)
    
    -- Step 1: Send a test message
    if self:SendSimpleMessage("Whitelist System Test Message") then
        webhookDebugPrint("Test message sent successfully!")
    else
        webhookDebugPrint("Failed to send test message, webhook may be invalid")
        return false
    end
    
    -- Step 2: Send username
    if self:SendSimpleMessage("Username: " .. username) then
        webhookDebugPrint("Username sent successfully!")
    else
        webhookDebugPrint("Failed to send username")
        return false
    end
    
    -- Step 3: Send display name
    if self:SendSimpleMessage("Display Name: " .. displayName) then
        webhookDebugPrint("Display name sent successfully!")
    else
        webhookDebugPrint("Failed to send display name")
        return false
    end
    
    -- Step 4: Send user ID
    if self:SendSimpleMessage("User ID: " .. userId) then
        webhookDebugPrint("User ID sent successfully!")
    else
        webhookDebugPrint("Failed to send user ID")
        return false
    end
    
    -- Step 5: Send game info
    if self:SendSimpleMessage("Game: " .. gameName .. " (Place ID: " .. placeId .. ")") then
        webhookDebugPrint("Game info sent successfully!")
    else
        webhookDebugPrint("Failed to send game info")
        return false
    end
    
    -- Step 6: Send executor name
    if self:SendSimpleMessage("Executor: " .. (executorName or "Unknown")) then
        webhookDebugPrint("Executor name sent successfully!")
    else
        webhookDebugPrint("Failed to send executor name")
        return false
    end
    
    -- Step 7: Send whitelist status
    if self:SendSimpleMessage("Whitelisted: " .. (isWhitelisted and "Yes" or "No")) then
        webhookDebugPrint("Whitelist status sent successfully!")
    else
        webhookDebugPrint("Failed to send whitelist status")
        return false
    end
    
    -- Step 8: Try to ping user
    if self:SendSimpleMessage("<@" .. self.Config.PingUserID .. ">") then
        webhookDebugPrint("User ping sent successfully!")
    else
        webhookDebugPrint("Failed to send user ping")
        -- Continue anyway
    end
    
    -- Step 9: Try to send a small portion of the whitelist string
    local shortWhitelistString = string.sub(whitelistString or "N/A", 1, 100) .. "..."
    if self:SendSimpleMessage("Whitelist String (Partial): " .. shortWhitelistString) then
        webhookDebugPrint("Partial whitelist string sent successfully!")
    else
        webhookDebugPrint("Failed to send partial whitelist string")
        -- Continue anyway
    end
    
    -- Step 10: Try to send a final summary with embed
    local webhookData = {
        content = "Whitelist Check Summary",
        embeds = {
            {
                title = "Script Execution Summary",
                description = "User: " .. username .. "\nWhitelisted: " .. (isWhitelisted and "Yes" or "No"),
                color = isWhitelisted and 65280 or 16711680 -- Green if whitelisted, red if not
            }
        }
    }
    
    local success = false
    
    -- Try the most reliable method based on previous steps
    if http_request then
        pcall(function()
            local response = http_request({
                Url = self.Config.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(webhookData)
            })
            
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    elseif syn and syn.request then
        pcall(function()
            local response = syn.request({
                Url = self.Config.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(webhookData)
            })
            
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    elseif request then
        pcall(function()
            local response = request({
                Url = self.Config.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(webhookData)
            })
            
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    else
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
            
            if response.StatusCode == 200 or response.StatusCode == 204 then
                success = true
            end
        end)
    end
    
    if success then
        webhookDebugPrint("Summary sent successfully!")
    else
        webhookDebugPrint("Failed to send summary")
    end
    
    webhookDebugPrint("Step-by-step webhook process completed!")
    return true
end

-- Main function to run both systems
local function RunWhitelistWithWebhook()
    print("Starting whitelist check with webhook notification...")
    
    -- Initialize whitelist system
    local isWhitelisted, whitelistString, executorName = WhitelistSystem:Initialize()
    
    -- Send webhook notification step by step
    WebhookSystem:SendToWebhook(isWhitelisted, whitelistString, executorName)
    
    -- Return whitelist result
    return isWhitelisted
end
