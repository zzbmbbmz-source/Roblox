# MyHub — Developer API

โครงสร้างไฟล์แบ่งเป็น 2 ชั้น:

| ไฟล์ | หน้าที่ |
|---|---|
| `Ui-1.lua` | Core UI library (`MyUI`) — สร้างหน้าต่าง, แท็บ, ปุ่ม, สไลเดอร์ ฯลฯ แทบไม่ต้องแก้ต่อ |
| `test.lua` | Hub script — โหลด `Ui.lua`, สร้างแท็บพื้นฐาน (Main/Player/Visual/Misc/Setting), แล้ว **`return Window, MyUI`** |

เพราะ `test.lua` return ค่ากลับมา สคริปต์อื่นที่ `loadstring` ไฟล์นี้จึงรับ `Window`
มาต่อยอดสร้างแท็บ/ฟังก์ชันของตัวเองได้ทันที **โดยไม่ต้องแก้ `test.lua` เลย**

---

## เริ่มต้นแบบเดิม (ผู้ใช้ทั่วไป)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/zzbmbbmz-source/Roblox/refs/heads/main/Test.lua"))()
```

ได้ UI + แท็บพื้นฐานทั้งหมดตามที่ตั้งไว้ใน `test.lua`

---

## เพิ่มแท็บ/ฟังก์ชันของตัวเอง (นักพัฒนา)

รับค่า `Window` ที่ `test.lua` return กลับมา แล้วเรียก `Window:CreateTab(...)` ต่อได้เลย
ไม่ต้องสร้างหน้าต่างใหม่ ไม่ต้องแก้โค้ดต้นฉบับ:

```lua
-- สคริปต์ของคุณเอง (แยกไฟล์ต่างหาก)
local Window = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/refs/heads/main/test.lua"))()

local MyTab = Window:CreateTab("My Feature")

MyTab:CreateButton({
    Title = "Say Hi",
    SubTitle = "ตัวอย่างฟังก์ชันของนักพัฒนาเอง",
    Callback = function()
        print("Hello from my custom tab!")
    end
})
```

ถ้าต้องการ `MyUI` เอง (เช่นจะเปิดหน้าต่างใหม่แยกต่างหาก) ให้รับตัวที่สอง:

```lua
local Window, MyUI = loadstring(game:HttpGet(".../test.lua"))()
```

---

## API Reference (`Window:CreateXxx`)

### `Window:CreateTab(name: string) -> Tab`
สร้างแท็บใหม่ในหน้าต่าง คืนค่า `Tab` object ไว้ใช้สร้าง component ต่างๆ ข้างในต่อ

### `Tab:CreateToggle(config)`
```lua
Tab:CreateToggle({
    Title = "ชื่อ",            -- string
    SubTitle = "คำอธิบาย",     -- string, optional
    Default = false,            -- boolean
    Callback = function(value: boolean) end
})
```

### `Tab:CreateSlider(config)`
```lua
Tab:CreateSlider({
    Title = "ชื่อ",
    SubTitle = "คำอธิบาย",     -- optional
    Min = 0, Max = 100,
    Default = 50,
    Callback = function(value: number) end
})
```

### `Tab:CreateDropdown(config)`
```lua
Tab:CreateDropdown({
    Title = "ชื่อ",
    SubTitle = "คำอธิบาย",     -- optional
    Options = {"A", "B", "C"},
    Default = "A",
    Callback = function(selected: string) end
})
```

### `Tab:CreateButton(config)`
```lua
Tab:CreateButton({
    Title = "ชื่อ",
    SubTitle = "คำอธิบาย",     -- optional
    Callback = function() end
})
```

### `Tab:CreateInput(config)`
```lua
Tab:CreateInput({
    Title = "ชื่อ",
    SubTitle = "คำอธิบาย",     -- optional
    Placeholder = "...",
    Default = "",
    Callback = function(text: string, enterPressed: boolean) end
})
```

### `MyUI:Notify(config)`
แจ้งเตือนมุมขวาล่างของจอ (ไม่ผูกกับแท็บ เรียกจาก `MyUI` ตรงๆ)
```lua
MyUI:Notify({
    Title = "หัวข้อ",
    Content = "รายละเอียด",
    Duration = 3   -- วินาที, optional (default 3)
})
```

### `Window:SetScale(scale: number, animate: boolean?)`
ปรับขนาด UI ทั้งหน้าต่างตอน runtime เช่นทำปุ่ม/สไลเดอร์ให้ผู้ใช้เลือกขนาดเอง
```lua
Window:SetScale(0.5)          -- ย่อเหลือ 50% พร้อม animation
Window:SetScale(1, false)     -- คืนขนาดปกติทันที ไม่มี animation
```

---

## ข้อควรระวังสำหรับนักพัฒนา

- ชื่อแท็บควรไม่ซ้ำกับแท็บพื้นฐานใน `test.lua` (Main, Player, Visual, Misc, Setting) เพื่อไม่ให้สับสน
- `Callback` ทุกตัวถูกเรียกผ่าน `pcall` อยู่แล้วใน `Ui.lua` ดังนั้น error ในฟังก์ชันของคุณจะไม่ทำให้ UI ทั้งหน้าค้าง แต่ควรใส่ `pcall`/ตรวจสอบ `Character` เองก่อนเข้าถึง เช่น `game.Players.LocalPlayer.Character` อาจเป็น `nil` ถ้าตัวละครยังไม่ spawn
- `Ui.lua` ไม่ควรถูกแก้บ่อย เพราะเป็นไฟล์ที่ทุกอย่าง (ทั้ง hub และสคริปต์นักพัฒนา) พึ่งพาอยู่ร่วมกัน — การเพิ่มฟีเจอร์ใหม่ควรทำผ่านสคริปต์แยกที่ต่อยอดจาก `Window` แทน
