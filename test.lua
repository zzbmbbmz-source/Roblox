local MyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/zzbmbbmz-source/Roblox/refs/heads/main/Ui-1.lua"))()

local Window = MyUI:CreateWindow({ 
    Title = "My Hub", 
    SubTitle = "v1.0",
    Scale = 0.7  -- ย่อ UI ทั้งหน้าต่างเหลือ 50% (1 = ปกติ, 0.5 = ครึ่งหนึ่ง)
})

-- =================================================================
-- MAIN TAB
-- =================================================================
local CreditTab = Window:CreateTab("Credit",-1000)

CreditTab:CreateButton({
    Title = creditCfg.Title or "3A1TR",
    SubTitle = creditCfg.SubTitle or "Created by 3A1TR",
    Callback = function() end,
})

-- =================================================================
-- PLAYER TAB (ฟังก์ชันเกี่ยวกับตัวละคร)
-- =================================================================
local TabPlayer = Window:CreateTab("PLAYER",100)

TabPlayer:CreateSlider({
    Title = "WalkSpeed", SubTitle = "ปรับความเร็วในการเดินพื้นฐาน",
    Min = 16, Max = 250, Default = 16, 
    Callback = function(v)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
})

TabPlayer:CreateSlider({
    Title = "JumpPower", SubTitle = "ปรับความสูงในการกระโดด",
    Min = 50, Max = 300, Default = 50, 
    Callback = function(v)
        game.Players.LocalPlayer.Character.Humanoid.UseJumpPower = true
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = v
    end
})

TabPlayer:CreateToggle({
    Title = "Infinite Jump", SubTitle = "กระโดดได้เรื่อยๆ บนอากาศ",
    Default = false,
    Callback = function(v)
        _G.InfJump = v
        game:GetService("UserInputService").JumpRequest:Connect(function()
            if _G.InfJump then
                game.Players.LocalPlayer.Character.Humanoid:ChangeState("Jumping")
            end
        end)
    end
})

-- =================================================================
-- VISUAL TAB (ฟังก์ชันการมองเห็น / ESP)
-- =================================================================
local TabVisual = Window:CreateTab("VISUAL",110)

TabVisual:CreateToggle({
    Title = "Player ESP", SubTitle = "มองเห็นผู้เล่นทะลุกำแพง (Highlight)",
    Default = false,
    Callback = function(v)
        _G.EspActive = v
        local function applyESP(player)
            if player ~= game.Players.LocalPlayer and player.Character then
                if v then
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

-- =================================================================
-- MISC TAB (ฟังก์ชันเบ็ดเตล็ด)
-- =================================================================
local TabMisc = Window:CreateTab("Misc",120)

TabMisc:CreateToggle({
    Title = "Noclip", SubTitle = "เดินทะลุกำแพง/สิ่งกีดขวาง",
    Default = false,
    Callback = function(v)
        _G.Noclip = v
        game:GetService("RunService").Stepped:Connect(function()
            if _G.Noclip and game.Players.LocalPlayer.Character then
                for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
})

-- =================================================================
-- SETTING TAB (ตั้งค่าตัว UI และระบบสคริปต์)
-- =================================================================
local TabSetting = Window:CreateTab("Setting",130)

TabSetting:CreateButton({
    Title = "Destroy UI", SubTitle = "ปิดและลบหน้าต่างสคริปต์นี้ออก",
    Callback = function()
        -- ใส่โค้ดเคลียร์ UI ของคุณที่นี่ เช่น MyUI:Destroy() หรือตามเมธอดของ API
        print("UI Destroyed") 
    end
})
return Window, MyUI

