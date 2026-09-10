-- ============================================================
-- RedupePanel v2.0 - DELTA EXECUTOR EDITION
-- Panel redupe buat scripting di Roblox (jalan di Delta!)
-- ============================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("[Redupe] Gagal: LocalPlayer tidak ditemukan")
    return
end

local mouse = LocalPlayer:GetMouse()
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Hapus GUI lama kalo ada
if playerGui:FindFirstChild("RedupePanel") then
    playerGui.RedupePanel:Destroy()
end

-- ============================================================
-- GUI UTAMA
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "RedupePanel"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = playerGui
gui.IgnoreGuiInset = true

-- Tombol Toggle "R"
local tombolR = Instance.new("TextButton")
tombolR.Text = "R"
tombolR.Font = Enum.Font.GothamBold
tombolR.TextSize = 16
tombolR.TextColor3 = Color3.fromRGB(255, 255, 255)
tombolR.BackgroundColor3 = Color3.fromRGB(30, 120, 220)
tombolR.BorderSizePixel = 0
tombolR.Size = UDim2.new(0, 44, 0, 44)
tombolR.Position = UDim2.new(0, 10, 0, 90)
tombolR.Parent = gui
tombolR.Active = true
tombolR.Draggable = true -- Delta support Draggable

local crR = Instance.new("UICorner")
crR.CornerRadius = UDim.new(0, 12)
crR.Parent = tombolR

-- Panel utama
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 250, 0, 420)
panel.Position = UDim2.new(1, -260, 0.5, -210)
panel.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = gui

local crP = Instance.new("UICorner")
crP.CornerRadius = UDim.new(0, 12)
crP.Parent = panel

local stP = Instance.new("UIStroke")
stP.Color = Color3.fromRGB(90, 90, 110)
stP.Thickness = 1
stP.Transparency = 0.4
stP.Parent = panel

-- Title
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 10, 0, 0)
title.Size = UDim2.new(1, -20, 0, 30)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "🔧 Redupe Panel v2.0"
title.Active = true
title.Parent = panel

-- Container
local isi = Instance.new("Frame")
isi.BackgroundTransparency = 1
isi.BorderSizePixel = 0
isi.Position = UDim2.new(0, 0, 0, 30)
isi.Size = UDim2.new(1, 0, 1, -34)
isi.Parent = panel

local padI = Instance.new("UIPadding")
padI.PaddingLeft = UDim.new(0, 10)
padI.PaddingRight = UDim.new(0, 10)
padI.PaddingTop = UDim.new(0, 4)
padI.PaddingBottom = UDim.new(0, 4)
padI.Parent = isi

local layI = Instance.new("UIListLayout")
layI.Padding = UDim.new(0, 4)
layI.SortOrder = Enum.SortOrder.LayoutOrder
layI.Parent = isi

-- Helper functions
local no = 0
local function urut()
    no = no + 1
    return no
end

local function buatLabel(teks, h)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, -20, 0, h)
    l.LayoutOrder = urut()
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.TextColor3 = Color3.fromRGB(200, 200, 210)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Text = teks
    l.Parent = isi
    return l
end

local function gayaKotak(b)
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 54)
    b.BorderSizePixel = 0
    b.ClearTextOnFocus = false
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
end

local function gayaTombol(b, warna)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.BackgroundColor3 = warna
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
end

local function baris(h)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Size = UDim2.new(1, -20, 0, h)
    f.LayoutOrder = urut()
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Horizontal
    l.Padding = UDim.new(0, 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.VerticalAlignment = Enum.VerticalAlignment.Center
    l.Parent = f
    f.Parent = isi
    return f
end

-- ============================================================
-- UI ELEMENTS
-- ============================================================
local srcLabel = buatLabel("Sumber: -", 18)

local rPilih = baris(30)
local pickBtn = Instance.new("TextButton")
pickBtn.Size = UDim2.new(0.45, -3, 0, 30)
pickBtn.LayoutOrder = 1
pickBtn.Text = "Tap Part"
gayaTombol(pickBtn, Color3.fromRGB(30, 120, 220))
pickBtn.Parent = rPilih

local namaBox = Instance.new("TextBox")
namaBox.Size = UDim2.new(0.55, -3, 0, 30)
namaBox.LayoutOrder = 2
namaBox.Text = ""
namaBox.PlaceholderText = "nama part?"
gayaKotak(namaBox)
namaBox.Parent = rPilih

-- Parameter input
local P = {}
local defs = {{"Jumlah", "7"}, {"Jarak", "4"}, {"Naik", "2"}, {"Putar", "0"}, {"Sudut", "360"}}
for _, d in pairs(defs) do
    local r = baris(28)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(0, 110, 0, 28)
    l.LayoutOrder = 1
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.TextColor3 = Color3.fromRGB(200, 200, 210)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = d[1]
    l.Parent = r
    local b = Instance.new("TextBox")
    b.Size = UDim2.new(1, -116, 0, 28)
    b.LayoutOrder = 2
    b.Text = d[2]
    gayaKotak(b)
    b.Parent = r
    P[d[1]] = b
end

-- Tombol mode
local modeWarna = {
    Garis = Color3.fromRGB(30, 140, 90),
    Lingkaran = Color3.fromRGB(200, 130, 30),
    Tangga = Color3.fromRGB(120, 80, 200),
    Spiral = Color3.fromRGB(200, 60, 120)
}
local btnMode = {}
local modeBaris = {{"Garis", "Lingkaran"}, {"Tangga", "Spiral"}}
for _, pasangan in pairs(modeBaris) do
    local r = baris(32)
    for j, nama in pairs(pasangan) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.5, -3, 0, 32)
        b.LayoutOrder = j
        b.Text = nama
        gayaTombol(b, modeWarna[nama])
        b.Parent = r
        btnMode[nama] = b
    end
end

-- Tombol hapus
local hapusBtn = Instance.new("TextButton")
hapusBtn.Size = UDim2.new(1, -20, 0, 30)
hapusBtn.LayoutOrder = urut()
hapusBtn.Text = "🗑️ Hapus Hasil"
gayaTombol(hapusBtn, Color3.fromRGB(180, 50, 50))
hapusBtn.Parent = isi

-- Tombol Save (KHUSUS DELTA!)
local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1, -20, 0, 30)
saveBtn.LayoutOrder = urut()
saveBtn.Text = "💾 Save ke File"
gayaTombol(saveBtn, Color3.fromRGB(100, 80, 200))
saveBtn.Parent = isi

local statusLabel = buatLabel("1. Tap Part → 2. Atur → 3. Tap Mode", 18)

-- ============================================================
-- LOGIKA
-- ============================================================
local sumber, tandai, milih = nil, nil, false
local hasil = {}

local function status(t)
    statusLabel.Text = t
    print("[Redupe] " .. t)
end

local function angka(box, def)
    local v = tonumber(box.Text)
    if v == nil then return def end
    return v
end

local function rapikan(c)
    if c:IsA("BasePart") then c.Anchored = true end
    for _, d in pairs(c:GetDescendants()) do
        if d:IsA("BasePart") then d.Anchored = true end
    end
end

local function polaGaris(s, n, offset, putar)
    local pivot = s:GetPivot()
    local step = CFrame.new(offset) * CFrame.Angles(0, math.rad(putar), 0)
    local cf = pivot
    for i = 1, n do
        cf = cf * step
        local c = s:Clone()
        c.Parent = Workspace
        rapikan(c)
        c:PivotTo(cf)
        table.insert(hasil, c)
    end
end

local function polaLingkaran(s, n, radius, total, naik)
    local pivot = s:GetPivot()
    local tengah = pivot.Position
    local rot = pivot.Rotation
    local langkah = math.rad(total) / (n + 1)
    for i = 1, n do
        local a = langkah * i
        local pos = tengah + Vector3.new(math.cos(a) * radius, naik * i, math.sin(a) * radius)
        local c = s:Clone()
        c.Parent = Workspace
        rapikan(c)
        c:PivotTo(CFrame.new(pos) * rot * CFrame.Angles(0, a, 0))
        table.insert(hasil, c)
    end
end

local function pilih(o)
    sumber = o
    if tandai ~= nil then tandai:Destroy() tandai = nil end
    pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "PanelTandai"
        h.Adornee = o
        h.FillColor = Color3.fromRGB(0, 170, 255)
        h.FillTransparency = 0.7
        h.OutlineColor = Color3.fromRGB(0, 170, 255)
        h.Parent = gui
        tandai = h
    end)
    srcLabel.Text = "Sumber: " .. o.Name
    status("Sumber: " .. o.Name .. ". Atur, tap mode!")
end

local function jalan(mode)
    if sumber == nil or sumber.Parent == nil then
        status("Pilih sumber dulu ya.")
        return
    end
    if not (sumber:IsA("BasePart") or sumber:IsA("Model")) then
        status("Sumber harus Part/Model.")
        return
    end
    local n = math.floor(angka(P.Jumlah, 7))
    if n < 1 then n = 1 end
    if n > 100 then n = 100 end
    local jarak = angka(P.Jarak, 4)
    local naik = angka(P.Naik, 2)
    local putar = angka(P.Putar, 0)
    local sudut = angka(P.Sudut, 360)

    if mode == "Garis" then
        polaGaris(sumber, n, Vector3.new(jarak, 0, 0), putar)
    elseif mode == "Lingkaran" then
        polaLingkaran(sumber, n, jarak, sudut, 0)
    elseif mode == "Tangga" then
        polaGaris(sumber, n, Vector3.new(jarak, naik, 0), 0)
    else
        polaLingkaran(sumber, n, jarak, sudut, naik)
    end
    status(n .. " copy " .. mode .. " jadi! Total: " .. #hasil)
end

-- ============================================================
-- FITUR SAVE (KHUSUS DELTA!)
-- ============================================================
local function saveHasil()
    if #hasil == 0 then
        status("⚠️ Belum ada hasil untuk di-save!")
        return
    end

    if not writefile then
        status("❌ Executor tidak support writefile!")
        return
    end

    -- Serialize ke JSON
    local data = {
        total = #hasil,
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        parts = {}
    }

    for i, part in ipairs(hasil) do
        local pos = part:GetPivot().Position
        table.insert(data.parts, {
            name = part.Name,
            className = part.ClassName,
            position = {x = pos.X, y = pos.Y, z = pos.Z}
        })
    end

    local json = game:GetService("HttpService"):JSONEncode(data)
    local filename = "Redupe_" .. os.time() .. ".json"
    
    writefile(filename, json)
    status("💾 Tersimpan: " .. filename)
    print("[Redupe] Saved to: " .. filename)
end

-- ============================================================
-- EVENT HANDLERS
-- ============================================================
pickBtn.MouseButton1Click:Connect(function()
    milih = not milih
    if milih then
        pickBtn.Text = "Batal"
        status("Tap 1 part di map...")
    else
        pickBtn.Text = "Tap Part"
        status("1. Tap Part → 2. Atur → 3. Tap Mode")
    end
end)

namaBox.FocusLost:Connect(function(ya)
    if not ya then return end
    local teks = namaBox.Text
    if teks == nil or teks == "" then return end
    local o = Workspace:FindFirstChild(teks, true)
    if o ~= nil and (o:IsA("BasePart") or o:IsA("Model")) then
        pilih(o)
    else
        status("'" .. teks .. "' tidak ketemu.")
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if not milih or gp then return end
    local t = input.UserInputType
    if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
    local target = mouse.Target
    if target == nil or not target:IsA("BasePart") then
        status("Tidak kena part.")
        return
    end
    pilih(target)
    milih = false
    pickBtn.Text = "Tap Part"
end)

for nama, b in pairs(btnMode) do
    b.MouseButton1Click:Connect(function() jalan(nama) end)
end

hapusBtn.MouseButton1Click:Connect(function()
    for _, o in pairs(hasil) do
        pcall(function() o:Destroy() end)
    end
    hasil = {}
    status("Hasil dibersihkan.")
end)

saveBtn.MouseButton1Click:Connect(saveHasil)

tombolR.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

-- ============================================================
-- DRAG PANEL (Delta compatible)
-- ============================================================
local geser, mulai, awal = false, nil, nil
title.InputBegan:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        geser, mulai, awal = true, input.Position, panel.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if geser then
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            local d = input.Position - mulai
            panel.Position = UDim2.new(awal.X.Scale, awal.X.Offset + d.X, awal.Y.Scale, awal.Y.Offset + d.Y)
        end
    end
end)
UIS.InputEnded:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then geser = false end
end)

-- ============================================================
-- LOADSTRING SUPPORT (KHUSUS DELTA!)
-- ============================================================
-- Kalo script ini di-host di GitHub, bisa di-load pake:
-- loadstring(game:HttpGet("URL_SCRIPT"))()

print("[Redupe] ✅ Panel v2.0 Delta Edition jalan!")
