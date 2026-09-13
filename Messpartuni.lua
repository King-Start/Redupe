-- ============================================================
-- Gabung Part v3.6 (hasil runtime tampil + pulih otomatis)
-- v3.5 + sumber CSG disimpan sebagai template:
-- hasil client CSG memang tidak menyimpan mesh saat Save,
-- jadi sumber tetap ada dan union dibuat ulang setiap mulai Play.
-- part PERTAMA = main (kuning), sisanya = pelubang.
-- Buat scripting bawaan Studio Lite.
-- ============================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local GeometryService = nil
pcall(function() GeometryService = game:GetService("GeometryService") end)
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
panel.Size = UDim2.new(0, 260, 0, 404)
panel.Position = UDim2.new(1, -270, 0.5, -202)
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
title.Text = "🔧 Gabung Part v3.6"
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

local lubangiBtn = tombolFull("Lubangi! (1 = main)", Color3.fromRGB(210, 60, 140), 32)

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

local rGrup = baris(30)
local grupBtn = Instance.new("TextButton")
grupBtn.Size = UDim2.new(0.5, -3, 0, 30)
grupBtn.LayoutOrder = 1
grupBtn.Text = "Grup Model"
gayaTombol(grupBtn, Color3.fromRGB(0, 170, 200))
grupBtn.Parent = rGrup
local bubarBtn = Instance.new("TextButton")
bubarBtn.Size = UDim2.new(0.5, -3, 0, 30)
bubarBtn.LayoutOrder = 2
bubarBtn.Text = "Bubar"
gayaTombol(bubarBtn, Color3.fromRGB(100, 110, 140))
bubarBtn.Parent = rGrup

local statusLabel = buatLabel("Pilih part, Gabung!", 18)

-- ===== LOGIKA =====
local dipilih = {}
local tandai = {}
local milih = false
local spawnList = {}
local sibuk = false

local milikKarakter

local function status(t)
    statusLabel.Text = t
end

-- ============================================================
-- TEMPLATE RUNTIME
-- GeometryService di client menghasilkan PartOperation yang tampil
-- saat Play, tetapi mesh-nya tidak ikut tersimpan ke Edit. Karena itu
-- part sumber dipindah ke model template dan hasil dibuat ulang saat Play.
-- ============================================================
local SUMBER_PREFIX = "__GabungSource_"
local HASIL_ATTR = "GabungRuntimeResult"
local OPERASI_ATTR = "GabungOperation"
local NAMA_ATTR = "GabungResultName"

local function ambilAtribut(o, nama)
    local ok, nilai = pcall(function()
        return o:GetAttribute(nama)
    end)
    if ok then return nilai end
    return nil
end

local function pasangAtribut(o, nama, nilai)
    pcall(function()
        o:SetAttribute(nama, nilai)
    end)
end

local function hasilRuntime(o)
    return ambilAtribut(o, HASIL_ATTR) == true
end

local function csgPart(o)
    local namaKelas = ""
    pcall(function() namaKelas = o.ClassName end)
    return namaKelas == "PartOperation" or namaKelas == "UnionOperation"
end

local function sembunyikanSumber(o)
    pcall(function()
        o.LocalTransparencyModifier = 1
    end)
end

local function tampilkanHasil(o)
    pcall(function()
        o.LocalTransparencyModifier = 0
    end)
end

local function namaModelSumber(operasi, namaHasil)
    return SUMBER_PREFIX .. operasi .. "_" .. namaHasil
end

local function buatModelSumber(operasi, namaHasil, sumber)
    local model = Instance.new("Model")
    model.Name = namaModelSumber(operasi, namaHasil)
    pasangAtribut(model, OPERASI_ATTR, operasi)
    pasangAtribut(model, NAMA_ATTR, namaHasil)
    model.Parent = Workspace
    for _, o in ipairs(sumber) do
        if o ~= nil and o.Parent ~= nil then
            o.Parent = model
            sembunyikanSumber(o)
        end
    end
    return model
end

local function pasangHasil(hasilArr, model, namaHasil)
    for _, u in ipairs(hasilArr) do
        if u ~= nil then
            u.Name = namaHasil
            u.Anchored = true
            pasangAtribut(u, HASIL_ATTR, true)
            u.Parent = model
            tampilkanHasil(u)
        end
    end
end

local function simpanDanTampilkan(operasi, namaHasil, sumber, hasilArr)
    local model = buatModelSumber(operasi, namaHasil, sumber)
    pasangHasil(hasilArr, model, namaHasil)
    return model
end

local function jalankanCSG(operasi, utama, lain)
    if operasi == "Subtract" then
        return GeometryService:SubtractAsync(utama, lain, {SplitApart = false})
    end
    return GeometryService:UnionAsync(utama, lain, {SplitApart = false})
end

local function kumpulkanPilihan()
    local valid = {}
    for _, o in ipairs(dipilih) do
        if o ~= nil and o.Parent ~= nil and o:IsA("BasePart") and not milikKarakter(o) then
            if hasilRuntime(o) then
                return nil, "Hasil runtime pilihannya jangan dipakai ulang; pilih part sumbernya."
            end
            table.insert(valid, o)
        end
    end
    return valid, nil
end

local function refreshHitung()
    if #dipilih == 0 then
        hitungLabel.Text = "Dipilih: 0"
    else
        hitungLabel.Text = "Main: " .. dipilih[1].Name .. " +" .. (#dipilih - 1)
    end
end

local function adaDi(o)
    for i, v in pairs(dipilih) do
        if v == o then return i end
    end
    return nil
end

local function kasihTandai(o, pertama)
    pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "GabungTandai"
        h.Adornee = o
        local warna = Color3.fromRGB(60, 220, 60)
        if pertama then warna = Color3.fromRGB(255, 220, 60) end
        h.FillColor = warna
        h.FillTransparency = 0.7
        h.OutlineColor = warna
        h.Parent = gui
        tandai[o] = h
    end)
end

local function catUlang()
    for o, h in pairs(tandai) do
        pcall(function() h:Destroy() end)
    end
    tandai = {}
    for i, o in pairs(dipilih) do
        kasihTandai(o, i == 1)
    end
end

local function tambah(o)
    table.insert(dipilih, o)
    kasihTandai(o, #dipilih == 1)
    refreshHitung()
    status(o.Name .. " dipilih (" .. #dipilih .. ").")
end

local function buang(o)
    local i = adaDi(o)
    if i ~= nil then table.remove(dipilih, i) end
    catUlang()
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
milikKarakter = function(o)
    local m = o:FindFirstAncestorWhichIsA("Model")
    if m ~= nil and m:FindFirstChildOfClass("Humanoid") ~= nil then
        return true
    end
    return false
end

local function gabung()
    local valid, alasan = kumpulkanPilihan()
    if valid == nil then
        status(alasan)
        return
    end
    if #valid < 2 then
        status("Pilih minimal 2 part dulu.")
        return
    end
    if GeometryService == nil or GeometryService.UnionAsync == nil then
        status("API Union tidak ada di sini.")
        return
    end
    if sibuk then
        status("Tunggu, lagi ngitung...")
        return
    end
    sibuk = true
    status("Menggabungkan " .. #valid .. " part...")
    local utama = valid[1]
    local lain = {}
    for i = 2, #valid do table.insert(lain, valid[i]) end
    local ok, hasilArr = pcall(function()
        return jalankanCSG("Union", utama, lain)
    end)
    if not ok then
        sibuk = false
        local emsg = tostring(hasilArr)
        print("[Gabung] ERROR ASLI: " .. emsg)
        status("Gagal: " .. emsg:sub(1, 48))
        return
    end
    if hasilArr == nil or #hasilArr == 0 then
        sibuk = false
        status("Gagal: hasil kosong.")
        return
    end
    simpanDanTampilkan("Union", "Gabungan", valid, hasilArr)
    sibuk = false
    reset()
    for _, u in ipairs(hasilArr) do
        tambah(u)
    end
    status(#valid .. " part jadi " .. #hasilArr .. " Union! Tampil + pulih otomatis.")
end

-- ============================================================
-- GABUNG COPY (asli utuh, yang digabung copy-annya)
-- ============================================================
local function gabungCopy()
    local valid, alasan = kumpulkanPilihan()
    if valid == nil then
        status(alasan)
        return
    end
    if #valid < 2 then
        status("Pilih minimal 2 part dulu.")
        return
    end
    if GeometryService == nil or GeometryService.UnionAsync == nil then
        status("API Union tidak ada di sini.")
        return
    end
    if sibuk then
        status("Tunggu, lagi ngitung...")
        return
    end
    sibuk = true
    status("Nge-copy + gabung " .. #valid .. " part...")
    local klon = {}
    for _, o in ipairs(valid) do
        local c = o:Clone()
        c.Parent = Workspace
        c.Anchored = true
        table.insert(klon, c)
    end
    local utama = klon[1]
    local lain = {}
    for i = 2, #klon do table.insert(lain, klon[i]) end
    local ok, hasilArr = pcall(function()
        return jalankanCSG("Union", utama, lain)
    end)
    if not ok then
        for _, c in ipairs(klon) do
            pcall(function() c:Destroy() end)
        end
        sibuk = false
        local emsg = tostring(hasilArr)
        print("[Gabung] ERROR ASLI: " .. emsg)
        status("Gagal: " .. emsg:sub(1, 48))
        return
    end
    if hasilArr == nil or #hasilArr == 0 then
        for _, c in ipairs(klon) do
            pcall(function() c:Destroy() end)
        end
        sibuk = false
        status("Gagal: hasil kosong.")
        return
    end
    simpanDanTampilkan("Union", "Gabungan_Copy", klon, hasilArr)
    sibuk = false
    reset()
    for _, u in ipairs(hasilArr) do
        tambah(u)
    end
    status("Union copy jadi, asli utuh + pulih otomatis.")
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
    if not csgPart(o) then
        status("Itu bukan Union.")
        return
    end
    local modelSumber = o.Parent
    local modelRuntime = modelSumber ~= nil and modelSumber:IsA("Model")
        and string.sub(modelSumber.Name, 1, #SUMBER_PREFIX) == SUMBER_PREFIX
    local ok, hasilPisah = pcall(function()
        return o:Separate()
    end)
    if not ok or hasilPisah == nil then
        local emsg = tostring(hasilPisah)
        print("[Gabung] ERROR ASLI: " .. emsg)
        status("Gagal: " .. emsg:sub(1, 48))
        return
    end
    reset()
    for _, p in ipairs(hasilPisah) do
        if p:IsA("BasePart") then
            p.Anchored = true
            tampilkanHasil(p)
            if modelRuntime then p.Parent = Workspace end
        end
        tambah(p)
    end
    if modelRuntime then
        pcall(function() modelSumber:Destroy() end)
    end
    status("Dipisah jadi " .. #hasilPisah .. " part.")
end

local function grup()
    local valid = {}
    for _, o in pairs(dipilih) do
        if o ~= nil and o.Parent ~= nil and o:IsA("BasePart") and not milikKarakter(o) then
            table.insert(valid, o)
        end
    end
    if #valid < 1 then
        status("Pilih part dulu.")
        return
    end
    local m = Instance.new("Model")
    m.Name = "Grup_" .. #valid
    m.Parent = Workspace
    for _, o in pairs(valid) do
        o.Parent = m
    end
    pcall(function() m.PrimaryPart = valid[1] end)
    reset()
    status(#valid .. " part jadi 1 Model!")
end

local function bubar()
    if #dipilih < 1 then
        status("Pilih 1 part dalam grup dulu.")
        return
    end
    local o = dipilih[1]
    if o == nil or o.Parent == nil then
        status("Objek gak ada.")
        return
    end
    local m = o.Parent
    if m == nil or m == Workspace or not m:IsA("Model") then
        status("Itu bukan isi grup.")
        return
    end
    if m:FindFirstChildOfClass("Humanoid") ~= nil then
        status("Itu karakter! Batal.")
        return
    end
    local isi = {}
    for _, c in pairs(m:GetChildren()) do
        table.insert(isi, c)
    end
    for _, c in pairs(isi) do
        c.Parent = Workspace
    end
    local n = #isi
    m:Destroy()
    reset()
    for _, c in pairs(isi) do
        if c:IsA("BasePart") then tambah(c) end
    end
    status("Grup dibubarkan (" .. n .. " isi).")
end

local function lubangi()
    local valid, alasan = kumpulkanPilihan()
    if valid == nil then
        status(alasan)
        return
    end
    if #valid < 2 then
        status("Pilih main + pelubang dulu.")
        return
    end
    if GeometryService == nil or GeometryService.SubtractAsync == nil then
        status("API Lubang tidak ada di sini.")
        return
    end
    if sibuk then
        status("Tunggu, lagi ngitung...")
        return
    end
    sibuk = true
    local namaMain = valid[1].Name
    status("Ngelubangi " .. namaMain .. "...")
    local utama = valid[1]
    local lain = {}
    for i = 2, #valid do table.insert(lain, valid[i]) end
    local ok, hasilArr = pcall(function()
        return jalankanCSG("Subtract", utama, lain)
    end)
    if not ok then
        sibuk = false
        local emsg = tostring(hasilArr)
        print("[Gabung] ERROR ASLI: " .. emsg)
        status("Gagal: " .. emsg:sub(1, 48))
        return
    end
    if hasilArr == nil or #hasilArr == 0 then
        sibuk = false
        status("Gagal: hasil kosong.")
        return
    end
    simpanDanTampilkan("Subtract", "Bolongan", valid, hasilArr)
    sibuk = false
    reset()
    for _, u in ipairs(hasilArr) do
        tambah(u)
    end
    status(namaMain .. " bolong! Tampil + pulih otomatis.")
end

-- ============================================================
-- PULIHKAN HASIL SAAT PLAY
-- ============================================================
local function operasiDariModel(model)
    local op = ambilAtribut(model, OPERASI_ATTR)
    if op == "Union" or op == "Subtract" then return op end
    if string.sub(model.Name, 1, #SUMBER_PREFIX + 8) == SUMBER_PREFIX .. "Subtract" then
        return "Subtract"
    end
    return "Union"
end

local function namaHasilDariModel(model, operasi)
    local nama = ambilAtribut(model, NAMA_ATTR)
    if type(nama) == "string" and nama ~= "" then return nama end
    if operasi == "Subtract" then return "Bolongan" end
    return "Gabungan"
end

local function buangHasilLama(model)
    for _, o in ipairs(model:GetChildren()) do
        if o:IsA("BasePart") then
            local nama = o.Name
            if hasilRuntime(o)
            or (csgPart(o) and (nama == "Gabungan" or nama == "Bolongan" or nama == "Gabungan_Copy")) then
                pcall(function() o:Destroy() end)
            end
        end
    end
end

local function pulihkanModel(model)
    local operasi = operasiDariModel(model)
    local namaHasil = namaHasilDariModel(model, operasi)
    buangHasilLama(model)
    local sumber = {}
    for _, o in ipairs(model:GetChildren()) do
        if o:IsA("BasePart") then
            table.insert(sumber, o)
            sembunyikanSumber(o)
        end
    end
    if #sumber < 2 then return false end
    local utama = sumber[1]
    local lain = {}
    for i = 2, #sumber do table.insert(lain, sumber[i]) end
    local ok, hasilArr = pcall(function()
        return jalankanCSG(operasi, utama, lain)
    end)
    if not ok then
        local emsg = tostring(hasilArr)
        print("[Gabung] ERROR ASLI saat pulih: " .. emsg)
        return false
    end
    if hasilArr == nil or #hasilArr == 0 then return false end
    pasangHasil(hasilArr, model, namaHasil)
    return true
end

local function bersihkanCangkangLama()
    for _, o in ipairs(Workspace:GetChildren()) do
        if o:IsA("BasePart") and csgPart(o)
        and (o.Name == "Gabungan" or o.Name == "Bolongan" or o.Name == "Gabungan_Copy")
        and not hasilRuntime(o) then
            pcall(function() o:Destroy() end)
        end
    end
end

local function pulihkanSemua()
    if GeometryService == nil or GeometryService.UnionAsync == nil then return end
    local daftar = {}
    for _, o in ipairs(Workspace:GetChildren()) do
        if o:IsA("Model")
        and string.sub(o.Name, 1, #SUMBER_PREFIX) == SUMBER_PREFIX then
            table.insert(daftar, o)
        end
    end
    if #daftar == 0 then return end
    sibuk = true
    local berhasil = 0
    for _, model in ipairs(daftar) do
        if model.Parent ~= nil and pulihkanModel(model) then
            berhasil = berhasil + 1
        end
    end
    sibuk = false
    if berhasil > 0 then
        status("Pulih " .. berhasil .. " hasil CSG; sekarang tampil.")
    end
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
lubangiBtn.MouseButton1Click:Connect(function() lubangi() end)
grupBtn.MouseButton1Click:Connect(function() grup() end)
bubarBtn.MouseButton1Click:Connect(function() bubar() end)
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

print("[Gabung] Panel v3.6 jalan!")
bersihkanCangkangLama()
pulihkanSemua()
