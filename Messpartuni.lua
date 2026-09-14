--[[
    AFTERLIFE PROJECT - RBXM Importer v1.0
    Studio Lite Edition | Delta Executor Compatible
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local GUI_NAME = "AfterlifeProject_Importer"

-- ============================================================
-- COLOR PALETTE (Afterlife style)
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
-- FILE SYSTEM
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
    -- Fallback: cek extension
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
-- TOAST NOTIFICATION
-- ============================================================
local toastHolder = Instance.new("Frame")
toastHolder.BackgroundTransparency = 1
toastHolder.Position = UDim2.new(1, -340, 0, 20)
toastHolder.Size = UDim2.new(0, 320, 0, 200)
toastHolder.Parent = screenGui

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 8)
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Top
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastHolder

local function showToast(title, message, color)
    color = color or C.purple
    local toast = Instance.new("Frame")
    toast.BackgroundColor3 = C.card
    toast.BorderSizePixel = 0
    toast.Size = UDim2.new(1, 0, 0, 60)
    toast.Parent = toastHolder
    corner(toast, 10)
    stroke(toast, color, 0.3, 1.5)
    
    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.Parent = toast
    corner(accent, 10)
    
    lbl(toast, title, UDim2.new(0, 14, 0, 10), UDim2.new(1, -20, 0, 18), Enum.Font.GothamBold, 12, C.text)
    local msg = lbl(toast, message, UDim2.new(0, 14, 0, 30), UDim2.new(1, -20, 0, 22), Enum.Font.Gotham, 10, C.muted)
    msg.TextWrapped = true
    
    -- Auto dismiss
    task.spawn(function()
        task.wait(3)
        TweenService:Create(toast, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        for _, c in ipairs(toast:GetDescendants()) do
            if c:IsA("TextLabel") then
                TweenService:Create(c, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            end
        end
        task.wait(0.4)
        toast:Destroy()
    end)
end

-- ============================================================
-- FLOATING TOGGLE BUTTON
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
-- MAIN APP FRAME
-- ============================================================
local app = Instance.new("Frame")
app.Name = "App"
app.Size = UDim2.new(0, 620, 0, 380)
app.Position = UDim2.new(0.5, 0, 0.5, 0)
app.AnchorPoint = Vector2.new(0.5, 0.5)
app.BackgroundColor3 = C.bg
app.BorderSizePixel = 0
app.Visible = false
app.Parent = screenGui
corner(app, 14)
stroke(app, C.purple2, 0.4, 1.5)

-- Purple gradient glow di top
local glow = Instance.new("Frame")
glow.BackgroundColor3 = C.purple
glow.BackgroundTransparency = 0.8
glow.BorderSizePixel = 0
glow.Position = UDim2.new(0, 0, 0, 0)
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

-- Logo / Brand
local brandBox = Instance.new("Frame")
brandBox.BackgroundColor3 = C.panel
brandBox.BorderSizePixel = 0
brandBox.Position = UDim2.new(0, 14, 0, 14)
brandBox.Size = UDim2.new(1, -28, 0, 44)
brandBox.Parent = sidebar
corner(brandBox, 10)
stroke(brandBox, C.purple2, 0.6, 1)

lbl(brandBox, "AFTERLIFE", UDim2.new(0, 10, 0, 4), UDim2.new(1, -20, 0, 18), Enum.Font.GothamBold, 12, C.text)
lbl(brandBox, "PROJECT", UDim2.new(0, 10, 0, 20), UDim2.new(1, -20, 0, 14), Enum.Font.Gotham, 8, C.muted)

-- Nav Items
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
-- CONTENT AREA
-- ============================================================
local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 150, 0, 0)
content.Size = UDim2.new(1, -150, 1, 0)
content.Parent = app

-- Content Header
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
-- DASHBOARD PAGE
-- ============================================================
local dashboardPage = Instance.new("Frame")
dashboardPage.BackgroundTransparency = 1
dashboardPage.Position = UDim2.new(0, 18, 0, 60)
dashboardPage.Size = UDim2.new(1, -36, 1, -74)
dashboardPage.Parent = content
pages["ASSETS"] = dashboardPage

-- Stats Cards Row
local statsRow = Instance.new("Frame")
statsRow.BackgroundTransparency = 1
statsRow.Size = UDim2.new(1, 0, 0, 62)
statsRow.Parent = dashboardPage

-- Card 1: Total Files
local totalCard = Instance.new("Frame")
totalCard.BackgroundColor3 = C.card
totalCard.BorderSizePixel = 0
totalCard.Size = UDim2.new(0.5, -4, 1, 0)
totalCard.Parent = statsRow
corner(totalCard, 10)
stroke(totalCard, C.purple2, 0.6, 1)

local totalNum = lbl(totalCard, "0", UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 24), Enum.Font.GothamBold, 20, C.text)
lbl(totalCard, "Total RBXM Files", UDim2.new(0, 12, 0, 36), UDim2.new(1, -24, 0, 14), Enum.Font.Gotham, 9, C.muted)

-- Card 2: VIP Users
local vipCard = Instance.new("Frame")
vipCard.BackgroundColor3 = C.card
vipCard.BorderSizePixel = 0
vipCard.Position = UDim2.new(0.5, 4, 0, 0)
vipCard.Size = UDim2.new(0.5, -4, 1, 0)
vipCard.Parent = statsRow
corner(vipCard, 10)
stroke(vipCard, C.gold, 0.4, 1.5)

local vipNum = lbl(vipCard, "0", UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 24), Enum.Font.GothamBold, 20, C.gold)
lbl(vipCard, "VIP USERS", UDim2.new(0, 12, 0, 36), UDim2.new(1, -24, 0, 14), Enum.Font.Gotham, 9, C.muted)

-- Recent Assets Header
local recentHeader = Instance.new("Frame")
recentHeader.BackgroundTransparency = 1
recentHeader.Position = UDim2.new(0, 0, 0, 78)
recentHeader.Size = UDim2.new(1, 0, 0, 22)
recentHeader.Parent = dashboardPage

lbl(recentHeader, "Recent Assets", UDim2.new(0, 0, 0, 0), UDim2.new(1, -80, 1, 0), Enum.Font.GothamBold, 12, C.text)

-- Folder path input
local pathInput = Instance.new("TextBox")
pathInput.BackgroundColor3 = C.input
pathInput.BorderSizePixel = 0
pathInput.Position = UDim2.new(0, 0, 0, 108)
pathInput.Size = UDim2.new(0.72, -4, 0, 32)
pathInput.Font = Enum.Font.Code
pathInput.TextSize = 10
pathInput.TextColor3 = C.text
pathInput.PlaceholderColor3 = C.muted
pathInput.PlaceholderText = "Path folder (contoh: /sdcard/Download)"
pathInput.Text = "/sdcard/Download"
pathInput.ClearTextOnFocus = false
pathInput.TextXAlignment = Enum.TextXAlignment.Left
pathInput.Parent = dashboardPage
corner(pathInput, 8)
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = pathInput

local scanBtn = btn(dashboardPage, "🔍 SCAN", UDim2.new(0.72, 4, 0, 108), UDim2.new(0.28, -4, 0, 32), C.purple2, 10)
hover(scanBtn, C.purple2, C.purple)

-- Asset List
local assetList = Instance.new("ScrollingFrame")
assetList.BackgroundColor3 = C.panel
assetList.BorderSizePixel = 0
assetList.Position = UDim2.new(0, 0, 0, 150)
assetList.Size = UDim2.new(1, 0, 1, -150)
assetList.ScrollBarThickness = 3
assetList.ScrollBarImageColor3 = C.purple
assetList.CanvasSize = UDim2.new(0, 0, 0, 0)
assetList.Parent = dashboardPage
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

local emptyLbl = lbl(assetList, "Belum ada file.\nKlik SCAN untuk mencari RBXM.", UDim2.new(0, 20, 0.5, -24), UDim2.new(1, -40, 0, 48), Enum.Font.Gotham, 10, C.muted)
emptyLbl.TextWrapped = true
emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
emptyLbl.TextYAlignment = Enum.TextYAlignment.Center

-- ============================================================
-- OTHER PAGES (Placeholder)
-- ============================================================
local otherPages = {}
local function makePlaceholder(name, title, desc)
    local p = Instance.new("Frame")
    p.BackgroundTransparency = 1
    p.Position = UDim2.new(0, 18, 0, 60)
    p.Size = UDim2.new(1, -36, 1, -74)
    p.Visible = false
    p.Parent = content
    pages[name] = p
    
    local card = Instance.new("Frame")
    card.BackgroundColor3 = C.card
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, 0, 0, 100)
    card.Parent = p
    corner(card, 10)
    stroke(card, C.purple2, 0.6, 1)
    
    lbl(card, title, UDim2.new(0, 16, 0, 18), UDim2.new(1, -32, 0, 24), Enum.Font.GothamBold, 14, C.text)
    local d = lbl(card, desc, UDim2.new(0, 16, 0, 48), UDim2.new(1, -32, 0, 40), Enum.Font.Gotham, 10, C.muted)
    d.TextWrapped = true
end

makePlaceholder("TOOLBOX", "🧰 Toolbox", "Fitur ini sedang dikembangkan. Nantikan update selanjutnya!")
makePlaceholder("PLUGINS", "⚙ Plugins", "Fitur ini sedang dikembangkan. Nantikan update selanjutnya!")
makePlaceholder("BUY ACC", "💎 Buy Account", "Fitur ini sedang dikembangkan. Nantikan update selanjutnya!")
makePlaceholder("SETTINGS", "☰ Settings", "Pengaturan aplikasi. Fitur ini sedang dikembangkan.")

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
    else
        pageTitle.Text = name:sub(1,1) .. name:sub(2):lower()
        pageSub.Text = "Coming soon feature"
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
end)

-- ============================================================
-- RENDER ASSETS
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
        
        -- File icon box
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
        
        -- Filename
        local nameLbl = lbl(row, entry.name, UDim2.new(0, 48, 0, 8), UDim2.new(1, -150, 0, 16), Enum.Font.GothamBold, 10, C.text)
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        
        -- Status
        local statusText, statusColor
        if entry.failed then
            statusText, statusColor = "ERROR", C.red
        elseif entry.imported then
            statusText, statusColor = "✓ IMPORTED", C.green
        else
            statusText, statusColor = "Ready", C.yellow
        end
        lbl(row, statusText, UDim2.new(0, 48, 0, 28), UDim2.new(1, -150, 0, 14), Enum.Font.Gotham, 9, statusColor)
        
        -- Import Button
        local importBtn = btn(row, entry.imported and "IMPORT LAGI" or "IMPORT", UDim2.new(1, -100, 0.5, -13), UDim2.new(0, 92, 0, 26), C.purple2, 9)
        hover(importBtn, C.purple2, C.purple)
        
        importBtn.MouseButton1Click:Connect(function()
            if importing or scanning then return end
            importing = true
            importBtn.Active = false
            showToast("Importing...", entry.name, C.yellow)
            local ok, res = importFile(entry)
            if ok then
                showToast("✓ Berhasil!", entry.name .. " di-import ke Workspace", C.green)
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

-- ============================================================
-- SCAN FUNCTION
-- ============================================================
local function doScan()
    if scanning or importing then return end
    local folder = normalizePath(pathInput.Text or "")
    if folder == "" then
        showToast("✗ Error", "Path folder kosong!", C.red)
        return
    end
    
    scanning = true
    scanBtn.Active = false
    scanBtn.Text = "⏳ SCANNING..."
    showToast("Scanning...", folder, C.yellow)
    
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

-- ============================================================
-- INIT
-- ============================================================
setPage("ASSETS")
showToast("👑 Afterlife Project", "Importer loaded! Klik tombol R untuk buka panel.", C.purple)

print("[Afterlife Importer] ✅ Loaded!")
