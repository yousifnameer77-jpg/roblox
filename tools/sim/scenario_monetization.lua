
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
local function check(name, cond) print((cond and "PASS " or "FAIL ") .. name) end
local offers = tagged("RobuxOffer")
check("4 robux offers", #offers == 4)
for _, o in ipairs(offers) do o:FindFirstChildOfClass("ProximityPrompt").Triggered:Fire(plr) end
S.step(S.now() + 1)
local MS = game:GetService("MarketplaceService")
local pc = rawget(MS, "_p").ProcessReceipt
check("ProcessReceipt registered", pc ~= nil)
local c0 = stat("Coins")
local r = pc({ PlayerId = 1001, PurchaseId = "r1", ProductId = 333 })
check("receipt grants 500", stat("Coins") == c0 + 500 and r.Name == "PurchaseGranted")
local r2 = pc({ PlayerId = 1001, PurchaseId = "r1", ProductId = 333 })
check("duplicate receipt not re-granted", stat("Coins") == c0 + 500 and r2.Name == "PurchaseGranted")
local r3 = pc({ PlayerId = 999, PurchaseId = "x", ProductId = 333 })
check("unknown player -> NotProcessedYet", r3.Name == "NotProcessedYet")
MS.PromptGamePassPurchaseFinished:Fire(plr, 111, true)
MS.PromptGamePassPurchaseFinished:Fire(plr, 222, true)
S.step(S.now() + 1)
check("pass attributes", plr:GetAttribute("Pass_coins2x") and plr:GetAttribute("Pass_vip"))
local c1 = stat("Coins")
local coin = tagged("Coin")[5]
coin.Touched:Fire(root)
S.step(S.now() + 0.3)
check("coin x2", stat("Coins") == c1 + 2)
print("errors", #S.errors)
for i, e in ipairs(S.errors) do print(i, e) if i > 5 then break end end
