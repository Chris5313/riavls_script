-- Rivals Script with Rayfield UI
-- Made by Resentvu

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ESP Variables
local playerESPEnabled = true -- Always enabled by default
local playerESPObjects = {}
local playerNametagObjects = {}

-- ESP Customization Variables
local showDistance = true
local showHealthBar = true
local showTracers = false
local showBoxes = false
local showNames = true
local distanceBasedScaling = true
local maxDistance = 5000

-- ESP Color Variables
local playerESPColor = Color3.fromRGB(255, 0, 0) -- Red
local fillTransparency = 0.5
local outlineTransparency = 0

-- Aimbot Variables
local aimbotEnabled = false
local aimbotConnection = nil
local aimbotFOV = 200
local aimbotSmoothness = 1
local aimbotTargetPart = 'Head'
local showFOVCircle = true
local aimbotTeamCheck = false
local aimbotKeybind = Enum.UserInputType.MouseButton2 -- Right mouse click
local isAimbotKeyPressed = false
local wallCheckEnabled = true
local stickyAim = true
local currentTarget = nil
local silentAimEnabled = true -- Trigger bot enabled by default

-- FOV Circle
local FOVCircle = Drawing.new('Circle')
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64
FOVCircle.Filled = false

-- Create Rayfield Window
local Window = Rayfield:CreateWindow({
    Name = '🎮 Rivals Script',
    LoadingTitle = 'Rivals Script',
    LoadingSubtitle = 'by Resentvu',
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil, -- nil = default folder
        FileName = 'RivalsConfig',
        IgnoreList = {}, -- Empty = save all flagged elements
    },
    AutoSave = true, -- Auto-saves when you close or change settings
    Discord = {
        Enabled = false,
        Invite = '',
        RememberJoins = false,
    },
    KeySystem = false,
})

-- Create Tabs
local CombatTab = Window:CreateTab('⚔️ Combat', 4483362458)
local ESPTab = Window:CreateTab('👁️ ESP', 4483362458)
local CustomizationTab = Window:CreateTab('🎨 Customization', 4483362458)
local AutoFarmTab = Window:CreateTab('🤖 Auto Farm', 4483362458)

-- === COMBAT TAB ===
local AimbotSection = CombatTab:CreateSection('Aimbot')

local AimbotToggle = CombatTab:CreateToggle({
    Name = 'Enable Aimbot',
    CurrentValue = false,
    Flag = 'Aimbot',
    Callback = function(Value)
        aimbotEnabled = Value
        Rayfield:Notify({
            Title = 'Aimbot',
            Content = Value and 'Aimbot ENABLED' or 'Aimbot disabled',
            Duration = 2,
        })
        if Value then
            startAimbot()
        else
            stopAimbot()
        end
    end,
})

local FOVSlider = CombatTab:CreateSlider({
    Name = 'Aimbot FOV',
    Range = { 50, 500 },
    Increment = 10,
    Suffix = ' px',
    CurrentValue = 200,
    Flag = 'AimbotFOV',
    Callback = function(Value)
        aimbotFOV = Value
        FOVCircle.Radius = Value
    end,
})

local SmoothnessSlider = CombatTab:CreateSlider({
    Name = 'Aimbot Smoothness',
    Range = { 1, 10 },
    Increment = 0.5,
    Suffix = 'x',
    CurrentValue = 1,
    Flag = 'AimbotSmoothness',
    Callback = function(Value)
        aimbotSmoothness = Value
    end,
})

local TargetPartDropdown = CombatTab:CreateDropdown({
    Name = 'Target Part',
    Options = { 'Head', 'Torso', 'HumanoidRootPart' },
    CurrentOption = 'Head',
    Flag = 'TargetPart',
    Callback = function(Option)
        aimbotTargetPart = Option
    end,
})

local FOVCircleToggle = CombatTab:CreateToggle({
    Name = 'Show FOV Circle',
    CurrentValue = true,
    Flag = 'FOVCircle',
    Callback = function(Value)
        showFOVCircle = Value
        FOVCircle.Visible = Value and aimbotEnabled
    end,
})

local TeamCheckToggle = CombatTab:CreateToggle({
    Name = 'Team Check',
    CurrentValue = false,
    Flag = 'TeamCheck',
    Callback = function(Value)
        aimbotTeamCheck = Value
    end,
})

local WallCheckToggle = CombatTab:CreateToggle({
    Name = 'Wall Check (Visible Only)',
    CurrentValue = true,
    Flag = 'WallCheck',
    Callback = function(Value)
        wallCheckEnabled = Value
    end,
})

local StickyAimToggle = CombatTab:CreateToggle({
    Name = 'Sticky Aim (Lock Target)',
    CurrentValue = true,
    Flag = 'StickyAim',
    Callback = function(Value)
        stickyAim = Value
        if not Value then
            currentTarget = nil
        end
    end,
})

local TriggerBotToggle = CombatTab:CreateToggle({
    Name = 'Trigger Bot (Auto Shoot)',
    CurrentValue = true, -- Enabled by default
    Flag = 'TriggerBot',
    Callback = function(Value)
        silentAimEnabled = Value
        Rayfield:Notify({
            Title = 'Trigger Bot',
            Content = Value and 'Will auto-shoot when on target'
                or 'Trigger bot disabled',
            Duration = 2,
        })
    end,
})

local AimbotInfoSection = CombatTab:CreateSection('Information')
local AimbotInfoLabel = CombatTab:CreateLabel(
    '💡 Hold RIGHT MOUSE to aim at closest player in FOV'
)
local AimbotInfoLabel2 =
    CombatTab:CreateLabel('🎯 Lower smoothness = faster lock')
local AimbotInfoLabel3 =
    CombatTab:CreateLabel('🧱 Wall check ensures target is visible')

-- Debug section removed

-- === ESP TAB ===
local PlayerESPSection = ESPTab:CreateSection('Player ESP')

local PlayerESPToggle = ESPTab:CreateToggle({
    Name = 'Enable Player ESP',
    CurrentValue = true, -- Enabled by default
    Flag = 'PlayerESP',
    Callback = function(Value)
        playerESPEnabled = Value
        Rayfield:Notify({
            Title = 'Player ESP',
            Content = Value and 'Player ESP ENABLED' or 'Player ESP disabled',
            Duration = 2,
        })
        if Value then
            createAllPlayerESP()
        else
            removeAllPlayerESP()
        end
    end,
})

local NametagToggle = ESPTab:CreateToggle({
    Name = 'Show Nametags',
    CurrentValue = true,
    Flag = 'PlayerNametag',
    Callback = function(Value)
        showNames = Value
        if playerESPEnabled then
            refreshAllPlayerESP()
        end
    end,
})

local ESPFeaturesSection = ESPTab:CreateSection('ESP Features')

local DistanceToggle = ESPTab:CreateToggle({
    Name = 'Show Distance',
    CurrentValue = true,
    Flag = 'ShowDistance',
    Callback = function(Value)
        showDistance = Value
    end,
})

local HealthBarToggle = ESPTab:CreateToggle({
    Name = 'Show Health Bar',
    CurrentValue = true,
    Flag = 'ShowHealthBar',
    Callback = function(Value)
        showHealthBar = Value
        if playerESPEnabled then
            refreshAllPlayerESP()
        end
    end,
})

local TracersToggle = ESPTab:CreateToggle({
    Name = 'Show Tracers (Lines)',
    CurrentValue = false,
    Flag = 'ShowTracers',
    Callback = function(Value)
        showTracers = Value
        if playerESPEnabled then
            refreshAllPlayerESP()
        end
    end,
})

local BoxesToggle = ESPTab:CreateToggle({
    Name = 'Show Boxes',
    CurrentValue = false,
    Flag = 'ShowBoxes',
    Callback = function(Value)
        showBoxes = Value
        if playerESPEnabled then
            refreshAllPlayerESP()
        end
    end,
})

local ScalingToggle = ESPTab:CreateToggle({
    Name = 'Distance-Based Scaling',
    CurrentValue = true,
    Flag = 'DistanceScaling',
    Callback = function(Value)
        distanceBasedScaling = Value
    end,
})

local DistanceSlider = ESPTab:CreateSlider({
    Name = 'Max ESP Distance',
    Range = { 1000, 10000 },
    Increment = 500,
    Suffix = ' studs',
    CurrentValue = 5000,
    Flag = 'MaxDistance',
    Callback = function(Value)
        maxDistance = Value
    end,
})

-- === CUSTOMIZATION TAB ===
local ColorSection = CustomizationTab:CreateSection('ESP Colors')

local PlayerColorPicker = CustomizationTab:CreateColorPicker({
    Name = 'Player ESP Color',
    Color = Color3.fromRGB(255, 0, 0), -- Red by default
    Flag = 'PlayerESPColor',
    Callback = function(Value)
        playerESPColor = Value
        if playerESPEnabled then
            refreshAllPlayerESP()
        end
    end,
})

local TransparencySection =
    CustomizationTab:CreateSection('Transparency Settings')

local FillTransparencySlider = CustomizationTab:CreateSlider({
    Name = 'Fill Transparency',
    Range = { 0, 1 },
    Increment = 0.05,
    Suffix = '',
    CurrentValue = 0.5,
    Flag = 'FillTransparency',
    Callback = function(Value)
        fillTransparency = Value
        if playerESPEnabled then
            refreshAllPlayerESP()
        end
    end,
})

local OutlineTransparencySlider = CustomizationTab:CreateSlider({
    Name = 'Outline Transparency',
    Range = { 0, 1 },
    Increment = 0.05,
    Suffix = '',
    CurrentValue = 0,
    Flag = 'OutlineTransparency',
    Callback = function(Value)
        outlineTransparency = Value
        if playerESPEnabled then
            refreshAllPlayerESP()
        end
    end,
})

local InfoSection = CustomizationTab:CreateSection('Information')
local InfoLabel =
    CustomizationTab:CreateLabel('💡 Customize ESP colors and transparency')
local InfoLabel2 = CustomizationTab:CreateLabel(
    '🎨 Changes apply instantly when ESP is enabled'
)

-- === FUNCTIONS ===

-- Helper function to calculate distance
local function getDistance(part1, part2)
    if not part1 or not part2 then
        return math.huge
    end
    return (part1.Position - part2.Position).Magnitude
end

-- Helper function to create health bar
local function createHealthBar(parent, humanoid)
    if not showHealthBar then
        return nil
    end

    local healthBarBg = Instance.new('Frame')
    healthBarBg.Name = 'HealthBarBG'
    healthBarBg.Size = UDim2.new(1, 0, 0.1, 0)
    healthBarBg.Position = UDim2.new(0, 0, 0, 0)
    healthBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBg.BorderSizePixel = 0
    healthBarBg.Parent = parent

    local healthBar = Instance.new('Frame')
    healthBar.Name = 'HealthBar'
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBg

    -- Update health bar continuously
    task.spawn(function()
        while healthBar and healthBar.Parent and humanoid and humanoid.Parent do
            pcall(function()
                if humanoid.MaxHealth > 0 then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    healthBar.Size =
                        UDim2.new(math.clamp(healthPercent, 0, 1), 0, 1, 0)

                    -- Color changes based on health
                    if healthPercent > 0.5 then
                        healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    elseif healthPercent > 0.25 then
                        healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                    else
                        healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    end
                end
            end)
            task.wait(0.1)
        end
    end)

    return healthBarBg
end

-- Helper function to create tracer line
local function createTracer(target, color)
    if not showTracers then
        return nil
    end

    local line = Drawing.new('Line')
    line.Visible = true
    line.Color = color
    line.Thickness = 1
    line.Transparency = 0.7

    task.spawn(function()
        while line do
            pcall(function()
                if target and target.Parent then
                    local pos, onScreen =
                        Camera:WorldToViewportPoint(target.Position)
                    if onScreen then
                        line.From = Vector2.new(
                            Camera.ViewportSize.X / 2,
                            Camera.ViewportSize.Y
                        )
                        line.To = Vector2.new(pos.X, pos.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line:Remove()
                    line = nil
                end
            end)
            task.wait(0.03)
        end
    end)

    return line
end

-- Helper function to create box
local function createBox(target, color)
    if not showBoxes then
        return nil
    end

    local box = Instance.new('BoxHandleAdornment')
    box.Name = 'ESPBox'
    box.Adornee = target
    box.Size = target.Size + Vector3.new(1, 1, 1)
    box.Color3 = color
    box.AlwaysOnTop = true
    box.ZIndex = 1
    box.Transparency = 0.7
    box.Parent = target

    return box
end

-- Create player nametag
local function createPlayerNametag(player)
    if player == LocalPlayer then
        return
    end
    if not player.Character then
        return
    end
    if not showNames then
        return
    end

    local character = player.Character
    local rootPart = character:FindFirstChild('HumanoidRootPart')
    local head = character:FindFirstChild('Head')
    local humanoid = character:FindFirstChild('Humanoid')
    if not rootPart or not head or not humanoid then
        return
    end

    if playerNametagObjects[player] then
        pcall(function()
            playerNametagObjects[player]:Destroy()
        end)
    end

    local billboardGui = Instance.new('BillboardGui')
    billboardGui.Name = 'NametagESP'
    billboardGui.Adornee = head
    billboardGui.Size = UDim2.new(0, 200, 0, 80)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = head

    local container = Instance.new('Frame')
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = billboardGui

    -- Health bar
    if showHealthBar then
        createHealthBar(container, humanoid)
    end

    -- Name label
    local nameLabel = Instance.new('TextLabel')
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.15, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = container

    -- Distance label
    local distanceLabel = Instance.new('TextLabel')
    distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.7, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.Parent = container

    -- Update distance and scaling
    task.spawn(function()
        while billboardGui and billboardGui.Parent do
            pcall(function()
                local localRoot = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
                if not localRoot then
                    return
                end

                local distance = getDistance(localRoot, rootPart)

                -- Hide if beyond max distance
                if distance > maxDistance then
                    billboardGui.Enabled = false
                    return
                else
                    billboardGui.Enabled = true
                end

                if showDistance then
                    distanceLabel.Text =
                        string.format('[%dm]', math.floor(distance))
                    distanceLabel.Visible = true
                else
                    distanceLabel.Visible = false
                end

                if distanceBasedScaling then
                    local scale = math.clamp(1 - (distance / 500), 0.5, 1)
                    billboardGui.Size = UDim2.new(0, 200 * scale, 0, 80 * scale)
                end
            end)
            task.wait(0.1)
        end
    end)

    playerNametagObjects[player] = billboardGui
end

-- Create player cham/highlight
local function createPlayerCham(player)
    if player == LocalPlayer then
        return
    end
    if not player.Character then
        return
    end

    local character = player.Character
    local rootPart = character:FindFirstChild('HumanoidRootPart')
    if not rootPart then
        return
    end

    if playerESPObjects[player] then
        pcall(function()
            if playerESPObjects[player].highlight then
                playerESPObjects[player].highlight:Destroy()
            end
            if playerESPObjects[player].tracer then
                playerESPObjects[player].tracer:Remove()
            end
            if playerESPObjects[player].box then
                playerESPObjects[player].box:Destroy()
            end
        end)
    end

    playerESPObjects[player] = {}

    -- Create highlight (chams)
    local highlight = Instance.new('Highlight')
    highlight.Name = 'PlayerESP'
    highlight.FillColor = playerESPColor
    highlight.OutlineColor = Color3.new(
        playerESPColor.R * 0.7,
        playerESPColor.G * 0.7,
        playerESPColor.B * 0.7
    )
    highlight.FillTransparency = fillTransparency
    highlight.OutlineTransparency = outlineTransparency
    highlight.Adornee = character
    highlight.Parent = character
    playerESPObjects[player].highlight = highlight

    -- Create tracer
    if showTracers then
        local tracer = createTracer(rootPart, playerESPColor)
        playerESPObjects[player].tracer = tracer
    end

    -- Create box
    if showBoxes then
        local box = createBox(rootPart, playerESPColor)
        playerESPObjects[player].box = box
    end

    -- Create nametag
    createPlayerNametag(player)
end

-- Create all player ESP
function createAllPlayerESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            createPlayerCham(player)
        end
    end
end

-- Remove all player ESP
function removeAllPlayerESP()
    for player, espObj in pairs(playerESPObjects) do
        pcall(function()
            if type(espObj) == 'table' then
                if espObj.highlight then
                    espObj.highlight:Destroy()
                end
                if espObj.tracer then
                    espObj.tracer:Remove()
                end
                if espObj.box then
                    espObj.box:Destroy()
                end
            else
                espObj:Destroy()
            end
        end)
    end
    playerESPObjects = {}
    removeAllNametags()
end

-- Remove all nametags
function removeAllNametags()
    for player, nametag in pairs(playerNametagObjects) do
        pcall(function()
            nametag:Destroy()
        end)
    end
    playerNametagObjects = {}
end

-- Refresh all player ESP (when settings change)
function refreshAllPlayerESP()
    removeAllPlayerESP()
    if playerESPEnabled then
        createAllPlayerESP()
    end
end

-- Monitor for new players
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if playerESPEnabled then
            task.wait(0.5)
            createPlayerCham(player)
        end
    end)
end)

-- Monitor existing players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(character)
            if playerESPEnabled then
                task.wait(0.5)
                createPlayerCham(player)
            end
        end)
    end
end

-- === AIMBOT FUNCTIONS ===

-- Update FOV Circle position
RunService.RenderStepped:Connect(function()
    if showFOVCircle and aimbotEnabled then
        FOVCircle.Visible = true
        FOVCircle.Position =
            Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = aimbotFOV
    else
        FOVCircle.Visible = false
    end
end)

-- Check if target is visible (not behind walls)
local function isTargetVisible(targetPart)
    if not wallCheckEnabled then
        return true
    end

    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local distance = (targetPart.Position - origin).Magnitude

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances =
        { LocalPlayer.Character, targetPart.Parent }
    raycastParams.IgnoreWater = true

    local raycastResult =
        Workspace:Raycast(origin, direction * distance, raycastParams)

    -- If raycast hit nothing or hit the target, they're visible
    return raycastResult == nil
        or raycastResult.Instance:IsDescendantOf(targetPart.Parent)
end

-- Get closest player to cursor
local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mousePos =
        Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- Team check
            if aimbotTeamCheck and player.Team == LocalPlayer.Team then
                continue
            end

            local character = player.Character
            local targetPart = character:FindFirstChild(aimbotTargetPart)
            local humanoid = character:FindFirstChild('Humanoid')

            if targetPart and humanoid and humanoid.Health > 0 then
                -- Wall check
                if not isTargetVisible(targetPart) then
                    continue
                end

                local screenPos, onScreen =
                    Camera:WorldToViewportPoint(targetPart.Position)

                if onScreen then
                    local distance = (
                        Vector2.new(screenPos.X, screenPos.Y) - mousePos
                    ).Magnitude

                    if distance < aimbotFOV and distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Check if current target is still valid
local function isTargetValid(player)
    if not player or not player.Character then
        return false
    end

    local character = player.Character
    local targetPart = character:FindFirstChild(aimbotTargetPart)
    local humanoid = character:FindFirstChild('Humanoid')

    if not targetPart or not humanoid or humanoid.Health <= 0 then
        return false
    end

    -- Check if still visible
    if not isTargetVisible(targetPart) then
        return false
    end

    -- Team check
    if aimbotTeamCheck and player.Team == LocalPlayer.Team then
        return false
    end

    return true
end

-- Aimbot function
local function aimAt(player)
    if not player or not player.Character then
        return
    end

    local character = player.Character
    local targetPart = character:FindFirstChild(aimbotTargetPart)

    if not targetPart then
        return
    end

    local targetPosition = targetPart.Position
    local cameraPosition = Camera.CFrame.Position

    -- Calculate direction
    local direction = (targetPosition - cameraPosition).Unit
    local targetCFrame = CFrame.new(cameraPosition, cameraPosition + direction)

    -- Apply smoothing
    if aimbotSmoothness > 1 then
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / aimbotSmoothness)
    else
        Camera.CFrame = targetCFrame
    end
end

-- Start aimbot
function startAimbot()
    if aimbotConnection then
        return
    end

    aimbotConnection = RunService.RenderStepped:Connect(function()
        if aimbotEnabled and isAimbotKeyPressed then
            -- Sticky aim: keep current target if valid
            if stickyAim and currentTarget and isTargetValid(currentTarget) then
                aimAt(currentTarget)
            else
                -- Find new target
                local target = getClosestPlayerToCursor()
                if target then
                    currentTarget = target
                    aimAt(target)
                else
                    currentTarget = nil
                end
            end
        else
            -- Reset target when key is released
            currentTarget = nil
        end
    end)

    FOVCircle.Visible = showFOVCircle
end

-- Stop aimbot
function stopAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end

    FOVCircle.Visible = false
end

-- Keybind listener
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if
        input.UserInputType == Enum.UserInputType.MouseButton2 and aimbotEnabled
    then
        isAimbotKeyPressed = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAimbotKeyPressed = false
    end
end)

-- === TRIGGER BOT SYSTEM ===
-- Auto-shoot when camera is on target

local lastShotTime = 0
local shootCooldown = 0.1 -- 100ms between shots

-- Trigger bot function
RunService.RenderStepped:Connect(function()
    if
        silentAimEnabled
        and aimbotEnabled
        and isAimbotKeyPressed
        and currentTarget
    then
        local character = LocalPlayer.Character
        if not character then
            return
        end

        local targetChar = currentTarget.Character
        if not targetChar then
            return
        end

        local targetPart = targetChar:FindFirstChild(aimbotTargetPart)
        if not targetPart then
            return
        end

        -- Check if we're aiming close enough to target
        local screenPos, onScreen =
            Camera:WorldToViewportPoint(targetPart.Position)
        if onScreen then
            local centerScreen = Vector2.new(
                Camera.ViewportSize.X / 2,
                Camera.ViewportSize.Y / 2
            )
            local distance = (
                Vector2.new(screenPos.X, screenPos.Y) - centerScreen
            ).Magnitude

            -- If crosshair is within 50 pixels of target, auto-shoot
            if distance < 50 then
                local currentTime = tick()
                if currentTime - lastShotTime > shootCooldown then
                    lastShotTime = currentTime

                    -- Simulate mouse click
                    pcall(function()
                        mouse1click()
                    end)
                end
            end
        end
    end
end)

print('[Rivals Script] Trigger bot system initialized')
print('[Rivals Script] Will auto-shoot when aiming at target')

-- === AUTO FARM SYSTEM ===
-- Auto farm variables (must be defined before UI)
local autoFarmEnabled = false
local autoFarmStatus = 'Idle'
local autoFarmLoop = nil

-- Function to update auto farm status
local function updateAutoFarmStatus(status)
    autoFarmStatus = status
    print('[Auto Farm] ' .. status)
end

-- Function to teleport to a queue pad
local function teleportToQueuePad(padNumber)
    local success = false
    local errorMsg = ''

    pcall(function()
        local character = LocalPlayer.Character
        if not character then
            errorMsg = 'Error: No character found'
            updateAutoFarmStatus(errorMsg)
            return
        end

        local rootPart = character:FindFirstChild('HumanoidRootPart')
        if not rootPart then
            errorMsg = 'Error: No HumanoidRootPart found'
            updateAutoFarmStatus(errorMsg)
            return
        end

        -- Debug: Print workspace structure
        print('[Debug] Searching for Queue Pad #' .. padNumber)

        -- Try to find the queue pad in workspace
        -- Path: Workspace → Lobby → Hub → Extra → Important → Center → Duels
        local queuePad = nil

        if not Workspace:FindFirstChild('Lobby') then
            errorMsg = 'Error: Lobby not found in Workspace'
            updateAutoFarmStatus(errorMsg)
            print('[Debug] ' .. errorMsg)
            return
        end

        local lobby = Workspace.Lobby
        print('[Debug] Found Lobby')

        if not lobby:FindFirstChild('Hub') then
            errorMsg = 'Error: Hub not found in Lobby'
            updateAutoFarmStatus(errorMsg)
            print('[Debug] ' .. errorMsg)
            print('[Debug] Children in Lobby:')
            for _, child in pairs(lobby:GetChildren()) do
                print('[Debug]   - ' .. child.Name)
            end
            return
        end

        local hub = lobby.Hub
        print('[Debug] Found Hub')

        if not hub:FindFirstChild('Important') then
            errorMsg = 'Error: Important not found in Hub'
            updateAutoFarmStatus(errorMsg)
            print('[Debug] ' .. errorMsg)
            print('[Debug] Children in Hub:')
            for _, child in pairs(hub:GetChildren()) do
                print('[Debug]   - ' .. child.Name)
            end
            return
        end

        local important = hub.Important
        print('[Debug] Found Important')

        if not important:FindFirstChild('Center') then
            errorMsg = 'Error: Center not found in Important'
            updateAutoFarmStatus(errorMsg)
            print('[Debug] ' .. errorMsg)
            print('[Debug] Children in Important:')
            for _, child in pairs(important:GetChildren()) do
                print('[Debug]   - ' .. child.Name)
            end
            return
        end

        local center = important.Center
        print('[Debug] Found Center')

        if not center:FindFirstChild('Duels') then
            errorMsg = 'Error: Duels not found in Center'
            updateAutoFarmStatus(errorMsg)
            print('[Debug] ' .. errorMsg)
            print('[Debug] Children in Center:')
            for _, child in pairs(center:GetChildren()) do
                print('[Debug]   - ' .. child.Name)
            end
            return
        end

        local duels = center.Duels
        print('[Debug] Found Duels')

        local padName = 'Queue Pad #' .. padNumber
        local queuePadModel = duels:FindFirstChild(padName)

        if queuePadModel then
            print('[Debug] Found ' .. padName .. ' (Model)')

            -- Queue Pad is a Model, we need to find PadBase1 inside it
            local padBase = queuePadModel:FindFirstChild('PadBase1')

            if padBase then
                print('[Debug] Found PadBase1 inside ' .. padName)
                -- Teleport to the pad base (right on top)
                rootPart.CFrame = padBase.CFrame + Vector3.new(0, 5, 0)
                updateAutoFarmStatus('Teleported to Queue Pad #' .. padNumber)
                success = true
            else
                errorMsg = 'Error: PadBase1 not found in ' .. padName
                updateAutoFarmStatus(errorMsg)
                print('[Debug] ' .. errorMsg)
                print('[Debug] Children in ' .. padName .. ':')
                for _, child in pairs(queuePadModel:GetChildren()) do
                    print(
                        '[Debug]   - '
                            .. child.Name
                            .. ' ('
                            .. child.ClassName
                            .. ')'
                    )
                end
            end
        else
            errorMsg = 'Error: ' .. padName .. ' not found in Duels'
            updateAutoFarmStatus(errorMsg)
            print('[Debug] ' .. errorMsg)
            print('[Debug] Available children in Duels:')
            for _, child in pairs(duels:GetChildren()) do
                print(
                    '[Debug]   - '
                        .. child.Name
                        .. ' ('
                        .. child.ClassName
                        .. ')'
                )
            end
        end
    end)

    return success
end

-- Function to find and teleport to any available queue pad
local function teleportToAvailableQueuePad()
    -- Try Queue Pad #1 first
    if teleportToQueuePad(1) then
        return true
    end

    -- If #1 is not available, try #2
    task.wait(0.5)
    if teleportToQueuePad(2) then
        return true
    end

    -- If both are not available, try random pads from #1 to #10
    task.wait(0.5)
    for i = 1, 10 do
        local randomPad = math.random(1, 10)
        if teleportToQueuePad(randomPad) then
            return true
        end
        task.wait(0.3)
    end

    updateAutoFarmStatus('Error: No available queue pads found')
    return false
end

-- Auto farm main loop
local function startAutoFarm()
    if autoFarmLoop then
        return
    end

    autoFarmEnabled = true
    updateAutoFarmStatus('Starting auto farm...')

    autoFarmLoop = task.spawn(function()
        while autoFarmEnabled do
            pcall(function()
                -- Step 1: Teleport to queue pad
                updateAutoFarmStatus('Finding queue pad...')
                if teleportToAvailableQueuePad() then
                    task.wait(2)

                    -- Step 2: Wait to enter match
                    updateAutoFarmStatus('Waiting to enter match...')
                    task.wait(5)

                    -- Step 3: Kill opponent (aimbot will handle this)
                    updateAutoFarmStatus('In match - hunting opponent...')
                    task.wait(10)

                    -- Step 4: Wait for match to end
                    updateAutoFarmStatus('Waiting for match to end...')
                    task.wait(5)

                    -- Loop back
                    updateAutoFarmStatus('Match complete - restarting...')
                    task.wait(2)
                else
                    updateAutoFarmStatus(
                        'Failed to find queue pad - retrying...'
                    )
                    task.wait(5)
                end
            end)
            task.wait(1)
        end
    end)
end

-- Stop auto farm
local function stopAutoFarm()
    autoFarmEnabled = false
    if autoFarmLoop then
        task.cancel(autoFarmLoop)
        autoFarmLoop = nil
    end
    updateAutoFarmStatus('Auto farm stopped')
end

-- === AUTO FARM TAB UI ===
-- Must be after all functions are defined
local AutoFarmSection = AutoFarmTab:CreateSection('Auto Farm 1v1')

local AutoFarmToggle = AutoFarmTab:CreateToggle({
    Name = 'Enable Auto Farm',
    CurrentValue = false,
    Flag = 'AutoFarm',
    Callback = function(Value)
        if Value then
            startAutoFarm()
            Rayfield:Notify({
                Title = 'Auto Farm',
                Content = 'Auto farm started!',
                Duration = 2,
            })
        else
            stopAutoFarm()
            Rayfield:Notify({
                Title = 'Auto Farm',
                Content = 'Auto farm stopped',
                Duration = 2,
            })
        end
    end,
})

local StatusSection = AutoFarmTab:CreateSection('Status')
local StatusLabel = AutoFarmTab:CreateLabel('Status: Idle')

-- Update status label periodically
task.spawn(function()
    while true do
        pcall(function()
            StatusLabel:Set('Status: ' .. autoFarmStatus)
        end)
        task.wait(0.5)
    end
end)

local InfoAutoFarmSection = AutoFarmTab:CreateSection('Information')
local InfoAutoFarmLabel =
    AutoFarmTab:CreateLabel('💡 Auto farm will queue for 1v1 matches')
local InfoAutoFarmLabel2 =
    AutoFarmTab:CreateLabel('🎯 Make sure aimbot is enabled for kills')
local InfoAutoFarmLabel3 =
    AutoFarmTab:CreateLabel('🔄 Will loop continuously until disabled')

-- Auto-enable ESP on script load
task.wait(0.5) -- Wait for players to load
createAllPlayerESP()

-- Notification on load
Rayfield:Notify({
    Title = 'Rivals Script Loaded',
    Content = 'Script ready! Made by Resentvu',
    Duration = 5,
    Image = 4483362458,
})
