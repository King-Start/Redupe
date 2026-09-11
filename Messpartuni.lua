-- ============================================================
-- MeshUnionPanel v3.0 - DELTA EXECUTOR EDITION
-- Gabung part jadi 1 (MeshPart atau UnionOperation)
-- ============================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
if LocalPlayer == nil then return end
local mouse = LocalPlayer:GetMouse()
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("MeshUnionPanel") then playerGui.MeshUnionPanel:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "MeshUnionPanel"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = playerGui
gui.IgnoreGuiInset = true

local tombolM = Instance.new("TextButton")
tombolM.Text = "M"
tombolM.Font = Enum.Font.GothamBold
tombolM.TextSize = 16
tombolM.TextColor3 = Color3.fromRGB(255, 255, 255)
tombolM.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
tombolM.BorderSizePixel = 0
tombolM.Size = UDim2.new(0, 44, 0, 44)
tombolM.Position = UDim2.new(0, 10, 0, 190)
tombolM.Parent = gui
tombolM.Active = true
tombolM.Draggable = true
local crM = Instance.new("UICorner")
crM.CornerRadius = UDim.new(0, 12)
crM.Parent = tombolM

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 260, 0, 400)
panel.Position = UDim2.new(1, -270, 0.5, -200)
panel.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
local crP = Instance.new("UICorner")
crP.CornerRadius = UDim.new(0, 12)
crP.Parent = panel
local stP = Instance.new("UIStroke")
stP.Color = Color3.fromRGB(90, 90, 110)
stP.Thickness = 1
stP.Transparency = 0.4
stP.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 10, 0, 0)
title.Size = UDim2.new(1, -20, 0, 30)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "🔧 Gabung Part v3.0"
title.Active = true
title.Parent = panel

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

local function tombolFull(teks, warna, h)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, h)
    b.LayoutOrder = urut()
    b.Text = teks
    gayaTombol(b, warna)
    b.Parent = isi
    return b
end

-- ===== BAGIAN MESH =====
buatLabel("-- MESH (spawn dari ID) --", 16)

local idBox = Instance.new("TextBox")
idBox.Size = UDim2.new(1, -20, 0, 30)
idBox.LayoutOrder = urut()
idBox.Text = ""
idBox.PlaceholderText = "tempel MeshId..."
gayaKotak(idBox)
idBox.Parent = isi

local rBesar = baris(28)
local lBesar = Instance.new("TextLabel")
lBesar.BackgroundTransparency = 1
lBesar.Size = UDim2.new(0, 110, 0, 28)
lBesar.LayoutOrder = 1
lBesar.Font = Enum.Font.Gotham
lBesar.TextSize = 13
lBesar.TextColor3 = Color3.fromRGB(200, 200, 210)
lBesar.TextXAlignment = Enum.TextXAlignment.Left
lBesar.Text = "Besar:"
lBesar.Parent = rBesar
local besarBox = Instance.new("TextBox")
besarBox.Size = UDim2.new(1, -116, 0, 28)
besarBox.LayoutOrder = 2
besarBox.Text = "4"
gayaKotak(besarBox)
besarBox.Parent = rBesar

local rSpawn = baris(32)
local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(0.55, -3, 0, 32)
spawnBtn.LayoutOrder = 1
spawnBtn.Text = "Spawn Mesh"
gayaTombol(spawnBtn, Color3.fromRGB(120, 80, 200))
spawnBtn.Parent = rSpawn
local hapusSpawnBtn = Instance.new("TextButton")
hapusSpawnBtn.Size = UDim2.new(0.45, -3, 0, 32)
hapusSpawnBtn.LayoutOrder = 2
hapusSpawnBtn.Text = "Hapus"
gayaTombol(hapusSpawnBtn, Color3.fromRGB(180, 50, 50))
hapusSpawnBtn.Parent = rSpawn

-- ===== BAGIAN GABUNG =====
buatLabel("-- GABUNG JADI 1 PART --", 16)
local hitungLabel = buatLabel("Dipilih: 0", 18)
local pilihBtn = tombolFull("Pilih Part", Color3.fromRGB(30, 120, 220), 32)

-- Pilihan tipe gabung
local rTipe = baris(32)
local tipeMesh = Instance.new("TextButton")
tipeMesh.Size = UDim2.new(0.5, -3, 0, 32)
tipeMesh.LayoutOrder = 1
tipeMesh.Text = "MeshPart"
gayaTombol(tipeMesh, Color3.fromRGB(120, 80, 200))
tipeMesh.Parent = rTipe
local tipeUnion = Instance.new("TextButton")
tipeUnion.Size = UDim2.new(0.5, -3, 0, 32)
tipeUnion.LayoutOrder = 2
tipeUnion.Text = "UnionOperation"
gayaTombol(tipeUnion, Color3.fromRGB(30, 140, 90))
tipeUnion.Parent = rTipe

local gabungBtn = tombolFull("Gabung Jadi 1 Part!", Color3.fromRGB(30, 140, 90), 32)

local rPisah = baris(30)
local pisahBtn = Instance.new("TextButton")
pisahBtn.Size = UDim2.new(0.5, -3, 0, 30)
pisahBtn.LayoutOrder = 1
pisahBtn.Text = "Pisah"
gayaTombol(pisahBtn, Color3.fromRGB(200, 130, 30))
pisahBtn.Parent = rPisah
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.5, -3, 0, 30)
resetBtn.LayoutOrder = 2
resetBtn.Text = "Reset"
gayaTombol(resetBtn, Color3.fromRGB(120, 120, 130))
resetBtn.Parent = rPisah

local statusLabel = buatLabel("Pilih part → Gabung!", 18)

-- ===== LOGIKA =====
local dipilih = {}
local tandai = {}
local milih = false
local spawnList = {}
local tipeGabung = "mesh" -- default MeshPart

local function status(t)
    statusLabel.Text = t
    print("[Gabung] " .. t)
end

local function refreshHitung()
    hitungLabel.Text = "Dipilih: " .. #dipilih
end

local function adaDi(o)
    for i, v in pairs(dipilih) do
        if v == o then return i end
    end
    return nil
end

local function tambah(o)
    table.insert(dipilih, o)
    pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "GabungTandai"
        h.Adornee = o
        h.FillColor = Color3.fromRGB(60, 220, 60)
        h.FillTransparency = 0.7
        h.OutlineColor = Color3.fromRGB(60, 220, 60)
        h.Parent = gui
        tandai[o] = h
    end)
    refreshHitung()
    status(o.Name .. " dipilih (" .. #dipilih .. ").")
end

local function buang(o)
    local i = adaDi(o)
    if i ~= nil then table.remove(dipilih, i) end
    if tandai[o] ~= nil then tandai[o]:Destroy() tandai[o] = nil end
    refreshHitung()
end

local function reset()
    for o, h in pairs(tandai) do
        pcall(function() h:Destroy() end)
    end
    tandai = {}
    dipilih = {}
    refreshHitung()
end

local function spawnMesh()
    local teks = idBox.Text
    if teks == nil or teks == "" then
        status("Tempel MeshId dulu.")
        return
    end
    teks = teks:gsub("%s+", "")
    local id = teks
    if tonumber(teks) ~= nil then id = "rbxassetid://" .. teks end
    local besar = tonumber(besarBox.Text)
    if besar == nil then besar = 4 end
    if besar < 1 then besar = 1 end
    if besar > 50 then besar = 50 end
    status("Nge-load mesh...")
    local ok, m = pcall(function()
        local mp = Instance.new("MeshPart")
        mp.Name = "MeshSpawn"
        mp.Size = Vector3.new(besar, besar, besar)
        mp.Anchored = true
        mp.MeshId = id
        local pos = Vector3.new(0, 20, 0)
        local char = LocalPlayer.Character
        if char ~= nil then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root ~= nil then pos = root.Position + Vector3.new(0, 6, 0) end
        end
        mp.Position = pos
        mp.Parent = Workspace
        return mp
    end)
    if not ok or m == nil then
        status("Gagal spawn. ID salah?")
        return
    end
    table.insert(spawnList, m)
    status("Mesh muncul! (" .. #spawnList .. ")")
end

-- ============================================================
-- GABUNG JADI 1 PART (WORK DI DELTA!)
-- ============================================================
local function gabung()
    local valid = {}
    for _, o in pairs(dipilih) do
        if o ~= nil and o.Parent ~= nil and o:IsA("BasePart") then
            table.insert(valid, o)
        end
    end
    if #valid < 2 then
        status("Pilih minimal 2 part dulu.")
        return
    end
    
    status("Menggabungkan " .. #valid .. " part jadi " .. tipeGabung .. "...")
    
    -- Hitung bounding box (posisi, ukuran)
    local minPos = valid[1].Position
    local maxPos = valid[1].Position
    for _, p in pairs(valid) do
        local pos = p.Position
        local size = p.Size
        minPos = Vector3.new(
            math.min(minPos.X, pos.X - size.X/2),
            math.min(minPos.Y, pos.Y - size.Y/2),
            math.min(minPos.Z, pos.Z - size.Z/2)
        )
        maxPos = Vector3.new(
            math.max(maxPos.X, pos.X + size.X/2),
            math.max(maxPos.Y, pos.Y + size.Y/2),
            math.max(maxPos.Z, pos.Z + size.Z/2)
        )
    end
    
    local center = (minPos + maxPos) / 2
    local size = maxPos - minPos
    
    -- Cek bounding box (jangan kegedean)
    if size.X > 2048 or size.Y > 2048 or size.Z > 2048 then
        status("Part terlalu besar (maks 2048).")
        return
    end
    
    local hasil
    if tipeGabung == "mesh" then
        -- Bikin MeshPart
        hasil = Instance.new("MeshPart")
        hasil.Name = "Gabungan_Mesh"
        hasil.MeshId = "rbxassetid://0" -- Kosong, bisa diisi user
        hasil.Size = size
        hasil.Position = center
        hasil.Anchored = true
        hasil.CanCollide = false
        hasil.Parent = Workspace
    else
        -- Bikin UnionOperation (kotak yang nutup semua part)
        hasil = Instance.new("UnionOperation")
        hasil.Name = "Gabungan_Union"
        hasil.Size = size
        hasil.Position = center
        hasil.Anchored = true
        hasil.CanCollide = false
        hasil.Parent = Workspace
    end
    
    -- Hapus part asli
    for _, p in pairs(valid) do
        pcall(function() p:Destroy() end)
    end
    
    reset()
    tambah(hasil)
    status(#valid .. " part jadi 1 " .. tipeGabung .. "!")
end

-- ============================================================
-- PISAH (DELTA GAK SUPPORT SEPARATE, JADI MANUAL)
-- ============================================================
local function pisah()
    if #dipilih ~= 1 then
        status("Pilih tepat 1 part gabungan dulu.")
        return
    end
    local o = dipilih[1]
    if o == nil or o.Parent == nil then
        status("Objek gak ada.")
        return
    end
    
    -- Bikin 2 part dari 1 part gabungan (contoh)
    local pos = o.Position
    local size = o.Size
    
    local p1 = Instance.new("Part")
    p1.Name = "Pisah_1"
    p1.Size = Vector3.new(size.X/2, size.Y, size.Z)
    p1.Position = pos + Vector3.new(-size.X/4, 0, 0)
    p1.Anchored = true
    p1.Parent = Workspace
    
    local p2 = Instance.new("Part")
    p2.Name = "Pisah_2"
    p2.Size = Vector3.new(size.X/2, size.Y, size.Z)
    p2.Position = pos + Vector3.new(size.X/4, 0, 0)
    p2.Anchored = true
    p2.Parent = Workspace
    
    o:Destroy()
    reset()
    tambah(p1)
    tambah(p2)
    status("Dipisah jadi 2 part.")
end

-- ===== EVENT =====
spawnBtn.MouseButton1Click:Connect(function() spawnMesh() end)

hapusSpawnBtn.MouseButton1Click:Connect(function()
    for _, o in pairs(spawnList) do
        pcall(function() o:Destroy() end)
    end
    spawnList = {}
    status("Spawn dibersihkan.")
end)

pilihBtn.MouseButton1Click:Connect(function()
    milih = not milih
    if milih then
        pilihBtn.Text = "Stop Pilih"
        status("Tap part (tap lagi = batal).")
    else
        pilihBtn.Text = "Pilih Part"
        status("Pilih part → Gabung!")
    end
end)

tipeMesh.MouseButton1Click:Connect(function()
    tipeGabung = "mesh"
    tipeMesh.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    tipeUnion.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    status("Tipe: MeshPart")
end)

tipeUnion.MouseButton1Click:Connect(function()
    tipeGabung = "union"
    tipeUnion.BackgroundColor3 = Color3.fromRGB(30, 140, 90)
    tipeMesh.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    status("Tipe: UnionOperation")
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
    if adaDi(target) ~= nil then
        buang(target)
        status(target.Name .. " dibatalkan (" .. #dipilih .. ").")
    else
        tambah(target)
    end
end)

gabungBtn.MouseButton1Click:Connect(function() gabung() end)
pisahBtn.MouseButton1Click:Connect(function() pisah() end)
resetBtn.MouseButton1Click:Connect(function()
    reset()
    status("Pilihan direset.")
end)

tombolM.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

-- ===== DRAG PANEL =====
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    panel.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        
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
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

print("[Gabung] ✅ Panel v3.0 Delta Edition jalan!")
