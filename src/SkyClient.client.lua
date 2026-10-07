--[[
	جزر السماء | سكربت العميل (اختياري، يُنصح به بشدة)
	ضعه كـ LocalScript داخل StarterPlayer ← StarterPlayerScripts.

	يضيف:
	  - واجهة (HUD): العملات، المرحلة مع شريط تقدم، عدّاد الزمن، الإنجازات
	  - جري (Shift) مع شريط طاقة، واندفاع Dash (Q) مع تبريد
	  - قفزة مزدوجة (تُشترى من المتجر)
	  - اهتزاز كاميرا عند الانفجارات وضربات الزعيم، ووميض أحمر عند التضرر
	  - اتساع زاوية الرؤية مع السرعة
	  - أزرار لمس للجوال
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local FxRemote = ReplicatedStorage:WaitForChild("SkyFx", 15)
local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local TOTAL_STAGES = 9
local TOTAL_ACH = 10
local SPRINT_MULT = 1.45
local DASH_COOLDOWN = 3
local STAMINA_DRAIN, STAMINA_REGEN = 28, 22

local INK = Color3.fromRGB(240, 244, 255)
local PANEL = Color3.fromRGB(18, 22, 44)
local GOLD = Color3.fromRGB(255, 205, 70)
local CYAN = Color3.fromRGB(110, 225, 255)
local RED = Color3.fromRGB(255, 70, 80)

------------------------------------------------------------------------
-- واجهة المستخدم
------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SkyClientHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local vignette = Instance.new("Frame")
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = RED
vignette.BackgroundTransparency = 1
vignette.BorderSizePixel = 0
vignette.ZIndex = 0
vignette.Parent = gui

local stack = Instance.new("Frame")
stack.Position = UDim2.new(0, 12, 0, 12)
stack.Size = UDim2.new(0, 210, 0, 0)
stack.AutomaticSize = Enum.AutomaticSize.Y
stack.BackgroundTransparency = 1
stack.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = stack

local function makePill(text)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 34)
	f.BackgroundColor3 = PANEL
	f.BackgroundTransparency = 0.18
	f.BorderSizePixel = 0
	f.Parent = stack
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = f
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(200, 215, 255)
	st.Transparency = 0.8
	st.Parent = f
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -16, 1, 0)
	l.Position = UDim2.new(0, 8, 0, 0)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextSize = 17
	l.TextColor3 = INK
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.Parent = f
	local sc = Instance.new("UIScale")
	sc.Parent = f
	return f, l, sc
end

local coinPill, coinLabel, coinScale = makePill("🪙 0")
coinLabel.TextColor3 = GOLD
local stagePill, stageLabel = makePill("المرحلة 0/" .. TOTAL_STAGES)
stagePill.Size = UDim2.new(1, 0, 0, 42)
stageLabel.Size = UDim2.new(1, -16, 0, 28)
local barBack = Instance.new("Frame")
barBack.Position = UDim2.new(0, 8, 1, -9)
barBack.Size = UDim2.new(1, -16, 0, 4)
barBack.BackgroundColor3 = Color3.fromRGB(60, 66, 100)
barBack.BorderSizePixel = 0
barBack.Parent = stagePill
local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = CYAN
barFill.BorderSizePixel = 0
barFill.Parent = barBack
local timerPill, timerLabel = makePill("⏱ 0:00.0")
timerPill.Visible = false
local achPill, achLabel, achScale = makePill("🏅 0/" .. TOTAL_ACH)

-- شريط الطاقة والاندفاع (أسفل الشاشة)
local bottom = Instance.new("Frame")
bottom.AnchorPoint = Vector2.new(0.5, 1)
bottom.Position = UDim2.new(0.5, 0, 1, -14)
bottom.Size = UDim2.new(0, 260, 0, 54)
bottom.BackgroundTransparency = 1
bottom.Parent = gui

local stamBack = Instance.new("Frame")
stamBack.Size = UDim2.new(1, 0, 0, 10)
stamBack.BackgroundColor3 = PANEL
stamBack.BackgroundTransparency = 0.25
stamBack.BorderSizePixel = 0
stamBack.Parent = bottom
local sc1 = Instance.new("UICorner")
sc1.CornerRadius = UDim.new(1, 0)
sc1.Parent = stamBack
local stamFill = Instance.new("Frame")
stamFill.Size = UDim2.fromScale(1, 1)
stamFill.BackgroundColor3 = Color3.fromRGB(120, 255, 160)
stamFill.BorderSizePixel = 0
stamFill.Parent = stamBack
local sc2 = Instance.new("UICorner")
sc2.CornerRadius = UDim.new(1, 0)
sc2.Parent = stamFill

local dashBack = Instance.new("Frame")
dashBack.Position = UDim2.new(0, 0, 0, 18)
dashBack.Size = UDim2.new(1, 0, 0, 6)
dashBack.BackgroundColor3 = PANEL
dashBack.BackgroundTransparency = 0.25
dashBack.BorderSizePixel = 0
dashBack.Parent = bottom
local sc3 = Instance.new("UICorner")
sc3.CornerRadius = UDim.new(1, 0)
sc3.Parent = dashBack
local dashFill = Instance.new("Frame")
dashFill.Size = UDim2.fromScale(1, 1)
dashFill.BackgroundColor3 = CYAN
dashFill.BorderSizePixel = 0
dashFill.Parent = dashBack
local sc4 = Instance.new("UICorner")
sc4.CornerRadius = UDim.new(1, 0)
sc4.Parent = dashFill

local hint = Instance.new("TextLabel")
hint.Position = UDim2.new(0, 0, 0, 28)
hint.Size = UDim2.new(1, 0, 0, 22)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.GothamMedium
hint.TextSize = 13
hint.TextColor3 = Color3.fromRGB(225, 232, 255)
hint.TextStrokeTransparency = 0.5
hint.Text = isTouch and "" or "Shift: جري  ·  Q: اندفاع"
hint.Parent = bottom

------------------------------------------------------------------------
-- الحركة: جري، اندفاع، قفزة مزدوجة
------------------------------------------------------------------------
local character, humanoid, root
local sprintHeld = false
local stamina, exhausted = 100, false
local lastDash = -100
local usedDouble, airStart = false, 0
local fovBoost = 0
local shakeAmp, shakeT, shakeDur = 0, 0, 0.01

local function bind(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	usedDouble, stamina, exhausted = false, 100, false
	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Freefall or new == Enum.HumanoidStateType.Jumping then
			if airStart == 0 then
				airStart = os.clock()
			end
		elseif new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running
			or new == Enum.HumanoidStateType.Climbing or new == Enum.HumanoidStateType.Swimming then
			usedDouble = false
			airStart = 0
		end
	end)
end
player.CharacterAdded:Connect(bind)
if player.Character then
	task.spawn(bind, player.Character)
end

local function doDash()
	if not humanoid or not root or humanoid.Health <= 0 or os.clock() - lastDash < DASH_COOLDOWN then
		return
	end
	lastDash = os.clock()
	local dir = humanoid.MoveDirection
	if dir.Magnitude < 0.1 then
		dir = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	end
	dir = dir.Unit
	fovBoost = 14
	task.spawn(function()
		for _ = 1, 6 do
			if not root or not root.Parent then
				break
			end
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(dir.X * 85, math.max(v.Y, 4), dir.Z * 85)
			task.wait(0.03)
		end
	end)
end

local function doDoubleJump()
	if not humanoid or not root or not player:GetAttribute("Own_double") or usedDouble then
		return
	end
	local st = humanoid:GetState()
	if (st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping)
		and airStart ~= 0 and os.clock() - airStart > 0.18 then
		usedDouble = true
		local v = root.AssemblyLinearVelocity
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		root.AssemblyLinearVelocity = Vector3.new(v.X, humanoid.JumpPower * 0.95, v.Z)
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		sprintHeld = true
	elseif input.KeyCode == Enum.KeyCode.Q then
		doDash()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		sprintHeld = false
	end
end)
UserInputService.JumpRequest:Connect(doDoubleJump)

-- أزرار الجوال
if isTouch then
	local function touchButton(text, y, onPress)
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(1, 1)
		b.Position = UDim2.new(1, -18, 1, y)
		b.Size = UDim2.new(0, 64, 0, 64)
		b.BackgroundColor3 = PANEL
		b.BackgroundTransparency = 0.25
		b.Font = Enum.Font.GothamBold
		b.TextSize = 14
		b.TextColor3 = INK
		b.Text = text
		b.Parent = gui
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = b
		b.Activated:Connect(onPress)
		return b
	end
	touchButton("اندفاع", -150, doDash)
	local sprintBtn = touchButton("جري", -226, function() end)
	sprintBtn.Activated:Connect(function()
		sprintHeld = not sprintHeld
		sprintBtn.BackgroundColor3 = sprintHeld and Color3.fromRGB(40, 120, 90) or PANEL
	end)
end

------------------------------------------------------------------------
-- مؤثرات من السيرفر
------------------------------------------------------------------------
local function shake(amount, secs)
	if amount > shakeAmp * (shakeT / shakeDur) then
		shakeAmp, shakeT, shakeDur = amount, secs, secs
	end
end

local function flashRed()
	vignette.BackgroundTransparency = 0.72
	TweenService:Create(vignette, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
end

local function pop(scale)
	scale.Scale = 1.18
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

if FxRemote then
	FxRemote.OnClientEvent:Connect(function(name, a, b)
		if name == "shake" then
			shake(tonumber(a) or 0.5, tonumber(b) or 0.4)
		elseif name == "hurt" then
			flashRed()
			shake(0.5, 0.25)
		elseif name == "achievement" then
			pop(achScale)
		end
	end)
end

------------------------------------------------------------------------
-- ربط البيانات
------------------------------------------------------------------------
task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 30)
	if not ls then
		return
	end
	local coins = ls:WaitForChild("Coins")
	local stage = ls:WaitForChild("Stage")
	local function updCoins()
		coinLabel.Text = "🪙 " .. coins.Value
		pop(coinScale)
	end
	local function updStage()
		stageLabel.Text = "المرحلة " .. stage.Value .. "/" .. TOTAL_STAGES
		TweenService:Create(barFill, TweenInfo.new(0.4), { Size = UDim2.fromScale(math.clamp(stage.Value / TOTAL_STAGES, 0, 1), 1) }):Play()
	end
	coins.Changed:Connect(updCoins)
	stage.Changed:Connect(updStage)
	coinLabel.Text = "🪙 " .. coins.Value
	updStage()
end)

local function updAch()
	achLabel.Text = "🏅 " .. (player:GetAttribute("AchCount") or 0) .. "/" .. TOTAL_ACH
end
player:GetAttributeChangedSignal("AchCount"):Connect(updAch)
updAch()

local function updHint()
	if isTouch then
		return
	end
	hint.Text = "Shift: جري  ·  Q: اندفاع" .. (player:GetAttribute("Own_double") and "  ·  Space×2: قفزة مزدوجة" or "")
end
player:GetAttributeChangedSignal("Own_double"):Connect(updHint)
updHint()

------------------------------------------------------------------------
-- الحلقة الرئيسية
------------------------------------------------------------------------
local timerAcc = 0
RunService.RenderStepped:Connect(function(dt)
	-- عدّاد الزمن
	timerAcc = timerAcc + dt
	if timerAcc > 0.1 then
		timerAcc = 0
		local startT = player:GetAttribute("RunStart")
		local finished = player:GetAttribute("RunTime")
		local t
		if startT then
			t = Workspace:GetServerTimeNow() - startT
		elseif finished then
			t = finished
		end
		timerPill.Visible = t ~= nil
		if t then
			timerLabel.Text = string.format("⏱ %d:%04.1f", math.floor(t / 60), t % 60)
			timerLabel.TextColor3 = startT and INK or GOLD
		end
	end

	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	-- جري وطاقة
	local base = player:GetAttribute("BaseSpeed") or 18
	local moving = humanoid.MoveDirection.Magnitude > 0.1
	local sprinting = sprintHeld and moving and stamina > 0 and not exhausted
	humanoid.WalkSpeed = sprinting and base * SPRINT_MULT or base
	if sprinting then
		stamina = math.max(0, stamina - STAMINA_DRAIN * dt)
		if stamina <= 0 then
			exhausted = true
		end
	else
		stamina = math.min(100, stamina + STAMINA_REGEN * dt)
		if exhausted and stamina >= 25 then
			exhausted = false
		end
	end
	stamFill.Size = UDim2.fromScale(stamina / 100, 1)
	stamFill.BackgroundColor3 = exhausted and RED or Color3.fromRGB(120, 255, 160)
	dashFill.Size = UDim2.fromScale(math.clamp((os.clock() - lastDash) / DASH_COOLDOWN, 0, 1), 1)

	-- زاوية الرؤية مع السرعة
	local v = root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	fovBoost = fovBoost * math.max(0, 1 - dt * 5)
	local targetFov = 70 + math.clamp((speed - base) * 0.6, 0, 12) + fovBoost
	camera.FieldOfView = camera.FieldOfView + (targetFov - camera.FieldOfView) * math.min(1, dt * 6)

	-- اهتزاز الكاميرا
	if shakeT > 0 then
		shakeT = shakeT - dt
		local k = math.max(shakeT, 0) / shakeDur * shakeAmp
		humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * 2 * k, (math.random() - 0.5) * 2 * k, 0)
	elseif humanoid.CameraOffset.Magnitude > 0.01 then
		humanoid.CameraOffset = humanoid.CameraOffset * 0.8
	end
end)
