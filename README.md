# Catalyst — Documentation

A three-panel Roblox UI library with dockable panels, a config system, and full mobile support.

> File: `CatalystLib.lua` — returns the `_Catalyst` source.
> Example: `CatalystLib_Example.lua`.

---

## Contents

1. [Loading](#loading)
2. [Creating a window](#creating-a-window)
3. [Tabs](#tabs)
4. [Components](#components)
5. [Sections (collapsible)](#sections)
6. [The Settings panel & config system](#config)
7. [Docking & panels](#docking)
8. [Mobile](#mobile)
9. [Theme & accent](#theme)
10. [Window methods](#window-methods)
11. [Behaviour notes](#notes)

---

<a name="loading"></a>
## 1. Loading

```lua
local _Catalyst = loadstring(game:HttpGet("urlhere"))()
```

The library creates one `ScreenGui` named `_CatalystLib`. **Re-running the
script automatically removes the previous UI** and disables the old script's
keybinds/loops, so you can re-execute safely.

---

<a name="creating-a-window"></a>
## 2. Creating a window

```lua
local Window = _Catalyst:Window({
    Title        = "main",
    SubTitle     = "sub",
    Accent       = Color3.fromRGB(255, 42, 74),
    ConfigFolder = "_CatalystConfigs",
    ToggleKey    = Enum.KeyCode.RightAlt,
})
```

| Option         | Type             | Default                       | Purpose                                  |
|----------------|------------------|-------------------------------|------------------------------------------|
| `Title`        | string           | `"_Catalyst"`                 | Shown in the content panel header.       |
| `SubTitle`     | string           | `"GX Edition"`                | Small text under the title.              |
| `Accent`       | Color3           | `255, 42, 74`                 | Theme accent colour.                     |
| `ConfigFolder` | string           | `"_CatalystConfigs"`          | Folder used for saved config files.      |
| `ToggleKey`    | Enum.KeyCode     | `RightAlt`                    | Key that shows/hides the UI.             |

A bare string is also accepted: `_Catalyst:Window("My Hub")`.

The window has three panels — **Tabs** (left), **Content** (middle) and
**Settings** (right). The Settings panel is built automatically.

---

<a name="tabs"></a>
## 3. Tabs

```lua
local Combat = Window:Tab("Combat", "rbxassetid://6034509993")
```

`Window:Tab(name, icon)` returns a component API. `icon` is an optional
`rbxassetid://` string. The first tab created is shown by default.

All components below are methods of that returned API.

---

<a name="components"></a>
## 4. Components

The last `flag` argument on most components is optional — if given, that
control's value is saved and loaded by the config system.

### Button

```lua
Tab:Button("Print Hi", "Optional description", function()
    print("clicked")
end)
```

### Toggle

```lua
Tab:Toggle("Aim Assist", "Smooth tracking", false, function(on)
    print(on)
end, "aim_enabled", { Keybind = Enum.KeyCode.V })
```

`Toggle(text, desc, default, callback, flag, opts)` → `{ Set(v), Get() }`

| `opts` field | Type                | Effect                                              |
|--------------|---------------------|-----------------------------------------------------|
| `Keybind`    | Enum.KeyCode/string | Adds a rebindable key chip; pressing it flips state.|

When a `Keybind` and a `flag` are both given, the key is persisted under
`flag .. "Key"`.

### Slider

```lua
Tab:Slider("FOV", "Targeting radius", 0, 500, 120, function(v)
    print(v)
end, "aim_fov", { Suffix = " px" })
```

`Slider(text, desc, min, max, default, callback, flag, opts)` → `{ Set(v), Get() }`

| `opts` field | Type   | Default | Effect                                       |
|--------------|--------|---------|----------------------------------------------|
| `Decimals`   | number | `0`     | Decimal places (e.g. `2` → `1.50`).          |
| `Prefix`     | string | `""`    | Text before the value (e.g. `"x"` → `x2`).   |
| `Suffix`     | string | `""`    | Text after the value (e.g. `" ms"` → `15 ms`).|

The callback and `Get()` return the rounded number.

### Dropdown

```lua
local dd = Tab:Dropdown("Target Part", { "Head", "Torso" }, function(v)
    print(v)
end, "aim_part", "Head")
```

`Dropdown(text, list, callback, flag, default)` →
`{ Get(), Set(v), Add(v), Refresh(newList) }`

* `Add(v)` — append one item.
* `Refresh(newList)` — replace all items.

### Colorpicker

```lua
Tab:Colorpicker("ESP Color", Color3.fromRGB(255,0,0), function(c)
    print(c)
end, "esp_color")
```

`Colorpicker(text, default, callback, flag)` → `{ Get(), Set(c) }`
Includes a saturation/value box, a hue bar and a **Rainbow** toggle.

### Keybind

```lua
Tab:Bind("Hold To Aim", Enum.KeyCode.F, function(held)
    print(held)
end, "bind_hold", { Mode = "Hold" })
```

`Bind(text, defaultKey, callback, flag, opts)` →
`{ Get(), Set(k), GetState() }`

| `Mode`     | Callback behaviour                                              |
|------------|-----------------------------------------------------------------|
| `"Press"`  | Fires `callback()` once on key down. *(default)*                |
| `"Hold"`   | Fires `callback(true)` on down, `callback(false)` on release.   |
| `"Toggle"` | Flips an internal state, fires `callback(state)` each press.    |

Clicking the key chip lets you rebind. `GetState()` returns the toggle-mode
boolean.

### Textbox

```lua
Tab:Textbox("Config Name", "Optional description", false, function(text)
    print(text)
end, "my_flag")
```

`Textbox(text, desc, clearOnEnter, callback, flag)` → `{ Get(), Set(v) }`
Stacked layout (label on top, input full-width below). The callback fires when
the box loses focus via Enter. `clearOnEnter` empties the box after submit.

### Label & Line

```lua
local lbl = Tab:Label("Status: idle")   -- returns { Set(text) }
Tab:Line()                              -- thin divider
```

---

<a name="sections"></a>
## 5. Sections

`Tab:Section("COMBAT")` adds a header. **Sections are collapsible** — clicking
the header hides every control beneath it until the next section.

```lua
local sec = Tab:Section("Combat")   -- returns { Collapse, Expand, Toggle }
sec.Collapse()
```

---

<a name="config"></a>
## 6. The Settings panel & config system

The Settings panel is generated automatically and contains:

* **Config Name** textbox and a **Saved Configs** dropdown.
* **Save / Load / Delete / Refresh List** buttons.
* **Auto-load Recent** toggle — loads the last used config on launch.
* **Reset to Defaults** — restores every flagged control to its default.
* **Accent Color** picker, **UI Scale** slider, **Toggle UI Key** bind.

Any component created with a `flag` is saved into the config file
(`Color3` values are serialised automatically). Call `Window:Init()` at the
end of your script to enable auto-loading the most recent config:

```lua
-- ... build all tabs and components ...
Window:Init()
```

If you forget, `Init()` also runs automatically a moment after the script
finishes building.

---

<a name="docking"></a>
## 7. Docking & panels

* Drag the **Tabs** or **Settings** panel by its header to dock it to any
  edge — **Left, Right, Top or Bottom**. While dragging, a single accent
  "DOCK HERE" zone previews the target.
* Two panels on the same edge stack; the half you drop in decides their order.
* Drag the **Content** (middle) panel's header to move the whole window.
* Positions snap to a grid while dragging.
* `Window:Relayout()` re-applies the layout with animation.

---

<a name="mobile"></a>
## 8. Mobile

On touch devices a floating **CX** button appears (draggable) to open/close the
UI, since there is no keyboard. Every drag interaction — window, panels,
sliders, colorpicker — supports touch. A `UIScale` auto-fits the window to the
viewport, and the **UI Scale** slider in Settings lets the user adjust it
further (scrolling works correctly at any scale).

---

<a name="theme"></a>
## 9. Theme & accent

`_Catalyst.Theme` holds the colour table (`Window`, `Panel`, `Header`,
`Element`, `Hover`, `Stroke`, `Text`, `SubText`, `Accent`).

Changing the accent updates **every** accent-coloured element instantly,
including controls already in an active state (on toggles, the active tab
icon, sliders, drop-zones, scrollbars):

```lua
Window:SetAccent(Color3.fromRGB(120, 80, 255))
```

The Settings panel's **Accent Color** picker does the same and persists it.

---

<a name="window-methods"></a>
## 10. Window methods

| Method                       | Description                                          |
|-------------------------------|------------------------------------------------------|
| `Window:Tab(name, icon)`      | Create a tab; returns its component API.             |
| `Window:Notify(title, desc, duration)` | Show a notification toast (default 4s).     |
| `Window:SaveConfig(name)`     | Save all flagged values to a file.                   |
| `Window:LoadConfig(name)`     | Apply a saved config.                                |
| `Window:DeleteConfig(name)`   | Delete a config file.                                |
| `Window:GetConfigs()`         | Returns a list of saved config names.                |
| `Window:ResetDefaults()`      | Reset every flagged control to its default.          |
| `Window:Init()`               | Refresh the config list and auto-load recent config. |
| `Window:SetAccent(color)`     | Change the accent colour live.                       |
| `Window:Toggle()`             | Show/hide the window.                                |
| `Window:Relayout()`           | Re-apply the panel layout.                           |

Globals: `_Catalyst.Flags` (flag → current value), `_Catalyst.Config`
(flag → `{ Get, Set, Default }`), `_Catalyst.Theme`, `_Catalyst.Version`.

---

<a name="notes"></a>
## 11. Behaviour notes

* **File system** — uses executor functions (`writefile`, `readfile`,
  `listfiles`, …) when available. Without them it falls back to an in-memory
  store so nothing errors, but configs won't persist between sessions.
* **Re-execution** — the old UI is destroyed and the old script's input
  handlers are disabled via a generation token, so re-running is clean.
* **Backward compatible** — all new options (`opts` tables, keybinds) are
  optional; older positional calls still work.
* This is a UI framework only. What you build with it is your responsibility,
  and automating gameplay may violate Roblox's Terms of Service.
