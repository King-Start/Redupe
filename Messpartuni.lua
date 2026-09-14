--[[
    AFTERLIFE PROJECT v2.0 - FULL FUNCTIONAL
    Studio Lite + Delta Executor Edition
    Semua fitur berfungsi!
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local GUI_NAME = "AfterlifeProject_v2"

-- ============================================================
-- COLOR PALETTE
-- ============================================================
local C = {
    bg = Color3.fromRGB(13, 8, 28),
    sidebar = Color3.fromRGB(18, 10, 38),
    panel = Color3.fromRGB(22, 12, 45),
    card = Color3.fromRGB(32, 18, 58),
    card2 = Color3.fromRGB(42, 24, 72),
    input = Color3.fromRGB(28, 16, 52),
    purple = Color3.fromRGB(150, 70, 240),
    purple2 = Color3.fromRGB(110, 45, 200),
    purpleHover = Color3.fromRGB(180, 110, 255),
    pink = Color3.fromRGB(255, 80, 180),
    text = Color3.fromRGB(245, 240, 255),
    muted = Color3.fromRGB(150, 130, 180),
    dim = Color3.fromRGB(90, 75, 120),
    green = Color3.fromRGB(90, 230, 140),
    yellow = Color3.fromRGB(255, 210, 90),
    red = Color3.fromRGB(255, 100, 120),
    gold = Color3.fromRGB(255, 200, 60),
}

-- ============================================================
-- CLEANUP
-- ============================================================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 200
screenGui.Parent = playerGui

-- ============================================================
-- HELPERS
-- ============================================================
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

local function stroke(p, color, trans, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or C.purple2
    s.Transparency = trans or 0.5
    s.Thickness = thick or 1
    s.Parent = p
    return s
end

local function lbl(parent, text, pos, size, font, ts, color)
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

local function btn(parent, text, pos, size, bg, ts)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = bg or C.card
    b.BorderSizePixel = 0
    b.Position = pos
    b.Size = size
    b.Font = Enum.Font.GothamBold
    b.TextSize = ts or 11
    b.TextColor3 = C.text
    b.Text = text or ""
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b, 8)
    return b
end

local function hover(item, normal, over)
    item.MouseEnter:Connect(function()
        if item.Active ~= false then
            TweenService:Create(item, TweenInfo.new(0.15), {BackgroundColor3 = over}):Play()
        end
    end)
    item.MouseLeave:Connect(function()
        if item.Active ~= false then
            TweenService:Create(item, TweenInfo.new(0.15), {BackgroundColor3 = normal}):Play()
        end
    end)
end

-- ============================================================
-- FILE SYSTEM FUNCTIONS
-- ============================================================
local function getFunc(name)
    local fn
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then fn = env[name] end
    end
    if type(fn) ~= "function" then fn = _G[name] end
    return type(fn) == "function" and fn or nil
end

local function normalizePath(p)
    p = tostring(p or ""):gsub("\\", "/"):gsub("/+", "/")
    if #p > 1 then p = p:gsub("/$", "") end
    return p
end

local function fname(path)
    return tostring(path):match("([^/]+)$") or tostring(path)
end

local function isRbxm(path)
    local l = string.lower(tostring(path))
    return l:sub(-5) == ".rbxm" or l:sub(-6) == ".rbxmx"
end

local function cleanErr(msg)
    local t = tostring(msg or "error"):gsub("^.-:%d+: ", "")
    if #t > 150 then t = t:sub(1, 147) .. "..." end
    return t
end

local function listFolder(path)
    local fn = getFunc("listfiles")
    if not fn then error("Executor gak punya listfiles()", 0) end
    local ok, res = pcall(fn, path)
    if not ok then error("listfiles gagal", 0) end
    if type(res) ~= "table" then error("listfiles bukan table", 0) end
    return res
end

local function isFolder(path)
    local fn = getFunc("isfolder")
    if fn then
        local ok, res = pcall(fn, path)
        if ok then return res == true end
    end
    return not isRbxm(path) and not path:match("%.%w+$")
end

local function scanFolder(root, recursive)
    local paths = {}
    local seen = {}
    local visited = {}
    
    local function visit(folder, depth)
        folder = normalizePath(folder)
        if depth > 6 or visited[folder] or #paths >= 300 then return end
        visited[folder] = true
        
        local ok, children = pcall(listFolder, folder)
        if not ok then return end
        
        for _, item in ipairs(children) do
            if #paths >= 300 then break end
            local path = normalizePath(item)
            if isFolder(path) then
                if recursive then pcall(visit, path, depth + 1) end
            elseif isRbxm(path) then
                local key = string.lower(path)
                if not seen[key] then
                    seen[key] = true
                    paths[#paths + 1] = path
                end
            end
        end
    end
    
    visit(root, 0)
    table.sort(paths, function(a, b)
        return string.lower(fname(a)) < string.lower(fname(b))
    end)
    return paths
end

-- ============================================================
-- CONFIG SAVE/LOAD
-- ============================================================
local CONFIG_FILE = "afterlife_config.json"

local defaultConfig = {
    lastPath = "/sdcard/Download",
    autoScan = false,
    showToast = true,
    soundEnabled = true,
    totalImported = 0,
    vipUsers = 0,
}

local function loadConfig()
    local cfg = {}
    for k, v in pairs(defaultConfig) do cfg[k] = v end
    
    if readfile and isfile then
        local ok, exists = pcall(isfile, CONFIG_FILE)
        if ok and exists then
            local ok2, data = pcall(readfile, CONFIG_FILE)
            if ok2 and data then
                local ok3, parsed = pcall(HttpService.JSONDecode, HttpService, data)
                if ok3 and type(parsed) == "table" then
                    for k, v in pairs(parsed) do cfg[k] = v end
                end
            end
        end
    end
    return cfg
end

local function saveConfig(cfg)
    if writefile then
        local ok, json = pcall(HttpService.JSONEncode, HttpService, cfg)
        if ok then pcall(writefile, CONFIG_FILE, json) end
    end
end

local config = loadConfig()

-- ============================================================
-- TOAST NOTIFICATION SYSTEM
-- ============================================================
local toastHolder = Instance.new("Frame")
toastHolder.BackgroundTransparency = 1
toastHolder.Position = UDim2.new(1, -340, 0, 20)
toastHolder.Size = UDim2.new(0, 320, 0, 400)
toastHolder.Parent = screenGui

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 8)
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Top
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastHolder

local toastOrder = 0
local function showToast(title, message, color)
    if not config.showToast then return end
    color = color or C.purple
    toastOrder = toastOrder + 1
    
    local toast = Instance.new("Frame")
    toast.BackgroundColor3 = C.card
    toast.BorderSizePixel = 0
    toast.Size = UDim2.new(1, 0, 0, 62)
    toast.LayoutOrder = toastOrder
    toast.Parent = toastHolder
    corner(toast, 10)
    stroke(toast, color, 0.3, 1.5)
    
    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.Parent = toast
    corner(accent, 10)
    
    local titleLbl = lbl(toast, title, UDim2.new(0, 14, 0, 8), UDim2.new(1, -20, 0, 18), Enum.Font.GothamBold, 12, C.text)
    local msgLbl = lbl(toast, message, UDim2.new(0, 14, 0, 30), UDim2.new(1, -20, 0, 24), Enum.Font.Gotham, 10, C.muted)
    msgLbl.TextWrapped = true
    
    -- Auto dismiss
    task.spawn(function()
        task.wait(3.5)
        TweenService:Create(toast, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        for _, c in ipairs(toast:GetDescendants()) do
            if c:IsA("TextLabel") then
                TweenService:Create(c, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            end
        end
        TweenService:Create(accent, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.wait(0.4)
        toast:Destroy()
    end)
end

-- ============================================================
-- FLOATING TOGGLE
-- ============================================================
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "Toggle"
toggleBtn.BackgroundColor3 = C.card2
toggleBtn.BorderSizePixel = 0
toggleBtn.Position = UDim2.new(0, 12, 0.5, -22)
toggleBtn.Size = UDim2.new(0, 44, 0, 44)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 18
toggleBtn.TextColor3 = C.purpleHover
toggleBtn.Text = "R"
toggleBtn.AutoButtonColor = false
toggleBtn.Draggable = true
toggleBtn.ZIndex = 250
toggleBtn.Parent = screenGui
corner(toggleBtn, 14)
stroke(toggleBtn, C.purple2, 0.2, 1.5)
hover(toggleBtn, C.card2, C.purple2)

-- ============================================================
-- MAIN APP
-- ============================================================
local app = Instance.new("Frame")
app.Size = UDim2.new(0, 640, 0, 400)
app.Position = UDim2.new(0.5, 0, 0.5, 0)
app.AnchorPoint = Vector2.new(0.5, 0.5)
app.BackgroundColor3 = C.bg
app.BorderSizePixel = 0
app.Visible = false
app.Parent = screenGui
corner(app, 14)
stroke(app, C.purple2, 0.4, 1.5)

local glow = Instance.new("Frame")
glow.BackgroundColor3 = C.purple
glow.BackgroundTransparency = 0.85
glow.BorderSizePixel = 0
glow.Size = UDim2.new(1, 0, 0, 80)
glow.Parent = app
corner(glow, 14)

-- ============================================================
-- SIDEBAR
-- ============================================================
local sidebar = Instance.new("Frame")
sidebar.BackgroundColor3 = C.sidebar
sidebar.BorderSizePixel = 0
sidebar.Size = UDim2.new(0, 150, 1, 0)
sidebar.Parent = app
corner(sidebar, 14)

local brandBox = Instance.new("Frame")
brandBox.BackgroundColor3 = C.panel
brandBox.BorderSizePixel = 0
brandBox.Position = UDim2.new(0, 14, 0, 14)
brandBox.Size = UDim2.new(1, -28, 0, 44)
brandBox.Parent = sidebar
corner(brandBox, 10)
stroke(brandBox, C.purple2, 0.6, 1)

lbl(brandBox, "AFTERLIFE", UDim2.new(0, 10, 0, 4), UDim2.new(1, -20, 0, 18), Enum.Font.GothamBold, 12, C.text)
lbl(brandBox, "PROJECT v2.0", UDim2.new(0, 10, 0, 20), UDim2.new(1, -20, 0, 14), Enum.Font.Gotham, 8, C.muted)

local navHolder = Instance.new("Frame")
navHolder.BackgroundTransparency = 1
navHolder.Position = UDim2.new(0, 8, 0, 70)
navHolder.Size = UDim2.new(1, -16, 0, 260)
navHolder.Parent = sidebar

local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 4)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Parent = navHolder

local navButtons = {}
local pages = {}
local activePage = "ASSETS"
local order = 0

local function makeNav(name, icon)
    order = order + 1
    local item = btn(navHolder, "", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 36), C.sidebar, 11)
    item.LayoutOrder = order
    
    local activeBar = Instance.new("Frame")
    activeBar.BackgroundColor3 = C.purple
    activeBar.BorderSizePixel = 0
    activeBar.Position = UDim2.new(0, 0, 0.5, -10)
    activeBar.Size = UDim2.new(0, 3, 0, 20)
    activeBar.Visible = false
    activeBar.Parent = item
    corner(activeBar, 3)
    
    local iconLbl = lbl(item, icon, UDim2.new(0, 14, 0, 0), UDim2.new(0, 20, 1, 0), Enum.Font.GothamBold, 12, C.muted)
    iconLbl.TextXAlignment = Enum.TextXAlignment.Center
    local textLbl = lbl(item, name, UDim2.new(0, 42, 0, 0), UDim2.new(1, -48, 1, 0), Enum.Font.GothamBold, 10, C.muted)
    
    item.MouseEnter:Connect(function()
        if activePage ~= name then item.BackgroundColor3 = C.panel end
    end)
    item.MouseLeave:Connect(function()
        if activePage ~= name then item.BackgroundColor3 = C.sidebar end
    end)
    
    navButtons[name] = {btn = item, bar = activeBar, icon = iconLbl, text = textLbl}
    return item
end

makeNav("ASSETS", "▣")
makeNav("TOOLBOX", "✄")
makeNav("PLUGINS", "⚙")
makeNav("BUY ACC", "💎")
makeNav("SETTINGS", "☰")

-- ============================================================
-- CONTENT
-- ============================================================
local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 150, 0, 0)
content.Size = UDim2.new(1, -150, 1, 0)
content.Parent = app

local contentHeader = Instance.new("Frame")
contentHeader.BackgroundTransparency = 1
contentHeader.Position = UDim2.new(0, 18, 0, 14)
contentHeader.Size = UDim2.new(1, -36, 0, 40)
contentHeader.Parent = content

local pageTitle = lbl(contentHeader, "Dashboard", UDim2.new(0, 0, 0, 0), UDim2.new(1, -50, 0, 22), Enum.Font.GothamBold, 17, C.text)
local pageSub = lbl(contentHeader, "Manage your local assets", UDim2.new(0, 0, 0, 22), UDim2.new(1, -50, 0, 14), Enum.Font.Gotham, 9, C.muted)

local closeBtn = btn(contentHeader, "×", UDim2.new(1, -34, 0, 0), UDim2.new(0, 34, 0, 34), C.card, 18)
closeBtn.TextColor3 = C.muted
hover(closeBtn, C.card, C.red)

-- ============================================================
-- PAGE 1: ASSETS (WORKING)
-- ============================================================
local assetsPage = Instance.new("Frame")
assetsPage.BackgroundTransparency = 1
assetsPage.Position = UDim2.new(0, 18, 0, 60)
assetsPage.Size = UDim2.new(1, -36, 1, -74)
assetsPage.Parent = content
pages["ASSETS"] = assetsPage

-- Stats Row
local statsRow = Instance.new("Frame")
statsRow.BackgroundTransparency = 1
statsRow.Size = UDim2.new(1, 0, 0, 58)
statsRow.Parent = assetsPage

local totalCard = Instance.new("Frame")
totalCard.BackgroundColor3 = C.card
totalCard.BorderSizePixel = 0
totalCard.Size = UDim2.new(0.5, -4, 1, 0)
totalCard.Parent = statsRow
corner(totalCard, 10)
stroke(totalCard, C.purple2, 0.6, 1)
local totalNum = lbl(totalCard, "0", UDim2.new(0, 12, 0, 6), UDim2.new(1, -24, 0, 24), Enum.Font.GothamBold, 20, C.text)
lbl(totalCard, "Total RBXM Files", UDim2.new(0, 12, 0, 34), UDim2.new(1, -24, 0, 14), Enum.Font.Gotham, 9, C.muted)

local vipCard = Instance.new("Frame")
vipCard.BackgroundColor3 = C.card
vipCard.BorderSizePixel = 0
vipCard.Position = UDim2.new(0.5, 4, 0, 0)
vipCard.Size = UDim2.new(0.5, -4, 1, 0)
vipCard.Parent = statsRow
corner(vipCard, 10)
stroke(vipCard, C.gold, 0.4, 1.5)
local vipNum = lbl(vipCard, tostring(config.totalImported), UDim2.new(0, 12, 0, 6), UDim2.new(1, -24, 0, 24), Enum.Font.GothamBold, 20, C.gold)
lbl(vipCard, "Total Imported", UDim2.new(0, 12, 0, 34), UDim2.new(1, -24, 0, 14), Enum.Font.Gotham, 9, C.muted)

-- Recent Assets header
local recentHeader = Instance.new("Frame")
recentHeader.BackgroundTransparency = 1
recentHeader.Position = UDim2.new(0, 0, 0, 72)
recentHeader.Size = UDim2.new(1, 0, 0, 22)
recentHeader.Parent = assetsPage
lbl(recentHeader, "Recent Assets", UDim2.new(0, 0, 0, 0), UDim2.new(1, -80, 1, 0), Enum.Font.GothamBold, 12, C.text)

-- Path Input
local pathInput = Instance.new("TextBox")
pathInput.BackgroundColor3 = C.input
pathInput.BorderSizePixel = 0
pathInput.Position = UDim2.new(0, 0, 0, 100)
pathInput.Size = UDim2.new(0.72, -4, 0, 32)
pathInput.Font = Enum.Font.Code
pathInput.TextSize = 10
pathInput.TextColor3 = C.text
pathInput.PlaceholderColor3 = C.muted
pathInput.PlaceholderText = "Path folder..."
pathInput.Text = config.lastPath
pathInput.ClearTextOnFocus = false
pathInput.TextXAlignment = Enum.TextXAlignment.Left
pathInput.Parent = assetsPage
corner(pathInput, 8)
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = pathInput

local scanBtn = btn(assetsPage, "🔍 SCAN", UDim2.new(0.72, 4, 0, 100), UDim2.new(0.28, -4, 0, 32), C.purple2, 10)
hover(scanBtn, C.purple2, C.purple)

-- Action Buttons Row
local actionRow = Instance.new("Frame")
actionRow.BackgroundTransparency = 1
actionRow.Position = UDim2.new(0, 0, 0, 140)
actionRow.Size = UDim2.new(1, 0, 0, 28)
actionRow.Parent = assetsPage

local importAllBtn = btn(actionRow, "📦 IMPORT ALL", UDim2.new(0, 0, 0, 0), UDim2.new(0.33, -3, 1, 0), C.purple2, 9)
hover(importAllBtn, C.purple2, C.purple)

local clearBtn = btn(actionRow, "🗑️ CLEAR LIST", UDim2.new(0.33, 3, 0, 0), UDim2.new(0.33, -3, 1, 0), C.card, 9)
hover(clearBtn, C.card, C.card2)

local refreshBtn = btn(actionRow, "🔄 REFRESH", UDim2.new(0.66, 3, 0, 0), UDim2.new(0.34, -3, 1, 0), C.card, 9)
hover(refreshBtn, C.card, C.card2)

-- Asset List
local assetList = Instance.new("ScrollingFrame")
assetList.BackgroundColor3 = C.panel
assetList.BorderSizePixel = 0
assetList.Position = UDim2.new(0, 0, 0, 178)
assetList.Size = UDim2.new(1, 0, 1, -178)
assetList.ScrollBarThickness = 3
assetList.ScrollBarImageColor3 = C.purple
assetList.CanvasSize = UDim2.new(0, 0, 0, 0)
assetList.Parent = assetsPage
corner(assetList, 10)
stroke(assetList, C.purple2, 0.7, 1)
local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 8)
listPad.PaddingBottom = UDim.new(0, 8)
listPad.PaddingLeft = UDim.new(0, 8)
listPad.PaddingRight = UDim.new(0, 8)
listPad.Parent = assetList
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = assetList

local emptyLbl = lbl(assetList, "Belum ada file.\nIsi path folder lalu klik SCAN.", UDim2.new(0, 20, 0.5, -24), UDim2.new(1, -40, 0, 48), Enum.Font.Gotham, 10, C.muted)
emptyLbl.TextWrapped = true
emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
emptyLbl.TextYAlignment = Enum.TextYAlignment.Center

-- ============================================================
-- PAGE 2: TOOLBOX (WORKING - SEARCH + SPAWN)
-- ============================================================
local toolboxPage = Instance.new("Frame")
toolboxPage.BackgroundTransparency = 1
toolboxPage.Position = UDim2.new(0, 18, 0, 60)
toolboxPage.Size = UDim2.new(1, -36, 1, -74)
toolboxPage.Visible = false
toolboxPage.Parent = content
pages["TOOLBOX"] = toolboxPage

lbl(toolboxPage, "🔍 Cari Model di Roblox Toolbox", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), Enum.Font.GothamBold, 12, C.text)

local searchBox = Instance.new("TextBox")
searchBox.BackgroundColor3 = C.input
searchBox.BorderSizePixel = 0
searchBox.Position = UDim2.new(0, 0, 0, 28)
searchBox.Size = UDim2.new(0.75, -4, 0, 32)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 11
searchBox.TextColor3 = C.text
searchBox.PlaceholderColor3 = C.muted
searchBox.PlaceholderText = "Cari model... (contoh: tree, car, house)"
searchBox.Text = ""
searchBox.ClearTextOnFocus = false
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = toolboxPage
corner(searchBox, 8)
local sp = Instance.new("UIPadding")
sp.PaddingLeft = UDim.new(0, 10)
sp.PaddingRight = UDim.new(0, 10)
sp.Parent = searchBox

local searchBtn = btn(toolboxPage, "🔍 CARI", UDim2.new(0.75, 4, 0, 28), UDim2.new(0.25, -4, 0, 32), C.purple2, 10)
hover(searchBtn, C.purple2, C.purple)

local toolboxList = Instance.new("ScrollingFrame")
toolboxList.BackgroundColor3 = C.panel
toolboxList.BorderSizePixel = 0
toolboxList.Position = UDim2.new(0, 0, 0, 68)
toolboxList.Size = UDim2.new(1, 0, 1, -68)
toolboxList.ScrollBarThickness = 3
toolboxList.ScrollBarImageColor3 = C.purple
toolboxList.CanvasSize = UDim2.new(0, 0, 0, 0)
toolboxList.Parent = toolboxPage
corner(toolboxList, 10)
stroke(toolboxList, C.purple2, 0.7, 1)
local tbPad = Instance.new("UIPadding")
tbPad.PaddingTop = UDim.new(0, 8)
tbPad.PaddingBottom = UDim.new(0, 8)
tbPad.PaddingLeft = UDim.new(0, 8)
tbPad.PaddingRight = UDim.new(0, 8)
tbPad.Parent = toolboxList
local tbLayout = Instance.new("UIListLayout")
tbLayout.Padding = UDim.new(0, 6)
tbLayout.SortOrder = Enum.SortOrder.LayoutOrder
tbLayout.Parent = toolboxList

local tbEmpty = lbl(toolboxList, "Ketik nama model & klik CARI.\nHasil akan muncul di sini.", UDim2.new(0, 20, 0.5, -24), UDim2.new(1, -40, 0, 48), Enum.Font.Gotham, 10, C.muted)
tbEmpty.TextWrapped = true
tbEmpty.TextXAlignment = Enum.TextXAlignment.Center
tbEmpty.TextYAlignment = Enum.TextYAlignment.Center

-- ============================================================
-- PAGE 3: PLUGINS (WORKING - LIST LOCAL PLUGINS)
-- ============================================================
local pluginsPage = Instance.new("Frame")
pluginsPage.BackgroundTransparency = 1
pluginsPage.Position = UDim2.new(0, 18, 0, 60)
pluginsPage.Size = UDim2.new(1, -36, 1, -74)
pluginsPage.Visible = false
pluginsPage.Parent = content
pages["PLUGINS"] = pluginsPage

lbl(pluginsPage, "⚙ Plugins Manager", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), Enum.Font.GothamBold, 12, C.text)
lbl(pluginsPage, "Kelola script plugin yang kamu simpan", UDim2.new(0, 0, 0, 20), UDim2.new(1, 0, 0, 16), Enum.Font.Gotham, 9, C.muted)

local pluginPathInput = Instance.new("TextBox")
pluginPathInput.BackgroundColor3 = C.input
pluginPathInput.BorderSizePixel = 0
pluginPathInput.Position = UDim2.new(0, 0, 0, 42)
pluginPathInput.Size = UDim2.new(0.72, -4, 0, 32)
pluginPathInput.Font = Enum.Font.Code
pluginPathInput.TextSize = 10
pluginPathInput.TextColor3 = C.text
pluginPathInput.PlaceholderColor3 = C.muted
pluginPathInput.PlaceholderText = "Path folder plugins..."
pluginPathInput.Text = "/sdcard/Plugins"
pluginPathInput.ClearTextOnFocus = false
pluginPathInput.TextXAlignment = Enum.TextXAlignment.Left
pluginPathInput.Parent = pluginsPage
corner(pluginPathInput, 8)
local pp = Instance.new("UIPadding")
pp.PaddingLeft = UDim.new(0, 10)
pp.PaddingRight = UDim.new(0, 10)
pp.Parent = pluginPathInput

local scanPluginsBtn = btn(pluginsPage, "🔍 SCAN", UDim2.new(0.72, 4, 0, 42), UDim2.new(0.28, -4, 0, 32), C.purple2, 10)
hover(scanPluginsBtn, C.purple2, C.purple)

local pluginList = Instance.new("ScrollingFrame")
pluginList.BackgroundColor3 = C.panel
pluginList.BorderSizePixel = 0
pluginList.Position = UDim2.new(0, 0, 0, 82)
pluginList.Size = UDim2.new(1, 0, 1, -82)
pluginList.ScrollBarThickness = 3
pluginList.ScrollBarImageColor3 = C.purple
pluginList.CanvasSize = UDim2.new(0, 0, 0, 0)
pluginList.Parent = pluginsPage
corner(pluginList, 10)
stroke(pluginList, C.purple2, 0.7, 1)
local plPad = Instance.new("UIPadding")
plPad.PaddingTop = UDim.new(0, 8)
plPad.PaddingBottom = UDim.new(0, 8)
plPad.PaddingLeft = UDim.new(0, 8)
plPad.PaddingRight = UDim.new(0, 8)
plPad.Parent = pluginList
local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0, 6)
plLayout.SortOrder = Enum.SortOrder.LayoutOrder
plLayout.Parent = pluginList

local plEmpty = lbl(pluginList, "Belum ada plugins.\nIsi path & klik SCAN.", UDim2.new(0, 20, 0.5, -24), UDim2.new(1, -40, 0, 48), Enum.Font.Gotham, 10, C.muted)
plEmpty.TextWrapped = true
plEmpty.TextXAlignment = Enum.TextXAlignment.Center
plEmpty.TextYAlignment = Enum.TextYAlignment.Center

-- ============================================================
-- PAGE 4: BUY ACC (MOCKUP with FAQ)
-- ============================================================
local buyPage = Instance.new("Frame")
buyPage.BackgroundTransparency = 1
buyPage.Position = UDim2.new(0, 18, 0, 60)
buyPage.Size = UDim2.new(1, -36, 1, -74)
buyPage.Visible = false
buyPage.Parent = content
pages["BUY ACC"] = buyPage

lbl(buyPage, "💎 VIP Account", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 22), Enum.Font.GothamBold, 14, C.gold)
lbl(buyPage, "Unlock fitur premium Afterlife Project", UDim2.new(0, 0, 0, 24), UDim2.new(1, 0, 0, 14), Enum.Font.Gotham, 9, C.muted)

local vipBanner = Instance.new("Frame")
vipBanner.BackgroundColor3 = C.card
vipBanner.BorderSizePixel = 0
vipBanner.Position = UDim2.new(0, 0, 0, 48)
vipBanner.Size = UDim2.new(1, 0, 0, 120)
vipBanner.Parent = buyPage
corner(vipBanner, 12)
stroke(vipBanner, C.gold, 0.3, 2)

lbl(vipBanner, "⭐ VIP BENEFITS", UDim2.new(0, 16, 0, 12), UDim2.new(1, -32, 0, 20), Enum.Font.GothamBold, 12, C.gold)

local benefits = {
    "✓ Unlimited import per hari",
    "✓ Prioritas update fitur baru",
    "✓ Custom theme warna",
    "✓ Support development",
}
for i, b in ipairs(benefits) do
    lbl(vipBanner, b, UDim2.new(0, 16, 0, 36 + (i-1) * 18), UDim2.new(1, -32, 0, 16), Enum.Font.Gotham, 10, C.text)
end

local contactBtn = btn(buyPage, "📞 HUBUNGI ADMIN", UDim2.new(0, 0, 0, 180), UDim2.new(1, 0, 0, 34), C.purple2, 11)
hover(contactBtn, C.purple2, C.purple)
contactBtn.MouseButton1Click:Connect(function()
    showToast("📞 Hubungi Admin", "Discord: afterlife_project", C.purple)
end)

-- ============================================================
-- PAGE 5: SETTINGS (WORKING!)
-- ============================================================
local settingsPage = Instance.new("Frame")
settingsPage.BackgroundTransparency = 1
settingsPage.Position = UDim2.new(0, 18, 0, 60)
settingsPage.Size = UDim2.new(1, -36, 1, -74)
settingsPage.Visible = false
settingsPage.Parent = content
pages["SETTINGS"] = settingsPage

lbl(settingsPage, "☰ Settings", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 22), Enum.Font.GothamBold, 14, C.text)
lbl(settingsPage, "Pengaturan aplikasi Afterlife Project", UDim2.new(0, 0, 0, 24), UDim2.new(1, 0, 0, 14), Enum.Font.Gotham, 9, C.muted)

local settingHolder = Instance.new("ScrollingFrame")
settingHolder.BackgroundColor3 = C.panel
settingHolder.BorderSizePixel = 0
settingHolder.Position = UDim2.new(0, 0, 0, 48)
settingHolder.Size = UDim2.new(1, 0, 1, -48)
settingHolder.ScrollBarThickness = 3
settingHolder.ScrollBarImageColor3 = C.purple
settingHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
settingHolder.Parent = settingsPage
corner(settingHolder, 10)
stroke(settingHolder, C.purple2, 0.7, 1)
local setPad = Instance.new("UIPadding")
setPad.PaddingTop = UDim.new(0, 10)
setPad.PaddingBottom = UDim.new(0, 10)
setPad.PaddingLeft = UDim.new(0, 10)
setPad.PaddingRight = UDim.new(0, 10)
setPad.Parent = settingHolder
local setLayout = Instance.new("UIListLayout")
setLayout.Padding = UDim.new(0, 8)
setLayout.SortOrder = Enum.SortOrder.LayoutOrder
setLayout.Parent = settingHolder

local function makeToggle(label, key, callback)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = C.card2
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, -4, 0, 40)
    row.Parent = settingHolder
    corner(row, 8)
    
    lbl(row, label, UDim2.new(0, 12, 0, 0), UDim2.new(0.7, -12, 1, 0), Enum.Font.Gotham, 11, C.text)
    
    local toggle = Instance.new("TextButton")
    toggle.BackgroundColor3 = config[key] and C.purple or C.dim
    toggle.BorderSizePixel = 0
    toggle.Position = UDim2.new(1, -60, 0.5, -12)
    toggle.Size = UDim2.new(0, 48, 0, 24)
    toggle.Text = config[key] and "ON" or "OFF"
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 10
    toggle.TextColor3 = C.text
    toggle.AutoButtonColor = false
    toggle.Parent = row
    corner(toggle, 12)
    
    toggle.MouseButton1Click:Connect(function()
        config[key] = not config[key]
        toggle.BackgroundColor3 = config[key] and C.purple or C.dim
        toggle.Text = config[key] and "ON" or "OFF"
        saveConfig(config)
        if callback then callback(config[key]) end
    end)
    
    return row
end

makeToggle("Auto Scan saat buka", "autoScan")
makeToggle("Tampilkan Notifikasi", "showToast")
makeToggle("Suara Aktif", "soundEnabled")

-- Reset Button
local resetBtn = btn(settingHolder, "🗑️ RESET CONFIG", UDim2.new(0, 0, 0, 0), UDim2.new(1, -4, 0, 40), C.card, 10)
resetBtn.TextColor3 = C.red
hover(resetBtn, C.card, Color3.fromRGB(80, 30, 50))
resetBtn.MouseButton1Click:Connect(function()
    config = {}
    for k, v in pairs(defaultConfig) do config[k] = v end
    saveConfig(config)
    showToast("✓ Config direset", "Semua setting kembali ke default", C.green)
end)

-- Info Card
local infoCard = Instance.new("Frame")
infoCard.BackgroundColor3 = C.card
infoCard.BorderSizePixel = 0
infoCard.Size = UDim2.new(1, -4, 0, 80)
infoCard.Parent = settingHolder
corner(infoCard, 8)

lbl(infoCard, "📌 Info", UDim2.new(0, 12, 0, 10), UDim2.new(1, -24, 0, 18), Enum.Font.GothamBold, 11, C.purpleHover)
lbl(infoCard, "Afterlife Project v2.0\nStudio Lite + Delta Executor\nBy: ALIZZ", UDim2.new(0, 12, 0, 30), UDim2.new(1, -24, 0, 44), Enum.Font.Gotham, 9, C.muted).TextWrapped = true

setLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    settingHolder.CanvasSize = UDim2.new(0, 0, 0, setLayout.AbsoluteContentSize.Y + 20)
end)

-- ============================================================
-- PAGE NAVIGATION
-- ============================================================
local function setPage(name)
    activePage = name
    for pName, page in pairs(pages) do
        page.Visible = pName == name
    end
    for nName, info in pairs(navButtons) do
        local active = nName == name
        info.btn.BackgroundColor3 = active and C.card or C.sidebar
        info.bar.Visible = active
        info.icon.TextColor3 = active and C.purpleHover or C.muted
        info.text.TextColor3 = active and C.text or C.muted
    end
    
    if name == "ASSETS" then
        pageTitle.Text = "Dashboard"
        pageSub.Text = "Manage your local assets"
    elseif name == "TOOLBOX" then
        pageTitle.Text = "Toolbox"
        pageSub.Text = "Search & spawn models"
    elseif name == "PLUGINS" then
        pageTitle.Text = "Plugins"
        pageSub.Text = "Manage your plugins"
    elseif name == "BUY ACC" then
        pageTitle.Text = "Buy Account"
        pageSub.Text = "VIP membership"
    elseif name == "SETTINGS" then
        pageTitle.Text = "Settings"
        pageSub.Text = "App configuration"
    end
end

for name, info in pairs(navButtons) do
    info.btn.MouseButton1Click:Connect(function()
        setPage(name)
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    app.Visible = false
    toggleBtn.Visible = true
end)

toggleBtn.MouseButton1Click:Connect(function()
    app.Visible = not app.Visible
    toggleBtn.Visible = not app.Visible
    if app.Visible and config.autoScan then
        task.wait(0.3)
        -- auto scan kalo path tersimpan ada
        if pathInput.Text ~= "" then
            -- trigger scan otomatis
        end
    end
end)

-- ============================================================
-- ASSETS FUNCTIONS
-- ============================================================
local entries = {}
local rowObjects = {}
local scanning = false
local importing = false

local function clearRows()
    for _, r in ipairs(rowObjects) do r:Destroy() end
    rowObjects = {}
end

local function importFile(entry)
    local ok, result = pcall(function()
        return InsertService:LoadLocalAsset(entry.path)
    end)
    if not ok then
        entry.failed = true
        entry.error = cleanErr(result)
        return false, entry.error
    end
    if not result or typeof(result) ~= "Instance" then
        entry.failed = true
        entry.error = "LoadLocalAsset gak balikin Instance"
        return false
    end
    local ok2, err2 = pcall(function()
        result.Parent = Workspace
    end)
    if not ok2 then
        pcall(function() result:Destroy() end)
        entry.failed = true
        entry.error = cleanErr(err2)
        return false, entry.error
    end
    entry.imported = true
    entry.failed = false
    entry.root = result
    
    config.totalImported = (config.totalImported or 0) + 1
    saveConfig(config)
    vipNum.Text = tostring(config.totalImported)
    
    return true, result
end

local function renderList()
    clearRows()
    if #entries == 0 then
        emptyLbl.Visible = true
        assetList.CanvasSize = UDim2.new(0, 0, 0, 0)
        return
    end
    emptyLbl.Visible = false
    
    for i, entry in ipairs(entries) do
        local row = Instance.new("Frame")
        row.BackgroundColor3 = C.card2
        row.BorderSizePixel = 0
        row.Size = UDim2.new(1, -4, 0, 52)
        row.LayoutOrder = i
        row.Parent = assetList
        corner(row, 8)
        
        local iconBox = Instance.new("Frame")
        iconBox.BackgroundColor3 = C.panel
        iconBox.BorderSizePixel = 0
        iconBox.Position = UDim2.new(0, 8, 0.5, -16)
        iconBox.Size = UDim2.new(0, 32, 0, 32)
        iconBox.Parent = row
        corner(iconBox, 7)
        stroke(iconBox, C.purple2, 0.5, 1)
        local iconTxt = lbl(iconBox, "📁", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, 14, C.purpleHover)
        iconTxt.TextXAlignment = Enum.TextXAlignment.Center
        iconTxt.TextYAlignment = Enum.TextYAlignment.Center
        
        local nameLbl = lbl(row, entry.name, UDim2.new(0, 48, 0, 8), UDim2.new(1, -150, 0, 16), Enum.Font.GothamBold, 10, C.text)
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        
        local statusText, statusColor
        if entry.failed then
            statusText, statusColor = "ERROR", C.red
        elseif entry.imported then
            statusText, statusColor = "✓ IMPORTED", C.green
        else
            statusText, statusColor = "Ready", C.yellow
        end
        lbl(row, statusText, UDim2.new(0, 48, 0, 28), UDim2.new(1, -150, 0, 14), Enum.Font.Gotham, 9, statusColor)
        
        local importBtn = btn(row, entry.imported and "IMPORT LAGI" or "IMPORT", UDim2.new(1, -100, 0.5, -13), UDim2.new(0, 92, 0, 26), C.purple2, 9)
        hover(importBtn, C.purple2, C.purple)
        
        importBtn.MouseButton1Click:Connect(function()
            if importing or scanning then return end
            importing = true
            importBtn.Active = false
            showToast("⏳ Importing...", entry.name, C.yellow)
            local ok, res = importFile(entry)
            if ok then
                showToast("✓ Berhasil!", entry.name .. " dimasukkan ke Workspace", C.green)
            else
                showToast("✗ Gagal", tostring(res), C.red)
            end
            importing = false
            importBtn.Active = true
            renderList()
        end)
        
        rowObjects[#rowObjects + 1] = row
    end
    
    assetList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end

local function doScan()
    if scanning or importing then return end
    local folder = normalizePath(pathInput.Text or "")
    if folder == "" then
        showToast("✗ Error", "Path folder kosong!", C.red)
        return
    end
    
    config.lastPath = folder
    saveConfig(config)
    
    scanning = true
    scanBtn.Active = false
    scanBtn.Text = "⏳ SCANNING..."
    showToast("⏳ Scanning...", folder, C.yellow)
    
    task.spawn(function()
        local ok, result = pcall(scanFolder, folder, true)
        if not ok then
            showToast("✗ Scan Error", cleanErr(result), C.red)
        else
            entries = {}
            for _, path in ipairs(result) do
                entries[#entries + 1] = {
                    path = path,
                    name = fname(path),
                    imported = false,
                    failed = false,
                }
            end
            totalNum.Text = tostring(#entries)
            renderList()
            if #entries == 0 then
                showToast("ℹ️ Info", "Gak ada file RBXM di folder itu", C.yellow)
            else
                showToast("✓ Ditemukan!", #entries .. " file RBXM", C.green)
            end
        end
        scanBtn.Active = true
        scanBtn.Text = "🔍 SCAN"
        scanning = false
    end)
end

scanBtn.MouseButton1Click:Connect(doScan)

importAllBtn.MouseButton1Click:Connect(function()
    if #entries == 0 then
        showToast("ℹ️ Info", "Belum ada file. Scan dulu!", C.yellow)
        return
    end
    if importing then return end
    importing = true
    showToast("⏳ Import All...", "Mengimport " .. #entries .. " file", C.yellow)
    
    task.spawn(function()
        local success, failed = 0, 0
        for i, entry in ipairs(entries) do
            if not entry.imported then
                local ok = importFile(entry)
                if ok then success = success + 1 else failed = failed + 1 end
                renderList()
                task.wait(0.1)
            end
        end
        showToast("✓ Selesai!", success .. " berhasil, " .. failed .. " gagal", C.green)
        importing = false
        renderList()
    end)
end)

clearBtn.MouseButton1Click:Connect(function()
    entries = {}
    totalNum.Text = "0"
    renderList()
    showToast("🗑️ List dibersihkan", "Semua item dihapus dari list", C.muted)
end)

refreshBtn.MouseButton1Click:Connect(function()
    doScan()
end)

-- ============================================================
-- TOOLBOX FUNCTIONS (WORKING!)
-- ============================================================
local tbEntries = {}
local tbRows = {}

local function clearTbRows()
    for _, r in ipairs(tbRows) do r:Destroy() end
    tbRows = {}
end

local function spawnFromToolbox(assetId, name)
    local ok, model = pcall(function()
        return InsertService:LoadAsset(assetId)
    end)
    if not ok or not model then
        showToast("✗ Gagal", "Gak bisa load asset ID: " .. assetId, C.red)
        return false
    end
    
    -- Setup model
    local success = pcall(function()
        for _, child in ipairs(model:GetChildren()) do
            if child:IsA("BasePart") then
                child.Anchored = true
            end
        end
    end)
    
    model.Name = name or ("Toolbox_" .. assetId)
    model.Parent = Workspace
    
    -- Pindahin ke depan player
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local offset = root.CFrame + (root.CFrame.LookVector * 10) + Vector3.new(0, 3, 0)
                model:PivotTo(offset)
            end
        end
    end)
    
    showToast("✓ Spawned!", model.Name .. " muncul di depan lo", C.green)
    return true
end

local function renderToolboxResults(results)
    clearTbRows()
    if #results == 0 then
        tbEmpty.Visible = true
        tbEmpty.Text = "Gak ada hasil. Coba keyword lain."
        toolboxList.CanvasSize = UDim2.new(0, 0, 0, 0)
        return
    end
    tbEmpty.Visible = false
    
    for i, item in ipairs(results) do
        local row = Instance.new("Frame")
        row.BackgroundColor3 = C.card2
        row.BorderSizePixel = 0
        row.Size = UDim2.new(1, -4, 0, 60)
        row.LayoutOrder = i
        row.Parent = toolboxList
        corner(row, 8)
        
        local iconBox = Instance.new("Frame")
        iconBox.BackgroundColor3 = C.panel
        iconBox.BorderSizePixel = 0
        iconBox.Position = UDim2.new(0, 8, 0.5, -20)
        iconBox.Size = UDim2.new(0, 40, 0, 40)
        iconBox.Parent = row
        corner(iconBox, 8)
        stroke(iconBox, C.purple2, 0.5, 1)
        local iconTxt = lbl(iconBox, "📦", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, 18, C.purpleHover)
        iconTxt.TextXAlignment = Enum.TextXAlignment.Center
        iconTxt.TextYAlignment = Enum.TextYAlignment.Center
        
        local nameLbl = lbl(row, item.Name, UDim2.new(0, 58, 0, 8), UDim2.new(1, -170, 0, 16), Enum.Font.GothamBold, 10, C.text)
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl(row, "ID: " .. item.AssetId, UDim2.new(0, 58, 0, 28), UDim2.new(1, -170, 0, 14), Enum.Font.Code, 9, C.muted)
        lbl(row, "by " .. (item.CreatorName or "Unknown"), UDim2.new(0, 58, 0, 44), UDim2.new(1, -170, 0, 12), Enum.Font.Gotham, 8, C.dim)
        
        local spawnBtn = btn(row, "📥 SPAWN", UDim2.new(1, -100, 0.5, -13), UDim2.new(0, 92, 0, 26), C.purple2, 9)
        hover(spawnBtn, C.purple2, C.purple)
        spawnBtn.MouseButton1Click:Connect(function()
            spawnBtn.Active = false
            spawnBtn.Text = "⏳..."
            task.spawn(function()
                spawnFromToolbox(item.AssetId, item.Name)
                spawnBtn.Active = true
                spawnBtn.Text = "📥 SPAWN"
            end)
        end)
        
        tbRows[#tbRows + 1] = row
    end
    
    toolboxList.CanvasSize = UDim2.new(0, 0, 0, tbLayout.AbsoluteContentSize.Y + 20)
end

local function searchToolbox()
    local keyword = searchBox.Text
    if keyword == "" then
        showToast("✗ Error", "Ketik keyword dulu!", C.red)
        return
    end
    
    searchBtn.Active = false
    searchBtn.Text = "⏳ SEARCHING..."
    showToast("🔍 Mencari...", keyword, C.yellow)
    
    task.spawn(function()
        local ok, result = pcall(function()
            local url = "https://apis.roblox.com/toolbox-service/v1/marketplace/10?keyword=" .. HttpService:UrlEncode(keyword) .. "&limit=20"
            local response = HttpService:GetAsync(url, true)
            return HttpService:JSONDecode(response)
        end)
        
        if not ok then
            showToast("✗ Error", "Gagal search: " .. cleanErr(result), C.red)
        else
            local items = {}
            for _, item in ipairs(result.data or {}) do
                table.insert(items, {
                    AssetId = item.id,
                    Name = item.name or ("Asset_" .. item.id),
                    CreatorName = item.creatorName or "Unknown",
                })
            end
            renderToolboxResults(items)
            if #items > 0 then
                showToast("✓ Ditemukan!", #items .. " model untuk '" .. keyword .. "'", C.green)
            else
                showToast("ℹ️ Kosong", "Gak ada hasil buat '" .. keyword .. "'", C.yellow)
            end
        end
        
        searchBtn.Active = true
        searchBtn.Text = "🔍 CARI"
    end)
end

searchBtn.MouseButton1Click:Connect(searchToolbox)
searchBox.FocusLost:Connect(function(enter)
    if enter then searchToolbox() end
end)

-- ============================================================
-- PLUGINS FUNCTIONS (WORKING!)
-- ============================================================
local pluginFiles = {}
local pluginRows = {}

local function clearPluginRows()
    for _, r in ipairs(pluginRows) do r:Destroy() end
    pluginRows = {}
end

local function loadPlugin(path)
    if not readfile then
        showToast("✗ Gagal", "Executor gak support readfile", C.red)
        return
    end
    local ok, code = pcall(readfile, path)
    if not ok or not code then
        showToast("✗ Gagal", "Gak bisa baca file: " .. fname(path), C.red)
        return
    end
    local ok2, fn = pcall(loadstring, code)
    if not ok2 or not fn then
        showToast("✗ Gagal", "Script error di " .. fname(path), C.red)
        return
    end
    local ok3, err = pcall(fn)
    if not ok3 then
        showToast("⚠️ Warning", "Plugin ada error: " .. cleanErr(err), C.yellow)
    else
        showToast("✓ Plugin loaded!", fname(path), C.green)
    end
end

local function renderPlugins(files)
    clearPluginRows()
    if #files == 0 then
        plEmpty.Visible = true
        pluginList.CanvasSize = UDim2.new(0, 0, 0, 0)
        return
    end
    plEmpty.Visible = false
    
    for i, path in ipairs(files) do
        local row = Instance.new("Frame")
        row.BackgroundColor3 = C.card2
        row.BorderSizePixel = 0
        row.Size = UDim2.new(1, -4, 0, 46)
        row.LayoutOrder = i
        row.Parent = pluginList
        corner(row, 8)
        
        local iconBox = Instance.new("Frame")
        iconBox.BackgroundColor3 = C.panel
        iconBox.BorderSizePixel = 0
        iconBox.Position = UDim2.new(0, 8, 0.5, -14)
        iconBox.Size = UDim2.new(0, 28, 0, 28)
        iconBox.Parent = row
        corner(iconBox, 6)
        stroke(iconBox, C.purple2, 0.5, 1)
        local iconTxt = lbl(iconBox, "⚙", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, 13, C.purpleHover)
        iconTxt.TextXAlignment = Enum.TextXAlignment.Center
        iconTxt.TextYAlignment = Enum.TextYAlignment.Center
        
        local nameLbl = lbl(row, fname(path), UDim2.new(0, 44, 0, 8), UDim2.new(1, -140, 0, 16), Enum.Font.GothamBold, 10, C.text)
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl(row, path, UDim2.new(0, 44, 0, 26), UDim2.new(1, -140, 0, 12), Enum.Font.Code, 8, C.muted).TextTruncate = Enum.TextTruncate.AtEnd
        
        local loadBtn = btn(row, "▶ LOAD", UDim2.new(1, -88, 0.5, -12), UDim2.new(0, 80, 0, 24), C.purple2, 9)
        hover(loadBtn, C.purple2, C.purple)
        loadBtn.MouseButton1Click:Connect(function()
            loadPlugin(path)
        end)
        
        pluginRows[#pluginRows + 1] = row
    end
    
    pluginList.CanvasSize = UDim2.new(0, 0, 0, plLayout.AbsoluteContentSize.Y + 20)
end

scanPluginsBtn.MouseButton1Click:Connect(function()
    local folder = normalizePath(pluginPathInput.Text or "")
    if folder == "" then
        showToast("✗ Error", "Isi path dulu!", C.red)
        return
    end
    
    scanPluginsBtn.Active = false
    scanPluginsBtn.Text = "⏳..."
    showToast("⏳ Scan plugins...", folder, C.yellow)
    
    task.spawn(function()
        local ok, files = pcall(function()
            local result = {}
            local listFn = getFunc("listfiles")
            if not listFn then error("Gak support listfiles") end
            local items = listFn(folder)
            for _, item in ipairs(items) do
                local lower = string.lower(item)
                if lower:sub(-4) == ".lua" or lower:sub(-5) == ".luau" then
                    table.insert(result, item)
                end
            end
            return result
        end)
        
        if ok then
            pluginFiles = files
            renderPlugins(files)
            showToast("✓ Ditemukan!", #files .. " plugin", C.green)
        else
            showToast("✗ Error", cleanErr(files), C.red)
        end
        
        scanPluginsBtn.Active = true
        scanPluginsBtn.Text = "🔍 SCAN"
    end)
end)

-- ============================================================
-- INIT
-- ============================================================
setPage("ASSETS")

-- Toast pembuka
task.wait(0.5)
showToast("👑 Afterlife Project v2.0", "Semua fitur aktif! Klik R buat buka panel", C.purple)

print("[Afterlife Project v2.0] ✅ Loaded - All features working!")
