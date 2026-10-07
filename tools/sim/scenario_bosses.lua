
-- ===== driver =====
if not ok then print("LOAD ERROR:", err) end
local S = __sim
local Players = game:GetService("Players")
local function mkPlayer(name, id)
	local plr = Instance.new("Player")
	plr.Name = name; plr.UserId = id; plr.DisplayName = name
	local gui = Instance.new("PlayerGui"); gui.Parent = plr
	local char = Instance.new("Model"); char.Name = name
	local hum = Instance.new("Humanoid"); hum.Parent = char
	hum.MaxHealth = 100000; hum.Health = 100000
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Parent = char
	root.Position = Vector3.new(0, 125, 24)
	local head = Instance.new("Part"); head.Name = "Head"; head.Parent = char
	local torso = Instance.new("Part"); torso.Name = "UpperTorso"; torso.Parent = char
	char.PrimaryPart = root
	char.Parent = workspace
	plr.Character = char
	table.insert(rawget(Players, "_players"), plr)
	return plr, char, hum, root
end
local plr, char, hum, root = mkPlayer("Tester", 1001)
Players.PlayerAdded:Fire(plr)
plr.CharacterAdded:Fire(char)
S.step(3)
local Map = workspace:FindFirstChild("SkyIslands")
local ls = plr:FindFirstChild("leaderstats")
local function stat(n) return ls:FindFirstChild(n).Value end
local function tagged(tag) return __tagged[tag] or {} end
local function touch(part, hitPart) part.Touched:Fire(hitPart or root) S.step(S.now() + 0.2) end
local function trig(prompt) prompt.Triggered:Fire(plr) S.step(S.now() + 0.2) end
local Map = workspace:FindFirstChild("SkyIslands")
local ls = plr:FindFirstChild("leaderstats")
local function stat(n) return ls:FindFirstChild(n).Value end
local function tagged(tag) return __tagged[tag] or {} end
local function touch(part, hitPart) part.Touched:Fire(hitPart or root) S.step(S.now() + 0.2) end
local function check(name, cond) print((cond and "PASS " or "FAIL ") .. name) end

-- run timer
ls:FindFirstChild("Stage").Value = 0
touch(tagged("StartLine")[1])
S.step(S.now() + 5)

local function fightBoss(name, hover, maxTime)
	local model = Map:FindFirstChild(name)
	local body = model.PrimaryPart
	local center = body.Position - Vector3.new(0, hover, 0)
	root.Position = center + Vector3.new(0, 3.5, 20)
	local t0 = S.now()
	local hits, minHp = 0, 99
	while S.now() - t0 < maxTime do
		S.step(S.now() + 0.25)
		hum.Health = hum.MaxHealth
		if model.Parent == nil then break end
		if body.Material == Enum.Material.Neon then
			root.Position = body.Position + Vector3.new(0, 9, 0)
			root.AssemblyLinearVelocity = Vector3.new(0, -5, 0)
			body.Touched:Fire(root)
			hits = hits + 1
		else
			root.Position = center + Vector3.new(0, 3.5, 20)
			root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	end
	return model.Parent == nil, S.now() - t0, hits
end

local gate
for _, c in ipairs(Map:GetChildren()) do
	if c.ClassName == "Part" and c.Size.Z == 44 and c.Size.Y == 32 then gate = c end
end
check("gate found & closed", gate and gate.CanCollide == true)

local dead, secs, hits = fightBoss("SkyTitan", 14, 400)
print("boss1 defeated:", dead, "after sim seconds:", math.floor(secs), "stomp touches:", hits)
check("boss1 defeated", dead)
check("gate opened", gate.CanCollide == false)
check("boss1 achievement", plr:GetAttribute("Ach_boss1") == true)
S.step(S.now() + 50)
check("boss1 respawned", Map:FindFirstChild("SkyTitan") ~= nil and Map:FindFirstChild("SkyTitan").Parent ~= nil)
S.step(S.now() + 15)
check("gate closed again", gate.CanCollide == true)

local dead2, secs2, hits2 = fightBoss("VoidLord", 17.5, 600)
print("boss2 defeated:", dead2, "after sim seconds:", math.floor(secs2), "stomp touches:", hits2)
check("boss2 defeated", dead2)
check("boss2 achievement", plr:GetAttribute("Ach_boss2") == true)
local win = tagged("Win")[1]
check("win pad unlocked", win.CanTouch == true and win.Transparency == 0)
touch(win)
check("win recorded", stat("Wins") == 1)
check("best time saved", stat("Best") > 0)
check("champion ach", plr:GetAttribute("Ach_champion") == true)
S.step(S.now() + 60)
check("win pad locks again", win.CanTouch == false)

-- turrets and storm exposure
local turretHead
for _, d in ipairs(Map:GetDescendants()) do
	if d.ClassName == "Part" and d.Size.X == 4 and d.Size.Y == 4 and d.Color.R == 1 and d.Material == Enum.Material.Neon and d.Position.Y > 200 then turretHead = d break end
end
if turretHead then
	hum.Health = hum.MaxHealth
	root.Position = turretHead.Position + Vector3.new(0, -12, 20)
	local h0 = hum.Health
	S.step(S.now() + 12)
	print("turret test: health delta", h0 - hum.Health)
end
print("== errors:", #S.errors)
for i, e in ipairs(S.errors) do print(i, e) if i > 8 then break end end
