-- Anime Hunters WindUI Script
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Variables for Auto Attack
local autoAttackEnabled = false
local autoAttackSpeed = 0.1
local autoAttackConnection = nil

-- Create confirmation popup
local Confirmed = false

WindUI:Popup({
    Title = "Welcome to Anime Hunters!",
    Icon = "rbxassetid://129260712070622",
    IconThemed = true,
    Content = "Welcome to the Anime Hunters automation script!",
    Buttons = {
        {
            Title = "Cancel",
            Callback = function() end,
            Variant = "Secondary",
        },
        {
            Title = "Continue",
            Icon = "arrow-right",
            Callback = function() Confirmed = true end,
            Variant = "Primary",
        }
    }
})

repeat wait() until Confirmed

-- Create main window
local Window = WindUI:CreateWindow({
    Title = "Anime Hunters",
    Icon = "rbxassetid://129260712070622",
    IconThemed = true,
    Author = "Anime Hunters Script",
    Folder = "AnimeHunters",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    User = {
        Enabled = true,
        Callback = function() print("User clicked") end,
        Anonymous = true
    },
    SideBarWidth = 200,
    ScrollBarEnabled = true,
})

-- Create tabs
local Tabs = {}

Tabs.MainSection = Window:Section({
    Title = "Main Features",
    Icon = "sword",
    Opened = true,
})

Tabs.ConfigSection = Window:Section({
    Title = "Configuration",
    Icon = "settings",
    Opened = true,
})

Tabs.MainTab = Tabs.MainSection:Tab({ 
    Title = "Auto Attack", 
    Icon = "zap", 
    Desc = "Configure auto attack settings" 
})

Tabs.ConfigTab = Tabs.ConfigSection:Tab({ 
    Title = "Config", 
    Icon = "file-cog", 
    Desc = "Save and load your settings" 
})

-- Select first tab
Window:SelectTab(1)

-- Auto Attack Function
local function startAutoAttack()
    if autoAttackConnection then
        autoAttackConnection:Disconnect()
    end
    
    autoAttackConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if autoAttackEnabled then
            local args = {
                "General",
                "Attack",
                "Click"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Signal"):FireServer(unpack(args))
            wait(autoAttackSpeed)
        end
    end)
end

local function stopAutoAttack()
    if autoAttackConnection then
        autoAttackConnection:Disconnect()
        autoAttackConnection = nil
    end
end

-- Main Tab Elements
Tabs.MainTab:Paragraph({
    Title = "Auto Attack System",
    Desc = "Automatically attacks enemies for you. Adjust the speed slider to control attack frequency.",
    Image = "zap",
    Color = "Blue",
})

local AutoAttackToggle = Tabs.MainTab:Toggle({
    Title = "Auto Attack",
    Desc = "Enable/disable automatic attacking",
    Icon = "sword",
    Value = false,
    Callback = function(state)
        autoAttackEnabled = state
        if state then
            startAutoAttack()
            WindUI:Notify({
                Title = "Auto Attack",
                Content = "Auto Attack enabled!",
                Icon = "check",
                Duration = 3,
            })
        else
            stopAutoAttack()
            WindUI:Notify({
                Title = "Auto Attack",
                Content = "Auto Attack disabled!",
                Icon = "x",
                Duration = 3,
            })
        end
        print("Auto Attack: " .. tostring(state))
    end
})

local SpeedSlider = Tabs.MainTab:Slider({
    Title = "Attack Speed",
    Desc = "Adjust the delay between attacks (lower = faster)",
    Value = {
        Min = 0.01,
        Max = 2.0,
        Default = 0.1,
    },
    Step = 0.01,
    Callback = function(value)
        autoAttackSpeed = value
        print("Attack Speed set to: " .. value .. " seconds")
    end
})

Tabs.MainTab:Divider()

Tabs.MainTab:Button({
    Title = "Test Attack",
    Desc = "Send a single attack to test if it's working",
    Icon = "target",
    Callback = function()
        local args = {
            "General",
            "Attack",
            "Click"
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Signal"):FireServer(unpack(args))
        WindUI:Notify({
            Title = "Test Attack",
            Content = "Attack sent successfully!",
            Icon = "zap",
            Duration = 2,
        })
    end
})

-- Config Tab Elements
local HttpService = game:GetService("HttpService")

-- Config Management Setup
local ConfigManager = Window.ConfigManager
local myConfig = ConfigManager:CreateConfig("AnimeHuntersConfig")

-- Register elements for config
myConfig:Register("autoAttackToggle", AutoAttackToggle)
myConfig:Register("attackSpeed", SpeedSlider)

Tabs.ConfigTab:Paragraph({
    Title = "Configuration Management",
    Desc = "Save and load your Anime Hunters settings to preserve them between sessions.",
    Image = "save",
    Color = "Green",
})

Tabs.ConfigTab:Button({
    Title = "Save Config",
    Desc = "Save current settings to file",
    Icon = "save",
    Callback = function()
        myConfig:Save()
        WindUI:Notify({
            Title = "Config Saved",
            Content = "Your settings have been saved successfully!",
            Icon = "check",
            Duration = 3,
        })
    end
})

Tabs.ConfigTab:Button({
    Title = "Load Config",
    Desc = "Load previously saved settings",
    Icon = "folder-open",
    Callback = function()
        myConfig:Load()
        WindUI:Notify({
            Title = "Config Loaded",
            Content = "Your settings have been loaded successfully!",
            Icon = "check",
            Duration = 3,
        })
    end
})

Tabs.ConfigTab:Divider()

Tabs.ConfigTab:Button({
    Title = "Reset Settings",
    Desc = "Reset all settings to default values",
    Icon = "refresh-cw",
    Callback = function()
        -- Reset to defaults
        AutoAttackToggle:SetValue(false)
        SpeedSlider:SetValue(0.1)
        autoAttackEnabled = false
        autoAttackSpeed = 0.1
        stopAutoAttack()
        
        WindUI:Notify({
            Title = "Settings Reset",
            Content = "All settings have been reset to default values!",
            Icon = "refresh-cw",
            Duration = 3,
        })
    end
})

-- Window close handler
Window:OnClose(function()
    stopAutoAttack()
    print("Anime Hunters UI closed.")
end)

-- Auto-load config on startup
spawn(function()
    wait(1) -- Wait a moment for everything to initialize
    myConfig:Load()
end)

print("Anime Hunters script loaded successfully!")