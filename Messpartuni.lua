--[[
    RBXM Asset Hub - Studio Lite

    UI bergaya asset manager: splash screen, sidebar, Dashboard, Assets,
    Settings, filter, search, Rescan Assets, dan import native.

    PENTING:
    - Scan hanya mencari file .rbxm menggunakan listfiles(folder).
    - Import TIDAK membongkar/membangun ulang Part.
    - Import diserahkan langsung ke InsertService:LoadLocalAsset(path)
      agar ukuran, CFrame, mesh, hierarchy, dan property tetap mengikuti file.

    Executor yang diperlukan:
      listfiles(folder)
      opsional: isfolder(path) untuk scan subfolder

    API Roblox/Studio Lite yang diperlukan:
      InsertService:LoadLocalAsset(path)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
if LocalPlayer == nil then
    return
end

local GUI_NAME = "RBXMAssetHub_StudioLite"
local MAX_SCAN_DEPTH = 8
local MAX_FILES = 500

local C = {
    black = Color3.fromRGB(5, 5, 9),
    background = Color3.fromRGB(13, 15, 23),
    panel = Color3.fromRGB(18, 18, 27),
    sidebar = Color3.fromRGB(9, 8, 14),
    card = Color3.fromRGB(27, 24, 40),
    card2 = Color3.fromRGB(33, 29, 49),
    input = Color3.fromRGB(35, 30, 51),
    line = Color3.fromRGB(101, 47, 141),
    purple = Color3.fromRGB(177, 83, 246),
    purple2 = Color3.fromRGB(122, 51, 187),
    purpleHover = Color3.fromRGB(198, 107, 255),
    text = Color3.fromRGB(246, 243, 252),
    muted = Color3.fromRGB(166, 151, 183),
    dim = Color3.fromRGB(111, 99, 127),
    green = Color3.fromRGB(99, 222, 155),
    yellow = Color3.fromRGB(244, 199, 96),
    red = Color3.fromRGB(255, 105, 126),
}

local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui ~= nil then
    oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 120
screenGui.Parent = playerGui

local function corner(parent, radius)
    local item = Instance.new("UICorner")
    item.CornerRadius = UDim.new(0, radius)
    item.Parent = parent
    return item
end

local function stroke(parent, color, transparency, thickness)
    local item = Instance.new("UIStroke")
    item.Color = color
    item.Transparency = transparency or 0
    item.Thickness = thickness or 1
    item.Parent = parent
    return item
end

local function label(parent, text, position, size, font, textSize, color)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Position = position
    item.Size = size
    item.Font = font or Enum.Font.Gotham
    item.TextSize = textSize or 12
    item.TextColor3 = color or C.text
    item.Text = text or ""
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.Parent = parent
    return item
end

local function button(parent, text, position, size, background, textSize)
    local item = Instance.new("TextButton")
    item.BackgroundColor3 = background or C.card
    item.BorderSizePixel = 0
    item.Position = position
    item.Size = size
    item.Font = Enum.Font.GothamBold
    item.TextSize = textSize or 11
    item.TextColor3 = C.text
    item.Text = text or ""
    item.AutoButtonColor = false
    item.Parent = parent
    corner(item, 8)
    return item
end

local function addHover(item, normal, over)
    item.MouseEnter:Connect(function()
        if item.Active then
            TweenService:Create(item, TweenInfo.new(0.12), {BackgroundColor3 = over}):Play()
        end
    end)
    item.MouseLeave:Connect(function()
        if item.Active then
            TweenService:Create(item, TweenInfo.new(0.12), {BackgroundColor3 = normal}):Play()
        end
    end)
end

-- -------------------------------------------------------------------------
-- Native file access helpers
-- -------------------------------------------------------------------------
local function executorFunction(name)
    local candidate = nil
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            candidate = env[name]
        end
    end
    if type(candidate) ~= "function" then
        candidate = _G[name]
    end
    if type(candidate) ~= "function" then
        local ok, value = pcall(function()
            return getfenv()[name]
        end)
        if ok then
            candidate = value
        end
    end
    return type(candidate) == "function" and candidate or nil
end

local function normalizePath(path)
    path = tostring(path or "")
    path = path:gsub("\\", "/")
    path = path:gsub("/+", "/")
    if #path > 1 then
        path = path:gsub("/$", "")
    end
    return path
end

local function fileName(path)
    return tostring(path):match("([^/]+)$") or tostring(path)
end

local function isRbxm(path)
    return string.lower(tostring(path)):sub(-5) == ".rbxm"
end

local function cleanError(message)
    local text = tostring(message or "error")
    text = text:gsub("^.-:%d+: ", "")
    if #text > 190 then
        text = text:sub(1, 187) .. "..."
    end
    return text
end

local function listFolder(path)
    local listFunction = executorFunction("listfiles")
    if listFunction == nil then
        error("Executor tidak menyediakan listfiles(folder)", 0)
    end
    local ok, result = pcall(listFunction, path)
    if not ok then
        error("listfiles gagal: " .. tostring(result), 0)
    end
    if type(result) ~= "table" then
        error("listfiles tidak mengembalikan table", 0)
    end
    return result
end

local function isFolder(path)
    local folderFunction = executorFunction("isfolder")
    if folderFunction ~= nil then
        local ok, result = pcall(folderFunction, path)
        if ok then
            return result == true
        end
    end
    return tostring(path):sub(-1) == "/"
end

local function collectRbxmFiles(root, recursive)
    local paths = {}
    local seenFiles = {}
    local seenFolders = {}

    local function visit(folder, depth)
        folder = normalizePath(folder)
        if depth > MAX_SCAN_DEPTH or seenFolders[folder] or #paths >= MAX_FILES then
            return
        end
        seenFolders[folder] = true

        local children = listFolder(folder)
        for _, item in ipairs(children) do
            if #paths >= MAX_FILES then
                break
            end
            local path = normalizePath(item)
            if isFolder(path) then
                if recursive then
                    pcall(visit, path, depth + 1)
                end
            elseif isRbxm(path) then
                local key = string.lower(path)
                if not seenFiles[key] then
                    seenFiles[key] = true
                    paths[#paths + 1] = path
                end
            end
        end
    end

    visit(root, 0)
    table.sort(paths, function(a, b)
        return string.lower(fileName(a)) < string.lower(fileName(b))
    end)
    return paths
end

-- -------------------------------------------------------------------------
-- UI shell
-- -------------------------------------------------------------------------
local backdrop = Instance.new("Frame")
backdrop.BackgroundColor3 = C.black
backdrop.BackgroundTransparency = 0.22
backdrop.BorderSizePixel = 0
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.Parent = screenGui

local app = Instance.new("Frame")
app.Name = "AssetHub"
app.Size = UDim2.new(0.91, 0, 0.82, 0)
app.Position = UDim2.new(0.5, 0, 0.5, 0)
app.AnchorPoint = Vector2.new(0.5, 0.5)
app.BackgroundColor3 = C.panel
app.BorderSizePixel = 0
app.Visible = false
app.Parent = backdrop
corner(app, 14)
stroke(app, C.line, 0.18, 1)

local appConstraint = Instance.new("UISizeConstraint")
appConstraint.MinSize = Vector2.new(540, 390)
appConstraint.MaxSize = Vector2.new(960, 650)
appConstraint.Parent = app

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.BackgroundColor3 = C.sidebar
sidebar.BorderSizePixel = 0
sidebar.Size = UDim2.new(0, 218, 1, 0)
sidebar.Parent = app
corner(sidebar, 14)

local sidebarMask = Instance.new("Frame")
sidebarMask.BackgroundColor3 = C.sidebar
sidebarMask.BorderSizePixel = 0
sidebarMask.Position = UDim2.new(1, -14, 0, 0)
sidebarMask.Size = UDim2.new(0, 14, 1, 0)
sidebarMask.Parent = sidebar

local brandIcon = Instance.new("TextLabel")
brandIcon.BackgroundColor3 = C.card2
brandIcon.BorderSizePixel = 0
brandIcon.Position = UDim2.new(0, 20, 0, 18)
brandIcon.Size = UDim2.new(0, 42, 0, 42)
brandIcon.Font = Enum.Font.GothamBold
brandIcon.TextSize = 18
brandIcon.TextColor3 = C.purpleHover
brandIcon.Text = "R"
brandIcon.Parent = sidebar
corner(brandIcon, 12)
stroke(brandIcon, C.purple2, 0.15, 1)

local brandTitle = label(sidebar, "RBXM Asset Hub", UDim2.new(0, 73, 0, 19), UDim2.new(1, -85, 0, 20), Enum.Font.GothamBold, 13, C.text)
local brandVersion = label(sidebar, "Studio Lite  •  Native", UDim2.new(0, 73, 0, 39), UDim2.new(1, -85, 0, 16), Enum.Font.Gotham, 9, C.muted)

local sideLine = Instance.new("Frame")
sideLine.BackgroundColor3 = C.line
sideLine.BackgroundTransparency = 0.55
sideLine.BorderSizePixel = 0
sideLine.Position = UDim2.new(0, 20, 0, 80)
sideLine.Size = UDim2.new(1, -40, 0, 1)
sideLine.Parent = sidebar

local navHolder = Instance.new("Frame")
navHolder.BackgroundTransparency = 1
navHolder.Position = UDim2.new(0, 12, 0, 101)
navHolder.Size = UDim2.new(1, -24, 0, 140)
navHolder.Parent = sidebar

local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 6)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Parent = navHolder

local navButtons = {}
local navOrder = 0
local pages = {}
local activePage = "Overview"

local function makeNav(name, icon)
    local item = button(navHolder, "", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 39), C.sidebar, 11)
    item.Name = name
    navOrder = navOrder + 1
    item.LayoutOrder = navOrder

    local activeBar = Instance.new("Frame")
    activeBar.Name = "ActiveBar"
    activeBar.BackgroundColor3 = C.purple
    activeBar.BorderSizePixel = 0
    activeBar.Position = UDim2.new(0, 0, 0.5, -11)
    activeBar.Size = UDim2.new(0, 4, 0, 22)
    activeBar.Visible = false
    activeBar.Parent = item
    corner(activeBar, 3)

    local iconLabel = label(item, icon, UDim2.new(0, 20, 0, 0), UDim2.new(0, 25, 1, 0), Enum.Font.GothamBold, 17, C.muted)
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    local textLabel = label(item, name, UDim2.new(0, 58, 0, 0), UDim2.new(1, -65, 1, 0), Enum.Font.Gotham, 11, C.muted)

    item.MouseEnter:Connect(function()
        if activePage ~= name then
            item.BackgroundColor3 = C.card
        end
    end)
    item.MouseLeave:Connect(function()
        if activePage ~= name then
            item.BackgroundColor3 = C.sidebar
        end
    end)

    navButtons[name] = {
        button = item,
        bar = activeBar,
        icon = iconLabel,
        text = textLabel,
    }
    return item
end

local overviewNav = makeNav("Overview", "▦")
local assetsNav = makeNav("Assets", "▰")
local settingsNav = makeNav("Settings", "⚙")

local quickLine = Instance.new("Frame")
quickLine.BackgroundColor3 = C.line
quickLine.BackgroundTransparency = 0.55
quickLine.BorderSizePixel = 0
quickLine.Position = UDim2.new(0, 20, 1, -145)
quickLine.Size = UDim2.new(1, -40, 0, 1)
quickLine.Parent = sidebar

local quickLabel = label(sidebar, "QUICK TOOLS", UDim2.new(0, 20, 1, -126), UDim2.new(1, -40, 0, 18), Enum.Font.GothamBold, 9, C.dim)

local rescanButton = button(sidebar, "↻    Rescan Assets", UDim2.new(0, 20, 1, -91), UDim2.new(1, -40, 0, 38), C.card, 10)
rescanButton.TextXAlignment = Enum.TextXAlignment.Left
local rescanPadding = Instance.new("UIPadding")
rescanPadding.PaddingLeft = UDim.new(0, 14)
rescanPadding.Parent = rescanButton
addHover(rescanButton, C.card, C.card2)

local sideHint = label(sidebar, "Native import keeps original\nmodel data intact.", UDim2.new(0, 20, 1, -43), UDim2.new(1, -40, 0, 34), Enum.Font.Gotham, 9, C.dim)
sideHint.TextWrapped = true

local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 218, 0, 0)
content.Size = UDim2.new(1, -218, 1, 0)
content.Parent = app

local contentHeader = Instance.new("Frame")
contentHeader.BackgroundTransparency = 1
contentHeader.Position = UDim2.new(0, 28, 0, 20)
contentHeader.Size = UDim2.new(1, -56, 0, 32)
contentHeader.Parent = content

local pageTitle = label(contentHeader, "Dashboard", UDim2.new(0, 0, 0, 0), UDim2.new(1, -60, 0, 22), Enum.Font.GothamBold, 19, C.text)
local pageSubTitle = label(contentHeader, "Manage your local Roblox assets seamlessly.", UDim2.new(0, 0, 0, 22), UDim2.new(1, -40, 0, 14), Enum.Font.Gotham, 10, C.muted)

local closeButton = button(contentHeader, "×", UDim2.new(1, -31, 0, 0), UDim2.new(0, 30, 0, 30), C.card, 16)
closeButton.TextColor3 = C.muted
addHover(closeButton, C.card, Color3.fromRGB(75, 44, 64))
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local footerStatus = label(content, "Ready.", UDim2.new(0, 28, 1, -28), UDim2.new(1, -56, 0, 16), Enum.Font.Gotham, 9, C.muted)
footerStatus.TextTruncate = Enum.TextTruncate.AtEnd

local function setStatus(text, color)
    footerStatus.Text = tostring(text)
    footerStatus.TextColor3 = color or C.muted
end

-- -------------------------------------------------------------------------
-- Dashboard page
-- -------------------------------------------------------------------------
local overviewPage = Instance.new("Frame")
overviewPage.Name = "OverviewPage"
overviewPage.BackgroundTransparency = 1
overviewPage.Position = UDim2.new(0, 28, 0, 83)
overviewPage.Size = UDim2.new(1, -56, 1, -124)
overviewPage.Parent = content
pages.Overview = overviewPage

local totalCard = Instance.new("Frame")
totalCard.BackgroundColor3 = C.card
totalCard.BorderSizePixel = 0
totalCard.Size = UDim2.new(0.5, -7, 0, 82)
totalCard.Parent = overviewPage
corner(totalCard, 11)
stroke(totalCard, C.line, 0.45, 1)
local totalNumber = label(totalCard, "0", UDim2.new(0, 18, 0, 13), UDim2.new(1, -36, 0, 28), Enum.Font.GothamBold, 24, C.text)
local totalCaption = label(totalCard, "TOTAL ASSETS", UDim2.new(0, 18, 0, 49), UDim2.new(1, -36, 0, 16), Enum.Font.Gotham, 9, C.muted)

local typeCard = Instance.new("Frame")
typeCard.BackgroundColor3 = C.card
typeCard.BorderSizePixel = 0
typeCard.Position = UDim2.new(0.5, 7, 0, 0)
typeCard.Size = UDim2.new(0.5, -7, 0, 82)
typeCard.Parent = overviewPage
corner(typeCard, 11)
stroke(typeCard, C.line, 0.45, 1)
local rbxmNumber = label(typeCard, "0", UDim2.new(0, 18, 0, 13), UDim2.new(1, -36, 0, 28), Enum.Font.GothamBold, 24, C.text)
local rbxmCaption = label(typeCard, "RBXM FILES", UDim2.new(0, 18, 0, 49), UDim2.new(1, -36, 0, 16), Enum.Font.Gotham, 9, C.muted)

local welcomeCard = Instance.new("Frame")
welcomeCard.BackgroundColor3 = C.card
welcomeCard.BorderSizePixel = 0
welcomeCard.Position = UDim2.new(0, 0, 0, 101)
welcomeCard.Size = UDim2.new(1, 0, 0, 138)
welcomeCard.Parent = overviewPage
corner(welcomeCard, 11)
stroke(welcomeCard, C.line, 0.55, 1)
local welcomeTitle = label(welcomeCard, "Native asset workflow", UDim2.new(0, 18, 0, 18), UDim2.new(1, -36, 0, 22), Enum.Font.GothamBold, 14, C.text)
local welcomeText = label(welcomeCard, "Scan folder untuk menemukan model lokal. Saat di-import, file langsung diproses oleh Roblox sehingga ukuran dan isi model tidak dihitung ulang oleh panel ini.", UDim2.new(0, 18, 0, 48), UDim2.new(1, -36, 0, 45), Enum.Font.Gotham, 10, C.muted)
welcomeText.TextWrapped = true

local openAssetsButton = button(welcomeCard, "OPEN ASSETS", UDim2.new(0, 18, 1, -39), UDim2.new(0, 126, 0, 28), C.purple2, 9)
addHover(openAssetsButton, C.purple2, C.purple)

local overviewNote = label(overviewPage, "Quick tools", UDim2.new(0, 0, 0, 258), UDim2.new(1, -4, 0, 18), Enum.Font.GothamBold, 11, C.text)
local overviewRescan = button(overviewPage, "↻   Rescan local assets", UDim2.new(0, 0, 0, 284), UDim2.new(1, -4, 0, 40), C.card2, 10)
overviewRescan.TextXAlignment = Enum.TextXAlignment.Left
local overviewPadding = Instance.new("UIPadding")
overviewPadding.PaddingLeft = UDim.new(0, 14)
overviewPadding.Parent = overviewRescan
addHover(overviewRescan, C.card2, C.input)

-- -------------------------------------------------------------------------
-- Assets page
-- -------------------------------------------------------------------------
local assetsPage = Instance.new("Frame")
assetsPage.Name = "AssetsPage"
assetsPage.BackgroundTransparency = 1
assetsPage.Position = UDim2.new(0, 28, 0, 79)
assetsPage.Size = UDim2.new(1, -56, 1, -120)
assetsPage.Visible = false
assetsPage.Parent = content
pages.Assets = assetsPage

local assetsTopLine = Instance.new("Frame")
assetsTopLine.BackgroundTransparency = 1
assetsTopLine.Size = UDim2.new(1, 0, 0, 34)
assetsTopLine.Parent = assetsPage
local assetsDescription = label(assetsTopLine, "Scan and import local RBXM files.", UDim2.new(0, 0, 0, 0), UDim2.new(0.5, 0, 1, 0), Enum.Font.Gotham, 10, C.muted)

local assetSearch = Instance.new("TextBox")
assetSearch.Position = UDim2.new(0.5, 0, 0, 0)
assetSearch.Size = UDim2.new(0.5, -4, 0, 30)
assetSearch.BackgroundColor3 = C.input
assetSearch.BorderSizePixel = 0
assetSearch.ClearTextOnFocus = false
assetSearch.Font = Enum.Font.Gotham
assetSearch.TextSize = 10
assetSearch.TextColor3 = C.text
assetSearch.PlaceholderColor3 = C.muted
assetSearch.PlaceholderText = "Search assets..."
assetSearch.Text = ""
assetSearch.TextXAlignment = Enum.TextXAlignment.Left
assetSearch.Parent = assetsTopLine
corner(assetSearch, 7)
local assetSearchPadding = Instance.new("UIPadding")
assetSearchPadding.PaddingLeft = UDim.new(0, 10)
assetSearchPadding.PaddingRight = UDim.new(0, 10)
assetSearchPadding.Parent = assetSearch

local filterBar = Instance.new("Frame")
filterBar.BackgroundColor3 = C.input
filterBar.BorderSizePixel = 0
filterBar.Position = UDim2.new(0, 0, 0, 44)
filterBar.Size = UDim2.new(1, 0, 0, 34)
filterBar.Parent = assetsPage
corner(filterBar, 17)

local filters = {}
local currentFilter = "ALL"
local function makeFilter(name, text, position, size)
    local item = button(filterBar, text, position, size, C.input, 9)
    item.TextColor3 = C.muted
    item.Name = name
    filters[name] = item
    return item
end
makeFilter("ALL", "ALL", UDim2.new(0, 2, 0, 2), UDim2.new(0.333, -3, 1, -4))
makeFilter("RBXM", "RBXM", UDim2.new(0.333, 1, 0, 2), UDim2.new(0.333, -3, 1, -4))
makeFilter("RBXL", "RBXL", UDim2.new(0.666, 0, 0, 2), UDim2.new(0.333, -3, 1, -4))

local assetList = Instance.new("ScrollingFrame")
assetList.BackgroundColor3 = C.card
assetList.BorderSizePixel = 0
assetList.Position = UDim2.new(0, 0, 0, 91)
assetList.Size = UDim2.new(1, 0, 1, -91)
assetList.ScrollBarThickness = 4
assetList.ScrollBarImageColor3 = C.line
assetList.CanvasSize = UDim2.new(0, 0, 0, 0)
assetList.Parent = assetsPage
corner(assetList, 11)
local assetListPadding = Instance.new("UIPadding")
assetListPadding.PaddingTop = UDim.new(0, 9)
assetListPadding.PaddingBottom = UDim.new(0, 9)
assetListPadding.PaddingLeft = UDim.new(0, 9)
assetListPadding.PaddingRight = UDim.new(0, 9)
assetListPadding.Parent = assetList
local assetLayout = Instance.new("UIListLayout")
assetLayout.Padding = UDim.new(0, 7)
assetLayout.SortOrder = Enum.SortOrder.LayoutOrder
assetLayout.Parent = assetList

local assetEmpty = label(assetList, "Belum ada file.\nTekan Rescan Assets untuk mencari RBXM.", UDim2.new(0, 20, 0.5, -24), UDim2.new(1, -40, 0, 48), Enum.Font.Gotham, 10, C.muted)
assetEmpty.TextWrapped = true
assetEmpty.TextXAlignment = Enum.TextXAlignment.Center
assetEmpty.TextYAlignment = Enum.TextYAlignment.Center

-- -------------------------------------------------------------------------
-- Settings page
-- -------------------------------------------------------------------------
local settingsPage = Instance.new("Frame")
settingsPage.Name = "SettingsPage"
settingsPage.BackgroundTransparency = 1
settingsPage.Position = UDim2.new(0, 28, 0, 79)
settingsPage.Size = UDim2.new(1, -56, 1, -120)
settingsPage.Visible = false
settingsPage.Parent = content
pages.Settings = settingsPage

local aboutTitle = label(settingsPage, "About & Information", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 25), Enum.Font.GothamBold, 18, C.text)
local aboutCard = Instance.new("Frame")
aboutCard.BackgroundColor3 = C.card
aboutCard.BorderSizePixel = 0
aboutCard.Position = UDim2.new(0, 0, 0, 43)
aboutCard.Size = UDim2.new(1, 0, 0, 125)
aboutCard.Parent = settingsPage
corner(aboutCard, 11)
stroke(aboutCard, C.line, 0.4, 1)
local aboutIcon = label(aboutCard, "R", UDim2.new(0, 17, 0, 17), UDim2.new(0, 42, 0, 42), Enum.Font.GothamBold, 19, C.purpleHover)
aboutIcon.BackgroundColor3 = C.input
aboutIcon.BackgroundTransparency = 0
aboutIcon.TextXAlignment = Enum.TextXAlignment.Center
aboutIcon.TextYAlignment = Enum.TextYAlignment.Center
corner(aboutIcon, 11)
local aboutName = label(aboutCard, "RBXM Asset Hub", UDim2.new(0, 76, 0, 18), UDim2.new(1, -92, 0, 22), Enum.Font.GothamBold, 14, C.text)
local aboutSub = label(aboutCard, "Native local model importer", UDim2.new(0, 76, 0, 41), UDim2.new(1, -92, 0, 18), Enum.Font.Gotham, 10, C.muted)
local aboutLine = Instance.new("Frame")
aboutLine.BackgroundColor3 = C.line
aboutLine.BackgroundTransparency = 0.45
aboutLine.BorderSizePixel = 0
aboutLine.Position = UDim2.new(0, 17, 0, 76)
aboutLine.Size = UDim2.new(1, -34, 0, 1)
aboutLine.Parent = aboutCard
local aboutHint = label(aboutCard, "Import engine: InsertService:LoadLocalAsset", UDim2.new(0, 17, 0, 88), UDim2.new(1, -34, 0, 20), Enum.Font.Code, 9, C.purpleHover)

local settingsInfo = Instance.new("Frame")
settingsInfo.BackgroundColor3 = C.card
settingsInfo.BorderSizePixel = 0
settingsInfo.Position = UDim2.new(0, 0, 0, 187)
settingsInfo.Size = UDim2.new(1, 0, 0, 120)
settingsInfo.Parent = settingsPage
corner(settingsInfo, 11)
local settingsHeader = label(settingsInfo, "Workflow", UDim2.new(0, 17, 0, 14), UDim2.new(1, -34, 0, 20), Enum.Font.GothamBold, 12, C.text)
local settingsText = label(settingsInfo, "Panel hanya melakukan scan nama/path file. Isi RBXM tidak direkonstruksi oleh script sehingga tidak ada scaling manual.", UDim2.new(0, 17, 0, 42), UDim2.new(1, -34, 0, 45), Enum.Font.Gotham, 10, C.muted)
settingsText.TextWrapped = true

local settingsNote = label(settingsPage, "File rusak akan gagal pada loader native dan tidak dipaksa masuk ke Workspace.", UDim2.new(0, 0, 0, 326), UDim2.new(1, -4, 0, 25), Enum.Font.Gotham, 10, C.yellow)
settingsNote.TextWrapped = true

-- -------------------------------------------------------------------------
-- State and rendering
-- -------------------------------------------------------------------------
local entries = {}
local rowObjects = {}
local scanSubfolders = false
local scanning = false
local importing = false
local filterButtons = filters

local function updateStats()
    totalNumber.Text = tostring(#entries)
    rbxmNumber.Text = tostring(#entries)
end

local function setActivePage(name)
    activePage = name
    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end
    for navName, info in pairs(navButtons) do
        local active = navName == name
        info.button.BackgroundColor3 = active and C.card or C.sidebar
        info.bar.Visible = active
        info.icon.TextColor3 = active and C.purpleHover or C.muted
        info.text.TextColor3 = active and C.text or C.muted
    end
    if name == "Overview" then
        pageTitle.Text = "Dashboard"
        pageSubTitle.Text = "Manage your local Roblox assets seamlessly."
    elseif name == "Assets" then
        pageTitle.Text = "Assets"
        pageSubTitle.Text = "Browse and import local RBXM files."
    elseif name == "Settings" then
        pageTitle.Text = "Settings"
        pageSubTitle.Text = "Information about the importer workflow."
    end
end

local function clearAssetRows()
    for _, item in ipairs(rowObjects) do
        item:Destroy()
    end
    rowObjects = {}
end

local function importAsset(entry)
    local ok, result = pcall(function()
        return InsertService:LoadLocalAsset(entry.path)
    end)
    if not ok then
        entry.failed = true
        entry.error = cleanError(result)
        return false, entry.error
    end
    if result == nil or typeof(result) ~= "Instance" then
        entry.failed = true
        entry.error = "LoadLocalAsset tidak mengembalikan Instance"
        return false, entry.error
    end

    local parentOK, parentError = pcall(function()
        result.Parent = Workspace
    end)
    if not parentOK then
        pcall(function()
            result:Destroy()
        end)
        entry.failed = true
        entry.error = cleanError(parentError)
        return false, entry.error
    end

    entry.imported = true
    entry.failed = false
    entry.root = result
    return true, result
end

local function renderAssetList()
    clearAssetRows()
    local query = string.lower(assetSearch.Text or "")
    local shown = 0

    for _, entry in ipairs(entries) do
        local matchesFilter = currentFilter == "ALL" or currentFilter == entry.type
        local matchesSearch = query == "" or string.find(string.lower(entry.name), query, 1, true) ~= nil
        if matchesFilter and matchesSearch then
            shown = shown + 1
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -4, 0, 64)
            row.LayoutOrder = shown
            row.BackgroundColor3 = C.card2
            row.BorderSizePixel = 0
            row.Parent = assetList
            corner(row, 9)

            local icon = label(row, "RB", UDim2.new(0, 11, 0.5, -19), UDim2.new(0, 38, 0, 38), Enum.Font.GothamBold, 11, C.purpleHover)
            icon.BackgroundColor3 = C.input
            icon.BackgroundTransparency = 0
            icon.TextXAlignment = Enum.TextXAlignment.Center
            icon.TextYAlignment = Enum.TextYAlignment.Center
            corner(icon, 9)

            local name = label(row, entry.name, UDim2.new(0, 61, 0, 10), UDim2.new(1, -180, 0, 18), Enum.Font.GothamBold, 11, C.text)
            name.TextTruncate = Enum.TextTruncate.AtEnd
            local path = label(row, entry.path, UDim2.new(0, 61, 0, 31), UDim2.new(1, -180, 0, 14), Enum.Font.Code, 8, C.muted)
            path.TextTruncate = Enum.TextTruncate.AtEnd

            local statusText
            local statusColor
            if entry.failed then
                statusText = "ERROR"
                statusColor = C.red
            elseif entry.imported then
                statusText = "IMPORTED"
                statusColor = C.green
            else
                statusText = "READY"
                statusColor = C.yellow
            end
            local status = label(row, statusText, UDim2.new(1, -110, 0, 10), UDim2.new(0, 94, 0, 15), Enum.Font.GothamBold, 8, statusColor)
            status.TextXAlignment = Enum.TextXAlignment.Right

            local import = button(row, entry.imported and "AGAIN" or "IMPORT", UDim2.new(1, -101, 0.5, -14), UDim2.new(0, 90, 0, 28), C.purple2, 9)
            import.TextColor3 = entry.failed and C.red or C.text
            addHover(import, C.purple2, C.purple)
            import.MouseButton1Click:Connect(function()
                if importing or scanning then
                    return
                end
                importing = true
                import.Active = false
                setStatus("Importing native: " .. entry.name, C.yellow)
                local ok, result = importAsset(entry)
                if ok then
                    setStatus("Import selesai: " .. entry.name, C.green)
                else
                    setStatus("ERROR ASLI: " .. tostring(result), C.red)
                end
                importing = false
                renderAssetList()
            end)

            local errorLine = label(row, entry.failed and ("  " .. tostring(entry.error)) or "", UDim2.new(0, 61, 0, 48), UDim2.new(1, -175, 0, 11), Enum.Font.Gotham, 8, C.red)
            errorLine.TextTruncate = Enum.TextTruncate.AtEnd
            rowObjects[#rowObjects + 1] = row
        end
    end

    assetEmpty.Visible = shown == 0
    if shown == 0 then
        assetEmpty.Text = #entries == 0 and "Belum ada file.\nTekan Rescan Assets untuk mencari RBXM." or "Tidak ada hasil yang cocok."
    end
    assetList.CanvasSize = UDim2.new(0, 0, 0, assetLayout.AbsoluteContentSize.Y + 14)
    updateStats()
end

for name, item in pairs(navButtons) do
    item.button.MouseButton1Click:Connect(function()
        setActivePage(name)
    end)
end

local function rescan()
    if scanning or importing then
        return
    end
    local folder = normalizePath(folderBox and folderBox.Text or "")
    if folder == "" then
        setStatus("Folder path belum diisi.", C.red)
        return
    end

    scanning = true
    rescanButton.Active = false
    rescanButton.Text = "↻    Scanning..."
    overviewRescan.Active = false
    overviewRescan.Text = "↻    Scanning..."
    setStatus("Scanning local assets...", C.yellow)

    task.spawn(function()
        local ok, result = pcall(collectRbxmFiles, folder, scanSubfolders)
        if not ok then
            setStatus("ERROR ASLI: " .. cleanError(result), C.red)
        else
            entries = {}
            for _, path in ipairs(result) do
                entries[#entries + 1] = {
                    path = path,
                    name = fileName(path),
                    type = "RBXM",
                    imported = false,
                    failed = false,
                }
            end
            renderAssetList()
            if #entries == 0 then
                setStatus("Tidak ada file .rbxm ditemukan.", C.yellow)
            else
                setStatus(string.format("Ditemukan %d file RBXM.", #entries), C.green)
            end
        end
        rescanButton.Active = true
        rescanButton.Text = "↻    Rescan Assets"
        overviewRescan.Active = true
        overviewRescan.Text = "↻   Rescan local assets"
        scanning = false
    end)
end

rescanButton.MouseButton1Click:Connect(function()
    setActivePage("Assets")
    rescan()
end)
overviewRescan.MouseButton1Click:Connect(function()
    setActivePage("Assets")
    rescan()
end)
openAssetsButton.MouseButton1Click:Connect(function()
    setActivePage("Assets")
end)

for name, item in pairs(filters) do
    item.MouseButton1Click:Connect(function()
        currentFilter = name
        for otherName, other in pairs(filters) do
            if otherName == currentFilter then
                other.BackgroundColor3 = C.purple2
                other.TextColor3 = C.text
            else
                other.BackgroundColor3 = C.input
                other.TextColor3 = C.muted
            end
        end
        renderAssetList()
    end)
end
filters.ALL.BackgroundColor3 = C.purple2
filters.ALL.TextColor3 = C.text
assetSearch:GetPropertyChangedSignal("Text"):Connect(renderAssetList)

-- Splash screen seperti asset manager pada screenshot.
local splash = Instance.new("Frame")
splash.Name = "Splash"
splash.BackgroundColor3 = C.black
splash.BorderSizePixel = 0
splash.Size = UDim2.new(1, 0, 1, 0)
splash.ZIndex = 50
splash.Parent = screenGui

local splashCard = Instance.new("Frame")
splashCard.BackgroundColor3 = C.black
splashCard.BorderSizePixel = 0
splashCard.Position = UDim2.new(0.5, 0, 0.52, 0)
splashCard.AnchorPoint = Vector2.new(0.5, 0.5)
splashCard.Size = UDim2.new(0.78, 0, 0, 250)
splashCard.ZIndex = 51
splashCard.Parent = splash
corner(splashCard, 15)
stroke(splashCard, C.line, 0.12, 1)

local splashIcon = label(splashCard, "R", UDim2.new(0.5, -25, 0, 29), UDim2.new(0, 50, 0, 50), Enum.Font.GothamBold, 22, C.purpleHover)
splashIcon.BackgroundColor3 = C.card
splashIcon.BackgroundTransparency = 0
splashIcon.TextXAlignment = Enum.TextXAlignment.Center
splashIcon.TextYAlignment = Enum.TextYAlignment.Center
splashIcon.ZIndex = 52
corner(splashIcon, 13)
local splashTitle = label(splashCard, "RBXM ASSET HUB", UDim2.new(0, 0, 0, 91), UDim2.new(1, 0, 0, 25), Enum.Font.GothamBold, 18, C.text)
splashTitle.TextXAlignment = Enum.TextXAlignment.Center
splashTitle.ZIndex = 52
local splashSub = label(splashCard, "ADVANCED ASSET MANAGEMENT", UDim2.new(0, 0, 0, 119), UDim2.new(1, 0, 0, 16), Enum.Font.Gotham, 9, C.muted)
splashSub.TextXAlignment = Enum.TextXAlignment.Center
splashSub.ZIndex = 52
local splashStatus = label(splashCard, "INITIALIZING NATIVE LOADER...", UDim2.new(0, 0, 0, 151), UDim2.new(1, 0, 0, 16), Enum.Font.GothamBold, 9, C.purpleHover)
splashStatus.TextXAlignment = Enum.TextXAlignment.Center
splashStatus.ZIndex = 52

local progressBack = Instance.new("Frame")
progressBack.BackgroundColor3 = C.input
progressBack.BorderSizePixel = 0
progressBack.Position = UDim2.new(0.1, 0, 0, 181)
progressBack.Size = UDim2.new(0.8, 0, 0, 9)
progressBack.ZIndex = 52
progressBack.Parent = splashCard
corner(progressBack, 5)
local progressFill = Instance.new("Frame")
progressFill.BackgroundColor3 = C.purple
progressFill.BorderSizePixel = 0
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.ZIndex = 53
progressFill.Parent = progressBack
corner(progressFill, 5)
local progressText = label(splashCard, "0%", UDim2.new(0.1, 0, 0, 198), UDim2.new(0.8, 0, 0, 16), Enum.Font.Code, 9, C.muted)
progressText.TextXAlignment = Enum.TextXAlignment.Left
progressText.ZIndex = 52
local splashVersion = label(splashCard, "NATIVE  •  STUDIO LITE", UDim2.new(0.1, 0, 0, 198), UDim2.new(0.8, 0, 0, 16), Enum.Font.Code, 9, C.muted)
splashVersion.TextXAlignment = Enum.TextXAlignment.Right
splashVersion.ZIndex = 52

setActivePage("Overview")
renderAssetList()

-- Startup progress tanpa Output spam.
task.spawn(function()
    local stages = {
        {25, "LOADING UI..."},
        {55, "READYING ASSET SCANNER..."},
        {85, "FINALIZING ENVIRONMENT..."},
        {100, "READY"},
    }
    for _, stage in ipairs(stages) do
        splashStatus.Text = stage[2]
        progressText.Text = tostring(stage[1]) .. "%"
        TweenService:Create(progressFill, TweenInfo.new(0.22), {Size = UDim2.new(stage[1] / 100, 0, 1, 0)}):Play()
        task.wait(0.26)
    end
    task.wait(0.18)
    app.Visible = true
    splash.Visible = false
end)
