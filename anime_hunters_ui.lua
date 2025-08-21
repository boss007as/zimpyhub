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
local isWalkingToTarget = false

-- Variables for Auto Hatch
local autoHatchEnabled = false
local hatchWorld = ""
local hatchMode = "Single"
local hatchSpeed = 0.5
local multiHatchAmount = 10
local hatchConnection = nil

-- Variables for Auto Join Mode
local autoJoinEnabled = false
local selectedModes = {}
local autoLeaveEnabled = false
local leaveAtTime = 30
local leaveByWave = false
local leaveAtWave = 5
local currentPlayerMode = ""
local modeMonitorConnections = {}
local playerModeConnection = nil
local savedLocation = nil

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

Tabs.HatchSection = Window:Section({
    Title = "Auto Hatch",
    Icon = "egg",
    Opened = true,
})

Tabs.GamemodeSection = Window:Section({
    Title = "Auto Join Modes",
    Icon = "gamepad-2",
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

Tabs.HatchTab = Tabs.HatchSection:Tab({ 
    Title = "Auto Hatch", 
    Icon = "egg", 
    Desc = "Automatically hatch eggs from worlds" 
})

Tabs.GamemodeTab = Tabs.GamemodeSection:Tab({ 
    Title = "Auto Join", 
    Icon = "log-in", 
    Desc = "Auto join dungeons and gamemodes" 
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
    
    -- If player is in a gamemode, get enemies from gamemode path
    if currentPlayerMode ~= "" and currentPlayerMode ~= "World" then
        local gamemodeEnemies = getEnemiesInGamemode(currentPlayerMode)
        for _, enemy in pairs(gamemodeEnemies) do
            table.insert(allEnemies, enemy)
        end
    else
        -- Get enemies from selected worlds
        for _, worldName in pairs(selectedWorlds) do
            local worldEnemies = getEnemiesInWorld(worldName)
            for _, enemy in pairs(worldEnemies) do
                table.insert(allEnemies, enemy)
            end
        end
    end
    
    return allEnemies
end

-- Get enemies from gamemode path
local function getEnemiesInGamemode(modeName)
    local enemies = {}
    local gamemodeFolder = workspace:FindFirstChild("Server")
    if gamemodeFolder then
        gamemodeFolder = gamemodeFolder:FindFirstChild("Enemies")
        if gamemodeFolder then
            gamemodeFolder = gamemodeFolder:FindFirstChild("Gamemodes")
            if gamemodeFolder then
                gamemodeFolder = gamemodeFolder:FindFirstChild(modeName)
                if gamemodeFolder then
                    for _, part in pairs(gamemodeFolder:GetChildren()) do
                        if part:IsA("BasePart") and part:GetAttribute("ID") then
                            local died = part:GetAttribute("Died")
                            local health = part:GetAttribute("Health") or part.Health
                            if not died and health and health > 0 then
                                table.insert(enemies, {
                                    part = part,
                                    id = part:GetAttribute("ID"),
                                    health = health,
                                    position = part.Position,
                                    name = part.Name
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

-- Get available gamemodes
local function getAvailableGamemodes()
    local modes = {}
    local gamemodesFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Gamemodes")
    if gamemodesFolder then
        for _, mode in pairs(gamemodesFolder:GetChildren()) do
            if mode:IsA("Folder") then
                table.insert(modes, mode.Name)
            end
        end
    end
    return modes
end

-- Get hatch worlds from ReplicatedStorage.Shared.Stars
local function getHatchWorlds()
    local worlds = {}
    local starsModule = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
    if starsModule then
        starsModule = starsModule:FindFirstChild("Stars")
        if starsModule then
            local success, starsData = pcall(function()
                return require(starsModule)
            end)
            
            if success and starsData then
                for worldName, _ in pairs(starsData) do
                    table.insert(worlds, worldName)
                end
            end
        end
    end
    return worlds
end

-- Get hatch price for a world
local function getHatchPrice(worldName)
    local starsModule = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
    if starsModule then
        starsModule = starsModule:FindFirstChild("Stars")
        if starsModule then
            local success, starsData = pcall(function()
                return require(starsModule)
            end)
            
            if success and starsData and starsData[worldName] then
                return starsData[worldName].Price or 0
            end
        end
    end
    return 0
end

-- Currency conversion function
local function convertCurrencyToNumber(currencyString)
    if not currencyString then return 0 end
    
    local str = tostring(currencyString):upper()
    local number = tonumber(str:match("%d+%.?%d*")) or 0
    
    if str:find("K") then
        return number * 1000
    elseif str:find("M") then
        return number * 1000000
    elseif str:find("B") then
        return number * 1000000000
    elseif str:find("T") then
        return number * 1000000000000
    elseif str:find("QD") then
        return number * 1000000000000000
    elseif str:find("QN") then
        return number * 1000000000000000000
    else
        return number
    end
end

-- Get player's current Stars currency
local function getPlayerStars()
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local stars = leaderstats:FindFirstChild("Stars")
        if stars then
            return convertCurrencyToNumber(stars.Value)
        end
    end
    return 0
end

-- Auto hatch function
local lastHatchTime = 0

local function startAutoHatch()
    if hatchConnection then
        hatchConnection:Disconnect()
    end
    
    hatchConnection = RunService.Heartbeat:Connect(function()
        if not autoHatchEnabled or hatchWorld == "" then return end
        
        -- Check hatch speed timing
        local currentTime = tick()
        local speedValue = tonumber(hatchSpeed) or 0.5
        if currentTime - lastHatchTime < speedValue then
            return -- Not enough time passed
        end
        
        -- Check if player has enough currency for this world
        local playerStars = getPlayerStars()
        local hatchPrice = getHatchPrice(hatchWorld)
        
        if playerStars < hatchPrice then
            -- Not enough currency, stop auto hatch
            autoHatchEnabled = false
            AutoHatchToggle:SetValue(false)
            WindUI:Notify({
                Title = "Insufficient Currency",
                Content = "Not enough Stars for " .. hatchWorld .. ". Auto Hatch stopped.",
                Icon = "alert-triangle",
                Duration = 3,
            })
            return
        end
        
        -- Protected hatch call
        spawn(function()
            local success, err = pcall(function()
                if hatchMode == "Multi" then
                    -- Multi hatch logic
                    local args = {
                        "General",
                        "Stars",
                        "Multi",
                        multiHatchAmount,
                        hatchWorld
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Signal"):FireServer(unpack(args))
                else
                    -- Single hatch logic
                    local args = {
                        "General",
                        "Stars",
                        "Single",
                        1, -- Amount (always 1 for single)
                        hatchWorld
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Signal"):FireServer(unpack(args))
                end
            end)
            
            if not success then
                warn("Hatch failed: " .. tostring(err))
            end
        end)
        
        lastHatchTime = currentTime
    end)
end

local function stopAutoHatch()
    if hatchConnection then
        hatchConnection:Disconnect()
        hatchConnection = nil
    end
end

-- Save current location
local function saveCurrentLocation()
    if rootPart then
        savedLocation = rootPart.CFrame
        WindUI:Notify({
            Title = "Location Saved",
            Content = "Current position saved for auto-return",
            Icon = "map-pin",
            Duration = 2,
        })
    end
end

-- Teleport back to saved location
local function teleportToSavedLocation()
    if savedLocation and rootPart then
        rootPart.CFrame = savedLocation
        WindUI:Notify({
            Title = "Returned to Saved Location",
            Content = "Teleported back to saved position",
            Icon = "home",
            Duration = 2,
        })
    end
end

-- Join selected gamemode
local function joinGamemode(modeName)
    local success, err = pcall(function()
        local args = {
            "Gamemodes",
            modeName,
            "Join"
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Signal"):FireServer(unpack(args))
    end)
    
    if success then
        WindUI:Notify({
            Title = "Joining Mode",
            Content = "Attempting to join " .. modeName,
            Icon = "log-in",
            Duration = 2,
        })
    else
        WindUI:Notify({
            Title = "Join Failed",
            Content = "Failed to join " .. modeName,
            Icon = "alert-triangle",
            Duration = 3,
        })
    end
end

-- Leave current gamemode
local function leaveGamemode()
    if currentPlayerMode ~= "" and currentPlayerMode ~= "World" then
        local success, err = pcall(function()
            local args = {
                "Gamemodes",
                currentPlayerMode,
                "Leave"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Signal"):FireServer(unpack(args))
        end)
        
        if success then
            WindUI:Notify({
                Title = "Leaving Mode",
                Content = "Left " .. currentPlayerMode,
                Icon = "log-out",
                Duration = 2,
            })
            
            -- Teleport back to saved location
            if autoLeaveEnabled then
                teleportToSavedLocation()
            end
        end
    end
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
    
    -- Don't move if already close enough
    local distance = (rootPart.Position - target.position).Magnitude
    if distance <= 10 then
        isWalkingToTarget = false
        return
    end
    
    local targetPos = target.position
    local offset = Vector3.new(
        math.random(-8, 8),
        0,
        math.random(-8, 8)
    )
    local finalPos = targetPos + offset
    
    if movementType == "TP" then
        rootPart.CFrame = CFrame.new(finalPos)
        isWalkingToTarget = false
        
    elseif movementType == "Tween" then
        local tweenInfo = TweenInfo.new(tweenSpeed, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(finalPos)})
        tween:Play()
        
        tween.Completed:Connect(function()
            isWalkingToTarget = false
        end)
        
    elseif movementType == "Walk" then
        if movementConnection then
            movementConnection:Disconnect()
            movementConnection = nil
        end
        
        isWalkingToTarget = true
        
        local success, err = pcall(function()
            local path = PathfindingService:CreatePath()
            path:ComputeAsync(rootPart.Position, finalPos)
            
            if path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()
                
                local waypointIndex = 1
                movementConnection = RunService.Heartbeat:Connect(function()
                    -- Stop if we're close enough to target (10 studs)
                    if currentTarget then
                        local currentDistance = (rootPart.Position - currentTarget.position).Magnitude
                        if currentDistance <= 10 then
                            if movementConnection then
                                movementConnection:Disconnect()
                                movementConnection = nil
                            end
                            isWalkingToTarget = false
                            humanoid:MoveTo(rootPart.Position) -- Stop moving
                            return
                        end
                    end
                    
                    if waypointIndex <= #waypoints and autoAttackEnabled and isWalkingToTarget then
                        local waypoint = waypoints[waypointIndex]
                        humanoid:MoveTo(waypoint.Position)
                        
                        local waypointDistance = (rootPart.Position - waypoint.Position).Magnitude
                        if waypointDistance < 5 then
                            waypointIndex = waypointIndex + 1
                        end
                    else
                        if movementConnection then
                            movementConnection:Disconnect()
                            movementConnection = nil
                        end
                        isWalkingToTarget = false
                    end
                end)
            else
                isWalkingToTarget = false
            end
        end)
        
        if not success then
            warn("Pathfinding failed: " .. tostring(err))
            isWalkingToTarget = false
        end
    end
end

local function updateCharacterReferences()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
end

-- No longer needed - removed auto world detection

-- Target monitoring functions
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

-- New radius-based enemy detection (1000 studs)
local function getAllEnemiesInRadius()
    local enemies = {}
    local playerPos = rootPart.Position
    
    -- Check if player is in gamemode first
    if currentPlayerMode ~= "" and currentPlayerMode ~= "World" then
        -- In gamemode - get enemies from gamemode path
        local gamemodeFolder = workspace:FindFirstChild("Server")
        if gamemodeFolder then
            gamemodeFolder = gamemodeFolder:FindFirstChild("Enemies")
            if gamemodeFolder then
                gamemodeFolder = gamemodeFolder:FindFirstChild("Gamemodes")
                if gamemodeFolder then
                    gamemodeFolder = gamemodeFolder:FindFirstChild(currentPlayerMode)
                    if gamemodeFolder then
                        for _, part in pairs(gamemodeFolder:GetChildren()) do
                            if part:IsA("BasePart") and part:GetAttribute("ID") then
                                local died = part:GetAttribute("Died")
                                local health = part:GetAttribute("Health") or part.Health
                                local distance = (playerPos - part.Position).Magnitude
                                
                                if not died and health and health > 0 and distance <= 1000 then
                                    -- Convert health to number if it's a string
                                    local numericHealth = tonumber(health) or 0
                                    table.insert(enemies, {
                                        part = part,
                                        id = part:GetAttribute("ID"),
                                        health = numericHealth,
                                        position = part.Position,
                                        name = part.Name,
                                        distance = distance
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        -- In world - scan all worlds for enemies within radius
        local serverFolder = workspace:FindFirstChild("Server")
        if serverFolder then
            local enemiesFolder = serverFolder:FindFirstChild("Enemies")
            if enemiesFolder then
                local worldFolder = enemiesFolder:FindFirstChild("World")
                if worldFolder then
                    -- Scan all worlds for enemies within 1000 studs
                    for _, world in pairs(worldFolder:GetChildren()) do
                        if world:IsA("Folder") then
                            for _, part in pairs(world:GetChildren()) do
                                if part:IsA("BasePart") and part:GetAttribute("ID") then
                                    local died = part:GetAttribute("Died")
                                    local health = part:GetAttribute("Health") or part.Health
                                    local distance = (playerPos - part.Position).Magnitude
                                    
                                    if not died and health and health > 0 and distance <= 1000 then
                                        -- Convert health to number if it's a string
                                        local numericHealth = tonumber(health) or 0
                                        table.insert(enemies, {
                                            part = part,
                                            id = part:GetAttribute("ID"),
                                            health = numericHealth,
                                            position = part.Position,
                                            name = part.Name,
                                            distance = distance,
                                            world = world.Name
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return enemies
end

local function findNextTarget()
    -- Don't switch targets while walking to prevent back-and-forth movement
    if isWalkingToTarget and currentTarget then
        -- Check if current target is still valid
        if currentTarget.part and currentTarget.part.Parent then
            local died = currentTarget.part:GetAttribute("Died")
            local health = currentTarget.part:GetAttribute("Health") or currentTarget.part.Health
            if not died and health and health > 0 then
                return currentTarget -- Keep current target while walking
            end
        end
        -- Current target died while walking, stop walking and find new target
        isWalkingToTarget = false
        if movementConnection then
            movementConnection:Disconnect()
            movementConnection = nil
        end
    end
    
    local enemies = getAllEnemiesInRadius()
    if #enemies == 0 then return nil end
    
    -- Filter by selected enemy names if any are chosen
    if #selectedEnemyNames > 0 then
        local filteredEnemies = {}
        for _, enemy in pairs(enemies) do
            for _, selectedName in pairs(selectedEnemyNames) do
                if enemy.name == selectedName then
                    table.insert(filteredEnemies, enemy)
                    break
                end
            end
        end
        
        if #filteredEnemies > 0 then
            enemies = filteredEnemies
        end
    end
    
    return findBestTarget(enemies)
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

-- Auto Attack Function
local lastAttackTime = 0

local function startAutoAttack()
    if autoAttackConnection then
        autoAttackConnection:Disconnect()
    end
    
    autoAttackConnection = RunService.Heartbeat:Connect(function()
        if not autoAttackEnabled then return end
        
        -- Only attack if we have a valid current target
        if not currentTarget then return end
        
        -- Simple part existence check (death/health monitoring is handled by attribute signals)
        if not currentTarget.part or not currentTarget.part.Parent then
            -- Target part no longer exists, switch to next target
            spawn(function() switchToNextTarget() end)
            return
        end
        
        -- Check attack speed timing
        local currentTime = tick()
        local speedValue = tonumber(autoAttackSpeed) or 0.1
        if currentTime - lastAttackTime < speedValue then
            return -- Not enough time passed
        end
        
        if isInAttackRange(currentTarget) then
            -- Protected attack call to prevent script breaking
            spawn(function()
                -- Store target ID before attack to prevent nil access
                local targetId = currentTarget and currentTarget.id
                if targetId then
                    local success, err = pcall(function()
                        local args = {
                            "General",
                            "Attack",
                            "Click",
                            targetId
                        }
                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Signal"):FireServer(unpack(args))
                    end)
                    
                    if not success then
                        -- Attack failed, but don't break the script
                        warn("Attack failed: " .. tostring(err))
                    end
                end
            end)
            
            lastAttackTime = currentTime
            tooFarNotified = false -- Reset notification flag when in range
        else
            -- Player is too far from target - auto move closer if not idle
            if movementType ~= "Idle" and not isWalkingToTarget then
                moveToTarget(currentTarget)
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
    stopAutoHatch() -- Also stop auto hatch when stopping auto attack
    currentTarget = nil
    tooFarNotified = false
    isWalkingToTarget = false
end

-- Monitor gamemode status and player mode with real-time change detection
local function startModeMonitoring()
    -- Clear old connections
    for _, connection in pairs(modeMonitorConnections) do
        connection:Disconnect()
    end
    modeMonitorConnections = {}
    
    if playerModeConnection then
        playerModeConnection:Disconnect()
    end
    
    -- Monitor player's current mode with attribute change signal
    playerModeConnection = player:GetAttributeChangedSignal("Mode"):Connect(function()
        local newPlayerMode = player:GetAttribute("Mode") or "World"
        local previousMode = currentPlayerMode
        currentPlayerMode = newPlayerMode
        
        -- Reset current target when mode changes
        currentTarget = nil
        disconnectTargetMonitoring()
        isWalkingToTarget = false
        
        -- Update status display
        if currentPlayerMode ~= "World" then
            ModeStatus:SetTitle("Current Mode: " .. currentPlayerMode)
            ModeStatus:SetDesc("Currently in gamemode. Auto-targeting gamemode enemies.")
            WindUI:Notify({
                Title = "Mode Changed",
                Content = "Now in: " .. currentPlayerMode,
                Icon = "gamepad-2",
                Duration = 2,
            })
        else
            ModeStatus:SetTitle("Current Mode: World")
            ModeStatus:SetDesc("Not in any gamemode currently.")
            
            -- Auto teleport back to saved location when leaving gamemode
            if previousMode ~= "World" and previousMode ~= "" then
                WindUI:Notify({
                    Title = "Left Gamemode",
                    Content = "Left " .. previousMode .. ", returning to saved location...",
                    Icon = "log-out",
                    Duration = 2,
                })
                spawn(function()
                    wait(1) -- Small delay to ensure mode change is complete
                    teleportToSavedLocation()
                end)
            end
        end
    end)
    
    -- Set initial player mode
    currentPlayerMode = player:GetAttribute("Mode") or "World"
    
    -- Monitor selected gamemodes with real-time change detection
    if autoJoinEnabled and #selectedModes > 0 then
        local gamemodeFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Gamemodes")
        if gamemodeFolder then
            for _, modeName in pairs(selectedModes) do
                local modeFolder = gamemodeFolder:FindFirstChild(modeName)
                if modeFolder then
                    -- Monitor Open attribute changes for instant join
                    local openConnection = modeFolder:GetAttributeChangedSignal("Open"):Connect(function()
                        local isOpen = modeFolder:GetAttribute("Open")
                        if isOpen and currentPlayerMode == "World" then
                            WindUI:Notify({
                                Title = "Gamemode Opened",
                                Content = modeName .. " is now open! Joining...",
                                Icon = "door-open",
                                Duration = 2,
                            })
                            spawn(function() joinGamemode(modeName) end)
                        end
                    end)
                    table.insert(modeMonitorConnections, openConnection)
                    
                    -- Monitor Timer/Remaining for auto-leave
                    if autoLeaveEnabled then
                        if leaveByWave then
                            -- Monitor Remaining attribute for wave-based leaving
                            local remainingConnection = modeFolder:GetAttributeChangedSignal("Remaining"):Connect(function()
                                local remaining = modeFolder:GetAttribute("Remaining") or 999
                                if currentPlayerMode == modeName and remaining <= leaveAtWave then
                                    WindUI:Notify({
                                        Title = "Auto Leave",
                                        Content = "Only " .. remaining .. " waves left, leaving " .. modeName,
                                        Icon = "layers",
                                        Duration = 2,
                                    })
                                    spawn(function() leaveGamemode() end)
                                end
                            end)
                            table.insert(modeMonitorConnections, remainingConnection)
                        else
                            -- Monitor Timer attribute for time-based leaving
                            local timerConnection = modeFolder:GetAttributeChangedSignal("Timer"):Connect(function()
                                local timer = modeFolder:GetAttribute("Timer") or 0
                                if currentPlayerMode == modeName and timer <= leaveAtTime then
                                    WindUI:Notify({
                                        Title = "Auto Leave",
                                        Content = "Only " .. timer .. " seconds left, leaving " .. modeName,
                                        Icon = "clock",
                                        Duration = 2,
                                    })
                                    spawn(function() leaveGamemode() end)
                                end
                            end)
                            table.insert(modeMonitorConnections, timerConnection)
                        end
                    end
                end
            end
        end
    end
end

local function stopModeMonitoring()
    for _, connection in pairs(modeMonitorConnections) do
        connection:Disconnect()
    end
    modeMonitorConnections = {}
    
    if playerModeConnection then
        playerModeConnection:Disconnect()
        playerModeConnection = nil
    end
end

local lastHealthCheckTime = 0

local function startHealthMonitoring()
    if healthCheckConnection then
        healthCheckConnection:Disconnect()
    end
    
    -- Backup monitoring system - checks for death and part existence
    healthCheckConnection = RunService.Heartbeat:Connect(function()
        if not autoAttackEnabled then return end
        
        -- Timing check to avoid excessive calls
        local currentTime = tick()
        if currentTime - lastHealthCheckTime < 0.2 then
            return
        end
        lastHealthCheckTime = currentTime
        
        -- Update character references if needed
        if not character or not character.Parent then
            spawn(function() updateCharacterReferences() end)
            return
        end
        
        -- If we have a current target, validate it
        if currentTarget then
            if not currentTarget.part or not currentTarget.part.Parent then
                -- Target part no longer exists - immediately switch
                spawn(function() switchToNextTarget() end)
            else
                -- Backup death check in case attribute signals fail
                local died = currentTarget.part:GetAttribute("Died")
                local health = currentTarget.part:GetAttribute("Health") or currentTarget.part.Health
                
                if died == true then
                    spawn(function() switchToNextTarget() end)
                elseif not health or health <= 0 then
                    spawn(function() switchToNextTarget() end)
                else
                    -- Update current target's position and health
                    currentTarget.position = currentTarget.part.Position
                    currentTarget.health = health
                end
            end
        else
            -- No current target, find one (radius-based detection)
            spawn(function() switchToNextTarget() end)
        end
    end)
end

-- Main Tab Elements
Tabs.MainTab:Paragraph({
    Title = "Radius-Based Enemy Targeting System",
    Desc = "Automatically detects and targets enemies within 1000 studs. No world selection needed - just choose enemy types and start hunting!",
    Image = "crosshair",
    Color = "Blue",
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
    Desc = "Update the list of available enemy names from nearby enemies",
    Icon = "refresh-cw",
    Callback = function()
        local success, enemyNames = pcall(function()
            local nearbyEnemies = getAllEnemiesInRadius()
            local nameSet = {}
            local names = {}
            
            for _, enemy in pairs(nearbyEnemies) do
                if not nameSet[enemy.name] then
                    nameSet[enemy.name] = true
                    table.insert(names, enemy.name)
                end
            end
            
            return names
        end)
        
        if success and enemyNames then
            EnemyNameDropdown:Refresh(enemyNames)
            WindUI:Notify({
                Title = "Enemy Names Refreshed",
                Content = "Found " .. #enemyNames .. " enemy types within 1000 studs",
                Icon = "users",
                Duration = 2,
            })
        else
            WindUI:Notify({
                Title = "Refresh Failed",
                Content = "Error scanning for nearby enemies",
                Icon = "alert-triangle",
                Duration = 3,
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
        tweenSpeed = tonumber(value) or 1.0
    end
})

Tabs.MainTab:Divider()

local AutoAttackToggle = Tabs.MainTab:Toggle({
    Title = "Auto Attack",
    Desc = "Enable/disable automatic enemy targeting and attacking within 1000 studs",
    Icon = "sword",
    Value = false,
    Callback = function(state)
        autoAttackEnabled = state
        if state then
            startAutoAttack()
            startHealthMonitoring()
            startModeMonitoring() -- Start mode monitoring for gamemode support
            WindUI:Notify({
                Title = "Auto Attack",
                Content = "Auto Attack enabled! Scanning 1000 stud radius...",
                Icon = "check",
                Duration = 3,
            })
        else
            stopAutoAttack()
            stopModeMonitoring()
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
        autoAttackSpeed = tonumber(value) or 0.1
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



-- Hatch Tab Elements
Tabs.HatchTab:Paragraph({
    Title = "Auto Hatch System",
    Desc = "Automatically hatch eggs from selected worlds using your Stars currency. Supports both single and multi hatching modes.",
    Image = "egg",
    Color = "Orange",
})

-- Currency Display
local CurrencyStatus = Tabs.HatchTab:Paragraph({
    Title = "Current Stars: Loading...",
    Desc = "Your current Stars currency for hatching.",
    Image = "star",
    Color = "Yellow",
})

-- Hatch World Selection
local HatchWorldDropdown = Tabs.HatchTab:Dropdown({
    Title = "Hatch World",
    Desc = "Select world to hatch eggs from",
    Icon = "globe",
    Values = getHatchWorlds(),
    Value = "",
    AllowNone = true,
    Callback = function(world)
        hatchWorld = world or ""
        if hatchWorld ~= "" then
            local price = getHatchPrice(hatchWorld)
            local playerStars = getPlayerStars()
            
            -- Format price for display
            local displayPrice = ""
            if price >= 1000000000000000000 then
                displayPrice = string.format("%.1fQn", price / 1000000000000000000)
            elseif price >= 1000000000000000 then
                displayPrice = string.format("%.1fQd", price / 1000000000000000)
            elseif price >= 1000000000000 then
                displayPrice = string.format("%.1fT", price / 1000000000000)
            elseif price >= 1000000000 then
                displayPrice = string.format("%.1fB", price / 1000000000)
            elseif price >= 1000000 then
                displayPrice = string.format("%.1fM", price / 1000000)
            elseif price >= 1000 then
                displayPrice = string.format("%.1fK", price / 1000)
            else
                displayPrice = tostring(price)
            end
            
            WindUI:Notify({
                Title = "Hatch World Selected",
                Content = hatchWorld .. " - Price: " .. displayPrice .. " Stars",
                Icon = "map-pin",
                Duration = 3,
            })
            
            if playerStars < price then
                WindUI:Notify({
                    Title = "Insufficient Currency",
                    Content = "You need " .. displayPrice .. " Stars to hatch from " .. hatchWorld,
                    Icon = "alert-triangle",
                    Duration = 4,
                })
            end
        else
            WindUI:Notify({
                Title = "No Hatch World",
                Content = "Auto hatch disabled",
                Icon = "x",
                Duration = 2,
            })
        end
    end
})

-- Hatch Mode Selection
local HatchModeDropdown = Tabs.HatchTab:Dropdown({
    Title = "Hatch Mode",
    Desc = "Choose hatching method",
    Icon = "layers",
    Values = {"Single", "Multi"},
    Value = "Single",
    Callback = function(mode)
        hatchMode = mode or "Single"
        WindUI:Notify({
            Title = "Hatch Mode",
            Content = "Set to: " .. hatchMode,
            Icon = "settings",
            Duration = 2,
        })
    end
})

-- Multi Hatch Amount Slider
local MultiHatchSlider = Tabs.HatchTab:Slider({
    Title = "Multi Hatch Amount",
    Desc = "Number of eggs to hatch at once in Multi mode",
    Value = {
        Min = 1,
        Max = 100,
        Default = 10,
    },
    Step = 1,
    Callback = function(value)
        multiHatchAmount = tonumber(value) or 10
    end
})

-- Hatch Speed Slider
local HatchSpeedSlider = Tabs.HatchTab:Slider({
    Title = "Hatch Speed",
    Desc = "Adjust the delay between hatches (lower = faster)",
    Value = {
        Min = 0.1,
        Max = 5.0,
        Default = 0.5,
    },
    Step = 0.1,
    Callback = function(value)
        hatchSpeed = tonumber(value) or 0.5
    end
})

Tabs.HatchTab:Divider()

-- Auto Hatch Toggle
local AutoHatchToggle = Tabs.HatchTab:Toggle({
    Title = "Auto Hatch",
    Desc = "Enable/disable automatic hatching",
    Icon = "egg",
    Value = false,
    Callback = function(state)
        autoHatchEnabled = state
        if state then
            if hatchWorld == "" then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Please select a hatch world first!",
                    Icon = "alert-triangle",
                    Duration = 3,
                })
                AutoHatchToggle:SetValue(false)
                return
            end
            
            startAutoHatch()
            WindUI:Notify({
                Title = "Auto Hatch",
                Content = "Auto Hatch enabled for " .. hatchWorld .. " (" .. hatchMode .. " mode)",
                Icon = "check",
                Duration = 3,
            })
        else
            stopAutoHatch()
            WindUI:Notify({
                Title = "Auto Hatch",
                Content = "Auto Hatch disabled!",
                Icon = "x",
                Duration = 3,
            })
        end
    end
})

Tabs.HatchTab:Button({
    Title = "Refresh Hatch Worlds",
    Desc = "Update the list of available worlds for hatching",
    Icon = "refresh-cw",
    Callback = function()
        local worlds = getHatchWorlds()
        HatchWorldDropdown:Refresh(worlds)
        WindUI:Notify({
            Title = "Worlds Refreshed",
            Content = "Found " .. #worlds .. " hatch worlds",
            Icon = "refresh-cw",
            Duration = 2,
        })
    end
})

Tabs.HatchTab:Button({
    Title = "Test Hatch",
    Desc = "Send a single hatch command to test if it's working",
    Icon = "egg",
    Callback = function()
        if hatchWorld ~= "" then
            local playerStars = getPlayerStars()
            if playerStars > 0 then
                local args = {
                    "General",
                    "Stars",
                    "Single",
                    1,
                    hatchWorld
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Signal"):FireServer(unpack(args))
                WindUI:Notify({
                    Title = "Test Hatch",
                    Content = "Hatch command sent for " .. hatchWorld,
                    Icon = "egg",
                    Duration = 2,
                })
            else
                WindUI:Notify({
                    Title = "No Currency",
                    Content = "You don't have enough Stars to hatch!",
                    Icon = "alert-triangle",
                    Duration = 2,
                })
            end
        else
            WindUI:Notify({
                Title = "No World Selected",
                Content = "Please select a hatch world first!",
                Icon = "alert-triangle",
                Duration = 2,
            })
        end
    end
})

-- Gamemode Tab Elements
Tabs.GamemodeTab:Paragraph({
    Title = "Auto Join Gamemode System",
    Desc = "Automatically join dungeons and gamemodes when they open. Save your location and auto-return when leaving.",
    Image = "gamepad-2",
    Color = "Green",
})

-- Status Display
local ModeStatus = Tabs.GamemodeTab:Paragraph({
    Title = "Current Mode: World",
    Desc = "Not in any gamemode currently.",
    Image = "map",
    Color = "Grey",
})

-- Gamemode Selection
local GamemodeDropdown = Tabs.GamemodeTab:Dropdown({
    Title = "Select Gamemodes",
    Desc = "Choose which gamemodes to auto-join when they open (can select multiple)",
    Icon = "gamepad-2",
    Values = getAvailableGamemodes(),
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(modes)
        selectedModes = modes or {}
        if #selectedModes > 0 then
            WindUI:Notify({
                Title = "Gamemodes Selected",
                Content = "Will auto-join " .. #selectedModes .. " gamemode(s)",
                Icon = "target",
                Duration = 2,
            })
        else
            WindUI:Notify({
                Title = "No Gamemodes",
                Content = "Auto-join disabled",
                Icon = "x",
                Duration = 2,
            })
        end
    end
})

-- Auto Join Toggle
local AutoJoinToggle = Tabs.GamemodeTab:Toggle({
    Title = "Auto Join",
    Desc = "Automatically join selected gamemodes when they open",
    Icon = "log-in",
    Value = false,
    Callback = function(state)
        autoJoinEnabled = state
        if state then
            if #selectedModes == 0 then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Please select at least one gamemode first!",
                    Icon = "alert-triangle",
                    Duration = 3,
                })
                AutoJoinToggle:SetValue(false)
                return
            end
            
            WindUI:Notify({
                Title = "Auto Join Enabled",
                Content = "Will auto-join " .. #selectedModes .. " gamemode(s) when they open",
                Icon = "check",
                Duration = 3,
            })
        else
            WindUI:Notify({
                Title = "Auto Join Disabled",
                Content = "Will not auto-join gamemodes",
                Icon = "x",
                Duration = 2,
            })
        end
    end
})

-- Auto Leave Toggle
local AutoLeaveToggle = Tabs.GamemodeTab:Toggle({
    Title = "Auto Leave",
    Desc = "Automatically leave gamemode based on timer or wave/rooms remaining",
    Icon = "log-out",
    Value = false,
    Callback = function(state)
        autoLeaveEnabled = state
        if state then
            local method = leaveByWave and "wave/rooms" or "timer"
            local value = leaveByWave and leaveAtWave or leaveAtTime
            WindUI:Notify({
                Title = "Auto Leave Enabled",
                Content = "Will auto-leave by " .. method .. " (" .. value .. ")",
                Icon = "clock",
                Duration = 2,
            })
        else
            WindUI:Notify({
                Title = "Auto Leave Disabled",
                Content = "Will not auto-leave gamemodes",
                Icon = "x",
                Duration = 2,
            })
        end
    end
})

-- Leave Method Selection
local LeaveMethodDropdown = Tabs.GamemodeTab:Dropdown({
    Title = "Leave Method",
    Desc = "Choose how to determine when to leave gamemode",
    Icon = "clock",
    Values = {"Timer", "Wave/Rooms"},
    Value = "Timer",
    Callback = function(method)
        leaveByWave = (method == "Wave/Rooms")
        if leaveByWave then
            WindUI:Notify({
                Title = "Leave Method",
                Content = "Will leave by remaining waves/rooms",
                Icon = "layers",
                Duration = 2,
            })
        else
            WindUI:Notify({
                Title = "Leave Method",
                Content = "Will leave by timer",
                Icon = "clock",
                Duration = 2,
            })
        end
    end
})

-- Leave Time Slider
local LeaveTimeSlider = Tabs.GamemodeTab:Slider({
    Title = "Leave At Time",
    Desc = "Leave gamemode when timer reaches this many seconds remaining",
    Value = {
        Min = 5,
        Max = 2000,
        Default = 30,
    },
    Step = 5,
    Callback = function(value)
        leaveAtTime = tonumber(value) or 30
    end
})

-- Leave Wave Slider
local LeaveWaveSlider = Tabs.GamemodeTab:Slider({
    Title = "Leave At Wave",
    Desc = "Leave gamemode when this many waves/rooms remain",
    Value = {
        Min = 1,
        Max = 50,
        Default = 5,
    },
    Step = 1,
    Callback = function(value)
        leaveAtWave = tonumber(value) or 5
    end
})

Tabs.GamemodeTab:Divider()

-- Location Management
Tabs.GamemodeTab:Button({
    Title = "Save Current Location",
    Desc = "Save your current position for auto-return when leaving gamemodes",
    Icon = "map-pin",
    Callback = function()
        saveCurrentLocation()
    end
})

Tabs.GamemodeTab:Button({
    Title = "Teleport to Saved Location",
    Desc = "Manually teleport back to your saved location",
    Icon = "home",
    Callback = function()
        teleportToSavedLocation()
    end
})

Tabs.GamemodeTab:Button({
    Title = "Leave Current Gamemode",
    Desc = "Manually leave the current gamemode and return to saved location",
    Icon = "log-out",
    Callback = function()
        leaveGamemode()
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
myConfig:Register("selectedEnemyNames", EnemyNameDropdown)
myConfig:Register("targetingMode", TargetingDropdown)
myConfig:Register("movementType", MovementDropdown)
myConfig:Register("tweenSpeed", TweenSpeedSlider)
myConfig:Register("hatchWorld", HatchWorldDropdown)
myConfig:Register("hatchMode", HatchModeDropdown)
myConfig:Register("hatchSpeed", HatchSpeedSlider)
myConfig:Register("multiHatchAmount", MultiHatchSlider)
myConfig:Register("autoHatchEnabled", AutoHatchToggle)
myConfig:Register("selectedModes", GamemodeDropdown)
myConfig:Register("autoJoinEnabled", AutoJoinToggle)
myConfig:Register("autoLeaveEnabled", AutoLeaveToggle)
myConfig:Register("leaveMethod", LeaveMethodDropdown)
myConfig:Register("leaveAtTime", LeaveTimeSlider)
myConfig:Register("leaveAtWave", LeaveWaveSlider)

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
        EnemyNameDropdown:Select({})
        TargetingDropdown:Select("Nearest")
        MovementDropdown:Select("Idle")
        TweenSpeedSlider:SetValue(1.0)
        HatchWorldDropdown:Select("")
        HatchModeDropdown:Select("Single")
        HatchSpeedSlider:SetValue(0.5)
        AutoHatchToggle:SetValue(false)
        GamemodeDropdown:Select({})
        AutoJoinToggle:SetValue(false)
        AutoLeaveToggle:SetValue(false)
        LeaveMethodDropdown:Select("Timer")
        LeaveTimeSlider:SetValue(30)
        LeaveWaveSlider:SetValue(5)
        
        autoAttackEnabled = false
        autoAttackSpeed = 0.1
        selectedEnemyNames = {}
        targetingMode = "Nearest"
        movementType = "Idle"
        tweenSpeed = 1.0
        hatchWorld = ""
        hatchMode = "Single"
        hatchSpeed = 0.5
        multiHatchAmount = 10
        autoHatchEnabled = false
        selectedModes = {}
        autoJoinEnabled = false
        autoLeaveEnabled = false
        leaveByWave = false
        leaveAtTime = 30
        leaveAtWave = 5
        currentTarget = nil
        tooFarNotified = false
        isWalkingToTarget = false
        
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

-- Currency monitoring
spawn(function()
    while true do
        wait(2) -- Update currency display every 2 seconds
        local stars = getPlayerStars()
        local displayStars = ""
        
        if stars >= 1000000000000000000 then
            displayStars = string.format("%.1fQn", stars / 1000000000000000000)
        elseif stars >= 1000000000000000 then
            displayStars = string.format("%.1fQd", stars / 1000000000000000)
        elseif stars >= 1000000000000 then
            displayStars = string.format("%.1fT", stars / 1000000000000)
        elseif stars >= 1000000000 then
            displayStars = string.format("%.1fB", stars / 1000000000)
        elseif stars >= 1000000 then
            displayStars = string.format("%.1fM", stars / 1000000)
        elseif stars >= 1000 then
            displayStars = string.format("%.1fK", stars / 1000)
        else
            displayStars = tostring(stars)
        end
        
        CurrencyStatus:SetTitle("Current Stars: " .. displayStars)
        CurrencyStatus:SetDesc("Your current Stars currency for hatching.")
    end
end)

-- Auto-load config on startup
spawn(function()
    wait(1) -- Wait a moment for everything to initialize
    myConfig:Load()
end)

print("Anime Hunters script loaded successfully!")