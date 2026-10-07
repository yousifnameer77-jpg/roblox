-- ===== Roblox mock (minimal, permissive) =====
local simTime = 0
local errors = {}
local function logErr(where, msg)
	table.insert(errors, where .. ": " .. tostring(msg))
	print("[ERROR] " .. where .. ": " .. tostring(msg))
end
local __clock = function() return simTime end

-- Vector3
local V3 = {}
local V3m = {}
local V3methods = {}
V3m.__index = function(t, k)
	if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z) end
	if k == "Unit" then
		local m = math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
		if m == 0 then return V3.new(0, 0, 0) end
		return V3.new(t.X / m, t.Y / m, t.Z / m)
	end
	return V3methods[k]
end
function V3.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3m) end
V3.zero = V3.new(0, 0, 0)
function V3methods.Dot(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
function V3methods.Cross(a, b) return V3.new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end
function V3methods.Lerp(a, b, t) return V3.new(a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t, a.Z + (b.Z - a.Z) * t) end
V3m.__add = function(a, b) return V3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3m.__sub = function(a, b) return V3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3m.__unm = function(a) return V3.new(-a.X, -a.Y, -a.Z) end
V3m.__mul = function(a, b)
	if type(a) == "number" then return V3.new(a * b.X, a * b.Y, a * b.Z) end
	if type(b) == "number" then return V3.new(a.X * b, a.Y * b, a.Z * b) end
	return V3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3m.__div = function(a, b)
	if type(b) == "number" then return V3.new(a.X / b, a.Y / b, a.Z / b) end
	return V3.new(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3m.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
V3m.__tostring = function(a) return string.format("(%.1f, %.1f, %.1f)", a.X, a.Y, a.Z) end
local Vector3 = V3

-- CFrame (position only; rotations ignored)
local CF = {}
local CFm = {}
local CFmethods = {}
CFm.__index = function(t, k)
	if k == "Position" then return t.p end
	if k == "X" then return t.p.X end
	if k == "Y" then return t.p.Y end
	if k == "Z" then return t.p.Z end
	if k == "LookVector" then return t.look or V3.new(0, 0, -1) end
	if k == "RightVector" then return V3.new(1, 0, 0) end
	if k == "UpVector" then return V3.new(0, 1, 0) end
	return CFmethods[k]
end
local function mkcf(p, look) return setmetatable({ p = p, look = look }, CFm) end
function CF.new(a, b, c)
	if a == nil then return mkcf(V3.new(0, 0, 0)) end
	if type(a) == "number" then return mkcf(V3.new(a, b, c)) end
	return mkcf(a)
end
function CF.Angles() return mkcf(V3.new(0, 0, 0)) end
function CF.lookAt(a, b)
	local d = b - a
	return mkcf(a, d.Magnitude > 0 and d.Unit or V3.new(0, 0, -1))
end
CF.identity = mkcf(V3.new(0, 0, 0))
CFm.__mul = function(a, b)
	if getmetatable(b) == V3m then return a.p + b end
	return mkcf(a.p + b.p, a.look)
end
CFm.__add = function(a, b) return mkcf(a.p + b, a.look) end
CFm.__sub = function(a, b) return mkcf(a.p - b, a.look) end
local CFrame = CF

-- Color3 and plain constructors
local C3m = {}
C3m.__index = function(t, k) return nil end
local C3 = {}
function C3.new(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3m) end
function C3.fromRGB(r, g, b) return C3.new(r / 255, g / 255, b / 255) end
function C3.fromHSV(h, s, v) assert(type(h) == "number" and h == h, "bad hue"); return C3.new(v, v * (1 - s), v * (1 - s * 0.5)) end
C3m.__index = { Lerp = function(a, b, t) return C3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t) end }
C3m.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end
local Color3 = C3
local function plain(name) return { new = function(...) return { _t = name, ... } end } end
local NumberSequence = plain("NumberSequence")
local NumberSequenceKeypoint = plain("NumberSequenceKeypoint")
local ColorSequence = plain("ColorSequence")
local ColorSequenceKeypoint = plain("ColorSequenceKeypoint")
local NumberRange = plain("NumberRange")
local Vector2 = plain("Vector2")
local UDim = plain("UDim")
local UDim2 = { new = function(...) return { ... } end, fromScale = function(...) return { ... } end, fromOffset = function(...) return { ... } end }
local TweenInfo = { new = function(t, ...) return { Time = t or 1 } end }
local RaycastParams = { new = function() return {} end }
local Random = { new = function() return {
	NextNumber = function(_, a, b) return a + (b - a) * math.random() end,
	NextInteger = function(_, a, b) return math.random(a, b) end,
} end }

-- Enum
local enumCache = {}
local Enum = setmetatable({}, { __index = function(_, en)
	return setmetatable({}, { __index = function(_, item)
		local k = en .. "." .. item
		if not enumCache[k] then enumCache[k] = { Name = item, EnumType = en } end
		return enumCache[k]
	end })
end })

-- Scheduler
local queue = {}
local function enqueue(co, t) table.insert(queue, { t = t, co = co }) end
local function resume(co, ...)
	local ok, res = coroutine.resume(co, ...)
	if not ok then
		logErr("thread", res .. "\n" .. debug.traceback(co))
	elseif coroutine.status(co) == "suspended" then
		enqueue(co, simTime + (type(res) == "number" and res or 0))
	end
end
local task = {
	spawn = function(f, ...) local co = coroutine.create(f); resume(co, ...); return co end,
	defer = function(f, ...) local co = coroutine.create(f); enqueue(co, simTime); end,
	delay = function(t, f, ...)
		local args = { ... }
		local co = coroutine.create(function() return f(table.unpack(args)) end)
		-- first resume happens when time arrives: wrap with a waiter
		local waiter = coroutine.create(function() coroutine.yield(t); resume(co) end)
		resume(waiter)
		return waiter
	end,
	wait = function(t)
		if not coroutine.isyieldable() then return 0 end
		coroutine.yield(t or 0.03)
		return t or 0.03
	end,
}
-- fix delay: use a proper chain
task.delay = function(t, f, ...)
	local args = { ... }
	local co = coroutine.create(function() f(table.unpack(args)) end)
	enqueue(co, simTime + t)
	return co
end
task.defer = function(f, ...)
	local args = { ... }
	local co = coroutine.create(function() f(table.unpack(args)) end)
	enqueue(co, simTime)
	return co
end

-- Signals
local function newSignal()
	local sig = { handlers = {} }
	function sig:Connect(fn)
		table.insert(self.handlers, fn)
		return { Disconnect = function() end }
	end
	sig.Once = sig.Connect
	function sig:Wait() task.wait(0.5) end
	function sig:Fire(...)
		for _, h in ipairs(self.handlers) do
			local args = { ... }
			local co = coroutine.create(function() h(table.unpack(args)) end)
			resume(co)
		end
	end
	return sig
end

-- Instances
local BASEPARTS = { Part = true, SpawnLocation = true, MeshPart = true, WedgePart = true }
local EVENTS = {
	Touched = true, Triggered = true, Changed = true, Died = true, StateChanged = true, Ended = true, Completed = true,
	Heartbeat = true, RenderStepped = true, PromptGamePassPurchaseFinished = true, PlayerAdded = true, PlayerRemoving = true, CharacterAdded = true, JumpRequest = true,
	OnClientEvent = true, OnServerEvent = true, ChildAdded = true, InputBegan = true, InputEnded = true,
}
local DEFAULTS = {
	Transparency = 0, CanCollide = true, CanTouch = true, CanQuery = true, Anchored = false, Massless = false,
	Health = 100, MaxHealth = 100, WalkSpeed = 16, JumpPower = 50, Value = 0, Text = "", Enabled = true, Rate = 20,
	Volume = 0.5, IsPlaying = false, Brightness = 1, Range = 8, Name = "Instance", MaxActivationDistance = 10,
}
local allInstances = setmetatable({}, { __mode = "k" })
local methods = {}
local makeInst
local function descendants(o, out)
	out = out or {}
	for _, c in ipairs(rawget(o, "_ch")) do
		table.insert(out, c)
		descendants(c, out)
	end
	return out
end
local instMt = {}
instMt.__index = function(self, k)
	local props = rawget(self, "_p")
	if props[k] ~= nil then return props[k] end
	if k == "Parent" then return rawget(self, "_parent") end
	do
		local class = rawget(self, "_class")
		if API[class] and not hasMember(class, k) then
			for _, c in ipairs(rawget(self, "_ch")) do if c.Name == k then return c end end
			error(tostring(k) .. " is not a valid member of " .. class, 2)
		end
	end
	if EVENTS[k] then
		local ev = rawget(self, "_ev")
		if not ev[k] then ev[k] = newSignal() end
		return ev[k]
	end
	if methods[k] then return methods[k] end
	if k == "Position" then return V3.new(0, 0, 0) end
	if k == "CFrame" then return CF.new() end
	if k == "Size" then return V3.new(4, 1, 2) end
	if k == "Color" then return C3.new(0.6, 0.6, 0.6) end
	if k == "AssemblyLinearVelocity" then return V3.new(0, 0, 0) end
	if k == "MoveDirection" then return V3.new(0, 0, 0) end
	if k == "CameraOffset" then return V3.new(0, 0, 0) end
	if DEFAULTS[k] ~= nil then return DEFAULTS[k] end
	if k == "ClassName" then return rawget(self, "_class") end
	return nil
end
local function setParent(self, p)
	local old = rawget(self, "_parent")
	if old then
		local ch = rawget(old, "_ch")
		for i, c in ipairs(ch) do if c == self then table.remove(ch, i) break end end
	end
	rawset(self, "_parent", p)
	if p then table.insert(rawget(p, "_ch"), self) end
end
instMt.__newindex = function(self, k, v)
	local props = rawget(self, "_p")
	do
		local class = rawget(self, "_class")
		if API[class] and not hasMember(class, k) then
			error(tostring(k) .. " is not a valid member of " .. class .. " (set)", 2)
		end
	end
	if k == "Parent" then setParent(self, v) return end
	if k == "CFrame" then
		props.CFrame = v
		props.Position = v.p
		return
	end
	if k == "Position" then
		props.Position = v
		props.CFrame = CF.new(v)
		return
	end
	props[k] = v
	local ev = rawget(self, "_ev")
	if ev.Changed then ev.Changed:Fire(v) end
	if ev["_attr_" .. k] then ev["_attr_" .. k]:Fire() end
end
instMt.__tostring = function(self) return rawget(self, "_class") .. ":" .. tostring(rawget(self, "_p").Name) end
makeInst = function(class)
	local self = setmetatable({ _class = class, _p = { Name = class }, _ch = {}, _ev = {}, _attr = {}, _parent = nil }, instMt)
	if class == "SpawnLocation" then rawget(self, "_p").Shape = Enum.PartType.Block end
	return self
end
local function isA(self, cls)
	local c = rawget(self, "_class")
	if c == cls then return true end
	if cls == "BasePart" then return BASEPARTS[c] == true end
	if cls == "PVInstance" then return BASEPARTS[c] == true or c == "Model" end
	return false
end
local Instance = { new = function(class) if not API[class] then error("Unable to create an Instance of type " .. tostring(class), 2) end return makeInst(class) end }

methods.IsA = isA
methods.Destroy = function(self) setParent(self, nil); rawget(self, "_p")._destroyed = true end
methods.Clone = function(self)
	local n = makeInst(rawget(self, "_class"))
	for k, v in pairs(rawget(self, "_p")) do rawget(n, "_p")[k] = v end
	for k, v in pairs(rawget(self, "_attr")) do rawget(n, "_attr")[k] = v end
	for _, c in ipairs(rawget(self, "_ch")) do local cc = methods.Clone(c); setParent(cc, n) end
	return n
end
methods.GetChildren = function(self) local t = {} for i, c in ipairs(rawget(self, "_ch")) do t[i] = c end return t end
methods.GetDescendants = function(self) return descendants(self) end
methods.FindFirstChild = function(self, name, rec)
	for _, c in ipairs(rawget(self, "_ch")) do if c.Name == name then return c end end
	if rec then for _, c in ipairs(descendants(self)) do if c.Name == name then return c end end end
	return nil
end
methods.WaitForChild = function(self, name) return methods.FindFirstChild(self, name) end
methods.FindFirstChildOfClass = function(self, cls)
	for _, c in ipairs(rawget(self, "_ch")) do if rawget(c, "_class") == cls then return c end end
	return nil
end
methods.FindFirstChildWhichIsA = function(self, cls)
	for _, c in ipairs(rawget(self, "_ch")) do if isA(c, cls) then return c end end
	return nil
end
methods.FindFirstAncestorOfClass = function(self, cls)
	local p = rawget(self, "_parent")
	while p do
		if rawget(p, "_class") == cls then return p end
		p = rawget(p, "_parent")
	end
	return nil
end
methods.SetAttribute = function(self, k, v)
	rawget(self, "_attr")[k] = v
	local ev = rawget(self, "_ev")
	if ev["_attr_" .. k] then ev["_attr_" .. k]:Fire() end
end
methods.GetAttribute = function(self, k) return rawget(self, "_attr")[k] end
methods.GetAttributeChangedSignal = function(self, k)
	local ev = rawget(self, "_ev")
	if not ev["_attr_" .. k] then ev["_attr_" .. k] = newSignal() end
	return ev["_attr_" .. k]
end
methods.GetPropertyChangedSignal = function(self, k) return newSignal() end
local function modelParts(self)
	local out = {}
	for _, d in ipairs(descendants(self)) do if BASEPARTS[rawget(d, "_class")] then table.insert(out, d) end end
	return out
end
methods.PivotTo = function(self, cf)
	local parts = modelParts(self)
	local pivot = rawget(self, "_pivot")
	if not pivot then
		local pp = rawget(self, "_p").PrimaryPart
		pivot = pp and pp.Position or (parts[1] and parts[1].Position) or V3.new(0, 0, 0)
	end
	local delta = cf.p - pivot
	for _, pt in ipairs(parts) do pt.Position = pt.Position + delta end
	rawset(self, "_pivot", cf.p)
end
methods.GetPivot = function(self) return CF.new(rawget(self, "_pivot") or V3.new(0, 0, 0)) end
methods.TakeDamage = function(self, d)
	local p = rawget(self, "_p")
	p.Health = math.max(0, (p.Health or 100) - d)
	if p.Health <= 0 and rawget(self, "_ev").Died then rawget(self, "_ev").Died:Fire() end
end
methods.ChangeState = function() end
methods.GetState = function() return Enum.HumanoidStateType.Running end
methods.FireClient = function(self, plr, ...) end
methods.FireAllClients = function() end
methods.Play = function(self)
	local info = rawget(self, "_tween")
	if info then
		task.delay(info.info.Time, function()
			for k, v in pairs(info.goal) do info.inst[k] = v end
			if rawget(self, "_ev").Completed then rawget(self, "_ev").Completed:Fire() end
		end)
	end
	rawget(self, "_p").IsPlaying = true
end
methods.Stop = function(self) rawget(self, "_p").IsPlaying = false end
methods.Cancel = function() end
methods.Emit = function() end
methods.Raycast = function(self, origin, dir) return { Position = origin + dir * 0.35, Instance = nil } end
methods.FillBlock = function() end
methods.GetServerTimeNow = function() return simTime + 1000 end
methods.GetPlayers = function(self) return rawget(self, "_players") or {} end
methods.GetPlayerFromCharacter = function(self, ch)
	for _, p in ipairs(rawget(self, "_players") or {}) do if p.Character == ch then return p end end
	return nil
end
methods.IsStudio = function() return true end
methods.GetPlayerByUserId = function(self, id) for _, p in ipairs(rawget(self, "_players") or {}) do if p.UserId == id then return p end end return nil end
methods.UserOwnsGamePassAsync = function() return false end
methods.PromptGamePassPurchase = function() end
methods.PromptProductPurchase = function() end
methods.BindToClose = function() end
methods.AddItem = function(self, inst, t) task.delay(t, function() if inst.Parent then inst:Destroy() end end) end
methods.GetDataStore = function(self)
	local data = {}
	return makeInst("DataStore") and {
		GetAsync = function(_, k) return data[k] end,
		SetAsync = function(_, k, v) data[k] = v end,
		_data = data,
	}
end
methods.Create = function(self, inst, info, goal)
	local tw = makeInst("Tween")
	rawset(tw, "_tween", { inst = inst, info = info, goal = goal })
	return tw
end
-- CollectionService
local tagged, tagSignals = {}, {}
methods.AddTag = function(self, inst, tag)
	tagged[tag] = tagged[tag] or {}
	table.insert(tagged[tag], inst)
	if tagSignals[tag] then tagSignals[tag]:Fire(inst) end
end
methods.HasTag = function(self, inst, tag)
	for _, i in ipairs(tagged[tag] or {}) do if i == inst then return true end end
	return false
end
methods.GetTagged = function(self, tag) local t = {} for i, v in ipairs(tagged[tag] or {}) do t[i] = v end return t end
methods.GetInstanceRemovedSignal = function(self, tag) return newSignal() end
methods.GetInstanceAddedSignal = function(self, tag)
	tagSignals[tag] = tagSignals[tag] or newSignal()
	return tagSignals[tag]
end
local __tagged = tagged

-- services
local services = {}
local function svc(name)
	local s = makeInst(name)
	services[name] = s
	return s
end
local Workspace = svc("Workspace")
Workspace.Terrain = makeInst("Terrain")
local Players = svc("Players")
rawset(Players, "_players", {})
svc("Lighting")
svc("RunService")
svc("TweenService")
svc("CollectionService")
svc("DataStoreService")
svc("StarterPlayer")
svc("Debris")
svc("ReplicatedStorage")
-- make Create/AddTag etc available on the right services via shared methods table (already global to all insts)

local game = makeInst("DataModel")
rawget(game, "_p").Workspace = Workspace
methods.GetService = function(self, name) return services[name] or svc(name) end
local game = game
local workspace = Workspace

-- test helpers
local __sim = {
	errors = errors,
	now = function() return simTime end,
	step = function(untilT, heartbeatDt)
		heartbeatDt = heartbeatDt or 1 / 30
		local nextHb = simTime
		while true do
			-- find earliest event
			local bestI, bestT = nil, math.huge
			for i, e in ipairs(queue) do if e.t < bestT then bestI, bestT = i, e.t end end
			local tnext = math.min(bestT, nextHb)
			if tnext > untilT then break end
			simTime = tnext
			if nextHb <= bestT then
				services.RunService.Heartbeat:Fire(heartbeatDt)
				nextHb = nextHb + heartbeatDt
			else
				local e = table.remove(queue, bestI)
				if coroutine.status(e.co) == "suspended" then resume(e.co) end
			end
		end
		simTime = untilT
	end,
	services = services,
	makeInst = makeInst,
	newSignal = newSignal,
	resume = resume,
}
