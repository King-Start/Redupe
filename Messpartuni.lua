--[[
    RBXM Importer - Studio Lite / executor LocalScript
    Versi bersih, tidak di-obfuscate.

    Cara pakai:
    1. Pastikan executor menyediakan readfile(path).
    2. Masukkan path file .rbxm pada kotak input.
    3. Tekan Import RBXM.

    Catatan:
    - Parser ini membaca RBXM binary normal dan chunk LZ4.
    - Zstandard hanya bisa dipakai bila executor menyediakan fungsi decompressor.
    - Objek hasil dibuat langsung di Workspace, tanpa wrapper tambahan.
    - Script di dalam model dibuat Disabled secara default agar file tidak langsung
      menjalankan kode asing. Ubah DISABLE_IMPORTED_SCRIPTS menjadi false jika perlu.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
if LocalPlayer == nil then
    return
end

local DISABLE_IMPORTED_SCRIPTS = true
local GUI_NAME = "RBXMImporter_StudioLite"
local ORIGINAL_CLASS_ATTRIBUTE = "RBXMOriginalClass"

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
panel.Size = UDim2.new(0, 360, 0, 190)
panel.Position = UDim2.new(0.5, -180, 0.5, -95)
panel.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(90, 90, 110)
panelStroke.Transparency = 0.35
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 14, 0, 8)
title.Size = UDim2.new(1, -28, 0, 26)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "RBXM Importer"
title.Parent = panel

local pathBox = Instance.new("TextBox")
pathBox.Name = "Path"
pathBox.Position = UDim2.new(0, 14, 0, 45)
pathBox.Size = UDim2.new(1, -28, 0, 38)
pathBox.BackgroundColor3 = Color3.fromRGB(43, 43, 52)
pathBox.BorderSizePixel = 0
pathBox.ClearTextOnFocus = false
pathBox.Font = Enum.Font.Code
pathBox.TextSize = 13
pathBox.TextColor3 = Color3.fromRGB(240, 240, 245)
pathBox.PlaceholderColor3 = Color3.fromRGB(145, 145, 155)
pathBox.PlaceholderText = "path file .rbxm, contoh: model.rbxm"
pathBox.Text = "model.rbxm"
pathBox.TextXAlignment = Enum.TextXAlignment.Left
pathBox.Parent = panel

local pathPadding = Instance.new("UIPadding")
pathPadding.PaddingLeft = UDim.new(0, 10)
pathPadding.PaddingRight = UDim.new(0, 10)
pathPadding.Parent = pathBox

local pathCorner = Instance.new("UICorner")
pathCorner.CornerRadius = UDim.new(0, 7)
pathCorner.Parent = pathBox

local importButton = Instance.new("TextButton")
importButton.Name = "Import"
importButton.Position = UDim2.new(0, 14, 0, 91)
importButton.Size = UDim2.new(0, 150, 0, 36)
importButton.BackgroundColor3 = Color3.fromRGB(55, 125, 220)
importButton.BorderSizePixel = 0
importButton.Font = Enum.Font.GothamBold
importButton.TextSize = 13
importButton.TextColor3 = Color3.fromRGB(255, 255, 255)
importButton.Text = "Import RBXM"
importButton.AutoButtonColor = true
importButton.Parent = panel

local importCorner = Instance.new("UICorner")
importCorner.CornerRadius = UDim.new(0, 7)
importCorner.Parent = importButton

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 14, 0, 137)
statusLabel.Size = UDim2.new(1, -28, 0, 40)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextColor3 = Color3.fromRGB(195, 195, 205)
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Text = "Siap. Executor harus menyediakan readfile(path)."
statusLabel.Parent = panel

-- Drag panel tanpa library luar.
do
    local dragging = false
    local dragStart
    local startPosition

    local function update(input)
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end

    title.InputBegan:Connect(function(input)
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

    title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            UserInputService.InputChanged:Connect(function(changedInput)
                if dragging and changedInput == input then
                    update(changedInput)
                end
            end)
        end
    end)
end

local function setStatus(text, color)
    statusLabel.Text = tostring(text)
    statusLabel.TextColor3 = color or Color3.fromRGB(195, 195, 205)
end

local function fail(message)
    error(tostring(message), 0)
end

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
            local chunkReader = Reader.new(chunkData)
            chunkReader:u8() -- version
            local count = chunkReader:u32le()
            local children = chunkReader:referents(count)
            local parents = chunkReader:referents(count)
            for i = 1, count do
                file.parentByRef[children[i]] = parents[i]
            end

        elseif chunkName == "SIGN" then
            -- Signature bytecode tidak diperlukan untuk membuat instance.

        elseif chunkName == "END\0" then
            if chunkData ~= "</roblox>" then
                fail("END chunk RBXM tidak valid")
            end
            break

        else
            fail("Chunk RBXM tidak dikenal: " .. tostring(chunkName))
        end
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

local importing = false

local function importPath(path)
    if path == nil or path:gsub("%s+", "") == "" then
        fail("Masukkan path file .rbxm terlebih dahulu")
    end

    setStatus("Membaca file...", Color3.fromRGB(220, 220, 150))
    local data = readLocalFile(path)
    setStatus("Menganalisis RBXM...", Color3.fromRGB(220, 220, 150))
    local file = decodeRbxm(data)
    setStatus("Membuat instance...", Color3.fromRGB(220, 220, 150))
    local created, failedProperties, failedClasses = importDecodedFile(file)

    local message = string.format(
        "Selesai: %d instance dibuat, %d property dilewati.",
        created,
        failedProperties
    )
    if failedClasses > 0 then
        message = message .. " " .. tostring(failedClasses) .. " class dibuat sebagai Folder pengganti."
    end
    if DISABLE_IMPORTED_SCRIPTS then
        message = message .. " Script di-disable."
    end
    setStatus(message, Color3.fromRGB(130, 230, 160))
end

importButton.MouseButton1Click:Connect(function()
    if importing then
        return
    end
    importing = true
    importButton.Active = false
    importButton.AutoButtonColor = false

    task.spawn(function()
        local ok, err = pcall(function()
            importPath(pathBox.Text)
        end)
        if not ok then
            setStatus("ERROR ASLI: " .. tostring(err), Color3.fromRGB(255, 125, 125))
        end
        importButton.Active = true
        importButton.AutoButtonColor = true
        importing = false
    end)
end)

-- Satu status startup ditampilkan di panel, tanpa spam Output.
setStatus("Siap. Masukkan path .rbxm lalu tekan Import RBXM.")
