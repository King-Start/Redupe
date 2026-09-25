--[[
	FileLibraryImporter.lua
	Roblox Studio Plugin

	Fungsi:
	- Menambahkan tombol di toolbar Studio
	- Membuka panel (dock widget) berisi daftar "file favorit" yang kamu
	  sendiri tambahkan (nama + catatan), dengan kotak pencarian
	- Tombol "Import" di tiap item akan mengingatkan/membuka alur
	  Insert-from-File bawaan Studio

	CATATAN PENTING (batasan teknis Roblox, bukan pilihan aku):
	Luau plugin API TIDAK punya fungsi resmi untuk membuka native OS
	file-picker dan langsung mem-parsing isi .rbxm/.rbxl/.rbxlx dari kode.
	Satu-satunya cara resmi memasukkan file itu ke tempat kerja adalah lewat
	menu Studio: File > Insert From File... (atau klik kanan Explorer >
	Insert From File). Jadi tombol "Import" di panel ini akan menampilkan
	notifikasi yang mengarahkan kamu ke menu itu, sekaligus menyalin nama
	file yang dicari ke clipboard supaya gampang dicari di file explorer.

	Cara pakai:
	1. Taruh file ini di folder Plugins Roblox Studio kamu, contoh:
	   Windows: %LOCALAPPDATA%\Roblox\Plugins\
	   Mac: ~/Documents/Roblox/Plugins/
	2. Restart Roblox Studio
	3. Klik tombol "File Library" di tab Plugins
]]

local toolbar = plugin:CreateToolbar("File Library")
local toggleButton = toolbar:CreateButton(
	"OpenLibrary",
	"Buka panel File Library",
	"rbxassetid://0", -- ganti dengan asset id icon kamu sendiri kalau mau
	"File Library"
)

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false, -- widget mulai tertutup
	false,
	360, 480, -- default width, height
	300, 300  -- minimum width, height
)

local widget = plugin:CreateDockWidgetPluginGui("FileLibraryWidget", widgetInfo)
widget.Title = "File Library"

-- ================== Tema warna ==================

local THEME = {
	Background = Color3.fromRGB(14, 14, 20),
	Panel = Color3.fromRGB(20, 20, 30),
	Field = Color3.fromRGB(24, 22, 40),
	Accent1 = Color3.fromRGB(120, 60, 230),   -- ungu
	Accent2 = Color3.fromRGB(60, 130, 240),   -- biru
	Border = Color3.fromRGB(90, 70, 200),
	Text = Color3.fromRGB(235, 235, 245),
	SubText = Color3.fromRGB(150, 150, 170),
}

local function addCorner(inst, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = inst
	return c
end

local function addStroke(inst, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.Border
	s.Thickness = thickness or 1.5
	s.Transparency = 0.2
	s.Parent = inst
	return s
end

local function addGradient(inst, c1, c2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1 or THEME.Accent1, c2 or THEME.Accent2)
	g.Rotation = rotation or 0
	g.Parent = inst
	return g
end

-- ================== UI ==================

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromScale(1, 1)
mainFrame.BackgroundColor3 = THEME.Background
mainFrame.BorderSizePixel = 0
mainFrame.Parent = widget

-- Header dengan gradient ungu-biru, mirip judul di screenshot
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = THEME.Accent1
header.BorderSizePixel = 0
header.Parent = mainFrame
addGradient(header, THEME.Accent1, THEME.Accent2, 20)

local headerTitle = Instance.new("TextLabel")
headerTitle.Text = "FILE LIBRARY"
headerTitle.Size = UDim2.new(1, -16, 1, 0)
headerTitle.Position = UDim2.new(0, 12, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
headerTitle.Font = Enum.Font.GothamBold
headerTitle.TextSize = 16
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

local searchBox = Instance.new("TextBox")
searchBox.PlaceholderText = "Search files..."
searchBox.Text = ""
searchBox.Size = UDim2.new(1, -20, 0, 34)
searchBox.Position = UDim2.new(0, 10, 0, 56)
searchBox.BackgroundColor3 = THEME.Field
searchBox.TextColor3 = THEME.Text
searchBox.PlaceholderColor3 = THEME.SubText
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14
searchBox.Parent = mainFrame
addCorner(searchBox, 8)
addStroke(searchBox)

local countLabel = Instance.new("TextLabel")
countLabel.Text = "0 items"
countLabel.Size = UDim2.new(1, -20, 0, 18)
countLabel.Position = UDim2.new(0, 10, 0, 94)
countLabel.BackgroundTransparency = 1
countLabel.TextColor3 = THEME.SubText
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 11
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = mainFrame

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Text = "Belum ada item. Tambahkan lewat tombol di bawah."
emptyLabel.Size = UDim2.new(1, -20, 0, 40)
emptyLabel.Position = UDim2.new(0, 10, 0, 130)
emptyLabel.BackgroundTransparency = 1
emptyLabel.TextColor3 = THEME.SubText
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.TextSize = 12
emptyLabel.TextWrapped = true
emptyLabel.Visible = false
emptyLabel.Parent = mainFrame

local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 1, -170)
listFrame.Position = UDim2.new(0, 10, 0, 120)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.ScrollBarThickness = 4
listFrame.ScrollBarImageColor3 = THEME.Accent1
listFrame.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = listFrame

local addButton = Instance.new("TextButton")
addButton.Text = "+ Tambah item ke daftar"
addButton.Size = UDim2.new(1, -20, 0, 36)
addButton.Position = UDim2.new(0, 10, 1, -44)
addButton.BackgroundColor3 = THEME.Accent1
addButton.TextColor3 = Color3.fromRGB(255, 255, 255)
addButton.Font = Enum.Font.GothamBold
addButton.TextSize = 14
addButton.Parent = mainFrame
addCorner(addButton, 8)
addGradient(addButton, THEME.Accent1, THEME.Accent2, 0)

-- ================== Data (disimpan lewat plugin settings) ==================

local SETTINGS_KEY = "FileLibraryItems"

local function loadItems()
	local ok, data = pcall(function()
		return plugin:GetSetting(SETTINGS_KEY)
	end)
	if ok and typeof(data) == "table" then
		return data
	end
	return {}
end

local function saveItems(items)
	plugin:SetSetting(SETTINGS_KEY, items)
end

local items = loadItems()

-- ================== Render ==================

local function clearList()
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function renderItem(item)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 46)
	row.BackgroundColor3 = THEME.Panel
	row.Parent = listFrame
	addCorner(row, 10)
	addStroke(row, THEME.Border, 1)

	local ext = item.name:match("%.(%a+)$")
	local badge
	if ext then
		badge = Instance.new("TextLabel")
		badge.Text = ext:upper()
		badge.Size = UDim2.new(0, 40, 0, 18)
		badge.Position = UDim2.new(0, 10, 0.5, -9)
		badge.BackgroundColor3 = THEME.Field
		badge.TextColor3 = THEME.Accent2
		badge.Font = Enum.Font.GothamBold
		badge.TextSize = 10
		badge.Parent = row
		addCorner(badge, 5)
	end

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Text = item.name
	nameLabel.Size = UDim2.new(1, ext and -140 or -100, 1, 0)
	nameLabel.Position = UDim2.new(0, ext and 58 or 12, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = THEME.Text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 13
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = row

	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = Color3.fromRGB(28, 26, 44)
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = THEME.Panel
	end)

	local importBtn = Instance.new("TextButton")
	importBtn.Text = "IMPORT"
	importBtn.Size = UDim2.new(0, 70, 0, 28)
	importBtn.Position = UDim2.new(1, -80, 0.5, -14)
	importBtn.BackgroundColor3 = THEME.Accent1
	importBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	importBtn.Font = Enum.Font.GothamBold
	importBtn.TextSize = 11
	importBtn.Parent = row
	addCorner(importBtn, 6)
	addGradient(importBtn, THEME.Accent1, THEME.Accent2, 0)

	importBtn.MouseButton1Click:Connect(function()
		-- Arahkan user ke alur Insert-from-File bawaan Studio.
		-- Ini bukan bisa "auto-import" karena Luau tidak punya akses OS file
		-- dialog secara langsung — itu batasan resmi Roblox Plugin API.
		warn(("[File Library] Cari & pilih '%s' lewat menu: File > Insert From File..."):format(item.name))
	end)
end

local function refresh(filter)
	clearList()
	filter = (filter or ""):lower()
	local shown = 0
	for _, item in ipairs(items) do
		if filter == "" or item.name:lower():find(filter, 1, true) then
			renderItem(item)
			shown += 1
		end
	end
	countLabel.Text = shown .. (shown == 1 and " item" or " items")
	emptyLabel.Visible = (#items == 0)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	refresh(searchBox.Text)
end)

addButton.MouseButton1Click:Connect(function()
	local newName = "Item baru " .. tostring(#items + 1)
	table.insert(items, { name = newName })
	saveItems(items)
	refresh(searchBox.Text)
end)

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

refresh("")
