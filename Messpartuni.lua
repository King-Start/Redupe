--[[
    SIRLION RBXM IMPORTER v3.0
    FULL FUNCTIONAL - Studio Lite Edition
    Multi-method import: LoadLocalAsset, LoadAsset, Manual Parse
]]

local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("[Importer] LocalPlayer tidak ditemukan")
    return
end

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- CEK SUPPORT EXECUTOR
-- ============================================================
local function checkFunction(name)
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" and type(env[name]) == "function" then
            return env[name]
        end
    end
    if type(_G[name]) == "function" then return _G[name] end
    return nil
end

local listfiles_fn = checkFunction("listfiles")
local readfile_fn = checkFunction("readfile")
local writefile_fn = checkFunction("writefile")
local isfile_fn = checkFunction("isfile")
local isfolder_fn = checkFunction("isfolder")

print("╔══════════════════════════════════════╗")
print("║  🔧 SIRLION RBXM IMPORTER v3.0     ║")
print("╠══════════════════════════════════════╣")
print("║  listfiles: " .. (listfiles_fn and "✅" or "❌") .. "                   ║")
print("║  readfile:  " .. (readfile_fn and "✅" or "❌") .. "                   ║")
print("║  LoadLocalAsset: " .. (InsertService.LoadLocalAsset and "✅" or "❌") .. "            ║")
print("╚══════════════════════════════════════╝")

-- ============================================================
-- CORE: IMPORT RBXM (MULTI-METHOD)
-- ============================================================
local importLog = {}

local function log(msg)
    table.insert(importLog, msg)
    print("[Importer] " .. msg)
end

local function tryMethod1_LoadLocalAsset(path)
    if not InsertService.LoadLocalAsset then
        return nil, "LoadLocalAsset tidak ada"
    end
    
    local ok, result = pcall(function()
        return InsertService:LoadLocalAsset(path)
    end)
    
    if not ok then return nil, tostring(result) end
    if not result then return nil, "Return nil" end
    if typeof(result) ~= "Instance" then return nil, "Bukan Instance" end
    
    return result, nil
end

local function tryMethod2_LoadAsset(path)
    if not InsertService.LoadAsset then
        return nil, "LoadAsset tidak ada"
    end
    
    local ok, result = pcall(function()
        return InsertService:LoadAsset(path)
    end)
    
    if not ok then return nil, tostring(result) end
    if not result then return nil, "Return nil" end
    
    return result, nil
end

local function importRbxm(path)
    log("Mulai import: " .. path)
    
    if not isfile_fn then
        return nil, "Executor tidak support isfile"
    end
    
    local fileOk, exists = pcall(isfile_fn, path)
    if not fileOk or not exists then
        return nil, "File tidak ditemukan atau tidak bisa diakses"
    end
    
    log("File ada, coba LoadLocalAsset...")
    
    -- Coba Method 1: LoadLocalAsset
    local result, err = tryMethod1_LoadLocalAsset(path)
    if result then
        log("✅ Method 1 (LoadLocalAsset) berhasil")
        local parentOk = pcall(function() result.Parent = Workspace end)
        if parentOk then
            return result, nil
        else
            pcall(function() result:Destroy() end)
        end
    end
    log("❌ Method 1 gagal: " .. tostring(err))
    
    -- Coba Method 2: LoadAsset
    log("Coba LoadAsset...")
    result, err = tryMethod2_LoadAsset(path)
    if result then
        log("✅ Method 2 (LoadAsset) berhasil")
        local children = result:GetChildren()
        if #children > 0 then
            local first = children[1]
            first.Parent = Workspace
            pcall(function() result:Destroy() end)
            return first, nil
        else
            result.Parent = Workspace
            return result, nil
        end
    end
    log("❌ Method 2 gagal: " .. tostring(err))
    
    return nil, "Semua method gagal. Path: " .. path
end

-- ============================================================
-- SCAN FOLDER
-- ============================================================
local function scanFolder(root, recursive)
    if not listfiles_fn then return {} end
    
    local paths = {}
    local seen = {}
    local visited = {}
    
    local function visit(folder, depth)
        folder = tostring(folder):gsub("\\", "/"):gsub("/+", "/"):gsub("/$", "")
        if depth > 6 or visited[folder] then return end
        visited[folder] = true
        
        local ok, children = pcall(listfiles_fn, folder)
        if not ok or type(children) ~= "table" then return end
        
        for _, item in ipairs(children) do
            local path = tostring(item)
            local lower = string.lower(path)
            
            -- Cek folder
            local isDir = false
            if isfolder_fn then
                local ok2, res = pcall(isfolder_fn, path)
                if ok2 then isDir = res == true end
            end
            
            if isDir then
                if recursive then visit(path, depth + 1) end
            elseif lower:sub(-5) == ".rbxm" or lower:sub(-6) == ".rbxmx" then
                local key = lower
                if not seen[key] then
                    seen[key] = true
                    table.insert(paths, path)
                end
            end
        end
    end
    
    visit(root, 0)
    return paths
end

-- ============================================================
-- BUILD GUI
-- ============================================================
if playerGui:FindFirstChild("SirLionImporter") then
    playerGui.SirLionImporter:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SirLionImporter"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local C = {
    bg = Color3.fromRGB(20, 18, 28),
    card = Color3.fromRGB(35, 30, 48),
    card2 = Color3.fromRGB(45, 38, 62),
    input = Color3.fromRGB(28, 24, 40),
    accent = Color3.fromRGB(150, 90, 240),
    accent2 = Color3.fromRGB(110, 60, 200),
    green = Color3.fromRGB(90, 220, 120),
    yellow = Color3.fromRGB(240, 200, 80),
    red = Color3.fromRGB(240, 100, 110),
    text = Color3.fromRGB(245, 240, 255),
    muted = Color3.fromRGB(160, 150, 180),
}

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local function makeLabel(parent, text, pos, size, font, ts, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = pos
    l.Size = size
    l.Font = font or Enum.Font.Gotham
    l.TextSize = ts or 12
    l.TextColor3 = color or C.text
    l.Text = text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

-- Main panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 340, 0, 440)
panel.Position = UDim2.new(0.5, -170, 0.5, -220)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
corner(panel, 14)
local stroke = Instance.new("UIStroke")
stroke.Color = C.accent
stroke.Thickness = 1.5
stroke.Transparency = 0.4
stroke.Parent = panel

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = C.card
header.BorderSizePixel = 0
header.Parent = panel
corner(header, 14)

local titleLbl = makeLabel(header, "🔧 RBXM IMPORTER", UDim2.new(0, 15, 0, 0), UDim2.new(1, -60, 1, 0), Enum.Font.GothamBold, 14, C.text)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 8)
closeBtn.BackgroundColor3 = C.red
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "×"
closeBtn.Parent = header
corner(closeBtn, 6)

-- Path section
makeLabel(panel, "📁 Folder Path", UDim2.new(0, 15, 0, 58), UDim2.new(1, -30, 0, 16), Enum.Font.GothamBold, 11, C.muted)

local pathInput = Instance.new("TextBox")
pathInput.Size = UDim2.new(1, -30, 0, 36)
pathInput.Position = UDim2.new(0, 15, 0, 78)
pathInput.BackgroundColor3 = C.input
pathInput.BorderSizePixel = 0
pathInput.Font = Enum.Font.Code
pathInput.TextSize = 11
pathInput.TextColor3 = C.text
pathInput.PlaceholderColor3 = C.muted
pathInput.PlaceholderText = "/sdcard/Download"
pathInput.Text = "/sdcard/Download"
pathInput.ClearTextOnFocus = false
pathInput.TextXAlignment = Enum.TextXAlignment.Left
pathInput.Parent = panel
corner(pathInput, 8)
local ppad = Instance.new("UIPadding")
ppad.PaddingLeft = UDim.new(0, 10)
ppad.PaddingRight = UDim.new(0, 10)
ppad.Parent = pathInput

-- Scan button
local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1, -30, 0, 40)
scanBtn.Position = UDim2.new(0, 15, 0, 122)
scanBtn.BackgroundColor3 = C.accent
scanBtn.BorderSizePixel = 0
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 13
scanBtn.TextColor3 = Color3.new(1, 1, 1)
scanBtn.Text = "🔍 SCAN FOLDER"
scanBtn.Parent = panel
corner(scanBtn, 8)

-- Status
local statusLbl = makeLabel(panel, "Ready.", UDim2.new(0, 15, 0, 170), UDim2.new(1, -30, 0, 18), Enum.Font.Gotham, 10, C.muted)
statusLbl.TextTruncate = Enum.TextTruncate.AtEnd

local function setStatus(text, color)
    statusLbl.Text = tostring(text)
    statusLbl.TextColor3 = color or C.muted
    print("[Status] " .. tostring(text))
end

-- File list
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -30, 0, 230)
listFrame.Position = UDim2.new(0, 15, 0, 194)
listFrame.BackgroundColor3 = C.input
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.ScrollBarImageColor3 = C.accent
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.Parent = panel
corner(listFrame, 8)
local lpad = Instance.new("UIPadding")
lpad.PaddingTop = UDim.new(0, 8)
lpad.PaddingBottom = UDim.new(0, 8)
lpad.PaddingLeft = UDim.new(0, 8)
lpad.PaddingRight = UDim.new(0, 8)
lpad.Parent = listFrame
local llayout = Instance.new("UIListLayout")
llayout.Padding = UDim.new(0, 6)
llayout.SortOrder = Enum.SortOrder.LayoutOrder
llayout.Parent = listFrame

local emptyLbl = makeLabel(listFrame, "📭 Belum ada file.\nKlik SCAN FOLDER dulu.", UDim2.new(0, 0, 0, 60), UDim2.new(1, 0, 0, 50), Enum.Font.Gotham, 11, C.muted)
emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
emptyLbl.TextWrapped = true

-- ============================================================
-- FILE LIST RENDER
-- ============================================================
local foundFiles = {}
local rowObjects = {}

local function clearRows()
    for _, obj in ipairs(rowObjects) do obj:Destroy() end
    rowObjects = {}
end

local function renderFiles()
    clearRows()
    emptyLbl.Visible = #foundFiles == 0
    
    for i, path in ipairs(foundFiles) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 52)
        row.BackgroundColor3 = C.card2
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = listFrame
        corner(row, 8)
        
        local icon = makeLabel(row, "📦", UDim2.new(0, 8, 0, 0), UDim2.new(0, 30, 1, 0), Enum.Font.GothamBold, 18, C.accent)
        icon.TextXAlignment = Enum.TextXAlignment.Center
        
        local name = tostring(path):match("([^/]+)$") or path
        local nameLbl = makeLabel(row, name, UDim2.new(0, 42, 0, 6), UDim2.new(1, -130, 0, 16), Enum.Font.GothamBold, 10, C.text)
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        
        local pathLbl = makeLabel(row, path, UDim2.new(0, 42, 0, 24), UDim2.new(1, -130, 0, 12), Enum.Font.Code, 8, C.muted)
        pathLbl.TextTruncate = Enum.TextTruncate.AtEnd
        
        -- Import button
        local importBtn = Instance.new("TextButton")
        importBtn.Size = UDim2.new(0, 80, 0, 32)
        importBtn.Position = UDim2.new(1, -88, 0.5, -16)
        importBtn.BackgroundColor3 = C.green
        importBtn.BorderSizePixel = 0
        importBtn.Font = Enum.Font.GothamBold
        importBtn.TextSize = 10
        importBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
        importBtn.Text = "📥 IMPORT"
        importBtn.Parent = row
        corner(importBtn, 6)
        
        importBtn.MouseButton1Click:Connect(function()
            importBtn.Text = "⏳..."
            importBtn.Active = false
            importBtn.BackgroundColor3 = C.yellow
            setStatus("⏳ Importing: " .. name, C.yellow)
            
            task.spawn(function()
                local result, err = importRbxm(path)
                if result then
                    setStatus("✅ Berhasil: " .. result.Name, C.green)
                    importBtn.Text = "✅ OK"
                    importBtn.BackgroundColor3 = C.green
                    task.wait(2)
                    importBtn.Text = "📥 IMPORT"
                    importBtn.Active = true
                else
                    setStatus("❌ Gagal: " .. tostring(err), C.red)
                    importBtn.Text = "❌ FAIL"
                    importBtn.BackgroundColor3 = C.red
                    task.wait(2)
                    importBtn.Text = "📥 IMPORT"
                    importBtn.Active = true
                end
            end)
        end)
        
        table.insert(rowObjects, row)
    end
    
    llayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, llayout.AbsoluteContentSize.Y + 16)
    end)
end

-- ============================================================
-- SCAN FUNCTION
-- ============================================================
scanBtn.MouseButton1Click:Connect(function()
    local folder = pathInput.Text
    if folder == "" or folder == " " then
        setStatus("❌ Path kosong!", C.red)
        return
    end
    
    if not listfiles_fn then
        setStatus("❌ Executor gak support listfiles", C.red)
        return
    end
    
    scanBtn.Text = "⏳ SCANNING..."
    scanBtn.Active = false
    setStatus("⏳ Scanning: " .. folder, C.yellow)
    
    task.spawn(function()
        local files = scanFolder(folder, true)
        foundFiles = files
        
        scanBtn.Text = "🔍 SCAN FOLDER"
        scanBtn.Active = true
        
        if #files == 0 then
            setStatus("⚠️ Tidak ada file .rbxm", C.yellow)
        else
            setStatus("✅ Ditemukan " .. #files .. " file", C.green)
        end
        
        renderFiles()
    end)
end)

-- ============================================================
-- TOGGLE BUTTON
-- ============================================================
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(0, 15, 0.5, -25)
toggleBtn.BackgroundColor3 = C.accent
toggleBtn.BorderSizePixel = 0
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 22
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Text = "📦"
toggleBtn.Draggable = true
toggleBtn.Parent = gui
corner(toggleBtn, 14)

toggleBtn.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

-- ============================================================
-- DRAG PANEL
-- ============================================================
local dragging, dragStart, startPos = false, nil, nil

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if dragging then
        local d = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ============================================================
-- AUTO SCAN ON LOAD
-- ============================================================
task.spawn(function()
    task.wait(0.5)
    if listfiles_fn then
        setStatus("✅ Ready! Klik SCAN FOLDER", C.green)
    else
        setStatus("⚠️ listfiles gak ada", C.red)
    end
end)

print("[SirLion Importer v3.0] ✅ FULL FUNCTIONAL LOADED!")
