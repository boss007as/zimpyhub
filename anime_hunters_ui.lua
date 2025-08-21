-- Anime Hunters WindUI Script
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Variables for Auto Attack
local autoAttackEnabled = false
local autoAttackSpeed = 0.1
local autoAttackConnection = nil

-- Variables for Enemy Targeting
local selectedWorlds = {}
local targetingMode = "Nearest"
local selectedEnemyNames = {}
local movementType = "Idle"
local tweenSpeed = 1
local currentTarget = nil
local healthCheckConnection = nil
local movementConnection = nil
local lastNotifiedTarget = nil
local tooFarNotified = false
local targetDeathConnection = nil
local targetHealthConnection = nil

-- Variables for Auto Join Mode
local autoJoinEnabled = false
local selectedMode = ""
local autoLeaveEnabled = false
local leaveAtTime = 30
local currentPlayerMode = ""
local modeMonitorConnection = nil
local playerModeConnection = nil

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
local function getAllWorlds()
    local worlds = {}
    local enemiesFolder = workspace:FindFirstChild("Server")
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

local function getEnemyNamesFromModuleScript(worlds)
    local allEnemyNames = {}
    local nameSet = {}
    
    if not worlds or #worlds == 0 then
        return allEnemyNames
    end
    
    for _, worldName in pairs(worlds) do
        local success, enemyData = pcall(function()
            local enemiesModule = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
            if enemiesModule then
                enemiesModule = enemiesModule:FindFirstChild("Enemies")
                if enemiesModule then
                    enemiesModule = enemiesModule:FindFirstChild(worldName)
                    if enemiesModule then
                        return require(enemiesModule)
                    end
                end
            end
            return nil
        end)
        
        if success and enemyData then
            for enemyName, _ in pairs(enemyData) do
                if not nameSet[enemyName] then
                    nameSet[enemyName] = true
                    table.insert(allEnemyNames, enemyName)
                end
            end
        end
    end
    
    return allEnemyNames
end

local function getEnemiesInWorld(worldName)
    local enemies = {}
    local worldFolder = workspace:FindFirstChild("Server")
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
                                    position = part.Position,
                                    name = part.Name -- Add enemy name
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

local function getAllEnemiesInSelectedWorlds()
    local allEnemies = {}
    
    for _, worldName in pairs(selectedWorlds) do
        local worldEnemies = getEnemiesInWorld(worldName)
        for _, enemy in pairs(worldEnemies) do
            table.insert(allEnemies, enemy)
        end
    end
    
    return allEnemies
end

-- Better world detection based on player's current location
local function detectCurrentWorld()
    local playerPos = rootPart.Position
    local closestWorld = ""
    local closestDistance = math.huge
    
    local enemiesFolder = workspace:FindFirstChild("Server")
    if not enemiesFolder then return "" end
    
    enemiesFolder = enemiesFolder:FindFirstChild("Enemies")
    if not enemiesFolder then return "" end
    
    enemiesFolder = enemiesFolder:FindFirstChild("World")
    if not enemiesFolder then return "" end
    
    -- Check all worlds for nearby enemies
    for _, worldFolder in pairs(enemiesFolder:GetChildren()) do
        if worldFolder:IsA("Folder") and #worldFolder:GetChildren() > 0 then
            for _, part in pairs(worldFolder:GetChildren()) do
                if part:IsA("BasePart") and part:GetAttribute("ID") then
                    local died = part:GetAttribute("Died")
                    local health = part:GetAttribute("Health") or part.Health
                    
                    if not died and health and health > 0 then
                        local distance = (playerPos - part.Position).Magnitude
                        if distance <= 100 and distance < closestDistance then
                            closestDistance = distance
                            closestWorld = worldFolder.Name
                        end
                    end
                end
            end
        end
    end
    
    return closestWorld
end

-- Auto-detect current world and suggest it
local function autoDetectAndSuggestWorld()
    local detectedWorld = detectCurrentWorld()
    if detectedWorld ~= "" then
        WindUI:Notify({
            Title = "World Detected",
            Content = "Detected world: " .. detectedWorld .. ". Click 'Auto-Select Current World' to use it.",
            Icon = "map-pin",
            Duration = 5,
        })
        return detectedWorld
    end
    return ""
end

local function isInAttackRange(target)
    if not target then return false end
    local distance = (rootPart.Position - target.position).Magnitude
    return distance <= 10
end

local function findBestTarget(enemies)
    if #enemies == 0 then return nil end
    
    local playerPos = rootPart.Position
    
    -- First, try to find enemies with the selected names (if any)
    local filteredEnemies = enemies
    if #selectedEnemyNames > 0 then
        local namedEnemies = {}
        for _, enemy in pairs(enemies) do
            for _, selectedName in pairs(selectedEnemyNames) do
                if enemy.name == selectedName then
                    table.insert(namedEnemies, enemy)
                    break
                end
            end
        end
        
        -- If we found enemies with the selected names, use them
        if #namedEnemies > 0 then
            filteredEnemies = namedEnemies
        else
            -- Selected enemy names not found, fall back to any enemy (nearest)
        end
    end
    
    -- Apply targeting mode to filtered enemies
    if targetingMode == "Nearest" then
        local nearest = filteredEnemies[1]
        local nearestDist = (playerPos - nearest.position).Magnitude
        
        for _, enemy in pairs(filteredEnemies) do
            local dist = (playerPos - enemy.position).Magnitude
            if dist < nearestDist then
                nearest = enemy
                nearestDist = dist
            end
        end
        return nearest
        
    elseif targetingMode == "Lowest Health" then
        local lowest = filteredEnemies[1]
        
        for _, enemy in pairs(filteredEnemies) do
            if enemy.health < lowest.health then
                lowest = enemy
            end
        end
        return lowest
        
    elseif targetingMode == "Highest Health" then
        local highest = filteredEnemies[1]
        
        for _, enemy in pairs(filteredEnemies) do
            if enemy.health > highest.health then
                highest = enemy
            end
        end
        return highest
        
    elseif targetingMode == "Nearest + Lowest Health" then
        -- Find enemies with lowest health first
        local lowestHealth = math.huge
        for _, enemy in pairs(filteredEnemies) do
            if enemy.health < lowestHealth then
                lowestHealth = enemy.health
            end
        end
        
        -- Get all enemies with the lowest health
        local lowestHealthEnemies = {}
        for _, enemy in pairs(filteredEnemies) do
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
        
    elseif targetingMode == "Nearest + Highest Health" then
        -- Find enemies with highest health first
        local highestHealth = 0
        for _, enemy in pairs(filteredEnemies) do
            if enemy.health > highestHealth then
                highestHealth = enemy.health
            end
        end
        
        -- Get all enemies with the highest health
        local highestHealthEnemies = {}
        for _, enemy in pairs(filteredEnemies) do
            if enemy.health == highestHealth then
                table.insert(highestHealthEnemies, enemy)
            end
        end
        
        -- Find nearest among highest health enemies
        local nearest = highestHealthEnemies[1]
        local nearestDist = (playerPos - nearest.position).Magnitude
        
        for _, enemy in pairs(highestHealthEnemies) do
            local dist = (playerPos - enemy.position).Magnitude
            if dist < nearestDist then
                nearest = enemy
                nearestDist = dist
            end
        end
        return nearest
    end
    
    return filteredEnemies[1]
end

local function moveToTarget(target)
    if not target or movementType == "Idle" then return end
    
    local targetPos = target.position
    local offset = Vector3.new(
        math.random(-10, 10),
        0,
        math.random(-10, 10)
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

-- No longer needed - removed auto world detection

-- Auto Attack Function
local function startAutoAttack()
    if autoAttackConnection then
        autoAttackConnection:Disconnect()
    end
    
    autoAttackConnection = RunService.Heartbeat:Connect(function()
        if autoAttackEnabled then
            -- Only attack if we have a valid current target
            if currentTarget then
                -- Simple part existence check (death/health monitoring is handled by attribute signals)
                if currentTarget.part and currentTarget.part.Parent then
                    if isInAttackRange(currentTarget) then
                        -- Protected attack call to prevent script breaking
                        local success, err = pcall(function()
                            local args = {
                                "General",
                                "Attack",
                                "Click",
                                currentTarget.id
                            }
                            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Signal"):FireServer(unpack(args))
                        end)
                        
                        if not success then
                            -- Attack failed, but don't break the script
                            warn("Attack failed: " .. tostring(err))
                        end
                        
                        tooFarNotified = false -- Reset notification flag when in range
                        wait(autoAttackSpeed)
                    else
                        -- Player is too far from target
                        if not tooFarNotified or lastNotifiedTarget ~= currentTarget.id then
                            WindUI:Notify({
                                Title = "Too Far",
                                Content = "Move closer to attack (within 10 studs)",
                                Icon = "move",
                                Duration = 2,
                            })
                            tooFarNotified = true
                            lastNotifiedTarget = currentTarget.id
                        end
                        
                        -- Auto move closer if not idle
                        if movementType ~= "Idle" then
                            moveToTarget(currentTarget)
                        end
                    end
                else
                    -- Target part no longer exists, switch to next target
                    switchToNextTarget()
                end
            end
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
    disconnectTargetMonitoring()
    currentTarget = nil
    tooFarNotified = false
end

local function findNextTarget()
    if #selectedWorlds == 0 then return nil end
    
    local enemies = getAllEnemiesInSelectedWorlds()
    if #enemies == 0 then return nil end
    
    return findBestTarget(enemies)
end

local function disconnectTargetMonitoring()
    if targetDeathConnection then
        targetDeathConnection:Disconnect()
        targetDeathConnection = nil
    end
    if targetHealthConnection then
        targetHealthConnection:Disconnect()
        targetHealthConnection = nil
    end
end

local function monitorTargetChanges(target)
    disconnectTargetMonitoring()
    
    if not target or not target.part then return end
    
    -- Monitor Died attribute changes
    local success1, err1 = pcall(function()
        targetDeathConnection = target.part:GetAttributeChangedSignal("Died"):Connect(function()
            local died = target.part:GetAttribute("Died")
            if died == true then
                -- Use spawn to prevent recursive issues
                spawn(function()
                    switchToNextTarget()
                end)
            end
        end)
    end)
    
    -- Monitor Health attribute changes
    local success2, err2 = pcall(function()
        targetHealthConnection = target.part:GetAttributeChangedSignal("Health"):Connect(function()
            local health = target.part:GetAttribute("Health")
            if not health or health <= 0 then
                -- Use spawn to prevent recursive issues
                spawn(function()
                    switchToNextTarget()
                end)
            else
                -- Update current target health
                if currentTarget then
                    currentTarget.health = health
                end
            end
        end)
    end)
end

local function switchToNextTarget()
    -- Disconnect monitoring for old target
    disconnectTargetMonitoring()
    
    local newTarget = findNextTarget()
    if newTarget then
        currentTarget = newTarget
        tooFarNotified = false -- Reset notification for new target
        lastNotifiedTarget = nil -- Reset last notified target
        
        -- Start monitoring the new target
        monitorTargetChanges(currentTarget)
        
        -- Move to new target immediately
        if movementType ~= "Idle" then
            moveToTarget(currentTarget)
        end
        
        WindUI:Notify({
            Title = "Target Switched",
            Content = "New target: " .. currentTarget.health .. " HP",
            Icon = "arrow-right",
            Duration = 1,
        })
        return true
    else
        currentTarget = nil
        return false
    end
end

local function startHealthMonitoring()
    if healthCheckConnection then
        healthCheckConnection:Disconnect()
    end
    
    -- Backup monitoring system - checks for death and part existence
    healthCheckConnection = RunService.Heartbeat:Connect(function()
        if autoAttackEnabled and #selectedWorlds > 0 then
            wait(0.2) -- Check more frequently as backup to attribute signals
            
            -- Update character references if needed
            if not character.Parent then
                updateCharacterReferences()
            end
            
            -- If we have a current target, validate it
            if currentTarget then
                if not currentTarget.part or not currentTarget.part.Parent then
                    -- Target part no longer exists - immediately switch
                    switchToNextTarget()
                else
                    -- Backup death check in case attribute signals fail
                    local died = currentTarget.part:GetAttribute("Died")
                    local health = currentTarget.part:GetAttribute("Health") or currentTarget.part.Health
                    
                    if died == true then
                        switchToNextTarget()
                    elseif not health or health <= 0 then
                        switchToNextTarget()
                    else
                        -- Update current target's position and health
                        currentTarget.position = currentTarget.part.Position
                        currentTarget.health = health
                    end
                end
            else
                -- No current target, find one
                switchToNextTarget()
            end
        end
    end)
end

-- Main Tab Elements
Tabs.MainTab:Paragraph({
    Title = "Multi-World Enemy Targeting System",
    Desc = "Select multiple worlds and enemy types to hunt. System will attack enemies within 10 studs and immediately switch when current target dies.",
    Image = "crosshair",
    Color = "Blue",
})

-- World Selection
local WorldDropdown = Tabs.MainTab:Dropdown({
    Title = "Select Worlds",
    Desc = "Choose which worlds to hunt enemies in (can select multiple)",
    Icon = "globe",
    Values = getAllWorlds(),
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(worlds)
        selectedWorlds = worlds or {}
        currentTarget = nil -- Reset target when worlds change
        disconnectTargetMonitoring() -- Disconnect old target monitoring
        
        if #selectedWorlds > 0 then
            WindUI:Notify({
                Title = "Worlds Selected",
                Content = "Selected " .. #selectedWorlds .. " world(s). Use Refresh Enemy Names to update list.",
                Icon = "map-pin",
                Duration = 3,
            })
        else
            WindUI:Notify({
                Title = "No Worlds Selected",
                Content = "Please select at least one world",
                Icon = "alert-triangle",
                Duration = 2,
            })
        end
    end
})

-- Enemy Name Selection
local EnemyNameDropdown = Tabs.MainTab:Dropdown({
    Title = "Target Enemy Names",
    Desc = "Choose specific enemy names to target (can select multiple, leave empty for any enemy)",
    Icon = "users",
    Values = {},
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(enemyNames)
        selectedEnemyNames = enemyNames or {}
        currentTarget = nil -- Reset target to apply new selection
        
        if #selectedEnemyNames > 0 then
            WindUI:Notify({
                Title = "Enemies Selected",
                Content = "Will target " .. #selectedEnemyNames .. " enemy type(s)",
                Icon = "crosshair",
                Duration = 2,
            })
        else
            WindUI:Notify({
                Title = "Enemy Selection",
                Content = "Will target any enemy",
                Icon = "users",
                Duration = 2,
            })
        end

    end
})

Tabs.MainTab:Button({
    Title = "Refresh Enemy Names",
    Desc = "Update the list of available enemy names from selected worlds",
    Icon = "refresh-cw",
    Callback = function()
        if #selectedWorlds > 0 then
            local success, enemyNames = pcall(function()
                return getEnemyNamesFromModuleScript(selectedWorlds)
            end)
            
            if success and enemyNames then
                EnemyNameDropdown:Refresh(enemyNames)
                WindUI:Notify({
                    Title = "Enemy Names Refreshed",
                    Content = "Found " .. #enemyNames .. " different enemy types",
                    Icon = "users",
                    Duration = 2,
                })
            else
                WindUI:Notify({
                    Title = "Refresh Failed",
                    Content = "Error loading enemy names from module scripts",
                    Icon = "alert-triangle",
                    Duration = 3,
                })
            end
        else
            WindUI:Notify({
                Title = "No Worlds Selected",
                Content = "Please select worlds first!",
                Icon = "alert-triangle",
                Duration = 2,
            })
        end
    end
})

-- Targeting Mode
local TargetingDropdown = Tabs.MainTab:Dropdown({
    Title = "Targeting Mode",
    Desc = "Choose how to select enemies",
    Icon = "target",
    Values = {"Nearest", "Lowest Health", "Highest Health", "Nearest + Lowest Health", "Nearest + Highest Health"},
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
            if #selectedWorlds == 0 then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Please select at least one world first!",
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
                Content = "Auto Attack enabled for " .. #selectedWorlds .. " world(s)!",
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

    end
})

Tabs.MainTab:Divider()



Tabs.MainTab:Button({
    Title = "Test Attack",
    Desc = "Send a single attack to current target",
    Icon = "target",
    Callback = function()
        if currentTarget then
            -- Validate target before attacking
            if currentTarget.part and currentTarget.part.Parent then
                local died = currentTarget.part:GetAttribute("Died")
                local health = currentTarget.part:GetAttribute("Health") or currentTarget.part.Health
                
                if not died and health and health > 0 then
                    local args = {
                        "General",
                        "Attack",
                        "Click",
                        currentTarget.id
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Signal"):FireServer(unpack(args))
                    WindUI:Notify({
                        Title = "Test Attack",
                        Content = "Attack sent to enemy with " .. health .. " HP!",
                        Icon = "zap",
                        Duration = 2,
                    })
                else
                    currentTarget = nil
                    WindUI:Notify({
                        Title = "Target Dead",
                        Content = "Current target is dead, finding new target...",
                        Icon = "skull",
                        Duration = 2,
                    })
                end
            else
                currentTarget = nil
                WindUI:Notify({
                    Title = "Invalid Target",
                    Content = "Target no longer exists, finding new target...",
                    Icon = "x",
                    Duration = 2,
                })
            end
        else
            WindUI:Notify({
                Title = "No Target",
                Content = "No enemy currently targeted! Enable Auto Attack to find targets.",
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
myConfig:Register("selectedWorlds", WorldDropdown)
myConfig:Register("selectedEnemyNames", EnemyNameDropdown)
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
        WorldDropdown:Select({})
        EnemyNameDropdown:Select({})
        TargetingDropdown:Select("Nearest")
        MovementDropdown:Select("Idle")
        TweenSpeedSlider:SetValue(1.0)
        
        autoAttackEnabled = false
        autoAttackSpeed = 0.1
        selectedWorlds = {}
        selectedEnemyNames = {}
        targetingMode = "Nearest"
        movementType = "Idle"
        tweenSpeed = 1.0
        currentTarget = nil
        tooFarNotified = false
        
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
    tooFarNotified = false
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