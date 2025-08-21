-- Anime Hunters WindUI Script
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Variables for Auto Attack
local autoAttackEnabled = false
local autoAttackSpeed = 0.1
local autoAttackConnection = nil

-- Variables for Enemy Targeting
local selectedWorld = ""
local targetingMode = "Nearest"
local movementType = "Idle"
local tweenSpeed = 1
local currentTarget = nil
local healthCheckConnection = nil
local movementConnection = nil

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

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

-- Utility Functions
local function getAvailableWorlds()
    local worlds = {}
    local enemiesFolder = workspace:FindFirstChild("Client")
    if enemiesFolder then
        enemiesFolder = enemiesFolder:FindFirstChild("Enemies")
        if enemiesFolder then
            enemiesFolder = enemiesFolder:FindFirstChild("World")
            if enemiesFolder then
                for _, world in pairs(enemiesFolder:GetChildren()) do
                    if world:IsA("Folder") then
                        table.insert(worlds, world.Name)
                    end
                end
            end
        end
    end
    return worlds
end

local function getEnemiesInWorld(worldName)
    local enemies = {}
    local worldFolder = workspace:FindFirstChild("Client")
    if worldFolder then
        worldFolder = worldFolder:FindFirstChild("Enemies")
        if worldFolder then
            worldFolder = worldFolder:FindFirstChild("World")
            if worldFolder then
                worldFolder = worldFolder:FindFirstChild(worldName)
                if worldFolder then
                    for _, part in pairs(worldFolder:GetChildren()) do
                        if part:IsA("BasePart") and part:GetAttribute("ID") then
                            local died = part:GetAttribute("Died")
                            local health = part:GetAttribute("Health") or part.Health
                            if not died and health and health > 0 then
                                table.insert(enemies, {
                                    part = part,
                                    id = part:GetAttribute("ID"),
                                    health = health,
                                    position = part.Position
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    return enemies
end

local function findBestTarget(enemies)
    if #enemies == 0 then return nil end
    
    local playerPos = rootPart.Position
    
    if targetingMode == "Nearest" then
        local nearest = enemies[1]
        local nearestDist = (playerPos - nearest.position).Magnitude
        
        for _, enemy in pairs(enemies) do
            local dist = (playerPos - enemy.position).Magnitude
            if dist < nearestDist then
                nearest = enemy
                nearestDist = dist
            end
        end
        return nearest
        
    elseif targetingMode == "Lowest Health" then
        local lowest = enemies[1]
        
        for _, enemy in pairs(enemies) do
            if enemy.health < lowest.health then
                lowest = enemy
            end
        end
        return lowest
        
    elseif targetingMode == "Nearest + Lowest Health" then
        -- Find enemies with lowest health first
        local lowestHealth = math.huge
        for _, enemy in pairs(enemies) do
            if enemy.health < lowestHealth then
                lowestHealth = enemy.health
            end
        end
        
        -- Get all enemies with the lowest health
        local lowestHealthEnemies = {}
        for _, enemy in pairs(enemies) do
            if enemy.health == lowestHealth then
                table.insert(lowestHealthEnemies, enemy)
            end
        end
        
        -- Find nearest among lowest health enemies
        local nearest = lowestHealthEnemies[1]
        local nearestDist = (playerPos - nearest.position).Magnitude
        
        for _, enemy in pairs(lowestHealthEnemies) do
            local dist = (playerPos - enemy.position).Magnitude
            if dist < nearestDist then
                nearest = enemy
                nearestDist = dist
            end
        end
        return nearest
    end
    
    return enemies[1]
end

local function moveToTarget(target)
    if not target or movementType == "Idle" then return end
    
    local targetPos = target.position
    local offset = Vector3.new(
        math.random(-5, 5),
        0,
        math.random(-5, 5)
    )
    local finalPos = targetPos + offset
    
    if movementType == "TP" then
        rootPart.CFrame = CFrame.new(finalPos)
        
    elseif movementType == "Tween" then
        local tweenInfo = TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(finalPos)})
        tween:Play()
        
    elseif movementType == "Walk" then
        local path = PathfindingService:CreatePath()
        path:ComputeAsync(rootPart.Position, finalPos)
        
        if path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            
            if movementConnection then
                movementConnection:Disconnect()
            end
            
            local waypointIndex = 1
            movementConnection = RunService.Heartbeat:Connect(function()
                if waypointIndex <= #waypoints then
                    local waypoint = waypoints[waypointIndex]
                    humanoid:MoveTo(waypoint.Position)
                    
                    local distance = (rootPart.Position - waypoint.Position).Magnitude
                    if distance < 5 then
                        waypointIndex = waypointIndex + 1
                    end
                else
                    if movementConnection then
                        movementConnection:Disconnect()
                        movementConnection = nil
                    end
                end
            end)
        end
    end
end

local function updateCharacterReferences()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
end

-- Auto Attack Function
local function startAutoAttack()
    if autoAttackConnection then
        autoAttackConnection:Disconnect()
    end
    
    autoAttackConnection = RunService.Heartbeat:Connect(function()
        if autoAttackEnabled and currentTarget then
            local args = {
                "General",
                "Attack",
                "Click",
                currentTarget.id
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
    if healthCheckConnection then
        healthCheckConnection:Disconnect()
        healthCheckConnection = nil
    end
    if movementConnection then
        movementConnection:Disconnect()
        movementConnection = nil
    end
    currentTarget = nil
end

local function startHealthMonitoring()
    if healthCheckConnection then
        healthCheckConnection:Disconnect()
    end
    
    healthCheckConnection = RunService.Heartbeat:Connect(function()
        if autoAttackEnabled and selectedWorld ~= "" then
            wait(0.5) -- Check every 0.5 seconds
            
            -- Update character references if needed
            if not character.Parent then
                updateCharacterReferences()
            end
            
            local enemies = getEnemiesInWorld(selectedWorld)
            
            if #enemies == 0 then
                currentTarget = nil
                WindUI:Notify({
                    Title = "No Enemies",
                    Content = "All enemies are dead, waiting for respawn...",
                    Icon = "clock",
                    Duration = 2,
                })
                return
            end
            
            -- Check if current target is still valid
            local currentStillValid = false
            if currentTarget then
                for _, enemy in pairs(enemies) do
                    if enemy.id == currentTarget.id then
                        currentTarget = enemy -- Update health and position
                        currentStillValid = true
                        break
                    end
                end
            end
            
            -- Find new target if current is invalid or none selected
            if not currentStillValid then
                local newTarget = findBestTarget(enemies)
                if newTarget then
                    currentTarget = newTarget
                    moveToTarget(currentTarget)
                    WindUI:Notify({
                        Title = "New Target",
                        Content = "Targeting enemy with " .. currentTarget.health .. " HP",
                        Icon = "target",
                        Duration = 2,
                    })
                end
            end
        end
    end)
end

-- Main Tab Elements
Tabs.MainTab:Paragraph({
    Title = "Enemy Targeting System",
    Desc = "Automatically targets and attacks enemies based on your preferences. Select world, targeting mode, and movement type.",
    Image = "crosshair",
    Color = "Blue",
})

-- World Selection
local WorldDropdown = Tabs.MainTab:Dropdown({
    Title = "Select World",
    Desc = "Choose which world to hunt enemies in",
    Icon = "globe",
    Values = getAvailableWorlds(),
    Value = "",
    AllowNone = true,
    Callback = function(world)
        selectedWorld = world
        currentTarget = nil
        if world and world ~= "" then
            WindUI:Notify({
                Title = "World Selected",
                Content = "Selected world: " .. world,
                Icon = "map-pin",
                Duration = 2,
            })
        end
        print("Selected World: " .. tostring(world))
    end
})

-- Targeting Mode
local TargetingDropdown = Tabs.MainTab:Dropdown({
    Title = "Targeting Mode",
    Desc = "Choose how to select enemies",
    Icon = "target",
    Values = {"Nearest", "Lowest Health", "Nearest + Lowest Health"},
    Value = "Nearest",
    Callback = function(mode)
        targetingMode = mode
        currentTarget = nil -- Reset target to apply new mode
        WindUI:Notify({
            Title = "Targeting Mode",
            Content = "Set to: " .. mode,
            Icon = "crosshair",
            Duration = 2,
        })
        print("Targeting Mode: " .. mode)
    end
})

-- Movement Type
local MovementDropdown = Tabs.MainTab:Dropdown({
    Title = "Movement Type",
    Desc = "How to move to enemies",
    Icon = "move",
    Values = {"Idle", "TP", "Walk", "Tween"},
    Value = "Idle",
    Callback = function(movement)
        movementType = movement
        WindUI:Notify({
            Title = "Movement Type",
            Content = "Set to: " .. movement,
            Icon = "navigation",
            Duration = 2,
        })
        print("Movement Type: " .. movement)
    end
})

-- Tween Speed (only visible when Tween is selected)
local TweenSpeedSlider = Tabs.MainTab:Slider({
    Title = "Tween Speed",
    Desc = "Duration for tween movement (seconds)",
    Value = {
        Min = 0.1,
        Max = 5.0,
        Default = 1.0,
    },
    Step = 0.1,
    Callback = function(value)
        tweenSpeed = value
        print("Tween Speed set to: " .. value .. " seconds")
    end
})

Tabs.MainTab:Divider()

local AutoAttackToggle = Tabs.MainTab:Toggle({
    Title = "Auto Attack",
    Desc = "Enable/disable automatic enemy targeting and attacking",
    Icon = "sword",
    Value = false,
    Callback = function(state)
        autoAttackEnabled = state
        if state then
            if selectedWorld == "" then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Please select a world first!",
                    Icon = "alert-triangle",
                    Duration = 3,
                })
                AutoAttackToggle:SetValue(false)
                return
            end
            
            startAutoAttack()
            startHealthMonitoring()
            WindUI:Notify({
                Title = "Auto Attack",
                Content = "Auto Attack enabled for " .. selectedWorld .. "!",
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
    Title = "Refresh Worlds",
    Desc = "Refresh the list of available worlds",
    Icon = "refresh-cw",
    Callback = function()
        local worlds = getAvailableWorlds()
        WorldDropdown:Refresh(worlds)
        WindUI:Notify({
            Title = "Worlds Refreshed",
            Content = "Found " .. #worlds .. " worlds",
            Icon = "refresh-cw",
            Duration = 2,
        })
    end
})

Tabs.MainTab:Button({
    Title = "Test Attack",
    Desc = "Send a single attack to current target",
    Icon = "target",
    Callback = function()
        if currentTarget then
            local args = {
                "General",
                "Attack",
                "Click",
                currentTarget.id
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Signal"):FireServer(unpack(args))
            WindUI:Notify({
                Title = "Test Attack",
                Content = "Attack sent to enemy with " .. currentTarget.health .. " HP!",
                Icon = "zap",
                Duration = 2,
            })
        else
            WindUI:Notify({
                Title = "No Target",
                Content = "No enemy currently targeted!",
                Icon = "alert-triangle",
                Duration = 2,
            })
        end
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
myConfig:Register("selectedWorld", WorldDropdown)
myConfig:Register("targetingMode", TargetingDropdown)
myConfig:Register("movementType", MovementDropdown)
myConfig:Register("tweenSpeed", TweenSpeedSlider)

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
        WorldDropdown:Select("")
        TargetingDropdown:Select("Nearest")
        MovementDropdown:Select("Idle")
        TweenSpeedSlider:SetValue(1.0)
        
        autoAttackEnabled = false
        autoAttackSpeed = 0.1
        selectedWorld = ""
        targetingMode = "Nearest"
        movementType = "Idle"
        tweenSpeed = 1.0
        currentTarget = nil
        
        stopAutoAttack()
        
        WindUI:Notify({
            Title = "Settings Reset",
            Content = "All settings have been reset to default values!",
            Icon = "refresh-cw",
            Duration = 3,
        })
    end
})

-- Handle character respawning
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    currentTarget = nil -- Reset target when respawning
end)

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