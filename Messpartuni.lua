--[[
    ALLZ RBXM IMPORTER - SCAN + NATIVE LOADER EDITION

    Ini memakai engine import dari workflow ALLZ:
      1. scan file melalui listfiles
      2. coba getobjects(getcustomasset(path))
      3. fallback ke InsertService:LoadLocalAsset(path)

    Script TIDAK mem-parse binary RBXM dan TIDAK menghitung ulang Size/CFrame.
    Default-nya menjaga transform asli file. Opsi anchor/spawn/refresh tersedia
    di bagian CONFIG dan semuanya false secara default.
]]

local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local LocalPlayer = Players.LocalPlayer
if LocalPlayer == nil then
    return
end

-- ===================== CONFIG =====================
local KEEP_ORIGINAL_TRANSFORM = true
local ANCHOR_IMPORTED_PARTS = false
local SPAWN_IN_FRONT_OF_PLAYER = false
local REFRESH_IMPORTED_SCRIPTS = false
local GUI_NAME = "ALLZImporter_StudioLite"
local MAX_FILES = 500

-- ===================== EXECUTOR FUNCTIONS =====================
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

-- Gunakan global executor secara langsung seperti loader ALLZ asli.
-- Beberapa executor tidak mengekspos fungsi mereka lewat _G/getgenv.
local getFiles = listfiles or list_files
local getAsset = getcustomasset or getsynasset
local readfileData = readfile
local getObjects = getobjects

-- ===================== THEME =====================
local COLOR_BG = Color3.fromRGB(11, 11, 14)
local COLOR_SURFACE = Color3.fromRGB(18, 18, 23)
local COLOR_SURFACE_2 = Color3.fromRGB(25, 25, 32)
local COLOR_GREEN = Color3.fromRGB(34, 197, 94)
local COLOR_GREEN_HOV = Color3.fromRGB(74, 222, 128)
local COLOR_TEXT = Color3.fromRGB(255, 255, 255)
local COLOR_MUTED = Color3.fromRGB(130, 130, 145)
local COLOR_YELLOW = Color3.fromRGB(245, 202, 92)
local COLOR_RED = Color3.fromRGB(255, 105, 125)

local currentFilter = "ALL"
local foundFiles = {}
local scanBusy = false
local importBusy = false
local vortexConnection

local function corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = inst
    return c
end

local function makeLabel(parent, text, size, position, color, font, textSize, xAlign)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Text = text or ""
    lbl.Font = font or Enum.Font.GothamMedium
    lbl.TextSize = textSize or 10
    lbl.TextColor3 = color or COLOR_TEXT
    lbl.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    lbl.Size = size
    lbl.Position = position
    lbl.Parent = parent
    return lbl
end

local function makeButton(parent, text, size, position, color, textSize)
    local btn = Instance.new("TextButton")
    btn.Text = text or ""
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = textSize or 8
    btn.TextColor3 = COLOR_TEXT
    btn.BackgroundColor3 = color or COLOR_SURFACE
    btn.BorderSizePixel = 0
    btn.Size = size
    btn.Position = position
    btn.AutoButtonColor = false
    btn.Parent = parent
    corner(btn, 6)
    return btn
end

local function addHover(button, normal, hover)
    button.MouseEnter:Connect(function()
        if button.Active then
            button.BackgroundColor3 = hover
        end
    end)
    button.MouseLeave:Connect(function()
        if button.Active then
            button.BackgroundColor3 = normal
        end
    end)
end

local function cleanError(value)
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

local function fileName(path)
    return tostring(path):match("([^/\\]+)$") or tostring(path)
end

local function extension(path)
    local name = fileName(path)
    return string.lower(name:match("%.([^%.]+)$") or "")
end

local function isFolder(path)
    local fn = isfolder or executorFunction("isfolder")
    if fn then
        local ok, result = pcall(fn, path)
        if ok then
            return result == true
        end
    end
    return tostring(path):sub(-1) == "/"
end

-- ===================== VORTEX BORDER =====================
local function applyVortexBorder(target)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.20, Color3.fromRGB(0, 120, 255)),
        ColorSequenceKeypoint.new(0.40, Color3.fromRGB(255, 230, 0)),
        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 60)),
        ColorSequenceKeypoint.new(0.80, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 120, 0)),
    })
    gradient.Parent = target
    vortexConnection = RunService.RenderStepped:Connect(function()
        if gradient.Parent == nil then
            if vortexConnection then
                vortexConnection:Disconnect()
                vortexConnection = nil
            end
            return
        end
        gradient.Rotation = (os.clock() * 50) % 360
    end)
end

-- ===================== OPTIONAL POST-PROCESS =====================
local function isRestrictedPart(obj)
    if not obj:IsA("BasePart") then
        return false
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and (obj == player.Character or obj:IsDescendantOf(player.Character)) then
            return true
        end
    end
    if Workspace.CurrentCamera and (obj == Workspace.CurrentCamera or obj:IsDescendantOf(Workspace.CurrentCamera)) then
        return true
    end
    return false
end

local function processModelParts(inst)
    if not inst then
        return
    end
    if not ANCHOR_IMPORTED_PARTS then
        return
    end
    if inst:IsA("BasePart") and not isRestrictedPart(inst) then
        inst.Anchored = true
        inst.CanCollide = true
    end
    for _, desc in ipairs(inst:GetDescendants()) do
        if desc:IsA("BasePart") and not isRestrictedPart(desc) then
            desc.Anchored = true
            desc.CanCollide = true
        end
    end
end

local function refreshScripts(model)
    if not REFRESH_IMPORTED_SCRIPTS then
        return
    end
    task.defer(function()
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("LocalScript") then
                local enabled = desc.Enabled
                desc.Enabled = false
                task.wait(0.2)
                desc.Enabled = enabled
            end
        end
    end)
end

local function spawnInFront(inst)
    if KEEP_ORIGINAL_TRANSFORM or not SPAWN_IN_FRONT_OF_PLAYER then
        return
    end
    if not LocalPlayer.Character then
        return
    end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end
    local target = hrp.CFrame + hrp.CFrame.LookVector * 6
    if inst:IsA("Model") then
        pcall(function()
            inst:PivotTo(target)
        end)
    elseif inst:IsA("BasePart") then
        pcall(function()
            inst.CFrame = target
        end)
    end
end

-- ===================== NATIVE IMPORT ENGINE =====================
-- Jalur ini mempertahankan engine dari script yang kamu kirim:
-- getobjects(getcustomasset(filePath)) lalu fallback LoadLocalAsset.
local function loadModelFile(filePath)
    local objectsToInsert = {}
    local errors = {}

    if getObjects then
        local assetPath = filePath
        if getAsset then
            local okAsset, converted = pcall(getAsset, filePath)
            if okAsset and type(converted) == "string" and converted ~= "" then
                assetPath = converted
            end
        end

        local okObjects, result = pcall(getObjects, assetPath)
        if okObjects then
            if type(result) == "table" then
                for _, obj in ipairs(result) do
                    if typeof(obj) == "Instance" then
                        objectsToInsert[#objectsToInsert + 1] = obj
                    end
                end
            elseif typeof(result) == "Instance" then
                objectsToInsert[#objectsToInsert + 1] = result
            end
        else
            errors[#errors + 1] = "getobjects: " .. cleanError(result)
        end
    else
        errors[#errors + 1] = "getobjects tidak tersedia"
    end

    if #objectsToInsert == 0 then
        local candidates = {filePath}
        if getAsset then
            local okAsset, converted = pcall(getAsset, filePath)
            if okAsset and type(converted) == "string" and converted ~= "" and converted ~= filePath then
                candidates[#candidates + 1] = converted
            end
        end

        for _, candidate in ipairs(candidates) do
            local okInsert, result = pcall(function()
                return InsertService:LoadLocalAsset(candidate)
            end)
            if okInsert and result and typeof(result) == "Instance" then
                objectsToInsert[#objectsToInsert + 1] = result
                break
            elseif not okInsert then
                errors[#errors + 1] = "LoadLocalAsset: " .. cleanError(result)
            end
        end
    end

    if #objectsToInsert == 0 then
        return {}, table.concat(errors, " | ")
    end
    return objectsToInsert, nil
end

-- ===================== GUI =====================
pcall(function()
    local oldCore = CoreGui:FindFirstChild(GUI_NAME)
    if oldCore then
        oldCore:Destroy()
    end
end)

pcall(function()
    if LocalPlayer.PlayerGui then
        local oldPlayerGui = LocalPlayer.PlayerGui:FindFirstChild(GUI_NAME)
        if oldPlayerGui then
            oldPlayerGui:Destroy()
        end
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

local toggleIcon = Instance.new("TextButton")
toggleIcon.Name = "ALLZToggle"
toggleIcon.Size = UDim2.new(0, 42, 0, 42)
toggleIcon.Position = UDim2.new(0, 15, 0.5, -21)
toggleIcon.BackgroundColor3 = COLOR_GREEN
toggleIcon.Text = "ALLZ"
toggleIcon.TextColor3 = COLOR_TEXT
toggleIcon.Font = Enum.Font.GothamBold
toggleIcon.TextSize = 9
toggleIcon.Active = true
toggleIcon.Draggable = true
toggleIcon.Parent = screenGui
corner(toggleIcon, 21)
addHover(toggleIcon, COLOR_GREEN, COLOR_GREEN_HOV)
local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(20, 100, 50)
toggleStroke.Thickness = 1.5
toggleStroke.Parent = toggleIcon

local guiContainer = Instance.new("Frame")
guiContainer.Name = "MainFrame"
guiContainer.BackgroundColor3 = COLOR_BG
guiContainer.Size = UDim2.new(0, 300, 0, 390)
guiContainer.Position = UDim2.new(0.5, -150, 0.5, -195)
guiContainer.Active = true
guiContainer.Draggable = true
guiContainer.Parent = screenGui
corner(guiContainer, 10)
local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 2.5
mainStroke.Parent = guiContainer
applyVortexBorder(mainStroke)

toggleIcon.MouseButton1Click:Connect(function()
    guiContainer.Visible = not guiContainer.Visible
end)

makeLabel(guiContainer, "ALLZ // IMPORTER", UDim2.new(0.7, 0, 0, 18), UDim2.new(0, 14, 0, 10), COLOR_TEXT, Enum.Font.GothamBold, 11)
makeLabel(guiContainer, KEEP_ORIGINAL_TRANSFORM and "NATIVE / ORIGINAL TRANSFORM" or "NATIVE / CUSTOM TRANSFORM", UDim2.new(0.8, 0, 0, 12), UDim2.new(0, 14, 0, 27), COLOR_MUTED, Enum.Font.Code, 7)

local closeBtn = makeButton(guiContainer, "×", UDim2.new(0, 20, 0, 20), UDim2.new(1, -27, 0, 10), COLOR_GREEN, 12)
addHover(closeBtn, COLOR_GREEN, COLOR_GREEN_HOV)
closeBtn.MouseButton1Click:Connect(function()
    guiContainer.Visible = false
end)

local folderBox = Instance.new("TextBox")
folderBox.BackgroundColor3 = COLOR_SURFACE
folderBox.PlaceholderText = "Folder path (contoh: /storage/emulated/0/Download)"
folderBox.Text = "."
folderBox.Font = Enum.Font.Code
folderBox.TextSize = 8
folderBox.TextColor3 = COLOR_TEXT
folderBox.PlaceholderColor3 = COLOR_MUTED
folderBox.ClearTextOnFocus = false
folderBox.Size = UDim2.new(0, 208, 0, 27)
folderBox.Position = UDim2.new(0, 14, 0, 45)
folderBox.TextXAlignment = Enum.TextXAlignment.Left
folderBox.Parent = guiContainer
corner(folderBox, 6)
local folderPad = Instance.new("UIPadding")
folderPad.PaddingLeft = UDim.new(0, 8)
folderPad.PaddingRight = UDim.new(0, 8)
folderPad.Parent = folderBox

local scanBtn = makeButton(guiContainer, "SCAN", UDim2.new(0, 48, 0, 27), UDim2.new(0, 232, 0, 45), COLOR_GREEN, 8)
addHover(scanBtn, COLOR_GREEN, COLOR_GREEN_HOV)

local searchBox = Instance.new("TextBox")
searchBox.BackgroundColor3 = COLOR_SURFACE
searchBox.PlaceholderText = "Search model files..."
searchBox.Text = ""
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 8
searchBox.TextColor3 = COLOR_TEXT
searchBox.PlaceholderColor3 = COLOR_MUTED
searchBox.ClearTextOnFocus = false
searchBox.Size = UDim2.new(0, 272, 0, 25)
searchBox.Position = UDim2.new(0, 14, 0, 76)
searchBox.Parent = guiContainer
corner(searchBox, 6)
local searchPad = Instance.new("UIPadding")
searchPad.PaddingLeft = UDim.new(0, 8)
searchPad.Parent = searchBox

local function createFilterBtn(text, posX, active)
    local btn = makeButton(guiContainer, text, UDim2.new(0, 84, 0, 21), UDim2.new(0, posX, 0, 108), active and COLOR_GREEN or COLOR_SURFACE, 8)
    return btn
end

local btnAll = createFilterBtn("ALL", 14, true)
local btnRbxm = createFilterBtn("RBXM", 105, false)
local btnRbxmx = createFilterBtn("RBXMX", 196, false)

local fileScroll = Instance.new("ScrollingFrame")
fileScroll.BackgroundTransparency = 1
fileScroll.Position = UDim2.new(0, 14, 0, 137)
fileScroll.Size = UDim2.new(0, 272, 0, 197)
fileScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
fileScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
fileScroll.ScrollBarThickness = 2
fileScroll.Parent = guiContainer

local fileLayout = Instance.new("UIListLayout")
fileLayout.Padding = UDim.new(0, 6)
fileLayout.Parent = fileScroll

local emptyLabel = makeLabel(fileScroll, "Belum ada file. Tekan SCAN.", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 25), COLOR_MUTED, Enum.Font.Gotham, 9, Enum.TextXAlignment.Center)
emptyLabel.TextWrapped = true

local logContainer = Instance.new("Frame")
logContainer.BackgroundColor3 = COLOR_SURFACE
logContainer.Position = UDim2.new(0, 14, 0, 137)
logContainer.Size = UDim2.new(0, 272, 0, 197)
logContainer.Visible = false
logContainer.Parent = guiContainer
corner(logContainer, 6)
makeLabel(logContainer, "EXECUTION LOG", UDim2.new(1, 0, 0, 18), UDim2.new(0, 10, 0, 8), COLOR_GREEN, Enum.Font.GothamBold, 9)

local logScroll = Instance.new("ScrollingFrame")
logScroll.BackgroundTransparency = 1
logScroll.Position = UDim2.new(0, 10, 0, 28)
logScroll.Size = UDim2.new(0, 252, 0, 155)
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.ScrollBarThickness = 2
logScroll.Parent = logContainer
local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0, 4)
logLayout.Parent = logScroll

local function addLog(message, color)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 14)
    lbl.Text = "[ALLZ] " .. tostring(message)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 8
    lbl.TextColor3 = color or COLOR_TEXT
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = logScroll
end

local statusLabel = makeLabel(guiContainer, "Ready.", UDim2.new(1, -28, 0, 13), UDim2.new(0, 14, 1, -57), COLOR_MUTED, Enum.Font.Code, 8)
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd

local refreshBtn = makeButton(guiContainer, "REFRESH", UDim2.new(0, 127, 0, 26), UDim2.new(0, 14, 1, -34), COLOR_GREEN, 8)
local toggleLogBtn = makeButton(guiContainer, "LOGS", UDim2.new(0, 127, 0, 26), UDim2.new(0, 149, 1, -34), COLOR_GREEN, 8)
addHover(refreshBtn, COLOR_GREEN, COLOR_GREEN_HOV)
addHover(toggleLogBtn, COLOR_GREEN, COLOR_GREEN_HOV)

toggleLogBtn.MouseButton1Click:Connect(function()
    logContainer.Visible = not logContainer.Visible
    toggleLogBtn.BackgroundColor3 = logContainer.Visible and COLOR_GREEN_HOV or COLOR_GREEN
end)

local function setStatus(text, color)
    statusLabel.Text = tostring(text)
    statusLabel.TextColor3 = color or COLOR_MUTED
end

-- ===================== LIST/SCAN =====================
local function clearFileRows()
    for _, child in ipairs(fileScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local function setFilterButtonColors()
    btnAll.BackgroundColor3 = currentFilter == "ALL" and COLOR_GREEN or COLOR_SURFACE
    btnRbxm.BackgroundColor3 = currentFilter == "rbxm" and COLOR_GREEN or COLOR_SURFACE
    btnRbxmx.BackgroundColor3 = currentFilter == "rbxmx" and COLOR_GREEN or COLOR_SURFACE
end

local function renderFiles()
    clearFileRows()
    local query = string.lower(searchBox.Text or "")
    local shown = 0

    for _, item in ipairs(foundFiles) do
        local matchesSearch = query == "" or string.find(string.lower(item.name), query, 1, true) ~= nil
        local matchesType = currentFilter == "ALL" or item.ext == string.lower(currentFilter)
        if matchesSearch and matchesType then
            shown = shown + 1
            local card = Instance.new("Frame")
            card.BackgroundColor3 = item.failed and Color3.fromRGB(55, 25, 31) or COLOR_SURFACE
            card.Size = UDim2.new(1, -4, 0, 36)
            card.LayoutOrder = shown
            card.Parent = fileScroll
            corner(card, 6)

            makeLabel(card, item.name, UDim2.new(0.62, 0, 0, 14), UDim2.new(0, 10, 0, 5), COLOR_TEXT, Enum.Font.GothamBold, 8)
            local meta = item.failed and ("ERROR: " .. item.error) or string.upper(item.ext)
            makeLabel(card, meta, UDim2.new(0.62, 0, 0, 10), UDim2.new(0, 10, 0, 20), item.failed and COLOR_RED or COLOR_MUTED, Enum.Font.Gotham, 7)

            local importButton = makeButton(card, item.imported and "AGAIN" or "IMPORT", UDim2.new(0, 56, 0, 20), UDim2.new(1, -62, 0.5, -10), COLOR_GREEN, 7)
            addHover(importButton, COLOR_GREEN, COLOR_GREEN_HOV)
            importButton.MouseButton1Click:Connect(function()
                if importBusy or scanBusy then
                    return
                end
                importBusy = true
                importButton.Active = false
                setStatus("Loading: " .. item.name, COLOR_YELLOW)
                addLog("Loading: " .. item.name, COLOR_YELLOW)

                local objects, err = loadModelFile(item.path)
                if #objects == 0 then
                    item.failed = true
                    item.error = cleanError(err or "native loader tidak mengembalikan object")
                    setStatus("Import gagal: " .. item.error, COLOR_RED)
                    addLog("Failed: " .. item.error, COLOR_RED)
                else
                    local successCount = 0
                    for _, obj in ipairs(objects) do
                        local parentOK, parentError = pcall(function()
                            obj.Parent = Workspace
                        end)
                        if parentOK then
                            processModelParts(obj)
                            spawnInFront(obj)
                            refreshScripts(obj)
                            successCount = successCount + 1
                        else
                            addLog("Parent gagal: " .. cleanError(parentError), COLOR_RED)
                        end
                    end
                    if successCount > 0 then
                        item.imported = true
                        item.failed = false
                        setStatus("Import selesai: " .. item.name, COLOR_GREEN)
                        addLog("Success: " .. item.name, COLOR_GREEN)
                    else
                        item.failed = true
                        item.error = "object gagal diparent ke Workspace"
                        setStatus("Import gagal: " .. item.error, COLOR_RED)
                    end
                end
                importBusy = false
                renderFiles()
            end)
        end
    end

    emptyLabel.Visible = shown == 0
    if shown == 0 then
        emptyLabel.Text = #foundFiles == 0 and "Belum ada file. Tekan SCAN." or "Tidak ada file yang cocok."
    end
end

local function collectFilesFromFolder(folder)
    if not getFiles then
        return {}, "listfiles tidak tersedia"
    end
    local ok, result = pcall(getFiles, folder)
    if not ok then
        return {}, cleanError(result)
    end
    if type(result) ~= "table" then
        return {}, "listfiles tidak mengembalikan table"
    end
    return result, nil
end

local function scanFolder()
    if scanBusy or importBusy then
        return
    end
    scanBusy = true
    scanBtn.Active = false
    refreshBtn.Active = false
    scanBtn.Text = "..."
    refreshBtn.Text = "SCANNING"
    foundFiles = {}
    clearFileRows()
    setStatus("Scanning...", COLOR_YELLOW)
    addLog("Scanning folder: " .. tostring(folderBox.Text), COLOR_YELLOW)

    task.spawn(function()
        local folder = normalizePath(folderBox.Text)
        local paths = {folder}
        if folder == "" or folder == "." then
            paths = {"workspace", "", ".", "./"}
        end

        local files = {}
        local usedPath = folder
        local lastError = nil
        for _, path in ipairs(paths) do
            local result, err = collectFilesFromFolder(path)
            if #result > 0 then
                files = result
                usedPath = path
                break
            end
            lastError = err
        end

        local seen = {}
        for _, filePath in ipairs(files) do
            if #foundFiles >= MAX_FILES then
                break
            end
            local normalized = normalizePath(filePath)
            local ext = extension(normalized)
            local key = string.lower(normalized)
            if (ext == "rbxm" or ext == "rbxmx") and not seen[key] then
                seen[key] = true
                foundFiles[#foundFiles + 1] = {
                    path = normalized,
                    name = fileName(normalized),
                    ext = ext,
                    imported = false,
                    failed = false,
                }
            end
        end

        table.sort(foundFiles, function(a, b)
            return string.lower(a.name) < string.lower(b.name)
        end)
        renderFiles()
        scanBtn.Active = true
        refreshBtn.Active = true
        scanBtn.Text = "SCAN"
        refreshBtn.Text = "REFRESH"
        scanBusy = false

        if #foundFiles == 0 then
            local detail = lastError and (" " .. cleanError(lastError)) or ""
            setStatus("Tidak ada RBXM/RBXMX di " .. tostring(usedPath) .. "." .. detail, COLOR_YELLOW)
            addLog("No model files found.", COLOR_YELLOW)
        else
            setStatus("Scan selesai: " .. tostring(#foundFiles) .. " file ditemukan.", COLOR_GREEN)
            addLog("Scan complete: " .. tostring(#foundFiles), COLOR_GREEN)
        end
    end)
end

btnAll.MouseButton1Click:Connect(function()
    currentFilter = "ALL"
    setFilterButtonColors()
    renderFiles()
end)
btnRbxm.MouseButton1Click:Connect(function()
    currentFilter = "rbxm"
    setFilterButtonColors()
    renderFiles()
end)
btnRbxmx.MouseButton1Click:Connect(function()
    currentFilter = "rbxmx"
    setFilterButtonColors()
    renderFiles()
end)
searchBox:GetPropertyChangedSignal("Text"):Connect(renderFiles)
scanBtn.MouseButton1Click:Connect(scanFolder)
refreshBtn.MouseButton1Click:Connect(scanFolder)

addLog("ALLZ native importer ready.", COLOR_GREEN)
setStatus("Ready. Isi folder lalu tekan SCAN.", COLOR_MUTED)
scanFolder()
