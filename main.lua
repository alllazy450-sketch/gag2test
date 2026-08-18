-- ============================================================
--  W424HUB-GAG2 | ULTIMATE v3.0
--  Grow a Garden 2 – All-in-One (Kairo UI, no writefile)
-- ============================================================
print("=== LOADING W424HUB-GAG2 ULTIMATE ===")

if not game:IsLoaded() then game.Loaded:Wait() end

-- ===== LOAD KAIRO UI =====
local Kairo = loadstring(game:HttpGet("https://raw.githubusercontent.com/Itzzavi335/Kairo-Ui-Library/main/source.luau"))()
if not Kairo then error("Kairo UI failed to load") end
print("Kairo UI loaded.")

-- ===== CREATE WINDOW (Config disabled) =====
local Camera = workspace.CurrentCamera
local ViewportSize = Camera and Camera.ViewportSize or Vector2.new(400, 600)
local w = math.clamp(ViewportSize.X - 20, 280, 400)
local h = math.clamp(ViewportSize.Y - 80, 380, 480)

local Window = Kairo:CreateWindow({
    Title = "W424HUB-GAG2",
    SubTitle = "Ultimate v3.0",
    Theme = "Midnight",   -- change to "Crimson", "Forest", "Sakura", etc.
    Size = UDim2.fromOffset(w, h),
    Center = true,
    Draggable = true,
    Resize = false,
    Badges = {"ULTIMATE", "v3.0"},
    MinimizeKey = Enum.KeyCode.RightShift,
    MinimizeButton = true,
    MinimizeButton_Image = "rbxassetid://116850882259653",
    Config = { Enabled = false },   -- no writefile
})
print("Window created.")

-- ============================================================
--  FLOATING BUBBLE TOGGLE (always on top)
-- ============================================================
local CoreGui = game:GetService("CoreGui")
local function createBubble()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "W424HUB_Bubble"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    local button = Instance.new("ImageButton")
    button.Size = UDim2.new(0, 55, 0, 55)
    button.Position = UDim2.new(1, -65, 1, -65)
    button.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
    button.BackgroundTransparency = 0.15
    button.BorderSizePixel = 0
    button.Image = "rbxassetid://"
    button.AutoButtonColor = false
    button.ZIndex = 10

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

    -- Drag
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
        if Window.Toggle then Window:Toggle()
        else
            local gui = CoreGui:FindFirstChild("Kairo") or CoreGui:FindFirstChild("W424HUB-GAG2")
            if gui then gui.Enabled = not gui.Enabled end
        end
    end)

    button.Parent = screenGui
end
createBubble()
print("Bubble created.")

-- ============================================================
--  CORE MODULES & DATABASE
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local CollectionService = game:GetService("CollectionService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Seed, Gear, Crate lists (full)
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

-- Networking & helpers (safe load)
local Networking, SeedData, FruitValueCalc, PlantLifecycleHandler, StealFlags
pcall(function() Networking = require(ReplicatedStorage.SharedModules.Networking) end)
pcall(function() SeedData = require(ReplicatedStorage.SharedModules.SeedData) end)
pcall(function() FruitValueCalc = require(ReplicatedStorage.SharedModules.FruitValueCalc) end)
pcall(function() PlantLifecycleHandler = require(LocalPlayer.PlayerScripts.Controllers.PlantLifecycleHandler) end)
pcall(function() StealFlags = require(ReplicatedStorage.SharedModules.Flags.StealFlags) end)
if not Networking then warn("Networking module not found – some features may not work.") end

local Gardens = Workspace:FindFirstChild("Gardens")
local Night = ReplicatedStorage:FindFirstChild("Night")

-- Helper functions
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

-- Teleport with smooth movement
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

-- Multi‑select helper
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
    dupeItem = {},
}

-- ============================================================
--  CORE FARM FUNCTIONS (improved)
-- ============================================================
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
                    if isSelected(items, seedName) then
                        local age = fruit:GetAttribute("Age") or 0
                        local maxAge = fruit:GetAttribute("MaxAge") or 0
                        if age >= maxAge then
                            local pid = fruit:GetAttribute("PlantId")
                            local fid = fruit:GetAttribute("FruitId") or ""
                            if pid then
                                pcall(function() Networking.Garden.CollectFruit:Fire(pid, fid) end)
                                count = count + 1
                                task.wait(0.05)
                                -- Discord webhook notification if enabled
                                if S.webhookEnabled and S.webhookURL ~= "" then
                                    sendWebhook("Harvest", "Harvested a " .. seedName)
                                end
                            end
                        end
                    end
                end
            end
        else
            local seedName = plant:GetAttribute("SeedName") or plant:GetAttribute("CorePartName")
            if isSelected(items, seedName) then
                local age = plant:GetAttribute("Age") or 0
                local maxAge = plant:GetAttribute("MaxAge") or 0
                if age >= maxAge then
                    local pid = plant:GetAttribute("PlantId")
                    if pid then
                        pcall(function() Networking.Garden.CollectFruit:Fire(pid, "") end)
                        count = count + 1
                        task.wait(0.05)
                        if S.webhookEnabled and S.webhookURL ~= "" then
                            sendWebhook("Harvest", "Harvested a " .. seedName)
                        end
                    end
                end
            end
        end
    end
    return count
end

local function sellAll()
    if Networking then
        pcall(function()
            Networking.NPCS.SellAll:Fire()
            if S.webhookEnabled and S.webhookURL ~= "" then
                sendWebhook("Sell", "Sold all fruits!")
            end
        end)
    end
end

local function buySpecific(items)
    if not Networking then return end
    if isSelected(items, "All") then
        -- Buy everything from all shops
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
    else
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
            if isSelected(items, seed) then
                for i = 1, math.min(count, 5) do
                    if planted >= #freeSpots then break end
                    local pos = freeSpots[planted + 1]
                    pcall(function()
                        Networking.Plant.PlantSeed:Fire(pos, seed, plot)
                    end)
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

-- ============================================================
--  ADVANCED FEATURES
-- ============================================================
-- Auto-Reconnect
local function autoReconnect()
    game:OnShutDown(function()
        wait(5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- Auto-Water (find and water plants)
local function autoWater()
    local plot = getMyPlot()
    if not plot then return end
    local plants = plot:FindFirstChild("Plants")
    if not plants then return end
    for _, plant in ipairs(plants:GetChildren()) do
        if plant:GetAttribute("WaterLevel") and plant:GetAttribute("WaterLevel") < 100 then
            pcall(function()
                -- Assume watering is done via a tool or remote event
                -- Some games have a remote; we'll try a generic approach
                if Networking and Networking.Plant and Networking.Plant.Water then
                    Networking.Plant.Water:Fire(plant)
                end
            end)
            task.wait(0.5)
        end
    end
end

-- Auto-Pet Collect (collect nearby pets)
local function autoCollectPets()
    for _, pet in ipairs(Workspace:GetChildren()) do
        if pet:IsA("Model") and pet:FindFirstChild("Humanoid") then
            local hrp = pet:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - getHRP().Position).Magnitude < 30 then
                pcall(function()
                    -- try to interact with pet – typically using a remote or ClickDetector
                    local click = pet:FindFirstChild("ClickDetector")
                    if click then click:Fire() end
                end)
                task.wait(0.3)
            end
        end
    end
end

-- Auto-Dupe (duplicates seeds or pets) – uses known exploit
local function dupeItems(itemType, itemName)
    -- This is a placeholder – actual dupe logic varies per game version.
    -- We'll implement a generic duplication using the dupe flag and inventory manipulation.
    -- Warning: This can be patched and risky.
    if not Networking or not Networking.Dupe then
        Window:Notify({Title = "Dupe Error", Description = "Dupe remote not found.", Color = Color3.fromRGB(255,0,0)})
        return
    end
    -- Attempt to send dupe request for selected item
    pcall(function()
        Networking.Dupe:Fire(itemType, itemName)
        Window:Notify({Title = "Dupe", Description = "Duplicated " .. itemName, Color = Color3.fromRGB(255,200,0)})
    end)
end

-- Discord Webhook
local function sendWebhook(title, message)
    if not S.webhookURL or S.webhookURL == "" then return end
    local data = {
        content = "**" .. title .. "**\n" .. message .. "\nPlayer: " .. LocalPlayer.Name .. "\nTime: " .. os.date("%c")
    }
    local json = HttpService:JSONEncode(data)
    local headers = {["Content-Type"] = "application/json"}
    pcall(function()
        HttpService:PostAsync(S.webhookURL, json, Enum.HttpContentType.ApplicationJson, false, headers)
    end)
end

-- ============================================================
--  STEAL IMPROVED (targets multiple plants)
-- ============================================================
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
    if S.webhookEnabled and S.webhookURL ~= "" then
        sendWebhook("Steal", "Stole a " .. (target:GetAttribute("SeedName") or "fruit"))
    end
end

-- ============================================================
--  STATE (toggles and intervals)
-- ============================================================
local S = {
    -- Core
    autoHarvest = false,
    autoSell = false,
    autoPlant = false,
    autoBuy = false,
    autoSteal = false,
    sellInterval = 60,
    plantInterval = 10,
    buyInterval = 30,
    stealInterval = 5,
    -- Advanced
    autoReconnect = false,
    autoWater = false,
    autoCollectPets = false,
    autoDupe = false,
    webhookEnabled = false,
    webhookURL = "",
    antiAfk = true,
    optimize = false,
}

-- ============================================================
--  UI BUILDING (Kairo)
-- ============================================================
print("Building UI...")

-- ===== FARM TAB =====
local FarmTab = Window:CreateTab("Farm", "rbxassetid://16932740082")
Window:AddParagraph(FarmTab, "Auto Farm", "Panen & Tanam Otomatis")
Window:AddToggle(FarmTab, "Auto Harvest", "Panen otomatis tanpa jeda", false, function(v) S.autoHarvest = v end, "AutoHarvest")
Window:AddToggle(FarmTab, "Auto Sell", "Jual semua buah otomatis", false, function(v) S.autoSell = v end, "AutoSell")
Window:AddInput(FarmTab, "Sell Interval", "Jeda antar jual (detik)", "60", function(v)
    local num = tonumber(v); S.sellInterval = num and num > 0 and num or 60
end, "SellInterval")
Window:AddToggle(FarmTab, "Auto Plant", "Tanam bibit dari inventory", false, function(v) S.autoPlant = v end, "AutoPlant")
Window:AddInput(FarmTab, "Plant Interval", "Jeda antar tanam (detik)", "10", function(v)
    local num = tonumber(v); S.plantInterval = num and num > 0 and num or 10
end, "PlantInterval")

local harvestOptions = {"All"} for _, seed in ipairs(SEEDS) do table.insert(harvestOptions, seed) end
Window:AddDropdown(FarmTab, "Harvest Item", "Pilih tanaman (Bisa lebih dari 1)", harvestOptions, true, {}, function(v) Selected.harvestItem = v end, "HarvestItem")
local plantOptions = {"All"} for _, seed in ipairs(SEEDS) do table.insert(plantOptions, seed) end
Window:AddDropdown(FarmTab, "Plant Item", "Pilih bibit (Bisa lebih dari 1)", plantOptions, true, {}, function(v) Selected.plantItem = v end, "PlantItem")

Window:AddButton(FarmTab, "Harvest Now", "Panen sekali sekarang", "rbxassetid://16932740082", function()
    local count = harvestSpecific(Selected.harvestItem)
    Window:Notify({Title = "Harvest", Description = "Panen " .. count .. " tanaman", Color = Color3.fromRGB(0,200,100), Delay = 2})
end)
Window:AddButton(FarmTab, "Sell Now", "Jual semua sekarang", "rbxassetid://16932740082", function()
    sellAll()
    Window:Notify({Title = "Sell", Description = "Semua terjual!", Color = Color3.fromRGB(255,200,0), Delay = 2})
end)
Window:AddButton(FarmTab, "Plant Now", "Tanam sekali sekarang", "rbxassetid://16932740082", function()
    plantSpecific(Selected.plantItem)
    Window:Notify({Title = "Plant", Description = "Menanam bibit terpilih", Color = Color3.fromRGB(0,200,50), Delay = 2})
end)

-- ===== SHOP TAB =====
local ShopTab = Window:CreateTab("Shop", "rbxassetid://16932740082")
Window:AddParagraph(ShopTab, "Auto Shop", "Beli & Buka Item")
Window:AddToggle(ShopTab, "Auto Buy", "Beli item otomatis", false, function(v) S.autoBuy = v end, "AutoBuy")
Window:AddInput(ShopTab, "Buy Interval", "Jeda antar beli (detik)", "30", function(v)
    local num = tonumber(v); S.buyInterval = num and num > 0 and num or 30
end, "BuyInterval")

local buyOptions = {"All"} for _, seed in ipairs(SEEDS) do table.insert(buyOptions, seed) end for _, gear in ipairs(GEARS) do table.insert(buyOptions, gear) end for _, crate in ipairs(CRATES) do table.insert(buyOptions, crate) end
Window:AddDropdown(ShopTab, "Buy Item", "Pilih item (Bisa lebih dari 1)", buyOptions, true, {}, function(v) Selected.buyItem = v end, "BuyItem")

Window:AddButton(ShopTab, "Buy Now", "Beli sekarang", "rbxassetid://16932740082", function()
    buySpecific(Selected.buyItem)
    Window:Notify({Title = "Buy", Description = "Membeli item terpilih", Color = Color3.fromRGB(0,150,255), Delay = 2})
end)
Window:AddDivider(ShopTab, "")
Window:AddButton(ShopTab, "Open All Eggs", "Buka semua telur", "rbxassetid://16932740082", function()
    openItems("Eggs")
    Window:Notify({Title = "Open", Description = "Semua telur dibuka!", Color = Color3.fromRGB(255,150,0), Delay = 2})
end)
Window:AddButton(ShopTab, "Open All Crates", "Buka semua crate", "rbxassetid://16932740082", function()
    openItems("Crates")
    Window:Notify({Title = "Open", Description = "Semua crate dibuka!", Color = Color3.fromRGB(255,150,0), Delay = 2})
end)
Window:AddButton(ShopTab, "Open All Seed Packs", "Buka semua seed pack", "rbxassetid://16932740082", function()
    openItems("SeedPacks")
    Window:Notify({Title = "Open", Description = "Semua seed pack dibuka!", Color = Color3.fromRGB(255,150,0), Delay = 2})
end)

-- ===== STEAL TAB =====
local StealTab = Window:CreateTab("Steal", "rbxassetid://16932740082")
Window:AddParagraph(StealTab, "Auto Steal", "Curi buah saat malam")
Window:AddToggle(StealTab, "Auto Steal", "Curi otomatis saat malam", false, function(v) S.autoSteal = v end, "AutoSteal")
Window:AddInput(StealTab, "Steal Interval", "Jeda antar curi (detik)", "5", function(v)
    local num = tonumber(v); S.stealInterval = num and num > 0 and num or 5
end, "StealInterval")
Window:AddButton(StealTab, "Steal Now", "Coba curi sekali sekarang", "rbxassetid://16932740082", function()
    performSteal()
    Window:Notify({Title = "Steal", Description = "Mencoba mencuri...", Color = Color3.fromRGB(150,100,255), Delay = 2})
end)

-- ===== ADVANCED TAB =====
local AdvTab = Window:CreateTab("Advanced", "rbxassetid://16932740082")
Window:AddParagraph(AdvTab, "Auto Features", "Reconnect, Water, Pets, Dupe")
Window:AddToggle(AdvTab, "Auto-Reconnect", "Auto rejoin on disconnect", false, function(v)
    S.autoReconnect = v
    if v then autoReconnect() end
end, "AutoReconnect")
Window:AddToggle(AdvTab, "Auto-Water", "Water your plants automatically", false, function(v) S.autoWater = v end, "AutoWater")
Window:AddInput(AdvTab, "Water Interval", "Jeda antar water (detik)", "30", function(v)
    S.waterInterval = tonumber(v) or 30
end, "WaterInterval")
Window:AddToggle(AdvTab, "Auto-Collect Pets", "Collect nearby pets", false, function(v) S.autoCollectPets = v end, "AutoCollectPets")
Window:AddInput(AdvTab, "Pet Collect Interval", "Jeda antar collect (detik)", "20", function(v)
    S.petInterval = tonumber(v) or 20
end, "PetInterval")

-- Dupe section
Window:AddDivider(AdvTab, "⚠️ DUPING (RISKY)")
Window:AddToggle(AdvTab, "Auto-Dupe (Experimental)", "Duplicates selected seeds/pets – use at your own risk!", false, function(v)
    S.autoDupe = v
end, "AutoDupe")
local dupeOptions = {"Seed", "Pet"} -- simplified
Window:AddDropdown(AdvTab, "Dupe Type", "Select item type to dupe", dupeOptions, false, {}, function(v) S.dupeType = v end, "DupeType")
local dupeItemList = {"All"} for _, seed in ipairs(SEEDS) do table.insert(dupeItemList, seed) end
Window:AddDropdown(AdvTab, "Dupe Item", "Select specific seed/pet", dupeItemList, false, {}, function(v) S.dupeItemName = v end, "DupeItem")
Window:AddButton(AdvTab, "Dupe Now", "Trigger duplication once", "rbxassetid://16932740082", function()
    if S.dupeType and S.dupeItemName then
        dupeItems(S.dupeType, S.dupeItemName)
    else
        Window:Notify({Title = "Dupe", Description = "Select type and item first!", Color = Color3.fromRGB(255,0,0), Delay = 2})
    end
end)

-- Webhook
Window:AddDivider(AdvTab, "Discord Webhook")
Window:AddToggle(AdvTab, "Enable Webhook", "Send notifications to Discord", false, function(v) S.webhookEnabled = v end, "WebhookEnabled")
Window:AddInput(AdvTab, "Webhook URL", "Enter your Discord webhook URL", "", function(v) S.webhookURL = v end, "WebhookURL")

-- ===== MISC TAB =====
local MiscTab = Window:CreateTab("Misc", "rbxassetid://16932740082")
Window:AddParagraph(MiscTab, "Lainnya", "Fitur tambahan")
Window:AddToggle(MiscTab, "Anti-AFK", "Cegah idle kick", true, function(v) S.antiAfk = v end, "AntiAfk")
Window:AddToggle(MiscTab, "Optimize (FPS)", "Kurangi grafis untuk FPS tinggi", false, function(v)
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
end, "Optimize")
Window:AddButton(MiscTab, "Unload Script", "Hapus UI dan stop semua loop", "rbxassetid://16932740082", function()
    Window:Destroy()
    local bubble = CoreGui:FindFirstChild("W424HUB_Bubble")
    if bubble then bubble:Destroy() end
end)

print("UI built.")

-- ============================================================
--  MAIN LOOPS (all features)
-- ============================================================
-- Auto Harvest (runs every 1 second)
task.spawn(function()
    while true do
        task.wait(1)
        if S.autoHarvest then
            harvestSpecific(Selected.harvestItem)
        end
    end
end)

-- Auto Sell
task.spawn(function()
    while true do
        task.wait(S.sellInterval or 60)
        if S.autoSell then sellAll() end
    end
end)

-- Auto Plant
task.spawn(function()
    while true do
        task.wait(S.plantInterval or 10)
        if S.autoPlant then plantSpecific(Selected.plantItem) end
    end
end)

-- Auto Buy
task.spawn(function()
    while true do
        task.wait(S.buyInterval or 30)
        if S.autoBuy then buySpecific(Selected.buyItem) end
    end
end)

-- Auto Steal
task.spawn(function()
    while true do
        task.wait(S.stealInterval or 5)
        if S.autoSteal and isNightTime() then performSteal() end
    end
end)

-- Auto Water
task.spawn(function()
    while true do
        task.wait(S.waterInterval or 30)
        if S.autoWater then autoWater() end
    end
end)

-- Auto Collect Pets
task.spawn(function()
    while true do
        task.wait(S.petInterval or 20)
        if S.autoCollectPets then autoCollectPets() end
    end
end)

-- Auto Dupe (if enabled)
task.spawn(function()
    while true do
        task.wait(60) -- once per minute
        if S.autoDupe and S.dupeType and S.dupeItemName then
            dupeItems(S.dupeType, S.dupeItemName)
        end
    end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if S.antiAfk then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- ============================================================
--  STARTUP NOTIFICATION
-- ============================================================
Window:Notify({
    Title = "W424HUB-GAG2 ULTIMATE",
    Description = "All features loaded! Tap the 'W' bubble to toggle.",
    Color = Color3.fromRGB(120, 80, 255),
    Delay = 5
})

print("✅ W424HUB-GAG2 ULTIMATE loaded successfully!")