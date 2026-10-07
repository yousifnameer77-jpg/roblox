
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
local function tagged(tag) return __tagged[tag] or {} end
local cps = {}
for _, cp in ipairs(tagged("Checkpoint")) do cps[cp:GetAttribute("Stage")] = cp end
hum.Health = hum.MaxHealth
root.Position = cps[6].Position + Vector3.new(40, 3, 0)
local h0 = hum.Health
S.step(S.now() + 30)
print("storm health delta:", h0 - hum.Health)
-- long run at hub: coin rain, tips, autosave
root.Position = Vector3.new(0, 125, 24)
S.step(S.now() + 900)
local coinsAlive = 0
for _, c in ipairs(tagged("Coin")) do if c.Parent then coinsAlive = coinsAlive + 1 end end
print("coins alive after long run:", coinsAlive)
-- player leaving
Players.PlayerRemoving:Fire(plr)
S.step(S.now() + 5)
print("errors", #S.errors)
for i, e in ipairs(S.errors) do print(i, e) if i > 5 then break end end
