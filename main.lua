-- ============================================================
--  W424HUB-GAG2 | V.3.0 (FLUENT LITE – PATCHED)
--  Grow a Garden 2 – Mobile-Optimized
-- ============================================================
print("=== LOADING W424HUB-GAG2 V.3.0 (FLUENT PATCHED) ===")

if not game:IsLoaded() then game.Loaded:Wait() end

-- ===== SAFE FLUENT LOADER WITH MULTIPLE SOURCES =====
local Fluent
local function fetchFluent()
    local urls = {
        "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
        "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/init.lua",
        "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/source.lua",
    }
    local errors = {}
    for _, url in ipairs(urls) do
        local ok, content = pcall(function() return game:HttpGet(url, true) end)
        if ok and content and type(content) == "string" and #content > 100 then
            local fn, compileErr = loadstring(content)
            if fn then
                local lib = fn()
                if lib and type(lib) == "table" and lib.CreateWindow then
                    print("✅ Fluent loaded from:", url)
                    return lib
                else
                    table.insert(errors, "Invalid library from " .. url)
                end
            else
                table.insert(errors, "Compile error: " .. tostring(compileErr))
            end
        else
            table.insert(errors, "Fetch failed: " .. tostring(ok) .. " (" .. tostring(content) .. ")")
        end
        task.wait(0.2)
    end
    error("All Fluent load attempts failed:\n" .. table.concat(errors, "\n"))
end

Fluent = fetchFluent()
print("Fluent Lite loaded successfully.")

-- ===== PATCH: Override internal size calculation =====
-- The original CreateWindow may try to read ViewportSize and fail.
-- We'll store the original method and wrap it to force a fixed size.
local originalCreateWindow = Fluent.CreateWindow
local fixedSize = UDim2.fromOffset(360, 420) -- Safe default for mobile

Fluent.CreateWindow = function(params)
    -- Force the Size parameter to a fixed UDim2 if not provided or invalid
    if not params.Size or type(params.Size) ~= "userdata" then
        params.Size = fixedSize
    end
    -- Also ensure no other nil values are passed
    return originalCreateWindow(params)
end

-- ===== CREATE WINDOW WITH FIXED SIZE =====
local Window
local function safeCreateWindow()
    local params = {
        Title = "W424HUB-GAG2",
        SubTitle = "V.3.0 | Grow a Garden 2",
        Size = fixedSize,
        MinimizeKey = Enum.KeyCode.RightShift,
    }
    local ok, result = pcall(function()
        return Fluent:CreateWindow(params)
    end)
    if ok and result then
        print("Window created with fixed size.")
        return result
    else
        warn("CreateWindow failed: " .. tostring(result))
        -- Fallback: call without Size, rely on patch
        params.Size = nil
        local ok2, result2 = pcall(function()
            return Fluent:CreateWindow(params)
        end)
        if ok2 and result2 then
            print("Window created without explicit size (patch applied).")
            return result2
        else
            error("Failed to create Fluent window: " .. tostring(result2))
        end
    end
end

Window = safeCreateWindow()
print("Window instance obtained.")

-- ============================================================
--  DATABASE AND CORE FUNCTIONS (unchanged)
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
--  UI BUILDING (FLUENT LITE – SAME AS BEFORE)
-- ============================================================
print("Building UI tabs...")

-- FARM TAB
local FarmTab = Window:AddTab({ Title = "Farm", Icon = "solar/plant-bold" })
FarmTab:AddParagraph({ Title = "Auto Farm", Content = "Panen & Tanam Otomatis" })
FarmTab:AddToggle("AutoHarvest", { Title = "Auto Harvest", Description = "Panen otomatis tanpa jeda", Default = false, Callback = function(v) S.autoHarvest = v end })
FarmTab:AddToggle("AutoSell", { Title = "Auto Sell", Description = "Jual semua buah otomatis", Default = false, Callback = function(v) S.autoSell = v end })
FarmTab:AddInput("SellInterval", { Title = "Sell Interval", Description = "Jeda antar jual (detik)", Default = "60", Numeric = true, Finished = true, Callback = function(v) S.sellInterval = tonumber(v) or 60 end })
FarmTab:AddToggle("AutoPlant", { Title = "Auto Plant", Description = "Tanam bibit dari inventory", Default = false, Callback = function(v) S.autoPlant = v end })
FarmTab:AddInput("PlantInterval", { Title = "Plant Interval", Description = "Jeda antar tanam (detik)", Default = "10", Numeric = true, Finished = true, Callback = function(v) S.plantInterval = tonumber(v) or 10 end })

local harvestOptions = {"All"} for _, seed in ipairs(SEEDS) do table.insert(harvestOptions, seed) end
FarmTab:AddDropdown("HarvestItem", { Title = "Harvest Item", Description = "Pilih tanaman (Bisa lebih dari 1)", Values = harvestOptions, Multi = true, Default = {"All"}, Callback = function(v) Selected.harvestItem = v end })

local plantOptions = {"All"} for _, seed in ipairs(SEEDS) do table.insert(plantOptions, seed) end
FarmTab:AddDropdown("PlantItem", { Title = "Plant Item", Description = "Pilih bibit (Bisa lebih dari 1)", Values = plantOptions, Multi = true, Default = {"All"}, Callback = function(v) Selected.plantItem = v end })

FarmTab:AddButton("HarvestNow", { Title = "Harvest Now", Description = "Panen sekali sekarang", Callback = function() local count = harvestSpecific(Selected.harvestItem); Fluent:Notify({ Title = "Harvest", Content = "Panen " .. count .. " tanaman", Duration = 2 }) end })
FarmTab:AddButton("SellNow", { Title = "Sell Now", Description = "Jual semua sekarang", Callback = function() sellAll(); Fluent:Notify({ Title = "Sell", Content = "Semua terjual!", Duration = 2 }) end })
FarmTab:AddButton("PlantNow", { Title = "Plant Now", Description = "Tanam sekali sekarang", Callback = function() plantSpecific(Selected.plantItem); Fluent:Notify({ Title = "Plant", Content = "Menanam bibit terpilih", Duration = 2 }) end })

-- SHOP TAB
local ShopTab = Window:AddTab({ Title = "Shop", Icon = "solar/cart-bold" })
ShopTab:AddParagraph({ Title = "Auto Shop", Content = "Beli & Buka Item" })
ShopTab:AddToggle("AutoBuy", { Title = "Auto Buy", Description = "Beli item otomatis", Default = false, Callback = function(v) S.autoBuy = v end })
ShopTab:AddInput("BuyInterval", { Title = "Buy Interval", Description = "Jeda antar beli (detik)", Default = "30", Numeric = true, Finished = true, Callback = function(v) S.buyInterval = tonumber(v) or 30 end })

local buyOptions = {"All"} for _, seed in ipairs(SEEDS) do table.insert(buyOptions, seed) end for _, gear in ipairs(GEARS) do table.insert(buyOptions, gear) end for _, crate in ipairs(CRATES) do table.insert(buyOptions, crate) end
ShopTab:AddDropdown("BuyItem", { Title = "Buy Item", Description = "Pilih item (Bisa lebih dari 1)", Values = buyOptions, Multi = true, Default = {"All"}, Callback = function(v) Selected.buyItem = v end })

ShopTab:AddButton("BuyNow", { Title = "Buy Now", Description = "Beli sekarang", Callback = function() buySpecific(Selected.buyItem); Fluent:Notify({ Title = "Buy", Content = "Membeli item terpilih", Duration = 2 }) end })
ShopTab:AddDivider()
ShopTab:AddButton("OpenEggs", { Title = "Open All Eggs", Description = "Buka semua telur", Callback = function() openItems("Eggs"); Fluent:Notify({ Title = "Open", Content = "Semua telur dibuka!", Duration = 2 }) end })
ShopTab:AddButton("OpenCrates", { Title = "Open All Crates", Description = "Buka semua crate", Callback = function() openItems("Crates"); Fluent:Notify({ Title = "Open", Content = "Semua crate dibuka!", Duration = 2 }) end })
ShopTab:AddButton("OpenSeedPacks", { Title = "Open All Seed Packs", Description = "Buka semua seed pack", Callback = function() openItems("SeedPacks"); Fluent:Notify({ Title = "Open", Content = "Semua seed pack dibuka!", Duration = 2 }) end })

-- STEAL TAB
local StealTab = Window:AddTab({ Title = "Steal", Icon = "solar/crime-bold" })
StealTab:AddParagraph({ Title = "Auto Steal", Content = "Curi buah saat malam" })
StealTab:AddToggle("AutoSteal", { Title = "Auto Steal", Description = "Curi otomatis saat malam", Default = false, Callback = function(v) S.autoSteal = v end })
StealTab:AddInput("StealInterval", { Title = "Steal Interval", Description = "Jeda antar curi (detik)", Default = "5", Numeric = true, Finished = true, Callback = function(v) S.stealInterval = tonumber(v) or 5 end })
StealTab:AddButton("StealNow", { Title = "Steal Now", Description = "Coba curi sekali sekarang", Callback = function() performSteal(); Fluent:Notify({ Title = "Steal", Content = "Mencoba mencuri...", Duration = 2 }) end })

-- MISC TAB
local MiscTab = Window:AddTab({ Title = "Misc", Icon = "solar/settings-bold" })
MiscTab:AddParagraph({ Title = "Lainnya", Content = "Fitur tambahan" })
MiscTab:AddToggle("AntiAfk", { Title = "Anti-AFK", Description = "Cegah idle kick", Default = true, Callback = function(v) S.antiAfk = v end })
MiscTab:AddToggle("Optimize", {
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
    end
})
MiscTab:AddButton("Unload", { Title = "Unload Script", Description = "Hapus UI dan stop script", Callback = function() Window:Destroy() end })

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

Fluent:Notify({
    Title = "W424HUB-GAG2",
    Content = "V.3.0 – Grow a Garden 2 | Press RightShift to toggle",
    Duration = 5
})

print("✅ W424HUB-GAG2 V.3.0 (Fluent Patched) fully loaded!")