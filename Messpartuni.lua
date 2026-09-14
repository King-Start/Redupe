--[[
    ALLZ IMPORTER - SIMPLE SCAN/IMPORT

    Fokus versi ini hanya dua hal:
      1. Scan file .rbxm/.rbxmx.
      2. Import memakai getobjects + getcustomasset, lalu fallback
         InsertService:LoadLocalAsset.

    Tidak ada parser binary, anchor, move, atau refresh script.
    Transform dan isi model dibiarkan seperti file asli.
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")
local LocalPlayer = Players.LocalPlayer
if LocalPlayer == nil then
    return
end

local GUI_NAME = "ALLZSimpleImporter"
local MAX_FILES = 300

-- Pakai pola global langsung seperti kode yang kamu kirim.
local getFiles = listfiles or list_files
local getAsset = getcustomasset or getsynasset
local readfileData = readfile
local getObjects = getobjects

local COLOR_BG = Color3.fromRGB(11, 11, 14)
local COLOR_SURFACE = Color3.fromRGB(18, 18, 23)
local COLOR_GREEN = Color3.fromRGB(34, 197, 94)
local COLOR_GREEN_HOV = Color3.fromRGB(74, 222, 128)
local COLOR_TEXT = Color3.fromRGB(255, 255, 255)
local COLOR_MUTED = Color3.fromRGB(130, 130, 145)
local COLOR_RED = Color3.fromRGB(255, 100, 120)
local COLOR_YELLOW = Color3.fromRGB(245, 202, 92)

local function corner(instance, radius)
    local item = Instance.new("UICorner")
    item.CornerRadius = UDim.new(0, radius or 6)
    item.Parent = instance
    return item
end

local function makeLabel(parent, text, size, position, color, font, textSize, align)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Text = text or ""
    item.Font = font or Enum.Font.Gotham
    item.TextSize = textSize or 10
    item.TextColor3 = color or COLOR_TEXT
    item.TextXAlignment = align or Enum.TextXAlignment.Left
    item.Size = size
    item.Position = position
    item.Parent = parent
    return item
end

local function errorText(value)
    local text = tostring(value or "error")
    text = text:gsub("^.-:%d+: ", "")
    if #text > 180 then
        text = text:sub(1, 177) .. "..."
    end
    return text
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

local function getName(path)
    return tostring(path):match("([^/\\]+)$") or tostring(path)
end

local function getExtension(path)
    local name = getName(path)
    return string.lower(name:match("%.([^%.]+)$") or "")
end

-- ===================== UI =====================
pcall(function()
    local old = CoreGui:FindFirstChild(GUI_NAME)
    if old then
        old:Destroy()
    end
end)
pcall(function()
    local old = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(GUI_NAME)
    if old then
        old:Destroy()
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 150
local parentOK = pcall(function()
    screenGui.Parent = CoreGui
end)
if not parentOK or screenGui.Parent == nil then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local toggle = Instance.new("TextButton")
toggle.Name = "Toggle"
toggle.Size = UDim2.new(0, 42, 0, 42)
toggle.Position = UDim2.new(0, 15, 0.5, -21)
toggle.BackgroundColor3 = COLOR_GREEN
toggle.BorderSizePixel = 0
toggle.Text = "ALLZ"
toggle.TextColor3 = COLOR_TEXT
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 9
toggle.Active = true
toggle.Draggable = true
toggle.Parent = screenGui
corner(toggle, 21)

local main = Instance.new("Frame")
main.Name = "Main"
main.BackgroundColor3 = COLOR_BG
main.BorderSizePixel = 0
main.Size = UDim2.new(0, 300, 0, 370)
main.Position = UDim2.new(0.5, -150, 0.5, -185)
main.Active = true
main.Draggable = true
main.Parent = screenGui
corner(main, 10)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLOR_GREEN
mainStroke.Thickness = 1.5
mainStroke.Parent = main

toggle.MouseEnter:Connect(function()
    toggle.BackgroundColor3 = COLOR_GREEN_HOV
end)
toggle.MouseLeave:Connect(function()
    toggle.BackgroundColor3 = COLOR_GREEN
end)
toggle.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)

makeLabel(main, "ALLZ // IMPORTER", UDim2.new(0.7, 0, 0, 18), UDim2.new(0, 14, 0, 10), COLOR_TEXT, Enum.Font.GothamBold, 11)
makeLabel(main, "SIMPLE NATIVE LOADER", UDim2.new(0.7, 0, 0, 12), UDim2.new(0, 14, 0, 27), COLOR_MUTED, Enum.Font.Code, 7)

local close = Instance.new("TextButton")
close.Text = "×"
close.Font = Enum.Font.GothamBold
close.TextSize = 12
close.TextColor3 = COLOR_TEXT
close.BackgroundColor3 = COLOR_GREEN
close.BorderSizePixel = 0
close.Size = UDim2.new(0, 20, 0, 20)
close.Position = UDim2.new(1, -27, 0, 10)
close.Parent = main
corner(close, 5)
close.MouseButton1Click:Connect(function()
    main.Visible = false
end)

local pathBox = Instance.new("TextBox")
pathBox.BackgroundColor3 = COLOR_SURFACE
pathBox.BorderSizePixel = 0
pathBox.PlaceholderText = "Folder path; kosong = auto scan"
pathBox.Text = ""
pathBox.Font = Enum.Font.Code
pathBox.TextSize = 8
pathBox.TextColor3 = COLOR_TEXT
pathBox.PlaceholderColor3 = COLOR_MUTED
pathBox.ClearTextOnFocus = false
pathBox.TextXAlignment = Enum.TextXAlignment.Left
pathBox.Size = UDim2.new(0, 207, 0, 27)
pathBox.Position = UDim2.new(0, 14, 0, 45)
pathBox.Parent = main
corner(pathBox, 6)
local pathPad = Instance.new("UIPadding")
pathPad.PaddingLeft = UDim.new(0, 8)
pathPad.PaddingRight = UDim.new(0, 8)
pathPad.Parent = pathBox

local scanButton = Instance.new("TextButton")
scanButton.Text = "SCAN"
scanButton.Font = Enum.Font.GothamBold
scanButton.TextSize = 8
scanButton.TextColor3 = COLOR_TEXT
scanButton.BackgroundColor3 = COLOR_GREEN
scanButton.BorderSizePixel = 0
scanButton.Size = UDim2.new(0, 48, 0, 27)
scanButton.Position = UDim2.new(0, 232, 0, 45)
scanButton.Parent = main
corner(scanButton, 6)

local search = Instance.new("TextBox")
search.BackgroundColor3 = COLOR_SURFACE
search.BorderSizePixel = 0
search.PlaceholderText = "Search model files..."
search.Text = ""
search.Font = Enum.Font.Gotham
search.TextSize = 8
search.TextColor3 = COLOR_TEXT
search.PlaceholderColor3 = COLOR_MUTED
search.ClearTextOnFocus = false
search.Size = UDim2.new(0, 272, 0, 25)
search.Position = UDim2.new(0, 14, 0, 76)
search.Parent = main
corner(search, 6)
local searchPad = Instance.new("UIPadding")
searchPad.PaddingLeft = UDim.new(0, 8)
searchPad.Parent = search

local allButton = Instance.new("TextButton")
local rbxmButton = Instance.new("TextButton")
local rbxmxButton = Instance.new("TextButton")
local currentFilter = "ALL"

local function filterButton(button, text, x, active)
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 8
    button.TextColor3 = COLOR_TEXT
    button.BackgroundColor3 = active and COLOR_GREEN or COLOR_SURFACE
    button.BorderSizePixel = 0
    button.Size = UDim2.new(0, 84, 0, 21)
    button.Position = UDim2.new(0, x, 0, 108)
    button.Parent = main
    corner(button, 5)
end
filterButton(allButton, "ALL", 14, true)
filterButton(rbxmButton, "RBXM", 105, false)
filterButton(rbxmxButton, "RBXMX", 196, false)

local fileScroll = Instance.new("ScrollingFrame")
fileScroll.BackgroundTransparency = 1
fileScroll.BorderSizePixel = 0
fileScroll.Position = UDim2.new(0, 14, 0, 137)
fileScroll.Size = UDim2.new(0, 272, 0, 176)
fileScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
fileScroll.ScrollBarThickness = 2
fileScroll.Parent = main
local fileLayout = Instance.new("UIListLayout")
fileLayout.Padding = UDim.new(0, 6)
fileLayout.Parent = fileScroll

local status = makeLabel(main, "Ready. Tekan SCAN.", UDim2.new(1, -28, 0, 13), UDim2.new(0, 14, 1, -54), COLOR_MUTED, Enum.Font.Code, 8)
status.TextTruncate = Enum.TextTruncate.AtEnd

local refresh = Instance.new("TextButton")
refresh.Text = "REFRESH"
refresh.Font = Enum.Font.GothamBold
refresh.TextSize = 8
refresh.TextColor3 = COLOR_TEXT
refresh.BackgroundColor3 = COLOR_GREEN
refresh.BorderSizePixel = 0
refresh.Size = UDim2.new(0, 127, 0, 26)
refresh.Position = UDim2.new(0, 14, 1, -34)
refresh.Parent = main
corner(refresh, 6)

local logButton = Instance.new("TextButton")
logButton.Text = "LOGS"
logButton.Font = Enum.Font.GothamBold
logButton.TextSize = 8
logButton.TextColor3 = COLOR_TEXT
logButton.BackgroundColor3 = COLOR_GREEN
logButton.BorderSizePixel = 0
logButton.Size = UDim2.new(0, 127, 0, 26)
logButton.Position = UDim2.new(0, 149, 1, -34)
logButton.Parent = main
corner(logButton, 6)

local logFrame = Instance.new("Frame")
logFrame.BackgroundColor3 = COLOR_SURFACE
logFrame.BorderSizePixel = 0
logFrame.Position = UDim2.new(0, 14, 0, 137)
logFrame.Size = UDim2.new(0, 272, 0, 176)
logFrame.Visible = false
logFrame.Parent = main
corner(logFrame, 6)
makeLabel(logFrame, "EXECUTION LOG", UDim2.new(1, -20, 0, 16), UDim2.new(0, 10, 0, 7), COLOR_GREEN, Enum.Font.GothamBold, 8)
local logScroll = Instance.new("ScrollingFrame")
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.Position = UDim2.new(0, 10, 0, 27)
logScroll.Size = UDim2.new(0, 252, 0, 140)
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.ScrollBarThickness = 2
logScroll.Parent = logFrame
local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0, 4)
logLayout.Parent = logScroll

local function addLog(message, color)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Size = UDim2.new(1, 0, 0, 14)
    item.Font = Enum.Font.Code
    item.TextSize = 8
    item.TextColor3 = color or COLOR_TEXT
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextWrapped = true
    item.Text = "[ALLZ] " .. tostring(message)
    item.Parent = logScroll
end

logButton.MouseButton1Click:Connect(function()
    logFrame.Visible = not logFrame.Visible
end)

-- ===================== SCAN =====================
local found = {}
local scanning = false
local importing = false

local function setStatus(message, color)
    status.Text = tostring(message)
    status.TextColor3 = color or COLOR_MUTED
end

local function clearRows()
    for _, child in ipairs(fileScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local function callListFiles(path)
    if not getFiles then
        return {}, "listfiles/list_files tidak tersedia"
    end

    local attempts = {}
    if path and path ~= "" then
        attempts[#attempts + 1] = function()
            return getFiles(path)
        end
    end
    attempts[#attempts + 1] = function()
        return getFiles()
    end

    local lastError = "folder tidak dapat dibaca"
    for _, attempt in ipairs(attempts) do
        local ok, result = pcall(attempt)
        if ok and type(result) == "table" then
            return result, nil
        elseif not ok then
            lastError = errorText(result)
        end
    end
    return {}, lastError
end

local function renderRows()
    clearRows()
    local query = string.lower(search.Text or "")
    local shown = 0

    for _, item in ipairs(found) do
        local searchMatch = query == "" or string.find(string.lower(item.name), query, 1, true) ~= nil
        local typeMatch = currentFilter == "ALL" or item.ext == string.lower(currentFilter)
        if searchMatch and typeMatch then
            shown = shown + 1
            local row = Instance.new("Frame")
            row.BackgroundColor3 = item.failed and Color3.fromRGB(60, 25, 33) or COLOR_SURFACE
            row.BorderSizePixel = 0
            row.Size = UDim2.new(1, -4, 0, 36)
            row.LayoutOrder = shown
            row.Parent = fileScroll
            corner(row, 6)

            makeLabel(row, item.name, UDim2.new(0.62, 0, 0, 14), UDim2.new(0, 10, 0, 5), COLOR_TEXT, Enum.Font.GothamBold, 8)
            makeLabel(row, item.failed and errorText(item.error) or string.upper(item.ext), UDim2.new(0.62, 0, 0, 10), UDim2.new(0, 10, 0, 20), item.failed and COLOR_RED or COLOR_MUTED, Enum.Font.Gotham, 7)

            local import = Instance.new("TextButton")
            import.Text = item.imported and "AGAIN" or "IMPORT"
            import.Font = Enum.Font.GothamBold
            import.TextSize = 7
            import.TextColor3 = COLOR_TEXT
            import.BackgroundColor3 = COLOR_GREEN
            import.BorderSizePixel = 0
            import.Size = UDim2.new(0, 56, 0, 20)
            import.Position = UDim2.new(1, -62, 0.5, -10)
            import.Parent = row
            corner(import, 4)

            import.MouseEnter:Connect(function()
                import.BackgroundColor3 = COLOR_GREEN_HOV
            end)
            import.MouseLeave:Connect(function()
                import.BackgroundColor3 = COLOR_GREEN
            end)
            import.MouseButton1Click:Connect(function()
                if importing or scanning then
                    return
                end
                importing = true
                import.Active = false
                setStatus("Loading: " .. item.name, COLOR_YELLOW)
                addLog("Loading: " .. item.path, COLOR_YELLOW)

                local objects, loadError = loadModelFile(item.path)
                if #objects == 0 then
                    item.failed = true
                    item.error = loadError or "loader tidak mengembalikan object"
                    setStatus("Import gagal: " .. errorText(item.error), COLOR_RED)
                    addLog("Failed: " .. errorText(item.error), COLOR_RED)
                else
                    local inserted = 0
                    for _, object in ipairs(objects) do
                        local okParent, parentError = pcall(function()
                            object.Parent = Workspace
                        end)
                        if okParent then
                            inserted = inserted + 1
                        else
                            addLog("Parent gagal: " .. errorText(parentError), COLOR_RED)
                        end
                    end
                    if inserted > 0 then
                        item.imported = true
                        item.failed = false
                        setStatus("Import selesai: " .. item.name, COLOR_GREEN)
                        addLog("Success: " .. tostring(inserted) .. " object", COLOR_GREEN)
                    else
                        item.failed = true
                        item.error = "object tidak dapat diparent ke Workspace"
                        setStatus("Import gagal: " .. item.error, COLOR_RED)
                    end
                end
                importing = false
                renderRows()
            end)
        end
    end

    fileScroll.CanvasSize = UDim2.new(0, 0, 0, fileLayout.AbsoluteContentSize.Y + 5)
    if shown == 0 then
        setStatus(#found == 0 and "Tidak ada file. Tekan SCAN." or "Tidak ada file yang cocok.", COLOR_YELLOW)
    end
end

local function scan()
    if scanning or importing then
        return
    end
    scanning = true
    scanButton.Active = false
    refresh.Active = false
    scanButton.Text = "..."
    refresh.Text = "SCANNING"
    found = {}
    clearRows()
    setStatus("Scanning...", COLOR_YELLOW)
    addLog("Scanning...", COLOR_YELLOW)

    task.spawn(function()
        local typedPath = normalizePath(pathBox.Text)
        local roots
        if typedPath ~= "" then
            roots = {typedPath}
        else
            roots = {"workspace", "", ".", "./"}
        end

        local files = {}
        local errorMessage = nil
        for _, root in ipairs(roots) do
            local result, err = callListFiles(root)
            if #result > 0 then
                files = result
                break
            end
            errorMessage = err
        end

        local seen = {}
        for _, path in ipairs(files) do
            if #found >= MAX_FILES then
                break
            end
            path = normalizePath(path)
            local ext = getExtension(path)
            local key = string.lower(path)
            if (ext == "rbxm" or ext == "rbxmx") and not seen[key] then
                seen[key] = true
                found[#found + 1] = {
                    path = path,
                    name = getName(path),
                    ext = ext,
                    imported = false,
                    failed = false,
                }
            end
        end

        table.sort(found, function(a, b)
            return string.lower(a.name) < string.lower(b.name)
        end)
        renderRows()
        scanButton.Active = true
        refresh.Active = true
        scanButton.Text = "SCAN"
        refresh.Text = "REFRESH"
        scanning = false

        if #found == 0 then
            local detail = errorMessage and (" " .. errorText(errorMessage)) or ""
            setStatus("File RBXM tidak ditemukan." .. detail, COLOR_YELLOW)
            addLog("No RBXM/RBXMX found.", COLOR_YELLOW)
        else
            setStatus("Ditemukan " .. tostring(#found) .. " file.", COLOR_GREEN)
            addLog("Scan complete: " .. tostring(#found), COLOR_GREEN)
        end
    end)
end

allButton.MouseButton1Click:Connect(function()
    currentFilter = "ALL"
    allButton.BackgroundColor3 = COLOR_GREEN
    rbxmButton.BackgroundColor3 = COLOR_SURFACE
    rbxmxButton.BackgroundColor3 = COLOR_SURFACE
    renderRows()
end)
rbxmButton.MouseButton1Click:Connect(function()
    currentFilter = "rbxm"
    allButton.BackgroundColor3 = COLOR_SURFACE
    rbxmButton.BackgroundColor3 = COLOR_GREEN
    rbxmxButton.BackgroundColor3 = COLOR_SURFACE
    renderRows()
end)
rbxmxButton.MouseButton1Click:Connect(function()
    currentFilter = "rbxmx"
    allButton.BackgroundColor3 = COLOR_SURFACE
    rbxmButton.BackgroundColor3 = COLOR_SURFACE
    rbxmxButton.BackgroundColor3 = COLOR_GREEN
    renderRows()
end)
search:GetPropertyChangedSignal("Text"):Connect(renderRows)
scanButton.MouseButton1Click:Connect(scan)
refresh.MouseButton1Click:Connect(scan)

addLog("Simple importer ready.", COLOR_GREEN)
scan()
