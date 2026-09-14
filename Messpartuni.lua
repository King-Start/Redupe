--  oo_       .-.    W  W  wWw    wWw wWw \\\  /// 
-- /  _)-<  c(O_O)c (O)(O) (O)    (O) (O)_((O)(O)) 
-- \__ `.  ,'.---.`,  ||   ( \    / ) / __)| \ ||  
--    `. |/ /|_|_|\ \ | \   \ \  / / / (   ||\\||  
--    _| || \_____/ | |  `. /  \/  \(  _)  || \ |  
-- ,-'   |'. `---' .`(.-.__)\ `--' / \ \_  ||  ||  
--(_..--'   `-...-'   `-'    `-..-'   \__)(_/  \_) 
--         Powered by solven studio 2026
 
 
if not plugin then
    return
end
 
local Selection = game:GetService("Selection")
local GeometryService = game:GetService("GeometryService")
local AssetService = game:GetService("AssetService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local StudioService = game:GetService("StudioService")
local SerializationService = game:GetService("SerializationService")
local EncodingService = game:GetService("EncodingService")
 
local PLUGIN_ID = "SOLVEN_UnionToMesh_V1"
local BUILD = "2026-08-31 SolidMesh Parser V1.0 FULL"
local MAX_ANALYZE = 120
 
local function safeGetSetting(key, fallback)
    local ok, value = pcall(function()
        return plugin:GetSetting(PLUGIN_ID .. "_" .. key)
    end)
    if ok and value ~= nil then
        return value
    end
    return fallback
end
 
local function safeSetSetting(key, value)
    pcall(function()
        plugin:SetSetting(PLUGIN_ID .. "_" .. key, value)
    end)
end
 
local settings = {
scanDescendants = safeGetSetting("ScanDescendants", true),
replaceOriginal = safeGetSetting("ReplaceOriginal", true),
preserveChildren = safeGetSetting("PreserveChildren", true),
}
 
local toolbar = plugin:CreateToolbar("UNION > MESH SOLVEN")
local toolbarButton = toolbar:CreateButton(
"UnionToMesh",
"Convert Union / CSG objects to MeshPart and inspect polygon counts",
"rbxassetid://90841794914982",
"Union > Mesh"
)
toolbarButton.ClickableWhenViewportHidden = true
 
local widgetInfo = DockWidgetPluginGuiInfo.new(
Enum.InitialDockState.Float,
false,
false,
430,
600,
340,
430
)
local widget = plugin:CreateDockWidgetPluginGui(PLUGIN_ID, widgetInfo)
widget.Title = "SOLVEN Union > Mesh Converter • V1.0"
widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
 
local COLORS = {
bg = Color3.fromRGB(20, 22, 27),
panel = Color3.fromRGB(28, 31, 38),
panel2 = Color3.fromRGB(34, 38, 47),
stroke = Color3.fromRGB(58, 64, 76),
text = Color3.fromRGB(239, 242, 248),
muted = Color3.fromRGB(157, 166, 181),
accent = Color3.fromRGB(255, 145, 44),
accent2 = Color3.fromRGB(220, 104, 25),
good = Color3.fromRGB(75, 200, 125),
medium = Color3.fromRGB(239, 188, 65),
high = Color3.fromRGB(240, 115, 68),
bad = Color3.fromRGB(229, 74, 82),
}
 
local function new(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end
 
local function corner(parent, radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, parent)
end
 
local function stroke(parent, color, thickness, transparency)
    return new("UIStroke", {
    Color = color or COLORS.stroke,
    Thickness = thickness or 1,
    Transparency = transparency or 0,
    }, parent)
end
 
local root = new("Frame", {
Name = "Root",
Size = UDim2.fromScale(1, 1),
BackgroundColor3 = COLORS.bg,
BorderSizePixel = 0,
}, widget)
 
new("UIPadding", {
PaddingTop = UDim.new(0, 14),
PaddingBottom = UDim.new(0, 14),
PaddingLeft = UDim.new(0, 14),
PaddingRight = UDim.new(0, 14),
}, root)
 
local header = new("Frame", {
Name = "Header",
Size = UDim2.new(1, 0, 0, 64),
BackgroundTransparency = 1,
}, root)
 
new("TextLabel", {
Name = "Title",
Size = UDim2.new(1, -96, 0, 29),
Position = UDim2.new(0, 0, 0, 0),
BackgroundTransparency = 1,
Font = Enum.Font.GothamBold,
Text = "UNION  >  MESHPART",
TextColor3 = COLORS.text,
TextSize = 18,
TextXAlignment = Enum.TextXAlignment.Left,
}, header)
 
new("TextLabel", {
Name = "Subtitle",
Size = UDim2.new(1, -10, 0, 24),
Position = UDim2.new(0, 0, 0, 30),
BackgroundTransparency = 1,
Font = Enum.Font.Gotham,
Text = "Persistent converter + exact mesh poly analyzer",
TextColor3 = COLORS.muted,
TextSize = 12,
TextXAlignment = Enum.TextXAlignment.Left,
}, header)
 
local selectionBadge = new("TextLabel", {
Name = "SelectionBadge",
AnchorPoint = Vector2.new(1, 0),
Position = UDim2.new(1, 0, 0, 2),
Size = UDim2.new(0, 88, 0, 25),
BackgroundColor3 = COLORS.panel2,
BorderSizePixel = 0,
Font = Enum.Font.GothamSemibold,
Text = "0 selected",
TextColor3 = COLORS.muted,
TextSize = 11,
}, header)
corner(selectionBadge, 7)
stroke(selectionBadge, COLORS.stroke, 1, 0.2)
 
local summary = new("Frame", {
Name = "Summary",
Position = UDim2.new(0, 0, 0, 68),
Size = UDim2.new(1, 0, 0, 78),
BackgroundColor3 = COLORS.panel,
BorderSizePixel = 0,
}, root)
corner(summary, 10)
stroke(summary, COLORS.stroke, 1, 0.25)
 
local summaryGrid = new("UIGridLayout", {
CellPadding = UDim2.new(0, 7, 0, 7),
CellSize = UDim2.new(0.5, -4, 0, 30),
FillDirectionMaxCells = 2,
HorizontalAlignment = Enum.HorizontalAlignment.Center,
VerticalAlignment = Enum.VerticalAlignment.Center,
SortOrder = Enum.SortOrder.LayoutOrder,
}, summary)
new("UIPadding", {
PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7),
PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7),
}, summary)
 
local function makeMetric(name, order)
    local box = new("Frame", {
    Name = name,
    LayoutOrder = order,
    BackgroundColor3 = COLORS.panel2,
    BorderSizePixel = 0,
    }, summary)
    corner(box, 7)
    local label = new("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold,
    Text = name .. ": 0",
    TextColor3 = COLORS.text,
    TextSize = 11,
    }, box)
    return label
end
 
local metricUnions = makeMetric("CSG", 1)
local metricMeshes = makeMetric("MeshParts", 2)
local metricTriangles = makeMetric("Triangles", 3)
local metricVertices = makeMetric("Vertices", 4)
 
local optionsFrame = new("Frame", {
Name = "Options",
Position = UDim2.new(0, 0, 0, 154),
Size = UDim2.new(1, 0, 0, 76),
BackgroundTransparency = 1,
}, root)
 
local function makeToggle(text, xScale, key, settingName)
    local button = new("TextButton", {
    Name = key,
    Position = UDim2.new(xScale, xScale == 0 and 0 or 4, 0, 0),
    Size = UDim2.new(0.5, -4, 0, 32),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "",
    }, optionsFrame)
    corner(button, 8)
    stroke(button, COLORS.stroke, 1, 0.25)
 
    local box = new("Frame", {
    Name = "Box",
    Position = UDim2.new(0, 9, 0.5, -7),
    Size = UDim2.fromOffset(14, 14),
    BorderSizePixel = 0,
    }, button)
    corner(box, 4)
 
    local check = new("TextLabel", {
    Name = "Check",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "✓",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 10,
    }, box)
 
    new("TextLabel", {
    Position = UDim2.new(0, 31, 0, 0),
    Size = UDim2.new(1, -36, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = text,
    TextColor3 = COLORS.text,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    }, button)
 
    local function render()
        box.BackgroundColor3 = settings[key] and COLORS.accent or COLORS.panel2
        check.Visible = settings[key]
    end
 
    button.MouseButton1Click:Connect(function()
        settings[key] = not settings[key]
        render()
        safeSetSetting(settingName, settings[key])
    end)
 
    render()
    return button
end
 
makeToggle("Scan descendants", 0, "scanDescendants", "ScanDescendants")
makeToggle("Replace originals", 0.5, "replaceOriginal", "ReplaceOriginal")
 
local preserveToggle = new("TextButton", {
Name = "preserveChildren",
Position = UDim2.new(0, 0, 0, 39),
Size = UDim2.new(1, 0, 0, 32),
BackgroundColor3 = COLORS.panel,
BorderSizePixel = 0,
AutoButtonColor = false,
Text = "",
}, optionsFrame)
corner(preserveToggle, 8)
stroke(preserveToggle, COLORS.stroke, 1, 0.25)
local preserveBox = new("Frame", {
Position = UDim2.new(0, 9, 0.5, -7),
Size = UDim2.fromOffset(14, 14),
BorderSizePixel = 0,
}, preserveToggle)
corner(preserveBox, 4)
local preserveCheck = new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
Font = Enum.Font.GothamBold, Text = "✓", TextSize = 10,
TextColor3 = Color3.new(1, 1, 1),
}, preserveBox)
new("TextLabel", {
Position = UDim2.new(0, 31, 0, 0), Size = UDim2.new(1, -36, 1, 0),
BackgroundTransparency = 1, Font = Enum.Font.Gotham,
Text = "Preserve children / attachments / constraints", TextColor3 = COLORS.text,
TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
}, preserveToggle)
local function renderPreserve()
    preserveBox.BackgroundColor3 = settings.preserveChildren and COLORS.accent or COLORS.panel2
    preserveCheck.Visible = settings.preserveChildren
end
preserveToggle.MouseButton1Click:Connect(function()
    settings.preserveChildren = not settings.preserveChildren
    renderPreserve()
    safeSetSetting("PreserveChildren", settings.preserveChildren)
end)
renderPreserve()
 
local actionFrame = new("Frame", {
Name = "Actions",
Position = UDim2.new(0, 0, 0, 239),
Size = UDim2.new(1, 0, 0, 42),
BackgroundTransparency = 1,
}, root)
 
local analyzeButton = new("TextButton", {
Name = "Analyze",
Size = UDim2.new(0.36, -4, 1, 0),
BackgroundColor3 = COLORS.panel2,
BorderSizePixel = 0,
AutoButtonColor = false,
Font = Enum.Font.GothamBold,
Text = "ANALYZE POLY",
TextColor3 = COLORS.text,
TextSize = 11,
}, actionFrame)
corner(analyzeButton, 9)
stroke(analyzeButton, COLORS.stroke, 1, 0.1)
 
local convertButton = new("TextButton", {
Name = "Convert",
Position = UDim2.new(0.36, 4, 0, 0),
Size = UDim2.new(0.64, -4, 1, 0),
BackgroundColor3 = COLORS.accent,
BorderSizePixel = 0,
AutoButtonColor = false,
Font = Enum.Font.GothamBold,
Text = "CONVERT MESH",
TextColor3 = Color3.fromRGB(255, 255, 255),
TextSize = 11,
}, actionFrame)
corner(convertButton, 9)
local convertGradient = new("UIGradient", {
Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, COLORS.accent),
ColorSequenceKeypoint.new(1, COLORS.accent2),
}),
Rotation = 90,
}, convertButton)
 
local statusLabel = new("TextLabel", {
Name = "Status",
Position = UDim2.new(0, 0, 0, 288),
Size = UDim2.new(1, 0, 0, 28),
BackgroundTransparency = 1,
Font = Enum.Font.Gotham,
Text = "Select a Union, MeshPart, Model, or Folder.",
TextColor3 = COLORS.muted,
TextSize = 11,
TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd,
}, root)
 
local resultsHeader = new("Frame", {
Name = "ResultsHeader",
Position = UDim2.new(0, 0, 0, 318),
Size = UDim2.new(1, 0, 0, 28),
BackgroundTransparency = 1,
}, root)
new("TextLabel", {
Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1,
Font = Enum.Font.GothamBold, Text = "ANALYZER RESULTS", TextColor3 = COLORS.text,
TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
}, resultsHeader)
local analysisHint = new("TextLabel", {
AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1,
Font = Enum.Font.Gotham, Text = "exact faces / vertices", TextColor3 = COLORS.muted,
TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right,
}, resultsHeader)
 
local results = new("ScrollingFrame", {
Name = "Results",
Position = UDim2.new(0, 0, 0, 348),
Size = UDim2.new(1, 0, 1, -348),
BackgroundColor3 = COLORS.panel,
BorderSizePixel = 0,
ScrollBarThickness = 4,
ScrollBarImageColor3 = COLORS.accent,
CanvasSize = UDim2.fromOffset(0, 0),
AutomaticCanvasSize = Enum.AutomaticSize.None,
}, root)
corner(results, 10)
stroke(results, COLORS.stroke, 1, 0.25)
new("UIPadding", {
PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
}, results)
local resultsLayout = new("UIListLayout", {
Padding = UDim.new(0, 7),
SortOrder = Enum.SortOrder.LayoutOrder,
}, results)
resultsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    results.CanvasSize = UDim2.fromOffset(0, resultsLayout.AbsoluteContentSize.Y + 16)
end)
 
local function setStatus(text, tone)
    statusLabel.Text = text
    if tone == "good" then
        statusLabel.TextColor3 = COLORS.good
    elseif tone == "bad" then
        statusLabel.TextColor3 = COLORS.bad
    elseif tone == "warn" then
        statusLabel.TextColor3 = COLORS.medium
    else
        statusLabel.TextColor3 = COLORS.muted
    end
end
 
local function clearResults()
    for _, child in ipairs(results:GetChildren()) do
        if child ~= resultsLayout and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end
 
local function formatInt(value)
    if value == nil then
        return "N/A"
    end
    local s = tostring(math.floor(value + 0.5))
    local sign, int = s:match("^([%-]?)(%d+)$")
    if not int then
        return s
    end
    local formatted = int:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. formatted
end
 
local function complexityFor(triangles)
    if not triangles then
        return "UNKNOWN", COLORS.muted
    elseif triangles <= 5000 then
        return "LOW", COLORS.good
    elseif triangles <= 15000 then
        return "MEDIUM", COLORS.medium
    elseif triangles <= 30000 then
        return "HIGH", COLORS.high
    else
        return "VERY HIGH", COLORS.bad
    end
end
 
local function objectKind(obj)
    if obj:IsA("UnionOperation") then
        return "UNION"
    elseif obj:IsA("NegateOperation") then
        return "NEGATE"
    elseif obj:IsA("PartOperation") then
        return "CSG"
    elseif obj:IsA("MeshPart") then
        return "MESH"
    elseif obj:IsA("BasePart") then
        return "PART"
    end
    return obj.ClassName:upper()
end
 
local function addResultCard(obj, triangles, vertices, errorText)
    local card = new("Frame", {
    Name = "ResultCard",
    Size = UDim2.new(1, -4, 0, 66),
    BackgroundColor3 = COLORS.panel2,
    BorderSizePixel = 0,
    }, results)
    corner(card, 8)
 
    local badgeText, badgeColor = complexityFor(triangles)
    local kind = objectKind(obj)
    local nameText = obj.Name
    if #nameText > 38 then
        nameText = string.sub(nameText, 1, 35) .. "..."
    end
 
    new("TextLabel", {
    Position = UDim2.new(0, 10, 0, 7),
    Size = UDim2.new(1, -105, 0, 19),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold,
    Text = nameText,
    TextColor3 = COLORS.text,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)
 
    local badge = new("TextLabel", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -8, 0, 7),
    Size = UDim2.new(0, 86, 0, 20),
    BackgroundColor3 = badgeColor,
    BackgroundTransparency = 0.82,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = badgeText,
    TextColor3 = badgeColor,
    TextSize = 9,
    }, card)
    corner(badge, 6)
 
    local size = obj:IsA("BasePart") and obj.Size or Vector3.zero
    local detailText
    if errorText then
        detailText = string.format("%s  |  Poly unavailable  |  %s", kind, errorText)
    else
        detailText = string.format(
        "%s  |  Tri: %s  |  Vert: %s  |  %.1f x %.1f x %.1f",
        kind,
        formatInt(triangles),
            formatInt(vertices),
                size.X, size.Y, size.Z
                )
            end
            new("TextLabel", {
            Position = UDim2.new(0, 10, 0, 31),
            Size = UDim2.new(1, -20, 0, 26),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = detailText,
            TextColor3 = errorText and COLORS.high or COLORS.muted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            }, card)
        end
 
        local function collectSelectionObjects(includeBaseParts)
            local selected = Selection:Get()
            local found = {}
            local list = {}
 
            local function consider(obj)
                local eligible = obj:IsA("PartOperation") or obj:IsA("MeshPart")
                if includeBaseParts then
                    eligible = eligible or obj:IsA("BasePart")
                end
                if eligible and not found[obj] then
                    found[obj] = true
                    table.insert(list, obj)
                end
            end
 
            for _, rootObj in ipairs(selected) do
                consider(rootObj)
                if settings.scanDescendants then
                    for _, descendant in ipairs(rootObj:GetDescendants()) do
                        consider(descendant)
                    end
                end
            end
            return list
        end
 
        local function collectConvertible()
            local all = collectSelectionObjects(false)
            local result = {}
            for _, obj in ipairs(all) do
                if obj:IsA("PartOperation") then
                    table.insert(result, obj)
                end
            end
            return result
        end
 
        local function refreshSelectionSummary()
            local selected = Selection:Get()
            selectionBadge.Text = tostring(#selected) .. " selected"
 
            local all = collectSelectionObjects(true)
            local unionCount, meshCount = 0, 0
            for _, obj in ipairs(all) do
                if obj:IsA("PartOperation") then
                    unionCount = unionCount + 1
                elseif obj:IsA("MeshPart") then
                    meshCount = meshCount + 1
                end
            end
            metricUnions.Text = "CSG: " .. formatInt(unionCount)
            metricMeshes.Text = "MeshParts: " .. formatInt(meshCount)
        end
 
        --[[
        CSG extraction note
        -------------------
        Roblox GeometryService MeshPart outputs are currently session-only and their mesh
        content cannot reliably be reopened with CreateEditableMeshAsync. For PartOperation
        conversion we therefore do NOT use FragmentAsync anymore.
 
        The CSG SolidMesh extraction/parser below is adapted from EgoMoose's
        rbx-csg-to-mesh-plugin, and the LZ4 block reader is adapted from llz4.
 
        MIT License - Copyright (c) 2025 EgoMoose
        MIT License - Copyright (c) 2025 RiskoZoSlovenska
        Permission is hereby granted, free of charge, to any person obtaining a copy of
        this software and associated documentation files (the "Software"), to deal in
        the Software without restriction, including without limitation the rights to
        use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
        of the Software, and to permit persons to whom the Software is furnished to do
        so, subject to the following conditions: the above copyright notice and this
        permission notice shall be included in all copies or substantial portions of
        the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
        EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
        EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
        OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
        FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
        THE SOFTWARE.
        ]]
 
        local RBXM_MAGIC = "<roblox!\x89\xff\x0d\x0a\x1a\x0a"
        local ZSTD_HEADER = "\x28\xB5\x2F\xFD"
        local SOLID_PADDING = 14
        local SOLID_HEADER = "SolidMesh\x00\x00\x00\x00"
 
        local function newBufferStream(b)
            local stream = {buffer = b, position = 0}
            function stream:readu8()
                local value = buffer.readu8(self.buffer, self.position)
                self.position = self.position + 1
                return value
            end
            function stream:readu16()
                local value = buffer.readu16(self.buffer, self.position)
                self.position = self.position + 2
                return value
            end
            function stream:readu32()
                local value = buffer.readu32(self.buffer, self.position)
                self.position = self.position + 4
                return value
            end
            function stream:readf32()
                local value = buffer.readf32(self.buffer, self.position)
                self.position = self.position + 4
                return value
            end
            function stream:readString(count)
                local value = buffer.readstring(self.buffer, self.position, count)
                self.position = self.position + count
                return value
            end
            function stream:skip(count)
                self.position = self.position + count
            end
            return stream
        end
 
        -- Minimal LZ4 block decompressor for RBXM chunks. RBXM provides the exact
        -- uncompressed length so this implementation can use a fixed output buffer.
        local function lz4DecompressExact(data, expectedLength)
            local band, rshift = bit32.band, bit32.rshift
            local MIN_MATCH = 4
            local LIT_COUNT_MASK = 15
            local MATCH_LEN_MASK = 15
            local MATCH_LEN_BITS = 4
 
            local dataLength = buffer.len(data)
            local out = buffer.create(expectedLength)
            local pos = 0
            local outNext = 0
 
            while pos < dataLength do
                local token = buffer.readu8(data, pos)
                pos = pos + 1
 
                local literalCount = rshift(token, MATCH_LEN_BITS)
                if literalCount == LIT_COUNT_MASK then
                    local lenPart
                    repeat
                    assert(pos < dataLength, "Invalid LZ4 literal length")
                    lenPart = buffer.readu8(data, pos)
                    pos = pos + 1
                    literalCount = literalCount + lenPart
                    until lenPart < 0xFF
                end
 
                assert(pos + literalCount <= dataLength, "Invalid LZ4 literal range")
                assert(outNext + literalCount <= expectedLength, "LZ4 output overflow")
                if literalCount > 0 then
                    buffer.copy(out, outNext, data, pos, literalCount)
                end
                outNext = outNext + literalCount
                pos = pos + literalCount
 
                if pos >= dataLength then
                    break
                end
 
                assert(pos + 2 <= dataLength, "Invalid LZ4 match offset")
                local matchLength = band(token, MATCH_LEN_MASK)
                local matchOffset = buffer.readu16(data, pos)
                pos = pos + 2
                assert(matchOffset > 0 and matchOffset <= outNext, "Invalid LZ4 back-reference")
 
                if matchLength == MATCH_LEN_MASK then
                    local lenPart
                    repeat
                    assert(pos < dataLength, "Invalid LZ4 match length")
                    lenPart = buffer.readu8(data, pos)
                    pos = pos + 1
                    matchLength = matchLength + lenPart
                    until lenPart < 0xFF
                end
                matchLength = matchLength + MIN_MATCH
                assert(outNext + matchLength <= expectedLength, "LZ4 output overflow")
 
                while matchLength > matchOffset do
                    buffer.copy(out, outNext, out, outNext - matchOffset, matchOffset)
                    outNext = outNext + matchOffset
                    matchLength = matchLength - matchOffset
                end
                if matchLength > 0 then
                    buffer.copy(out, outNext, out, outNext - matchOffset, matchLength)
                    outNext = outNext + matchLength
                end
            end
 
            assert(outNext == expectedLength, string.format("LZ4 size mismatch (%d/%d)", outNext, expectedLength))
            return out
        end
 
        local function decodeRBXMChunk(payload, compressedLength, uncompressedLength)
            if compressedLength == 0 then
                return buffer.fromstring(payload)
            end
            local compressed = buffer.fromstring(payload)
            if compressedLength >= 4 and buffer.readstring(compressed, 0, 4) == ZSTD_HEADER then
                return EncodingService:DecompressBuffer(compressed, Enum.CompressionAlgorithm.Zstd)
            end
            return lz4DecompressExact(compressed, uncompressedLength)
        end
 
        local function extractSolidMeshSharedString(serialized)
            assert(typeof(serialized) == "buffer", "SerializationService returned unexpected data type")
            local stream = newBufferStream(serialized)
            assert(stream:readString(#RBXM_MAGIC) == RBXM_MAGIC, "Serialized RBXM header mismatch")
            local modelVersion = stream:readu16()
            assert(modelVersion == 0, "Unsupported RBXM model version")
            stream:readu32() -- class count
            stream:readu32() -- instance count
            stream:skip(8)
 
            while stream.position + 16 <= buffer.len(serialized) do
                local chunkType = stream:readString(4)
                local compressedLength = stream:readu32()
                local uncompressedLength = stream:readu32()
                stream:skip(4)
                local storedLength = compressedLength ~= 0 and compressedLength or uncompressedLength
                assert(storedLength >= 0 and stream.position + storedLength <= buffer.len(serialized), "Malformed RBXM chunk")
                local payload = stream:readString(storedLength)
 
                if chunkType == "SSTR" then
                    local content = decodeRBXMChunk(payload, compressedLength, uncompressedLength)
                    local s = newBufferStream(content)
                    s:readu32() -- SSTR version
                    local count = s:readu32()
                    for _ = 1, count do
                        s:skip(16) -- hash
                        local length = s:readu32()
                        local shared = s:readString(length)
                        local b = buffer.fromstring(shared)
                        if buffer.len(b) >= SOLID_PADDING + #SOLID_HEADER
                            and buffer.readstring(b, SOLID_PADDING, #SOLID_HEADER) == SOLID_HEADER then
                            return b
                        end
                    end
                elseif chunkType == "END\0" then
                    break
                end
            end
            return nil
        end
 
        local function signedByte(value)
            if value >= 128 then
                return value - 256
            end
            return value
        end
 
        local function readIndexStateMachine(count, stream)
            local index = 0
            local indices = table.create(count)
            for i = 1, count do
                local v0 = stream:readu8()
                if bit32.band(v0, bit32.lshift(1, 7)) == 0 then
                    if bit32.band(v0, bit32.lshift(1, 6)) == 0 then
                        index = index + v0
                    else
                        index = index + signedByte(bit32.bor(v0, 0x80))
                    end
                else
                    local v1 = stream:readu8()
                    local v2 = stream:readu8()
                    index = index + bit32.bor(v2, bit32.lshift(v1, 8), bit32.lshift(bit32.band(v0, 0x7F), 16))
                end
                indices[i] = bit32.band(index, 0x7FFFFF)
            end
            return indices
        end
 
        local function parseSolidMesh(b)
            local stream = newBufferStream(b)
            stream:skip(SOLID_PADDING)
            assert(stream:readString(#SOLID_HEADER) == SOLID_HEADER, "Buffer is not a SolidMesh")
 
            local positions = {}
            local nPositions = stream:readu32()
            stream:readu32()
            for i = 1, nPositions do
                positions[i] = Vector3.new(stream:readf32(), stream:readf32(), stream:readf32())
            end
 
            local normals = {}
            local nNormals = stream:readu32()
            stream:readu32()
            for i = 1, nNormals do
                normals[i] = Vector3.new(stream:readf32(), stream:readf32(), stream:readf32())
            end
 
            -- Unknown pair data in the SolidMesh format (likely UV data).
            local unknown1 = stream:readu32()
            stream:readu32()
            for _ = 1, unknown1 do
                stream:readf32()
                stream:readf32()
            end
 
            local colors = {}
            local nColors = stream:readu32()
            stream:readu32()
            for i = 1, nColors do
                colors[i] = {stream:readf32(), stream:readf32(), stream:readf32()}
            end
 
            local nFacesData = stream:readu32()
            stream:readu32()
            local faces = readIndexStateMachine(nFacesData, stream)
 
            local nFaceNormalsData = stream:readu32()
            stream:readu32()
            local faceNormals = readIndexStateMachine(nFaceNormalsData, stream)
 
            local nFaceUnknownData = stream:readu32()
            stream:readu32()
            if nFaceUnknownData > 0 then
                -- Consume the data so malformed cursor state doesn't hide the useful error.
                pcall(function()
                    readIndexStateMachine(nFaceUnknownData, stream)
                end)
                error("Unsupported SolidMesh face data detected")
            end
 
            local nFaceColorsData = stream:readu32()
            stream:readu32()
            local faceColors = readIndexStateMachine(nFaceColorsData, stream)
 
            return {
            positions = positions,
            normals = normals,
            colors = colors,
            faces = faces,
            faceNormals = faceNormals,
            faceColors = faceColors,
            }
        end
 
        local function solidMeshFromPart(part)
            local localUnion = nil
            local unionOk, unionErr = pcall(function()
                local options = {SplitApart = false}
                if part:IsA("PartOperation") then
                    options.CollisionFidelity = part.CollisionFidelity
                    options.RenderFidelity = part.RenderFidelity
                    options.FluidFidelity = part.FluidFidelity
                end
                local outputs = GeometryService:UnionAsync(part, {}, options)
                localUnion = outputs and outputs[1] or nil
            end)
            if not unionOk or not localUnion then
                return nil, "could not make local CSG copy: " .. tostring(unionErr)
            end
 
            local serialized = nil
            local serializeOk, serializeErr = pcall(function()
                serialized = SerializationService:SerializeInstancesAsync({localUnion})
            end)
            localUnion:Destroy()
            if not serializeOk or not serialized then
                return nil, "could not serialize CSG: " .. tostring(serializeErr)
            end
 
            local solidBuffer = nil
            local extractOk, extractErr = pcall(function()
                solidBuffer = extractSolidMeshSharedString(serialized)
            end)
            if not extractOk or not solidBuffer then
                return nil, "could not locate SolidMesh data: " .. tostring(extractErr or "not found")
            end
 
            local solid = nil
            local parseOk, parseErr = pcall(function()
                solid = parseSolidMesh(solidBuffer)
            end)
            if not parseOk or not solid then
                return nil, "could not parse SolidMesh data: " .. tostring(parseErr)
            end
            return solid, nil
        end
 
        local function buildEditableFromSolid(solid, useColorData)
            local editable = AssetService:CreateEditableMesh()
            if not editable then
                return nil, "EditableMesh memory budget unavailable"
            end
 
            local ok, err = pcall(function()
                local vertexIds = table.create(#solid.positions)
                for i, position in ipairs(solid.positions) do
                    vertexIds[i] = editable:AddVertex(position)
                end
 
                local normalIds = table.create(#solid.normals)
                for i, normal in ipairs(solid.normals) do
                    normalIds[i] = editable:AddNormal(normal)
                end
 
                local colorIds = {}
                if useColorData then
                    for i, rgb in ipairs(solid.colors) do
                        colorIds[i] = editable:AddColor(Color3.new(rgb[1], rgb[2], rgb[3]), 1)
                    end
                end
 
                for i = 1, #solid.faces, 3 do
                    local a = vertexIds[(solid.faces[i] or -1) + 1]
                    local b = vertexIds[(solid.faces[i + 1] or -1) + 1]
                    local c = vertexIds[(solid.faces[i + 2] or -1) + 1]
                    assert(a and b and c, "SolidMesh contains invalid vertex index")
                    local faceId = editable:AddTriangle(a, b, c)
 
                    local n1 = normalIds[(solid.faceNormals[i] or -1) + 1]
                    local n2 = normalIds[(solid.faceNormals[i + 1] or -1) + 1]
                    local n3 = normalIds[(solid.faceNormals[i + 2] or -1) + 1]
                    if n1 and n2 and n3 then
                        editable:SetFaceNormals(faceId, {n1, n2, n3})
                    end
 
                    if useColorData then
                        local c1 = colorIds[(solid.faceColors[i] or -1) + 1]
                        local c2 = colorIds[(solid.faceColors[i + 1] or -1) + 1]
                        local c3 = colorIds[(solid.faceColors[i + 2] or -1) + 1]
                        if c1 and c2 and c3 then
                            editable:SetFaceColors(faceId, {c1, c2, c3})
                        end
                    end
                end
            end)
 
            if not ok then
                editable:Destroy()
                return nil, tostring(err)
            end
            return editable, nil
        end
 
        -- Used only for already-existing MeshParts. PartOperations are analyzed directly
        -- from their serialized SolidMesh data so this no longer touches FragmentAsync.
        local function getEditableMeshFromMeshPart(meshPart)
            local content = meshPart.MeshContent
            local editable = nil
            local ok, err = pcall(function()
                editable = AssetService:CreateEditableMeshAsync(content, {FixedSize = true})
            end)
            if ok and editable then
                return editable, true, nil
            end
            return nil, false, tostring(err or "mesh data unavailable")
        end
 
        local function analyzeMesh(meshPart)
            local editable, shouldDestroy, err = getEditableMeshFromMeshPart(meshPart)
            if not editable then
                return nil, nil, "mesh data blocked/unavailable: " .. tostring(err)
            end
            local faces, vertices
            local faceOk = pcall(function() faces = editable:GetFaces() end)
                local vertexOk = pcall(function() vertices = editable:GetVertices() end)
                    if shouldDestroy then
                        pcall(function() editable:Destroy() end)
                        end
                            if not faceOk or not vertexOk then
                                return nil, nil, "could not read EditableMesh"
                            end
                            return #faces, #vertices, nil
                        end
 
                        local function analyzeObject(obj)
                            if obj:IsA("MeshPart") then
                                return analyzeMesh(obj)
                            elseif obj:IsA("PartOperation") then
                                local solid, err = solidMeshFromPart(obj)
                                if not solid then
                                    return nil, nil, err
                                end
                                return math.floor(#solid.faces / 3), #solid.positions, nil
                            end
                            return nil, nil, "not a mesh/CSG object"
                        end
 
                        local busy = false
 
                        local function setBusy(value)
                            busy = value
                            analyzeButton.Active = not value
                            convertButton.Active = not value
                            analyzeButton.TextTransparency = value and 0.45 or 0
                            convertButton.TextTransparency = value and 0.45 or 0
                            convertGradient.Enabled = true
                        end
 
                        local function runAnalysis()
                            if busy then return end
                            setBusy(true)
                            clearResults()
                            metricTriangles.Text = "Triangles: ..."
                            metricVertices.Text = "Vertices: ..."
 
                            task.spawn(function()
                                local targets = collectSelectionObjects(false)
                                if #targets == 0 then
                                    metricTriangles.Text = "Triangles: 0"
                                    metricVertices.Text = "Vertices: 0"
                                    setStatus("No Union/CSG or MeshPart found in the current selection.", "warn")
                                    setBusy(false)
                                    return
                                end
 
                                local analyzeCount = math.min(#targets, MAX_ANALYZE)
                                local totalFaces, totalVertices, successful = 0, 0, 0
                                for i = 1, analyzeCount do
                                    local obj = targets[i]
                                    setStatus(string.format("Analyzing %d/%d: %s", i, analyzeCount, obj.Name))
                                    local faces, vertices, err = analyzeObject(obj)
                                    if faces and vertices then
                                        totalFaces = totalFaces + faces
                                        totalVertices = totalVertices + vertices
                                        successful = successful + 1
                                    end
                                    addResultCard(obj, faces, vertices, err)
                                    task.wait()
                                end
 
                                metricTriangles.Text = "Triangles: " .. formatInt(totalFaces)
                                metricVertices.Text = "Vertices: " .. formatInt(totalVertices)
                                if #targets > MAX_ANALYZE then
                                    setStatus(string.format("Analyzed first %d of %d mesh/CSG objects. Selection is very large.", MAX_ANALYZE, #targets), "warn")
                                elseif successful == #targets then
                                    setStatus(string.format("Analysis complete: %s triangles across %d object(s).", formatInt(totalFaces), successful), "good")
                                else
                                    setStatus(string.format("Analysis complete: %d/%d object(s) returned poly data.", successful, #targets), "warn")
                                end
                                setBusy(false)
                            end)
                        end
 
                        local COPY_PROPERTIES = {
                        "Anchored", "CanCollide", "CanQuery", "CanTouch", "CastShadow",
                        "CollisionGroup", "CustomPhysicalProperties", "Massless", "RootPriority",
                        "Transparency", "Reflectance", "Material", "MaterialVariant", "Color",
                        "Locked", "Archivable", "PivotOffset",
                        }
 
                        local function copyProperties(source, destination)
                            for _, property in ipairs(COPY_PROPERTIES) do
                                pcall(function()
                                    destination[property] = source[property]
                                end)
                            end
                            pcall(function()
                                destination.CollisionFidelity = source.CollisionFidelity
                            end)
                            pcall(function()
                                destination.RenderFidelity = source.RenderFidelity
                            end)
                            pcall(function()
                                destination.FluidFidelity = source.FluidFidelity
                            end)
                        end
 
                        local function copyAttributesAndTags(source, destination)
                            local ok, attributes = pcall(function()
                                return source:GetAttributes()
                            end)
                            if ok then
                                for name, value in pairs(attributes) do
                                    pcall(function()
                                        destination:SetAttribute(name, value)
                                    end)
                                end
                            end
 
                            local tagsOk, tags = pcall(function()
                                return CollectionService:GetTags(source)
                            end)
                            if tagsOk then
                                for _, tag in ipairs(tags) do
                                    pcall(function()
                                        CollectionService:AddTag(destination, tag)
                                    end)
                                end
                            end
                        end
 
                        local function preserveGeometryConnections(source, outputs, primary)
                            -- Keep joints and WeldConstraints connected to the replacement MeshPart.
                            -- This version intentionally avoids CalculateConstraintsToPreserve because
                            -- its recommendation record shape can vary between Studio builds.
                            local jointsOk, joints = pcall(function()
                                return source:GetJoints()
                            end)
                            if jointsOk and type(joints) == "table" then
                                for _, joint in ipairs(joints) do
                                    pcall(function()
                                        local part0 = joint.Part0
                                        local part1 = joint.Part1
                                        if part0 == source then
                                            joint.Part0 = primary
                                        end
                                        if part1 == source then
                                            joint.Part1 = primary
                                        end
                                    end)
                                end
                            end
 
                            local parent = source.Parent
                            if parent == nil then
                                return
                            end
 
                            local descendantsOk, descendants = pcall(function()
                                return parent:GetDescendants()
                            end)
                            if not descendantsOk or type(descendants) ~= "table" then
                                return
                            end
 
                            for _, item in ipairs(descendants) do
                                if item:IsA("WeldConstraint") then
                                    pcall(function()
                                        local part0 = item.Part0
                                        local part1 = item.Part1
                                        if part0 == source then
                                            item.Part0 = primary
                                        end
                                        if part1 == source then
                                            item.Part1 = primary
                                        end
                                    end)
                                end
                            end
                        end
 
                        local function moveRemainingChildren(source, primary)
                            for _, child in ipairs(source:GetChildren()) do
                                pcall(function()
                                    child.Parent = primary
                                end)
                            end
                        end
 
                        -- Persistent conversion pipeline.
                        -- The source CSG is parsed directly into an EditableMesh, then uploaded as a real
                        -- Mesh asset. CreateAssetAsync in local-plugin context defaults to the logged-in
                        -- Studio user, intentionally avoiding group Create Asset permission failures.
                        local function buildUserAssetRequest(source)
                            return {
                            Name = source.Name .. "_Mesh",
                            Description = "Mesh generated by SOLVEN STUDIO Union > Mesh V3",
                            }
                        end
 
                        local function createMeshPartFromAsset(assetId, source)
                            local persistent = nil
                            local lastError = nil
                            for attempt = 1, 10 do
                                local ok, createdOrError = pcall(function()
                                    return AssetService:CreateMeshPartAsync(Content.fromAssetId(assetId), {
                                    CollisionFidelity = source.CollisionFidelity,
                                    RenderFidelity = source.RenderFidelity,
                                    FluidFidelity = source.FluidFidelity,
                                    })
                                end)
                                if ok and createdOrError then
                                    persistent = createdOrError
                                    break
                                end
                                lastError = createdOrError
                                if attempt < 10 then
                                    task.wait(math.min(0.3 * attempt, 1.5))
                                end
                            end
                            if not persistent then
                                return nil, "uploaded mesh could not be loaded: " .. tostring(lastError)
                            end
                            persistent:SetAttribute("solvenstudioMeshAssetId", assetId)
                            return persistent, nil
                        end
 
                        local function uploadEditableAsMesh(editable, source)
                            local uploadOk, result, assetIdOrError = pcall(function()
                                return AssetService:CreateAssetAsync(editable, Enum.AssetType.Mesh, buildUserAssetRequest(source))
                            end)
                            if not uploadOk then
                                return nil, "mesh upload call failed: " .. tostring(result)
                            end
                            if result ~= Enum.CreateAssetResult.Success then
                                return nil, "mesh upload failed: " .. tostring(result) .. " / " .. tostring(assetIdOrError)
                            end
                            local assetId = tonumber(assetIdOrError)
                            if not assetId or assetId <= 0 then
                                return nil, "mesh upload returned an invalid asset id"
                            end
                            return createMeshPartFromAsset(assetId, source)
                        end
 
                        local function convertOne(source)
                            local originalParent = source.Parent
                            if not originalParent then
                                return nil, "source has no parent"
                            end
 
                            local solid, solidErr = solidMeshFromPart(source)
                            if not solid then
                                return nil, solidErr
                            end
 
                            local useColorData = false
                            pcall(function()
                                useColorData = source:IsA("UnionOperation") and not source.UsePartColor
                            end)
 
                            local editable, editableErr = buildEditableFromSolid(solid, useColorData)
                            if not editable then
                                return nil, "could not build EditableMesh: " .. tostring(editableErr)
                            end
 
                            setStatus("Uploading persistent mesh asset: " .. source.Name)
                            local mesh, uploadErr = uploadEditableAsMesh(editable, source)
                            editable:Destroy()
                            if not mesh then
                                return nil, uploadErr
                            end
 
                            copyProperties(source, mesh)
                            copyAttributesAndTags(source, mesh)
                            if useColorData then
                                -- Vertex colors already contain the union colors. White avoids double tinting.
                                mesh.Color = Color3.new(1, 1, 1)
                            end
                            pcall(function() mesh.Size = source.Size end)
                                pcall(function() mesh.CFrame = source.CFrame end)
 
                                    if settings.replaceOriginal then
                                        mesh.Name = source.Name
                                    else
                                        mesh.Name = source.Name .. "_Mesh"
                                    end
                                    mesh.Parent = originalParent
 
                                    if settings.replaceOriginal then
                                        if settings.preserveChildren then
                                            preserveGeometryConnections(source, {mesh}, mesh)
                                            moveRemainingChildren(source, mesh)
                                        end
                                        source:Destroy()
                                    end
 
                                    return {mesh}, nil
                                end
 
                                local function runConversion()
                                    if busy then return end
                                    local targets = collectConvertible()
                                    if #targets == 0 then
                                        setStatus("No Union/CSG object found. Select a Union or a Model/Folder containing one.", "warn")
                                        return
                                    end
 
                                    setBusy(true)
                                    clearResults()
                                    pcall(function()
                                        ChangeHistoryService:SetWaypoint("Before Union to Mesh")
                                    end)
 
                                    task.spawn(function()
                                        local converted = {}
                                        local failed = 0
                                        for i, source in ipairs(targets) do
                                            if source.Parent ~= nil then
                                                setStatus(string.format("Converting %d/%d: %s", i, #targets, source.Name))
                                                local outputs, err = convertOne(source)
                                                if outputs then
                                                    for _, mesh in ipairs(outputs) do
                                                        table.insert(converted, mesh)
                                                    end
                                                else
                                                    failed = failed + 1
                                                    warn("[Union > Mesh] " .. source:GetFullName() .. " failed: " .. tostring(err))
                                                end
                                            end
                                            task.wait()
                                        end
 
                                        if #converted > 0 then
                                            Selection:Set(converted)
                                        end
                                        pcall(function()
                                            ChangeHistoryService:SetWaypoint("Union to Mesh")
                                        end)
 
                                        refreshSelectionSummary()
                                        if #converted > 0 then
                                            local totalFaces, totalVertices, successful = 0, 0, 0
                                            local displayCount = math.min(#converted, MAX_ANALYZE)
                                            for i = 1, displayCount do
                                                local mesh = converted[i]
                                                setStatus(string.format("Reading poly %d/%d: %s", i, displayCount, mesh.Name))
                                                local faces, vertices, err = analyzeMesh(mesh)
                                                if faces and vertices then
                                                    totalFaces = totalFaces + faces
                                                    totalVertices = totalVertices + vertices
                                                    successful = successful + 1
                                                end
                                                addResultCard(mesh, faces, vertices, err)
                                                task.wait()
                                            end
                                            metricTriangles.Text = "Triangles: " .. formatInt(totalFaces)
                                            metricVertices.Text = "Vertices: " .. formatInt(totalVertices)
                                            if failed == 0 then
                                                setStatus(string.format("Done. %d CSG object(s) converted to %d MeshPart(s).", #targets, #converted), "good")
                                            else
                                                setStatus(string.format("Done with %d failure(s). Check Output for details.", failed), "warn")
                                            end
                                        else
                                            metricTriangles.Text = "Triangles: 0"
                                            metricVertices.Text = "Vertices: 0"
                                            setStatus("Conversion failed for every selected CSG object. Check Output.", "bad")
                                        end
                                        setBusy(false)
                                    end)
                                end
 
                                local function hover(button, normalColor, hoverColor)
                                    button.MouseEnter:Connect(function()
                                        if not busy then
                                            button.BackgroundColor3 = hoverColor
                                        end
                                    end)
                                    button.MouseLeave:Connect(function()
                                        button.BackgroundColor3 = normalColor
                                    end)
                                end
                                hover(analyzeButton, COLORS.panel2, Color3.fromRGB(45, 50, 61))
 
                                analyzeButton.MouseButton1Click:Connect(runAnalysis)
                                convertButton.MouseButton1Click:Connect(runConversion)
 
                                Selection.SelectionChanged:Connect(function()
                                    if not busy then
                                        refreshSelectionSummary()
                                    end
                                end)
 
                                widget:GetPropertyChangedSignal("Enabled"):Connect(function()
                                    toolbarButton:SetActive(widget.Enabled)
                                    if widget.Enabled then
                                        refreshSelectionSummary()
                                    end
                                end)
 
                                toolbarButton.Click:Connect(function()
                                    widget.Enabled = not widget.Enabled
                                end)
 
                                refreshSelectionSummary()
                                setStatus("Ready V1.0. Full Get update on discord Solven Studio.")
