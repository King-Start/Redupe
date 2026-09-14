--[[
    RBXM Importer Premium - Studio Lite / executor LocalScript
    Fokus: scan folder, verifikasi RBXM, lalu import file valid.

    Executor yang dibutuhkan:
    - readfile(path)
    - listfiles(folder)
    - opsional: isfolder(path) untuk scan subfolder

    File yang gagal dibaca, header-nya salah, chunk-nya rusak, atau property-nya
    tidak dapat dianalisis akan ditandai REJECTED dan tidak akan di-import.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
if LocalPlayer == nil then
    return
end

local Workspace = game:GetService("Workspace")
local DISABLE_IMPORTED_SCRIPTS = true
local GUI_NAME = "RBXMImporter_Premium"
local ORIGINAL_CLASS_ATTRIBUTE = "RBXMOriginalClass"
local MAX_SCAN_DEPTH = 8
local MAX_FILES = 500

local COLORS = {
    background = Color3.fromRGB(13, 16, 25),
    panel = Color3.fromRGB(20, 24, 36),
    card = Color3.fromRGB(26, 31, 45),
    cardAlt = Color3.fromRGB(31, 37, 54),
    input = Color3.fromRGB(36, 42, 60),
    border = Color3.fromRGB(67, 77, 106),
    text = Color3.fromRGB(244, 247, 255),
    muted = Color3.fromRGB(157, 168, 192),
    accent = Color3.fromRGB(111, 94, 255),
    accentHover = Color3.fromRGB(132, 116, 255),
    cyan = Color3.fromRGB(73, 200, 224),
    green = Color3.fromRGB(90, 218, 151),
    red = Color3.fromRGB(255, 108, 126),
    yellow = Color3.fromRGB(245, 201, 91),
}

local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui ~= nil then
    oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 100
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0.92, 0, 0.84, 0)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = COLORS.panel
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = screenGui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(500, 400)
sizeConstraint.MaxSize = Vector2.new(820, 620)
sizeConstraint.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = COLORS.border
panelStroke.Transparency = 0.25
panelStroke.Thickness = 1
panelStroke.Parent = panel

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.BackgroundTransparency = 1
topBar.Position = UDim2.new(0, 18, 0, 12)
topBar.Size = UDim2.new(1, -36, 0, 38)
topBar.Active = true
topBar.Parent = panel

local brandMark = Instance.new("TextLabel")
brandMark.BackgroundColor3 = COLORS.accent
brandMark.BorderSizePixel = 0
brandMark.Size = UDim2.new(0, 34, 0, 34)
brandMark.Font = Enum.Font.GothamBold
brandMark.TextSize = 14
brandMark.TextColor3 = COLORS.text
brandMark.Text = "R"
brandMark.Parent = topBar
local brandCorner = Instance.new("UICorner")
brandCorner.CornerRadius = UDim.new(0, 10)
brandCorner.Parent = brandMark

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 45, 0, 0)
title.Size = UDim2.new(1, -100, 0, 20)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = COLORS.text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "RBXM VAULT"
title.Parent = topBar

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 46, 0, 19)
subtitle.Size = UDim2.new(1, -105, 0, 15)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 10
subtitle.TextColor3 = COLORS.muted
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "Verified model importer  •  Studio Lite"
subtitle.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.BackgroundColor3 = COLORS.cardAlt
closeButton.BorderSizePixel = 0
closeButton.Position = UDim2.new(1, -34, 0, 2)
closeButton.Size = UDim2.new(0, 32, 0, 30)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.TextColor3 = COLORS.muted
closeButton.Text = "×"
closeButton.AutoButtonColor = false
closeButton.Parent = topBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local statusDot = Instance.new("TextLabel")
statusDot.BackgroundTransparency = 1
statusDot.Position = UDim2.new(1, -84, 0, 8)
statusDot.Size = UDim2.new(0, 20, 0, 20)
statusDot.Font = Enum.Font.GothamBold
statusDot.TextSize = 14
statusDot.TextColor3 = COLORS.green
statusDot.Text = "●"
statusDot.Parent = topBar

local folderBox = Instance.new("TextBox")
folderBox.Name = "FolderPath"
folderBox.Position = UDim2.new(0, 18, 0, 60)
folderBox.Size = UDim2.new(1, -142, 0, 36)
folderBox.BackgroundColor3 = COLORS.input
folderBox.BorderSizePixel = 0
folderBox.ClearTextOnFocus = false
folderBox.Font = Enum.Font.Code
folderBox.TextSize = 12
folderBox.TextColor3 = COLORS.text
folderBox.PlaceholderColor3 = COLORS.muted
folderBox.PlaceholderText = "Folder tujuan, contoh: /storage/emulated/0/Download"
folderBox.Text = "."
folderBox.TextXAlignment = Enum.TextXAlignment.Left
folderBox.Parent = panel
local folderPadding = Instance.new("UIPadding")
folderPadding.PaddingLeft = UDim.new(0, 11)
folderPadding.PaddingRight = UDim.new(0, 11)
folderPadding.Parent = folderBox
local folderCorner = Instance.new("UICorner")
folderCorner.CornerRadius = UDim.new(0, 8)
folderCorner.Parent = folderBox

local scanButton = Instance.new("TextButton")
scanButton.Name = "Scan"
scanButton.Position = UDim2.new(1, -116, 0, 60)
scanButton.Size = UDim2.new(0, 98, 0, 36)
scanButton.BackgroundColor3 = COLORS.accent
scanButton.BorderSizePixel = 0
scanButton.Font = Enum.Font.GothamBold
scanButton.TextSize = 12
scanButton.TextColor3 = COLORS.text
scanButton.Text = "SCAN FOLDER"
scanButton.AutoButtonColor = false
scanButton.Parent = panel
local scanCorner = Instance.new("UICorner")
scanCorner.CornerRadius = UDim.new(0, 8)
scanCorner.Parent = scanButton

local recursiveButton = Instance.new("TextButton")
recursiveButton.Name = "Recursive"
recursiveButton.Position = UDim2.new(0, 18, 0, 102)
recursiveButton.Size = UDim2.new(0, 132, 0, 25)
recursiveButton.BackgroundTransparency = 1
recursiveButton.BorderSizePixel = 0
recursiveButton.Font = Enum.Font.Gotham
recursiveButton.TextSize = 11
recursiveButton.TextColor3 = COLORS.muted
recursiveButton.TextXAlignment = Enum.TextXAlignment.Left
recursiveButton.Text = "↳  Subfolder: OFF"
recursiveButton.AutoButtonColor = false
recursiveButton.Parent = panel

local function makeStatCard(position, titleText, valueColor)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = COLORS.card
    card.BorderSizePixel = 0
    card.Position = position
    card.Size = UDim2.new(0.333, -5, 1, 0)
    card.Parent = panel
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 4)
    label.Size = UDim2.new(1, -20, 0, 12)
    label.Font = Enum.Font.Gotham
    label.TextSize = 9
    label.TextColor3 = COLORS.muted
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = titleText
    label.Parent = card

    local value = Instance.new("TextLabel")
    value.BackgroundTransparency = 1
    value.Position = UDim2.new(0, 10, 0, 16)
    value.Size = UDim2.new(1, -20, 0, 18)
    value.Font = Enum.Font.GothamBold
    value.TextSize = 15
    value.TextColor3 = valueColor
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.Text = "0"
    value.Parent = card
    return card, value
end

local summaryBar = Instance.new("Frame")
summaryBar.BackgroundTransparency = 1
summaryBar.Position = UDim2.new(0, 18, 0, 132)
summaryBar.Size = UDim2.new(1, -36, 0, 40)
summaryBar.Parent = panel

local totalCard, totalValue = makeStatCard(UDim2.new(0, 0, 0, 0), "DISCOVERED", COLORS.cyan)
totalCard.Parent = summaryBar
local validCard, validValue = makeStatCard(UDim2.new(0.333, 2, 0, 0), "VERIFIED", COLORS.green)
validCard.Parent = summaryBar
local rejectedCard, rejectedValue = makeStatCard(UDim2.new(0.666, 4, 0, 0), "REJECTED", COLORS.red)
rejectedCard.Parent = summaryBar

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 18, 0, 182)
content.Size = UDim2.new(1, -36, 1, -262)
content.Parent = panel

local fileCard = Instance.new("Frame")
fileCard.Name = "FileCard"
fileCard.BackgroundColor3 = COLORS.card
fileCard.BorderSizePixel = 0
fileCard.Size = UDim2.new(0.61, -5, 1, 0)
fileCard.Parent = content
local fileCardCorner = Instance.new("UICorner")
fileCardCorner.CornerRadius = UDim.new(0, 10)
fileCardCorner.Parent = fileCard

local fileHeader = Instance.new("TextLabel")
fileHeader.BackgroundTransparency = 1
fileHeader.Position = UDim2.new(0, 12, 0, 8)
fileHeader.Size = UDim2.new(0.38, 0, 0, 22)
fileHeader.Font = Enum.Font.GothamBold
fileHeader.TextSize = 11
fileHeader.TextColor3 = COLORS.text
fileHeader.TextXAlignment = Enum.TextXAlignment.Left
fileHeader.Text = "RBXM FILES"
fileHeader.Parent = fileCard

local searchBox = Instance.new("TextBox")
searchBox.Name = "Search"
searchBox.Position = UDim2.new(0.40, 0, 0, 7)
searchBox.Size = UDim2.new(0.58, -10, 0, 24)
searchBox.BackgroundColor3 = COLORS.input
searchBox.BorderSizePixel = 0
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 10
searchBox.TextColor3 = COLORS.text
searchBox.PlaceholderColor3 = COLORS.muted
searchBox.PlaceholderText = "Search..."
searchBox.Text = ""
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = fileCard
local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 8)
searchPadding.PaddingRight = UDim.new(0, 8)
searchPadding.Parent = searchBox
local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 6)
searchCorner.Parent = searchBox

local fileList = Instance.new("ScrollingFrame")
fileList.Name = "FileList"
fileList.Position = UDim2.new(0, 8, 0, 37)
fileList.Size = UDim2.new(1, -16, 1, -45)
fileList.BackgroundTransparency = 1
fileList.BorderSizePixel = 0
fileList.ScrollBarThickness = 4
fileList.ScrollBarImageColor3 = COLORS.border
fileList.CanvasSize = UDim2.new(0, 0, 0, 0)
fileList.AutomaticCanvasSize = Enum.AutomaticSize.None
fileList.Parent = fileCard

local fileLayout = Instance.new("UIListLayout")
fileLayout.Padding = UDim.new(0, 5)
fileLayout.SortOrder = Enum.SortOrder.LayoutOrder
fileLayout.Parent = fileList

local emptyLabel = Instance.new("TextLabel")
emptyLabel.BackgroundTransparency = 1
emptyLabel.Position = UDim2.new(0, 20, 0.5, -20)
emptyLabel.Size = UDim2.new(1, -40, 0, 40)
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.TextSize = 11
emptyLabel.TextColor3 = COLORS.muted
emptyLabel.TextWrapped = true
emptyLabel.Text = "Belum ada hasil scan.\nPilih folder lalu tekan SCAN FOLDER."
emptyLabel.Parent = fileCard

local detailCard = Instance.new("Frame")
detailCard.Name = "Details"
detailCard.BackgroundColor3 = COLORS.card
detailCard.BorderSizePixel = 0
detailCard.Position = UDim2.new(0.61, 5, 0, 0)
detailCard.Size = UDim2.new(0.39, -5, 1, 0)
detailCard.Parent = content
local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0, 10)
detailCorner.Parent = detailCard

local detailHeader = Instance.new("TextLabel")
detailHeader.BackgroundTransparency = 1
detailHeader.Position = UDim2.new(0, 14, 0, 12)
detailHeader.Size = UDim2.new(1, -28, 0, 18)
detailHeader.Font = Enum.Font.GothamBold
detailHeader.TextSize = 11
detailHeader.TextColor3 = COLORS.text
detailHeader.TextXAlignment = Enum.TextXAlignment.Left
detailHeader.Text = "SELECTED FILE"
detailHeader.Parent = detailCard

local detailName = Instance.new("TextLabel")
detailName.BackgroundTransparency = 1
detailName.Position = UDim2.new(0, 14, 0, 39)
detailName.Size = UDim2.new(1, -28, 0, 42)
detailName.Font = Enum.Font.GothamBold
detailName.TextSize = 13
detailName.TextColor3 = COLORS.text
detailName.TextWrapped = true
detailName.TextTruncate = Enum.TextTruncate.AtEnd
detailName.TextXAlignment = Enum.TextXAlignment.Left
detailName.TextYAlignment = Enum.TextYAlignment.Top
detailName.Text = "Belum ada file dipilih"
detailName.Parent = detailCard

local detailBadge = Instance.new("TextLabel")
detailBadge.BackgroundColor3 = COLORS.input
detailBadge.BorderSizePixel = 0
detailBadge.Position = UDim2.new(0, 14, 0, 88)
detailBadge.Size = UDim2.new(0, 92, 0, 23)
detailBadge.Font = Enum.Font.GothamBold
detailBadge.TextSize = 10
detailBadge.TextColor3 = COLORS.muted
detailBadge.Text = "WAITING"
detailBadge.Parent = detailCard
local detailBadgeCorner = Instance.new("UICorner")
detailBadgeCorner.CornerRadius = UDim.new(0, 6)
detailBadgeCorner.Parent = detailBadge

local detailInfo = Instance.new("TextLabel")
detailInfo.BackgroundTransparency = 1
detailInfo.Position = UDim2.new(0, 14, 0, 124)
detailInfo.Size = UDim2.new(1, -28, 0, 86)
detailInfo.Font = Enum.Font.Code
detailInfo.TextSize = 10
detailInfo.TextColor3 = COLORS.muted
detailInfo.TextWrapped = true
detailInfo.TextXAlignment = Enum.TextXAlignment.Left
detailInfo.TextYAlignment = Enum.TextYAlignment.Top
detailInfo.Text = "Pilih file untuk melihat detail."
detailInfo.Parent = detailCard

local detailError = Instance.new("TextLabel")
detailError.BackgroundTransparency = 1
detailError.Position = UDim2.new(0, 14, 0, 216)
detailError.Size = UDim2.new(1, -28, 0, 60)
detailError.Font = Enum.Font.Gotham
detailError.TextSize = 10
detailError.TextColor3 = COLORS.red
detailError.TextWrapped = true
detailError.TextXAlignment = Enum.TextXAlignment.Left
detailError.TextYAlignment = Enum.TextYAlignment.Top
detailError.Text = ""
detailError.Parent = detailCard

local importSelectedButton = Instance.new("TextButton")
importSelectedButton.Name = "ImportSelected"
importSelectedButton.Position = UDim2.new(0, 18, 1, -68)
importSelectedButton.Size = UDim2.new(0, 168, 0, 34)
importSelectedButton.BackgroundColor3 = COLORS.accent
importSelectedButton.BorderSizePixel = 0
importSelectedButton.Font = Enum.Font.GothamBold
importSelectedButton.TextSize = 11
importSelectedButton.TextColor3 = COLORS.text
importSelectedButton.Text = "IMPORT SELECTED"
importSelectedButton.AutoButtonColor = false
importSelectedButton.Parent = panel
local importSelectedCorner = Instance.new("UICorner")
importSelectedCorner.CornerRadius = UDim.new(0, 8)
importSelectedCorner.Parent = importSelectedButton

local importAllButton = Instance.new("TextButton")
importAllButton.Name = "ImportAll"
importAllButton.Position = UDim2.new(0, 194, 1, -68)
importAllButton.Size = UDim2.new(0, 168, 0, 34)
importAllButton.BackgroundColor3 = COLORS.cardAlt
importAllButton.BorderSizePixel = 0
importAllButton.Font = Enum.Font.GothamBold
importAllButton.TextSize = 11
importAllButton.TextColor3 = COLORS.text
importAllButton.Text = "IMPORT ALL VALID"
importAllButton.AutoButtonColor = false
importAllButton.Parent = panel
local importAllCorner = Instance.new("UICorner")
importAllCorner.CornerRadius = UDim.new(0, 8)
importAllCorner.Parent = importAllButton

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 18, 1, -31)
statusLabel.Size = UDim2.new(1, -36, 0, 18)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextColor3 = COLORS.muted
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
statusLabel.Text = "Ready. Masukkan folder lalu scan."
statusLabel.Parent = panel

local function addHover(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        if button.Active then
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = hoverColor}):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        if button.Active then
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = normalColor}):Play()
        end
    end)
end

addHover(scanButton, COLORS.accent, COLORS.accentHover)
addHover(importSelectedButton, COLORS.accent, COLORS.accentHover)
addHover(importAllButton, COLORS.cardAlt, COLORS.input)
addHover(closeButton, COLORS.cardAlt, Color3.fromRGB(72, 47, 65))

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local function setStatus(text, color)
    statusLabel.Text = tostring(text)
    statusLabel.TextColor3 = color or COLORS.muted
    statusDot.TextColor3 = color or COLORS.green
end

-- Drag panel dari top bar.
do
    local dragging = false
    local dragStart
    local startPosition

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

local recursive = false
recursiveButton.MouseButton1Click:Connect(function()
    recursive = not recursive
    recursiveButton.Text = recursive and "↳  Subfolder: ON" or "↳  Subfolder: OFF"
    recursiveButton.TextColor3 = recursive and COLORS.cyan or COLORS.muted
end)

local fileEntries = {}
local selectedEntry = nil
local scanning = false
local importing = false
local rowObjects = {}

local function updateSummary()
    local valid = 0
    local rejected = 0
    for _, entry in ipairs(fileEntries) do
        if entry.valid then
            valid = valid + 1
        else
            rejected = rejected + 1
        end
    end
    totalValue.Text = tostring(#fileEntries)
    validValue.Text = tostring(valid)
    rejectedValue.Text = tostring(rejected)
end

local function clearRows()
    for _, object in ipairs(rowObjects) do
        if object ~= nil then
            object:Destroy()
        end
    end
    rowObjects = {}
end

local function updateDetails()
    if selectedEntry == nil then
        detailName.Text = "Belum ada file dipilih"
        detailBadge.Text = "WAITING"
        detailBadge.TextColor3 = COLORS.muted
        detailBadge.BackgroundColor3 = COLORS.input
        detailInfo.Text = "Pilih file untuk melihat detail."
        detailError.Text = ""
        return
    end

    detailName.Text = selectedEntry.name
    if selectedEntry.valid then
        detailBadge.Text = "✓  VERIFIED"
        detailBadge.TextColor3 = COLORS.green
        detailBadge.BackgroundColor3 = Color3.fromRGB(28, 74, 62)
    else
        detailBadge.Text = "×  REJECTED"
        detailBadge.TextColor3 = COLORS.red
        detailBadge.BackgroundColor3 = Color3.fromRGB(80, 37, 53)
    end

    detailInfo.Text = string.format(
        "Path\n%s\n\nSize     %s\nInstances %s\nClasses   %s\nRoots     %s",
        selectedEntry.path,
        tostring(selectedEntry.sizeText or "-"),
        tostring(selectedEntry.instanceCount or "-"),
        tostring(selectedEntry.classCount or "-"),
        tostring(selectedEntry.rootCount or "-")
    )
    detailError.Text = selectedEntry.valid and "File lolos preflight scan. Siap di-import." or (selectedEntry.error or "File ditolak.")
    detailError.TextColor3 = selectedEntry.valid and COLORS.green or COLORS.red
end

local function formatBytes(size)
    if size == nil then
        return "-"
    elseif size >= 1048576 then
        return string.format("%.2f MB", size / 1048576)
    elseif size >= 1024 then
        return string.format("%.1f KB", size / 1024)
    end
    return tostring(size) .. " B"
end

local function renderRows()
    clearRows()
    local query = string.lower(searchBox.Text or "")
    local shown = 0

    for _, entry in ipairs(fileEntries) do
        local lowerName = string.lower(entry.name)
        if query == "" or string.find(lowerName, query, 1, true) ~= nil then
            shown = shown + 1
            local row = Instance.new("Frame")
            row.Name = "FileRow"
            row.LayoutOrder = shown
            row.Size = UDim2.new(1, -6, 0, 52)
            row.BackgroundColor3 = (entry == selectedEntry) and Color3.fromRGB(48, 47, 83) or COLORS.cardAlt
            row.BorderSizePixel = 0
            row.Parent = fileList
            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 8)
            rowCorner.Parent = row

            local status = Instance.new("TextLabel")
            status.BackgroundTransparency = 1
            status.Position = UDim2.new(0, 9, 0, 7)
            status.Size = UDim2.new(0, 18, 0, 20)
            status.Font = Enum.Font.GothamBold
            status.TextSize = 16
            status.TextColor3 = entry.valid and COLORS.green or COLORS.red
            status.Text = entry.valid and "✓" or "×"
            status.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.BackgroundTransparency = 1
            nameLabel.Position = UDim2.new(0, 33, 0, 6)
            nameLabel.Size = UDim2.new(1, -122, 0, 20)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 11
            nameLabel.TextColor3 = COLORS.text
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Text = entry.name
            nameLabel.Parent = row

            local metaLabel = Instance.new("TextLabel")
            metaLabel.BackgroundTransparency = 1
            metaLabel.Position = UDim2.new(0, 33, 0, 27)
            metaLabel.Size = UDim2.new(1, -42, 0, 15)
            metaLabel.Font = Enum.Font.Code
            metaLabel.TextSize = 9
            metaLabel.TextColor3 = COLORS.muted
            metaLabel.TextXAlignment = Enum.TextXAlignment.Left
            metaLabel.TextTruncate = Enum.TextTruncate.AtEnd
            metaLabel.Text = entry.valid
                and string.format("%s  •  %s instances", entry.sizeText or "-", tostring(entry.instanceCount or "?"))
                or (entry.error or "ditolak")
            metaLabel.Parent = row

            local selectButton = Instance.new("TextButton")
            selectButton.BackgroundTransparency = 1
            selectButton.BorderSizePixel = 0
            selectButton.Size = UDim2.new(1, 0, 1, 0)
            selectButton.Text = ""
            selectButton.AutoButtonColor = false
            selectButton.Parent = row
            selectButton.MouseButton1Click:Connect(function()
                selectedEntry = entry
                updateDetails()
                renderRows()
            end)
            rowObjects[#rowObjects + 1] = row
        end
    end

    emptyLabel.Visible = shown == 0
    if shown == 0 and #fileEntries > 0 then
        emptyLabel.Text = "Tidak ada file yang cocok dengan pencarian."
    elseif #fileEntries == 0 then
        emptyLabel.Text = "Belum ada hasil scan.\nPilih folder lalu tekan SCAN FOLDER."
    end
    fileList.CanvasSize = UDim2.new(0, 0, 0, fileLayout.AbsoluteContentSize.Y + 8)
    updateSummary()
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    renderRows()
end)


local function byteAt(data, position)
    local value = string.byte(data, position)
    if value == nil then
        fail("Data RBXM berakhir terlalu cepat pada byte " .. tostring(position))
    end
    return value
end

local function bytesToString(bytes)
    local pieces = {}
    local pieceIndex = 1
    local length = #bytes
    local first = 1

    while first <= length do
        local last = math.min(first + 2047, length)
        local chars = {}
        local n = 1
        for i = first, last do
            chars[n] = string.char(bytes[i])
            n = n + 1
        end
        pieces[pieceIndex] = table.concat(chars)
        pieceIndex = pieceIndex + 1
        first = last + 1
    end

    return table.concat(pieces)
end

local function lz4Decompress(compressed, expectedLength)
    local inputPosition = 1
    local inputLength = #compressed
    local output = {}

    local function readInputByte()
        if inputPosition > inputLength then
            fail("Chunk LZ4 terpotong")
        end
        local value = string.byte(compressed, inputPosition)
        inputPosition = inputPosition + 1
        return value
    end

    local function readInputUInt16LE()
        local a = readInputByte()
        local b = readInputByte()
        return a + b * 256
    end

    while #output < expectedLength do
        local token = readInputByte()
        local literalLength = math.floor(token / 16)

        if literalLength == 15 then
            repeat
                local extra = readInputByte()
                literalLength = literalLength + extra
            until extra ~= 255
        end

        for _ = 1, literalLength do
            output[#output + 1] = readInputByte()
        end

        if #output >= expectedLength then
            break
        end

        local offset = readInputUInt16LE()
        if offset <= 0 or offset > #output then
            fail("Offset LZ4 tidak valid: " .. tostring(offset))
        end

        local matchLength = token % 16
        if matchLength == 15 then
            repeat
                local extra = readInputByte()
                matchLength = matchLength + extra
            until extra ~= 255
        end
        matchLength = matchLength + 4

        local copyFrom = #output - offset + 1
        for i = 0, matchLength - 1 do
            output[#output + 1] = output[copyFrom + i]
        end
    end

    if #output ~= expectedLength then
        fail("Ukuran hasil LZ4 tidak sesuai")
    end

    return bytesToString(output)
end

local function externalDecompress(compressed, expectedLength)
    local environments = {_G}
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            environments[#environments + 1] = env
        end
    end

    local names = {"zstd_decompress", "lz4_decompress", "decompress"}
    for _, environment in ipairs(environments) do
        for _, name in ipairs(names) do
            local decoder = environment[name]
            if type(decoder) == "function" then
                local ok, result = pcall(decoder, compressed)
                if ok and type(result) == "string" and #result == expectedLength then
                    return result
                end
            end
        end
    end

    return nil
end

local Reader = {}
Reader.__index = Reader

function Reader.new(data)
    return setmetatable({
        data = data,
        position = 1,
        length = #data,
    }, Reader)
end

function Reader:remaining()
    return self.length - self.position + 1
end

function Reader:take(count)
    if count < 0 or self.position + count - 1 > self.length then
        fail("Data RBXM berakhir terlalu cepat")
    end

    local value = string.sub(self.data, self.position, self.position + count - 1)
    self.position = self.position + count
    return value
end

function Reader:skip(count)
    self:take(count)
end

function Reader:u8()
    local value = byteAt(self.data, self.position)
    self.position = self.position + 1
    return value
end

function Reader:u16le()
    local a = self:u8()
    local b = self:u8()
    return a + b * 256
end

function Reader:u32le()
    local a = self:u8()
    local b = self:u8()
    local c = self:u8()
    local d = self:u8()
    return a + b * 256 + c * 65536 + d * 16777216
end

function Reader:i16le()
    local value = self:u16le()
    if value >= 32768 then
        return value - 65536
    end
    return value
end

function Reader:u32be()
    local a = self:u8()
    local b = self:u8()
    local c = self:u8()
    local d = self:u8()
    return a * 16777216 + b * 65536 + c * 256 + d
end

function Reader:string()
    local length = self:u32le()
    return self:take(length)
end

function Reader:ieee32le()
    local raw = self:u32le()
    local sign = math.floor(raw / 2147483648)
    local exponent = math.floor(raw / 8388608) % 256
    local mantissa = raw % 8388608

    if exponent == 255 then
        if mantissa == 0 then
            return sign == 1 and -math.huge or math.huge
        end
        return 0 / 0
    elseif exponent == 0 then
        if mantissa == 0 then
            return sign == 1 and -0 or 0
        end
        local value = (mantissa / 8388608) * (2 ^ -126)
        return sign == 1 and -value or value
    end

    local value = (1 + mantissa / 8388608) * (2 ^ (exponent - 127))
    return sign == 1 and -value or value
end

function Reader:ieee64le()
    local low = self:u32le()
    local high = self:u32le()
    local sign = math.floor(high / 2147483648)
    local exponent = math.floor(high / 1048576) % 2048
    local mantissaHigh = high % 1048576
    local mantissa = mantissaHigh * 4294967296 + low

    if exponent == 2047 then
        if mantissa == 0 then
            return sign == 1 and -math.huge or math.huge
        end
        return 0 / 0
    elseif exponent == 0 then
        if mantissa == 0 then
            return sign == 1 and -0 or 0
        end
        local value = (mantissa / 4503599627370496) * (2 ^ -1022)
        return sign == 1 and -value or value
    end

    local value = (1 + mantissa / 4503599627370496) * (2 ^ (exponent - 1023))
    return sign == 1 and -value or value
end

function Reader:interleavedBE(count, width)
    if count == 0 then
        return {}
    end

    local start = self.position
    self:skip(count * width)
    local values = {}

    for i = 1, count do
        local value = 0
        for column = 0, width - 1 do
            value = value * 256 + byteAt(self.data, start + (i - 1) + column * count)
        end
        values[i] = value
    end

    return values
end

function Reader:interleavedRaw(count, width)
    local start = self.position
    self:skip(count * width)
    local values = {}

    for i = 1, count do
        local one = {}
        for column = 0, width - 1 do
            one[column + 1] = byteAt(self.data, start + (i - 1) + column * count)
        end
        values[i] = one
    end

    return values
end

function Reader:rbxFloatFromInterleavedRaw(raw)
    -- RBX float disimpan sebagai IEEE float yang bit-nya diputar satu posisi.
    local rotated = math.floor(raw / 2) + (raw % 2) * 2147483648
    local sign = math.floor(rotated / 2147483648)
    local exponent = math.floor(rotated / 8388608) % 256
    local mantissa = rotated % 8388608

    if exponent == 255 then
        if mantissa == 0 then
            return sign == 1 and -math.huge or math.huge
        end
        return 0 / 0
    elseif exponent == 0 then
        if mantissa == 0 then
            return sign == 1 and -0 or 0
        end
        local value = (mantissa / 8388608) * (2 ^ -126)
        return sign == 1 and -value or value
    end

    local value = (1 + mantissa / 8388608) * (2 ^ (exponent - 127))
    return sign == 1 and -value or value
end

function Reader:rbxFloats(count)
    local encoded = self:interleavedBE(count, 4)
    local values = {}
    for i, raw in ipairs(encoded) do
        values[i] = self:rbxFloatFromInterleavedRaw(raw)
    end
    return values
end

local function untransformInteger(value)
    if value % 2 == 0 then
        return value / 2
    end
    return -(value + 1) / 2
end

function Reader:referents(count)
    local encoded = self:interleavedBE(count, 4)
    local values = {}
    local last = 0

    for i, value in ipairs(encoded) do
        last = last + untransformInteger(value)
        values[i] = last
    end

    return values
end

local ORIENTATION_MATRICES = {
    [0x02] = {1, 0, 0, 0, 1, 0, 0, 0, 1},
    [0x03] = {1, 0, 0, 0, 0, -1, 0, 1, 0},
    [0x05] = {1, 0, 0, 0, -1, 0, 0, 0, -1},
    [0x06] = {1, 0, 0, 0, 0, 1, 0, -1, 0},
    [0x07] = {0, 1, 0, 1, 0, 0, 0, 0, -1},
    [0x09] = {0, 0, 1, 1, 0, 0, 0, 1, 0},
    [0x0a] = {0, -1, 0, 1, 0, 0, 0, 0, 1},
    [0x0c] = {0, 0, -1, 1, 0, 0, 0, -1, 0},
    [0x0d] = {0, 1, 0, 0, 0, 1, 1, 0, 0},
    [0x0e] = {0, 0, -1, 0, 1, 0, 1, 0, 0},
    [0x10] = {0, -1, 0, 0, 0, -1, 1, 0, 0},
    [0x11] = {0, 0, 1, 0, -1, 0, 1, 0, 0},
    [0x14] = {-1, 0, 0, 0, 1, 0, 0, 0, -1},
    [0x15] = {-1, 0, 0, 0, 0, 1, 0, 1, 0},
    [0x17] = {-1, 0, 0, 0, -1, 0, 0, 0, 1},
    [0x18] = {-1, 0, 0, 0, 0, -1, 0, -1, 0},
    [0x19] = {0, 1, 0, -1, 0, 0, 0, 0, 1},
    [0x1b] = {0, 0, -1, -1, 0, 0, 0, 1, 0},
    [0x1c] = {0, -1, 0, -1, 0, 0, 0, 0, -1},
    [0x1e] = {0, 0, 1, -1, 0, 0, 0, -1, 0},
    [0x1f] = {0, 1, 0, 0, 0, -1, -1, 0, 0},
    [0x20] = {0, 0, 1, 0, 1, 0, -1, 0, 0},
    [0x22] = {0, -1, 0, 0, 0, 1, -1, 0, 0},
    [0x23] = {0, 0, -1, 0, -1, 0, -1, 0, 0},
}

local function readCFrames(reader, count)
    local rotations = {}

    for i = 1, count do
        local id = reader:u8()
        if id == 0 then
            local matrix = {}
            for j = 1, 9 do
                matrix[j] = reader:ieee32le()
            end
            rotations[i] = matrix
        else
            local matrix = ORIENTATION_MATRICES[id]
            if matrix == nil then
                fail("Orientation CFrame tidak dikenal: " .. tostring(id))
            end
            rotations[i] = matrix
        end
    end

    local xs = reader:rbxFloats(count)
    local ys = reader:rbxFloats(count)
    local zs = reader:rbxFloats(count)
    local values = {}

    for i = 1, count do
        local matrix = rotations[i]
        local args = {
            xs[i], ys[i], zs[i],
            matrix[1], matrix[2], matrix[3],
            matrix[4], matrix[5], matrix[6],
            matrix[7], matrix[8], matrix[9],
        }
        values[i] = CFrame.new(table.unpack(args))
    end

    return values
end

local function readFaces(reader, count)
    local values = {}
    for i = 1, count do
        local mask = reader:u8()
        values[i] = Faces.new(
            mask % 2 == 1,
            math.floor(mask / 2) % 2 == 1,
            math.floor(mask / 4) % 2 == 1,
            math.floor(mask / 8) % 2 == 1,
            math.floor(mask / 16) % 2 == 1,
            math.floor(mask / 32) % 2 == 1
        )
    end
    return values
end

local function readAxes(reader, count)
    local values = {}
    for i = 1, count do
        local mask = reader:u8()
        values[i] = Axes.new(
            mask % 2 == 1,
            math.floor(mask / 2) % 2 == 1,
            math.floor(mask / 4) % 2 == 1
        )
    end
    return values
end

local function decodePropertyValues(reader, typeId, count, file)
    local values = {}

    if typeId == 0x01 then
        for i = 1, count do
            values[i] = reader:string()
        end

    elseif typeId == 0x02 then
        for i = 1, count do
            values[i] = reader:u8() == 1
        end

    elseif typeId == 0x03 then
        local encoded = reader:interleavedBE(count, 4)
        for i, value in ipairs(encoded) do
            values[i] = untransformInteger(value)
        end

    elseif typeId == 0x04 then
        values = reader:rbxFloats(count)

    elseif typeId == 0x05 then
        for i = 1, count do
            values[i] = reader:ieee64le()
        end

    elseif typeId == 0x06 then
        local scales = reader:rbxFloats(count)
        local offsets = reader:interleavedBE(count, 4)
        for i = 1, count do
            values[i] = UDim.new(scales[i], untransformInteger(offsets[i]))
        end

    elseif typeId == 0x07 then
        local xScales = reader:rbxFloats(count)
        local yScales = reader:rbxFloats(count)
        local xOffsets = reader:interleavedBE(count, 4)
        local yOffsets = reader:interleavedBE(count, 4)
        for i = 1, count do
            values[i] = UDim2.new(
                xScales[i], untransformInteger(xOffsets[i]),
                yScales[i], untransformInteger(yOffsets[i])
            )
        end

    elseif typeId == 0x08 then
        for i = 1, count do
            values[i] = Ray.new(
                Vector3.new(reader:ieee32le(), reader:ieee32le(), reader:ieee32le()),
                Vector3.new(reader:ieee32le(), reader:ieee32le(), reader:ieee32le())
            )
        end

    elseif typeId == 0x09 then
        values = readFaces(reader, count)

    elseif typeId == 0x0a then
        values = readAxes(reader, count)

    elseif typeId == 0x0b then
        local encoded = reader:interleavedBE(count, 4)
        for i, value in ipairs(encoded) do
            values[i] = BrickColor.new(value)
        end

    elseif typeId == 0x0c then
        local rs = reader:rbxFloats(count)
        local gs = reader:rbxFloats(count)
        local bs = reader:rbxFloats(count)
        for i = 1, count do
            values[i] = Color3.new(rs[i], gs[i], bs[i])
        end

    elseif typeId == 0x0d then
        local xs = reader:rbxFloats(count)
        local ys = reader:rbxFloats(count)
        for i = 1, count do
            values[i] = Vector2.new(xs[i], ys[i])
        end

    elseif typeId == 0x0e then
        local xs = reader:rbxFloats(count)
        local ys = reader:rbxFloats(count)
        local zs = reader:rbxFloats(count)
        for i = 1, count do
            values[i] = Vector3.new(xs[i], ys[i], zs[i])
        end

    elseif typeId == 0x10 then
        values = readCFrames(reader, count)

    elseif typeId == 0x12 then
        values = reader:interleavedBE(count, 4)

    elseif typeId == 0x13 then
        local refs = reader:referents(count)
        for i, ref in ipairs(refs) do
            values[i] = {__rbxmReference = true, ref = ref}
        end

    elseif typeId == 0x14 then
        for i = 1, count do
            values[i] = Vector3int16.new(reader:i16le(), reader:i16le(), reader:i16le())
        end

    elseif typeId == 0x15 then
        for i = 1, count do
            local keypointCount = reader:u32le()
            local keypoints = {}
            for j = 1, keypointCount do
                keypoints[j] = NumberSequenceKeypoint.new(
                    reader:ieee32le(),
                    reader:ieee32le(),
                    reader:ieee32le()
                )
            end
            values[i] = NumberSequence.new(keypoints)
        end

    elseif typeId == 0x16 then
        for i = 1, count do
            local keypointCount = reader:u32le()
            local keypoints = {}
            for j = 1, keypointCount do
                local time = reader:ieee32le()
                local color = Color3.new(reader:ieee32le(), reader:ieee32le(), reader:ieee32le())
                reader:ieee32le() -- envelope tersimpan tetapi tidak dipakai ColorSequence
                keypoints[j] = ColorSequenceKeypoint.new(time, color)
            end
            values[i] = ColorSequence.new(keypoints)
        end

    elseif typeId == 0x17 then
        for i = 1, count do
            values[i] = NumberRange.new(reader:ieee32le(), reader:ieee32le())
        end

    elseif typeId == 0x18 then
        local minXs = reader:rbxFloats(count)
        local minYs = reader:rbxFloats(count)
        local maxXs = reader:rbxFloats(count)
        local maxYs = reader:rbxFloats(count)
        for i = 1, count do
            values[i] = Rect.new(minXs[i], minYs[i], maxXs[i], maxYs[i])
        end

    elseif typeId == 0x19 then
        for i = 1, count do
            local flags = reader:u8()
            if flags % 2 == 1 then
                local density = reader:ieee32le()
                local friction = reader:ieee32le()
                local elasticity = reader:ieee32le()
                local frictionWeight = reader:ieee32le()
                local elasticityWeight = reader:ieee32le()
                local acousticAbsorption = 1
                if math.floor(flags / 2) % 2 == 1 then
                    acousticAbsorption = reader:ieee32le()
                end
                local ok, physical = pcall(
                    PhysicalProperties.new,
                    density,
                    friction,
                    elasticity,
                    frictionWeight,
                    elasticityWeight,
                    acousticAbsorption
                )
                if not ok then
                    physical = PhysicalProperties.new(
                        density,
                        friction,
                        elasticity,
                        frictionWeight,
                        elasticityWeight
                    )
                end
                values[i] = physical
            else
                if math.floor(flags / 2) % 2 == 1 then
                    reader:ieee32le()
                end
                values[i] = nil
            end
        end

    elseif typeId == 0x1a then
        local colors = reader:interleavedBE(count, 3)
        for i, value in ipairs(colors) do
            local r = math.floor(value / 65536) % 256
            local g = math.floor(value / 256) % 256
            local b = value % 256
            values[i] = Color3.fromRGB(r, g, b)
        end

    elseif typeId == 0x1b then
        -- Int64 tidak selalu aman direpresentasikan sebagai number Lua.
        -- Simpan nilai kecil; nilai besar diberi marker agar tidak rusak.
        local rawValues = reader:interleavedRaw(count, 8)
        for i, raw in ipairs(rawValues) do
            local value = 0
            for _, byte in ipairs(raw) do
                value = value * 256 + byte
            end
            if value <= 9007199254740991 then
                values[i] = untransformInteger(value)
            else
                values[i] = {__rbxmUnsupported = true}
            end
        end

    elseif typeId == 0x1c then
        local indices = reader:interleavedBE(count, 4)
        for i, index in ipairs(indices) do
            values[i] = file.sharedStrings[index]
            if values[i] == nil then
                values[i] = ""
            end
        end

    elseif typeId == 0x1d then
        for i = 1, count do
            values[i] = reader:string()
        end

    elseif typeId == 0x1e then
        local nestedType = reader:u8()
        if nestedType ~= 0x10 then
            fail("OptionalCoordinateFrame berisi type CFrame yang tidak dikenal")
        end
        local frames = readCFrames(reader, count)
        local boolType = reader:u8()
        if boolType ~= 0x02 then
            fail("OptionalCoordinateFrame tidak memiliki array bool")
        end
        for i = 1, count do
            local present = reader:u8() == 1
            values[i] = present and frames[i] or nil
        end

    elseif typeId == 0x1f then
        local rawValues = reader:interleavedRaw(count, 16)
        for i = 1, count do
            values[i] = {__rbxmUnsupported = true, raw = rawValues[i]}
        end

    elseif typeId == 0x20 then
        for i = 1, count do
            values[i] = {
                __rbxmFont = true,
                family = reader:string(),
                weight = reader:u16le(),
                style = reader:u8(),
                cachedFaceId = reader:string(),
            }
        end

    elseif typeId == 0x21 then
        -- SecurityCapabilities/Capabilities: 64-bit bitfield. Tidak writable
        -- melalui assignment runtime biasa, tetapi byte-nya tetap dikonsumsi.
        reader:skip(count * 8)
        for i = 1, count do
            values[i] = {__rbxmUnsupported = true}
        end

    elseif typeId == 0x22 then
        -- Content modern: satu SourceType untuk tiap nilai property, lalu daftar
        -- URI dan referent object. URI adalah bentuk yang paling umum untuk mesh.
        local sourceTypes = reader:interleavedBE(count, 4)
        local uriCount = reader:u32le()
        local uris = {}
        for i = 1, uriCount do
            uris[i] = reader:string()
        end
        local objectCount = reader:u32le()
        local objectRefs = reader:referents(objectCount)
        local externalCount = reader:u32le()
        local externalRefs = reader:referents(externalCount)
        local uriIndex = 1
        local objectIndex = 1
        local externalIndex = 1

        for i = 1, count do
            local sourceType = sourceTypes[i]
            if sourceType == 1 then
                values[i] = {__rbxmContent = true, uri = uris[uriIndex] or ""}
                uriIndex = uriIndex + 1
            elseif sourceType == 2 then
                values[i] = {
                    __rbxmReference = true,
                    ref = objectRefs[objectIndex],
                }
                objectIndex = objectIndex + 1
            else
                values[i] = nil
            end
        end
        -- externalRefs sengaja dibaca untuk menjaga pointer; belum dapat
        -- direferensikan ke instance luar file.
        externalIndex = externalIndex + #externalRefs

    else
        fail(string.format("Tipe property RBXM belum didukung: 0x%02X", typeId))
    end

    return values
end

local function decodeRbxm(data)
    local reader = Reader.new(data)
    if reader:take(8) ~= "<roblox!" then
        fail("File bukan RBXM binary: magic header tidak cocok")
    end
    if reader:take(6) ~= string.char(0x89, 0xff, 0x0d, 0x0a, 0x1a, 0x0a) then
        fail("Header RBXM tidak valid")
    end

    local version = reader:u16le()
    if version ~= 0 then
        fail("Versi RBXM tidak didukung: " .. tostring(version))
    end

    local classCount = reader:u32le()
    local instanceCount = reader:u32le()
    reader:skip(8)

    local file = {
        classCount = classCount,
        instanceCount = instanceCount,
        sharedStrings = {},
        groups = {},
        groupById = {},
        nodesByRef = {},
        parentByRef = {},
        propertyRecords = {},
        sawParentChunk = false,
        sawEndChunk = false,
    }

    while reader:remaining() > 0 do
        local chunkName = reader:take(4)
        local compressedLength = reader:u32le()
        local decompressedLength = reader:u32le()
        reader:skip(4)

        local chunkData
        if compressedLength == 0 then
            chunkData = reader:take(decompressedLength)
        else
            local compressed = reader:take(compressedLength)
            chunkData = externalDecompress(compressed, decompressedLength)
            if chunkData == nil then
                if string.sub(compressed, 1, 4) == string.char(0x28, 0xb5, 0x2f, 0xfd) then
                    fail("Chunk memakai Zstandard, tetapi executor tidak menyediakan zstd_decompress")
                end
                chunkData = lz4Decompress(compressed, decompressedLength)
            end
        end

        if chunkName == "META" then
            local chunkReader = Reader.new(chunkData)
            local count = chunkReader:u32le()
            for _ = 1, count do
                chunkReader:string()
                chunkReader:string()
            end

        elseif chunkName == "SSTR" then
            local chunkReader = Reader.new(chunkData)
            chunkReader:u32le() -- version
            local count = chunkReader:u32le()
            for index = 0, count - 1 do
                chunkReader:skip(16) -- MD5; tidak perlu divalidasi untuk import
                file.sharedStrings[index] = chunkReader:string()
            end

        elseif chunkName == "INST" then
            local chunkReader = Reader.new(chunkData)
            local classId = chunkReader:u32le()
            local className = chunkReader:string()
            local objectFormat = chunkReader:u8()
            local count = chunkReader:u32le()
            local refs = chunkReader:referents(count)
            local group = {
                id = classId,
                className = className,
                count = count,
                refs = refs,
                nodes = {},
            }
            file.groups[#file.groups + 1] = group
            file.groupById[classId] = group

            for index, ref in ipairs(refs) do
                local node = {
                    ref = ref,
                    className = className,
                    index = index,
                    props = {},
                    instance = nil,
                }
                group.nodes[index] = node
                file.nodesByRef[ref] = node
            end

            if objectFormat ~= 0 then
                chunkReader:skip(count)
            end

        elseif chunkName == "PROP" then
            local chunkReader = Reader.new(chunkData)
            local classId = chunkReader:u32le()
            local propertyName = chunkReader:string()
            local typeId = chunkReader:u8()
            local group = file.groupById[classId]
            if group == nil then
                fail("PROP merujuk class ID yang belum dikenal: " .. tostring(classId))
            end
            local values = decodePropertyValues(chunkReader, typeId, group.count, file)
            file.propertyRecords[#file.propertyRecords + 1] = {
                group = group,
                name = propertyName,
                typeId = typeId,
                values = values,
            }
            for index, node in ipairs(group.nodes) do
                node.props[propertyName] = {
                    typeId = typeId,
                    value = values[index],
                }
            end

        elseif chunkName == "PRNT" then
            file.sawParentChunk = true
            local chunkReader = Reader.new(chunkData)
            chunkReader:u8() -- version
            local count = chunkReader:u32le()
            local children = chunkReader:referents(count)
            local parents = chunkReader:referents(count)
            for i = 1, count do
                local child = children[i]
                local parent = parents[i]
                if file.nodesByRef[child] == nil then
                    fail("PRNT merujuk child yang tidak ada: " .. tostring(child))
                end
                if parent ~= -1 and file.nodesByRef[parent] == nil then
                    fail("PRNT merujuk parent yang tidak ada: " .. tostring(parent))
                end
                if file.parentByRef[child] ~= nil then
                    fail("PRNT memiliki child duplikat: " .. tostring(child))
                end
                file.parentByRef[child] = parent
            end

        elseif chunkName == "SIGN" then
            -- Signature bytecode tidak diperlukan untuk membuat instance.

        elseif chunkName == "END\0" then
            if chunkData ~= "</roblox>" then
                fail("END chunk RBXM tidak valid")
            end
            file.sawEndChunk = true
            break

        else
            fail("Chunk RBXM tidak dikenal: " .. tostring(chunkName))
        end
    end

    if not file.sawEndChunk then
        fail("RBXM tidak memiliki END chunk")
    end
    if not file.sawParentChunk then
        fail("RBXM tidak memiliki PRNT chunk")
    end

    local actualInstanceCount = 0
    for _, group in ipairs(file.groups) do
        actualInstanceCount = actualInstanceCount + group.count
    end
    if actualInstanceCount ~= file.instanceCount then
        fail(string.format(
            "Jumlah instance tidak cocok: header %d, terbaca %d",
            file.instanceCount,
            actualInstanceCount
        ))
    end
    if #file.groups ~= file.classCount then
        fail(string.format(
            "Jumlah class tidak cocok: header %d, terbaca %d",
            file.classCount,
            #file.groups
        ))
    end

    local parentEntryCount = 0
    for _ in pairs(file.parentByRef) do
        parentEntryCount = parentEntryCount + 1
    end
    if parentEntryCount ~= actualInstanceCount then
        fail(string.format(
            "PRNT tidak lengkap: header %d, terbaca %d",
            actualInstanceCount,
            parentEntryCount
        ))
    end

    local roots = {}
    for ref, node in pairs(file.nodesByRef) do
        if file.parentByRef[ref] == nil or file.parentByRef[ref] == -1 then
            roots[#roots + 1] = node
        end
    end

    table.sort(roots, function(a, b)
        return a.ref < b.ref
    end)
    file.roots = roots
    return file
end

local function getEnvironment()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            return env
        end
    end
    return _G
end

local function readLocalFile(path)
    local environment = getEnvironment()
    local reader = environment.readfile
    if type(reader) ~= "function" then
        reader = readfile
    end
    if type(reader) ~= "function" then
        fail("Executor ini tidak menyediakan readfile(path)")
    end

    local ok, data = pcall(reader, path)
    if not ok then
        fail("readfile gagal: " .. tostring(data))
    end
    if type(data) ~= "string" or #data == 0 then
        fail("File kosong atau readfile tidak mengembalikan binary string")
    end
    return data
end

local function resolveValue(value, instancesByRef)
    if type(value) ~= "table" then
        return value
    end
    if value.__rbxmReference then
        return instancesByRef[value.ref]
    end
    if value.__rbxmContent then
        return value.uri
    end
    return value
end

local function enumItemFromNumber(object, propertyName, number)
    local ok, current = pcall(function()
        return object[propertyName]
    end)
    if not ok or typeof(current) ~= "EnumItem" then
        return nil
    end

    local okItems, items = pcall(function()
        return current.EnumType:GetEnumItems()
    end)
    if not okItems then
        return nil
    end

    for _, item in ipairs(items) do
        if item.Value == number then
            return item
        end
    end
    return nil
end

local function assignProperty(object, propertyName, rawValue, typeId, instancesByRef)
    if propertyName == "Parent" then
        return false
    end

    if typeId == 0x21
        or propertyName == "AttributesSerialize"
        or propertyName == "Capabilities"
        or propertyName == "DefinesCapabilities"
        or propertyName == "ModelMeshData"
        or propertyName == "ModelMeshSize"
        or propertyName == "ModelMeshCFrame"
        or propertyName == "WorldPivotData"
        or propertyName == "SourceAssetId"
        or propertyName == "SlimHash"
        or propertyName == "Tags" then
        -- Read-only/internal serialized fields. Byte data sudah dibaca, tetapi
        -- assignment-nya akan selalu ditolak oleh runtime biasa.
        return false
    end

    if rawValue == nil then
        return false
    end

    local value = resolveValue(rawValue, instancesByRef)
    if value == nil and typeId == 0x13 then
        return false
    end

    if type(rawValue) == "table" and rawValue.__rbxmFont then
        local family = rawValue.family
        local weight = rawValue.weight
        local style = rawValue.style
        local ok, font = pcall(Font.new, family, weight, style)
        if ok then
            value = font
        else
            return false
        end
    end

    local ok = pcall(function()
        object[propertyName] = value
    end)
    if ok then
        return true
    end

    -- Enum properties disimpan sebagai token angka di RBXM.
    if type(value) == "number" then
        local item = enumItemFromNumber(object, propertyName, value)
        if item ~= nil then
            return pcall(function()
                object[propertyName] = item
            end)
        end
    end

    -- Content modern kadang membutuhkan Content.fromUri(), sedangkan property
    -- lama menerima string biasa.
    if type(rawValue) == "table" and rawValue.__rbxmContent
        and type(Content) == "table" and type(Content.fromUri) == "function" then
        local okContent, contentValue = pcall(Content.fromUri, rawValue.uri)
        if okContent then
            return pcall(function()
                object[propertyName] = contentValue
            end)
        end
    end

    return false
end

local function createImportedInstance(node, failedClasses)
    local ok, object = pcall(Instance.new, node.className)
    if not ok or object == nil then
        object = Instance.new("Folder")
        failedClasses[node.className] = (failedClasses[node.className] or 0) + 1
        pcall(function()
            object:SetAttribute(ORIGINAL_CLASS_ATTRIBUTE, node.className)
        end)
    end
    node.instance = object
    return object
end

local function importDecodedFile(file)
    local instancesByRef = {}
    local failedClasses = {}
    local createdCount = 0
    local failedProperties = 0

    -- Buat semua instance lebih dulu agar referensi ObjectValue/PrimaryPart
    -- dapat diselesaikan setelah seluruh class sudah tersedia.
    for ref, node in pairs(file.nodesByRef) do
        local object = createImportedInstance(node, failedClasses)
        instancesByRef[ref] = object
        createdCount = createdCount + 1
    end

    -- Isi properties sebelum Parent dipasang.
    for _, node in pairs(file.nodesByRef) do
        local propertyNames = {}
        for name in pairs(node.props) do
            propertyNames[#propertyNames + 1] = name
        end
        table.sort(propertyNames, function(a, b)
            if a == "Name" then
                return true
            elseif b == "Name" then
                return false
            end
            return a < b
        end)

        for _, propertyName in ipairs(propertyNames) do
            local property = node.props[propertyName]
            if not assignProperty(
                node.instance,
                propertyName,
                property.value,
                property.typeId,
                instancesByRef
            ) then
                failedProperties = failedProperties + 1
            end
        end

        if DISABLE_IMPORTED_SCRIPTS
            and (node.className == "Script"
                or node.className == "LocalScript"
                or node.className == "ModuleScript") then
            pcall(function()
                node.instance.Disabled = true
            end)
        end
    end

    -- Parent sesuai PRNT. Root langsung ke Workspace.
    for ref, node in pairs(file.nodesByRef) do
        local parentRef = file.parentByRef[ref]
        local parentObject = parentRef and instancesByRef[parentRef] or nil
        if parentObject ~= nil then
            pcall(function()
                node.instance.Parent = parentObject
            end)
        else
            pcall(function()
                node.instance.Parent = Workspace
            end)
        end
    end

    local failedClassCount = 0
    for _ in pairs(failedClasses) do
        failedClassCount = failedClassCount + 1
    end

    return createdCount, failedProperties, failedClassCount
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

local function fileNameFromPath(path)
    local name = tostring(path):match("([^/]+)$")
    return name or tostring(path)
end

local function isRbxmPath(path)
    return string.lower(tostring(path)):sub(-5) == ".rbxm"
end

local function cleanError(errorText)
    local text = tostring(errorText or "error")
    text = text:gsub("^.-:%d+: ", "")
    if #text > 210 then
        text = string.sub(text, 1, 207) .. "..."
    end
    return text
end

local function getExecutorFunction(name)
    local environment = getEnvironment()
    local value = environment[name]
    if type(value) == "function" then
        return value
    end
    local globalValue = _G[name]
    if type(globalValue) == "function" then
        return globalValue
    end
    return nil
end

local function listDirectory(folder)
    local listFunction = getExecutorFunction("listfiles")
    if listFunction == nil then
        fail("Executor ini tidak menyediakan listfiles(folder)")
    end
    local ok, result = pcall(listFunction, folder)
    if not ok then
        fail("listfiles gagal: " .. tostring(result))
    end
    if type(result) ~= "table" then
        fail("listfiles tidak mengembalikan daftar file")
    end
    return result
end

local function pathIsFolder(path)
    local folderFunction = getExecutorFunction("isfolder")
    if folderFunction ~= nil then
        local ok, result = pcall(folderFunction, path)
        if ok then
            return result == true
        end
    end
    return tostring(path):sub(-1) == "/"
end

local function collectRbxmPaths(folder, recursive)
    local paths = {}
    local pathSeen = {}
    local folderSeen = {}
    local scanErrors = {}

    local function visit(current, depth)
        current = normalizePath(current)
        if depth > MAX_SCAN_DEPTH or folderSeen[current] then
            return
        end
        folderSeen[current] = true

        local ok, result = pcall(listDirectory, current)
        if not ok then
            scanErrors[#scanErrors + 1] = fileNameFromPath(current) .. ": " .. cleanError(result)
            return
        end

        for _, item in ipairs(result) do
            local path = normalizePath(item)
            if pathIsFolder(path) then
                if recursive then
                    visit(path, depth + 1)
                end
            elseif isRbxmPath(path) then
                local key = string.lower(path)
                if not pathSeen[key] then
                    pathSeen[key] = true
                    paths[#paths + 1] = path
                    if #paths >= MAX_FILES then
                        return
                    end
                end
            end
        end
    end

    visit(folder, 0)
    table.sort(paths, function(a, b)
        return string.lower(fileNameFromPath(a)) < string.lower(fileNameFromPath(b))
    end)
    return paths, scanErrors
end

local function validateDecodedFile(file)
    if file == nil then
        fail("Parser mengembalikan data kosong")
    end
    if file.instanceCount == nil or file.instanceCount < 1 then
        fail("RBXM tidak berisi instance")
    end
    if file.roots == nil or #file.roots < 1 then
        fail("RBXM tidak memiliki root instance")
    end
    if not file.sawEndChunk or not file.sawParentChunk then
        fail("Struktur RBXM tidak lengkap")
    end
end

local function makeEntry(path)
    local entry = {
        path = path,
        name = fileNameFromPath(path),
        valid = false,
        error = "Belum diverifikasi",
        size = 0,
        sizeText = "-",
        instanceCount = nil,
        classCount = nil,
        rootCount = nil,
    }

    local okData, data = pcall(readLocalFile, path)
    if not okData then
        entry.error = cleanError(data)
        return entry
    end
    entry.size = #data
    entry.sizeText = formatBytes(#data)

    local okDecoded, file = pcall(decodeRbxm, data)
    if not okDecoded then
        entry.error = cleanError(file)
        return entry
    end

    local okValid, validationError = pcall(validateDecodedFile, file)
    if not okValid then
        entry.error = cleanError(validationError)
        return entry
    end

    entry.valid = true
    entry.error = ""
    entry.instanceCount = file.instanceCount
    entry.classCount = #file.groups
    entry.rootCount = #file.roots
    return entry
end

local function scanFolder()
    if scanning or importing then
        return
    end

    local folder = normalizePath(folderBox.Text)
    if folder == "" then
        setStatus("Masukkan folder tujuan terlebih dahulu.", COLORS.red)
        return
    end

    scanning = true
    selectedEntry = nil
    fileEntries = {}
    updateDetails()
    renderRows()
    scanButton.Active = false
    scanButton.Text = "SCANNING..."
    scanButton.BackgroundColor3 = COLORS.input
    setStatus("Mencari file .rbxm...", COLORS.yellow)

    task.spawn(function()
        local ok, pathsOrError, errors = pcall(collectRbxmPaths, folder, recursive)
        if not ok then
            setStatus("ERROR ASLI: " .. cleanError(pathsOrError), COLORS.red)
            scanButton.Active = true
            scanButton.Text = "SCAN FOLDER"
            scanButton.BackgroundColor3 = COLORS.accent
            scanning = false
            return
        end

        local paths = pathsOrError
        if #paths == 0 then
            local message = "Tidak ditemukan file .rbxm di folder itu."
            if errors ~= nil and #errors > 0 then
                message = message .. " " .. cleanError(errors[1])
            end
            setStatus(message, COLORS.yellow)
        else
            setStatus("Preflight verify 0/" .. tostring(#paths) .. "...", COLORS.yellow)
        end

        for index, path in ipairs(paths) do
            local entry = makeEntry(path)
            fileEntries[#fileEntries + 1] = entry
            if index % 2 == 0 or index == #paths then
                renderRows()
                setStatus(
                    string.format("Preflight verify %d/%d...", index, #paths),
                    COLORS.yellow
                )
                task.wait()
            end
        end

        renderRows()
        scanButton.Active = true
        scanButton.Text = "SCAN FOLDER"
        scanButton.BackgroundColor3 = COLORS.accent
        scanning = false

        local valid = 0
        for _, entry in ipairs(fileEntries) do
            if entry.valid then
                valid = valid + 1
            end
        end
        if #paths > 0 then
            setStatus(
                string.format("Scan selesai: %d valid, %d ditolak.", valid, #paths - valid),
                valid > 0 and COLORS.green or COLORS.red
            )
        end
    end)
end

local function entryStillValid(entry)
    local data = readLocalFile(entry.path)
    local file = decodeRbxm(data)
    validateDecodedFile(file)
    return file
end

local function markEntryRejected(entry, message)
    entry.valid = false
    entry.error = cleanError(message)
    if selectedEntry == entry then
        updateDetails()
    end
    renderRows()
end

local function importOneEntry(entry, index, total)
    if not entry.valid then
        return false, "File sudah ditolak preflight"
    end

    setStatus(
        total and string.format("Verifikasi ulang %d/%d: %s", index, total, entry.name)
            or "Verifikasi ulang: " .. entry.name,
        COLORS.yellow
    )

    local ok, result = pcall(function()
        local file = entryStillValid(entry)
        local created, failedProperties, failedClasses = importDecodedFile(file)
        return created, failedProperties, failedClasses
    end)
    if not ok then
        markEntryRejected(entry, result)
        return false, cleanError(result)
    end

    entry.imported = true
    return true, result
end

scanButton.MouseButton1Click:Connect(scanFolder)

importSelectedButton.MouseButton1Click:Connect(function()
    if scanning or importing then
        return
    end
    if selectedEntry == nil then
        setStatus("Pilih satu file yang sudah VERIFIED.", COLORS.yellow)
        return
    end
    if not selectedEntry.valid then
        setStatus("File REJECTED tidak akan di-import.", COLORS.red)
        return
    end

    importing = true
    importSelectedButton.Active = false
    importAllButton.Active = false
    local ok, message = importOneEntry(selectedEntry)
    if ok then
        setStatus("Import selesai: " .. selectedEntry.name, COLORS.green)
    else
        setStatus("Import ditolak: " .. tostring(message), COLORS.red)
    end
    importSelectedButton.Active = true
    importAllButton.Active = true
    importing = false
end)

importAllButton.MouseButton1Click:Connect(function()
    if scanning or importing then
        return
    end

    local validEntries = {}
    for _, entry in ipairs(fileEntries) do
        if entry.valid then
            validEntries[#validEntries + 1] = entry
        end
    end
    if #validEntries == 0 then
        setStatus("Tidak ada file VERIFIED untuk di-import.", COLORS.yellow)
        return
    end

    importing = true
    importSelectedButton.Active = false
    importAllButton.Active = false
    local success = 0
    local failed = 0

    task.spawn(function()
        for index, entry in ipairs(validEntries) do
            local ok = importOneEntry(entry, index, #validEntries)
            if ok then
                success = success + 1
            else
                failed = failed + 1
            end
            task.wait()
        end
        renderRows()
        setStatus(
            string.format("Import batch selesai: %d berhasil, %d ditolak.", success, failed),
            failed == 0 and COLORS.green or COLORS.yellow
        )
        importSelectedButton.Active = true
        importAllButton.Active = true
        importing = false
    end)
end)

setStatus("Ready. Masukkan folder lalu tekan SCAN FOLDER.", COLORS.green)
