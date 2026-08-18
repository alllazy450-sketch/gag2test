-- ============================================================
--  W424HUB-GAG2 | GROW A GARDEN 2 FIXED (NO FREEZE)
-- ============================================================
print("=== LOADING W424HUB-GAG2 (FIXED) ===")

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local CollectionService = game:GetService("CollectionService")
local VirtualUser = game:GetService("VirtualUser")

-- ===== LOAD KAIRO UI =====
local Kairo = loadstring(game:HttpGet("https://raw.githubusercontent.com/Itzzavi335/Kairo-Ui-Library/refs/heads/main/source.luau"))()
if not Kairo then error("Kairo UI gagal dimuat") end

local ScreenSize = workspace.CurrentCamera.ViewportSize
local MobileWidth = math.clamp(ScreenSize.X - 20, 300, 420)
local MobileHeight = math.clamp(ScreenSize.Y - 80, 400, 500)

local Window = Kairo:CreateWindow({
    Title = "W424HUB-GAG2 | FIXED",
    Theme = "Midnight",
    Size = UDim2.fromOffset(MobileWidth, MobileHeight),
    Center = true,
    Draggable = true,
    Resize = false,
    Badges = {"GAG2", "FIXED"},
    MinimizeKey = Enum.KeyCode.RightShift,
    MinimizeButton = true,
    MinimizeButton_Image = "rbxassetid://116850882259653",
    Config = { Enabled = true, Folder = "W424HUB_GAG2", AutoLoad = true }
})

-- ============================================================
--  ITEM DATABASE (Grow a Garden 2 spesifik)
-- ============================================================
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

-- ============================================================
--  REMOTE CACHE (FIXED — hanya di-scan SEKALI)
-- ============================================================
local RemoteCache = {}

local function buildRemoteCache()
    -- Scan ReplicatedStorage SEKALI saat startup
    local function scan(container)
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local name = child.Name:lower()
                RemoteCache[name] = child
                RemoteCache[child.Name] = child
            end
            scan(child)
        end
    end
    scan(ReplicatedStorage)

    -- Scan folder Remotes jika ada
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesFolder then
        scan(remotesFolder)
    end

    -- Scan folder Network jika ada
    local networkFolder = ReplicatedStorage:FindFirstChild("Network")
    if networkFolder then
        scan(networkFolder)
    end

    print("[W424] Remote cache built: " .. table.len(RemoteCache) .. " remotes")
end

buildRemoteCache()

local function getRemoteCached(patterns)
    if type(patterns) == "string" then patterns = {patterns} end
    for _, pat in ipairs(patterns) do
        local patLower = pat:lower()
        -- Exact match
        if RemoteCache[patLower] then return RemoteCache[patLower] end
        if RemoteCache[pat] then return RemoteCache[pat] end
        -- Partial match (cari yang mengandung pattern)
        for name, remote in pairs(RemoteCache) do
            if string.find(name, patLower, 1, true) or string.find(patLower, name, 1, true) then
                return remote
            end
        end
    end
    return nil
end

local function fireRemoteSafe(patterns, ...)
    local remote = getRemoteCached(patterns)
    if not remote then
        -- Silent fail, jangan print error setiap kali (cuma sekali)
        local key = table.concat(patterns, ",")
        if not RemoteCache["_missing_" .. key] then
            RemoteCache["_missing_" .. key] = true
            -- warn("[W424] Remote not found: " .. key) -- matikan supaya gak spam
        end
        return false
    end
    local args = {...}
    local success, err = pcall(function()
        remote:FireServer(unpack(args))
    end)
    if not success then
        if not RemoteCache["_error_" .. remote.Name] then
            RemoteCache["_error_" .. remote.Name] = true
            warn("[W424] Remote error: " .. remote.Name .. " -> " .. tostring(err))
        end
        return false
    end
    return true
end

-- ============================================================
--  HELPERS
-- ============================================================
local function getMyPlot()
    local Gardens = Workspace:FindFirstChild("Gardens")
    if not Gardens then return nil end
    for _, plot in ipairs(Gardens:GetChildren()) do
        local owner = plot:GetAttribute("OwnerId") or plot:GetAttribute("Owner")
        if owner then
            if type(owner) == "number" and owner == LocalPlayer.UserId then
                return plot
            elseif type(owner) == "string" and owner == LocalPlayer.Name then
                return plot
            end
        end
    end
    return nil
end

local function isNightTime()
    local Night = ReplicatedStorage:FindFirstChild("Night")
    return Night and Night.Value == true
end

local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
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

-- ============================================================
--  HARVEST (OPTIMIZED)
-- ============================================================
local harvestPatterns = {"CollectFruit", "Harvest", "HarvestFruit", "Collect", "TakeFruit", "PickupFruit"}

local function harvestSpecific(items)
    local plot = getMyPlot()
    if not plot then return 0 end
    local plants = plot:FindFirstChild("Plants")
    if not plants then return 0 end

    local count = 0
    local processed = 0
    local toHarvest = {} -- Kumpulkan dulu, baru fire remote

    for _, plant in ipairs(plants:GetChildren()) do
        if plant:IsA("Model") then
            local fruits = plant:FindFirstChild("Fruits")
            if fruits then
                for _, fruit in ipairs(fruits:GetChildren()) do
                    if fruit:IsA("Model") then
                        local seedName = fruit:GetAttribute("SeedName") or fruit:GetAttribute("CorePartName")
                        if isSelected(items, seedName) then
                            local age = fruit:GetAttribute("Age") or 0
                            local maxAge = fruit:GetAttribute("MaxAge") or 0
                            if maxAge == 0 or age >= maxAge then
                                local pid = fruit:GetAttribute("PlantId")
                                local fid = fruit:GetAttribute("FruitId") or ""
                                if pid then
                                    table.insert(toHarvest, {pid = pid, fid = fid})
                                end
                            end
                        end
                    end
                    processed = processed + 1
                end
            else
                local seedName = plant:GetAttribute("SeedName") or plant:GetAttribute("CorePartName")
                if isSelected(items, seedName) then
                    local age = plant:GetAttribute("Age") or 0
                    local maxAge = plant:GetAttribute("MaxAge") or 0
                    if maxAge == 0 or age >= maxAge then
                        local pid = plant:GetAttribute("PlantId")
                        if pid then
                            table.insert(toHarvest, {pid = pid, fid = ""})
                        end
                    end
                end
            end
        end
        if processed % 20 == 0 then task.wait() end
    end

    -- Fire remote sekaligus dengan jeda aman
    for _, data in ipairs(toHarvest) do
        if fireRemoteSafe(harvestPatterns, data.pid, data.fid) then
            count = count + 1
        end
        if count % 5 == 0 then task.wait(0.1) end
    end

    if count > 0 then print("🌾 Harvested " .. count) end
    return count
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
    stealInterval = 10,
    plantInterval = 30,
    buyInterval = 30,
    antiAfk = true,
    optimize = false,
    autoWater = false,
    autoSprinkler = false,
    waterInterval = 60,
    autoExpand = false,
    autoShovel = false,
    autoClaim = false,
    onlyHarvestMutated = false,
    onlyHarvestFavorite = false,
    targetWeight = 0,
}

local Selected = {
    harvestItem = {},
    plantItem = {},
    buyItem = {},
}

local function AddNumberInput(tab, title, desc, default, callback, flag)
    if Window.AddInput then
        Window:AddInput(tab, title, desc, tostring(default), function(v)
            local num = tonumber(v)
            if num then callback(num) else callback(default) end
        end, flag)
    elseif Window.AddTextbox then
        Window:AddTextbox(tab, title, desc, tostring(default), function(v)
            local num = tonumber(v)
            if num then callback(num) else callback(default) end
        end, flag)
    else
        callback(default)
    end
end

-- ============================================================
--  PLANT
-- ============================================================
local plantPatterns = {"PlantSeed", "Plant", "PlantSeedling", "PlaceSeed"}

local function plantSpecific(items)
    local plot = getMyPlot()
    if not plot then return end
    local plantRemote = getRemoteCached(plantPatterns)
    if not plantRemote then return end

    local inv = LocalPlayer:GetAttribute("Inventory")
    if not inv or not inv.Seeds then return end
    local seeds = inv.Seeds

    local freeSpots = {}
    local function scanArea(areaPart)
        local size = areaPart.Size
        local step = 5
        local cf = areaPart.CFrame
        local processed = 0
        for x = -size.X/2 + step/2, size.X/2 - step/2, step do
            for z = -size.Z/2 + step/2, size.Z/2 - step/2, step do
                local pos = cf * CFrame.new(x, 0.5, z)
                local occupied = false
                local plantsContainer = plot:FindFirstChild("Plants")
                if plantsContainer then
                    for _, plant in ipairs(plantsContainer:GetChildren()) do
                        if plant:IsA("Model") then
                            local root = plant:FindFirstChild("HumanoidRootPart") or plant:FindFirstChildWhichIsA("BasePart")
                            if root and (root.Position - pos.Position).Magnitude < 2 then
                                occupied = true
                                break
                            end
                        end
                    end
                end
                if not occupied then
                    table.insert(freeSpots, pos.Position)
                end
                processed = processed + 1
            end
        end
    end

    for _, area in ipairs(plot:GetDescendants()) do
        if area:IsA("BasePart") and (area.Name == "PlantArea" or area.Name == "Soil") then
            scanArea(area)
            task.wait()
        end
    end
    for _, area in ipairs(CollectionService:GetTagged("PlantArea")) do
        if area:IsDescendantOf(plot) then
            scanArea(area)
            task.wait()
        end
    end

    if #freeSpots == 0 then return end

    local planted = 0
    local maxPerRun = math.min(#freeSpots, 10)
    for seed, count in pairs(seeds) do
        if count > 0 and planted < maxPerRun then
            if isSelected(items, seed) then
                for i = 1, math.min(count, 2) do
                    if planted >= maxPerRun then break end
                    local pos = freeSpots[planted + 1]
                    if pos then
                        pcall(function()
                            plantRemote:FireServer(pos, seed, plot)
                        end)
                        planted = planted + 1
                        task.wait(0.2)
                    end
                end
            end
        end
    end
    if planted > 0 then print("🌱 Planted " .. planted) end
end

-- ============================================================
--  SELL & BUY (Patterns spesifik untuk Grow a Garden 2)
-- ============================================================
local function sellAll()
    fireRemoteSafe({"SellAll", "SellAllFruits", "SellFruits", "SellInventory", "Sell"})
end

local buySeedPatterns = {"PurchaseSeed", "BuySeed", "SeedPurchase"}
local buyGearPatterns = {"PurchaseGear", "BuyGear", "GearPurchase"}
local buyCratePatterns = {"PurchaseCrate", "BuyCrate", "CratePurchase"}

local function buySpecific(items)
    if isSelected(items, "All") then buyItems(); return end
    local seedStock = ReplicatedStorage:FindFirstChild("StockValues") and ReplicatedStorage.StockValues:FindFirstChild("SeedShop") and ReplicatedStorage.StockValues.SeedShop:FindFirstChild("Items")
    if seedStock then
        for _, item in ipairs(seedStock:GetChildren()) do
            if item:IsA("ValueBase") and item.Value > 0 and isSelected(items, item.Name) then
                fireRemoteSafe(buySeedPatterns, item.Name)
                task.wait(0.1)
            end
        end
    end
    local gearStock = ReplicatedStorage:FindFirstChild("StockValues") and ReplicatedStorage.StockValues:FindFirstChild("GearShop") and ReplicatedStorage.StockValues.GearShop:FindFirstChild("Items")
    if gearStock then
        for _, item in ipairs(gearStock:GetChildren()) do
            if item:IsA("ValueBase") and item.Value > 0 and isSelected(items, item.Name) then
                fireRemoteSafe(buyGearPatterns, item.Name)
                task.wait(0.1)
            end
        end
    end
    local crateStock = ReplicatedStorage:FindFirstChild("StockValues") and ReplicatedStorage.StockValues:FindFirstChild("CrateShop") and ReplicatedStorage.StockValues.CrateShop:FindFirstChild("Items")
    if crateStock then
        for _, item in ipairs(crateStock:GetChildren()) do
            if item:IsA("ValueBase") and item.Value > 0 and isSelected(items, item.Name) then
                fireRemoteSafe(buyCratePatterns, item.Name)
                task.wait(0.1)
            end
        end
    end
end

local function buyItems()
    local seedStock = ReplicatedStorage:FindFirstChild("StockValues") and ReplicatedStorage.StockValues:FindFirstChild("SeedShop") and ReplicatedStorage.StockValues.SeedShop:FindFirstChild("Items")
    if seedStock then
        for _, item in ipairs(seedStock:GetChildren()) do
            if item:IsA("ValueBase") and item.Value > 0 then
                fireRemoteSafe(buySeedPatterns, item.Name)
                task.wait(0.1)
            end
        end
    end
    local gearStock = ReplicatedStorage:FindFirstChild("StockValues") and ReplicatedStorage.StockValues:FindFirstChild("GearShop") and ReplicatedStorage.StockValues.GearShop:FindFirstChild("Items")
    if gearStock then
        for _, item in ipairs(gearStock:GetChildren()) do
            if item:IsA("ValueBase") and item.Value > 0 then
                fireRemoteSafe(buyGearPatterns, item.Name)
                task.wait(0.1)
            end
        end
    end
    local crateStock = ReplicatedStorage:FindFirstChild("StockValues") and ReplicatedStorage.StockValues:FindFirstChild("CrateShop") and ReplicatedStorage.StockValues.CrateShop:FindFirstChild("Items")
    if crateStock then
        for _, item in ipairs(crateStock:GetChildren()) do
            if item:IsA("ValueBase") and item.Value > 0 then
                fireRemoteSafe(buyCratePatterns, item.Name)
                task.wait(0.1)
            end
        end
    end
end

-- ============================================================
--  WATER
-- ============================================================
local function autoWaterPlants()
    local plot = getMyPlot()
    if not plot then return end
    local plants = plot:FindFirstChild("Plants")
    if not plants then return end
    for _, plant in ipairs(plants:GetChildren()) do
        if plant:IsA("Model") then
            local waterLevel = plant:GetAttribute("WaterLevel") or 0
            local maxWater = plant:GetAttribute("MaxWater") or 100
            if maxWater > 0 and waterLevel < maxWater * 0.4 then
                local pid = plant:GetAttribute("PlantId")
                if pid then
                    fireRemoteSafe({"WaterPlant", "Water", "Hydrate"}, pid)
                    task.wait(0.15)
                end
            end
        end
    end
end

local function autoPlaceSprinkler()
    local plot = getMyPlot()
    if not plot then return end
    local inv = LocalPlayer:GetAttribute("Inventory") or {}
    local gears = inv.Gears or {}
    local hasSprinkler = false
    for name, count in pairs(gears) do
        if string.find(string.lower(name), "sprinkler") and count > 0 then
            hasSprinkler = true
            break
        end
    end
    if not hasSprinkler then return end
    local ref = plot:FindFirstChild("PlotSizeReference")
    if not ref then return end
    local pos = ref.CFrame * CFrame.new(0, 0.5, 0)
    fireRemoteSafe({"PlaceSprinkler", "SprinklerPlace", "PlaceGear"}, pos.Position, plot)
end

-- ============================================================
--  STEAL (optimized)
-- ============================================================
local function performSteal()
    if not isNightTime() then return end
    local Gardens = Workspace:FindFirstChild("Gardens")
    if not Gardens then return end
    local target = nil
    for _, plot in ipairs(Gardens:GetChildren()) do
        local plants = plot:FindFirstChild("Plants")
        if plants then
            for _, plant in ipairs(plants:GetChildren()) do
                local fruits = plant:FindFirstChild("Fruits")
                if fruits then
                    for _, fruit in ipairs(fruits:GetChildren()) do
                        if fruit:IsA("Model") then
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
    fireRemoteSafe({"BeginSteal", "StartSteal", "StealStart"}, tonumber(ownerId), plantId, fruitId)
    task.wait(0.1)
    fireRemoteSafe({"CompleteSteal", "FinishSteal"})
    task.wait(0.5)
    teleportTo(home, 33)
end

-- ============================================================
--  TELEPORT
-- ============================================================
local function teleportTo(targetCF, speed)
    speed = speed or 35
    local hrp = getHRP()
    if not hrp or not targetCF then return end
    local start = hrp.CFrame
    local dist = (targetCF.Position - start.Position).Magnitude
    if dist < 2 then return end
    local duration = dist / speed
    local con, elapsed = nil, 0
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

local function teleportToLocation(locationName)
    local hrp = getHRP()
    if not hrp then return end
    local loc = nil
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name == locationName or string.find(string.lower(part.Name), string.lower(locationName), 1, true)) then
            loc = part
            break
        end
    end
    if loc then
        local targetCF = loc.CFrame + Vector3.new(0, 3, 0)
        teleportTo(targetCF, 50)
    end
end

-- ============================================================
--  OPEN ITEMS
-- ============================================================
local function openItems(category)
    local inv = LocalPlayer:GetAttribute("Inventory") or {}
    local patterns
    if category == "Eggs" then patterns = {"OpenEgg", "EggOpen"}
    elseif category == "Crates" then patterns = {"OpenCrate", "CrateOpen"}
    elseif category == "SeedPacks" then patterns = {"OpenSeedPack", "SeedPackOpen"}
    else return end
    for name, count in pairs(inv[category] or {}) do
        for i = 1, count do
            fireRemoteSafe(patterns, name)
            task.wait(0.15)
        end
    end
end

-- ============================================================
--  UI – KAIRO
-- ============================================================
local FarmTab = Window:CreateTab("Farm", "rbxassetid://16932740082")
Window:AddParagraph(FarmTab, "Auto Farm", "Panen & Tanam Otomatis")
Window:AddToggle(FarmTab, "Auto Harvest", "Panen otomatis", false, function(v) S.autoHarvest = v end, "AutoHarvest")
Window:AddToggle(FarmTab, "Auto Sell", "Jual semua buah otomatis", false, function(v) S.autoSell = v end, "AutoSell")
AddNumberInput(FarmTab, "Sell Interval", "Jeda antar jual (detik)", 60, function(v) S.sellInterval = v end, "SellInterval")
Window:AddToggle(FarmTab, "Auto Plant", "Tanam bibit dari inventory", false, function(v) S.autoPlant = v end, "AutoPlant")
AddNumberInput(FarmTab, "Plant Interval", "Jeda antar tanam (detik)", 30, function(v) S.plantInterval = v end, "PlantInterval")
Window:AddDivider(FarmTab, "Harvest Filters")
Window:AddToggle(FarmTab, "Only Mutated", "Hanya panen buah yang bermutasi", false, function(v) S.onlyHarvestMutated = v end, "OnlyMutated")
Window:AddToggle(FarmTab, "Only Favorite", "Hanya panen buah favorit", false, function(v) S.onlyHarvestFavorite = v end, "OnlyFavorite")
AddNumberInput(FarmTab, "Min Weight", "Panen buah dengan berat >= nilai ini", 0, function(v) S.targetWeight = v end, "MinWeight")

local harvestOptions = {"All"}; for _, seed in ipairs(SEEDS) do table.insert(harvestOptions, seed) end
Window:AddDropdown(FarmTab, "Harvest Item", "Pilih tanaman (Bisa lebih dari 1)", harvestOptions, true, {}, function(v) Selected.harvestItem = v end, "HarvestItem")
local plantOptions = {"All"}; for _, seed in ipairs(SEEDS) do table.insert(plantOptions, seed) end
Window:AddDropdown(FarmTab, "Plant Item", "Pilih bibit (Bisa lebih dari 1)", plantOptions, true, {}, function(v) Selected.plantItem = v end, "PlantItem")

Window:AddButton(FarmTab, "Harvest Now", "Panen sekali sekarang", "rbxassetid://16932740082", function()
    local count = harvestSpecific(Selected.harvestItem)
    Window:Notify({Title = "Harvest", Description = "Panen " .. count .. " tanaman", Content = "Selesai", Color = Color3.fromRGB(0,200,100), Delay = 2})
end)
Window:AddButton(FarmTab, "Sell Now", "Jual semua sekarang", "rbxassetid://16932740082", function()
    sellAll()
    Window:Notify({Title = "Sell", Description = "Semua terjual!", Content = "", Color = Color3.fromRGB(255,200,0), Delay = 2})
end)
Window:AddButton(FarmTab, "Plant Now", "Tanam sekali sekarang", "rbxassetid://16932740082", function()
    plantSpecific(Selected.plantItem)
    Window:Notify({Title = "Plant", Description = "Menanam bibit terpilih", Content = "", Color = Color3.fromRGB(0,200,50), Delay = 2})
end)

local WaterTab = Window:CreateTab("Water", "rbxassetid://16932740082")
Window:AddParagraph(WaterTab, "Auto Water", "Siram & Sprinkler otomatis")
Window:AddToggle(WaterTab, "Auto Water", "Siram tanaman otomatis", false, function(v) S.autoWater = v end, "AutoWater")
Window:AddToggle(WaterTab, "Auto Sprinkler", "Pasang sprinkler otomatis", false, function(v) S.autoSprinkler = v end, "AutoSprinkler")
AddNumberInput(WaterTab, "Water Interval", "Jeda antar siram (detik)", 60, function(v) S.waterInterval = v end, "WaterInterval")

local ShopTab = Window:CreateTab("Shop", "rbxassetid://16932740082")
Window:AddParagraph(ShopTab, "Auto Shop", "Beli & Buka Item")
Window:AddToggle(ShopTab, "Auto Buy", "Beli item otomatis", false, function(v) S.autoBuy = v end, "AutoBuy")
AddNumberInput(ShopTab, "Buy Interval", "Jeda antar beli (detik)", 30, function(v) S.buyInterval = v end, "BuyInterval")
local buyOptions = {"All"}; for _, seed in ipairs(SEEDS) do table.insert(buyOptions, seed) end
for _, gear in ipairs(GEARS) do table.insert(buyOptions, gear) end
for _, crate in ipairs(CRATES) do table.insert(buyOptions, crate) end
Window:AddDropdown(ShopTab, "Buy Item", "Pilih item (Bisa lebih dari 1)", buyOptions, true, {}, function(v) Selected.buyItem = v end, "BuyItem")
Window:AddButton(ShopTab, "Buy Now", "Beli sekarang", "rbxassetid://16932740082", function()
    buySpecific(Selected.buyItem)
    Window:Notify({Title = "Buy", Description = "Membeli item terpilih", Content = "", Color = Color3.fromRGB(0,150,255), Delay = 2})
end)
Window:AddDivider(ShopTab, "")
Window:AddButton(ShopTab, "Open All Eggs", "Buka semua telur", "rbxassetid://16932740082", function()
    openItems("Eggs")
    Window:Notify({Title = "Open", Description = "Semua telur dibuka!", Content = "", Color = Color3.fromRGB(255,150,0), Delay = 2})
end)
Window:AddButton(ShopTab, "Open All Crates", "Buka semua crate", "rbxassetid://16932740082", function()
    openItems("Crates")
    Window:Notify({Title = "Open", Description = "Semua crate dibuka!", Content = "", Color = Color3.fromRGB(255,150,0), Delay = 2})
end)
Window:AddButton(ShopTab, "Open All Seed Packs", "Buka semua seed pack", "rbxassetid://16932740082", function()
    openItems("SeedPacks")
    Window:Notify({Title = "Open", Description = "Semua seed pack dibuka!", Content = "", Color = Color3.fromRGB(255,150,0), Delay = 2})
end)

local StealTab = Window:CreateTab("Steal", "rbxassetid://16932740082")
Window:AddParagraph(StealTab, "Auto Steal", "Curi buah saat malam")
Window:AddToggle(StealTab, "Auto Steal", "Curi otomatis saat malam", false, function(v) S.autoSteal = v end, "AutoSteal")
AddNumberInput(StealTab, "Steal Interval", "Jeda antar curi (detik)", 10, function(v) S.stealInterval = v end, "StealInterval")
Window:AddButton(StealTab, "Steal Now", "Coba curi sekali sekarang", "rbxassetid://16932740082", function()
    performSteal()
    Window:Notify({Title = "Steal", Description = "Mencoba mencuri...", Content = "", Color = Color3.fromRGB(150,100,255), Delay = 2})
end)

local AdvTab = Window:CreateTab("Adv", "rbxassetid://16932740082")
Window:AddParagraph(AdvTab, "Advanced", "Fitur tambahan")
Window:AddToggle(AdvTab, "Auto Expand", "Perluas kebun otomatis", false, function(v) S.autoExpand = v end, "AutoExpand")
Window:AddToggle(AdvTab, "Auto Shovel", "Buang tanaman terburuk", false, function(v) S.autoShovel = v end, "AutoShovel")
Window:AddToggle(AdvTab, "Auto Claim", "Klaim reward harian & redeem codes", false, function(v) S.autoClaim = v end, "AutoClaim")
Window:AddDivider(AdvTab, "Teleport")
Window:AddButton(AdvTab, "TP to Garden", "Teleport ke kebun sendiri", "rbxassetid://16932740082", function()
    teleportToLocation("Garden")
end)
Window:AddButton(AdvTab, "TP to Shop", "Teleport ke toko benih", "rbxassetid://16932740082", function()
    teleportToLocation("SeedShop")
end)
Window:AddButton(AdvTab, "TP to Crate Shop", "Teleport ke toko crate", "rbxassetid://16932740082", function()
    teleportToLocation("CrateShop")
end)
Window:AddButton(AdvTab, "TP to Mailbox", "Teleport ke mailbox", "rbxassetid://16932740082", function()
    teleportToLocation("Mailbox")
end)

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
Window:AddButton(MiscTab, "Unload Script", "Hapus UI dan stop script", "rbxassetid://16932740082", function()
    Window:Destroy()
end)

-- ============================================================
--  MAIN LOOPS (OPTIMIZED – JANGAN TERLALU CEPAT)
-- ============================================================
task.spawn(function()
    while true do
        task.wait(8) -- Lebih lambat dari 5 detik
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
        task.wait(S.plantInterval or 30)
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
        task.wait(S.stealInterval or 10)
        if S.autoSteal and isNightTime() then performSteal() end
    end
end)

task.spawn(function()
    while true do
        task.wait(S.waterInterval or 60)
        if S.autoWater then autoWaterPlants() end
        if S.autoSprinkler then autoPlaceSprinkler() end
    end
end)

task.spawn(function()
    while true do
        task.wait(120)
        if S.autoExpand then autoExpandGarden() end
    end
end)

task.spawn(function()
    while true do
        task.wait(180)
        if S.autoShovel then autoShovelWorstPlant() end
    end
end)

task.spawn(function()
    while true do
        task.wait(300)
        if S.autoClaim then autoClaimRewards() end
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

Window:Notify({
    Title = "W424HUB-GAG2 FIXED",
    Description = "No freeze – optimized remote calls",
    Content = "Harvest every 8s, Plant every 30s",
    Color = Color3.fromRGB(30, 30, 60),
    Delay = 6
})

print("✅ W424HUB-GAG2 FIXED LOADED – NO FREEZE!")