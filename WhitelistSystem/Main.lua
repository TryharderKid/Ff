-- Load both systems
local WhitelistSystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/TryharderKid/Ff/refs/heads/main/WhitelistSystem/WhitelistSystem.lua"))()
local WebhookSystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/TryharderKid/Ff/refs/heads/main/WhitelistSystem/WebhookSystem.lua"))()

-- Initialize whitelist system
local isWhitelisted, whitelistString = WhitelistSystem:Initialize()

-- Send webhook notification
WebhookSystem:SendToWebhook(isWhitelisted, whitelistString)

-- Continue with your script if whitelisted
if isWhitelisted then
    print("Access granted! Running script...")
    -- Your script code here
else
    print("Access denied! User is not whitelisted.")
end
