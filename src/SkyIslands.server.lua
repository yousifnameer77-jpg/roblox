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
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- قناة المؤثرات نحو سكربت العميل (اهتزاز الكاميرا، وميض الضرر...). اللعبة تعمل بدونه.
local FxRemote = Instance.new("RemoteEvent")
FxRemote.Name = "SkyFx"
FxRemote.Parent = ReplicatedStorage
local function fx(plr, name, a, b)
	if plr then
		FxRemote:FireClient(plr, name, a, b)
	end
end

------------------------------------------------------------------------
-- الأصوات: أصوات Roblox المدمجة (rbxasset). يمكنك استبدال أي قيمة برقم من
-- Creator Store مثل "rbxassetid://123456". اترك النص فارغاً "" لإيقاف الصوت.
------------------------------------------------------------------------
local SFX = {
	coin = "rbxasset://sounds/electronicpingshort.wav",
	checkpoint = "rbxasset://sounds/victory.wav",
	jump = "rbxasset://sounds/action_jump.mp3",
	push = "rbxasset://sounds/impact_water.mp3",
	glass = "rbxasset://sounds/impact_explosion_03.mp3",
	hurt = "rbxasset://sounds/uuhhh.mp3",
	stomp = "rbxasset://sounds/snap.mp3",
	buy = "rbxasset://sounds/button.wav",
	deny = "rbxasset://sounds/clickfast.wav",
	win = "rbxasset://sounds/victory.wav",
}
-- موسيقى الخلفية: ضع هنا أرقام موسيقى (مثل "rbxassetid://1234567890") وتتشغل بالتتابع
local MUSIC = {}
-- موسيقى الزعيم: تُشغَّل فقط للاعبين داخل ساحة الزعيم (ضع رقم موسيقى مثل "rbxassetid://1234567890")
local BOSS_MUSIC = ""
-- موسيقى الحديقة السرية: تُشغَّل فقط للاعبين داخلها
local SECRET_MUSIC = ""
-- موسيقى الزعيم الثاني (سيّد العدم)
local BOSS2_MUSIC = ""

local function sfx(key, parent, volume, pitch)
	local id = SFX[key]
	if not id or id == "" or not parent then
		return
	end
	local snd = Instance.new("Sound")
	snd.SoundId = id
	snd.Volume = volume or 0.6
	snd.PlaybackSpeed = pitch or 1
	snd.RollOffMaxDistance = 140
	snd.Parent = parent
	snd:Play()
	Debris:AddItem(snd, 5)
end

------------------------------------------------------------------------
-- المتجر: العناصر المعروضة (السعر بالعملات)
------------------------------------------------------------------------
local SHOP = {
	{ id = "speed", name = "حذاء السرعة", desc = "+6 سرعة مشي", price = 30, color = Color3.fromRGB(80, 200, 255), shape = Enum.PartType.Block },
	{ id = "jump", name = "نطّة عالية", desc = "+15 قوة قفز", price = 40, color = Color3.fromRGB(110, 255, 140), shape = Enum.PartType.Cylinder },
	{ id = "hearts", name = "قلب إضافي", desc = "الصحة 150", price = 35, color = Color3.fromRGB(255, 90, 120), shape = Enum.PartType.Ball },
	{ id = "magnet", name = "مغناطيس العملات", desc = "يجذب العملات القريبة", price = 60, color = Color3.fromRGB(255, 205, 40), shape = Enum.PartType.Ball },
	{ id = "pet", name = "رفيق متوهج", desc = "كرة مضيئة تتبعك", price = 50, color = Color3.fromRGB(190, 120, 255), shape = Enum.PartType.Ball },
	{ id = "trail", name = "ذيل ناري", desc = "ذيل لهب ملوّن", price = 25, color = Color3.fromRGB(255, 130, 40), shape = Enum.PartType.Block },
	{ id = "double", name = "قفزة مزدوجة", desc = "اضغط قفز مرتين (يتطلب سكربت العميل)", price = 80, color = Color3.fromRGB(255, 120, 200), shape = Enum.PartType.Ball },
}

-- الإنجازات
local ACH = {
	{ id = "coins100", name = "جامع العملات (100 عملة)", reward = 20 },
	{ id = "kills10", name = "صيّاد الوحوش (10 أعداء)", reward = 30 },
	{ id = "explorer", name = "المستكشف (3 نجوم سرية)", reward = 40 },
	{ id = "shopper", name = "المتسوّق (3 مشتريات)", reward = 25 },
	{ id = "treasure", name = "صائد الكنوز", reward = 30 },
	{ id = "voidwalker", name = "ماشي في العدم", reward = 60 },
	{ id = "boss1", name = "قاهر تيتان السماء", reward = 50 },
	{ id = "boss2", name = "قاتل سيّد العدم", reward = 120 },
	{ id = "champion", name = "بطل جزر السماء", reward = 100 },
	{ id = "speedy", name = "الصاروخ (أقل من 10 دقائق)", reward = 150 },
}
local ACH_BY_ID = {}
for _, a in ipairs(ACH) do
	ACH_BY_ID[a.id] = a
end
-- المتجر الثاني (في الحديقة السرية): مظاهر وتأثيرات
local SHOP2 = {
	{ id = "halo", name = "هالة ذهبية", desc = "حلقة مضيئة فوق رأسك", price = 120, color = Color3.fromRGB(255, 220, 90), shape = Enum.PartType.Ball },
	{ id = "wings", name = "أجنحة نيون", desc = "أجنحة متوهجة على ظهرك", price = 200, color = Color3.fromRGB(100, 220, 255), shape = Enum.PartType.Block },
	{ id = "aura", name = "هالة شرارات", desc = "شرارات تحيط بك", price = 150, color = Color3.fromRGB(255, 160, 255), shape = Enum.PartType.Ball },
	{ id = "ghost", name = "جسم متوهج", desc = "جسم يلمع كالزجاج", price = 100, color = Color3.fromRGB(180, 255, 235), shape = Enum.PartType.Cylinder },
	{ id = "shield", name = "درع البداية", desc = "حماية 10 ثوانٍ عند كل ظهور", price = 90, color = Color3.fromRGB(120, 160, 255), shape = Enum.PartType.Block },
	{ id = "startrail", name = "ذيل نجمي", desc = "ذيل ذهبي طويل", price = 70, color = Color3.fromRGB(255, 245, 170), shape = Enum.PartType.Block },
}
local ALL_ITEMS = {}
local SHOP_BY_ID = {}
for _, list in ipairs({ SHOP, SHOP2 }) do
	for _, it in ipairs(list) do
		table.insert(ALL_ITEMS, it)
		SHOP_BY_ID[it.id] = it
	end
end

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
local STYLE_ICE = {
	top = Color3.fromRGB(200, 238, 255), topMat = Enum.Material.Ice,
	dirt = Color3.fromRGB(150, 200, 232), rock = Color3.fromRGB(110, 150, 195),
}
local STYLE_CRYSTAL = {
	top = Color3.fromRGB(150, 110, 225), topMat = Enum.Material.Slate,
	dirt = Color3.fromRGB(90, 62, 150), rock = Color3.fromRGB(58, 42, 100),
}
local STYLE_STORM = {
	top = Color3.fromRGB(78, 86, 124), topMat = Enum.Material.Slate,
	dirt = Color3.fromRGB(52, 58, 92), rock = Color3.fromRGB(34, 38, 62),
}
local STYLE_ARENA = {
	top = Color3.fromRGB(44, 50, 92), topMat = Enum.Material.Slate,
	dirt = Color3.fromRGB(32, 36, 70), rock = Color3.fromRGB(22, 24, 48),
}
local FLOWER_COLORS = {
	Color3.fromRGB(255, 105, 180), Color3.fromRGB(255, 220, 70), Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(170, 120, 255), Color3.fromRGB(255, 130, 80), Color3.fromRGB(90, 200, 255),
}

local floaters = {}
local auroras = {}
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

local function tree(base, parent, scale, snow)
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
		if snow then
			g = Color3.fromRGB(215 + i * 8, 232 + i * 5, 245)
		end
		ball(base + Vector3.new(0, h - 1 + (i - 1) * 2.2 * scale, 0), d, g,
			snow and Enum.Material.SmoothPlastic or Enum.Material.Grass, parent, false)
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
		tree(spot(0.6, 0.88), model, RNG:NextNumber(0.8, 1.3), o.snow)
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

-- بلورة نيون
local function crystal(pos, height, color, parent)
	local c = pt({
		Size = Vector3.new(2.4, height, 2.4),
		CFrame = CFrame.new(pos + Vector3.new(0, height / 2, 0))
			* CFrame.Angles(math.rad(RNG:NextNumber(-12, 12)), math.rad(RNG:NextNumber(0, 90)), math.rad(RNG:NextNumber(-12, 12))),
		Color = color, Material = Enum.Material.Neon, Transparency = 0.12,
	}, parent)
	local l = Instance.new("PointLight")
	l.Range = 12
	l.Color = color
	l.Parent = c
	return c
end

-- انفجار جزيئات لحظي في مكان معين
local function burst(pos, color, count, speed)
	local a = pt({ Size = Vector3.new(1, 1, 1), Position = pos, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(speed * 0.5, speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.LightEmission = 1
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	e.Parent = a
	e:Emit(count)
	game:GetService("Debris"):AddItem(a, 2)
end

-- هطول (ثلج / جزيئات ناعمة) فوق منطقة
local function weather(center, size, color, rate, fall, life, up)
	local a = pt({ Size = size, Position = center, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local e = Instance.new("ParticleEmitter")
	e.Rate = rate
	e.Lifetime = life and NumberRange.new(life, life + 1) or NumberRange.new(7, 9)
	e.Speed = NumberRange.new(fall, fall + 3)
	e.EmissionDirection = up and Enum.NormalId.Top or Enum.NormalId.Bottom
	e.SpreadAngle = Vector2.new(20, 20)
	e.RotSpeed = NumberRange.new(-60, 60)
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(0.4)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0.2), NumberSequenceKeypoint.new(0.9, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.LightEmission = 0.4
	e.Parent = a
	return a
end

-- الأعداء: slime (يتحرك ذهاباً وإياباً)، drone وghost (طيران)، guardian (يدور حول الكأس)
local enemies = {}
local function newEnemy(look, motion, p)
	local id = #enemies + 1
	local m = Instance.new("Model")
	m.Name = "Enemy_" .. look
	local function bp(shape, size, offset, color, material, transparency)
		return pt({
			Shape = shape, Size = size, Position = offset, Color = color,
			Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0, CanCollide = false,
		}, m)
	end
	local B = Enum.PartType.Ball
	local K = Enum.PartType.Block
	local body, dmg, killable, spin = nil, 20, true, false
	if look == "slime" then
		body = bp(B, Vector3.new(4.4, 4.4, 4.4), Vector3.zero, Color3.fromRGB(90, 230, 110), nil, 0.1)
		for _, sx in ipairs({ -0.95, 0.95 }) do
			bp(B, Vector3.new(1.2, 1.2, 1.2), Vector3.new(sx, 0.7, -1.9), Color3.fromRGB(255, 255, 255))
			bp(B, Vector3.new(0.6, 0.6, 0.6), Vector3.new(sx, 0.7, -2.4), Color3.fromRGB(10, 10, 10))
		end
	elseif look == "drone" then
		body = bp(B, Vector3.new(3.4, 3.4, 3.4), Vector3.zero, Color3.fromRGB(255, 60, 70), Enum.Material.Neon)
		for _, sx in ipairs({ -3, 3 }) do
			bp(K, Vector3.new(4, 0.2, 1.4), Vector3.new(sx, 0.3, 0), Color3.fromRGB(40, 40, 55), Enum.Material.Metal)
		end
		bp(B, Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 0.3, -1.6), Color3.fromRGB(255, 240, 80), Enum.Material.Neon)
	elseif look == "ghost" then
		body = bp(B, Vector3.new(4, 4, 4), Vector3.zero, Color3.fromRGB(245, 245, 255), Enum.Material.Neon, 0.35)
		for _, sx in ipairs({ -0.9, 0.9 }) do
			bp(B, Vector3.new(0.9, 1.3, 0.9), Vector3.new(sx, 0.5, -1.8), Color3.fromRGB(20, 20, 30))
		end
	else -- guardian
		body = bp(B, Vector3.new(7, 7, 7), Vector3.zero, Color3.fromRGB(40, 30, 60), Enum.Material.Metal)
		bp(K, Vector3.new(1.2, 13, 1.2), Vector3.zero, Color3.fromRGB(255, 50, 80), Enum.Material.Neon)
		bp(K, Vector3.new(13, 1.2, 1.2), Vector3.zero, Color3.fromRGB(255, 50, 80), Enum.Material.Neon)
		bp(K, Vector3.new(1.2, 1.2, 13), Vector3.zero, Color3.fromRGB(255, 50, 80), Enum.Material.Neon)
		dmg, killable, spin = 35, false, true
	end
	m.PrimaryPart = body
	for _, d in ipairs(m:GetChildren()) do
		d:SetAttribute("EnemyId", id)
		CollectionService:AddTag(d, "Enemy")
	end
	enemies[id] = { id = id, model = m, body = body, look = look, motion = motion, p = p, alive = true, dmg = dmg, killable = killable, spin = spin }
	m.Parent = Map
	return enemies[id]
end

local function updateEnemy(e, t)
	local p = e.p
	local ph = p.phase or 0
	local cf
	if e.motion == "patrol" then
		local dist = (p.b - p.a).Magnitude
		local u = (t * p.speed / dist + ph) % 2
		local s = u < 1 and u or 2 - u
		local pos = p.a:Lerp(p.b, s)
		if e.look == "slime" then
			pos = pos + Vector3.new(0, math.abs(math.sin(t * 5 + ph * 3)) * 1.2, 0)
		else
			pos = pos + Vector3.new(0, math.sin(t * 3 + ph) * 0.8, 0)
		end
		local dirv = (u < 1) and (p.b - p.a) or (p.a - p.b)
		cf = CFrame.lookAt(pos, pos + dirv)
	else
		local ang = ph + t * p.speed
		local pos = p.center + Vector3.new(math.cos(ang) * p.radius, math.sin(t * 2 + ang), math.sin(ang) * p.radius)
		cf = CFrame.lookAt(pos, pos + Vector3.new(-math.sin(ang), 0, math.cos(ang)))
		if e.spin then
			cf = cf * CFrame.Angles(0, t * 3, t * 1.5)
		end
	end
	e.model:PivotTo(cf)
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

-- أبراج المدافع (ممر العدم): تطلق كرات نارية على اللاعب بعد تحذير قصير
local turrets = {}
local function newTurret(base, phase)
	island(base, 2.5, { top = Color3.fromRGB(40, 28, 56), topMat = Enum.Material.Slate, dirt = Color3.fromRGB(30, 20, 42), rock = Color3.fromRGB(20, 14, 30) })
	pt({ Size = Vector3.new(1.6, 14, 1.6), Position = base + Vector3.new(0, 7, 0), Color = Color3.fromRGB(30, 28, 44), Material = Enum.Material.Metal })
	local head = ball(base + Vector3.new(0, 15.5, 0), 4, Color3.fromRGB(255, 50, 60), Enum.Material.Neon, Map, true)
	local l = Instance.new("PointLight")
	l.Range = 22
	l.Color = Color3.fromRGB(255, 80, 80)
	l.Parent = head
	table.insert(turrets, { head = head, nextShot = os.clock() + 3 + phase * 0.9 })
end

-- قرص دوّار سريع عليه جدران (تستخدمه مرحلة ممر العدم)
local function spinDisc(pos, speed, walls, tint)
	local m = Instance.new("Model")
	m.Name = "SpinDisc"
	m.Parent = Map
	local top = disc(pos - Vector3.new(0, 1, 0), 9, 2, tint, Enum.Material.Metal, m)
	disc(pos - Vector3.new(0, 4, 0), 5.5, 4, Color3.fromRGB(26, 18, 38), Enum.Material.Slate, m)
	local rim = disc(pos - Vector3.new(0, 1, 0), 9.15, 1.2, Color3.fromRGB(255, 70, 110), Enum.Material.Neon, m)
	rim.Transparency = 0.35
	local pivot = pos - Vector3.new(0, 1, 0)
	local flat = CFrame.Angles(0, 0, math.pi / 2)
	table.insert(spinners, { part = top, pivot = pivot, speed = speed, phase = 0, localCF = flat })
	table.insert(spinners, { part = rim, pivot = pivot, speed = speed, phase = 0, localCF = flat })
	for k = 1, walls do
		local wall = pt({ Size = Vector3.new(12, 4, 1.5), CFrame = CFrame.new(pivot), Color = Color3.fromRGB(255, 60, 90), Material = Enum.Material.Neon }, m, "Pusher")
		table.insert(spinners, { part = wall, pivot = pivot, speed = speed, phase = (k - 1) * math.pi, localCF = CFrame.new(0, 3, 4.5) })
	end
	addPathPoint(pos)
end

-- نجمة سرية مخفية على جزيرة صغيرة جانبية (3 نجوم تفتح البوابة السرية في الهب)
local function secretStar(top, id, style)
	island(top, 4, style)
	local st = pt({
		Size = Vector3.new(2.6, 2.6, 2.6), Position = top + Vector3.new(0, 3.6, 0), Color = Color3.fromRGB(255, 235, 90),
		Material = Enum.Material.Neon, CanCollide = false,
	}, Map, "SecretStar")
	st:SetAttribute("Id", id)
	local l = Instance.new("PointLight")
	l.Range = 20
	l.Color = st.Color
	l.Parent = st
	local e = Instance.new("ParticleEmitter")
	e.Rate = 12
	e.Lifetime = NumberRange.new(1, 1.6)
	e.Speed = NumberRange.new(2, 5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.LightEmission = 1
	e.Color = ColorSequence.new(Color3.fromRGB(255, 240, 120))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	e.Parent = st
	table.insert(floaters, { part = st, center = top + Vector3.new(0, 3.6, 0), radius = 0, angle = 0, speed = 0, bob = id * 2 })
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

local checkpointsByStage = {}
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
	checkpointsByStage[stage] = sp
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
	checkpointsByStage[0] = hubSpawn
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

	-- بلورات عائمة تدور حول النافورة
	for i = 1, 8 do
		local c = pt({
			Size = Vector3.new(2, 4.5, 2), Color = Color3.fromHSV(i / 8, 0.7, 1),
			Material = Enum.Material.Neon, Transparency = 0.1,
		}, m)
		local l = Instance.new("PointLight")
		l.Range = 14
		l.Color = c.Color
		l.Parent = c
		table.insert(floaters, { part = c, center = HUB_TOP + Vector3.new(0, 13, 0), radius = 17, angle = (i / 8) * math.pi * 2, speed = 0.45, bob = i })
	end

	-- شلالات من حافة الجزيرة
	for _, ang in ipairs({ 0.9, 2.4, 4.0, 5.4 }) do
		local edge = HUB_TOP + Vector3.new(math.cos(ang) * 43.5, -2, math.sin(ang) * 43.5)
		local fall = pt({
			Size = Vector3.new(6, 70, 1.5),
			CFrame = CFrame.lookAt(edge + Vector3.new(0, -34, 0), HUB_TOP + Vector3.new(0, -36, 0)),
			Color = Color3.fromRGB(150, 215, 255), Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false,
		}, m)
		local mist = Instance.new("ParticleEmitter")
		mist.Rate = 18
		mist.Lifetime = NumberRange.new(2, 3)
		mist.Speed = NumberRange.new(2, 5)
		mist.SpreadAngle = Vector2.new(180, 180)
		mist.Color = ColorSequence.new(Color3.fromRGB(235, 245, 255))
		mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 8) })
		mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
		mist.Parent = fall
		local top = pt({ Size = Vector3.new(1, 1, 1), Position = edge + Vector3.new(0, -68, 0), Transparency = 1, CanCollide = false }, m)
		local mist2 = mist:Clone()
		mist2.Parent = top
	end

	-- يراعات متوهجة فوق الهب
	weather(HUB_TOP + Vector3.new(0, 22, 0), Vector3.new(70, 1, 70), Color3.fromRGB(190, 255, 160), 10, 1)
end

------------------------------------------------------------------------
-- المتاجر: اقترب من أي عرض واضغط E للشراء
------------------------------------------------------------------------
local function buildShop(title, center, items, accent)
	local m = Instance.new("Model")
	m.Name = title
	m.Parent = Map
	disc(center + Vector3.new(0, 0.2, 0), 13, 0.4, Color3.fromRGB(70, 60, 95), Enum.Material.Slate, m)
	disc(center + Vector3.new(0, 0.45, 0), 11.5, 0.2, accent, Enum.Material.Neon, m).Transparency = 0.5

	local roof = disc(center + Vector3.new(0, 14, 0), 13.5, 1, accent, Enum.Material.Neon, m)
	roof.Transparency = 0.35
	local rl = Instance.new("PointLight")
	rl.Range = 40
	rl.Brightness = 1.5
	rl.Color = accent
	rl.Parent = roof
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2
		pt({ Size = Vector3.new(1.2, 14, 1.2), Position = center + Vector3.new(math.cos(a) * 12.5, 7, math.sin(a) * 12.5),
			Color = Color3.fromRGB(235, 235, 250), Material = Enum.Material.Marble }, m)
	end
	local sign = pt({ Size = Vector3.new(1, 1, 1), Position = center + Vector3.new(0, 17.5, 0), Transparency = 1, CanCollide = false }, m)
	billboard(sign, title, Color3.fromRGB(255, 230, 120))

	for i, item in ipairs(items) do
		local a = math.pi * 0.5 + ((i - 1) / (#items - 1)) * math.pi
		local base = center + Vector3.new(math.cos(a) * 8.5, 0, math.sin(a) * 8.5)
		local stand = disc(base + Vector3.new(0, 1, 0), 2.2, 1.6, Color3.fromRGB(235, 235, 245), Enum.Material.Marble, m)
		stand:SetAttribute("ItemId", item.id)
		CollectionService:AddTag(stand, "ShopItem")

		local icon = pt({
			Shape = item.shape, Size = Vector3.new(2.6, 2.6, 2.6), Color = item.color,
			Material = Enum.Material.Neon, CanCollide = false,
		}, m)
		local il = Instance.new("PointLight")
		il.Range = 12
		il.Color = item.color
		il.Parent = icon
		table.insert(floaters, { part = icon, center = base + Vector3.new(0, 5, 0), radius = 0, angle = 0, speed = 0, bob = i })

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 200, 0, 70)
		bb.StudsOffset = Vector3.new(0, 7.5, 0)
		bb.MaxDistance = 60
		bb.Parent = stand
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = Enum.Font.GothamBlack
		t.TextColor3 = Color3.fromRGB(255, 255, 255)
		t.TextStrokeTransparency = 0.3
		t.Text = item.name .. "\n" .. item.price .. " 🪙 — " .. item.desc
		t.Parent = bb

		local pr = Instance.new("ProximityPrompt")
		pr.ActionText = "شراء"
		pr.ObjectText = item.name .. " (" .. item.price .. " عملة)"
		pr.HoldDuration = 0.3
		pr.MaxActivationDistance = 12
		pr.RequiresLineOfSight = false
		pr.KeyboardKeyCode = Enum.KeyCode.E
		pr.Parent = stand
	end
	return m
end

buildShop("🛒 المتجر", HUB_TOP + Vector3.new(-26, 0, -6), SHOP, Color3.fromRGB(150, 90, 230))

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
		if i == 3 or i == 6 then
			newEnemy("slime", "patrol", { a = pos + Vector3.new(-3.2, 2.3, 0), b = pos + Vector3.new(3.2, 2.3, 0), speed = 5, phase = i * 0.3 })
		end
		if i == 5 then
			secretStar(pos + Vector3.new(16, 0.5, 0), 1, STYLE_GRASS)
		end
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
		if i == 3 or i == 5 then
			newEnemy("drone", "orbit", { center = Vector3.new(base.X, y + 4, z), radius = 11, speed = 1.3, phase = i })
		end
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
-- المرحلة 4: الجبال الجليدية (اتجاه +Z) - سيور متحركة عكس اتجاهك
------------------------------------------------------------------------
local cp4
do
	local dir = Vector3.new(0, 0, 1)
	local pos, r = cp3.Position - Vector3.new(0, 0.5, 0), 11
	local startZ = pos.Z
	local belts = {
		{ len = 18, vel = Vector3.new(0, 0, -11), arrows = "▲▲▲" },
		{ len = 20, vel = Vector3.new(9, 0, -3), arrows = "▶▶▶" },
		{ len = 20, vel = Vector3.new(-9, 0, -3), arrows = "◀◀◀" },
		{ len = 22, vel = Vector3.new(0, 0, -13), arrows = "▲▲▲" },
	}
	for i, b in ipairs(belts) do
		local beltStart = pos + dir * (r - 0.5)
		local beltPos = beltStart + dir * (b.len / 2) - Vector3.new(0, 0.5, 0)
		local belt = pt({
			Size = Vector3.new(i == 1 and 14 or 22, 1, b.len), Position = beltPos,
			Color = Color3.fromRGB(60, 215, 255), Material = Enum.Material.Neon,
		}, Map)
		belt.AssemblyLinearVelocity = b.vel
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Top
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 25
		sg.Parent = belt
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = Enum.Font.GothamBlack
		t.TextColor3 = Color3.fromRGB(20, 60, 110)
		t.TextTransparency = 0.25
		t.Text = b.arrows
		t.Parent = sg
		addPathPoint(beltPos)

		local nextPos = beltStart + dir * b.len + dir * (8 - 0.5)
		pos, r = nextPos, 8
		local m = island(pos, 8, STYLE_ICE)
		scatter(m, pos, 8, { trees = 1, snow = true, lamps = 2, lampOffset = i })
		coin(pos + Vector3.new(0, 3.5, 0))
		coin(beltPos + Vector3.new(0, 4, 0))
		if i == 2 or i == 4 then
			newEnemy("slime", "patrol", { a = pos + Vector3.new(-3.5, 2.3, 0), b = pos + Vector3.new(3.5, 2.3, 0), speed = 6, phase = i })
		end
	end
	pos = pos + dir * (r + 11 + 4)
	cp4 = checkpoint(pos, 4, "نقطة حفظ 4 ✔", STYLE_ICE)
	secretStar(pos + Vector3.new(-19, 1.5, 0), 2, STYLE_ICE)
	weather((cp3.Position + pos) / 2 + Vector3.new(0, 45, 0), Vector3.new(90, 1, math.abs(pos.Z - startZ) + 80), Color3.fromRGB(255, 255, 255), 220, 8)
end

------------------------------------------------------------------------
-- المرحلة 5: جسر الزجاج السحري (اتجاه +X) - اختر البلاطة الصحيحة!
------------------------------------------------------------------------
local cp5
do
	local dir = Vector3.new(1, 0, 0)
	local start = cp4.Position - Vector3.new(0, 0.5, 0)
	local glassRng = Random.new(os.time())
	local rows = 10
	for i = 1, rows do
		local center = start + dir * (18.5 + (i - 1) * 11) + Vector3.new(0, i * 0.6, 0)
		local real = glassRng:NextInteger(1, 2)
		local color = Color3.fromHSV(((i - 1) / rows) * 0.8, 0.55, 1)
		for lane = 1, 2 do
			local tile = pt({
				Size = Vector3.new(7, 1, 7), Position = center + Vector3.new(0, -0.5, lane == 1 and -5 or 5),
				Color = color, Material = Enum.Material.Glass, Transparency = 0.3,
			}, Map, lane ~= real and "FakeGlass" or nil)
			local edge = pt({
				Size = Vector3.new(7.2, 0.2, 7.2), Position = tile.Position + Vector3.new(0, 0.55, 0),
				Color = color, Material = Enum.Material.Neon, Transparency = 0.55, CanCollide = false,
			}, Map)
			edge.Name = "GlassGlow"
			edge.Parent = tile
		end
		addPathPoint(center)
		if i % 3 == 0 then
			coin(center + Vector3.new(0, 4.5, 0))
		end
		if i == 4 or i == 8 then
			newEnemy("ghost", "patrol", { a = center + Vector3.new(0, 3.2, -9), b = center + Vector3.new(0, 3.2, 9), speed = 7, phase = i })
		end
	end
	local endPos = start + dir * (18.5 + (rows - 1) * 11 + 3.5 + 4 + 11) + Vector3.new(0, rows * 0.6 + 0.5, 0)
	cp5 = checkpoint(endPos, 5, "نقطة حفظ 5 ✔", STYLE_CRYSTAL)
	local m = cp5.Parent
	for k = 1, 9 do
		local a = (k / 9) * math.pi * 2
		crystal(endPos + Vector3.new(math.cos(a) * 9, 0, math.sin(a) * 9), RNG:NextNumber(4, 9),
			Color3.fromHSV(RNG:NextNumber(0.7, 0.95), 0.6, 1), m)
	end
	weather(start + dir * 60 + Vector3.new(0, 30, 0), Vector3.new(60, 1, 150), Color3.fromRGB(230, 190, 255), 40, 3)
end

------------------------------------------------------------------------
-- المرحلة 6: برج النيون (اتجاه -Z وللأعلى)
------------------------------------------------------------------------
local cp6
do
	local dir = Vector3.new(0, 0, -1)
	local cur = cp5.Position - Vector3.new(0, 0.5, 0)
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
		if i == 3 then
			secretStar(center + Vector3.new(14.5, 0, 0), 3, STYLE_CRYSTAL)
		end
		padPos = center
		jumpPad(padPos, 110, m)
	end
	cp6 = checkpoint(padPos + dir * 14 + Vector3.new(0, 22, 0), 6, "نقطة حفظ 6 ✔", STYLE_STORM)
end

------------------------------------------------------------------------
-- المرحلة 7: قلعة العاصفة (اتجاه +X) - أقراص دوّارة، صواعق، مطر
------------------------------------------------------------------------
local cp7
local arena = {}
do
	local dir = Vector3.new(1, 0, 0)
	local startTop = cp6.Position - Vector3.new(0, 0.5, 0)
	local pos, r = startTop, 11
	for i = 1, 4 do
		pos = advance(pos, r, 9, 5, dir, 1)
		r = 9
		local m = Instance.new("Model")
		m.Name = "StormDisc"
		m.Parent = Map
		local top = disc(pos - Vector3.new(0, 1, 0), 9, 2, Color3.fromRGB(86, 98, 150), Enum.Material.Metal, m)
		disc(pos - Vector3.new(0, 4, 0), 5.5, 4, Color3.fromRGB(34, 38, 62), Enum.Material.Slate, m)
		local rim = disc(pos - Vector3.new(0, 1, 0), 9.15, 1.2, Color3.fromRGB(110, 230, 255), Enum.Material.Neon, m)
		rim.Transparency = 0.35
		local speed = (i % 2 == 0 and -1 or 1) * (0.5 + i * 0.07)
		local pivot = pos - Vector3.new(0, 1, 0)
		local flat = CFrame.Angles(0, 0, math.pi / 2)
		table.insert(spinners, { part = top, pivot = pivot, speed = speed, phase = 0, localCF = flat })
		table.insert(spinners, { part = rim, pivot = pivot, speed = speed, phase = 0, localCF = flat })
		local wall = pt({
			Size = Vector3.new(12, 4, 1.5), CFrame = CFrame.new(pivot), Color = Color3.fromRGB(255, 70, 90),
			Material = Enum.Material.Neon,
		}, m, "Pusher")
		table.insert(spinners, { part = wall, pivot = pivot, speed = speed, phase = i, localCF = CFrame.new(0, 3, 4.5) })
		coin(pos + Vector3.new(0, 6, 0))
		addPathPoint(pos)
	end
	for i = 1, 3 do
		pos = advance(pos, r, 4.5, 3, dir, 1.5)
		pos = Vector3.new(pos.X, pos.Y, startTop.Z + (i % 2 == 0 and 3 or -3))
		r = 4.5
		local m = island(pos, 4.5, STYLE_STORM)
		crystal(pos + Vector3.new(2.6, 0, 0), 7, Color3.fromRGB(255, 255, 130), m)
		coin(pos + Vector3.new(0, 3.5, 0))
	end
	pos = advance(pos, r, 11, 4, dir, 1.5)
	pos = Vector3.new(pos.X, pos.Y, startTop.Z)
	cp7 = checkpoint(pos, 7, "نقطة حفظ 7 ✔", STYLE_STORM)

	-- أجواء العاصفة: غيوم داكنة ومطر
	local midX = (startTop.X + pos.X) / 2
	local len = pos.X - startTop.X
	for k = 1, 12 do
		local c = ball(Vector3.new(startTop.X - 30 + RNG:NextNumber(0, len + 60), startTop.Y + RNG:NextNumber(38, 55), startTop.Z + RNG:NextNumber(-45, 45)),
			RNG:NextNumber(26, 44), Color3.fromRGB(56, 60, 84), Enum.Material.SmoothPlastic, Map, false)
		c.Transparency = 0.1
		c.CanQuery = false
		c.CanTouch = false
	end
	weather(Vector3.new(midX, startTop.Y + 45, startTop.Z), Vector3.new(len + 80, 1, 110), Color3.fromRGB(160, 185, 235), 700, 75, 1)
	arena.stormMinX, arena.stormMaxX = startTop.X - 20, pos.X + 20
	arena.stormZ, arena.stormY = startTop.Z, startTop.Y
end

------------------------------------------------------------------------
-- المرحلة 8: ساحة الزعيم الأول "تيتان السماء" (البوابة تُفتح عند هزيمته)
------------------------------------------------------------------------
local arena2 = {}

local function buildBoss(id, top, spec)
	local bm = Instance.new("Model")
	bm.Name = spec.name
	local sc = spec.scale
	local B, K = Enum.PartType.Ball, Enum.PartType.Block
	local function bpart(shape, size, offset, color, material)
		local pp = pt({
			Shape = shape, Size = size * sc, Position = offset * sc, Color = color,
			Material = material or Enum.Material.SmoothPlastic, CanCollide = false,
		}, bm, "BossPart")
		pp:SetAttribute("BossId", id)
		return pp
	end
	local body = bpart(B, Vector3.new(13, 13, 13), Vector3.zero, spec.body, Enum.Material.Metal)
	bpart(B, Vector3.new(5.5, 5.5, 5.5), Vector3.new(0, 3.5, -5.2), spec.core, Enum.Material.Neon)
	for k = 1, spec.eyes do
		bpart(B, Vector3.new(2, 2, 2), Vector3.new((k - (spec.eyes + 1) / 2) * 5.2, 1.2, -6.2), spec.eye, Enum.Material.Neon)
	end
	for k = 1, spec.spikes do
		local ang = (k / spec.spikes) * math.pi * 2
		bpart(K, Vector3.new(1.2, 5, 1.2), Vector3.new(math.cos(ang) * 4, 7.5, math.sin(ang) * 4), spec.crown, Enum.Material.Neon)
	end
	for _, sx in ipairs({ -10, 10 }) do
		bpart(B, Vector3.new(6, 6, 6), Vector3.new(sx, -3, -1), spec.fist, Enum.Material.Metal)
		bpart(B, Vector3.new(3, 3, 3), Vector3.new(sx, -3, -3.5), spec.crown, Enum.Material.Neon)
	end
	bm.PrimaryPart = body

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 320, 0, 46)
	bb.StudsOffset = Vector3.new(0, 13 * sc, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 260
	bb.Parent = body
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	back.BorderSizePixel = 0
	back.Parent = bb
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = spec.bar
	fill.BorderSizePixel = 0
	fill.Parent = back
	local lab = Instance.new("TextLabel")
	lab.Size = UDim2.fromScale(1, 1)
	lab.BackgroundTransparency = 1
	lab.TextScaled = true
	lab.Font = Enum.Font.GothamBlack
	lab.TextColor3 = Color3.fromRGB(255, 255, 255)
	lab.TextStrokeTransparency = 0.4
	lab.Parent = back

	local hover = 14 * sc
	local spawnPos = top + Vector3.new(0, hover, 0)
	bm:PivotTo(CFrame.new(spawnPos))
	bm.Parent = Map
	return {
		id = id, model = bm, body = body, fill = fill, label = lab, display = spec.display, hp = spec.hp, maxHp = spec.hp,
		alive = true, vulnerable = false, pos = spawnPos, target = spawnPos, face = top + Vector3.new(0, hover, 30),
		hover = hover, ground = 7.5 * sc, baseColor = spec.body, vulnColor = spec.vuln, contactDmg = spec.dmg,
		reward = spec.reward, respawn = spec.respawn,
	}
end

local function buildArena(t, top, radius, style, ringColor, hue, spec, id)
	local m = island(top, radius, style)
	m.Name = "BossArena" .. id
	t.center, t.radius = top, radius
	for _, f in ipairs({ radius - 4, radius * 0.53, radius * 0.2 }) do
		local ring = disc(top + Vector3.new(0, 0.12, 0), f, 0.2, ringColor, Enum.Material.Neon, m)
		ring.Transparency = 0.55
		ring.CanCollide = false
	end
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		local base = top + Vector3.new(math.cos(a) * (radius - 2.5), 0, math.sin(a) * (radius - 2.5))
		pt({ Size = Vector3.new(3, 16, 3), Position = base + Vector3.new(0, 8, 0), Color = Color3.fromRGB(28, 30, 54), Material = Enum.Material.Metal }, m)
		local orb = ball(base + Vector3.new(0, 17.5, 0), 3.4, Color3.fromHSV((hue + i * 0.02) % 1, 0.7, 1), Enum.Material.Neon, m, false)
		local l = Instance.new("PointLight")
		l.Range = 30
		l.Color = orb.Color
		l.Parent = orb
	end
	t.boss = buildBoss(id, top, spec)
	t.boss.arena = t
	return m
end

local arena1Top = advance(cp7.Position - Vector3.new(0, 0.5, 0), 11, 34, 5, Vector3.new(1, 0, 0), 1)
buildArena(arena, arena1Top, 34, STYLE_ARENA, Color3.fromRGB(150, 90, 255), 0.72, {
	name = "SkyTitan", display = "تيتان السماء", scale = 1, hp = 10, bar = Color3.fromRGB(255, 60, 90),
	body = Color3.fromRGB(60, 40, 110), vuln = Color3.fromRGB(255, 150, 50), core = Color3.fromRGB(255, 140, 40),
	eye = Color3.fromRGB(255, 240, 80), crown = Color3.fromRGB(255, 60, 200), fist = Color3.fromRGB(40, 28, 80),
	eyes = 2, spikes = 5, dmg = 30, reward = 25, respawn = 45,
}, 1)
-- بوابة مغلقة تمنع الانتقال للمرحلة التالية قبل هزيمة الزعيم الأول
do
	local gate = pt({
		Size = Vector3.new(2, 32, 44), Position = arena1Top + Vector3.new(32.5, 16, 0),
		Color = Color3.fromRGB(170, 90, 255), Material = Enum.Material.Neon, Transparency = 0.55,
	}, Map)
	arena.gate = gate
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 260, 0, 60)
	bg.StudsOffset = Vector3.new(0, 20, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 200
	bg.Parent = gate
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.TextColor3 = Color3.fromRGB(255, 255, 255)
	t.TextStrokeTransparency = 0.3
	t.Text = "🔒 اهزم تيتان السماء لفتح الطريق"
	t.Parent = bg
	arena.gateGui = bg
end

------------------------------------------------------------------------
-- المرحلة 9: ممر العدم (الأصعب): جسر ينهار، مدافع، أقراص سريعة
------------------------------------------------------------------------
local cp8, cp9
do
	local dir = Vector3.new(1, 0, 0)
	local A = arena.center
	local VOID = {
		top = Color3.fromRGB(44, 30, 62), topMat = Enum.Material.Slate,
		dirt = Color3.fromRGB(32, 22, 46), rock = Color3.fromRGB(20, 14, 30),
	}
	-- 1) جسر ينهار: كل بلاطة تسقط بعد نصف ثانية من لمسها
	local lastX
	for i = 1, 8 do
		local c = Vector3.new(A.X + 41 + (i - 1) * 9, A.Y, A.Z + (i % 2 == 0 and 3 or -3))
		pt({
			Size = Vector3.new(5, 1, 5), Position = c - Vector3.new(0, 0.5, 0), Color = Color3.fromRGB(180, 120, 255),
			Material = Enum.Material.Neon, Transparency = 0.15,
		}, Map, "Crumble")
		addPathPoint(c)
		lastX = c.X
		if i % 2 == 0 then
			coin(c + Vector3.new(0, 3.5, 0))
		end
	end
	local pos = Vector3.new(lastX + 2.5 + 4 + 11, A.Y, A.Z)
	cp8 = checkpoint(pos, 8, "نقطة حفظ 8 ✔", VOID)

	-- 2) جزر تحت نيران المدافع
	local r = 11
	for i = 1, 4 do
		pos = advance(pos, r, 7, 5, dir, 1)
		r = 7
		local m = island(pos, 7, VOID)
		coin(pos + Vector3.new(0, 3.5, 0))
		newTurret(pos + Vector3.new(0, 0, 13), i)
		newTurret(pos + Vector3.new(0, 0, -13), i + 0.5)
	end
	-- 3) أقراص دوّارة سريعة بجدارين
	for i = 1, 4 do
		pos = advance(pos, r, 9, 6, dir, 1)
		r = 9
		spinDisc(pos, (i % 2 == 0 and -1 or 1) * (0.95 + i * 0.12), 2, Color3.fromRGB(70, 50, 100))
		coin(pos + Vector3.new(0, 6, 0))
	end
	pos = advance(pos, r, 11, 6, dir, 1)
	cp9 = checkpoint(pos, 9, "نقطة حفظ 9 ✔", VOID)
	weather(Vector3.new((cp8.Position.X + cp9.Position.X) / 2, A.Y - 6, A.Z), Vector3.new(cp9.Position.X - cp8.Position.X + 60, 1, 90), Color3.fromRGB(255, 120, 70), 120, 7, 4, true)
end

------------------------------------------------------------------------
-- المرحلة 10: ساحة الزعيم الثاني "سيّد العدم" (الأصعب)
------------------------------------------------------------------------
do
	local top = advance(cp9.Position - Vector3.new(0, 0.5, 0), 11, 38, 5, Vector3.new(1, 0, 0), 1)
	local VOIDARENA = {
		top = Color3.fromRGB(34, 18, 44), topMat = Enum.Material.Slate,
		dirt = Color3.fromRGB(24, 12, 32), rock = Color3.fromRGB(14, 8, 20),
	}
	local m = buildArena(arena2, top, 38, VOIDARENA, Color3.fromRGB(255, 50, 90), 0.98, {
		name = "VoidLord", display = "سيّد العدم", scale = 1.25, hp = 16, bar = Color3.fromRGB(190, 60, 255),
		body = Color3.fromRGB(26, 12, 34), vuln = Color3.fromRGB(255, 70, 70), core = Color3.fromRGB(255, 40, 70),
		eye = Color3.fromRGB(255, 255, 255), crown = Color3.fromRGB(255, 40, 70), fist = Color3.fromRGB(18, 8, 24),
		eyes = 3, spikes = 7, dmg = 40, reward = 75, respawn = 60,
	}, 2)

	-- الكأس وقاعدة الفوز (مخفية حتى يُهزم سيّد العدم)
	local pedestal = pt({ Size = Vector3.new(5, 3, 5), Position = top + Vector3.new(0, 1.5, 0),
		Color = Color3.fromRGB(240, 240, 250), Material = Enum.Material.Marble, Transparency = 1, CanCollide = false }, m)
	local trophy = ball(top + Vector3.new(0, 6, 0), 5, Color3.fromRGB(255, 205, 40), Enum.Material.Neon, m, false)
	trophy.Transparency = 1
	local tl = Instance.new("PointLight")
	tl.Range = 40
	tl.Brightness = 3
	tl.Color = Color3.fromRGB(255, 220, 100)
	tl.Enabled = false
	tl.Parent = trophy
	local winPad = disc(top + Vector3.new(0, 0.3, 0), 7, 0.6, Color3.fromRGB(255, 205, 40), Enum.Material.Neon, m)
	winPad.Transparency = 1
	winPad.CanTouch = false
	CollectionService:AddTag(winPad, "Win")
	billboard(trophy, "🏆 القمة! 🏆", Color3.fromRGB(255, 230, 120))

	local fw = pt({ Size = Vector3.new(1, 1, 1), Position = top + Vector3.new(0, 14, 0), Transparency = 1, CanCollide = false }, m)
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
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
	arena2.winPad, arena2.pedestal, arena2.trophy, arena2.trophyLight, arena2.fireworks = winPad, pedestal, trophy, tl, e
end

------------------------------------------------------------------------
-- خط البداية وقاعدة العودة السريعة (الهب)
------------------------------------------------------------------------
do
	pt({
		Size = Vector3.new(22, 14, 2), Position = HUB_TOP + Vector3.new(0, 7, -40),
		Transparency = 1, CanCollide = false, CanQuery = false,
	}, Map, "StartLine")
	local pad = disc(HUB_TOP + Vector3.new(15, 0.3, 14), 3.2, 0.6, Color3.fromRGB(255, 205, 40), Enum.Material.Neon, Map)
	billboard(pad, "⚡ آخر نقطة حفظ", Color3.fromRGB(255, 240, 150))
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = "انتقال"
	pr.ObjectText = "آخر نقطة حفظ"
	pr.HoldDuration = 0.4
	pr.MaxActivationDistance = 12
	pr.RequiresLineOfSight = false
	pr.Parent = pad
	CollectionService:AddTag(pad, "ResumePad")
end

------------------------------------------------------------------------
-- المرحلة السرية: الحديقة الذهبية (بوابتها في الهب وتحتاج 3 نجوم مخفية) + المتجر الثاني
------------------------------------------------------------------------
local secret = {}
do
	-- بوابة في الهب
	local hm = Instance.new("Model")
	hm.Name = "SecretPortal"
	hm.Parent = Map
	local pc = HUB_TOP + Vector3.new(33, 8.5, -6)
	pt({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 17, 17), CFrame = CFrame.new(pc),
		Color = Color3.fromRGB(150, 90, 255), Material = Enum.Material.Neon }, hm)
	local inner = pt({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 13, 13), CFrame = CFrame.new(pc),
		Color = Color3.fromRGB(80, 200, 255), Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false }, hm)
	for _, dz in ipairs({ -8, 8 }) do
		pt({ Size = Vector3.new(2.5, 18, 2.5), Position = HUB_TOP + Vector3.new(33, 9, -6 + dz * 1.15),
			Color = Color3.fromRGB(40, 36, 70), Material = Enum.Material.Slate }, hm)
	end
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 40
	pe.Lifetime = NumberRange.new(1, 1.6)
	pe.Speed = NumberRange.new(1, 4)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(Color3.fromRGB(190, 150, 255), Color3.fromRGB(120, 230, 255))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
	pe.Parent = inner
	local pl = Instance.new("PointLight")
	pl.Range = 35
	pl.Color = Color3.fromRGB(150, 120, 255)
	pl.Parent = inner
	billboard(inner, "؟ بوابة سرية ؟\nاجمع 3 نجوم مخفية ⭐", Color3.fromRGB(230, 200, 255))
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = "ادخل"
	pr.ObjectText = "الحديقة الذهبية السرية"
	pr.HoldDuration = 0.6
	pr.MaxActivationDistance = 14
	pr.RequiresLineOfSight = false
	pr.Parent = inner
	CollectionService:AddTag(inner, "SecretPortal")

	-- العالم السري
	local C = HUB_TOP + Vector3.new(0, 110, 430)
	secret.center = C
	local GOLDEN = { top = Color3.fromRGB(255, 214, 110), topMat = Enum.Material.Sand, dirt = Color3.fromRGB(190, 130, 70), rock = Color3.fromRGB(120, 90, 80) }

	-- جزيرة البداية
	local a = -0.5
	local startPos = C + Vector3.new(math.cos(a) * 56, 0, math.sin(a) * 56)
	local sm = island(startPos, 8, GOLDEN)
	scatter(sm, startPos, 8, { flowers = 10, lamps = 2 })
	local sp = Instance.new("SpawnLocation")
	sp.Size = Vector3.new(6, 1, 6)
	sp.Anchored = true
	sp.Neutral = true
	sp.Duration = 0
	sp.Material = Enum.Material.Neon
	sp.Color = Color3.fromRGB(255, 220, 90)
	sp.CFrame = CFrame.new(startPos + Vector3.new(0, 0.5, 0))
	for _, d in ipairs(sp:GetChildren()) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	sp.Parent = sm
	secret.spawn = sp
	billboard(sp, "الحديقة السرية ✨", Color3.fromRGB(255, 240, 150))

	-- حلزون صاعد من منصات قوس قزح
	local ang, y = a, 0
	for i = 1, 16 do
		local R = 52 - i * 1.3
		ang = ang + 13 / R
		y = y + 3
		local pos = C + Vector3.new(math.cos(ang) * R, y, math.sin(ang) * R)
		local col = Color3.fromHSV((i / 16) % 1, 0.65, 1)
		local m = Instance.new("Model")
		m.Name = "SecretStep"
		m.Parent = Map
		disc(pos - Vector3.new(0, 0.6, 0), 4.4, 1.2, col, Enum.Material.Neon, m)
		disc(pos - Vector3.new(0, 2, 0), 2.6, 1.6, Color3.fromRGB(70, 56, 100), Enum.Material.Slate, m)
		local l = Instance.new("PointLight")
		l.Range = 18
		l.Color = col
		l.Parent = m:FindFirstChildWhichIsA("BasePart")
		coin(pos + Vector3.new(0, 3.5, 0))
		addPathPoint(pos)
		if i % 4 == 0 then
			jumpPad(pos + Vector3.new(0, 0.6, 0), 70, m)
		end
	end

	-- الجزيرة الكبيرة العلوية: الصندوق + المتجر الثاني + بوابة العودة
	local topPos = C + Vector3.new(0, y + 3, 0)
	local bm = island(topPos, 22, GOLDEN)
	bm.Name = "TreasureIsland"
	scatter(bm, topPos, 22, { flowers = 30, lamps = 6 })
	buildShop("✨ متجر الكنوز", topPos + Vector3.new(0, 0, 8), SHOP2, Color3.fromRGB(255, 200, 80))

	local chestPos = topPos + Vector3.new(0, 0, -14)
	local base = pt({ Size = Vector3.new(6, 3, 4), Position = chestPos + Vector3.new(0, 1.5, 0),
		Color = Color3.fromRGB(130, 84, 48), Material = Enum.Material.Wood }, bm, "Chest")
	local lid = pt({ Size = Vector3.new(6.2, 1.6, 4.2), Position = chestPos + Vector3.new(0, 3.8, 0),
		Color = Color3.fromRGB(255, 205, 40), Material = Enum.Material.Neon }, bm)
	pt({ Size = Vector3.new(1, 1.4, 0.4), Position = chestPos + Vector3.new(0, 3, -2.2),
		Color = Color3.fromRGB(255, 255, 200), Material = Enum.Material.Neon, CanCollide = false }, bm)
	local cl = Instance.new("PointLight")
	cl.Range = 30
	cl.Brightness = 2
	cl.Color = Color3.fromRGB(255, 220, 100)
	cl.Parent = lid
	billboard(base, "💰 صندوق الكنز", Color3.fromRGB(255, 230, 120))
	secret.lid = lid
	secret.lidClosed = lid.CFrame

	local exitPos = topPos + Vector3.new(16, 0, -10)
	local ex = disc(exitPos + Vector3.new(0, 0.3, 0), 4, 0.6, Color3.fromRGB(150, 90, 255), Enum.Material.Neon, bm)
	billboard(ex, "العودة للهب 🏝", Color3.fromRGB(230, 200, 255))
	local ep = Instance.new("ProximityPrompt")
	ep.ActionText = "عودة"
	ep.ObjectText = "الهب"
	ep.HoldDuration = 0.5
	ep.MaxActivationDistance = 12
	ep.RequiresLineOfSight = false
	ep.Parent = ex
	CollectionService:AddTag(ex, "SecretExit")

	weather(C + Vector3.new(0, 55, 0), Vector3.new(130, 1, 130), Color3.fromRGB(255, 235, 150), 60, 2, 6)
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

	-- شفق قطبي: شرائط نيون شفافة تتغير ألوانها
	for i = 1, 3 do
		local c = Vector3.new((minV.X + maxV.X) / 2, maxV.Y + 140 + i * 28, minV.Z - 260 - i * 60)
		local ribbon = pt({
			Size = Vector3.new(900, 90, 2), CFrame = CFrame.new(c) * CFrame.Angles(0, math.rad((i - 2) * 9), math.rad((i - 2) * 4)),
			Color = Color3.fromHSV(0.35 + i * 0.12, 0.7, 1), Material = Enum.Material.Neon,
			Transparency = 0.82, CanCollide = false, CanQuery = false, CanTouch = false,
		}, decor)
		table.insert(auroras, { part = ribbon, hue = 0.35 + i * 0.12, i = i })
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
			s.part.CFrame = CFrame.new(s.pivot) * CFrame.Angles(0, s.phase + t * s.speed, 0) * (s.localCF or CFrame.new())
		end
		for _, e in ipairs(enemies) do
			if e.alive then
				updateEnemy(e, t)
			end
		end
		for _, f in ipairs(floaters) do
			local a = f.angle + t * f.speed
			f.part.CFrame = CFrame.new(f.center + Vector3.new(math.cos(a) * f.radius, math.sin(t * 1.5 + f.bob) * 1.5, math.sin(a) * f.radius))
				* CFrame.Angles(t * 0.8, a, t * 0.5)
		end
		for _, au in ipairs(auroras) do
			au.part.Color = Color3.fromHSV((au.hue + math.sin(t * 0.15 + au.i) * 0.12) % 1, 0.7, 1)
			au.part.Transparency = 0.8 + math.sin(t * 0.4 + au.i * 2) * 0.06
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
local STAGE_NAMES = {
	"🌸 جزر الزهور", "🌀 المنصات المتحركة", "🌋 بركان الدوّامات",
	"❄️ الجبال الجليدية", "🔮 جسر الزجاج السحري", "⚡ برج النيون",
	"🌩 قلعة العاصفة", "🐉 معركة تيتان السماء", "☠ ممر العدم", "👑 معركة سيّد العدم",
}

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

-- المظاهر (من المتجر الثاني)
local function applyCosmetics(plr, char, root, hum)
	for _, d in ipairs(char:GetDescendants()) do
		if d.Name == "SkyCosmetic" then
			d:Destroy()
		end
	end
	local head = char:FindFirstChild("Head")
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	local function attach(part, to)
		part.Name = "SkyCosmetic"
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.Material = Enum.Material.Neon
		part.Parent = char
		local w = Instance.new("WeldConstraint")
		w.Part0 = to
		w.Part1 = part
		w.Parent = part
	end
	if plr:GetAttribute("Own_halo") and head then
		for i = 1, 8 do
			local a = (i / 8) * math.pi * 2
			local b = Instance.new("Part")
			b.Shape = Enum.PartType.Ball
			b.Size = Vector3.new(0.45, 0.45, 0.45)
			b.Color = Color3.fromRGB(255, 225, 90)
			b.CFrame = head.CFrame * CFrame.new(math.cos(a) * 1.1, 1.5, math.sin(a) * 1.1)
			attach(b, head)
		end
	end
	if plr:GetAttribute("Own_wings") and torso then
		for _, side in ipairs({ -1, 1 }) do
			for k = 1, 3 do
				local w = Instance.new("Part")
				w.Size = Vector3.new(0.25, 3.2 - k * 0.6, 0.9)
				w.Color = Color3.fromHSV(0.52 + k * 0.08, 0.6, 1)
				w.Transparency = 0.15
				w.CFrame = torso.CFrame * CFrame.new(side * (1.2 + k * 0.45), 1.2 - k * 0.5, 0.7)
					* CFrame.Angles(0, 0, side * math.rad(-25 - k * 12))
				attach(w, torso)
			end
		end
	end
	if plr:GetAttribute("Own_aura") then
		local e = Instance.new("ParticleEmitter")
		e.Name = "SkyCosmetic"
		e.Rate = 30
		e.Lifetime = NumberRange.new(0.8, 1.4)
		e.Speed = NumberRange.new(3, 7)
		e.SpreadAngle = Vector2.new(180, 180)
		e.LightEmission = 1
		e.Color = ColorSequence.new(Color3.fromRGB(255, 190, 255), Color3.fromRGB(255, 240, 150))
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
		e.Parent = root
	end
	if plr:GetAttribute("Own_ghost") then
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Name ~= "SkyCosmetic" then
				d.Material = Enum.Material.ForceField
			end
		end
	end
	if plr:GetAttribute("Own_shield") and not char:FindFirstChildOfClass("ForceField") then
		local ff = Instance.new("ForceField")
		ff.Visible = true
		ff.Parent = char
		Debris:AddItem(ff, 10)
	end
end

-- ترقيات المتجر
local pets = {}
local addTrail -- تُعرَّف لاحقاً

local function applyUpgrades(plr)
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then
		return
	end
	local speed = 18 + (plr:GetAttribute("Own_speed") and 6 or 0)
	plr:SetAttribute("BaseSpeed", speed)
	hum.WalkSpeed = speed
	hum.UseJumpPower = true
	hum.JumpPower = 55 + (plr:GetAttribute("Own_jump") and 15 or 0)
	local maxH = plr:GetAttribute("Own_hearts") and 150 or 100
	if hum.MaxHealth ~= maxH then
		hum.MaxHealth = maxH
		hum.Health = maxH
	end
	local tr = root:FindFirstChildOfClass("Trail")
	if tr and plr:GetAttribute("Own_trail") then
		tr.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 20, 20)),
		})
		tr.Lifetime = 0.8
	end
	if tr and plr:GetAttribute("Own_startrail") then
		tr.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 235, 140)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 60)),
		})
		tr.Lifetime = 1.3
	end
	applyCosmetics(plr, char, root, hum)
	if pets[plr] then
		pets[plr]:Destroy()
		pets[plr] = nil
	end
	if plr:GetAttribute("Own_pet") then
		local pet = pt({
			Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), Position = root.Position + Vector3.new(2, 3, 3),
			Color = Color3.fromRGB(190, 120, 255), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CanTouch = false,
		}, Map)
		local l = Instance.new("PointLight")
		l.Range = 16
		l.Color = pet.Color
		l.Parent = pet
		pets[plr] = pet
	end
end

RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for plr, pet in pairs(pets) do
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if root and pet.Parent then
			local target = (root.CFrame * CFrame.new(2.6, 2.4 + math.sin(t * 3) * 0.4, 3)).Position
			pet.Position = pet.Position:Lerp(target, 0.18)
		end
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	if pets[plr] then
		pets[plr]:Destroy()
		pets[plr] = nil
	end
end)

local function save(plr)
	local ls = plr:FindFirstChild("leaderstats")
	if not store or not ls then
		return
	end
	pcall(function()
		local owned = {}
		for _, it in ipairs(ALL_ITEMS) do
			if plr:GetAttribute("Own_" .. it.id) then
				table.insert(owned, it.id)
			end
		end
		local stars = {}
		for i = 1, 3 do
			if plr:GetAttribute("Star" .. i) then
				table.insert(stars, i)
			end
		end
		local ach = {}
		for _, a in ipairs(ACH) do
			if plr:GetAttribute("Ach_" .. a.id) then
				table.insert(ach, a.id)
			end
		end
		store:SetAsync("p" .. plr.UserId, {
			Coins = ls.Coins.Value, Wins = ls.Wins.Value, Owned = owned, Stars = stars, Secret = plr:GetAttribute("SecretDone") or false,
			Best = ls.Best.Value, Deaths = ls.Deaths.Value, Ach = ach, TotalCoins = plr:GetAttribute("TotalCoins") or 0,
			Kills = plr:GetAttribute("Kills") or 0, LastDay = plr:GetAttribute("LastDay"), Streak = plr:GetAttribute("Streak") or 0,
		})
	end)
end

-- منح إنجاز (مرة واحدة)
local function achieve(plr, id)
	local a = ACH_BY_ID[id]
	if not a or plr:GetAttribute("Ach_" .. id) then
		return
	end
	plr:SetAttribute("Ach_" .. id, true)
	local n = 0
	for _, x in ipairs(ACH) do
		if plr:GetAttribute("Ach_" .. x.id) then
			n = n + 1
		end
	end
	plr:SetAttribute("AchCount", n)
	local ls = plr:FindFirstChild("leaderstats")
	if ls then
		ls.Coins.Value = ls.Coins.Value + a.reward
	end
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if root then
		burst(root.Position + Vector3.new(0, 3, 0), Color3.fromRGB(255, 215, 80), 60, 40)
		sfx("checkpoint", root, 0.9, 1.2)
	end
	task.delay(1.2, function()
		if plr.Parent then
			toast(plr, "🏅 إنجاز: " .. a.name .. " (+" .. a.reward .. ")", Color3.fromRGB(255, 215, 90))
		end
	end)
	fx(plr, "achievement", a.name)
end

local function setupPlayer(plr)
	plr.RespawnLocation = hubSpawn -- أول ظهور دائماً في الهب

	local function onChar(char)
		if addTrail then
			addTrail(char)
		end
		applyUpgrades(plr)
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hum.Died:Connect(function()
				local l = plr:FindFirstChild("leaderstats")
				if l and l:FindFirstChild("Deaths") then
					l.Deaths.Value = l.Deaths.Value + 1
				end
			end)
		end
	end
	plr.CharacterAdded:Connect(onChar)
	if plr.Character then
		task.spawn(onChar, plr.Character)
	end

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local function stat(name)
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = ls
		return v
	end
	local stageV, coinsV, winsV = stat("Stage"), stat("Coins"), stat("Wins")
	local bestV, deathsV = stat("Best"), stat("Deaths")
	ls.Parent = plr

	if store then
		local ok, data = pcall(function()
			return store:GetAsync("p" .. plr.UserId)
		end)
		if ok and type(data) == "table" then
			coinsV.Value = data.Coins or 0
			winsV.Value = data.Wins or 0
			bestV.Value = data.Best or 0
			deathsV.Value = data.Deaths or 0
			plr:SetAttribute("TotalCoins", data.TotalCoins or 0)
			plr:SetAttribute("Kills", data.Kills or 0)
			plr:SetAttribute("LastDay", data.LastDay)
			plr:SetAttribute("Streak", data.Streak or 0)
			local achCount = 0
			for _, id in ipairs(data.Ach or {}) do
				if ACH_BY_ID[id] then
					plr:SetAttribute("Ach_" .. id, true)
					achCount = achCount + 1
				end
			end
			plr:SetAttribute("AchCount", achCount)
			for _, id in ipairs(data.Owned or {}) do
				if SHOP_BY_ID[id] then
					plr:SetAttribute("Own_" .. id, true)
				end
			end
			for _, id in ipairs(data.Stars or {}) do
				plr:SetAttribute("Star" .. id, true)
			end
			if data.Secret then
				plr:SetAttribute("SecretDone", true)
			end
			applyUpgrades(plr)
		end
	end
	task.delay(2, function()
		if plr.Parent then
			toast(plr, "أهلاً! اتجه للبوابة وابدأ المغامرة 🌈", Color3.fromRGB(255, 230, 120))
		end
	end)

	-- مكافأة يومية: تزداد مع تتابع الأيام (حتى 7)
	local today = math.floor(os.time() / 86400)
	local last = plr:GetAttribute("LastDay")
	if last ~= today then
		local streak = (last == today - 1) and ((plr:GetAttribute("Streak") or 0) + 1) or 1
		plr:SetAttribute("LastDay", today)
		plr:SetAttribute("Streak", streak)
		local reward = 10 * math.min(streak, 7)
		coinsV.Value = coinsV.Value + reward
		task.delay(5, function()
			if plr.Parent then
				toast(plr, "🎁 مكافأة يومية +" .. reward .. " عملة (اليوم " .. streak .. " على التوالي)", Color3.fromRGB(150, 230, 255))
			end
		end)
	end
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
			sfx("checkpoint", cp, 0.8)
			burst(cp.Position + Vector3.new(0, 4, 0), Color3.fromRGB(255, 220, 90), 60, 45)
			burst(cp.Position + Vector3.new(0, 4, 0), Color3.fromRGB(110, 230, 255), 40, 35)
			toast(plr, "✅ نقطة حفظ " .. stage .. " — +5 عملات", Color3.fromRGB(110, 255, 160))
			if stage == 9 then
				achieve(plr, "voidwalker")
			end
			task.delay(3.6, function()
				if STAGE_NAMES[stage + 1] and plr.Parent then
					toast(plr, "المرحلة القادمة: " .. STAGE_NAMES[stage + 1], Color3.fromRGB(120, 210, 255))
				end
			end)
		end
	end)
end)

-- العملات
local function collectCoin(plr, c)
	if c:GetAttribute("Taken") then
		return
	end
	c:SetAttribute("Taken", true)
	c.Transparency = 1
	burst(c.Position, Color3.fromRGB(255, 215, 70), 14, 22)
	sfx("coin", c, 0.5, 1 + math.random() * 0.2)
	local v = plr.leaderstats and plr.leaderstats:FindFirstChild("Coins")
	if v then
		v.Value = v.Value + 1
	end
	local total = (plr:GetAttribute("TotalCoins") or 0) + 1
	plr:SetAttribute("TotalCoins", total)
	if total >= 100 then
		achieve(plr, "coins100")
	end
	task.delay(15, function()
		c.Transparency = 0
		c:SetAttribute("Taken", nil)
	end)
end

onTag("Coin", function(c)
	c.Touched:Connect(function(hit)
		if c:GetAttribute("Taken") then
			return
		end
		local plr = fromHit(hit)
		if plr then
			collectCoin(plr, c)
		end
	end)
end)

-- مغناطيس العملات (من المتجر)
task.spawn(function()
	while true do
		task.wait(0.15)
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr:GetAttribute("Own_magnet") then
				local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if root then
					for _, c in ipairs(coins) do
						if not c.part:GetAttribute("Taken") and (c.part.Position - root.Position).Magnitude < 18 then
							collectCoin(plr, c.part)
						end
					end
				end
			end
		end
	end
end)

-- شراء من المتجر
onTag("ShopItem", function(stand)
	local prompt = stand:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(plr)
		local item = SHOP_BY_ID[stand:GetAttribute("ItemId")]
		local ls = plr:FindFirstChild("leaderstats")
		if not item or not ls then
			return
		end
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if plr:GetAttribute("Own_" .. item.id) then
			toast(plr, "تملك " .. item.name .. " بالفعل ✔", Color3.fromRGB(180, 200, 255))
			return
		end
		if ls.Coins.Value < item.price then
			toast(plr, "تحتاج " .. (item.price - ls.Coins.Value) .. " عملة إضافية 🪙", Color3.fromRGB(255, 120, 120))
			sfx("deny", root, 0.6)
			return
		end
		ls.Coins.Value = ls.Coins.Value - item.price
		plr:SetAttribute("Own_" .. item.id, true)
		applyUpgrades(plr)
		toast(plr, "🛍 اشتريت " .. item.name .. "!", item.color)
		local owned = 0
		for _, it in ipairs(ALL_ITEMS) do
			if plr:GetAttribute("Own_" .. it.id) then
				owned = owned + 1
			end
		end
		if owned >= 3 then
			achieve(plr, "shopper")
		end
		sfx("buy", root, 0.8)
		if root then
			burst(root.Position, item.color, 50, 40)
		end
		save(plr)
	end)
end)

-- الأعداء: دوس على الرأس لتقتل (الحارس لا يموت)، وإلا تتضرر وتُدفع للخلف
onTag("Enemy", function(part)
	part.Touched:Connect(function(hit)
		local e = enemies[part:GetAttribute("EnemyId")]
		if not e or not e.alive then
			return
		end
		local plr, _, hum, root = fromHit(hit)
		if not plr then
			return
		end
		local above = root.Position.Y > e.body.Position.Y + 1.5 and root.AssemblyLinearVelocity.Y < 8
		if e.killable and above then
			e.alive = false
			burst(e.body.Position, e.body.Color, 40, 35)
			sfx("stomp", root, 0.9)
			e.model.Parent = nil
			root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 65, root.AssemblyLinearVelocity.Z)
			local v = plr.leaderstats and plr.leaderstats:FindFirstChild("Coins")
			if v then
				v.Value = v.Value + 3
			end
			toast(plr, "💥 قضيت على عدو! +3 عملات", Color3.fromRGB(255, 220, 120))
			local kills = (plr:GetAttribute("Kills") or 0) + 1
			plr:SetAttribute("Kills", kills)
			if kills >= 10 then
				achieve(plr, "kills10")
			end
			fx(plr, "shake", 0.3, 0.2)
			task.delay(12, function()
				e.alive = true
				e.model.Parent = Map
			end)
		elseif cooldown(plr.UserId .. "dmg", 1) then
			hum:TakeDamage(e.dmg)
			fx(plr, "hurt", e.dmg)
			local away = (root.Position - e.body.Position) * Vector3.new(1, 0, 1)
			if away.Magnitude < 0.1 then
				away = Vector3.new(0, 0, 1)
			end
			root.AssemblyLinearVelocity = away.Unit * 55 + Vector3.new(0, 38, 0)
			burst(root.Position, Color3.fromRGB(255, 70, 70), 18, 25)
			sfx("hurt", root, 0.7)
		end
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
		sfx("jump", pad, 0.8, 1.5)
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
		sfx("push", bar, 0.7)
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

-- زجاج مزيّف ينكسر عند اللمس ثم يعود
onTag("FakeGlass", function(tile)
	tile.Touched:Connect(function(hit)
		if tile:GetAttribute("Broken") or not fromHit(hit) then
			return
		end
		tile:SetAttribute("Broken", true)
		burst(tile.Position, tile.Color, 30, 30)
		sfx("glass", tile, 0.9)
		task.wait(0.12)
		local glow = tile:FindFirstChild("GlassGlow")
		tile.Transparency = 1
		tile.CanCollide = false
		if glow then
			glow.Transparency = 1
		end
		task.wait(6)
		tile.Transparency = 0.3
		tile.CanCollide = true
		if glow then
			glow.Transparency = 0.55
		end
		tile:SetAttribute("Broken", nil)
	end)
end)

-- ذيل ملوّن خلف اللاعب
addTrail = function(char)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1.2, 0)
	a1.Position = Vector3.new(0, -1.2, 0)
	a0.Parent, a1.Parent = root, root
	local tr = Instance.new("Trail")
	tr.Attachment0, tr.Attachment1 = a0, a1
	tr.Lifetime = 0.5
	tr.LightEmission = 1
	tr.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 160)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 90)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 200, 255)),
	})
	tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	tr.Parent = root
end
-- أدوات عامة للمعارك
local function playersWithin(center, radius, yRange)
	local list = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local d = (root.Position - center) * Vector3.new(1, 0, 1)
			if d.Magnitude <= radius and math.abs(root.Position.Y - center.Y) <= (yRange or 60) then
				table.insert(list, { plr = plr, root = root, hum = hum })
			end
		end
	end
	return list
end

local function shakeNear(pos, radius, amount, secs)
	for _, e in ipairs(playersWithin(pos, radius, 80)) do
		fx(e.plr, "shake", amount, secs)
	end
end

local function hurt(entry, dmg, fromPos)
	entry.hum:TakeDamage(dmg)
	fx(entry.plr, "hurt", dmg)
	local away = (entry.root.Position - fromPos) * Vector3.new(1, 0, 1)
	if away.Magnitude < 0.1 then
		away = Vector3.new(0, 0, 1)
	end
	entry.root.AssemblyLinearVelocity = away.Unit * 50 + Vector3.new(0, 35, 0)
	burst(entry.root.Position, Color3.fromRGB(255, 70, 70), 16, 22)
	sfx("hurt", entry.root, 0.7)
end

local function warnDisc(pos, radius, secs)
	local d = disc(pos + Vector3.new(0, 0.3, 0), radius, 0.3, Color3.fromRGB(255, 50, 60), Enum.Material.Neon, Map)
	d.CanCollide, d.CanQuery, d.CanTouch = false, false, false
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < secs and d.Parent do
			d.Transparency = 0.2 + 0.4 * (math.sin((os.clock() - t0) * 14) + 1) / 2
			task.wait(0.05)
		end
		d:Destroy()
	end)
end

-- صواعق العاصفة (المرحلة 7): دائرة تحذير حمراء ثم صاعقة
local function strike(pos)
	warnDisc(pos, 5.5, 1.2)
	task.delay(1.2, function()
		local bolt = pt({
			Size = Vector3.new(2.5, 90, 2.5), Position = pos + Vector3.new(0, 45, 0), Color = Color3.fromRGB(255, 255, 170),
			Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CanTouch = false,
		}, Map)
		local l = Instance.new("PointLight")
		l.Range = 70
		l.Brightness = 6
		l.Color = bolt.Color
		l.Parent = bolt
		burst(pos, Color3.fromRGB(255, 255, 150), 40, 40)
		shakeNear(pos, 45, 0.6, 0.3)
		sfx("glass", bolt, 1, 0.7)
		Debris:AddItem(bolt, 0.3)
		for _, e in ipairs(playersWithin(pos, 6.5, 12)) do
			hurt(e, 30, pos)
		end
	end)
end

task.spawn(function()
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { Map }
	while true do
		task.wait(2.2)
		for _, plr in ipairs(Players:GetPlayers()) do
			local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if root and arena.stormMinX then
				local p = root.Position
				if p.X > arena.stormMinX and p.X < arena.stormMaxX and math.abs(p.Z - arena.stormZ) < 45 and p.Y > arena.stormY - 40 then
					local v = root.AssemblyLinearVelocity
					local target = p + Vector3.new(math.random(-14, 14) + v.X * 1.2, 0, math.random(-14, 14) + v.Z * 1.2)
					local res = Workspace:Raycast(target + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), rp)
					if res then
						strike(res.Position)
					end
				end
			end
		end
	end
end)

-- المعارك: أدوات عامة تستخدمها المعركتان
local bosses = { [1] = arena.boss, [2] = arena2.boss }

local function setBossHP(boss, hp)
	boss.hp = hp
	boss.fill.Size = UDim2.fromScale(math.max(hp, 0) / boss.maxHp, 1)
	boss.label.Text = boss.display .. "  " .. math.max(hp, 0) .. "/" .. boss.maxHp
end
local function setVulnerable(boss, v)
	boss.vulnerable = v
	boss.body.Material = v and Enum.Material.Neon or Enum.Material.Metal
	boss.body.Color = v and boss.vulnColor or boss.baseColor
end
setBossHP(bosses[1], bosses[1].maxHp)
setBossHP(bosses[2], bosses[2].maxHp)

local function meteor(pos)
	warnDisc(pos, 6, 1.1)
	task.delay(0.1, function()
		local m = ball(pos + Vector3.new(0, 70, 0), 5, Color3.fromRGB(255, 130, 40), Enum.Material.Neon, Map, false)
		m.CanQuery, m.CanTouch = false, false
		local tw = TweenService:Create(m, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = pos + Vector3.new(0, 2.5, 0) })
		tw:Play()
		tw.Completed:Wait()
		m.Transparency = 1
		Debris:AddItem(m, 3)
		burst(pos, Color3.fromRGB(255, 150, 50), 40, 45)
		shakeNear(pos, 45, 0.5, 0.35)
		sfx("glass", m, 1, 0.8)
		for _, e in ipairs(playersWithin(pos, 7, 10)) do
			hurt(e, 30, pos)
		end
	end)
end

local function shockwave(center, maxR)
	maxR = maxR or 36
	shakeNear(center, 70, 0.8, 0.5)
	local ring = pt({
		Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 8, 8), CFrame = CFrame.new(center + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(140, 220, 255), Material = Enum.Material.Neon, Transparency = 0.25,
		CanCollide = false, CanQuery = false, CanTouch = false,
	}, Map)
	local t0, dur, hit = os.clock(), 2.6, {}
	while true do
		local u = (os.clock() - t0) / dur
		if u >= 1 then
			break
		end
		local R = 4 + (maxR - 4) * u
		ring.Size = Vector3.new(3, R * 2, R * 2)
		ring.Transparency = 0.25 + 0.6 * u
		for _, e in ipairs(playersWithin(center, R + 3, 20)) do
			local d = ((e.root.Position - center) * Vector3.new(1, 0, 1)).Magnitude
			if math.abs(d - R) < 2.5 and e.root.Position.Y < center.Y + 4 and not hit[e.plr] then
				hit[e.plr] = true
				hurt(e, 25, center)
			end
		end
		task.wait(0.05)
	end
	ring:Destroy()
end

-- شعاع ليزر دوّار على الأرض (اقفز فوقه!)
local function laserSweep(boss, a, secs, speed, arms)
	local c = Vector3.new(boss.pos.X, a.center.Y, boss.pos.Z)
	local len = a.radius - 2
	local beams = {}
	for k = 1, arms do
		beams[k] = pt({
			Size = Vector3.new(len, 1.4, 1.4), CFrame = CFrame.new(c + Vector3.new(0, 1.2, 0)), Color = Color3.fromRGB(255, 50, 80),
			Material = Enum.Material.Neon, Transparency = 0.7, CanCollide = false, CanQuery = false, CanTouch = false,
		}, Map)
	end
	local ang, t0 = math.random() * math.pi * 2, os.clock()
	local last = t0
	while boss.alive and os.clock() - t0 < secs do
		local now = os.clock()
		local dt = now - last
		last = now
		local armed = now - t0 > 0.8
		ang = ang + speed * dt
		for k, bp in ipairs(beams) do
			local ak = ang + (k - 1) * math.pi * 2 / arms
			bp.CFrame = CFrame.new(c + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, -ak, 0) * CFrame.new(len / 2, 0, 0)
			bp.Transparency = armed and 0.05 or 0.7
			if armed then
				local dirv = Vector3.new(math.cos(ak), 0, math.sin(ak))
				for _, e in ipairs(playersWithin(a.center, a.radius + 5, 30)) do
					local rel = (e.root.Position - c) * Vector3.new(1, 0, 1)
					local along = rel:Dot(dirv)
					local perp = (rel - dirv * along).Magnitude
					if along > 0 and along < len and perp < 2.2 and e.root.Position.Y < a.center.Y + 4.2 and cooldown(e.plr.UserId .. "beam", 0.8) then
						hurt(e, 30, c)
					end
				end
			end
		end
		task.wait(0.03)
	end
	for _, bp in ipairs(beams) do
		bp:Destroy()
	end
end

-- كرات بنفسجية تلاحقك ببطء (اركض أسرع منها)
local function homingOrbs(boss, a, n, secs)
	for k = 1, n do
		task.spawn(function()
			local ang = k / n * math.pi * 2
			local orb = ball(boss.pos + Vector3.new(math.cos(ang) * 8, 0, math.sin(ang) * 8), 3, Color3.fromRGB(190, 80, 255), Enum.Material.Neon, Map, false)
			orb.CanQuery, orb.CanTouch = false, false
			local l = Instance.new("PointLight")
			l.Range = 14
			l.Color = orb.Color
			l.Parent = orb
			local t0, last = os.clock(), os.clock()
			while orb.Parent and os.clock() - t0 < secs and boss.alive do
				local now = os.clock()
				local dt = now - last
				last = now
				local target, best
				for _, e in ipairs(playersWithin(a.center, a.radius + 5, 30)) do
					local d = (e.root.Position - orb.Position).Magnitude
					if not best or d < best then
						best, target = d, e
					end
				end
				if target then
					local to = target.root.Position - orb.Position
					if to.Magnitude < 3.2 then
						hurt(target, 20, orb.Position)
						burst(orb.Position, orb.Color, 30, 35)
						break
					end
					orb.Position = orb.Position + to.Unit * math.min(13 * dt, to.Magnitude)
				end
				task.wait(0.03)
			end
			orb:Destroy()
		end)
	end
end

local function randomArenaSpot(a)
	local ang = math.random() * math.pi * 2
	local r = math.random() * (a.radius - 5)
	return a.center + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
end

-- أقفال: البوابة بعد الزعيم الأول، وقاعدة الفوز بعد الزعيم الثاني
local function setGate(open)
	arena.gate.CanCollide = not open
	arena.gate.Transparency = open and 1 or 0.55
	arena.gateGui.Enabled = not open
end
local function lockWin()
	arena2.winPad.Transparency, arena2.winPad.CanTouch = 1, false
	arena2.pedestal.Transparency, arena2.trophy.Transparency = 1, 1
	arena2.pedestal.CanCollide = false
	arena2.trophyLight.Enabled = false
	arena2.fireworks.Enabled = false
end
local function unlockWin()
	arena2.winPad.Transparency, arena2.winPad.CanTouch = 0, true
	arena2.pedestal.Transparency, arena2.trophy.Transparency = 0, 0
	arena2.pedestal.CanCollide = true
	arena2.trophyLight.Enabled = true
	arena2.fireworks.Enabled = true
end

bosses[1].onDefeat = function()
	setGate(true)
	for _, p in ipairs(Players:GetPlayers()) do
		toast(p, "🔓 فُتحت بوابة ممر العدم لمدة دقيقة!", Color3.fromRGB(190, 140, 255))
	end
	task.delay(60, function()
		setGate(false)
	end)
end
bosses[2].onDefeat = function()
	unlockWin()
	task.delay(40, lockWin)
end

local function defeatBoss(boss)
	boss.alive = false
	setVulnerable(boss, false)
	local p = boss.body.Position
	for _, c in ipairs({ Color3.fromRGB(255, 80, 120), Color3.fromRGB(255, 220, 80), Color3.fromRGB(80, 200, 255), Color3.fromRGB(190, 120, 255) }) do
		burst(p, c, 80, 70)
	end
	sfx("win", boss.body, 1)
	boss.model.Parent = nil
	shakeNear(p, 90, 1.3, 1.3)
	for _, e in ipairs(playersWithin(boss.arena.center, boss.arena.radius + 10, 60)) do
		achieve(e.plr, boss.id == 1 and "boss1" or "boss2")
		local v = e.plr.leaderstats and e.plr.leaderstats:FindFirstChild("Coins")
		if v then
			v.Value = v.Value + boss.reward
		end
		toast(e.plr, "🐉 هُزم " .. boss.display .. "! +" .. boss.reward .. " عملة", Color3.fromRGB(255, 220, 90))
	end
	boss.onDefeat()
	task.delay(boss.respawn, function()
		setBossHP(boss, boss.maxHp)
		boss.pos = boss.arena.center + Vector3.new(0, boss.hover * 3, 0)
		boss.target = boss.arena.center + Vector3.new(0, boss.hover, 0)
		boss.model.Parent = Map
		boss.alive = true
	end)
end

onTag("BossPart", function(part)
	part.Touched:Connect(function(hit)
		local boss = bosses[part:GetAttribute("BossId")]
		if not boss or not boss.alive then
			return
		end
		local plr, _, hum, root = fromHit(hit)
		if not plr then
			return
		end
		local above = root.Position.Y > boss.body.Position.Y + 5 * (boss.hover / 14) and root.AssemblyLinearVelocity.Y < 8
		if boss.vulnerable and above then
			if cooldown("bossHit" .. boss.id, 1.2) then
				root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 75, root.AssemblyLinearVelocity.Z)
				burst(boss.body.Position + Vector3.new(0, 6, 0), Color3.fromRGB(255, 200, 80), 50, 45)
				sfx("stomp", root, 1, 0.8)
				setBossHP(boss, boss.hp - 1)
				toast(plr, "💥 ضربة قوية! " .. math.max(boss.hp, 0) .. " متبقي", Color3.fromRGB(255, 200, 100))
				if boss.hp <= 0 then
					defeatBoss(boss)
				end
			end
		elseif cooldown(plr.UserId .. "bossdmg" .. boss.id, 1) then
			hurt({ plr = plr, hum = hum, root = root }, boss.contactDmg, boss.body.Position)
		end
	end)
end)

-- خطوات مشتركة داخل دورة الزعيم
local function chase(boss, a, steps)
	for _ = 1, steps do
		local l = playersWithin(a.center, a.radius + 12, 40)
		if #l > 0 and boss.alive then
			local pp = l[1].root.Position
			boss.target = Vector3.new(pp.X, a.center.Y + boss.hover, pp.Z)
			boss.face = pp
		end
		task.wait(0.2)
	end
end
local function slam(boss, a)
	boss.target = Vector3.new(boss.pos.X, a.center.Y + boss.ground, boss.pos.Z)
	task.wait(0.9)
	local ground = Vector3.new(boss.pos.X, a.center.Y, boss.pos.Z)
	burst(ground + Vector3.new(0, 1, 0), Color3.fromRGB(140, 220, 255), 60, 50)
	sfx("glass", boss.body, 1, 0.6)
	return ground
end
local function weakWindow(boss, a, steps)
	setVulnerable(boss, true)
	for _ = 1, steps do
		if not boss.alive then
			break
		end
		task.wait(0.2)
	end
	setVulnerable(boss, false)
	if boss.alive then
		boss.target = a.center + Vector3.new(0, boss.hover, 0)
	end
end
local function meteors(boss, a, n, interval)
	for i = 1, n do
		if not boss.alive then
			break
		end
		local spot = randomArenaSpot(a)
		if i % 3 == 0 then
			local l = playersWithin(a.center, a.radius, 40)
			if #l > 0 then
				spot = Vector3.new(l[1].root.Position.X, a.center.Y, l[1].root.Position.Z)
			end
		end
		meteor(spot)
		task.wait(interval)
	end
end

-- دورة تيتان السماء
local function cycle1(boss, a)
	local phase2 = boss.hp <= boss.maxHp / 2
	chase(boss, a, 15)
	if not boss.alive then
		return
	end
	local ground = slam(boss, a)
	task.spawn(shockwave, ground, a.radius)
	if phase2 then
		task.delay(1.1, function()
			task.spawn(shockwave, ground, a.radius)
		end)
	end
	weakWindow(boss, a, 30)
	if boss.alive then
		task.wait(1)
		meteors(boss, a, phase2 and 14 or 8, phase2 and 0.25 or 0.4)
		task.wait(1.8)
	end
end

-- دورة سيّد العدم: 3 أطوار، ليزر + موجات متتالية + نيازك + كرات تلاحقك، ونافذة ضعف أقصر
local function cycle2(boss, a)
	local phase = boss.hp > 10 and 1 or (boss.hp > 5 and 2 or 3)
	chase(boss, a, phase == 3 and 8 or 12)
	if not boss.alive then
		return
	end
	laserSweep(boss, a, phase == 1 and 3.5 or 4.5, phase == 3 and 1.9 or 1.4, phase == 1 and 1 or 2)
	if not boss.alive then
		return
	end
	chase(boss, a, 3)
	local ground = slam(boss, a)
	task.spawn(shockwave, ground, a.radius)
	if phase >= 2 then
		task.delay(0.9, function()
			task.spawn(shockwave, ground, a.radius)
		end)
	end
	if phase == 3 then
		task.delay(1.8, function()
			task.spawn(shockwave, ground, a.radius)
		end)
	end
	weakWindow(boss, a, phase == 3 and 16 or 20)
	if boss.alive then
		task.wait(0.6)
		homingOrbs(boss, a, phase + 1, 6)
		meteors(boss, a, ({ 12, 18, 26 })[phase], ({ 0.3, 0.22, 0.16 })[phase])
		task.wait(1.5)
	end
end

local function runBossLoop(boss, cycle)
	local a = boss.arena
	task.spawn(function()
		while true do
			task.wait(0.4)
			local list = boss.alive and playersWithin(a.center, a.radius + 12, 40) or {}
			if #list == 0 then
				if boss.alive then
					boss.target = a.center + Vector3.new(0, boss.hover, 0)
					setVulnerable(boss, false)
					if boss.hp < boss.maxHp then
						setBossHP(boss, boss.maxHp)
					end
				end
			else
				cycle(boss, a)
			end
		end
	end)
end
runBossLoop(bosses[1], cycle1)
runBossLoop(bosses[2], cycle2)

RunService.Heartbeat:Connect(function(dt)
	for _, boss in pairs(bosses) do
		if boss.alive then
			boss.pos = boss.pos:Lerp(boss.target, 1 - math.pow(0.02, dt))
			local bob = boss.vulnerable and 0 or math.sin(os.clock() * 2) * 0.8
			local at = Vector3.new(boss.face.X, boss.pos.Y, boss.face.Z)
			if (at - boss.pos).Magnitude < 0.5 then
				at = boss.pos + Vector3.new(0, 0, -1)
			end
			boss.model:PivotTo(CFrame.lookAt(boss.pos + Vector3.new(0, bob, 0), at))
		end
	end
end)

-- ممر العدم: بلاطات تنهار + مدافع
onTag("Crumble", function(tile)
	local busy = false
	tile.Touched:Connect(function(hit)
		if busy or not fromHit(hit) then
			return
		end
		busy = true
		tile.Transparency = 0.5
		task.wait(0.5)
		burst(tile.Position, tile.Color, 20, 20)
		tile.Transparency, tile.CanCollide = 1, false
		task.wait(4)
		tile.Transparency, tile.CanCollide = 0.15, true
		busy = false
	end)
end)

local function shoot(from, aim)
	local dirv = (aim - from).Unit
	local orb = ball(from, 2.6, Color3.fromRGB(255, 120, 40), Enum.Material.Neon, Map, false)
	orb.CanQuery, orb.CanTouch = false, false
	sfx("push", orb, 0.6, 1.6)
	local life, last = 0, os.clock()
	while life < 2.6 and orb.Parent do
		local now = os.clock()
		local dt = now - last
		last = now
		life = life + dt
		orb.Position = orb.Position + dirv * 42 * dt
		local hits = playersWithin(orb.Position, 3, 6)
		if #hits > 0 then
			hurt(hits[1], 25, orb.Position)
			burst(orb.Position, Color3.fromRGB(255, 130, 50), 25, 30)
			break
		end
		task.wait(0.03)
	end
	orb:Destroy()
end

task.spawn(function()
	while true do
		task.wait(0.1)
		local now = os.clock()
		for _, tr in ipairs(turrets) do
			if now >= tr.nextShot then
				local target, best = nil, 80
				for _, plr in ipairs(Players:GetPlayers()) do
					local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local d = (root.Position - tr.head.Position).Magnitude
						if d < best then
							best, target = d, root
						end
					end
				end
				if target then
					tr.nextShot = now + 2.8
					task.spawn(function()
						tr.head.Color = Color3.fromRGB(255, 255, 255)
						task.wait(0.55)
						tr.head.Color = Color3.fromRGB(255, 50, 60)
						if target.Parent then
							local travel = (target.Position - tr.head.Position).Magnitude / 42
							shoot(tr.head.Position, target.Position + target.AssemblyLinearVelocity * travel * 0.8)
						end
					end)
				else
					tr.nextShot = now + 0.5
				end
			end
		end
	end
end)

-- النجوم السرية والبوابة والصندوق
onTag("SecretStar", function(st)
	st.Touched:Connect(function(hit)
		local plr = fromHit(hit)
		if not plr then
			return
		end
		local id = st:GetAttribute("Id")
		if plr:GetAttribute("Star" .. id) then
			return
		end
		plr:SetAttribute("Star" .. id, true)
		local n = 0
		for i = 1, 3 do
			n = n + (plr:GetAttribute("Star" .. i) and 1 or 0)
		end
		burst(st.Position, Color3.fromRGB(255, 235, 90), 50, 40)
		sfx("checkpoint", st, 0.8, 1.3)
		toast(plr, "⭐ نجمة سرية " .. n .. "/3" .. (n == 3 and " — البوابة السرية في الهب فُتحت!" or ""), Color3.fromRGB(255, 235, 110))
		if n == 3 then
			achieve(plr, "explorer")
			save(plr)
		end
	end)
end)

onTag("SecretPortal", function(part)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(plr)
		local n = 0
		for i = 1, 3 do
			n = n + (plr:GetAttribute("Star" .. i) and 1 or 0)
		end
		if n < 3 then
			toast(plr, "تحتاج 3 نجوم مخفية — لديك " .. n .. "/3 ⭐ (ابحث عن جزر صغيرة جانبية)", Color3.fromRGB(255, 200, 120))
			sfx("deny", plr.Character and plr.Character:FindFirstChild("HumanoidRootPart"), 0.6)
			return
		end
		local char = plr.Character
		if char then
			plr.RespawnLocation = secret.spawn
			char:PivotTo(secret.spawn.CFrame + Vector3.new(0, 4, 0))
			toast(plr, "🌟 مرحباً في الحديقة الذهبية السرية!", Color3.fromRGB(255, 230, 120))
		end
	end)
end)

onTag("SecretExit", function(part)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(plr)
		plr.RespawnLocation = hubSpawn
		if plr.Character then
			plr.Character:PivotTo(hubSpawn.CFrame + Vector3.new(0, 4, 0))
		end
	end)
end)

onTag("Chest", function(chest)
	local opening = false
	chest.Touched:Connect(function(hit)
		local plr = fromHit(hit)
		if not plr or opening or not cooldown(plr.UserId .. "chest", 120) then
			return
		end
		opening = true
		local first = not plr:GetAttribute("SecretDone")
		local reward = first and 150 or 20
		plr:SetAttribute("SecretDone", true)
		achieve(plr, "treasure")
		local v = plr.leaderstats and plr.leaderstats:FindFirstChild("Coins")
		if v then
			v.Value = v.Value + reward
		end
		local lid, closed = secret.lid, secret.lidClosed
		local hinge = closed * CFrame.new(0, -0.8, 2.1) * CFrame.Angles(math.rad(-70), 0, 0) * CFrame.new(0, 0.8, -2.1)
		TweenService:Create(lid, TweenInfo.new(0.5, Enum.EasingStyle.Back), { CFrame = hinge }):Play()
		burst(chest.Position + Vector3.new(0, 4, 0), Color3.fromRGB(255, 215, 70), 120, 55)
		sfx("win", chest, 1)
		toast(plr, first and "💰 فتحت صندوق الكنز! +150 عملة" or "💰 صندوق الكنز: +20 عملة", Color3.fromRGB(255, 225, 100))
		save(plr)
		task.delay(4, function()
			TweenService:Create(lid, TweenInfo.new(0.4), { CFrame = closed }):Play()
			opening = false
		end)
	end)
end)

-- موسيقى المناطق (لكل لاعب على حدة، تظهر فقط عندما يكون داخل المنطقة)
local function zoneMusic(name, soundId, volume, inZone)
	if not soundId or soundId == "" then
		return
	end
	task.spawn(function()
		while true do
			task.wait(1)
			for _, plr in ipairs(Players:GetPlayers()) do
				local pg = plr:FindFirstChildOfClass("PlayerGui")
				local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if pg then
					local snd = pg:FindFirstChild(name)
					if not snd then
						snd = Instance.new("Sound")
						snd.Name = name
						snd.SoundId = soundId
						snd.Looped = true
						snd.Volume = 0
						snd.Parent = pg
					end
					local want = root ~= nil and inZone(root.Position)
					if want and not snd.IsPlaying then
						snd:Play()
					end
					TweenService:Create(snd, TweenInfo.new(1.2), { Volume = want and volume or 0 }):Play()
				end
			end
		end
	end)
end

local function inBossArena(boss, p)
	local ar = boss.arena
	return boss.alive and ((p - ar.center) * Vector3.new(1, 0, 1)).Magnitude < ar.radius + 14 and math.abs(p.Y - ar.center.Y) < 60
end
zoneMusic("BossMusic", BOSS_MUSIC, 0.5, function(p)
	return inBossArena(bosses[1], p)
end)
zoneMusic("Boss2Music", BOSS2_MUSIC, 0.55, function(p)
	return inBossArena(bosses[2], p)
end)
zoneMusic("SecretMusic", SECRET_MUSIC, 0.45, function(p)
	return (p - secret.center).Magnitude < 150 and p.Y > secret.center.Y - 20
end)

-- خط البداية: يبدأ عدّاد الزمن عند عبور بوابة الهب (والمرحلة 0)
onTag("StartLine", function(part)
	part.Touched:Connect(function(hit)
		local plr = fromHit(hit)
		if not plr or plr:GetAttribute("RunStart") then
			return
		end
		local sv = plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Stage")
		if sv and sv.Value == 0 then
			plr:SetAttribute("RunTime", nil)
			plr:SetAttribute("RunStart", Workspace:GetServerTimeNow())
			toast(plr, "⏱ بدأ عدّاد الزمن! بالتوفيق", Color3.fromRGB(150, 230, 255))
		end
	end)
end)

-- قاعدة الهب: الانتقال السريع لآخر نقطة حفظ وصلت إليها
onTag("ResumePad", function(pad)
	local prompt = pad:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(plr)
		local ls = plr:FindFirstChild("leaderstats")
		local n = ls and ls.Stage.Value or 0
		local sp = checkpointsByStage[n]
		if n <= 0 or not sp or not plr.Character then
			toast(plr, "لا توجد نقطة حفظ بعد — ابدأ المغامرة من البوابة!", Color3.fromRGB(255, 200, 120))
			return
		end
		plr.RespawnLocation = sp
		plr.Character:PivotTo(sp.CFrame + Vector3.new(0, 4, 0))
		toast(plr, "⚡ انتقلت إلى نقطة الحفظ " .. n, Color3.fromRGB(120, 230, 255))
	end)
end)

-- حدث دوري: مطر العملات في الهب + نصائح
local function tempCoin(pos, life)
	local c = pt({
		Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 3, 3), CFrame = CFrame.new(pos),
		Color = Color3.fromRGB(255, 205, 40), Material = Enum.Material.Neon, CanCollide = false,
	}, Map, "Coin")
	local rec = { part = c, pos = pos, phase = math.random() * 6 }
	table.insert(coins, rec)
	task.delay(life, function()
		local i = table.find(coins, rec)
		if i then
			table.remove(coins, i)
		end
		c:Destroy()
	end)
end

task.spawn(function()
	task.wait(240)
	while true do
		for _, p in ipairs(Players:GetPlayers()) do
			toast(p, "🌧 مطر العملات! عملات ذهبية ظهرت في الهب لمدة 40 ثانية", Color3.fromRGB(255, 220, 90))
		end
		for _ = 1, 40 do
			local a = math.random() * math.pi * 2
			local r = math.random() * 38
			tempCoin(HUB_TOP + Vector3.new(math.cos(a) * r, 4, math.sin(a) * r), 40)
		end
		task.wait(600)
	end
end)

local TIPS = {
	"💡 ادعس على رأس الأعداء لتقتلهم",
	"💡 ابحث عن 3 نجوم مخفية على جزر صغيرة جانبية",
	"💡 مغناطيس العملات يوفّر عليك الجري خلف العملات",
	"💡 القاعدة الذهبية بجانب النافورة تنقلك لآخر نقطة حفظ",
	"💡 الزعيم يضعف عندما يتوهج: ادعس على رأسه!",
	"💡 شاهد دوائر التحذير الحمراء: النيازك والصواعق تأتي بعدها",
}
task.spawn(function()
	task.wait(90)
	local i = 1
	while true do
		for _, p in ipairs(Players:GetPlayers()) do
			toast(p, TIPS[i], Color3.fromRGB(190, 220, 255))
		end
		i = i % #TIPS + 1
		task.wait(300)
	end
end)

-- الفوز
onTag("Win", function(w)
	w.Touched:Connect(function(hit)
		local plr, model = fromHit(hit)
		if not plr or not cooldown(plr.UserId .. "win", 8) then
			return
		end
		local ls = plr.leaderstats
		sfx("win", w, 1)
		local startT = plr:GetAttribute("RunStart")
		if startT then
			local elapsed = Workspace:GetServerTimeNow() - startT
			plr:SetAttribute("RunTime", elapsed)
			plr:SetAttribute("RunStart", nil)
			local secs = math.floor(elapsed)
			local label = string.format("%d:%02d", math.floor(secs / 60), secs % 60)
			local isBest = ls.Best.Value == 0 or secs < ls.Best.Value
			if isBest then
				ls.Best.Value = secs
			end
			task.delay(4, function()
				if plr.Parent then
					toast(plr, (isBest and "⏱ أفضل زمن جديد: " or "⏱ زمنك: ") .. label, Color3.fromRGB(150, 230, 255))
				end
			end)
			if elapsed <= 600 then
				achieve(plr, "speedy")
			end
		end
		achieve(plr, "champion")
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

if #MUSIC > 0 then
	task.spawn(function()
		local music = Instance.new("Sound")
		music.Name = "BackgroundMusic"
		music.Volume = 0.35
		music.Parent = Workspace
		local i = 1
		while true do
			music.SoundId = MUSIC[i]
			music:Play()
			music.Ended:Wait()
			i = i % #MUSIC + 1
		end
	end)
end

print("[SkyIslands] تم بناء الماب بنجاح ✔")
