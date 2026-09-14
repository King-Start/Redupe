--[[
╔══════════════════════════════════════════════════════════╗
║  SIRLION RBXM IMPORTER v4.0 - ULTIMATE EDITION          ║
║  Studio Lite + Delta Executor Compatible                ║
║  Features:                                              ║
║    - Auto-detect executor support                       ║
║    - Multi-method import (LoadLocalAsset, LoadAsset)    ║
║    - Manual path input (kalo listfiles gak ada)         ║
║    - Auto-scan multiple folders                         ║
║    - Real-time log & status                             ║
║    - Import history                                     ║
║    - Drag & drop panel                                  ║
║    - Compact & expandable UI                            ║
╚══════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("[SirLion] LocalPlayer tidak ditemukan")
    return
end

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- CEK SUPPORT EXECUTOR (COMPREHENSIVE)
-- ============================================================
local function checkFunc(name)
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" and type(env[name]) == "function" then
            return env[name], "getgenv"
        end
    end
    if type(_G[name]) == "function" then
        return _G[name], "_G"
    end
    return nil, nil
end

local FUNCS = {
    listfiles = checkFunc("listfiles"),
    readfile = checkFunc("readfile"),
    writefile = checkFunc("writefile"),
    isfile = checkFunc("isfile"),
    isfolder = checkFunc("isfolder"),
    makefolder = checkFunc("makefolder"),
    delfile = checkFunc("delfile"),
    appendfile = checkFunc("appendfile"),
}

local SUPPORT = {
    listfiles = FUNCS.listfiles ~= nil,
    readfile = FUNCS.readfile ~= nil,
    writefile = FUNCS.writefile ~= nil,
    isfile = FUNCS.isfile ~= nil,
    isfolder = FUNCS.isfolder ~= nil,
    loadLocalAsset = InsertService.LoadLocalAsset ~= nil,
    loadAsset = InsertService.LoadAsset ~= nil,
}

print("╔══════════════════════════════════════════════════════════╗")
print("║  🔧 SIRLION RBXM IMPORTER v4.0                          ║")
print("╠══════════════════════════════════════════════════════════╣")
print("║  📋 EXECUTOR SUPPORT:                                   ║")
for k, v in pairs(SUPPORT) do
    print(string.format("║    %-18s : %s%s", k, v and "✅" or "❌", string.rep(" ", 20 - #k)))
end
print("╚══════════════════════════════════════════════════════════╝")

-- ============================================================
-- IMPORT LOG STORAGE
-- ============================================================
local importHistory = {}
local MAX_HISTORY = 50

-- ============================================================
-- CORE: IMPORT RBXM (MULTI-METHOD)
-- ============================================================
local function cleanErr(msg)
    local t = tostring(msg or "unknown error"):gsub("^.-:%d+: ", "")
    if #t > 200 then t = t:sub(1, 197) .. "..." end
    return t
end

local function importMethod_LoadLocalAsset(path)
    if not SUPPORT.loadLocalAsset then
        return nil, "LoadLocalAsset tidak tersedia"
    end
    
    local ok, result = pcall(function()
        return InsertService:LoadLocalAsset(path)
    end)
    
    if not ok then return nil, cleanErr(result) end
    if not result then return nil, "Return nil" end
    if typeof(result) ~= "Instance" then return nil, "Bukan Instance (dapet: " .. typeof(result) .. ")" end
    
    return result, nil
end

local function importMethod_LoadAsset(path)
    if not SUPPORT.loadAsset then
        return nil, "LoadAsset tidak tersedia"
    end
    
    local ok, result = pcall(function()
        return InsertService:LoadAsset(path)
    end)
    
    if not ok then return nil, cleanErr(result) end
    if not result then return nil, "Return nil" end
    
    return result, nil
end

local function importRbxm(path)
    if not path or path == "" then
        return nil, "Path kosong"
    end
    
    -- Verify file exists (kalo support)
    if SUPPORT.isfile then
        local ok, exists = pcall(FUNCS.isfile[1], path)
        if not ok then
            -- Coba tanpa verify, mungkin isfile error
        elseif not exists then
            return nil, "File tidak ditemukan: " .. path
        end
    end
    
    -- METHOD 1: LoadLocalAsset
    local result, err = importMethod_LoadLocalAsset(path)
    if result then
        return result, nil, "LoadLocalAsset"
    end
    
    -- METHOD 2: LoadAsset
    result, err = importMethod_LoadAsset(path)
    if result then
        -- Extract child if it's a model
        local children = result:GetChildren()
        if #children > 0 then
            local first = children[1]
            first.Parent = Workspace
            pcall(function() result:Destroy() end)
            return first, nil, "LoadAsset (extracted)"
        end
        result.Parent = Workspace
        return result, nil, "LoadAsset"
    end
    
    return nil, "Semua method gagal. Error: " .. tostring(err)
end

-- ============================================================
-- SCAN FOLDER (MULTI-PATH)
-- ============================================================
local function scanFolder(root, recursive)
    if not SUPPORT.listfiles then
        return {}, "listfiles tidak tersedia"
    end
    
    local paths = {}
    local seen = {}
    local visited = {}
    local listFn = FUNCS.listfiles[1]
    local isFolderFn = FUNCS.isfolder and FUNCS.isfolder[1] or nil
    
    local function visit(folder, depth)
        folder = tostring(folder):gsub("\\", "/"):gsub("/+", "/")
        if #folder > 1 then folder = folder:gsub("/$", "") end
        
        if depth > 5 or visited[folder] then return end
        visited[folder] = true
        
        local ok, children = pcall(listFn, folder)
        if not ok or type(children) ~= "table" then return end
        
        for _, item in ipairs(children) do
            local path = tostring(item)
            local lower = string.lower(path)
            
            -- Cek folder
            local isDir = false
            if isFolderFn then
                local ok2, res = pcall(isFolderFn, path)
                if ok2 then isDir = res == true end
            else
                -- Fallback: cek extension
                isDir = not lower:match("%.%w+$")
            end
            
            if isDir then
                if recursive then
                    visit(path, depth + 1)
                end
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
    return paths, nil
end

-- ============================================================
-- AUTO-DETECT FOLDERS
-- ============================================================
local function autoDetectFolders()
    if not SUPPORT.listfiles then
        return {}
    end
    
    local candidates = {
        "/sdcard/Download",
        "/sdcard/Documents",
        "/sdcard/Roblox",
        "/sdcard/Delta",
        "/sdcard/Plugins",
        "/sdcard/Projects",
        "/storage/emulated/0/Download",
        "/storage/emulated/0/Documents",
        "/storage/emulated/0/Roblox",
    }
    
    local found = {}
    local listFn = FUNCS.listfiles[1]
    
    for _, path in ipairs(candidates) do
        local ok, items = pcall(listFn, path)
        if ok and type(items) == "table" then
            local rbxmCount = 0
            for _, item in ipairs(items) do
                local lower = string.lower(tostring(item))
                if lower:sub(-5) == ".rbxm" or lower:sub(-6) == ".rbxmx" then
                    rbxmCount = rbxmCount + 1
                end
            end
            table.insert(found, {
                path = path,
                total = #items,
                rbxm = rbxmCount,
            })
        end
    end
    
    return found
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
gui.DisplayOrder = 100
gui.Parent = playerGui

-- Color palette
local C = {
    bg = Color3.fromRGB(18, 16, 26),
    panel = Color3.fromRGB(26, 22, 38),
    card = Color3.fromRGB(38, 32, 52),
    card2 = Color3.fromRGB(48, 40, 65),
    input = Color3.fromRGB(30, 26, 42),
    border = Color3.fromRGB(70, 55, 100),
    accent = Color3.fromRGB(150, 90, 240),
    accent2 = Color3.fromRGB(110, 60, 200),
    green = Color3.fromRGB(90, 220, 130),
    yellow = Color3.fromRGB(240, 200, 80),
    red = Color3.fromRGB(240, 100, 110),
    blue = Color3.fromRGB(100, 180, 240),
    text = Color3.fromRGB(245, 240, 255),
    muted = Color3.fromRGB(160, 150, 180),
    dim = Color3.fromRGB(90, 85, 105),
}

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

local function stroke(p, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.border
    s.Transparency = transparency or 0.3
    s.Thickness = thickness or 1
    s.Parent = p
    return s
end

local function mkLabel(parent, text, pos, size, font, ts, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = pos
    l.Size = size
    l.Font = font or Enum.Font.Gotham
    l.TextSize = ts or 12
    l.TextColor3 = color or C.text
    l.Text = text or ""
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function mkButton(parent, text, pos, size, bg, ts, color)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = bg or C.card
    b.BorderSizePixel = 0
    b.Position = pos
    b.Size = size
    b.Font = Enum.Font.GothamBold
    b.TextSize = ts or 12
    b.TextColor3 = color or C.text
    b.Text = text or ""
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b, 8)
    return b
end

local function addHover(btn, normal, over)
    btn.MouseEnter:Connect(function()
        if btn.Active ~= false then
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = over}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.Active ~= false then
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = normal}):Play()
        end
    end)
end

-- ============================================================
-- MAIN PANEL
-- ============================================================
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 380, 0, 520)
panel.Position = UDim2.new(0.5, -190, 0.5, -260)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
corner(panel, 16)
stroke(panel, C.accent, 0.4, 1.5)

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = C.panel
header.BorderSizePixel = 0
header.Parent = panel
corner(header, 16)

local titleLbl = mkLabel(header, "🔧 RBXM IMPORTER v4.0", UDim2.new(0, 16, 0, 0), UDim2.new(1, -80, 1, 0), Enum.Font.GothamBold, 14, C.text)

local closeBtn = mkButton(header, "×", UDim2.new(1, -40, 0, 8), UDim2.new(0, 32, 0, 32), C.red, 18)
addHover(closeBtn, C.red, Color3.fromRGB(255, 130, 140))

-- Tab buttons
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, -20, 0, 32)
tabFrame.Position = UDim2.new(0, 10, 0, 56)
tabFrame.BackgroundColor3 = C.input
tabFrame.BorderSizePixel = 0
tabFrame.Parent = panel
corner(tabFrame, 8)

local tabs = {}
local activeTab = "import"

local function mkTab(name, text, pos, size)
    local btn = mkButton(tabFrame, text, pos, size, C.input, 11, C.muted)
    btn.Name = name
    btn.AutoButtonColor = false
    tabs[name] = btn
    return btn
end

mkTab("import", "📥 IMPORT", UDim2.new(0, 2, 0, 2), UDim2.new(0.33, -3, 1, -4))
mkTab("scan", "🔍 SCAN", UDim2.new(0.33, 1, 0, 2), UDim2.new(0.33, -3, 1, -4))
mkTab("log", "📋 LOG", UDim2.new(0.66, 0, 0, 2), UDim2.new(0.34, -3, 1, -4))

-- ============================================================
-- PAGE: IMPORT (Manual Path)
-- ============================================================
local importPage = Instance.new("Frame")
importPage.Size = UDim2.new(1, -20, 0, 220)
importPage.Position = UDim2.new(0, 10, 0, 96)
importPage.BackgroundTransparency = 1
importPage.Parent = panel

mkLabel(importPage, "📁 Manual Path", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 16), Enum.Font.GothamBold, 11, C.muted)

local pathInput = Instance.new("TextBox")
pathInput.Size = UDim2.new(1, 0, 0, 36)
pathInput.Position = UDim2.new(0, 0, 0, 22)
pathInput.BackgroundColor3 = C.input
pathInput.BorderSizePixel = 0
pathInput.Font = Enum.Font.Code
pathInput.TextSize = 11
pathInput.TextColor3 = C.text
pathInput.PlaceholderColor3 = C.dim
pathInput.PlaceholderText = "/sdcard/Download/model.rbxm"
pathInput.Text = ""
pathInput.ClearTextOnFocus = false
pathInput.TextXAlignment = Enum.TextXAlignment.Left
pathInput.Parent = importPage
corner(pathInput, 8)
stroke(pathInput, C.border, 0.5, 1)
local ppad = Instance.new("UIPadding")
ppad.PaddingLeft = UDim.new(0, 10)
ppad.PaddingRight = UDim.new(0, 10)
ppad.Parent = pathInput

local importBtn = mkButton(importPage, "📥 IMPORT FILE", UDim2.new(0, 0, 0, 64), UDim2.new(1, 0, 0, 38), C.green, 13, Color3.fromRGB(20, 20, 20))
addHover(importBtn, C.green, Color3.fromRGB(120, 240, 150))

mkLabel(importPage, "📦 Import dari Roblox ID", UDim2.new(0, 0, 0, 112), UDim2.new(1, 0, 0, 16), Enum.Font.GothamBold, 11, C.muted)

local idInput = Instance.new("TextBox")
idInput.Size = UDim2.new(1, 0, 0, 36)
idInput.Position = UDim2.new(0, 0, 0, 134)
idInput.BackgroundColor3 = C.input
idInput.BorderSizePixel = 0
idInput.Font = Enum.Font.Code
idInput.TextSize = 11
idInput.TextColor3 = C.text
idInput.PlaceholderColor3 = C.dim
idInput.PlaceholderText = "Asset ID (contoh: 123456789)"
idInput.Text = ""
idInput.ClearTextOnFocus = false
idInput.TextXAlignment = Enum.TextXAlignment.Left
idInput.Parent = importPage
corner(idInput, 8)
stroke(idInput, C.border, 0.5, 1)
local ipad = Instance.new("UIPadding")
ipad.PaddingLeft = UDim.new(0, 10)
ipad.PaddingRight = UDim.new(0, 10)
ipad.Parent = idInput

local importIdBtn = mkButton(importPage, "📦 IMPORT DARI ID", UDim2.new(0, 0, 0, 176), UDim2.new(1, 0, 0, 38), C.blue, 13, Color3.fromRGB(20, 20, 20))
addHover(importIdBtn, C.blue, Color3.fromRGB(130, 200, 255))

-- ============================================================
-- PAGE: SCAN
-- ============================================================
local scanPage = Instance.new("Frame")
scanPage.Size = UDim2.new(1, -20, 0, 380)
scanPage.Position = UDim2.new(0, 10, 0, 96)
scanPage.BackgroundTransparency = 1
scanPage.Visible = false
scanPage.Parent = panel

mkLabel(scanPage, "📁 Folder Path", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 16), Enum.Font.GothamBold, 11, C.muted)

local scanPathInput = Instance.new("TextBox")
scanPathInput.Size = UDim2.new(0.7, -4, 0, 34)
scanPathInput.Position = UDim2.new(0, 0, 0, 20)
scanPathInput.BackgroundColor3 = C.input
scanPathInput.BorderSizePixel = 0
scanPathInput.Font = Enum.Font.Code
scanPathInput.TextSize = 10
scanPathInput.TextColor3 = C.text
scanPathInput.PlaceholderColor3 = C.dim
scanPathInput.PlaceholderText = "/sdcard/Download"
scanPathInput.Text = "/sdcard/Download"
scanPathInput.ClearTextOnFocus = false
scanPathInput.TextXAlignment = Enum.TextXAlignment.Left
scanPathInput.Parent = scanPage
corner(scanPathInput, 8)
local spad = Instance.new("UIPadding")
spad.PaddingLeft = UDim.new(0, 8)
spad.PaddingRight = UDim.new(0, 8)
spad.Parent = scanPathInput

local scanBtn = mkButton(scanPage, "🔍 SCAN", UDim2.new(0.7, 2, 0, 20), UDim2.new(0.3, -2, 0, 34), C.accent, 11)
addHover(scanBtn, C.accent, C.accent2)

local autoScanBtn = mkButton(scanPage, "🔎 AUTO-DETECT FOLDERS", UDim2.new(0, 0, 0, 60), UDim2.new(1, 0, 0, 32), C.accent2, 11)
addHover(autoScanBtn, C.accent2, C.accent)

-- Result list
local resultList = Instance.new("ScrollingFrame")
resultList.Size = UDim2.new(1, 0, 0, 270)
resultList.Position = UDim2.new(0, 0, 0, 102)
resultList.BackgroundColor3 = C.input
resultList.BorderSizePixel = 0
resultList.ScrollBarThickness = 4
resultList.ScrollBarImageColor3 = C.accent
resultList.CanvasSize = UDim2.new(0, 0, 0, 0)
resultList.Parent = scanPage
corner(resultList, 8)
stroke(resultList, C.border, 0.5, 1)
local rlpad = Instance.new("UIPadding")
rlpad.PaddingTop = UDim.new(0, 8)
rlpad.PaddingBottom = UDim.new(0, 8)
rlpad.PaddingLeft = UDim.new(0, 8)
rlpad.PaddingRight = UDim.new(0, 8)
rlpad.Parent = resultList
local rllayout = Instance.new("UIListLayout")
rllayout.Padding = UDim.new(0, 6)
rllayout.SortOrder = Enum.SortOrder.LayoutOrder
rllayout.Parent = resultList

local emptyLbl = mkLabel(resultList, "📭 Belum ada hasil.\nKlik SCAN atau AUTO-DETECT dulu.", UDim2.new(0, 0, 0, 80), UDim2.new(1, 0, 0, 50), Enum.Font.Gotham, 11, C.muted)
emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
emptyLbl.TextWrapped = true

-- ============================================================
-- PAGE: LOG
-- ============================================================
local logPage = Instance.new("Frame")
logPage.Size = UDim2.new(1, -20, 0, 380)
logPage.Position = UDim2.new(0, 10, 0, 96)
logPage.BackgroundTransparency = 1
logPage.Visible = false
logPage.Parent = panel

mkLabel(logPage, "📋 Import History & Log", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 16), Enum.Font.GothamBold, 11, C.muted)

local clearLogBtn = mkButton(logPage, "🗑️ CLEAR", UDim2.new(0.65, 0, 0, 0), UDim2.new(0.35, 0, 0, 20), C.red, 10)
addHover(clearLogBtn, C.red, Color3.fromRGB(255, 130, 140))

local logList = Instance.new("ScrollingFrame")
logList.Size = UDim2.new(1, 0, 0, 348)
logList.Position = UDim2.new(0, 0, 0, 28)
logList.BackgroundColor3 = C.input
logList.BorderSizePixel = 0
logList.ScrollBarThickness = 4
logList.ScrollBarImageColor3 = C.accent
logList.CanvasSize = UDim2.new(0, 0, 0, 0)
logList.Parent = logPage
corner(logList, 8)
stroke(logList, C.border, 0.5, 1)
local llpad = Instance.new("UIPadding")
llpad.PaddingTop = UDim.new(0, 8)
llpad.PaddingBottom = UDim.new(0, 8)
llpad.PaddingLeft = UDim.new(0, 8)
llpad.PaddingRight = UDim.new(0, 8)
llpad.Parent = logList
local lllayout = Instance.new("UIListLayout")
lllayout.Padding = UDim.new(0, 4)
lllayout.SortOrder = Enum.SortOrder.LayoutOrder
lllayout.Parent = logList

local logEmptyLbl = mkLabel(logList, "📭 Belum ada log.", UDim2.new(0, 0, 0, 80), UDim2.new(1, 0, 0, 20), Enum.Font.Gotham, 11, C.muted)
logEmptyLbl.TextXAlignment = Enum.TextXAlignment.Center

-- ============================================================
-- STATUS BAR
-- ============================================================
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -20, 0, 24)
statusBar.Position = UDim2.new(0, 10, 1, -34)
statusBar.BackgroundColor3 = C.panel
statusBar.BorderSizePixel = 0
statusBar.Parent = panel
corner(statusBar, 6)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(0, 10, 0.5, -4)
statusDot.BackgroundColor3 = C.green
statusDot.BorderSizePixel = 0
statusDot.Parent = statusBar
corner(statusDot, 4)

local statusLbl = mkLabel(statusBar, "Ready.", UDim2.new(0, 26, 0, 0), UDim2.new(1, -36, 1, 0), Enum.Font.Gotham, 10, C.muted)
statusLbl.TextTruncate = Enum.TextTruncate.AtEnd

local function setStatus(text, color)
    statusLbl.Text = tostring(text)
    statusLbl.TextColor3 = color or C.muted
    statusDot.BackgroundColor3 = color or C.green
    print("[SirLion] " .. tostring(text))
end

-- ============================================================
-- TAB SWITCHING
-- ============================================================
local pages = {
    import = importPage,
    scan = scanPage,
    log = logPage,
}

local function switchTab(name)
    activeTab = name
    for tabName, page in pairs(pages) do
        page.Visible = (tabName == name)
    end
    for tabName, btn in pairs(tabs) do
        if tabName == name then
            btn.BackgroundColor3 = C.accent
            btn.TextColor3 = C.text
        else
            btn.BackgroundColor3 = C.input
            btn.TextColor3 = C.muted
        end
    end
end

tabs.import.MouseButton1Click:Connect(function() switchTab("import") end)
tabs.scan.MouseButton1Click:Connect(function() switchTab("scan") end)
tabs.log.MouseButton1Click:Connect(function() switchTab("log") end)

switchTab("import")

-- ============================================================
-- LOG SYSTEM
-- ============================================================
local logRows = {}

local function addLog(message, color)
    color = color or C.muted
    
    table.insert(importHistory, {
        time = os.date("%H:%M:%S"),
        message = message,
        color = color,
    })
    
    if #importHistory > MAX_HISTORY then
        table.remove(importHistory, 1)
    end
    
    -- Add to log UI
    logEmptyLbl.Visible = false
    
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 32)
    row.BackgroundColor3 = C.card
    row.BorderSizePixel = 0
    row.LayoutOrder = #logRows + 1
    row.Parent = logList
    corner(row, 6)
    
    local timeLbl = mkLabel(row, os.date("%H:%M:%S"), UDim2.new(0, 8, 0, 0), UDim2.new(0, 55, 1, 0), Enum.Font.Code, 9, C.dim)
    
    local msgLbl = mkLabel(row, message, UDim2.new(0, 65, 0, 0), UDim2.new(1, -70, 1, 0), Enum.Font.Gotham, 10, color)
    msgLbl.TextTruncate = Enum.TextTruncate.AtEnd
    
    table.insert(logRows, row)
    
    lllayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        logList.CanvasSize = UDim2.new(0, 0, 0, lllayout.AbsoluteContentSize.Y + 16)
    end)
end

-- ============================================================
-- RESULT LIST RENDER
-- ============================================================
local resultRows = {}

local function clearResults()
    for _, obj in ipairs(resultRows) do
        obj:Destroy()
    end
    resultRows = {}
end

local function renderResults(files)
    clearResults()
    
    if #files == 0 then
        emptyLbl.Visible = true
        emptyLbl.Text = "📭 Tidak ada file .rbxm ditemukan."
        return
    end
    
    emptyLbl.Visible = false
    
    for i, path in ipairs(files) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 56)
        row.BackgroundColor3 = C.card2
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = resultList
        corner(row, 8)
        
        local icon = mkLabel(row, "📦", UDim2.new(0, 8, 0, 0), UDim2.new(0, 32, 1, 0), Enum.Font.GothamBold, 20, C.accent)
        icon.TextXAlignment = Enum.TextXAlignment.Center
        
        local name = tostring(path):match("([^/]+)$") or path
        local nameLbl = mkLabel(row, name, UDim2.new(0, 44, 0, 8), UDim2.new(1, -140, 0, 16), Enum.Font.GothamBold, 10, C.text)
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        
        local pathLbl = mkLabel(row, path, UDim2.new(0, 44, 0, 26), UDim2.new(1, -140, 0, 12), Enum.Font.Code, 8, C.muted)
        pathLbl.TextTruncate = Enum.TextTruncate.AtEnd
        
        -- Import button
        local btn = mkButton(row, "📥 IMPORT", UDim2.new(1, -92, 0.5, -15), UDim2.new(0, 84, 0, 30), C.green, 10, Color3.fromRGB(20, 20, 20))
        addHover(btn, C.green, Color3.fromRGB(120, 240, 150))
        
        btn.MouseButton1Click:Connect(function()
            if btn.Active == false then return end
            btn.Active = false
            btn.Text = "⏳..."
            btn.BackgroundColor3 = C.yellow
            setStatus("Importing: " .. name, C.yellow)
            addLog("⏳ Import: " .. name, C.yellow)
            
            task.spawn(function()
                local result, err, method = importRbxm(path)
                if result then
                    btn.Text = "✅ OK"
                    btn.BackgroundColor3 = C.green
                    setStatus("✅ Berhasil: " .. result.Name, C.green)
                    addLog("✅ " .. result.Name .. " [" .. (method or "?") .. "]", C.green)
                    task.wait(2)
                    btn.Text = "📥 IMPORT"
                    btn.BackgroundColor3 = C.green
                    btn.Active = true
                else
                    btn.Text = "❌ FAIL"
                    btn.BackgroundColor3 = C.red
                    setStatus("❌ Gagal: " .. tostring(err), C.red)
                    addLog("❌ Gagal: " .. tostring(err):sub(1, 60), C.red)
                    task.wait(2)
                    btn.Text = "📥 IMPORT"
                    btn.BackgroundColor3 = C.green
                    btn.Active = true
                end
            end)
        end)
        
        table.insert(resultRows, row)
    end
    
    rllayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        resultList.CanvasSize = UDim2.new(0, 0, 0, rllayout.AbsoluteContentSize.Y + 16)
    end)
end

-- ============================================================
-- SCAN HANDLER
-- ============================================================
scanBtn.MouseButton1Click:Connect(function()
    if scanBtn.Active == false then return end
    
    local folder = scanPathInput.Text
    if folder == "" then
        setStatus("❌ Path kosong!", C.red)
        return
    end
    
    if not SUPPORT.listfiles then
        setStatus("❌ listfiles gak ada", C.red)
        addLog("❌ listfiles gak support!", C.red)
        return
    end
    
    scanBtn.Active = false
    scanBtn.Text = "⏳ SCANNING..."
    setStatus("⏳ Scan: " .. folder, C.yellow)
    addLog("🔍 Scan: " .. folder, C.blue)
    
    task.spawn(function()
        local files, err = scanFolder(folder, true)
        
        scanBtn.Text = "🔍 SCAN"
        scanBtn.Active = true
        
        if err then
            setStatus("❌ " .. err, C.red)
            addLog("❌ " .. err, C.red)
            renderResults({})
        elseif #files == 0 then
            setStatus("⚠️ Tidak ada .rbxm di " .. folder, C.yellow)
            addLog("⚠️ 0 file di " .. folder, C.yellow)
            renderResults({})
        else
            setStatus("✅ " .. #files .. " file ditemukan", C.green)
            addLog("✅ " .. #files .. " file ditemukan", C.green)
            renderResults(files)
        end
    end)
end)

-- ============================================================
-- AUTO DETECT HANDLER
-- ============================================================
autoScanBtn.MouseButton1Click:Connect(function()
    if autoScanBtn.Active == false then return end
    
    autoScanBtn.Active = false
    autoScanBtn.Text = "⏳ DETECTING..."
    setStatus("⏳ Auto-detect folders...", C.yellow)
    addLog("🔎 Auto-detect folders...", C.blue)
    
    task.spawn(function()
        local folders = autoDetectFolders()
        
        autoScanBtn.Text = "🔎 AUTO-DETECT FOLDERS"
        autoScanBtn.Active = true
        
        if #folders == 0 then
            setStatus("❌ Gak ada folder yang bisa diakses", C.red)
            addLog("❌ Gak ada folder accessible", C.red)
            renderResults({})
            return
        end
        
        -- Gabungin semua file dari folder yang ada rbxm
        local allFiles = {}
        for _, fd in ipairs(folders) do
            addLog("📁 " .. fd.path .. " (" .. fd.total .. " item, " .. fd.rbxm .. " rbxm)", C.muted)
            
            if fd.rbxm > 0 then
                local files = scanFolder(fd.path, true)
                for _, f in ipairs(files) do
                    table.insert(allFiles, f)
                end
            end
        end
        
        setStatus("✅ " .. #allFiles .. " file dari " .. #folders .. " folder", C.green)
        addLog("✅ Total: " .. #allFiles .. " rbxm", C.green)
        renderResults(allFiles)
    end)
end)

-- ============================================================
-- MANUAL IMPORT HANDLER
-- ============================================================
importBtn.MouseButton1Click:Connect(function()
    if importBtn.Active == false then return end
    
    local path = pathInput.Text
    if path == "" then
        setStatus("❌ Path kosong!", C.red)
        return
    end
    
    importBtn.Active = false
    importBtn.Text = "⏳ IMPORTING..."
    setStatus("⏳ Import: " .. path, C.yellow)
    addLog("⏳ Manual import: " .. path, C.yellow)
    
    task.spawn(function()
        local result, err, method = importRbxm(path)
        
        if result then
            importBtn.Text = "✅ BERHASIL!"
            importBtn.BackgroundColor3 = C.green
            setStatus("✅ " .. result.Name .. " masuk ke Workspace!", C.green)
            addLog("✅ " .. result.Name .. " [" .. (method or "?") .. "]", C.green)
            task.wait(2)
            importBtn.Text = "📥 IMPORT FILE"
            importBtn.Active = true
        else
            importBtn.Text = "❌ GAGAL"
            importBtn.BackgroundColor3 = C.red
            setStatus("❌ " .. tostring(err), C.red)
            addLog("❌ " .. tostring(err):sub(1, 80), C.red)
            task.wait(2)
            importBtn.Text = "📥 IMPORT FILE"
            importBtn.BackgroundColor3 = C.green
            importBtn.Active = true
        end
    end)
end)

-- ============================================================
-- IMPORT FROM ID HANDLER
-- ============================================================
importIdBtn.MouseButton1Click:Connect(function()
    if importIdBtn.Active == false then return end
    
    local id = idInput.Text
    if id == "" then
        setStatus("❌ ID kosong!", C.red)
        return
    end
    
    local numId = tonumber(id)
    if not numId then
        setStatus("❌ ID harus angka!", C.red)
        return
    end
    
    importIdBtn.Active = false
    importIdBtn.Text = "⏳ LOADING..."
    setStatus("⏳ Load asset ID: " .. numId, C.yellow)
    addLog("📦 Load ID: " .. numId, C.blue)
    
    task.spawn(function()
        if not SUPPORT.loadAsset then
            importIdBtn.Text = "❌ GAGAL"
            importIdBtn.BackgroundColor3 = C.red
            setStatus("❌ LoadAsset gak support", C.red)
            addLog("❌ LoadAsset gak support", C.red)
            task.wait(2)
            importIdBtn.Text = "📦 IMPORT DARI ID"
            importIdBtn.BackgroundColor3 = C.blue
            importIdBtn.Active = true
            return
        end
        
        local ok, result = pcall(function()
            return InsertService:LoadAsset(numId)
        end)
        
        if ok and result then
            local children = result:GetChildren()
            if #children > 0 then
                local first = children[1]
                first.Parent = Workspace
                pcall(function() result:Destroy() end)
                setStatus("✅ " .. first.Name .. " masuk ke Workspace!", C.green)
                addLog("✅ " .. first.Name .. " (dari ID)", C.green)
            else
                result.Parent = Workspace
                setStatus("✅ Asset masuk ke Workspace!", C.green)
                addLog("✅ Asset loaded", C.green)
            end
            importIdBtn.Text = "✅ BERHASIL!"
            importIdBtn.BackgroundColor3 = C.green
        else
            local err = cleanErr(result)
            setStatus("❌ " .. err, C.red)
            addLog("❌ " .. err, C.red)
            importIdBtn.Text = "❌ GAGAL"
            importIdBtn.BackgroundColor3 = C.red
        end
        
        task.wait(2)
        importIdBtn.Text = "📦 IMPORT DARI ID"
        importIdBtn.BackgroundColor3 = C.blue
        importIdBtn.Active = true
    end)
end)

-- ============================================================
-- CLEAR LOG
-- ============================================================
clearLogBtn.MouseButton1Click:Connect(function()
    for _, row in ipairs(logRows) do
        row:Destroy()
    end
    logRows = {}
    importHistory = {}
    logEmptyLbl.Visible = true
    setStatus("🗑️ Log dibersihkan", C.muted)
end)

-- ============================================================
-- CLOSE & DRAG
-- ============================================================
closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
    toggleBtn.Visible = true
end)

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
-- TOGGLE BUTTON
-- ============================================================
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 54, 0, 54)
toggleBtn.Position = UDim2.new(0, 15, 0.5, -27)
toggleBtn.BackgroundColor3 = C.accent
toggleBtn.BorderSizePixel = 0
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 24
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Text = "📦"
toggleBtn.Draggable = true
toggleBtn.Parent = gui
corner(toggleBtn, 14)
stroke(toggleBtn, C.accent2, 0.3, 2)

toggleBtn.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
    toggleBtn.Visible = not panel.Visible
end)

-- ============================================================
-- INIT
-- ============================================================
addLog("🚀 SirLion Importer v4.0 loaded!", C.green)

-- Cek support dan kasih warning
if not SUPPORT.listfiles then
    addLog("⚠️ listfiles gak support — pake manual path", C.yellow)
    setStatus("⚠️ listfiles gak ada, pake Manual Path", C.yellow)
else
    addLog("✅ listfiles support", C.green)
end

if not SUPPORT.loadLocalAsset then
    addLog("⚠️ LoadLocalAsset gak support", C.yellow)
end

if not SUPPORT.loadAsset then
    addLog("⚠️ LoadAsset gak support", C.yellow)
end

print("╔══════════════════════════════════════════════════════════╗")
print("║  ✅ SIRLION IMPORTER v4.0 LOADED!                       ║")
print("║  📦 Klik tombol 📦 di kiri layar buat buka panel       ║")
print("╚══════════════════════════════════════════════════════════╝")
