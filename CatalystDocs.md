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
11. [Globals](#globals)
12. [Behaviour notes](#notes)

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
    Theme        = "GX",
    ConfigFolder = "_CatalystConfigs",
    ToggleKey    = Enum.KeyCode.RightAlt,
})
```

| Option         | Type         | Default              | Purpose                                         |
|----------------|--------------|----------------------|-------------------------------------------------|
| `Title`        | string       | `"_Catalyst"`        | Shown in the content panel header.              |
| `SubTitle`     | string       | `"GX Edition"`       | Small text under the title.                     |
| `Accent`       | Color3       | `255, 42, 74`        | Theme accent colour. Persisted as a custom override. |
| `Theme`        | string       | `"GX"`               | Built-in theme to start with (`"GX"`, `"Discord"`, `"Light"`). |
| `ConfigFolder` | string       | `"_CatalystConfigs"` | Folder used for saved config files.             |
| `ToggleKey`    | Enum.KeyCode | `RightAlt`           | Key that shows/hides the UI.                    |

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

| `opts` field | Type                | Effect                                               |
|--------------|---------------------|------------------------------------------------------|
| `Keybind`    | Enum.KeyCode/string | Adds a rebindable key chip; pressing it flips state. |

When a `Keybind` and a `flag` are both given, the key is persisted under
`flag .. "Key"`.

### Slider

```lua
Tab:Slider("FOV", "Targeting radius", 0, 500, 120, function(v)
    print(v)
end, "aim_fov", { Suffix = " px" })
```

`Slider(text, desc, min, max, default, callback, flag, opts)` → `{ Set(v), Get() }`

| `opts` field | Type   | Default | Effect                                        |
|--------------|--------|---------|-----------------------------------------------|
| `Decimals`   | number | `0`     | Decimal places (e.g. `2` → `1.50`).           |
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

### MultiDropdown

Allows selecting multiple items from a list simultaneously.

```lua
local md = Tab:MultiDropdown("Kill Effects", { "Ragdoll", "Dissolve", "Explosion" }, function(selected)
    -- selected is a table of all chosen values, e.g. { "Ragdoll", "Explosion" }
    print(selected)
end, "kill_effects", { "Ragdoll" })
```

`MultiDropdown(text, list, callback, flag, default)` →
`{ Get(), GetSelected(), Set(tbl), Add(v), Clear(), Refresh(newList) }`

| Method           | Description                                          |
|------------------|------------------------------------------------------|
| `Get()`          | Returns a table of currently selected values.        |
| `GetSelected()`  | Alias for `Get()`.                                   |
| `Set(tbl)`       | Replace selection with a new table of values.        |
| `Add(v)`         | Append a new item to the list.                       |
| `Clear()`        | Deselect all items.                                  |
| `Refresh(list)`  | Replace all items; clears current selection display. |

`default` is a table of pre-selected values, e.g. `{ "Head", "Torso" }`.
The config system saves and restores the full selection table.

### Colorpicker

```lua
Tab:Colorpicker("ESP Color", Color3.fromRGB(255,0,0), function(c)
    print(c)
end, "esp_color")
```

`Colorpicker(text, default, callback, flag, opts)` → `{ Get(), Set(c), SetSilent(c) }`

| `opts` field | Type | Effect                                              |
|--------------|------|-----------------------------------------------------|
| `NoRainbow`  | bool | Hides the Rainbow toggle if `true`.                 |

| Method        | Description                                             |
|---------------|---------------------------------------------------------|
| `Get()`       | Returns the current `Color3`.                           |
| `Set(c)`      | Set color and fire the callback.                        |
| `SetSilent(c)`| Set color without firing the callback. Useful for syncing pickers programmatically. |

Includes a saturation/value box, a hue bar, a hex input field, and a **Rainbow** toggle (unless `NoRainbow = true`).

### Keybind

```lua
Tab:Bind("Hold To Aim", Enum.KeyCode.F, function(held)
    print(held)
end, "bind_hold", { Mode = "Hold" })
```

`Bind(text, defaultKey, callback, flag, opts)` →
`{ Get(), Set(k), GetState() }`

| `opts` field | Type | Effect                                         |
|--------------|------|------------------------------------------------|
| `Mode`       | string | `"Press"`, `"Hold"`, or `"Toggle"` (default `"Press"`). |
| `NoList`     | bool | If `true`, omits this bind from the keybind list overlay. |

| `Mode`     | Callback behaviour                                              |
|------------|-----------------------------------------------------------------|
| `"Press"`  | Fires `callback()` once on key down. *(default)*                |
| `"Hold"`   | Fires `callback(true)` on down, `callback(false)` on release.   |
| `"Toggle"` | Flips an internal state, fires `callback(state)` each press.    |

Clicking the key chip lets you rebind. `GetState()` returns the toggle-mode boolean.

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

`Tab:Section("COMBAT")` adds a collapsible header. Clicking it hides every
control beneath it until the next section.

```lua
local sec = Tab:Section("Combat")   -- returns { Collapse, Expand, Toggle }
sec.Collapse()
```

Section collapsed/expanded state is tracked as a flag internally and saved
with configs.

---

<a name="config"></a>
## 6. The Settings panel & config system

The Settings panel is generated automatically and contains:

**Interface**
* **UI Scale** slider — resizes the whole window (50–150 %).
* **Streamer Mode** toggle — hides the watermark when the UI is closed.
* **Toggle UI Key** bind — rebind the show/hide key.

**Appearance**
* **UI Theme** dropdown — choose from built-in themes (`GX`, `Discord`, `Light`) or any saved custom themes.
* **Accent Color** picker — overrides the theme accent; persisted as a custom value.
* **Text Font** dropdown — change the global font across all UI text.
* **Element Padding** slider — gap between cards and elements (2–16 px).

**Custom Theme**
* Per-aspect colour pickers (`Window`, `Panel`, `Header`, `Element`, `Hover`, `Stroke`, `Text`, `SubText`) and a **Theme Accent** picker — all preview live.
* **Theme Name** textbox + **Save as New Theme** button — create a new named theme from current draft colours.
* **Custom Themes** dropdown + **Update Selected Theme** / **Delete Selected Theme** — manage saved custom themes. Custom themes are written to `ConfigFolder/_themes.json` and survive re-execution.

**Keybind List**
* **Show Keybind List** toggle — show/hide the floating keybind overlay.
* **Reset Keybind Position** button.

**Watermark**
* **Show Watermark** toggle.
* **Display Name** textbox — override the name shown on the watermark.
* **Avatar Image** textbox — `rbxassetid` number or full asset URL.
* **Watermark Scale** slider (50–200 %).
* **Reset Watermark Position** button.

**Notifications**
* **Enable Notifications** toggle.
* **Notification Position** dropdown — `"Bottom Right"`, `"Top Right"`, `"Top Left"`.
* **Notification Size** slider (75–100 %).

**Configuration**
* **Config Name** textbox and a **Saved Configs** dropdown.
* **Save / Load / Delete** buttons.
* **Auto-load Recent** toggle — loads the last used config on launch.
* **Reset to Defaults** — restores every flagged control to its default.

Any component created with a `flag` is saved into the config file (`Color3` values are serialised automatically). Call `Window:Init()` at the end of your script to enable auto-loading the most recent config:

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

`_Catalyst.Themes` holds all registered themes (built-in and custom). Built-in
themes are `GX`, `Discord`, and `Light`.

### Changing the accent

```lua
Window:SetAccent(Color3.fromRGB(120, 80, 255))
```

Changing the accent updates **every** accent-coloured element instantly,
including controls already in an active state.

### Switching themes programmatically

```lua
Window:SetTheme("Discord")         -- applies a built-in or custom theme by name
_Catalyst.ApplyTheme("Discord")    -- module-level alias; same effect
```

Switching themes resets the accent to the theme's default unless a custom
accent was previously set (i.e. `_Catalyst._customAccent` is `true`).

### Custom themes at runtime

Custom themes built in the Settings panel are stored in
`ConfigFolder/_themes.json` and reloaded automatically on next execution.
You can also register a theme in code before creating the window:

```lua
_Catalyst.Themes["MyTheme"] = {
    Window  = Color3.fromRGB(10, 10, 14),
    Panel   = Color3.fromRGB(18, 18, 24),
    Header  = Color3.fromRGB(24, 24, 32),
    Element = Color3.fromRGB(28, 28, 38),
    Hover   = Color3.fromRGB(38, 38, 50),
    Stroke  = Color3.fromRGB(44, 44, 58),
    Text    = Color3.fromRGB(240, 240, 248),
    SubText = Color3.fromRGB(130, 130, 148),
    Accent  = Color3.fromRGB(80, 200, 120),
}
```

---

<a name="window-methods"></a>
## 10. Window methods

| Method                                   | Description                                                    |
|------------------------------------------|----------------------------------------------------------------|
| `Window:Tab(name, icon)`                 | Create a tab; returns its component API.                       |
| `Window:Notify(title, desc, duration, color)` | Show a notification toast (default 4 s). `color` tints the progress bar; defaults to accent. Notifications display a live countdown timer. |
| `Window:SaveConfig(name)`                | Save all flagged values to a file.                             |
| `Window:LoadConfig(name)`                | Apply a saved config.                                          |
| `Window:DeleteConfig(name)`              | Delete a config file.                                          |
| `Window:GetConfigs()`                    | Returns a list of saved config names.                          |
| `Window:ResetDefaults()`                 | Reset every flagged control to its default.                    |
| `Window:Init()`                          | Refresh the config list and auto-load the most recent config.  |
| `Window:SetAccent(color)`                | Change the accent colour live.                                 |
| `Window:SetTheme(name)`                  | Apply a built-in or custom theme by name.                      |
| `Window:Toggle()`                        | Show/hide the window.                                          |
| `Window:Relayout()`                      | Re-apply the panel layout with animation.                      |
| `Window:RefreshVisuals()`                | Re-apply the full theme, accent, and layout.                   |
| `Window:SetFont(fontEnum)`               | Change the global font (accepts an `Enum.Font` value).         |
| `Window:SetPadding(px)`                  | Set the gap between all list elements (integer pixels).        |
| `Window:SetWatermarkName(text)`          | Override the name shown on the watermark overlay.              |
| `Window:SetWatermarkImage(assetOrId)`    | Set the watermark avatar image (asset URL or numeric ID string).|
| `Window:SetWatermarkVisible(bool)`       | Show or hide the watermark overlay.                            |
| `Window:SetKeybindListVisible(bool)`     | Show or hide the floating keybind list overlay.                |

---

<a name="globals"></a>
## 11. Globals

| Global                    | Type   | Description                                                  |
|---------------------------|--------|--------------------------------------------------------------|
| `_Catalyst.Flags`         | table  | `flag → current value` for every flagged control.            |
| `_Catalyst.Config`        | table  | `flag → { Get, Set, Default }` for every flagged control.    |
| `_Catalyst.Theme`         | table  | Live colour table. Mutate keys to change colours globally.   |
| `_Catalyst.Themes`        | table  | All registered themes (built-in + custom).                   |
| `_Catalyst.ApplyTheme(name)` | function | Apply a theme by name; same as `Window:SetTheme`.         |
| `_Catalyst.Version`       | string | Library version string (e.g. `"3.1"`).                       |
| `_Catalyst._customAccent` | bool   | `true` when a custom accent is overriding the theme default. |

---

<a name="notes"></a>
## 12. Behaviour notes

* **File system** — uses executor functions (`writefile`, `readfile`,
  `listfiles`, …) when available. Without them it falls back to an in-memory
  store so nothing errors, but configs won't persist between sessions. The
  About section in Settings reports which mode is active.
* **Custom themes** — saved to `ConfigFolder/_themes.json` separately from
  config files. They persist independently of any config save/load.
* **Re-execution** — the old UI is destroyed and the old script's input
  handlers are disabled via a generation token, so re-running is clean.
* **Backward compatible** — all new options (`opts` tables, keybinds,
  `NoRainbow`, `NoList`) are optional; older positional calls still work.
* **Notifications** include a live countdown timer in the top-right corner and
  an optional `color` argument that tints the progress bar.
* This is a UI framework only. What you build with it is your responsibility,
  and automating gameplay may violate Roblox's Terms of Service.
