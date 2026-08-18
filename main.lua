-- ============================================================
--  W424HUB-GAG2 | V.3.0 (WINDUI + CUSTOM THEME + BUBBLE)
--  Grow a Garden 2 – All-in-One
-- ============================================================
print("=== LOADING W424HUB-GAG2 V.3.0 (WINDUI) ===")

if not game:IsLoaded() then game.Loaded:Wait() end

-- ===== LOAD WINDUI =====
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
if not WindUI then error("WindUI gagal dimuat") end
print("WindUI loaded.")

-- ===== CREATE WINDOW WITH CUSTOM THEME =====
local Camera = workspace.CurrentCamera
local ViewportSize = Camera and Camera.ViewportSize or Vector2.new(400, 600)
local w = math.clamp(ViewportSize.X - 20, 280, 400)
local h = math.clamp(ViewportSize.Y - 80, 380, 480)

-- Customize these colors to your liking
local MyTheme = {
    Accent = Color3.fromRGB(120, 80, 255),   -- Purple-blue accent
    Background = Color3.fromRGB(18, 18, 28), -- Dark background
    Text = Color3.fromRGB(255, 255, 255),    -- White text
    -- You can also add: SubText, Border, etc.
}

local Window = WindUI:CreateWindow({
    Title = "W424HUB-GAG2",
    Author = "V.3.0 | Grow a Garden 2",
    Folder = "W424HUB_WindUI",
    Icon = "solar:folder-2-bold-duotone",
    Size = UDim2.fromOffset(w, h),
    Theme = MyTheme,   -- Apply custom theme
    OpenButton = {
        Enabled = false, -- disable default button (we use custom bubble)
    },
})
print("Window created with custom theme.")

-- ============================================================
--  CUSTOM FLOATING BUBBLE
-- ============================================================
local CoreGui = game:GetService("CoreGui")

local function createBubble()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "W424HUB_Bubble"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local button = Instance.new("ImageButton")
    button.Size = UDim2.new(0, 55, 0, 55)
    button.Position = UDim2.new(1, -65, 1, -65)
    button.BackgroundColor3 = MyTheme.Accent or Color3.fromRGB(120, 80, 255)
    button.BackgroundTransparency = 0.15
    button.BorderSizePixel = 0
    button.Image = "rbxassetid://"
    button.AutoButtonColor = false

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button

    local label = Instance.new("TextLabel")
    label.Text = "W"
    label.TextColor3 = Color3.new(1,1,1)
    label.TextSize = 24
    label.Font = Enum.Font.SourceSansBold
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1,0,1,0)
    label.Parent = button

    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1.2, 0, 1.2, 0)
    glow.Position = UDim2.new(-0.1, 0, -0.1, 0)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://"
    glow.ImageColor3 = MyTheme.Accent or Color3.fromRGB(120, 80, 255)
    glow.ImageTransparency = 0.8
    glow.ZIndex = 0
    glow.Parent = button

    -- Drag logic
    local dragging = false
    local dragStart, buttonStart
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            buttonStart = button.Position
        end
    end)
    button.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            local newX = buttonStart.X.Offset + delta.X
            local newY = buttonStart.Y.Offset + delta.Y
            local maxX = screenGui.AbsoluteSize.X - 55
            local maxY = screenGui.AbsoluteSize.Y - 55
            newX = math.clamp(newX, 0, maxX)
            newY = math.clamp(newY, 0, maxY)
            button.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    button.MouseButton1Click:Connect(function()
        Window:Toggle()
    end)

    button.Parent = screenGui
end

createBubble()
print("Custom bubble created.")

-- ============================================================
--  CORE DATABASE AND FUNCTIONS
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local CollectionService = game:GetService("CollectionService")
local VirtualUser = game:GetService("VirtualUser")

local SEEDS = {
    "Carrot", "Strawberry", "Blueberry", "Tulip", "Tomato", "Apple",
    "Bamboo", "Corn", "Cactus", "Pineapple", "Mushroom", "Green Bean",
    "Banana", "Grape", "Coconut", "Mango", "Dragon Fruit", "Acorn",
    "Cherry", "Sunflower", "Venus Fly Trap", "Pomegranate", "Poison Apple",
    "Venom Spitter", "Moon Bloom", "Hypno Bloom", "Dragon's Breath"
}

local GEARS = {
    "Common Watering Can", "Common Sprinkler", "Sign", "Uncommon Sprinkler",
    "Trowel", "Rare Sprinkler", "Jump Mushroom", "Speed Mushroom",
    "Lantern", "Shrink Mushroom", "Supersize Mushroom", "Gnome",
    "Flashbang", "Basic Pot", "Legendary Sprinkler", "Invisibility Mushroom",
    "Teleporter", "Wheelbarrow", "Super Watering Can", "Super Sprinkler"
}

local CRATES = {
    "Ladder Crate", "Bench Crate", "Light Crate", "Sign Crate",
    "Arch Crate", "Roleplay Crate", "Bridge Crate", "Spring Crate",
    "Seesaw Crate", "Conveyor Crate", "Owner Door Crate", "Bear Trap Crate",
    "Fence Crate", "Teleporter Pad Crate"
}

local Networking, SeedData, FruitValueCalc, PlantLifecycleHandler, StealFlags
pcall(function() Networking = require(ReplicatedStorage.SharedModules.Networking) end)
if not Networking then warn("Networking module failed to load.") end
pcall(function() SeedData = require(ReplicatedStorage.SharedModules.SeedData) end)
pcall(function() FruitValueCalc = require(ReplicatedStorage.SharedModules.FruitValueCalc) end)
pcall(function() PlantLifecycleHandler = require(LocalPlayer.PlayerScripts.Controllers.PlantLifecycleHandler) end)
pcall(function() StealFlags = require(ReplicatedStorage.SharedModules.Flags.StealFlags) end)

local Gardens = Workspace:FindFirstChild("Gardens")
local Night = ReplicatedStorage:FindFirstChild("Night")

local function getMyPlot()
    if not Gardens then return nil end
    for _, plot in ipairs(Gardens:GetChildren()) do
        if plot:GetAttribute("Owner") == LocalPlayer.Name then return plot end
    end
    return nil
end

local function isNightTime()
    return Night and Night.Value == true
end

local function getChar() return LocalPlayer.Character end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

local function teleportTo(targetCF, speed)
    speed = speed or 35
    local hrp = getHRP()
    if not hrp or not targetCF then return end
    local start = hrp.CFrame
    local dist = (targetCF.Position - start.Position).Magnitude
    if dist < 2 then return end
    local duration = dist / speed
    local con
    local elapsed = 0
    con = RunService.RenderStepped:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed >= duration then
            if hrp and hrp.Parent then hrp.CFrame = targetCF end
            if con then con:Disconnect() end
            return
        end
        local alpha = elapsed / duration
        if hrp and hrp.Parent then
            hrp.CFrame = start:Lerp(targetCF, alpha)
        else
            if con then con:Disconnect() end
        end
    end)
    task.wait(duration + 0.5)
    if con and con.Connected then con:Disconnect() end
end

local function isSelected(items, name)
    if not items then return false end
    if type(items) == "table" then
        for k, v in pairs(items) do
            if v == "All" or k == "All" then return true end
            if v == name or k == name then return true end
        end
        return false
    elseif type(items) == "string" then
        return items == "All" or items == name
    end
    return false
end

local Selected = {
    harvestItem = {},
    plantItem = {},
    buyItem = {},
}

local function harvestSpecific(items)
    local plot = getMyPlot()
    if not plot or not Networking then return 0 end
    local plants = plot:FindFirstChild("Plants")
    if not plants then return 0 end
    local count = 0
    for _, plant in ipairs(plants:GetChildren()) do
        local fruits = plant:FindFirstChild("Fruits")
        if fruits then
            for _, fruit in ipairs(fruits:GetChildren()) do
                if fruit:IsA("Model") then
                    local seedName = fruit:GetAttribute("SeedName") or fruit:GetAttribute("CorePartName")
                    local shouldHarvest = isSelected(items, seedName)
                    if shouldHarvest then
                        local age = fruit:GetAttribute("Age") or 0
                        local maxAge = fruit:GetAttribute("MaxAge") or 0
                        if age >= maxAge then
                            local pid = fruit:GetAttribute("PlantId")
                            local fid = fruit:GetAttribute("FruitId") or ""
                            if pid then
                                pcall(function() Networking.Garden.CollectFruit:Fire(pid, fid) end)
                                count = count + 1
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end
        else
            local seedName = plant:GetAttribute("SeedName") or plant:GetAttribute("CorePartName")
            local shouldHarvest = isSelected(items, seedName)
            if shouldHarvest then
                local age = plant:GetAttribute("Age") or 0
                local maxAge = plant:GetAttribute("MaxAge") or 0
                if age >= maxAge then
                    local pid = plant:GetAttribute("PlantId")
                    if pid then
                        pcall(function() Networking.Garden.CollectFruit:Fire(pid, "") end)
                        count = count + 1
                        task.wait(0.05)
                    end
                end
            end
        end
    end
    return count
end

local function sellAll()
    if Networking then pcall(function() Networking.NPCS.SellAll:Fire() end) end
end

local function buySpecific(items)
    if not Networking then return end
    if isSelected(items, "All") then buyItems(); return end
    pcall(function()
        local seedStock = ReplicatedStorage.StockValues.SeedShop.Items
        for _, item in ipairs(seedStock:GetChildren()) do
            if item:IsA("ValueBase") and item.Value > 0 and isSelected(items, item.Name) then
                Networking.SeedShop.PurchaseSeed:Fire(item.Name)
                task.wait(0.05)
            end
        end
    end)
    pcall(function()
        local gearStock = ReplicatedStorage.StockValues.GearShop.Items
        for _, item in ipairs(gearStock:GetChildren()) do
            if item:IsA("ValueBase") and item.Value > 0 and isSelected(items, item.Name) then
                Networking.GearShop.PurchaseGear:Fire(item.Name)
                task.wait(0.05)
            end
        end
    end)
    pcall(function()
        local crateStock = ReplicatedStorage.StockValues.CrateShop.Items
        for _, item in ipairs(crateStock:GetChildren()) do
            if item:IsA("ValueBase") and item.Value > 0 and isSelected(items, item.Name) then
                Networking.CrateShop.PurchaseCrate:Fire(item.Name)
                task.wait(0.05)
            end
        end
    end)
end

local function buyItems()
    if not Networking then return end
    pcall(function()
        local seedStock = ReplicatedStorage.StockValues.SeedShop.Items
        for _, item in ipairs(seedStock:GetChildren()) do
            if item:IsA("ValueBase") and item.Value > 0 then
                Networking.SeedShop.PurchaseSeed:Fire(item.Name)
                task.wait(0.05)
            end
        end
    end)
    pcall(function()
        local gearStock = ReplicatedStorage.StockValues.GearShop.Items
        for _, item in ipairs(gearStock:GetChildren()) do
            if item:IsA("ValueBase") and item.Value > 0 then
                Networking.GearShop.PurchaseGear:Fire(item.Name)
                task.wait(0.05)
            end
        end
    end)
    pcall(function()
        local crateStock = ReplicatedStorage.StockValues.CrateShop.Items
        for _, item in ipairs(crateStock:GetChildren()) do
            if item:IsA("ValueBase") and item.Value > 0 then
                Networking.CrateShop.PurchaseCrate:Fire(item.Name)
                task.wait(0.05)
            end
        end
    end)
end

local function plantSpecific(items)
    local plot = getMyPlot()
    if not plot or not Networking then return end
    local inv = LocalPlayer:GetAttribute("Inventory")
    if not inv or not inv.Seeds then return end
    local seeds = inv.Seeds
    local freeSpots = {}
    local function addSpotsFromArea(area)
        local size = area.Size
        local step = 6
        for x = -size.X/2 + 3, size.X/2 - 3, step do
            for z = -size.Z/2 + 3, size.Z/2 - 3, step do
                local pos = area.CFrame * CFrame.new(x, 0.5, z)
                table.insert(freeSpots, pos.Position)
            end
        end
    end
    for _, area in ipairs(plot:GetDescendants()) do
        if area:IsA("BasePart") and (area.Name == "PlantArea" or area.Name == "Soil") then
            addSpotsFromArea(area)
        end
    end
    for _, area in ipairs(CollectionService:GetTagged("PlantArea")) do
        if area:IsDescendantOf(plot) then
            addSpotsFromArea(area)
        end
    end
    if #freeSpots == 0 then return end
    local planted = 0
    for seed, count in pairs(seeds) do
        if count > 0 and planted < 40 then
            local shouldPlant = isSelected(items, seed)
            if shouldPlant then
                for i = 1, math.min(count, 5) do
                    if planted >= #freeSpots then break end
                    local pos = freeSpots[planted + 1]
                    pcall(function() Networking.Plant.PlantSeed:Fire(pos, seed, plot) end)
                    planted = planted + 1
                    task.wait(0.1)
                end
            end
        end
    end
end

local function openItems(category)
    if not Networking then return end
    local inv = LocalPlayer:GetAttribute("Inventory") or {}
    local pkt
    if category == "Eggs" then pkt = Networking.Egg.OpenEgg
    elseif category == "Crates" then pkt = Networking.Crate.OpenCrate
    elseif category == "SeedPacks" then pkt = Networking.SeedPack.OpenSeedPack
    else return end
    for name, count in pairs(inv[category] or {}) do
        for i = 1, count do
            pcall(function() pkt:Fire(name) end)
            task.wait(0.1)
        end
    end
end

local function performSteal()
    if not isNightTime() or not Networking then return end
    local target = nil
    for _, plot in ipairs(Gardens:GetChildren()) do
        local plants = plot:FindFirstChild("Plants")
        if plants then
            for _, plant in ipairs(plants:GetChildren()) do
                local fruits = plant:FindFirstChild("Fruits")
                if fruits then
                    for _, fruit in ipairs(fruits:GetChildren()) do
                        if fruit:IsA("Model") then
                            local seedName = fruit:GetAttribute("SeedName") or fruit:GetAttribute("CorePartName")
                            if seedName and StealFlags and StealFlags.IsPlantStealable and StealFlags.IsPlantStealable(seedName) then
                                local ownerId = fruit:GetAttribute("UserId")
                                if ownerId then
                                    local owner = Players:GetPlayerByUserId(tonumber(ownerId))
                                    if owner and owner ~= LocalPlayer and not owner:GetAttribute("IsInOwnGarden") then
                                        target = fruit
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                if target then break end
            end
        end
        if target then break end
    end
    if not target then return end
    local ownerId = target:GetAttribute("UserId")
    local plantId = target:GetAttribute("PlantId")
    local fruitId = target:GetAttribute("FruitId") or ""
    if not (ownerId and plantId) then return end
    local plot = getMyPlot()
    if not plot then return end
    local ref = plot:FindFirstChild("PlotSizeReference")
    if not ref then return end
    local home = ref.CFrame
    local bp = target:FindFirstChildWhichIsA("BasePart")
    if not bp then return end
    local targetCF = bp.CFrame + Vector3.new(0, 3, 0)
    teleportTo(targetCF, 33)
    task.wait(0.5)
    pcall(function() Networking.Steal.BeginSteal:Fire(tonumber(ownerId), plantId, fruitId) end)
    task.wait(0.1)
    pcall(function() Networking.Steal.CompleteSteal:Fire() end)
    task.wait(0.5)
    teleportTo(home, 33)
end

-- ============================================================
--  STATE
-- ============================================================
local S = {
    autoHarvest = false,
    autoSell = false,
    autoSteal = false,
    autoBuy = false,
    autoPlant = false,
    sellInterval = 60,
    stealInterval = 5,
    plantInterval = 10,
    buyInterval = 30,
    antiAfk = true,
    optimize = false,
}

-- ============================================================
--  UI BUILDING (WINDUI)
-- ============================================================
print("Building UI tabs...")

-- FARM TAB
local FarmTab = Window:Tab({ Title = "Farm", Icon = "solar:plant-bold" })
FarmTab:Paragraph({ Title = "Auto Farm", Content = "Panen & Tanam Otomatis" })
FarmTab:Toggle({
    Title = "Auto Harvest",
    Description = "Panen otomatis tanpa jeda",
    Default = false,
    Callback = function(v) S.autoHarvest = v end,
})
FarmTab:Toggle({
    Title = "Auto Sell",
    Description = "Jual semua buah otomatis",
    Default = false,
    Callback = function(v) S.autoSell = v end,
})
FarmTab:Slider({
    Title = "Sell Interval",
    Description = "Jeda antar jual (detik)",
    Min = 10,
    Max = 120,
    Default = 60,
    Callback = function(v) S.sellInterval = v end,
})
FarmTab:Toggle({
    Title = "Auto Plant",
    Description = "Tanam bibit dari inventory",
    Default = false,
    Callback = function(v) S.autoPlant = v end,
})
FarmTab:Slider({
    Title = "Plant Interval",
    Description = "Jeda antar tanam (detik)",
    Min = 5,
    Max = 60,
    Default = 10,
    Callback = function(v) S.plantInterval = v end,
})

local harvestOptions = {"All"} for _, seed in ipairs(SEEDS) do table.insert(harvestOptions, seed) end
FarmTab:Dropdown({
    Title = "Harvest Item",
    Description = "Pilih tanaman (Bisa lebih dari 1)",
    Options = harvestOptions,
    Multiselect = true,
    Default = {"All"},
    Callback = function(v) Selected.harvestItem = v end,
})

local plantOptions = {"All"} for _, seed in ipairs(SEEDS) do table.insert(plantOptions, seed) end
FarmTab:Dropdown({
    Title = "Plant Item",
    Description = "Pilih bibit (Bisa lebih dari 1)",
    Options = plantOptions,
    Multiselect = true,
    Default = {"All"},
    Callback = function(v) Selected.plantItem = v end,
})

FarmTab:Button({
    Title = "Harvest Now",
    Callback = function()
        local count = harvestSpecific(Selected.harvestItem)
        WindUI:Notify({ Title = "Harvest", Content = "Panen " .. count .. " tanaman", Duration = 2 })
    end,
})
FarmTab:Button({
    Title = "Sell Now",
    Callback = function()
        sellAll()
        WindUI:Notify({ Title = "Sell", Content = "Semua terjual!", Duration = 2 })
    end,
})
FarmTab:Button({
    Title = "Plant Now",
    Callback = function()
        plantSpecific(Selected.plantItem)
        WindUI:Notify({ Title = "Plant", Content = "Menanam bibit terpilih", Duration = 2 })
    end,
})

-- SHOP TAB
local ShopTab = Window:Tab({ Title = "Shop", Icon = "solar:cart-bold" })
ShopTab:Paragraph({ Title = "Auto Shop", Content = "Beli & Buka Item" })
ShopTab:Toggle({
    Title = "Auto Buy",
    Description = "Beli item otomatis",
    Default = false,
    Callback = function(v) S.autoBuy = v end,
})
ShopTab:Slider({
    Title = "Buy Interval",
    Description = "Jeda antar beli (detik)",
    Min = 10,
    Max = 120,
    Default = 30,
    Callback = function(v) S.buyInterval = v end,
})

local buyOptions = {"All"} for _, seed in ipairs(SEEDS) do table.insert(buyOptions, seed) end for _, gear in ipairs(GEARS) do table.insert(buyOptions, gear) end for _, crate in ipairs(CRATES) do table.insert(buyOptions, crate) end
ShopTab:Dropdown({
    Title = "Buy Item",
    Description = "Pilih item (Bisa lebih dari 1)",
    Options = buyOptions,
    Multiselect = true,
    Default = {"All"},
    Callback = function(v) Selected.buyItem = v end,
})

ShopTab:Button({
    Title = "Buy Now",
    Callback = function()
        buySpecific(Selected.buyItem)
        WindUI:Notify({ Title = "Buy", Content = "Membeli item terpilih", Duration = 2 })
    end,
})

ShopTab:Divider()
ShopTab:Button({
    Title = "Open All Eggs",
    Callback = function()
        openItems("Eggs")
        WindUI:Notify({ Title = "Open", Content = "Semua telur dibuka!", Duration = 2 })
    end,
})
ShopTab:Button({
    Title = "Open All Crates",
    Callback = function()
        openItems("Crates")
        WindUI:Notify({ Title = "Open", Content = "Semua crate dibuka!", Duration = 2 })
    end,
})
ShopTab:Button({
    Title = "Open All Seed Packs",
    Callback = function()
        openItems("SeedPacks")
        WindUI:Notify({ Title = "Open", Content = "Semua seed pack dibuka!", Duration = 2 })
    end,
})

-- STEAL TAB
local StealTab = Window:Tab({ Title = "Steal", Icon = "solar:crime-bold" })
StealTab:Paragraph({ Title = "Auto Steal", Content = "Curi buah saat malam" })
StealTab:Toggle({
    Title = "Auto Steal",
    Description = "Curi otomatis saat malam",
    Default = false,
    Callback = function(v) S.autoSteal = v end,
})
StealTab:Slider({
    Title = "Steal Interval",
    Description = "Jeda antar curi (detik)",
    Min = 1,
    Max = 30,
    Default = 5,
    Callback = function(v) S.stealInterval = v end,
})
StealTab:Button({
    Title = "Steal Now",
    Callback = function()
        performSteal()
        WindUI:Notify({ Title = "Steal", Content = "Mencoba mencuri...", Duration = 2 })
    end,
})

-- MISC TAB
local MiscTab = Window:Tab({ Title = "Misc", Icon = "solar:settings-bold" })
MiscTab:Paragraph({ Title = "Lainnya", Content = "Fitur tambahan" })
MiscTab:Toggle({
    Title = "Anti-AFK",
    Description = "Cegah idle kick",
    Default = true,
    Callback = function(v) S.antiAfk = v end,
})
MiscTab:Toggle({
    Title = "Optimize (FPS)",
    Description = "Kurangi grafis untuk FPS tinggi",
    Default = false,
    Callback = function(v)
        S.optimize = v
        if v then
            Lighting.GlobalShadows = false
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            for _, e in ipairs(Lighting:GetDescendants()) do
                if e:IsA("PostEffect") or e:IsA("Atmosphere") then
                    pcall(function() e.Enabled = false end)
                end
            end
        else
            Lighting.GlobalShadows = true
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        end
    end,
})
MiscTab:Button({
    Title = "Unload Script",
    Callback = function()
        Window:Destroy()
        local bubble = CoreGui:FindFirstChild("W424HUB_Bubble")
        if bubble then bubble:Destroy() end
    end,
})

print("All UI tabs built.")

-- ============================================================
--  MAIN LOOPS
-- ============================================================
task.spawn(function()
    while true do
        task.wait(1)
        if S.autoHarvest then harvestSpecific(Selected.harvestItem) end
    end
end)

task.spawn(function()
    while true do
        task.wait(S.sellInterval or 60)
        if S.autoSell then sellAll() end
    end
end)

task.spawn(function()
    while true do
        task.wait(S.plantInterval or 10)
        if S.autoPlant then plantSpecific(Selected.plantItem) end
    end
end)

task.spawn(function()
    while true do
        task.wait(S.buyInterval or 30)
        if S.autoBuy then buySpecific(Selected.buyItem) end
    end
end)

task.spawn(function()
    while true do
        task.wait(S.stealInterval or 5)
        if S.autoSteal and isNightTime() then performSteal() end
    end
end)

LocalPlayer.Idled:Connect(function()
    if S.antiAfk then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

WindUI:Notify({ Title = "W424HUB-GAG2", Content = "V.3.0 – Tap 'W' bubble to toggle", Duration = 5 })
print("✅ W424HUB-GAG2 V.3.0 (WindUI + custom theme + bubble) fully loaded!")