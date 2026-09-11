-- ============================================================
-- Gabung Part v3.1 (diperbaiki)
-- UI v3.0 dipertahankan, mesin gabung/pisah dibenerin:
-- gabung pakai UnionAsync beneran, pisah pakai Separate().
-- Mode "MeshPart" dicabut karena mustahil (part tidak bisa
-- diubah jadi mesh). Buat scripting bawaan Studio Lite.
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
panel.Size = UDim2.new(0, 260, 0, 340)
panel.Position = UDim2.new(1, -270, 0.5, -170)
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
title.Text = "🔧 Gabung Part v3.1"
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

local rGabung = baris(32)
local gabungBtn = Instance.new("TextButton")
gabungBtn.Size = UDim2.new(0.5, -3, 0, 32)
gabungBtn.LayoutOrder = 1
gabungBtn.Text = "Gabung!"
gayaTombol(gabungBtn, Color3.fromRGB(30, 140, 90))
gabungBtn.Parent = rGabung
local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0.5, -3, 0, 32)
copyBtn.LayoutOrder = 2
copyBtn.Text = "Gabung Copy"
gayaTombol(copyBtn, Color3.fromRGB(30, 170, 170))
copyBtn.Parent = rGabung

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

local statusLabel = buatLabel("Pilih part, Gabung!", 18)

-- ===== LOGIKA =====
local dipilih = {}
local tandai = {}
local milih = false
local spawnList = {}

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
-- GABUNG (UnionAsync beneran - hasilnya union kelihatan)
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
    status("Menggabungkan " .. #valid .. " part...")
    local utama = valid[1]
    local lain = {}
    for i = 2, #valid do table.insert(lain, valid[i]) end
    local ok, hasilUnion = pcall(function()
        return utama:UnionAsync(lain)
    end)
    if not ok or hasilUnion == nil then
        status("Gagal gabung. Coba part lain.")
        return
    end
    hasilUnion.Name = "Gabungan"
    hasilUnion.Anchored = true
    hasilUnion.Parent = Workspace
    for _, o in pairs(valid) do
        pcall(function() o:Destroy() end)
    end
    reset()
    tambah(hasilUnion)
    status(#valid .. " part jadi 1 Union!")
end

-- ============================================================
-- GABUNG COPY (asli utuh, yang digabung copy-annya)
-- ============================================================
local function gabungCopy()
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
    status("Nge-copy + gabung " .. #valid .. " part...")
    local klon = {}
    for _, o in pairs(valid) do
        local c = o:Clone()
        c.Parent = Workspace
        c.Anchored = true
        table.insert(klon, c)
    end
    local utama = klon[1]
    local lain = {}
    for i = 2, #klon do table.insert(lain, klon[i]) end
    local ok, hasilUnion = pcall(function()
        return utama:UnionAsync(lain)
    end)
    if not ok or hasilUnion == nil then
        for _, c in pairs(klon) do
            pcall(function() c:Destroy() end)
        end
        status("Gagal gabung. Coba part lain.")
        return
    end
    hasilUnion.Name = "Gabungan_Copy"
    hasilUnion.Anchored = true
    hasilUnion.Parent = Workspace
    for _, c in pairs(klon) do
        pcall(function() c:Destroy() end)
    end
    reset()
    tambah(hasilUnion)
    status("Union copy jadi, asli utuh!")
end

-- ============================================================
-- PISAH (Separate beneran - balik jadi part asli)
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
    if not o:IsA("UnionOperation") then
        status("Itu bukan Union.")
        return
    end
    local ok, hasilPisah = pcall(function()
        return o:Separate()
    end)
    if not ok or hasilPisah == nil then
        status("Gagal pisah.")
        return
    end
    reset()
    for _, p in pairs(hasilPisah) do
        if p:IsA("BasePart") then p.Anchored = true end
        tambah(p)
    end
    status("Dipisah jadi " .. #hasilPisah .. " part.")
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
        status("Pilih part, Gabung!")
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
    if adaDi(target) ~= nil then
        buang(target)
        status(target.Name .. " dibatalkan (" .. #dipilih .. ").")
    else
        tambah(target)
    end
end)

gabungBtn.MouseButton1Click:Connect(function() gabung() end)
copyBtn.MouseButton1Click:Connect(function() gabungCopy() end)
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

print("[Gabung] Panel v3.1 jalan!")
