local _Catalyst = loadstring(game:HttpGet("https://raw.githubusercontent.com/misyn/Catalyst/refs/heads/main/CatalystLib.lua"))()

local Window = _Catalyst:Window({
    Title        = "Title",
    SubTitle     = "SubTitle",
    Accent       = Color3.fromRGB(255, 42, 74),
    Theme        = "GX",
    ConfigFolder = "_CatalystConfigs",
    ToggleKey    = Enum.KeyCode.RightAlt,
})

local Tab1 = Window:Tab("Tab 1", "rbxassetid://6034509993")

Tab1:Section("Section 1")

Tab1:Toggle("Toggle", "Description", false, function(on)
end, "toggle")

Tab1:Toggle("Toggle Keybind", "Description", false, function(on)
end, "toggle_keybind", { Keybind = Enum.KeyCode.V })

Tab1:Slider("Slider", "Description", 0, 100, 50, function(v)
end, "slider")

Tab1:Slider("Slider Suffix", "Description", 0, 100, 50, function(v)
end, "slider_suffix", { Suffix = " px" })

Tab1:Slider("Slider Prefix", "Description", 0, 100, 50, function(v)
end, "slider_prefix", { Prefix = "x" })

Tab1:Slider("Slider Decimals", "Description", 0, 10, 5, function(v)
end, "slider_decimals", { Decimals = 2 })

Tab1:Dropdown("Dropdown", { "Option 1", "Option 2", "Option 3", "Option 4" }, function(v)
end, "dropdown", "Option 1")

Tab1:MultiDropdown("Multi Dropdown", { "Option 1", "Option 2", "Option 3", "Option 4" }, function(selected)
end, "multidropdown", { "Option 1" })

Tab1:Colorpicker("Colorpicker", Color3.fromRGB(255, 0, 0), function(c)
end, "colorpicker")

Tab1:Colorpicker("Colorpicker No Rainbow", Color3.fromRGB(255, 0, 0), function(c)
end, "colorpicker_norain", { NoRainbow = true })

Tab1:Section("Section 2")

Tab1:Bind("Bind Press", Enum.KeyCode.E, function()
end, "bind_press", { Mode = "Press" })

Tab1:Bind("Bind Hold", Enum.KeyCode.F, function(held)
end, "bind_hold", { Mode = "Hold" })

Tab1:Bind("Bind Toggle", Enum.KeyCode.R, function(on)
end, "bind_toggle", { Mode = "Toggle" })

Tab1:Textbox("Textbox", "Description", false, function(text)
end, "textbox")

Tab1:Textbox("Textbox Clear", "Clears after submit", true, function(text)
end, "textbox_clear")

Tab1:Button("Button", "Description", function()
end)

local lbl = Tab1:Label("Label")

Tab1:Line()

local Tab2 = Window:Tab("Tab 2", "rbxassetid://6035067832")

Tab2:Section("Section 1")

Tab2:Toggle("Toggle", "Description", false, function(on)
end, "tab2_toggle")

Window:Init()
Window:Notify("Title", "Subtitle", 5)
