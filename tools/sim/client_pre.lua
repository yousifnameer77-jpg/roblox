
-- ===== client pre-setup =====
local Players = game:GetService("Players")
local plr = Instance.new("Player"); plr.Name = "Me"
rawget(Players, "_p").LocalPlayer = plr
local pg = Instance.new("PlayerGui"); pg.Parent = plr
local lsf = Instance.new("Folder"); lsf.Name = "leaderstats"; lsf.Parent = plr
local coins = Instance.new("IntValue"); coins.Name = "Coins"; coins.Parent = lsf
local stage = Instance.new("IntValue"); stage.Name = "Stage"; stage.Parent = lsf
local cam = Instance.new("Camera"); rawget(workspace, "_p").CurrentCamera = cam
cam.FieldOfView = 70
local RS = game:GetService("ReplicatedStorage")
local fxr = Instance.new("RemoteEvent"); fxr.Name = "SkyFx"; fxr.Parent = RS
local char = Instance.new("Model")
local hum = Instance.new("Humanoid"); hum.Parent = char
local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Parent = char
plr.Character = char
local UIS = game:GetService("UserInputService")
rawget(UIS, "_p").TouchEnabled = false
rawget(UIS, "_p").KeyboardEnabled = true
local ok2, err2 = pcall(function()
