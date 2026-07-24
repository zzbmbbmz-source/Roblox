local MyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/zzbmbbmz-source/Roblox/refs/heads/main/Ui-1.lua"))()

local Window = MyUI:CreateWindow({ 
    Title = "My Hub", 
    SubTitle = "v1.0",
    Scale = 0.7
})

local TabPlayer = Window:CreateTab("PLAYER")

-- =================================================================
-- CREDIT TEXT
-- =================================================================

-- =================================================================
-- PLAYER FUNCTIONS
-- =================================================================
TabPlayer:CreateSlider({
    Title = "WalkSpeed", SubTitle = "ปรับความเร็วในการเดินพื้นฐาน",
    Min = 16, Max = 250, Default = 16, 
    Callback = function(v)
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end
})

TabPlayer:CreateToggle({
    Title = "Infinite Jump", SubTitle = "กระโดดได้เรื่อยๆ บนอากาศ",
    Default = false,
    Callback = function(v)
        _G.InfJump = v
        if not _G.InfJumpConnected then
            _G.InfJumpConnected = true
            game:GetService("UserInputService").JumpRequest:Connect(function()
                if _G.InfJump and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    game.Players.LocalPlayer.Character.Humanoid:ChangeState("Jumping")
                end
            end)
        end
    end
})

TabPlayer:CreateToggle({
    Title = "Player ESP", SubTitle = "มองเห็นผู้เล่นทะลุกำแพง (Highlight)",
    Default = false,
    Callback = function(v)
        _G.EspActive = v
        local function applyESP(player)
            if player ~= game.Players.LocalPlayer and player.Character then
                if _G.EspActive then
                    local hl = player.Character:FindFirstChildOfClass("Highlight") or Instance.new("Highlight", player.Character)
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                else
                    local hl = player.Character:FindFirstChildOfClass("Highlight")
                    if hl then hl:Destroy() end
                end
            end
        end
        for _, p in pairs(game.Players:GetPlayers()) do applyESP(p) end
    end
})

TabPlayer:CreateToggle({
    Title = "Noclip", SubTitle = "เดินทะลุกำแพง/สิ่งกีดขวาง",
    Default = false,
    Callback = function(v)
        _G.Noclip = v
        if not _G.NoclipConnected then
            _G.NoclipConnected = true
            game:GetService("RunService").Stepped:Connect(function()
                if _G.Noclip and game.Players.LocalPlayer.Character then
                    for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
        end
    end
})

-- =================================================================
-- FIX FULLBRIGHT SYSTEM
-- =================================================================
local Lighting = game:GetService("Lighting")

local function ResetLighting()
    if _G.DefaultLighting then
        Lighting.Brightness = _G.DefaultLighting.Brightness
        Lighting.ClockTime = _G.DefaultLighting.ClockTime
        Lighting.FogEnd = _G.DefaultLighting.FogEnd
        Lighting.GlobalShadows = _G.DefaultLighting.GlobalShadows
        Lighting.Ambient = _G.DefaultLighting.Ambient
        Lighting.OutdoorAmbient = _G.DefaultLighting.OutdoorAmbient
    end
end

TabPlayer:CreateToggle({
    Title = "FullBright", SubTitle = "ปรับแสงสว่างเต็มที่ตัดหมอกและเงา",
    Default = false,
    Callback = function(v)
        _G.FullBright = v
        
        if _G.FullBright then
            if not _G.DefaultLighting then
                _G.DefaultLighting = {
                    Brightness = Lighting.Brightness,
                    ClockTime = Lighting.ClockTime,
                    FogEnd = Lighting.FogEnd,
                    GlobalShadows = Lighting.GlobalShadows,
                    Ambient = Lighting.Ambient,
                    OutdoorAmbient = Lighting.OutdoorAmbient
                }
            end
            
            if not _G.FullBrightConnected then
                _G.FullBrightConnected = true
                game:GetService("RunService").RenderStepped:Connect(function()
                    if _G.FullBright then
                        Lighting.Brightness = 2
                        Lighting.ClockTime = 14
                        Lighting.FogEnd = 999999
                        Lighting.GlobalShadows = false
                        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                    end
                end)
            end
        else
            ResetLighting()
        end
    end
})

return Window, MyUI
        end
        for _, p in pairs(game.Players:GetPlayers()) do applyESP(p) end
    end
})

TabPlayer:CreateToggle({
    Title = "Infinite Jump", SubTitle = "กระโดดได้เรื่อยๆ บนอากาศ",
    Default = false,
    Callback = function(v)
        _G.InfJump = v
        if not _G.InfJumpConnected then
            _G.InfJumpConnected = true
            game:GetService("UserInputService").JumpRequest:Connect(function()
                if _G.InfJump and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    game.Players.LocalPlayer.Character.Humanoid:ChangeState("Jumping")
                end
            end)
        end
    end
})

return Window, MyUI
