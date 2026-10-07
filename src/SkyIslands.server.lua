--[[
	جزر السماء | SKY ISLANDS
	ماب أوبي/مغامرة كامل يُبنى بالكود بالكامل، ضعه كـ Script داخل ServerScriptService.

	المراحل:
	  0) الهب (جزيرة البداية) مع نافورة وبوابة
	  1) جزر الزهور       - قفز بين جزر عائمة
	  2) المنصات المتحركة - منصات تتحرك يميناً/يساراً وأعلى/أسفل
	  3) بركان الدوّامات  - جزر بركانية وعصي دوّارة فوق الحمم
	  4) برج النيون       - منصات جامبينج باد (قفز عالي) حتى القمة
	  القمة) كأس الفوز + ألعاب نارية + مكافأة
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local StarterPlayer = game:GetService("StarterPlayer")

------------------------------------------------------------------------
-- إعدادات عامة
------------------------------------------------------------------------
local RNG = Random.new(2024)
local HUB_TOP = Vector3.new(0, 120, 0)
local KILL_Y = 74

StarterPlayer.CharacterWalkSpeed = 18
StarterPlayer.CharacterUseJumpPower = true
StarterPlayer.CharacterJumpPower = 55

for _, child in ipairs(Workspace:GetChildren()) do
	if child.Name == "Baseplate" or child.Name == "SkyIslands" then
		child:Destroy()
	end
end

local Map = Instance.new("Folder")
Map.Name = "SkyIslands"
Map.Parent = Workspace

local STYLE_GRASS = {
	top = Color3.fromRGB(106, 190, 86), topMat = Enum.Material.Grass,
	dirt = Color3.fromRGB(124, 92, 70), rock = Color3.fromRGB(110, 112, 130),
}
local STYLE_VOLCANO = {
	top = Color3.fromRGB(52, 46, 54), topMat = Enum.Material.Slate,
	dirt = Color3.fromRGB(80, 48, 40), rock = Color3.fromRGB(38, 34, 38),
}
local STYLE_GOLD = {
	top = Color3.fromRGB(255, 226, 120), topMat = Enum.Material.Sand,
	dirt = Color3.fromRGB(200, 150, 80), rock = Color3.fromRGB(150, 120, 90),
}
local FLOWER_COLORS = {
	Color3.fromRGB(255, 105, 180), Color3.fromRGB(255, 220, 70), Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(170, 120, 255), Color3.fromRGB(255, 130, 80), Color3.fromRGB(90, 200, 255),
}

local pathPoints = {} -- نقاط المسار (لتجنب وضع الديكور فوقها)
local spinners = {}
local coins = {}

------------------------------------------------------------------------
-- أدوات البناء
------------------------------------------------------------------------
local function pt(props, parent, tagName)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent or Map
	if tagName then
		CollectionService:AddTag(p, tagName)
	end
	return p
end

local function disc(pos, radius, thickness, color, material, parent)
	return pt({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(thickness, radius * 2, radius * 2),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2),
		Color = color,
		Material = material,
	}, parent)
end

local function ball(pos, d, color, material, parent, collide)
	return pt({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(d, d, d),
		Position = pos,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		CanCollide = collide ~= false,
	}, parent)
end

local function addPathPoint(p)
	table.insert(pathPoints, p)
end

local function advance(from, fromR, toR, gap, dir, rise)
	return from + dir * (fromR + toR + gap) + Vector3.new(0, rise or 0, 0)
end

-- جزيرة عائمة: عشب + تراب + صخور متدرجة للأسفل
local function island(top, radius, style)
	style = style or STYLE_GRASS
	local m = Instance.new("Model")
	m.Name = "Island"
	m.Parent = Map
	disc(top - Vector3.new(0, 1, 0), radius, 2, style.top, style.topMat, m)
	disc(top - Vector3.new(0, 3.5, 0), radius * 0.92, 3, style.dirt, Enum.Material.Ground, m)
	disc(top - Vector3.new(0, 6.5, 0), radius * 0.70, 3, style.rock, Enum.Material.Slate, m)
	disc(top - Vector3.new(0, 9.5, 0), radius * 0.45, 3, style.rock, Enum.Material.Slate, m)
	disc(top - Vector3.new(0, 12.0, 0), radius * 0.22, 2.5, style.rock, Enum.Material.Slate, m)
	addPathPoint(top)
	return m
end

local function tree(base, parent, scale)
	scale = scale or 1
	local h = 7 * scale
	pt({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(h, 1.4 * scale, 1.4 * scale),
		CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(110, 76, 50),
		Material = Enum.Material.Wood,
	}, parent)
	for i = 1, 3 do
		local d = (9 - i * 1.8) * scale
		local g = Color3.fromRGB(70 + i * 14, 165 + i * 8, 80)
		ball(base + Vector3.new(0, h - 1 + (i - 1) * 2.2 * scale, 0), d, g, Enum.Material.Grass, parent, false)
	end
end

local function flower(pos, parent)
	local c = FLOWER_COLORS[RNG:NextInteger(1, #FLOWER_COLORS)]
	pt({
		Size = Vector3.new(0.2, 1.4, 0.2), Position = pos + Vector3.new(0, 0.7, 0),
		Color = Color3.fromRGB(60, 150, 60), CanCollide = false,
	}, parent)
	ball(pos + Vector3.new(0, 1.5, 0), 0.9, c, Enum.Material.SmoothPlastic, parent, false)
end

local function lamp(pos, parent, fire)
	pt({
		Size = Vector3.new(0.6, 6, 0.6), Position = pos + Vector3.new(0, 3, 0),
		Color = Color3.fromRGB(40, 40, 50), Material = Enum.Material.Metal,
	}, parent)
	local bulb = ball(pos + Vector3.new(0, 6.4, 0), 1.6,
		fire and Color3.fromRGB(255, 120, 30) or Color3.fromRGB(255, 235, 170), Enum.Material.Neon, parent, false)
	local l = Instance.new("PointLight")
	l.Range = 18
	l.Brightness = 1.6
	l.Color = fire and Color3.fromRGB(255, 130, 50) or Color3.fromRGB(255, 225, 150)
	l.Parent = bulb
	if fire then
		local f = Instance.new("Fire")
		f.Size = 4
		f.Heat = 6
		f.Parent = bulb
	end
end

local function scatter(model, center, radius, o)
	local function spot(a, b)
		local ang = RNG:NextNumber(0, math.pi * 2)
		local r = radius * RNG:NextNumber(a, b)
		return center + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
	end
	for _ = 1, o.trees or 0 do
		tree(spot(0.6, 0.88), model, RNG:NextNumber(0.8, 1.3))
	end
	for _ = 1, o.flowers or 0 do
		flower(spot(0.15, 0.92), model)
	end
	local n = o.lamps or 0
	for i = 1, n do
		local ang = (i / n) * math.pi * 2 + (o.lampOffset or 0)
		lamp(center + Vector3.new(math.cos(ang), 0, math.sin(ang)) * radius * 0.86, model, o.fire)
	end
end

local function coin(pos)
	local c = pt({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 3, 3),
		CFrame = CFrame.new(pos),
		Color = Color3.fromRGB(255, 205, 40),
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, Map, "Coin")
	table.insert(coins, { part = c, pos = pos, phase = RNG:NextNumber(0, 6) })
end

local function textSign(size, cf, text, face, bg, fg)
	local p = pt({ Size = size, CFrame = cf, Color = bg, Material = Enum.Material.Metal })
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.TextColor3 = fg
	t.Text = text
	t.Parent = sg
	return p
end

local function billboard(parent, text, color)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 240, 0, 50)
	bb.StudsOffset = Vector3.new(0, 7, 0)
	bb.MaxDistance = 140
	bb.Parent = parent
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.3
	t.Text = text
	t.Parent = bb
end

local function checkpoint(top, stage, label, style)
	local m = island(top, 11, style)
	scatter(m, top, 11, { flowers = style == STYLE_GRASS and 16 or 0, lamps = 3, fire = style == STYLE_VOLCANO })
	local sp = Instance.new("SpawnLocation")
	sp.Size = Vector3.new(9, 1, 9)
	sp.Anchored = true
	sp.Neutral = true
	sp.Duration = 0
	sp.TopSurface = Enum.SurfaceType.Smooth
	sp.Material = Enum.Material.Neon
	sp.Color = Color3.fromRGB(80, 220, 255)
	sp.CFrame = CFrame.new(top + Vector3.new(0, 0.5, 0))
	sp:SetAttribute("Stage", stage)
	for _, d in ipairs(sp:GetChildren()) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	sp.Parent = m
	CollectionService:AddTag(sp, "Checkpoint")
	billboard(sp, label, Color3.fromRGB(255, 255, 255))
	return sp
end

local function jumpPad(pos, power, parent)
	local p = pt({
		Size = Vector3.new(6, 0.8, 6), Position = pos + Vector3.new(0, 0.4, 0),
		Color = Color3.fromRGB(60, 255, 120), Material = Enum.Material.Neon,
	}, parent, "JumpPad")
	p:SetAttribute("Power", power)
	local e = Instance.new("ParticleEmitter")
	e.Rate = 25
	e.Lifetime = NumberRange.new(0.8, 1.2)
	e.Speed = NumberRange.new(8, 14)
	e.SpreadAngle = Vector2.new(10, 10)
	e.Color = ColorSequence.new(Color3.fromRGB(120, 255, 170))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	e.LightEmission = 1
	e.Parent = p
	return p
end

------------------------------------------------------------------------
-- الهب (جزيرة البداية)
------------------------------------------------------------------------
local hubSpawn
do
	local m = island(HUB_TOP, 44, STYLE_GRASS)
	m.Name = "Hub"
	scatter(m, HUB_TOP, 44, { trees = 9, flowers = 70, lamps = 8 })

	-- ممشى حجري
	disc(HUB_TOP + Vector3.new(0, 0.12, 0), 12, 0.3, Color3.fromRGB(190, 190, 200), Enum.Material.Cobblestone, m)

	-- نافورة
	disc(HUB_TOP + Vector3.new(0, 1, 0), 8, 2, Color3.fromRGB(170, 170, 185), Enum.Material.Marble, m)
	disc(HUB_TOP + Vector3.new(0, 1.6, 0), 6.6, 1.4, Color3.fromRGB(60, 160, 255), Enum.Material.Glass, m).Transparency = 0.3
	pt({ Size = Vector3.new(1.6, 6, 1.6), Position = HUB_TOP + Vector3.new(0, 4, 0),
		Color = Color3.fromRGB(200, 200, 215), Material = Enum.Material.Marble }, m)
	local spout = pt({ Size = Vector3.new(1, 1, 1), Position = HUB_TOP + Vector3.new(0, 7.5, 0),
		Transparency = 1, CanCollide = false }, m)
	local jet = Instance.new("ParticleEmitter")
	jet.Rate = 90
	jet.Lifetime = NumberRange.new(1.4, 2)
	jet.Speed = NumberRange.new(22, 30)
	jet.SpreadAngle = Vector2.new(12, 12)
	jet.Acceleration = Vector3.new(0, -40, 0)
	jet.Color = ColorSequence.new(Color3.fromRGB(150, 210, 255))
	jet.Size = NumberSequence.new(0.7)
	jet.LightEmission = 0.6
	jet.Parent = spout

	-- مكان الظهور
	hubSpawn = Instance.new("SpawnLocation")
	hubSpawn.Size = Vector3.new(12, 1, 12)
	hubSpawn.Anchored = true
	hubSpawn.Neutral = true
	hubSpawn.Duration = 0
	hubSpawn.TopSurface = Enum.SurfaceType.Smooth
	hubSpawn.Material = Enum.Material.Neon
	hubSpawn.Color = Color3.fromRGB(255, 190, 70)
	hubSpawn.CFrame = CFrame.new(HUB_TOP + Vector3.new(0, 0.5, 24))
	hubSpawn:SetAttribute("Stage", 0)
	for _, d in ipairs(hubSpawn:GetChildren()) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	hubSpawn.Parent = m
	CollectionService:AddTag(hubSpawn, "Checkpoint")

	-- بوابة المرحلة الأولى
	local gz = -36
	for _, sx in ipairs({ -9, 9 }) do
		pt({ Size = Vector3.new(3, 18, 3), Position = HUB_TOP + Vector3.new(sx, 9, gz),
			Color = Color3.fromRGB(235, 235, 245), Material = Enum.Material.Marble }, m)
		local orb = ball(HUB_TOP + Vector3.new(sx, 19.5, gz), 3, Color3.fromRGB(90, 220, 255), Enum.Material.Neon, m, false)
		local l = Instance.new("PointLight")
		l.Range = 25
		l.Color = orb.Color
		l.Parent = orb
	end
	textSign(Vector3.new(24, 5, 2), CFrame.new(HUB_TOP + Vector3.new(0, 17, gz)),
		"SKY ISLANDS\nجزر السماء", Enum.NormalId.Back, Color3.fromRGB(30, 34, 60), Color3.fromRGB(255, 230, 120))
	-- لوحة ترحيب قريبة من الظهور
	textSign(Vector3.new(20, 7, 1), CFrame.new(HUB_TOP + Vector3.new(0, 4, 36)) * CFrame.Angles(0, math.pi, 0),
		"مرحباً بك!\nاجمع العملات وصل للقمة 🏆", Enum.NormalId.Back, Color3.fromRGB(35, 40, 70), Color3.fromRGB(255, 255, 255))

	-- حلقة عملات
	for i = 1, 12 do
		local a = (i / 12) * math.pi * 2
		coin(HUB_TOP + Vector3.new(math.cos(a) * 28, 3.5, math.sin(a) * 28))
	end
end

------------------------------------------------------------------------
-- المرحلة 1: جزر الزهور (اتجاه -Z)
------------------------------------------------------------------------
local cp1
do
	local dir = Vector3.new(0, 0, -1)
	local pos, r = HUB_TOP, 44
	for i = 1, 8 do
		local nr = math.max(5.5, 7.5 - i * 0.25)
		pos = advance(pos, r, nr, 4, dir, 1.5)
		pos = Vector3.new(i % 2 == 0 and 4 or -4, pos.Y, pos.Z)
		r = nr
		local m = island(pos, nr, STYLE_GRASS)
		scatter(m, pos, nr, { flowers = 8, lamps = (i % 3 == 0) and 1 or 0, lampOffset = 1 })
		coin(pos + Vector3.new(0, 3.5, 0))
	end
	pos = advance(pos, r, 11, 4, dir, 1.5)
	pos = Vector3.new(0, pos.Y, pos.Z)
	cp1 = checkpoint(pos, 1, "نقطة حفظ 1 ✔", STYLE_GRASS)
end

------------------------------------------------------------------------
-- المرحلة 2: المنصات المتحركة (اتجاه -Z)
------------------------------------------------------------------------
local cp2
do
	local base = cp1.Position - Vector3.new(0, 0.5, 0)
	local z = base.Z - 18
	local y = base.Y
	for i = 1, 7 do
		y = y + 1
		local vertical = (i == 4 or i == 6)
		local amp = vertical and 0 or 14
		local a = Vector3.new(base.X - amp, y, z)
		local b = Vector3.new(base.X + amp, y, z)
		if vertical then
			a = Vector3.new(base.X, y - 5, z)
			b = Vector3.new(base.X, y + 5, z)
		end
		if i % 2 == 0 then
			a, b = b, a
		end
		local p = pt({
			Size = Vector3.new(10, 1.5, 8), Position = a,
			Color = Color3.fromHSV((i / 8) % 1, 0.75, 1), Material = Enum.Material.Metal,
		})
		local l = Instance.new("PointLight")
		l.Range = 14
		l.Color = p.Color
		l.Parent = p
		TweenService:Create(p, TweenInfo.new(vertical and 3 or 3.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Position = b }):Play()
		coin(Vector3.new(base.X, y + 5.5, z))
		addPathPoint(Vector3.new(base.X, y, z))
		addPathPoint(Vector3.new(base.X - 14, y, z))
		addPathPoint(Vector3.new(base.X + 14, y, z))
		z = z - 14
	end
	local pos = Vector3.new(base.X, y + 1, z + 14 - 4 - 3 - 11)
	cp2 = checkpoint(pos, 2, "نقطة حفظ 2 ✔", STYLE_GRASS)
end

------------------------------------------------------------------------
-- المرحلة 3: بركان الدوّامات (اتجاه +X)
------------------------------------------------------------------------
local cp3
do
	local dir = Vector3.new(1, 0, 0)
	local start = cp2.Position - Vector3.new(0, 0.5, 0)
	local pos, r = start, 11
	local first, last
	for i = 1, 6 do
		pos = advance(pos, r, 8, 6, dir, 1)
		r = 8
		local m = island(pos, 8, STYLE_VOLCANO)
		scatter(m, pos, 8, { lamps = 2, lampOffset = math.pi / 2, fire = true })
		first = first or pos
		last = pos
		-- عصا دوّارة (أو عصاتين متقاطعتين)
		local count = (i % 2 == 0) and 2 or 1
		local speed = (i % 2 == 0 and -1 or 1) * (1.5 + i * 0.15)
		local pivot = pos + Vector3.new(0, 1.6, 0)
		for k = 1, count do
			local bar = pt({
				Size = Vector3.new(13, 2.4, 1.4), CFrame = CFrame.new(pivot),
				Color = Color3.fromRGB(255, 60, 60), Material = Enum.Material.Neon,
			}, Map, "Pusher")
			table.insert(spinners, { part = bar, pivot = pivot, speed = speed, phase = (k - 1) * math.pi / 2 })
		end
		coin(pos + Vector3.new(0, 7, 0))
	end
	-- بحر الحمم
	local mid = (first + last) / 2
	local lava = pt({
		Size = Vector3.new((last.X - first.X) + 120, 2, 80),
		Position = Vector3.new(mid.X, first.Y - 9, mid.Z),
		Color = Color3.fromRGB(255, 90, 20), Material = Enum.Material.Neon, Transparency = 0.1,
		CanCollide = false,
	}, Map, "Kill")
	local ll = Instance.new("PointLight")
	ll.Range = 60
	ll.Brightness = 2
	ll.Color = Color3.fromRGB(255, 120, 40)
	ll.Parent = lava
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(70, 60, 60)
	smoke.Opacity = 0.2
	smoke.Size = 10
	smoke.RiseVelocity = 6
	smoke.Parent = lava

	pos = advance(pos, r, 11, 6, dir, 1)
	cp3 = checkpoint(pos, 3, "نقطة حفظ 3 ✔", STYLE_VOLCANO)
end

------------------------------------------------------------------------
-- المرحلة 4: برج النيون (اتجاه +X وللأعلى)
------------------------------------------------------------------------
local summitTop
do
	local dir = Vector3.new(1, 0, 0)
	local cur = cp3.Position - Vector3.new(0, 0.5, 0)
	local padPos = cur + dir * 3
	jumpPad(padPos, 110, Map)
	for i = 1, 5 do
		local center = padPos + dir * 14 + Vector3.new(0, 22, 0)
		local color = Color3.fromHSV((i / 6) % 1, 0.85, 1)
		local m = Instance.new("Model")
		m.Name = "NeonTier"
		m.Parent = Map
		disc(center - Vector3.new(0, 1, 0), 7, 2, color, Enum.Material.Neon, m)
		disc(center - Vector3.new(0, 3, 0), 4.5, 2, Color3.fromRGB(35, 35, 55), Enum.Material.Metal, m)
		local light = Instance.new("PointLight")
		light.Range = 24
		light.Brightness = 2
		light.Color = color
		light.Parent = m:FindFirstChildWhichIsA("BasePart")
		addPathPoint(center)
		coin(padPos + dir * 7 + Vector3.new(0, 20, 0))
		padPos = center
		jumpPad(padPos, 110, m)
	end

	-- القمة
	summitTop = padPos + dir * 14 + Vector3.new(0, 22, 0) + dir * 8
	local m = island(summitTop, 18, STYLE_GOLD)
	m.Name = "Summit"
	scatter(m, summitTop, 18, { lamps = 6, flowers = 20 })

	pt({ Size = Vector3.new(5, 3, 5), Position = summitTop + Vector3.new(0, 1.5, 0),
		Color = Color3.fromRGB(240, 240, 250), Material = Enum.Material.Marble }, m)
	local trophy = ball(summitTop + Vector3.new(0, 6, 0), 5, Color3.fromRGB(255, 205, 40), Enum.Material.Neon, m, false)
	local tl = Instance.new("PointLight")
	tl.Range = 40
	tl.Brightness = 3
	tl.Color = Color3.fromRGB(255, 220, 100)
	tl.Parent = trophy
	local winPad = disc(summitTop + Vector3.new(0, 0.3, 0), 7, 0.6, Color3.fromRGB(255, 205, 40), Enum.Material.Neon, m)
	CollectionService:AddTag(winPad, "Win")
	billboard(trophy, "🏆 القمة! 🏆", Color3.fromRGB(255, 230, 120))

	local fw = pt({ Size = Vector3.new(1, 1, 1), Position = summitTop + Vector3.new(0, 14, 0),
		Transparency = 1, CanCollide = false }, m)
	local e = Instance.new("ParticleEmitter")
	e.Rate = 25
	e.Lifetime = NumberRange.new(1.5, 2.2)
	e.Speed = NumberRange.new(25, 45)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, -12, 0)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	e.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 200, 255)),
	})
	e.Parent = fw
end

------------------------------------------------------------------------
-- ديكور: محيط، جزر بعيدة، غيوم، خط الموت
------------------------------------------------------------------------
do
	pcall(function()
		Workspace.Terrain:FillBlock(CFrame.new(0, 64, 0), Vector3.new(2000, 16, 2000), Enum.Material.Water)
	end)

	local killPlane = pt({
		Size = Vector3.new(4000, 2, 4000), Position = Vector3.new(0, KILL_Y, 0),
		Transparency = 1, CanCollide = false, CanQuery = false,
	}, Map, "Kill")
	killPlane.Name = "KillPlane"

	local minV, maxV = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, p in ipairs(pathPoints) do
		minV = Vector3.new(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
		maxV = Vector3.new(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
	end

	local function farFromPath(p, d)
		for _, q in ipairs(pathPoints) do
			if (q - p).Magnitude < d then
				return false
			end
		end
		return true
	end

	local function randomSpot(d)
		for _ = 1, 40 do
			local p = Vector3.new(
				RNG:NextNumber(minV.X - 220, maxV.X + 220),
				RNG:NextNumber(minV.Y - 40, maxV.Y + 80),
				RNG:NextNumber(minV.Z - 220, maxV.Z + 220))
			if farFromPath(p, d) then
				return p
			end
		end
		return nil
	end

	-- جزر صغيرة بعيدة
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = Map
	for _ = 1, 22 do
		local p = randomSpot(70)
		if p then
			local r = RNG:NextNumber(8, 20)
			local before = #pathPoints
			local m = island(p, r, STYLE_GRASS)
			table.remove(pathPoints, before + 1) -- لا نحسبها كمسار
			m.Parent = decor
			scatter(m, p, r, { trees = RNG:NextInteger(0, 3), flowers = 6 })
		end
	end

	-- غيوم
	for _ = 1, 45 do
		local p = randomSpot(35)
		if p then
			local g = Instance.new("Model")
			g.Name = "Cloud"
			g.Parent = decor
			for _ = 1, RNG:NextInteger(4, 6) do
				local d = RNG:NextNumber(14, 26)
				local b = ball(p + Vector3.new(RNG:NextNumber(-16, 16), RNG:NextNumber(-3, 3), RNG:NextNumber(-10, 10)),
					d, Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, g, false)
				b.Transparency = 0.15
				b.CanQuery = false
				b.CanTouch = false
			end
		end
	end
end

------------------------------------------------------------------------
-- الإضاءة ودورة النهار والليل
------------------------------------------------------------------------
do
	Lighting.ClockTime = 14
	Lighting.Brightness = 3
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 130, 160)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true

	local function ensure(class, name)
		local o = Lighting:FindFirstChild(name)
		if not o then
			o = Instance.new(class)
			o.Name = name
			o.Parent = Lighting
		end
		return o
	end
	local atm = ensure("Atmosphere", "SkyAtmosphere")
	atm.Density = 0.28
	atm.Offset = 0.25
	atm.Color = Color3.fromRGB(190, 205, 235)
	atm.Decay = Color3.fromRGB(255, 190, 150)
	atm.Glare = 0.3
	atm.Haze = 1.2
	local bloom = ensure("BloomEffect", "SkyBloom")
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.6
	local cc = ensure("ColorCorrectionEffect", "SkyColor")
	cc.Saturation = 0.18
	cc.Contrast = 0.08
	local rays = ensure("SunRaysEffect", "SkyRays")
	rays.Intensity = 0.1

	task.spawn(function()
		while true do
			Lighting.ClockTime = (Lighting.ClockTime + 0.04) % 24
			task.wait(0.5)
		end
	end)
end

------------------------------------------------------------------------
-- حركة: العصي الدوّارة + دوران العملات
------------------------------------------------------------------------
do
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		local t = os.clock()
		for _, s in ipairs(spinners) do
			s.part.CFrame = CFrame.new(s.pivot) * CFrame.Angles(0, s.phase + t * s.speed, 0)
		end
		acc = acc + dt
		if acc >= 0.05 then
			acc = 0
			for _, c in ipairs(coins) do
				if not c.part:GetAttribute("Taken") then
					c.part.CFrame = CFrame.new(c.pos + Vector3.new(0, math.sin(t * 2 + c.phase) * 0.5, 0))
						* CFrame.Angles(0, t * 2.5 + c.phase, 0)
				end
			end
		end
	end)
end

------------------------------------------------------------------------
-- اللعب: بيانات اللاعب، نقاط الحفظ، العملات، القفز، الموت، الفوز
------------------------------------------------------------------------
local STAGE_NAMES = { "🌸 جزر الزهور", "🌀 المنصات المتحركة", "🌋 بركان الدوّامات", "⚡ برج النيون" }

local store
pcall(function()
	store = DataStoreService:GetDataStore("SkyIslandsV1")
end)

local function toast(plr, text, color)
	task.spawn(function()
		local pg = plr:FindFirstChildOfClass("PlayerGui") or plr:WaitForChild("PlayerGui", 10)
		if not pg then
			return
		end
		local gui = pg:FindFirstChild("SkyHUD")
		if not gui then
			gui = Instance.new("ScreenGui")
			gui.Name = "SkyHUD"
			gui.ResetOnSpawn = false
			gui.Parent = pg
		end
		local old = gui:FindFirstChild("Toast")
		if old then
			old:Destroy()
		end
		local l = Instance.new("TextLabel")
		l.Name = "Toast"
		l.AnchorPoint = Vector2.new(0.5, 0)
		l.Position = UDim2.new(0.5, 0, 0, -70)
		l.Size = UDim2.new(0, 460, 0, 54)
		l.BackgroundColor3 = Color3.fromRGB(22, 26, 46)
		l.BackgroundTransparency = 0.1
		l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
		l.Font = Enum.Font.GothamBold
		l.TextSize = 26
		l.Text = text
		l.Parent = gui
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 14)
		c.Parent = l
		local s = Instance.new("UIStroke")
		s.Color = color or Color3.fromRGB(255, 255, 255)
		s.Thickness = 2
		s.Parent = l
		TweenService:Create(l, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.5, 0, 0, 24) }):Play()
		task.wait(3)
		if l.Parent then
			local tw = TweenService:Create(l, TweenInfo.new(0.4),
				{ Position = UDim2.new(0.5, 0, 0, -70), BackgroundTransparency = 1, TextTransparency = 1 })
			tw:Play()
			tw.Completed:Wait()
			l:Destroy()
		end
	end)
end

local function save(plr)
	local ls = plr:FindFirstChild("leaderstats")
	if not store or not ls then
		return
	end
	pcall(function()
		store:SetAsync("p" .. plr.UserId, { Coins = ls.Coins.Value, Wins = ls.Wins.Value })
	end)
end

local function setupPlayer(plr)
	plr.RespawnLocation = hubSpawn -- أول ظهور دائماً في الهب

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local function stat(name)
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = ls
		return v
	end
	local stageV, coinsV, winsV = stat("Stage"), stat("Coins"), stat("Wins")
	ls.Parent = plr

	if store then
		local ok, data = pcall(function()
			return store:GetAsync("p" .. plr.UserId)
		end)
		if ok and type(data) == "table" then
			coinsV.Value = data.Coins or 0
			winsV.Value = data.Wins or 0
		end
	end
	task.delay(2, function()
		if plr.Parent then
			toast(plr, "أهلاً! اتجه للبوابة وابدأ المغامرة 🌈", Color3.fromRGB(255, 230, 120))
		end
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end
Players.PlayerRemoving:Connect(save)
game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		save(p)
	end
end)
task.spawn(function()
	while true do
		task.wait(120)
		for _, p in ipairs(Players:GetPlayers()) do
			save(p)
		end
	end
end)

local function fromHit(hit)
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	local plr = Players:GetPlayerFromCharacter(model)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if plr and hum and root and hum.Health > 0 then
		return plr, model, hum, root
	end
	return nil
end

local function onTag(tagName, fn)
	for _, i in ipairs(CollectionService:GetTagged(tagName)) do
		task.spawn(fn, i)
	end
	CollectionService:GetInstanceAddedSignal(tagName):Connect(fn)
end

local lastHit = {}
local function cooldown(key, secs)
	local now = os.clock()
	if lastHit[key] and now - lastHit[key] < secs then
		return false
	end
	lastHit[key] = now
	return true
end

-- نقاط الحفظ
onTag("Checkpoint", function(cp)
	cp.Touched:Connect(function(hit)
		local plr = fromHit(hit)
		if not plr then
			return
		end
		local sv = plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Stage")
		local stage = cp:GetAttribute("Stage") or 0
		if sv and stage > sv.Value then
			sv.Value = stage
			plr.RespawnLocation = cp
			plr.leaderstats.Coins.Value = plr.leaderstats.Coins.Value + 5
			toast(plr, "✅ نقطة حفظ " .. stage .. " — +5 عملات", Color3.fromRGB(110, 255, 160))
			task.delay(3.6, function()
				if STAGE_NAMES[stage + 1] and plr.Parent then
					toast(plr, "المرحلة القادمة: " .. STAGE_NAMES[stage + 1], Color3.fromRGB(120, 210, 255))
				end
			end)
		end
	end)
end)

-- العملات
onTag("Coin", function(c)
	c.Touched:Connect(function(hit)
		if c:GetAttribute("Taken") then
			return
		end
		local plr = fromHit(hit)
		if not plr then
			return
		end
		c:SetAttribute("Taken", true)
		c.Transparency = 1
		local v = plr.leaderstats and plr.leaderstats:FindFirstChild("Coins")
		if v then
			v.Value = v.Value + 1
		end
		task.delay(15, function()
			c.Transparency = 0
			c:SetAttribute("Taken", nil)
		end)
	end)
end)

-- منصات القفز
onTag("JumpPad", function(pad)
	pad.Touched:Connect(function(hit)
		local plr, _, hum, root = fromHit(hit)
		if not plr or not cooldown(plr.UserId .. "jp", 0.5) then
			return
		end
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(v.X, pad:GetAttribute("Power") or 110, v.Z)
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end)
end)

-- العصي الدوّارة تدفع اللاعب
onTag("Pusher", function(bar)
	bar.Touched:Connect(function(hit)
		local plr, _, _, root = fromHit(hit)
		if not plr or not cooldown(plr.UserId .. "push", 0.6) then
			return
		end
		local away = (root.Position - bar.Position) * Vector3.new(1, 0, 1)
		if away.Magnitude < 0.1 then
			away = Vector3.new(0, 0, 1)
		end
		root.AssemblyLinearVelocity = away.Unit * 75 + Vector3.new(0, 45, 0)
	end)
end)

-- حمم / خط الموت
onTag("Kill", function(k)
	k.Touched:Connect(function(hit)
		local _, _, hum = fromHit(hit)
		if hum then
			hum.Health = 0
		end
	end)
end)

-- الفوز
onTag("Win", function(w)
	w.Touched:Connect(function(hit)
		local plr, model = fromHit(hit)
		if not plr or not cooldown(plr.UserId .. "win", 8) then
			return
		end
		local ls = plr.leaderstats
		ls.Wins.Value = ls.Wins.Value + 1
		ls.Coins.Value = ls.Coins.Value + 50
		ls.Stage.Value = 0
		plr.RespawnLocation = hubSpawn
		for _, p in ipairs(Players:GetPlayers()) do
			toast(p, "🏆 " .. plr.DisplayName .. " وصل للقمة!", Color3.fromRGB(255, 220, 90))
		end
		task.delay(3, function()
			if model.Parent then
				model:PivotTo(hubSpawn.CFrame + Vector3.new(0, 4, 0))
			end
		end)
		save(plr)
	end)
end)

print("[SkyIslands] تم بناء الماب بنجاح ✔")
