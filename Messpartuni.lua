--[[
    RBXM Native Scanner - Studio Lite

    PENTING:
    Script ini TIDAK mem-parse atau membangun ulang isi RBXM.
    Script hanya mencari file .rbxm, lalu menyerahkan file tersebut ke
    Roblox melalui InsertService:LoadLocalAsset(path).

    Dengan begitu Size, CFrame, MeshPart, SpecialMesh, property, hierarchy,
    attachment, constraint, dan isi model tidak dihitung ulang oleh script.

    Executor yang dibutuhkan:
      listfiles(folder)
      InsertService:LoadLocalAsset(path) harus dapat dipanggil di environment.

    Subfolder membutuhkan:
      isfolder(path)
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

local GUI_NAME = "RBXMNativeScanner"
local MAX_SCAN_DEPTH = 8
local MAX_FILES = 500

local C = {
    bg = Color3.fromRGB(14, 17, 26),
    panel = Color3.fromRGB(24, 28, 41),
    card = Color3.fromRGB(31, 37, 53),
    cardHover = Color3.fromRGB(43, 48, 70),
    input = Color3.fromRGB(38, 45, 64),
    border = Color3.fromRGB(72, 82, 112),
    text = Color3.fromRGB(244, 247, 255),
    muted = Color3.fromRGB(159, 169, 191),
    accent = Color3.fromRGB(105, 91, 235),
    accentHover = Color3.fromRGB(128, 113, 255),
    green = Color3.fromRGB(92, 220, 153),
    yellow = Color3.fromRGB(244, 198, 88),
    red = Color3.fromRGB(255, 111, 130),
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

-- Ukuran sengaja compact. Max 430x500 agar tidak memenuhi layar.
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0.86, 0, 0.76, 0)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = C.panel
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = screenGui

local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(320, 350)
constraint.MaxSize = Vector2.new(430, 500)
constraint.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = C.border
panelStroke.Transparency = 0.25
panelStroke.Parent = panel

local topBar = Instance.new("Frame")
topBar.BackgroundTransparency = 1
topBar.Position = UDim2.new(0, 14, 0, 10)
topBar.Size = UDim2.new(1, -28, 0, 32)
topBar.Active = true
topBar.Parent = panel

local logo = Instance.new("TextLabel")
logo.BackgroundColor3 = C.accent
logo.BorderSizePixel = 0
logo.Size = UDim2.new(0, 30, 0, 30)
logo.Font = Enum.Font.GothamBold
logo.TextSize = 13
logo.TextColor3 = C.text
logo.Text = "R"
logo.Parent = topBar
local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(0, 8)
logoCorner.Parent = logo

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 39, 0, 0)
title.Size = UDim2.new(1, -75, 0, 18)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = C.text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "RBXM IMPORTER"
title.Parent = topBar

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 40, 0, 16)
subtitle.Size = UDim2.new(1, -80, 0, 12)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 9
subtitle.TextColor3 = C.muted
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "Native Roblox loader  •  no custom geometry rebuild"
subtitle.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.BackgroundColor3 = C.card
closeButton.BorderSizePixel = 0
closeButton.Position = UDim2.new(1, -30, 0, 1)
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 15
closeButton.TextColor3 = C.muted
closeButton.Text = "×"
closeButton.AutoButtonColor = false
closeButton.Parent = topBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 7)
closeCorner.Parent = closeButton

local folderBox = Instance.new("TextBox")
folderBox.Position = UDim2.new(0, 14, 0, 52)
folderBox.Size = UDim2.new(1, -116, 0, 34)
folderBox.BackgroundColor3 = C.input
folderBox.BorderSizePixel = 0
folderBox.ClearTextOnFocus = false
folderBox.Font = Enum.Font.Code
folderBox.TextSize = 11
folderBox.TextColor3 = C.text
folderBox.PlaceholderColor3 = C.muted
folderBox.PlaceholderText = "Folder path..."
folderBox.Text = "."
folderBox.TextXAlignment = Enum.TextXAlignment.Left
folderBox.Parent = panel
local folderPadding = Instance.new("UIPadding")
folderPadding.PaddingLeft = UDim.new(0, 9)
folderPadding.PaddingRight = UDim.new(0, 9)
folderPadding.Parent = folderBox
local folderCorner = Instance.new("UICorner")
folderCorner.CornerRadius = UDim.new(0, 7)
folderCorner.Parent = folderBox

local scanButton = Instance.new("TextButton")
scanButton.Position = UDim2.new(1, -92, 0, 52)
scanButton.Size = UDim2.new(0, 78, 0, 34)
scanButton.BackgroundColor3 = C.accent
scanButton.BorderSizePixel = 0
scanButton.Font = Enum.Font.GothamBold
scanButton.TextSize = 10
scanButton.TextColor3 = C.text
scanButton.Text = "SCAN"
scanButton.AutoButtonColor = false
scanButton.Parent = panel
local scanCorner = Instance.new("UICorner")
scanCorner.CornerRadius = UDim.new(0, 7)
scanCorner.Parent = scanButton

local recursiveButton = Instance.new("TextButton")
recursiveButton.BackgroundTransparency = 1
recursiveButton.Position = UDim2.new(0, 14, 0, 91)
recursiveButton.Size = UDim2.new(0, 125, 0, 20)
recursiveButton.Font = Enum.Font.Gotham
recursiveButton.TextSize = 10
recursiveButton.TextColor3 = C.muted
recursiveButton.TextXAlignment = Enum.TextXAlignment.Left
recursiveButton.Text = "↳ Subfolder: OFF"
recursiveButton.AutoButtonColor = false
recursiveButton.Parent = panel

local countLabel = Instance.new("TextLabel")
countLabel.BackgroundTransparency = 1
countLabel.Position = UDim2.new(1, -170, 0, 91)
countLabel.Size = UDim2.new(0, 156, 0, 20)
countLabel.Font = Enum.Font.Code
countLabel.TextSize = 10
countLabel.TextColor3 = C.muted
countLabel.TextXAlignment = Enum.TextXAlignment.Right
countLabel.Text = "0 file"
countLabel.Parent = panel

local searchBox = Instance.new("TextBox")
searchBox.Position = UDim2.new(0, 14, 0, 116)
searchBox.Size = UDim2.new(1, -28, 0, 29)
searchBox.BackgroundColor3 = C.input
searchBox.BorderSizePixel = 0
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 10
searchBox.TextColor3 = C.text
searchBox.PlaceholderColor3 = C.muted
searchBox.PlaceholderText = "Cari nama file..."
searchBox.Text = ""
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = panel
local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 9)
searchPadding.PaddingRight = UDim.new(0, 9)
searchPadding.Parent = searchBox
local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 7)
searchCorner.Parent = searchBox

local fileList = Instance.new("ScrollingFrame")
fileList.Position = UDim2.new(0, 14, 0, 152)
fileList.Size = UDim2.new(1, -28, 1, -239)
fileList.BackgroundColor3 = C.card
fileList.BorderSizePixel = 0
fileList.ScrollBarThickness = 4
fileList.ScrollBarImageColor3 = C.border
fileList.CanvasSize = UDim2.new(0, 0, 0, 0)
fileList.Parent = panel
local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 9)
listCorner.Parent = fileList

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 7)
listPadding.PaddingBottom = UDim.new(0, 7)
listPadding.PaddingLeft = UDim.new(0, 7)
listPadding.PaddingRight = UDim.new(0, 7)
listPadding.Parent = fileList

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = fileList

local emptyLabel = Instance.new("TextLabel")
emptyLabel.BackgroundTransparency = 1
emptyLabel.Position = UDim2.new(0, 20, 0.5, -18)
emptyLabel.Size = UDim2.new(1, -40, 0, 38)
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.TextSize = 10
emptyLabel.TextColor3 = C.muted
emptyLabel.TextWrapped = true
emptyLabel.Text = "Belum ada file.\nMasukkan folder lalu tekan SCAN."
emptyLabel.Parent = panel

local importButton = Instance.new("TextButton")
importButton.Position = UDim2.new(0, 14, 1, -74)
importButton.Size = UDim2.new(0.5, -20, 0, 34)
importButton.BackgroundColor3 = C.accent
importButton.BorderSizePixel = 0
importButton.Font = Enum.Font.GothamBold
importButton.TextSize = 10
importButton.TextColor3 = C.text
importButton.Text = "IMPORT SELECTED"
importButton.AutoButtonColor = false
importButton.Parent = panel
local importCorner = Instance.new("UICorner")
importCorner.CornerRadius = UDim.new(0, 7)
importCorner.Parent = importButton

local importAllButton = Instance.new("TextButton")
importAllButton.Position = UDim2.new(0.5, 6, 1, -74)
importAllButton.Size = UDim2.new(0.5, -20, 0, 34)
importAllButton.BackgroundColor3 = C.cardHover
importAllButton.BorderSizePixel = 0
importAllButton.Font = Enum.Font.GothamBold
importAllButton.TextSize = 10
importAllButton.TextColor3 = C.text
importAllButton.Text = "IMPORT ALL"
importAllButton.AutoButtonColor = false
importAllButton.Parent = panel
local importAllCorner = Instance.new("UICorner")
importAllCorner.CornerRadius = UDim.new(0, 7)
importAllCorner.Parent = importAllButton

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 14, 1, -35)
statusLabel.Size = UDim2.new(1, -28, 0, 18)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 9
statusLabel.TextColor3 = C.muted
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
statusLabel.Text = "Ready."
statusLabel.Parent = panel

local function setStatus(text, color)
    statusLabel.Text = tostring(text)
    statusLabel.TextColor3 = color or C.muted
end

local function hover(button, normal, over)
    button.MouseEnter:Connect(function()
        if button.Active then
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = over}):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        if button.Active then
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = normal}):Play()
        end
    end)
end

hover(scanButton, C.accent, C.accentHover)
hover(importButton, C.accent, C.accentHover)
hover(importAllButton, C.cardHover, C.input)
hover(closeButton, C.card, Color3.fromRGB(76, 48, 67))

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Drag panel.
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
local scanning = false
local importing = false
local selectedEntry = nil
local entries = {}
local rowObjects = {}

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
    if #text > 170 then
        text = text:sub(1, 167) .. "..."
    end
    return text
end

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

local function folderPath(path)
    local folderFunction = executorFunction("isfolder")
    if folderFunction ~= nil then
        local ok, result = pcall(folderFunction, path)
        if ok then
            return result == true
        end
    end
    return tostring(path):sub(-1) == "/"
end

local function collectFiles(root, includeSubfolders)
    local result = {}
    local seenFiles = {}
    local seenFolders = {}

    local function visit(folder, depth)
        folder = normalizePath(folder)
        if depth > MAX_SCAN_DEPTH or seenFolders[folder] or #result >= MAX_FILES then
            return
        end
        seenFolders[folder] = true

        local children = listFolder(folder)
        for _, item in ipairs(children) do
            if #result >= MAX_FILES then
                break
            end
            local path = normalizePath(item)
            if folderPath(path) then
                if includeSubfolders then
                    local ok = pcall(visit, path, depth + 1)
                    if not ok then
                        -- Subfolder yang tidak bisa dibaca dilewati; file utama
                        -- tetap dapat dipakai.
                    end
                end
            elseif isRbxm(path) then
                local key = string.lower(path)
                if not seenFiles[key] then
                    seenFiles[key] = true
                    result[#result + 1] = path
                end
            end
        end
    end

    visit(root, 0)
    table.sort(result, function(a, b)
        return string.lower(fileName(a)) < string.lower(fileName(b))
    end)
    return result
end

local function formatRowMeta(entry)
    if entry.imported then
        return "IMPORTED  •  native load success"
    elseif entry.failed then
        return "ERROR  •  " .. tostring(entry.error)
    end
    return "READY  •  native Roblox import"
end

local function clearRows()
    for _, row in ipairs(rowObjects) do
        row:Destroy()
    end
    rowObjects = {}
end

local function renderRows()
    clearRows()
    local query = string.lower(searchBox.Text or "")
    local shown = 0

    for _, entry in ipairs(entries) do
        if query == "" or string.find(string.lower(entry.name), query, 1, true) then
            shown = shown + 1
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -4, 0, 48)
            row.BackgroundColor3 = entry == selectedEntry and Color3.fromRGB(54, 51, 95) or C.cardHover
            row.BorderSizePixel = 0
            row.LayoutOrder = shown
            row.Parent = fileList
            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 7)
            rowCorner.Parent = row

            local marker = Instance.new("TextLabel")
            marker.BackgroundTransparency = 1
            marker.Position = UDim2.new(0, 9, 0, 7)
            marker.Size = UDim2.new(0, 18, 0, 22)
            marker.Font = Enum.Font.GothamBold
            marker.TextSize = 15
            marker.TextColor3 = entry.failed and C.red or (entry.imported and C.green or C.yellow)
            marker.Text = entry.failed and "×" or (entry.imported and "✓" or "•")
            marker.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.BackgroundTransparency = 1
            nameLabel.Position = UDim2.new(0, 33, 0, 5)
            nameLabel.Size = UDim2.new(1, -43, 0, 19)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 11
            nameLabel.TextColor3 = C.text
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Text = entry.name
            nameLabel.Parent = row

            local metaLabel = Instance.new("TextLabel")
            metaLabel.BackgroundTransparency = 1
            metaLabel.Position = UDim2.new(0, 33, 0, 25)
            metaLabel.Size = UDim2.new(1, -43, 0, 15)
            metaLabel.Font = Enum.Font.Code
            metaLabel.TextSize = 8
            metaLabel.TextColor3 = entry.failed and C.red or C.muted
            metaLabel.TextXAlignment = Enum.TextXAlignment.Left
            metaLabel.TextTruncate = Enum.TextTruncate.AtEnd
            metaLabel.Text = formatRowMeta(entry)
            metaLabel.Parent = row

            local choose = Instance.new("TextButton")
            choose.BackgroundTransparency = 1
            choose.BorderSizePixel = 0
            choose.Size = UDim2.new(1, 0, 1, 0)
            choose.Text = ""
            choose.AutoButtonColor = false
            choose.Parent = row
            choose.MouseButton1Click:Connect(function()
                selectedEntry = entry
                renderRows()
            end)
            rowObjects[#rowObjects + 1] = row
        end
    end

    emptyLabel.Visible = shown == 0
    fileList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
    countLabel.Text = tostring(#entries) .. (#entries == 1 and " file" or " files")
end

local function loadNative(path)
    -- Ini satu-satunya jalur import. Tidak ada parser fallback yang bisa
    -- mengubah ukuran atau posisi model.
    local ok, root = pcall(function()
        return InsertService:LoadLocalAsset(path)
    end)
    if not ok then
        error("LoadLocalAsset gagal: " .. tostring(root), 0)
    end
    if root == nil or typeof(root) ~= "Instance" then
        error("LoadLocalAsset tidak mengembalikan Instance", 0)
    end

    local parentOK, parentError = pcall(function()
        root.Parent = Workspace
    end)
    if not parentOK then
        pcall(function()
            root:Destroy()
        end)
        error("Gagal menaruh hasil ke Workspace: " .. tostring(parentError), 0)
    end
    return root
end

local function importEntry(entry)
    if entry == nil then
        return false, "Pilih file terlebih dahulu"
    end
    if entry.failed then
        return false, entry.error or "File sebelumnya gagal di-import"
    end

    local ok, result = pcall(function()
        return loadNative(entry.path)
    end)
    if not ok then
        entry.failed = true
        entry.error = cleanError(result)
        renderRows()
        return false, entry.error
    end

    entry.imported = true
    entry.root = result
    renderRows()
    return true, result
end

local function scan()
    if scanning or importing then
        return
    end
    local folder = normalizePath(folderBox.Text)
    if folder == "" then
        setStatus("Masukkan folder terlebih dahulu.", C.red)
        return
    end

    scanning = true
    selectedEntry = nil
    entries = {}
    renderRows()
    scanButton.Active = false
    scanButton.Text = "..."
    scanButton.BackgroundColor3 = C.input
    setStatus("Scanning folder...", C.yellow)

    task.spawn(function()
        local ok, paths = pcall(collectFiles, folder, recursive)
        if not ok then
            setStatus("ERROR ASLI: " .. cleanError(paths), C.red)
        else
            for _, path in ipairs(paths) do
                entries[#entries + 1] = {
                    path = path,
                    name = fileName(path),
                    imported = false,
                    failed = false,
                }
            end
            renderRows()
            if #entries == 0 then
                setStatus("Tidak ada file .rbxm di folder itu.", C.yellow)
            else
                setStatus(string.format("%d file siap di-import native.", #entries), C.green)
            end
        end
        scanButton.Active = true
        scanButton.Text = "SCAN"
        scanButton.BackgroundColor3 = C.accent
        scanning = false
    end)
end

scanButton.MouseButton1Click:Connect(scan)

recursiveButton.MouseButton1Click:Connect(function()
    recursive = not recursive
    recursiveButton.Text = recursive and "↳ Subfolder: ON" or "↳ Subfolder: OFF"
    recursiveButton.TextColor3 = recursive and C.green or C.muted
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(renderRows)

importButton.MouseButton1Click:Connect(function()
    if scanning or importing then
        return
    end
    importing = true
    importButton.Active = false
    importAllButton.Active = false
    local ok, result = importEntry(selectedEntry)
    if ok then
        setStatus("Import native selesai: " .. selectedEntry.name, C.green)
    else
        setStatus("ERROR ASLI: " .. tostring(result), C.red)
    end
    importButton.Active = true
    importAllButton.Active = true
    importing = false
end)

importAllButton.MouseButton1Click:Connect(function()
    if scanning or importing then
        return
    end
    if #entries == 0 then
        setStatus("Scan folder dulu.", C.yellow)
        return
    end

    importing = true
    importButton.Active = false
    importAllButton.Active = false
    task.spawn(function()
        local success = 0
        local failed = 0
        local total = #entries
        for index, entry in ipairs(entries) do
            setStatus(string.format("Import native %d/%d: %s", index, total, entry.name), C.yellow)
            local ok = importEntry(entry)
            if ok then
                success = success + 1
            else
                failed = failed + 1
            end
            task.wait()
        end
        setStatus(string.format("Selesai: %d berhasil, %d gagal.", success, failed), failed == 0 and C.green or C.yellow)
        importButton.Active = true
        importAllButton.Active = true
        importing = false
    end)
end)

renderRows()
setStatus("Ready. Scan folder untuk mencari RBXM.", C.green)
