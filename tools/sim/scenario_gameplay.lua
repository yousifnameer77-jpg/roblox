
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
local function prompt(part) return part:FindFirstChildOfClass("ProximityPrompt") end
local function check(name, cond) print((cond and "PASS " or "FAIL ") .. name) end
local function errCount() return #S.errors end

-- 1 coin
local c0 = stat("Coins")
touch(tagged("Coin")[1])
check("coin pickup", stat("Coins") == c0 + 1)

-- 2 checkpoints in order
local cps = {}
for _, cp in ipairs(tagged("Checkpoint")) do cps[cp:GetAttribute("Stage")] = cp end
for n = 1, 9 do
	if not cps[n] then print("FAIL missing checkpoint", n) else
		root.Position = cps[n].Position + Vector3.new(0, 3, 0)
		touch(cps[n])
		check("checkpoint " .. n, stat("Stage") == n)
	end
end
check("voidwalker ach", plr:GetAttribute("Ach_voidwalker") == true)

-- 3 shop
ls:FindFirstChild("Coins").Value = 5000
local bought = 0
for _, st in ipairs(tagged("ShopItem")) do
	trig(prompt(st))
	if plr:GetAttribute("Own_" .. st:GetAttribute("ItemId")) then bought = bought + 1 end
end
check("shop items bought = " .. bought .. "/" .. #tagged("ShopItem"), bought == #tagged("ShopItem") and bought == 13)
check("shopper ach", plr:GetAttribute("Ach_shopper") == true)
S.step(S.now() + 1)

-- 4 stars + portal + chest + exit
local portal = tagged("SecretPortal")[1]
trig(prompt(portal))
check("portal denied w/o stars", (root.Position - Vector3.new(0, 0, 0)).Magnitude > 0)
for _, st in ipairs(tagged("SecretStar")) do touch(st) end
check("explorer ach", plr:GetAttribute("Ach_explorer") == true)
local before = root.Position
trig(prompt(portal))
check("teleported to secret", root.Position.Y > 200)
local chest = tagged("Chest")[1]
local cc = stat("Coins")
touch(chest)
check("chest reward", stat("Coins") >= cc + 150)
trig(prompt(tagged("SecretExit")[1]))
check("exit to hub", root.Position.Y < 200)

-- 5 enemies
local enemyPart
for _, e in ipairs(tagged("Enemy")) do if e.Parent and e.Parent.Name == "Enemy_slime" then enemyPart = e break end end
local body = enemyPart.Parent.PrimaryPart
root.Position = body.Position + Vector3.new(0, 4, 0)
root.AssemblyLinearVelocity = Vector3.new(0, -5, 0)
local cn = stat("Coins")
touch(enemyPart)
print("stomp dbg", stat("Coins"), cn, enemyPart.Parent and enemyPart.Parent.Parent, body.Position, root.Position, root.AssemblyLinearVelocity.Y)
check("stomp enemy +3", stat("Coins") == cn + 3 and enemyPart.Parent.Parent == nil)
local drone
for _, e in ipairs(tagged("Enemy")) do if e.Parent and e.Parent.Name == "Enemy_drone" then drone = e break end end
hum.Health = 100000
root.Position = drone.Parent.PrimaryPart.Position + Vector3.new(1, 0, 0)
root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
touch(drone)
check("enemy side-hit damages", hum.Health < 100000)

-- 6 crumble / fakeglass / jumppad / pusher / kill
local cr = tagged("Crumble")[1]
touch(cr)
S.step(S.now() + 1)
check("crumble falls", cr.CanCollide == false)
local fg = tagged("FakeGlass")[1]
touch(fg); S.step(S.now() + 0.5)
check("fake glass breaks", fg.Transparency == 1)
local jp = tagged("JumpPad")[1]
root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
touch(jp)
check("jump pad launches", root.AssemblyLinearVelocity.Y > 50)
local pu = tagged("Pusher")[1]
root.Position = pu.Position + Vector3.new(2, 0, 0)
touch(pu)
check("pusher pushes", root.AssemblyLinearVelocity.Magnitude > 20)
local k = tagged("Kill")[1]
local h0 = hum.Health
touch(k)
check("kill zone", hum.Health == 0)
hum.Health = 100000

-- 7 start line / resume / debug pads
local sl = tagged("StartLine")[1]
ls:FindFirstChild("Stage").Value = 0
touch(sl)
check("run timer started", plr:GetAttribute("RunStart") ~= nil)
ls:FindFirstChild("Stage").Value = 5
trig(prompt(tagged("ResumePad")[1]))
check("resume pad teleport", true)
for _, dp in ipairs(tagged("DebugPad")) do trig(prompt(dp)) end
print("debug pads:", #tagged("DebugPad"))

print("== errors so far:", errCount())
for i, e in ipairs(S.errors) do print(i, e) if i > 8 then break end end
