end)
if not ok2 then print("CLIENT LOAD ERROR:", err2) end
local S = __sim
local RunService = game:GetService("RunService")
plr.CharacterAdded:Fire(char)
S.step(1)
coins.Value = 5; stage.Value = 3
plr:SetAttribute("Own_double", true)
plr:SetAttribute("AchCount", 4)
plr:SetAttribute("RunStart", S.now() + 1000 - 12)
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.LeftShift }, false)
hum.MoveDirection = Vector3.new(1, 0, 0)
for i = 1, 90 do RunService.RenderStepped:Fire(1 / 30) end
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.Q }, false)
S.step(S.now() + 0.5)
fxr.OnClientEvent:Fire("shake", 1, 0.5)
fxr.OnClientEvent:Fire("hurt", 20)
fxr.OnClientEvent:Fire("achievement", "x")
for i = 1, 60 do RunService.RenderStepped:Fire(1 / 30) end
UIS.JumpRequest:Fire()
print("client errors:", #S.errors)
for i, e in ipairs(S.errors) do print(i, e) if i > 5 then break end end
print("walkspeed", hum.WalkSpeed, "fov", cam.FieldOfView)
