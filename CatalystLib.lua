local _Catalyst = {}
_Catalyst.Version = "2.7"
_Catalyst.RainbowColorValue = 0
_Catalyst.HueSelectionPosition = 0
_Catalyst.Flags = {}
_Catalyst.Config = {}
_Catalyst._customAccent = false

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer

local taskLib = task or {
    wait  = wait,
    spawn = function(f, ...) local a = {...} coroutine.wrap(function() f(unpack(a)) end)() end,
    defer = function(f, ...) local a = {...} coroutine.wrap(function() f(unpack(a)) end)() end,
}

local genv
do
    local ok, g = pcall(function() return getgenv() end)
    genv = (ok and g) or _G or {}
end
genv.__CatalystGen = (genv.__CatalystGen or 0) + 1
local MY_GEN = genv.__CatalystGen
local function alive() return genv.__CatalystGen == MY_GEN end

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local Theme = {
    Window  = Color3.fromRGB(18, 18, 21),
    Panel   = Color3.fromRGB(24, 24, 28),
    Header  = Color3.fromRGB(31, 31, 37),
    Element = Color3.fromRGB(35, 35, 41),
    Hover   = Color3.fromRGB(46, 46, 54),
    Stroke  = Color3.fromRGB(50, 50, 60),
    Text    = Color3.fromRGB(237, 237, 243),
    SubText = Color3.fromRGB(140, 140, 152),
    Accent  = Color3.fromRGB(255, 42, 74),
}
_Catalyst.Theme = Theme

local Themes = {
    GX = {
        Window  = Color3.fromRGB(18, 18, 21),
        Panel   = Color3.fromRGB(24, 24, 28),
        Header  = Color3.fromRGB(31, 31, 37),
        Element = Color3.fromRGB(35, 35, 41),
        Hover   = Color3.fromRGB(46, 46, 54),
        Stroke  = Color3.fromRGB(50, 50, 60),
        Text    = Color3.fromRGB(237, 237, 243),
        SubText = Color3.fromRGB(140, 140, 152),
        Accent  = Color3.fromRGB(255, 42, 74),
    },
    Discord = {
        Window  = Color3.fromRGB(30, 31, 34),
        Panel   = Color3.fromRGB(43, 45, 49),
        Header  = Color3.fromRGB(49, 51, 56),
        Element = Color3.fromRGB(56, 58, 64),
        Hover   = Color3.fromRGB(66, 70, 78),
        Stroke  = Color3.fromRGB(38, 39, 43),
        Text    = Color3.fromRGB(219, 222, 225),
        SubText = Color3.fromRGB(148, 155, 164),
        Accent  = Color3.fromRGB(88, 101, 242),
    },
    Light = {
        Window  = Color3.fromRGB(240, 241, 245),
        Panel   = Color3.fromRGB(252, 252, 255),
        Header  = Color3.fromRGB(232, 233, 238),
        Element = Color3.fromRGB(246, 247, 250),
        Hover   = Color3.fromRGB(228, 229, 235),
        Stroke  = Color3.fromRGB(214, 216, 223),
        Text    = Color3.fromRGB(32, 33, 38),
        SubText = Color3.fromRGB(120, 122, 134),
        Accent  = Color3.fromRGB(59, 130, 246),
    },
}
_Catalyst.Themes = Themes

local AccentObjects   = {}
local AccentListeners = {}
local ThemeListeners  = {}

local function regAccent(obj, prop)
    AccentObjects[#AccentObjects + 1] = { obj = obj, prop = prop }
    obj[prop] = Theme.Accent
    return obj
end
local function onAccent(fn)
    AccentListeners[#AccentListeners + 1] = fn
end
local function onTheme(fn)
    ThemeListeners[#ThemeListeners + 1] = fn
end

local function setAccent(c)
    Theme.Accent = c
    for _, e in ipairs(AccentObjects) do
        if e.obj and e.obj.Parent then
            pcall(function() e.obj[e.prop] = c end)
        end
    end
    for _, fn in ipairs(AccentListeners) do
        pcall(fn, c)
    end
end

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = o
    return c
end
local function stroke(o, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or Theme.Stroke
    s.Thickness = th or 1
    s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    return s
end
local function tween(o, t, props, st, dir)
    local tw = TweenService:Create(
        o,
        TweenInfo.new(t or 0.2, st or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end
local function pad(o, all)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, all)
    p.PaddingBottom = UDim.new(0, all)
    p.PaddingLeft   = UDim.new(0, all)
    p.PaddingRight  = UDim.new(0, all)
    p.Parent = o
    return p
end

local function bindDrag(target, onMove)
    local dragging = false
    target.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            onMove(i.Position)
        end
    end)
    target.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not alive() then return end
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            onMove(i.Position)
        end
    end)
end

local function roundTo(n, d)
    local m = 10 ^ (d or 0)
    return math.floor(n * m + 0.5) / m
end

local function keyNameOf(k)
    if typeof(k) == "EnumItem" then return k.Name end
    if type(k) == "string" then return k end
    return "None"
end

local FileSystem = {}
do
    local hasIO = (typeof(writefile) == "function")
        and (typeof(readfile) == "function")
        and (typeof(isfile) == "function")
    local mem = {}
    function FileSystem.write(path, data)
        if hasIO then pcall(writefile, path, data) else mem[path] = data end
    end
    function FileSystem.read(path)
        if hasIO then
            local r
            pcall(function() r = readfile(path) end)
            return r
        else
            return mem[path]
        end
    end
    function FileSystem.exists(path)
        if hasIO then
            local r = false
            pcall(function() r = isfile(path) end)
            return r
        else
            return mem[path] ~= nil
        end
    end
    function FileSystem.delete(path)
        if hasIO and typeof(delfile) == "function" then
            pcall(delfile, path)
        else
            mem[path] = nil
        end
    end
    function FileSystem.list(folder)
        local out = {}
        if hasIO and typeof(listfiles) == "function" then
            local files
            pcall(function() files = listfiles(folder) end)
            if files then for _, f in ipairs(files) do out[#out + 1] = f end end
        else
            for k in pairs(mem) do out[#out + 1] = k end
        end
        return out
    end
    function FileSystem.makeFolder(folder)
        if hasIO and typeof(makefolder) == "function" then
            pcall(function()
                if not (typeof(isfolder) == "function" and isfolder(folder)) then
                    makefolder(folder)
                end
            end)
        end
    end
    FileSystem.hasIO = hasIO
end

local GUI_NAME = "_CatalystLib"

local function destroyOldGui()
    local parents = {}
    pcall(function() local h = gethui() if h then parents[#parents + 1] = h end end)
    pcall(function() parents[#parents + 1] = game:GetService("CoreGui") end)
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then parents[#parents + 1] = pg end
    end)
    for _, par in ipairs(parents) do
        for _, ch in ipairs(par:GetChildren()) do
            if ch.Name == GUI_NAME then
                pcall(function() ch:Destroy() end)
            end
        end
    end
end
destroyOldGui()

local function getGuiParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = getGuiParent() end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function applyTheme(name)
    local t = Themes[name]
    if not t then return end

    local map = {}
    for k, v in pairs(t) do
        if k ~= "Accent" and Theme[k] then
            map[#map + 1] = { from = Theme[k], to = v }
        end
    end
    for k, v in pairs(t) do
        if k ~= "Accent" then Theme[k] = v end
    end

    local function conv(c)
        for _, m in ipairs(map) do
            if c == m.from then return m.to end
        end
        return nil
    end

    for _, obj in ipairs(ScreenGui:GetDescendants()) do
        if obj:IsA("GuiObject") then
            if obj.BackgroundColor3 ~= Theme.Accent then
                local nb = conv(obj.BackgroundColor3)
                if nb then obj.BackgroundColor3 = nb end
            end
        end
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if obj.TextColor3 ~= Theme.Accent then
                local nt = conv(obj.TextColor3)
                if nt then obj.TextColor3 = nt end
            end
            if obj:IsA("TextBox") then
                local np = conv(obj.PlaceholderColor3)
                if np then obj.PlaceholderColor3 = np end
            end
        end
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            if obj.ImageColor3 ~= Theme.Accent then
                local ni = conv(obj.ImageColor3)
                if ni then obj.ImageColor3 = ni end
            end
        end
        if obj:IsA("UIStroke") then
            if obj.Color ~= Theme.Accent then
                local ns = conv(obj.Color)
                if ns then obj.Color = ns end
            end
        end
    end

    for _, fn in ipairs(ThemeListeners) do
        pcall(fn, t)
    end

    if _Catalyst._customAccent then
        setAccent(Theme.Accent)
    else
        setAccent(t.Accent)
    end
end
_Catalyst.ApplyTheme = applyTheme

taskLib.spawn(function()
    while alive() do
        _Catalyst.RainbowColorValue = (_Catalyst.RainbowColorValue + 1 / 255) % 1
        _Catalyst.HueSelectionPosition = (_Catalyst.HueSelectionPosition + 1) % 80
        taskLib.wait()
    end
end)

local function serialize(v)
    if typeof(v) == "Color3" then
        return { __c3 = { v.R, v.G, v.B } }
    end
    return v
end
local function deserialize(v)
    if type(v) == "table" and v.__c3 then
        return Color3.new(v.__c3[1], v.__c3[2], v.__c3[3])
    end
    return v
end

local function makeAPI(scroll)
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 8)
    layout.Parent    = scroll

    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, 6)
    p.PaddingLeft   = UDim.new(0, 6)
    p.PaddingRight  = UDim.new(0, 8)
    p.PaddingBottom = UDim.new(0, 10)
    p.Parent = scroll

    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

    local order = 0
    local function nextOrder() order = order + 1 return order end

    local currentSection = nil
    local function track(obj)
        if currentSection then
            table.insert(currentSection.members, obj)
            obj.Visible = not currentSection.collapsed
        end
    end

    local searchItems = {}
    local function register(frame, name, kind)
        searchItems[#searchItems + 1] = {
            frame = frame,
            name = string.lower(tostring(name or "")),
            section = currentSection,
            kind = kind or "card",
        }
    end
    local function registerSection(frame, sec, name)
        searchItems[#searchItems + 1] = {
            frame = frame,
            name = string.lower(tostring(name or "")),
            sec = sec,
            kind = "section",
        }
    end

    local function newCard(h)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, h)
        f.BackgroundColor3 = Theme.Element
        f.BorderSizePixel = 0
        f.LayoutOrder = nextOrder()
        f.Parent = scroll
        corner(f, 6)
        track(f)
        return f
    end

    local function makeTitle(card, text, yOff, widthOffset)
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.Position = UDim2.new(0, 12, 0, yOff)
        t.Size = UDim2.new(1, widthOffset, 0, 18)
        t.Font = Enum.Font.GothamMedium
        t.Text = text
        t.TextColor3 = Theme.Text
        t.TextSize = 14
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextTruncate = Enum.TextTruncate.AtEnd
        t.Parent = card
        return t
    end

    local function makeDesc(card, text, yOff)
        local d = Instance.new("TextLabel")
        d.BackgroundTransparency = 1
        d.Position = UDim2.new(0, 12, 0, yOff)
        d.Size = UDim2.new(1, -24, 0, 28)
        d.Font = Enum.Font.Gotham
        d.Text = text
        d.TextColor3 = Theme.SubText
        d.TextSize = 12
        d.TextWrapped = true
        d.TextTruncate = Enum.TextTruncate.AtEnd
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextYAlignment = Enum.TextYAlignment.Top
        d.Parent = card
        return d
    end

    local function hitOverlay(card, height)
        local b = Instance.new("TextButton")
        b.Name = "Hit"
        b.BackgroundTransparency = 1
        b.Size = height and UDim2.new(1, 0, 0, height) or UDim2.new(1, 0, 1, 0)
        b.Text = ""
        b.AutoButtonColor = false
        b.ZIndex = 2
        b.Parent = card
        b.MouseEnter:Connect(function()
            tween(card, 0.15, { BackgroundColor3 = Theme.Hover })
        end)
        b.MouseLeave:Connect(function()
            tween(card, 0.15, { BackgroundColor3 = Theme.Element })
        end)
        return b
    end

    local function keyName(k)
        if typeof(k) == "EnumItem" then return k.Name end
        if type(k) == "string" then return k end
        return "None"
    end

    local api = {}

    function api.__search(query)
        query = string.lower(tostring(query or ""))
        local searching = query ~= ""
        for _, it in ipairs(searchItems) do
            if it.kind == "section" then it.sec.__match = false end
        end
        for _, it in ipairs(searchItems) do
            if it.kind == "card" then
                if searching then
                    local hit = string.find(it.name, query, 1, true) ~= nil
                    it.frame.Visible = hit
                    if hit and it.section then it.section.__match = true end
                else
                    it.frame.Visible = (not it.section) or (not it.section.collapsed)
                end
            elseif it.kind == "line" then
                if searching then
                    it.frame.Visible = false
                else
                    it.frame.Visible = (not it.section) or (not it.section.collapsed)
                end
            end
        end
        for _, it in ipairs(searchItems) do
            if it.kind == "section" then
                if searching then
                    it.frame.Visible = it.sec.__match == true
                else
                    it.frame.Visible = true
                end
            end
        end
    end

    function api:Section(text)
        local sec = { members = {}, collapsed = false }
        _Catalyst.__secCount = (_Catalyst.__secCount or 0) + 1
        local secFlag = "_sec" .. _Catalyst.__secCount
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 28)
        f.BackgroundColor3 = Theme.Panel
        f.BorderSizePixel = 0
        f.LayoutOrder = nextOrder()
        f.Parent = scroll
        corner(f, 6)

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 0, 14)
        bar.Position = UDim2.new(0, 8, 0.5, -7)
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = Theme.Accent
        bar.Parent = f
        corner(bar, 2)
        regAccent(bar, "BackgroundColor3")

        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Position = UDim2.new(0, 20, 0, 0)
        l.Size = UDim2.new(1, -52, 1, 0)
        l.Font = Enum.Font.GothamBold
        l.Text = string.upper(text)
        l.TextColor3 = Theme.Text
        l.TextSize = 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.Parent = f

        local chev = Instance.new("TextLabel")
        chev.BackgroundTransparency = 1
        chev.AnchorPoint = Vector2.new(1, 0.5)
        chev.Position = UDim2.new(1, -12, 0.5, 0)
        chev.Size = UDim2.new(0, 16, 0, 16)
        chev.Font = Enum.Font.GothamBold
        chev.Text = ">"
        chev.Rotation = 90
        chev.TextColor3 = Theme.SubText
        chev.TextSize = 13
        chev.Parent = f

        local btn = Instance.new("TextButton")
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 2
        btn.Parent = f

        local function setCollapsed(v)
            sec.collapsed = v and true or false
            for _, m in ipairs(sec.members) do
                if m and m.Parent then m.Visible = not sec.collapsed end
            end
            tween(chev, 0.2, { Rotation = sec.collapsed and 0 or 90 })
            _Catalyst.Flags[secFlag] = sec.collapsed
        end
        btn.MouseButton1Click:Connect(function()
            setCollapsed(not sec.collapsed)
        end)

        _Catalyst.Config[secFlag] = {
            Get     = function() return sec.collapsed end,
            Set     = function(v) setCollapsed(v and true or false) end,
            Default = false,
        }
        _Catalyst.Flags[secFlag] = false

        registerSection(f, sec, text)
        currentSection = sec
        return {
            Collapse = function() setCollapsed(true) end,
            Expand   = function() setCollapsed(false) end,
            Toggle   = function() setCollapsed(not sec.collapsed) end,
        }
    end

    function api:Label(text)
        local card = newCard(34)
        card.BackgroundColor3 = Theme.Panel
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Position = UDim2.new(0, 12, 0, 0)
        l.Size = UDim2.new(1, -24, 1, 0)
        l.Font = Enum.Font.Gotham
        l.Text = text
        l.TextColor3 = Theme.SubText
        l.TextSize = 13
        l.TextWrapped = true
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = card
        register(card, text, "card")
        return { Set = function(t) l.Text = t end }
    end

    function api:Line()
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 1)
        f.BackgroundColor3 = Theme.Stroke
        f.BorderSizePixel = 0
        f.LayoutOrder = nextOrder()
        f.Parent = scroll
        track(f)
        register(f, "", "line")
    end

    function api:Button(text, desc, callback)
        callback = callback or function() end
        local hasDesc = desc and desc ~= ""
        local card = newCard(hasDesc and 62 or 38)
        register(card, text, "card")
        local title = makeTitle(card, text, hasDesc and 8 or 0, -52)
        if not hasDesc then title.Size = UDim2.new(1, -52, 1, 0) end
        if hasDesc then makeDesc(card, desc, 27) end

        local arrow = Instance.new("TextLabel")
        arrow.BackgroundTransparency = 1
        arrow.AnchorPoint = Vector2.new(1, 0.5)
        arrow.Position = hasDesc and UDim2.new(1, -14, 0, 18) or UDim2.new(1, -14, 0.5, 0)
        arrow.Size = UDim2.new(0, 20, 0, 20)
        arrow.Font = Enum.Font.GothamBold
        arrow.Text = ">"
        arrow.TextColor3 = Theme.SubText
        arrow.TextSize = 14
        arrow.Parent = card

        hitOverlay(card).MouseButton1Click:Connect(function()
            tween(card, 0.08, { BackgroundColor3 = Theme.Accent })
            taskLib.spawn(function()
                taskLib.wait(0.12)
                tween(card, 0.2, { BackgroundColor3 = Theme.Element })
            end)
            pcall(callback)
        end)
        return {}
    end

    function api:Toggle(text, desc, default, callback, flag, opts)
        callback = callback or function() end
        opts = opts or {}
        local hasDesc = desc and desc ~= ""
        local kbKey = opts.Keybind and keyName(opts.Keybind) or nil
        local card = newCard(hasDesc and 62 or 38)
        register(card, text, "card")
        local titleReserve = kbKey and -120 or -64
        local title = makeTitle(card, text, hasDesc and 8 or 0, titleReserve)
        if not hasDesc then title.Size = UDim2.new(1, titleReserve, 1, 0) end
        if hasDesc then makeDesc(card, desc, 27) end

        local cY = hasDesc and { 0, 18 } or { 0.5, 0 }

        local pill = Instance.new("Frame")
        pill.AnchorPoint = Vector2.new(1, 0.5)
        pill.Position = UDim2.new(1, -14, cY[1], cY[2])
        pill.Size = UDim2.new(0, 40, 0, 20)
        pill.BackgroundColor3 = Theme.Stroke
        pill.BorderSizePixel = 0
        pill.Parent = card
        corner(pill, 10)

        local knob = Instance.new("Frame")
        knob.Position = UDim2.new(0, 2, 0.5, 0)
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.BackgroundColor3 = Theme.Text
        knob.BorderSizePixel = 0
        knob.Parent = pill
        corner(knob, 8)

        local state = default and true or false
        local toggleKbEntry

        local function apply(v, fire)
            state = v and true or false
            tween(knob, 0.18, { Position = UDim2.new(state and 1 or 0, state and -18 or 2, 0.5, 0) })
            tween(pill, 0.18, { BackgroundColor3 = state and Theme.Accent or Theme.Stroke })
            knob.BackgroundColor3 = Theme.Text
            if flag then _Catalyst.Flags[flag] = state end
            if toggleKbEntry then toggleKbEntry:SetActive(state) end
            if fire then pcall(callback, state) end
        end

        onAccent(function(c)
            pill.BackgroundColor3 = state and c or Theme.Stroke
            knob.BackgroundColor3 = Theme.Text
        end)

        onTheme(function()
            knob.BackgroundColor3 = Theme.Text
            pill.BackgroundColor3 = state and Theme.Accent or Theme.Stroke
        end)

        hitOverlay(card).MouseButton1Click:Connect(function()
            apply(not state, true)
        end)

        if kbKey then
            if _Catalyst.__kbAdd then
                toggleKbEntry = _Catalyst.__kbAdd(text, opts.Keybind)
            end

            local chip = Instance.new("Frame")
            chip.AnchorPoint = Vector2.new(1, 0.5)
            chip.Position = UDim2.new(1, -62, cY[1], cY[2])
            chip.Size = UDim2.new(0, 48, 0, 22)
            chip.BackgroundColor3 = Theme.Panel
            chip.BorderSizePixel = 0
            chip.Parent = card
            corner(chip, 4)
            stroke(chip, Theme.Stroke, 1, 0)

            local chipLbl = Instance.new("TextLabel")
            chipLbl.BackgroundTransparency = 1
            chipLbl.Size = UDim2.new(1, -6, 1, 0)
            chipLbl.Position = UDim2.new(0, 3, 0, 0)
            chipLbl.Font = Enum.Font.GothamMedium
            chipLbl.Text = kbKey
            chipLbl.TextColor3 = Theme.SubText
            chipLbl.TextSize = 11
            chipLbl.TextTruncate = Enum.TextTruncate.AtEnd
            chipLbl.Parent = chip

            local chipBtn = Instance.new("TextButton")
            chipBtn.BackgroundTransparency = 1
            chipBtn.Size = UDim2.new(1, 0, 1, 0)
            chipBtn.Text = ""
            chipBtn.AutoButtonColor = false
            chipBtn.ZIndex = 3
            chipBtn.Parent = chip

            local kbListening = false
            local function setKbKey(k)
                kbKey = keyName(k)
                chipLbl.Text = kbKey
                chipLbl.TextColor3 = Theme.SubText
                if toggleKbEntry then toggleKbEntry:SetKey(k) end
                if flag then _Catalyst.Flags[flag .. "Key"] = kbKey end
            end

            chipBtn.MouseButton1Click:Connect(function()
                if kbListening then return end
                kbListening = true
                chipLbl.Text = "..."
                chipLbl.TextColor3 = Theme.Accent
                local conn
                conn = UserInputService.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Keyboard then
                        setKbKey(i.KeyCode)
                        kbListening = false
                        conn:Disconnect()
                    end
                end)
            end)

            UserInputService.InputBegan:Connect(function(i, gpe)
                if not alive() then return end
                if gpe or kbListening then return end
                if i.KeyCode ~= Enum.KeyCode.Unknown and kbKey and i.KeyCode.Name == kbKey then
                    apply(not state, true)
                end
            end)

            if flag then
                _Catalyst.Config[flag .. "Key"] = {
                    Get     = function() return kbKey end,
                    Set     = function(k) setKbKey(k) end,
                    Default = kbKey,
                }
                _Catalyst.Flags[flag .. "Key"] = kbKey
            end
        end

        apply(state, false)
        if flag then
            _Catalyst.Config[flag] = {
                Get     = function() return state end,
                Set     = function(v) apply(v, true) end,
                Default = default and true or false,
            }
            _Catalyst.Flags[flag] = state
        end
        if state then pcall(callback, true) end
        return { Set = function(v) apply(v, true) end, Get = function() return state end }
    end

    function api:Slider(text, desc, min, max, default, callback, flag, opts)
        min, max = min or 0, max or 100
        default = math.clamp(default or min, min, max)
        callback = callback or function() end
        opts = opts or {}
        local decimals = opts.Decimals or 0
        local prefix   = opts.Prefix or ""
        local suffix   = opts.Suffix or ""
        local hasDesc  = desc and desc ~= ""
        local card = newCard(hasDesc and 84 or 52)
        register(card, text, "card")

        local function fmt(n)
            local v
            if decimals > 0 then
                v = string.format("%." .. decimals .. "f", n)
            else
                v = tostring(math.floor(n + 0.5))
            end
            return prefix .. v .. suffix
        end

        makeTitle(card, text, 8, -104)

        local valLbl = Instance.new("TextLabel")
        valLbl.BackgroundTransparency = 1
        valLbl.AnchorPoint = Vector2.new(1, 0)
        valLbl.Position = UDim2.new(1, -14, 0, 8)
        valLbl.Size = UDim2.new(0, 88, 0, 18)
        valLbl.Font = Enum.Font.GothamBold
        valLbl.Text = fmt(default)
        valLbl.TextColor3 = Theme.Text
        valLbl.TextSize = 13
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.TextTruncate = Enum.TextTruncate.AtEnd
        valLbl.Parent = card

        if hasDesc then makeDesc(card, desc, 27) end

        local track = Instance.new("Frame")
        track.AnchorPoint = Vector2.new(0, 1)
        track.Position = UDim2.new(0, 12, 1, -13)
        track.Size = UDim2.new(1, -24, 0, 5)
        track.BackgroundColor3 = Theme.Stroke
        track.BorderSizePixel = 0
        track.Parent = card
        corner(track, 3)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = track
        corner(fill, 3)
        regAccent(fill, "BackgroundColor3")

        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.new(0, 0, 0.5, 0)
        knob.Size = UDim2.new(0, 13, 0, 13)
        knob.BackgroundColor3 = Theme.Text
        knob.BorderSizePixel = 0
        knob.ZIndex = 3
        knob.Parent = track
        corner(knob, 7)

        onTheme(function()
            knob.BackgroundColor3 = Theme.Text
            track.BackgroundColor3 = Theme.Stroke
            valLbl.TextColor3 = Theme.Text
        end)

        local value = default
        local function setAlpha(a, fire)
            a = math.clamp(a, 0, 1)
            value = roundTo(min + a * (max - min), decimals)
            fill.Size = UDim2.new(a, 0, 1, 0)
            knob.Position = UDim2.new(a, 0, 0.5, 0)
            valLbl.Text = fmt(value)
            if flag then _Catalyst.Flags[flag] = value end
            if fire then pcall(callback, value) end
        end
        local function setValue(v, fire)
            v = math.clamp(v, min, max)
            setAlpha((v - min) / (max - min), fire)
        end

        bindDrag(track, function(posV)
            local a = (posV.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
            setAlpha(a, true)
        end)

        setValue(default, false)
        if flag then
            _Catalyst.Config[flag] = {
                Get     = function() return value end,
                Set     = function(v) setValue(v, true) end,
                Default = default,
            }
            _Catalyst.Flags[flag] = value
        end
        pcall(callback, value)
        return { Set = function(v) setValue(v, true) end, Get = function() return value end }
    end

    function api:Dropdown(text, list, callback, flag, default)
        list = list or {}
        callback = callback or function() end
        local card = newCard(38)
        register(card, text, "card")
        card.ClipsDescendants = true

        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0, 12, 0, 0)
        title.Size = UDim2.new(1, -122, 0, 38)
        title.Font = Enum.Font.GothamMedium
        title.Text = text
        title.TextColor3 = Theme.Text
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.Parent = card

        local sel = Instance.new("TextLabel")
        sel.BackgroundTransparency = 1
        sel.AnchorPoint = Vector2.new(1, 0)
        sel.Position = UDim2.new(1, -34, 0, 0)
        sel.Size = UDim2.new(0, 86, 0, 38)
        sel.Font = Enum.Font.Gotham
        sel.Text = default or "Select..."
        sel.TextColor3 = Theme.SubText
        sel.TextSize = 13
        sel.TextXAlignment = Enum.TextXAlignment.Right
        sel.TextTruncate = Enum.TextTruncate.AtEnd
        sel.Parent = card

        local arrow = Instance.new("TextLabel")
        arrow.BackgroundTransparency = 1
        arrow.AnchorPoint = Vector2.new(1, 0)
        arrow.Position = UDim2.new(1, -14, 0, 0)
        arrow.Size = UDim2.new(0, 16, 0, 38)
        arrow.Font = Enum.Font.GothamBold
        arrow.Text = "v"
        arrow.TextColor3 = Theme.SubText
        arrow.TextSize = 12
        arrow.Parent = card

        local holder = Instance.new("ScrollingFrame")
        holder.Position = UDim2.new(0, 8, 0, 40)
        holder.Size = UDim2.new(1, -16, 1, -46)
        holder.BackgroundTransparency = 1
        holder.BorderSizePixel = 0
        holder.ScrollBarThickness = 3
        holder.AutomaticCanvasSize = Enum.AutomaticSize.Y
        holder.CanvasSize = UDim2.new(0, 0, 0, 0)
        holder.Parent = card
        regAccent(holder, "ScrollBarImageColor3")
        local hLayout = Instance.new("UIListLayout")
        hLayout.SortOrder = Enum.SortOrder.LayoutOrder
        hLayout.Padding = UDim.new(0, 3)
        hLayout.Parent = holder

        local items = {}
        local open = false
        local selected = default

        local function sizeCard()
            if open then
                local n = math.min(#items, 5)
                card.Size = UDim2.new(1, 0, 0, 44 + n * 28)
            else
                card.Size = UDim2.new(1, 0, 0, 38)
            end
        end
        local function toggle()
            open = not open
            tween(arrow, 0.2, { Rotation = open and 180 or 0 })
            sizeCard()
        end
        local function choose(v, fire)
            selected = v
            sel.Text = tostring(v)
            sel.TextColor3 = Theme.Text
            if flag then _Catalyst.Flags[flag] = v end
            if fire then pcall(callback, v) end
            if open then toggle() end
        end
        local function addItem(v)
            local it = Instance.new("TextButton")
            it.Size = UDim2.new(1, 0, 0, 25)
            it.BackgroundColor3 = Theme.Panel
            it.AutoButtonColor = false
            it.Font = Enum.Font.Gotham
            it.Text = tostring(v)
            it.TextColor3 = Theme.SubText
            it.TextSize = 13
            it.TextTruncate = Enum.TextTruncate.AtEnd
            it.Parent = holder
            corner(it, 4)
            it.MouseEnter:Connect(function()
                tween(it, 0.12, { BackgroundColor3 = Theme.Hover, TextColor3 = Theme.Text })
            end)
            it.MouseLeave:Connect(function()
                tween(it, 0.12, { BackgroundColor3 = Theme.Panel, TextColor3 = Theme.SubText })
            end)
            it.MouseButton1Click:Connect(function() choose(v, true) end)
            items[#items + 1] = it
        end

        for _, v in ipairs(list) do addItem(v) end
        hitOverlay(card, 38).MouseButton1Click:Connect(toggle)

        if default then choose(default, false) end
        if flag then
            _Catalyst.Config[flag] = {
                Get     = function() return selected end,
                Set     = function(v) choose(v, true) end,
                Default = default,
            }
            _Catalyst.Flags[flag] = selected
        end

        return {
            Get     = function() return selected end,
            Set     = function(v) choose(v, true) end,
            Add     = function(v) addItem(v) if open then sizeCard() end end,
            Refresh = function(newList)
                for _, it in ipairs(items) do it:Destroy() end
                items = {}
                for _, v in ipairs(newList or {}) do addItem(v) end
                sizeCard()
            end,
        }
    end

    function api:MultiDropdown(text, list, callback, flag, default)
        list = list or {}
        callback = callback or function() end
        local card = newCard(38)
        register(card, text, "card")
        card.ClipsDescendants = true

        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0, 12, 0, 0)
        title.Size = UDim2.new(1, -150, 0, 38)
        title.Font = Enum.Font.GothamMedium
        title.Text = text
        title.TextColor3 = Theme.Text
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.Parent = card

        local sel = Instance.new("TextLabel")
        sel.BackgroundTransparency = 1
        sel.AnchorPoint = Vector2.new(1, 0)
        sel.Position = UDim2.new(1, -34, 0, 0)
        sel.Size = UDim2.new(0, 130, 0, 38)
        sel.Font = Enum.Font.Gotham
        sel.Text = "None"
        sel.TextColor3 = Theme.SubText
        sel.TextSize = 13
        sel.TextXAlignment = Enum.TextXAlignment.Right
        sel.TextTruncate = Enum.TextTruncate.AtEnd
        sel.Parent = card

        local arrow = Instance.new("TextLabel")
        arrow.BackgroundTransparency = 1
        arrow.AnchorPoint = Vector2.new(1, 0)
        arrow.Position = UDim2.new(1, -14, 0, 0)
        arrow.Size = UDim2.new(0, 16, 0, 38)
        arrow.Font = Enum.Font.GothamBold
        arrow.Text = "v"
        arrow.TextColor3 = Theme.SubText
        arrow.TextSize = 12
        arrow.Parent = card

        local holder = Instance.new("ScrollingFrame")
        holder.Position = UDim2.new(0, 8, 0, 40)
        holder.Size = UDim2.new(1, -16, 1, -46)
        holder.BackgroundTransparency = 1
        holder.BorderSizePixel = 0
        holder.ScrollBarThickness = 3
        holder.AutomaticCanvasSize = Enum.AutomaticSize.Y
        holder.CanvasSize = UDim2.new(0, 0, 0, 0)
        holder.Parent = card
        regAccent(holder, "ScrollBarImageColor3")
        local hLayout = Instance.new("UIListLayout")
        hLayout.SortOrder = Enum.SortOrder.LayoutOrder
        hLayout.Padding = UDim.new(0, 3)
        hLayout.Parent = holder

        local items = {}
        local open = false
        local selected = {}

        local function isSel(v)
            for _, x in ipairs(selected) do
                if x == v then return true end
            end
            return false
        end
        local function snapshot()
            local t = {}
            for _, v in ipairs(selected) do t[#t + 1] = v end
            return t
        end
        local function refreshDisplay()
            if #selected == 0 then
                sel.Text = "None"
                sel.TextColor3 = Theme.SubText
            else
                sel.Text = table.concat(selected, ", ")
                sel.TextColor3 = Theme.Text
            end
        end
        local function sizeCard()
            if open then
                local n = math.max(1, math.min(#items, 5))
                card.Size = UDim2.new(1, 0, 0, 44 + n * 28)
            else
                card.Size = UDim2.new(1, 0, 0, 38)
            end
        end
        local function toggleOpen()
            open = not open
            tween(arrow, 0.2, { Rotation = open and 180 or 0 })
            sizeCard()
        end
        local function refreshItems()
            for _, it in ipairs(items) do it.update() end
        end
        local function fire()
            if flag then _Catalyst.Flags[flag] = snapshot() end
            pcall(callback, snapshot())
        end
        local function toggleItem(v)
            if isSel(v) then
                for i, x in ipairs(selected) do
                    if x == v then table.remove(selected, i) break end
                end
            else
                selected[#selected + 1] = v
            end
            refreshItems()
            refreshDisplay()
            fire()
        end
        local function setSelected(tbl, doFire)
            selected = {}
            if type(tbl) == "table" then
                for _, v in ipairs(tbl) do selected[#selected + 1] = v end
            end
            refreshItems()
            refreshDisplay()
            if flag then _Catalyst.Flags[flag] = snapshot() end
            if doFire then pcall(callback, snapshot()) end
        end
        local function addItem(v)
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, 0, 0, 25)
            row.BackgroundColor3 = Theme.Panel
            row.AutoButtonColor = false
            row.Text = ""
            row.Parent = holder
            corner(row, 4)

            local cb = Instance.new("Frame")
            cb.AnchorPoint = Vector2.new(0, 0.5)
            cb.Position = UDim2.new(0, 7, 0.5, 0)
            cb.Size = UDim2.new(0, 15, 0, 15)
            cb.BackgroundColor3 = Theme.Panel
            cb.BorderSizePixel = 0
            cb.Parent = row
            corner(cb, 4)
            local cbStroke = stroke(cb, Theme.Stroke, 1, 0)

            local check = Instance.new("TextLabel")
            check.BackgroundTransparency = 1
            check.Size = UDim2.new(1, 0, 1, 0)
            check.Font = Enum.Font.GothamBold
            check.Text = "X"
            check.TextColor3 = Color3.fromRGB(255, 255, 255)
            check.TextSize = 11
            check.Visible = false
            check.Parent = cb

            local nameLbl = Instance.new("TextLabel")
            nameLbl.BackgroundTransparency = 1
            nameLbl.Position = UDim2.new(0, 30, 0, 0)
            nameLbl.Size = UDim2.new(1, -36, 1, 0)
            nameLbl.Font = Enum.Font.Gotham
            nameLbl.Text = tostring(v)
            nameLbl.TextColor3 = Theme.SubText
            nameLbl.TextSize = 13
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.Parent = row

            local function update()
                local on = isSel(v)
                cb.BackgroundColor3 = on and Theme.Accent or Theme.Panel
                cbStroke.Color = on and Theme.Accent or Theme.Stroke
                check.Visible = on
                nameLbl.TextColor3 = on and Theme.Text or Theme.SubText
            end

            row.MouseEnter:Connect(function()
                tween(row, 0.12, { BackgroundColor3 = Theme.Hover })
            end)
            row.MouseLeave:Connect(function()
                tween(row, 0.12, { BackgroundColor3 = Theme.Panel })
            end)
            row.MouseButton1Click:Connect(function() toggleItem(v) end)

            items[#items + 1] = { instance = row, update = update }
            update()
        end

        for _, v in ipairs(list) do addItem(v) end
        hitOverlay(card, 38).MouseButton1Click:Connect(toggleOpen)

        onAccent(refreshItems)
        onTheme(refreshItems)
        onTheme(refreshDisplay)

        if type(default) == "table" then
            setSelected(default, false)
        else
            refreshDisplay()
        end

        if flag then
            _Catalyst.Config[flag] = {
                Get     = function() return snapshot() end,
                Set     = function(v) setSelected(v, true) end,
                Default = snapshot(),
            }
            _Catalyst.Flags[flag] = snapshot()
        end

        return {
            Get         = function() return snapshot() end,
            GetSelected = function() return snapshot() end,
            Set         = function(v) setSelected(v, true) end,
            Add         = function(v) addItem(v) if open then sizeCard() end end,
            Clear       = function() setSelected({}, true) end,
            Refresh     = function(newList)
                for _, it in ipairs(items) do it.instance:Destroy() end
                items = {}
                for _, v in ipairs(newList or {}) do addItem(v) end
                refreshDisplay()
                sizeCard()
            end,
        }
    end

    function api:Colorpicker(text, default, callback, flag)
        default = default or Theme.Accent
        callback = callback or function() end
        local card = newCard(38)
        register(card, text, "card")
        card.ClipsDescendants = true
        local title = makeTitle(card, text, 0, -64)
        title.Size = UDim2.new(1, -64, 0, 38)

        local swatch = Instance.new("Frame")
        swatch.AnchorPoint = Vector2.new(1, 0.5)
        swatch.Position = UDim2.new(1, -14, 0, 19)
        swatch.Size = UDim2.new(0, 34, 0, 18)
        swatch.BackgroundColor3 = default
        swatch.BorderSizePixel = 0
        swatch.Parent = card
        corner(swatch, 4)
        stroke(swatch, Theme.Stroke, 1, 0)

        local h, s, v = Color3.toHSV(default)
        local rainbow = false

        local box = Instance.new("ImageLabel")
        box.Position = UDim2.new(0, 12, 0, 44)
        box.Size = UDim2.new(1, -24, 0, 100)
        box.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        box.BorderSizePixel = 0
        box.Image = "rbxassetid://4155801252"
        box.Parent = card
        corner(box, 4)

        local boxDot = Instance.new("Frame")
        boxDot.AnchorPoint = Vector2.new(0.5, 0.5)
        boxDot.Size = UDim2.new(0, 10, 0, 10)
        boxDot.BackgroundColor3 = Color3.new(1, 1, 1)
        boxDot.BorderSizePixel = 0
        boxDot.Parent = box
        corner(boxDot, 5)
        stroke(boxDot, Color3.new(0, 0, 0), 1, 0.3)

        local hueBar = Instance.new("Frame")
        hueBar.Position = UDim2.new(0, 12, 0, 150)
        hueBar.Size = UDim2.new(1, -24, 0, 14)
        hueBar.BorderSizePixel = 0
        hueBar.Parent = card
        corner(hueBar, 4)
        local hg = Instance.new("UIGradient")
        hg.Color = ColorSequence.new {
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
        }
        hg.Parent = hueBar

        local hueDot = Instance.new("Frame")
        hueDot.AnchorPoint = Vector2.new(0.5, 0.5)
        hueDot.Size = UDim2.new(0, 6, 1, 4)
        hueDot.BackgroundColor3 = Color3.new(1, 1, 1)
        hueDot.BorderSizePixel = 0
        hueDot.Parent = hueBar
        corner(hueDot, 3)
        stroke(hueDot, Color3.new(0, 0, 0), 1, 0.3)

        local rbRow = Instance.new("TextButton")
        rbRow.Position = UDim2.new(0, 12, 0, 172)
        rbRow.Size = UDim2.new(1, -24, 0, 22)
        rbRow.BackgroundTransparency = 1
        rbRow.Text = "Rainbow"
        rbRow.Font = Enum.Font.Gotham
        rbRow.TextColor3 = Theme.SubText
        rbRow.TextSize = 13
        rbRow.TextXAlignment = Enum.TextXAlignment.Left
        rbRow.AutoButtonColor = false
        rbRow.Parent = card

        local rbPill = Instance.new("Frame")
        rbPill.AnchorPoint = Vector2.new(1, 0.5)
        rbPill.Position = UDim2.new(1, 0, 0.5, 0)
        rbPill.Size = UDim2.new(0, 34, 0, 16)
        rbPill.BackgroundColor3 = Theme.Stroke
        rbPill.BorderSizePixel = 0
        rbPill.Parent = rbRow
        corner(rbPill, 8)

        local rbKnob = Instance.new("Frame")
        rbKnob.Position = UDim2.new(0, 2, 0.5, 0)
        rbKnob.AnchorPoint = Vector2.new(0, 0.5)
        rbKnob.Size = UDim2.new(0, 12, 0, 12)
        rbKnob.BackgroundColor3 = Theme.Text
        rbKnob.BorderSizePixel = 0
        rbKnob.Parent = rbPill
        corner(rbKnob, 6)

        onTheme(function()
            rbKnob.BackgroundColor3 = Theme.Text
            rbRow.TextColor3 = Theme.SubText
            if not rainbow then rbPill.BackgroundColor3 = Theme.Stroke end
        end)

        local open = false
        local function sizeCard()
            card.Size = UDim2.new(1, 0, 0, open and 204 or 38)
        end
        local function applyColor(fire)
            local col = Color3.fromHSV(h, s, v)
            swatch.BackgroundColor3 = col
            box.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            boxDot.Position = UDim2.new(s, 0, 1 - v, 0)
            hueDot.Position = UDim2.new(h, 0, 0.5, 0)
            if flag then _Catalyst.Flags[flag] = col end
            if fire then pcall(callback, col) end
        end

        onAccent(function(c)
            if rainbow then rbPill.BackgroundColor3 = c end
        end)

        bindDrag(box, function(posV)
            if rainbow then return end
            local x = math.clamp((posV.X - box.AbsolutePosition.X) / math.max(box.AbsoluteSize.X, 1), 0, 1)
            local y = math.clamp((posV.Y - box.AbsolutePosition.Y) / math.max(box.AbsoluteSize.Y, 1), 0, 1)
            s, v = x, 1 - y
            applyColor(true)
        end)
        bindDrag(hueBar, function(posV)
            if rainbow then return end
            local x = math.clamp((posV.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
            h = x
            applyColor(true)
        end)

        rbRow.MouseButton1Click:Connect(function()
            rainbow = not rainbow
            tween(rbPill, 0.18, { BackgroundColor3 = rainbow and Theme.Accent or Theme.Stroke })
            tween(rbKnob, 0.18, { Position = UDim2.new(rainbow and 1 or 0, rainbow and -14 or 2, 0.5, 0) })
            if rainbow then
                taskLib.spawn(function()
                    while rainbow and alive() do
                        h, s, v = _Catalyst.RainbowColorValue, 1, 1
                        applyColor(true)
                        taskLib.wait()
                    end
                end)
            end
        end)

        hitOverlay(card, 38).MouseButton1Click:Connect(function()
            open = not open
            sizeCard()
        end)

        applyColor(false)
        if flag then
            _Catalyst.Config[flag] = {
                Get     = function() return Color3.fromHSV(h, s, v) end,
                Set     = function(c) h, s, v = Color3.toHSV(c) applyColor(true) end,
                Default = default,
            }
            _Catalyst.Flags[flag] = default
        end
        pcall(callback, default)
        return {
            Get       = function() return Color3.fromHSV(h, s, v) end,
            Set       = function(c) h, s, v = Color3.toHSV(c) applyColor(true) end,
            SetSilent = function(c) h, s, v = Color3.toHSV(c) applyColor(false) end,
        }
    end

    function api:Bind(text, defaultKey, callback, flag, opts)
        callback = callback or function() end
        opts = opts or {}
        local mode = opts.Mode or "Press"
        local card = newCard(38)
        register(card, text, "card")
        local title = makeTitle(card, text, 0, -104)
        title.Size = UDim2.new(1, -104, 1, 0)

        local key = keyName(defaultKey)
        local bstate = false

        local kbEntry
        if _Catalyst.__kbAdd and not opts.NoList then
            kbEntry = _Catalyst.__kbAdd(text, defaultKey)
        end

        local modeLbl = Instance.new("TextLabel")
        modeLbl.BackgroundTransparency = 1
        modeLbl.AnchorPoint = Vector2.new(1, 0.5)
        modeLbl.Position = UDim2.new(1, -104, 0.5, 0)
        modeLbl.Size = UDim2.new(0, 50, 0, 16)
        modeLbl.Font = Enum.Font.Gotham
        modeLbl.Text = string.lower(mode)
        modeLbl.TextColor3 = Theme.SubText
        modeLbl.TextSize = 11
        modeLbl.TextXAlignment = Enum.TextXAlignment.Right
        modeLbl.Parent = card

        local box = Instance.new("Frame")
        box.AnchorPoint = Vector2.new(1, 0.5)
        box.Position = UDim2.new(1, -14, 0.5, 0)
        box.Size = UDim2.new(0, 84, 0, 24)
        box.BackgroundColor3 = Theme.Panel
        box.BorderSizePixel = 0
        box.Parent = card
        corner(box, 4)
        local boxStroke = stroke(box, Theme.Stroke, 1, 0)

        local keyLbl = Instance.new("TextLabel")
        keyLbl.BackgroundTransparency = 1
        keyLbl.Size = UDim2.new(1, -8, 1, 0)
        keyLbl.Position = UDim2.new(0, 4, 0, 0)
        keyLbl.Font = Enum.Font.GothamMedium
        keyLbl.Text = key
        keyLbl.TextColor3 = Theme.SubText
        keyLbl.TextSize = 12
        keyLbl.TextTruncate = Enum.TextTruncate.AtEnd
        keyLbl.Parent = box

        local active = false
        local function bindFlashOn()
            active = true
            tween(box, 0.12, { BackgroundColor3 = Theme.Accent })
            boxStroke.Color = Theme.Accent
            keyLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        local function bindFlashOff()
            active = false
            tween(box, 0.18, { BackgroundColor3 = Theme.Panel })
            boxStroke.Color = Theme.Stroke
            keyLbl.TextColor3 = Theme.SubText
        end

        onAccent(function(c)
            if active then
                box.BackgroundColor3 = c
                boxStroke.Color = c
            end
        end)
        onTheme(function()
            if active then
                box.BackgroundColor3 = Theme.Accent
                boxStroke.Color = Theme.Accent
                keyLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                box.BackgroundColor3 = Theme.Panel
                boxStroke.Color = Theme.Stroke
                keyLbl.TextColor3 = Theme.SubText
            end
            modeLbl.TextColor3 = Theme.SubText
        end)

        local listening = false
        local function setKey(k)
            key = keyName(k)
            keyLbl.Text = key
            if not active then keyLbl.TextColor3 = Theme.SubText end
            if kbEntry then kbEntry:SetKey(k) end
            if flag then _Catalyst.Flags[flag] = key end
        end

        hitOverlay(card).MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            keyLbl.Text = "..."
            keyLbl.TextColor3 = Theme.Accent
            local conn
            conn = UserInputService.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.Keyboard then
                    setKey(i.KeyCode)
                    listening = false
                    conn:Disconnect()
                end
            end)
        end)

        UserInputService.InputBegan:Connect(function(i, gpe)
            if not alive() then return end
            if gpe or listening then return end
            if i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode.Name == key then
                if mode == "Hold" then
                    bindFlashOn()
                    if kbEntry then kbEntry:SetActive(true) end
                    pcall(callback, true)
                elseif mode == "Toggle" then
                    bstate = not bstate
                    if bstate then bindFlashOn() else bindFlashOff() end
                    if kbEntry then kbEntry:SetActive(bstate) end
                    pcall(callback, bstate)
                else
                    bindFlashOn()
                    if kbEntry then kbEntry:SetActive(true) end
                    taskLib.spawn(function()
                        taskLib.wait(0.16)
                        bindFlashOff()
                        if kbEntry then kbEntry:SetActive(false) end
                    end)
                    pcall(callback)
                end
            end
        end)
        if mode == "Hold" then
            UserInputService.InputEnded:Connect(function(i)
                if not alive() then return end
                if i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode.Name == key then
                    bindFlashOff()
                    if kbEntry then kbEntry:SetActive(false) end
                    pcall(callback, false)
                end
            end)
        end

        if flag then
            _Catalyst.Config[flag] = {
                Get     = function() return key end,
                Set     = function(k) setKey(k) end,
                Default = key,
            }
            _Catalyst.Flags[flag] = key
        end
        return {
            Get      = function() return key end,
            Set      = setKey,
            GetState = function() return bstate end,
        }
    end

    function api:Textbox(text, desc, clearOnEnter, callback, flag)
        callback = callback or function() end
        local hasDesc = desc and desc ~= ""
        local card = newCard(hasDesc and 88 or 66)
        register(card, text, "card")
        makeTitle(card, text, 8, -24)
        if hasDesc then
            local d = makeDesc(card, desc, 26)
            d.Size = UDim2.new(1, -24, 0, 24)
        end

        local frame = Instance.new("Frame")
        frame.AnchorPoint = Vector2.new(0, 1)
        frame.Position = UDim2.new(0, 12, 1, -10)
        frame.Size = UDim2.new(1, -24, 0, 28)
        frame.BackgroundColor3 = Theme.Panel
        frame.BorderSizePixel = 0
        frame.Parent = card
        corner(frame, 4)
        stroke(frame, Theme.Stroke, 1, 0)

        local tb = Instance.new("TextBox")
        tb.BackgroundTransparency = 1
        tb.Size = UDim2.new(1, -16, 1, 0)
        tb.Position = UDim2.new(0, 8, 0, 0)
        tb.Font = Enum.Font.Gotham
        tb.PlaceholderText = "..."
        tb.Text = ""
        tb.TextColor3 = Theme.Text
        tb.PlaceholderColor3 = Theme.SubText
        tb.TextSize = 13
        tb.ClearTextOnFocus = false
        tb.TextXAlignment = Enum.TextXAlignment.Left
        tb.TextTruncate = Enum.TextTruncate.AtEnd
        tb.Parent = frame

        tb.FocusLost:Connect(function(enter)
            if enter then
                pcall(callback, tb.Text)
                if flag then _Catalyst.Flags[flag] = tb.Text end
                if clearOnEnter then tb.Text = "" end
            end
        end)

        if flag then
            _Catalyst.Config[flag] = {
                Get     = function() return tb.Text end,
                Set     = function(vv) tb.Text = tostring(vv) pcall(callback, tb.Text) end,
                Default = "",
            }
            _Catalyst.Flags[flag] = ""
        end
        return {
            Get = function() return tb.Text end,
            Set = function(vv) tb.Text = tostring(vv) end,
        }
    end

    return api
end

function _Catalyst:Window(opt)
    if type(opt) == "string" then opt = { Title = opt } end
    opt = opt or {}

    local Title        = opt.Title or "_Catalyst"
    local SubTitle     = opt.SubTitle or opt.Sub or "GX Edition"
    local ConfigFolder = opt.ConfigFolder or "_CatalystConfigs"
    local ToggleKey    = opt.ToggleKey or opt.CloseBind or Enum.KeyCode.RightAlt
    if opt.Accent then
        _Catalyst._customAccent = true
        _Catalyst.Flags["_customaccent"] = true
        setAccent(opt.Accent)
    end
    if opt.Theme and Themes[opt.Theme] then applyTheme(opt.Theme) end
    FileSystem.makeFolder(ConfigFolder)

    local WIN_W, WIN_H = 880, 540
    local PAD, GAP     = 12, 10
    local SIDE_W       = 250
    local SIDE_H       = 150
    local GRID         = 16
    local function snap(n) return math.floor(n / GRID + 0.5) * GRID end

    local Window = {}

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Size = UDim2.fromOffset(WIN_W, WIN_H)
    MainFrame.BackgroundColor3 = Theme.Window
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Parent = ScreenGui
    corner(MainFrame, 10)
    stroke(MainFrame, Theme.Stroke, 1, 0.2)

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 0
    uiScale.Parent = MainFrame

    local fitScale, userScale, isOpen = 1, 1, true
    local function targetScale() return fitScale * userScale end
    local function computeFit()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        fitScale = math.min(1, (vp.X - 40) / WIN_W, (vp.Y - 40) / WIN_H)
        if fitScale < 0.4 then fitScale = 0.4 end
    end
    local function applyScale()
        if isOpen then tween(uiScale, 0.2, { Scale = targetScale() }) end
    end
    computeFit()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if not alive() then return end
            computeFit() applyScale()
        end)
    end

    local streamerMode = false
    local wmVisible = true

    local toggleBusy = false
    local function toggleUI()
        if not MainFrame.Parent then return end
        if toggleBusy then return end
        toggleBusy = true
        isOpen = not isOpen
        if isOpen then
            MainFrame.Visible = true
            local tw = tween(uiScale, 0.26, { Scale = targetScale() }, Enum.EasingStyle.Quart)
            tw.Completed:Connect(function() toggleBusy = false end)
        else
            local tw = tween(uiScale, 0.24, { Scale = 0 }, Enum.EasingStyle.Quart)
            tw.Completed:Connect(function()
                if not isOpen then MainFrame.Visible = false end
                toggleBusy = false
            end)
        end
        
        -- Handle watermark visibility with streamer mode
        if wmVisible and streamerMode then
            local wmFrame = ScreenGui:FindFirstChild("_CatalystWatermark")
            if wmFrame then
                wmFrame.Visible = isOpen
            end
        end
        
        -- Handle keybind list visibility with streamer mode
        if streamerMode then
            kbFrame.Visible = isOpen and kbListEnabled and (#kbRows > 0)
        else
            kbRefresh()
        end
    end

    local function makePanel(titleText)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = Theme.Panel
        f.BorderSizePixel = 0
        f.ClipsDescendants = true
        f.Active = true
        f.Parent = MainFrame
        corner(f, 8)
        stroke(f, Theme.Stroke, 1, 0.35)

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 32)
        header.BackgroundColor3 = Theme.Header
        header.BorderSizePixel = 0
        header.Active = true
        header.Parent = f

        local accentLine = Instance.new("Frame")
        accentLine.Size = UDim2.new(1, 0, 0, 2)
        accentLine.BorderSizePixel = 0
        accentLine.BackgroundColor3 = Theme.Accent
        accentLine.Parent = header
        regAccent(accentLine, "BackgroundColor3")

        local grip = Instance.new("TextLabel")
        grip.BackgroundTransparency = 1
        grip.Position = UDim2.new(0, 10, 0, 0)
        grip.Size = UDim2.new(0, 16, 1, 0)
        grip.Font = Enum.Font.GothamBold
        grip.Text = "::"
        grip.TextColor3 = Theme.SubText
        grip.TextSize = 14
        grip.Parent = header

        local tl = Instance.new("TextLabel")
        tl.BackgroundTransparency = 1
        tl.Position = UDim2.new(0, 28, 0, 0)
        tl.Size = UDim2.new(1, -40, 1, 0)
        tl.Font = Enum.Font.GothamBold
        tl.Text = titleText
        tl.TextColor3 = Theme.Text
        tl.TextSize = 14
        tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.TextTruncate = Enum.TextTruncate.AtEnd
        tl.Parent = header

        local body = Instance.new("Frame")
        body.Position = UDim2.new(0, 0, 0, 32)
        body.Size = UDim2.new(1, 0, 1, -32)
        body.BackgroundTransparency = 1
        body.Parent = f

        return { frame = f, header = header, body = body, title = tl }
    end

    local tabsPanel     = makePanel("MENU")
    local contentPanel  = makePanel(Title)
    local settingsPanel = makePanel("SETTINGS")

    local currentTabApi
    local searchBox

    do
        contentPanel.title.Size = UDim2.new(1, -210, 0, 18)
        contentPanel.title.Position = UDim2.new(0, 28, 0, 4)
        local sub = Instance.new("TextLabel")
        sub.BackgroundTransparency = 1
        sub.Position = UDim2.new(0, 28, 0, 17)
        sub.Size = UDim2.new(1, -210, 0, 12)
        sub.Font = Enum.Font.Gotham
        sub.Text = SubTitle
        sub.TextColor3 = Theme.SubText
        sub.TextSize = 11
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextTruncate = Enum.TextTruncate.AtEnd
        sub.Parent = contentPanel.header

        local searchFrame = Instance.new("Frame")
        searchFrame.AnchorPoint = Vector2.new(1, 0.5)
        searchFrame.Position = UDim2.new(1, -10, 0.5, 0)
        searchFrame.Size = UDim2.new(0, 176, 0, 24)
        searchFrame.BackgroundColor3 = Theme.Element
        searchFrame.BorderSizePixel = 0
        searchFrame.Parent = contentPanel.header
        corner(searchFrame, 5)
        local searchStroke = stroke(searchFrame, Theme.Stroke, 1, 0)

        local searchDot = Instance.new("Frame")
        searchDot.AnchorPoint = Vector2.new(0, 0.5)
        searchDot.Position = UDim2.new(0, 9, 0.5, -1)
        searchDot.Size = UDim2.new(0, 8, 0, 8)
        searchDot.BackgroundTransparency = 1
        searchDot.BorderSizePixel = 0
        searchDot.Parent = searchFrame
        corner(searchDot, 4)
        local searchRing = stroke(searchDot, Theme.SubText, 1.4, 0)

        local searchHandle = Instance.new("Frame")
        searchHandle.AnchorPoint = Vector2.new(0.5, 0.5)
        searchHandle.Position = UDim2.new(1, 1, 1, 1)
        searchHandle.Size = UDim2.new(0, 4, 0, 1.4)
        searchHandle.Rotation = 45
        searchHandle.BackgroundColor3 = Theme.SubText
        searchHandle.BorderSizePixel = 0
        searchHandle.Parent = searchDot

        searchBox = Instance.new("TextBox")
        searchBox.BackgroundTransparency = 1
        searchBox.Position = UDim2.new(0, 24, 0, 0)
        searchBox.Size = UDim2.new(1, -32, 1, 0)
        searchBox.Font = Enum.Font.Gotham
        searchBox.PlaceholderText = "Search this tab..."
        searchBox.Text = ""
        searchBox.TextColor3 = Theme.Text
        searchBox.PlaceholderColor3 = Theme.SubText
        searchBox.TextSize = 12
        searchBox.ClearTextOnFocus = false
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        searchBox.TextTruncate = Enum.TextTruncate.AtEnd
        searchBox.Parent = searchFrame

        searchBox.Focused:Connect(function()
            tween(searchStroke, 0.15, { Color = Theme.Accent })
        end)
        searchBox.FocusLost:Connect(function()
            tween(searchStroke, 0.15, { Color = Theme.Stroke })
        end)
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            if currentTabApi and currentTabApi.__search then
                currentTabApi.__search(searchBox.Text)
            end
        end)

        onTheme(function()
            searchFrame.BackgroundColor3 = Theme.Element
            searchBox.TextColor3 = Theme.Text
            searchBox.PlaceholderColor3 = Theme.SubText
            searchRing.Color = Theme.SubText
            searchHandle.BackgroundColor3 = Theme.SubText
            searchStroke.Color = Theme.Stroke
        end)
    end

    local panels = {
        Tabs     = { panel = tabsPanel,     edge = "Left",  order = 1 },
        Settings = { panel = settingsPanel, edge = "Right", order = 1 },
    }

    local function getLayout()
        return {
            tabsEdge      = panels.Tabs.edge,
            tabsOrder     = panels.Tabs.order,
            settingsEdge  = panels.Settings.edge,
            settingsOrder = panels.Settings.order,
        }
    end

    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Size = UDim2.new(1, 0, 1, 0)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 3
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.Parent = tabsPanel.body
    regAccent(tabScroll, "ScrollBarImageColor3")
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabScroll
    pad(tabScroll, 6)

    local tabs = {}

    local function refreshTabList()
        local horiz = (panels.Tabs.edge == "Top" or panels.Tabs.edge == "Bottom")
        tabLayout.FillDirection = horiz and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
        for _, t in ipairs(tabs) do
            if horiz then
                t.btn.Size = UDim2.new(0, 130, 1, -12)
                t.indicator.Size = UDim2.new(1, -8, 0, 3)
                t.indicator.Position = UDim2.new(0, 4, 1, -3)
            else
                t.btn.Size = UDim2.new(1, 0, 0, 36)
                t.indicator.Size = UDim2.new(0, 3, 1, -12)
                t.indicator.Position = UDim2.new(0, 0, 0, 6)
            end
        end
        if horiz then
            tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
            tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
        else
            tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            tabScroll.ScrollingDirection = Enum.ScrollingDirection.Y
        end
    end

    local function placeFrame(f, x, y, w, h, animated)
        local posU  = UDim2.fromOffset(math.floor(x), math.floor(y))
        local sizeU = UDim2.fromOffset(math.floor(w), math.floor(h))
        if animated then
            tween(f, 0.28, { Position = posU, Size = sizeU }, Enum.EasingStyle.Quart)
        else
            f.Position, f.Size = posU, sizeU
        end
    end

    local function relayout(animated)
        local rect = { x = PAD, y = PAD, w = WIN_W - 2 * PAD, h = WIN_H - 2 * PAD }
        local byEdge = { Left = {}, Right = {}, Top = {}, Bottom = {} }
        for _, p in pairs(panels) do table.insert(byEdge[p.edge], p) end
        for _, arr in pairs(byEdge) do
            table.sort(arr, function(a, b) return a.order < b.order end)
        end
        if #byEdge.Left > 0 then
            local arr = byEdge.Left
            local each = (rect.h - GAP * (#arr - 1)) / #arr
            local cy = rect.y
            for _, pp in ipairs(arr) do
                placeFrame(pp.panel.frame, rect.x, cy, SIDE_W, each, animated)
                cy = cy + each + GAP
            end
            rect.x = rect.x + SIDE_W + GAP
            rect.w = rect.w - SIDE_W - GAP
        end
        if #byEdge.Right > 0 then
            local arr = byEdge.Right
            local each = (rect.h - GAP * (#arr - 1)) / #arr
            local cy = rect.y
            for _, pp in ipairs(arr) do
                placeFrame(pp.panel.frame, rect.x + rect.w - SIDE_W, cy, SIDE_W, each, animated)
                cy = cy + each + GAP
            end
            rect.w = rect.w - SIDE_W - GAP
        end
        if #byEdge.Top > 0 then
            local arr = byEdge.Top
            local each = (rect.w - GAP * (#arr - 1)) / #arr
            local cx = rect.x
            for _, pp in ipairs(arr) do
                placeFrame(pp.panel.frame, cx, rect.y, each, SIDE_H, animated)
                cx = cx + each + GAP
            end
            rect.y = rect.y + SIDE_H + GAP
            rect.h = rect.h - SIDE_H - GAP
        end
        if #byEdge.Bottom > 0 then
            local arr = byEdge.Bottom
            local each = (rect.w - GAP * (#arr - 1)) / #arr
            local cx = rect.x
            for _, pp in ipairs(arr) do
                placeFrame(pp.panel.frame, cx, rect.y + rect.h - SIDE_H, each, SIDE_H, animated)
                cx = cx + each + GAP
            end
            rect.h = rect.h - SIDE_H - GAP
        end
        placeFrame(contentPanel.frame, rect.x, rect.y, rect.w, rect.h, animated)
        refreshTabList()
    end

    local function applyLayout(L)
        if type(L) ~= "table" then return end
        if L.tabsEdge      then panels.Tabs.edge      = L.tabsEdge end
        if L.tabsOrder     then panels.Tabs.order     = L.tabsOrder end
        if L.settingsEdge  then panels.Settings.edge  = L.settingsEdge end
        if L.settingsOrder then panels.Settings.order = L.settingsOrder end
        relayout(true)
        _Catalyst.Flags["_layout"] = getLayout()
    end
    _Catalyst.Config["_layout"] = {
        Get     = function() return getLayout() end,
        Set     = function(v) applyLayout(v) end,
        Default = getLayout(),
    }
    _Catalyst.Flags["_layout"] = getLayout()

    local zoneFrames = {}

    local function makeZoneFrame()
        local z = Instance.new("Frame")
        z.BackgroundColor3 = Theme.Header
        z.BackgroundTransparency = 0.15
        z.BorderSizePixel = 0
        z.Visible = false
        z.ZIndex = 30
        z.Parent = MainFrame
        corner(z, 8)
        local s = stroke(z, Theme.Accent, 2, 0)
        regAccent(s, "Color")
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.Font = Enum.Font.GothamBold
        lbl.Text = "DOCK HERE"
        lbl.TextColor3 = Theme.Accent
        lbl.TextSize = 12
        lbl.ZIndex = 31
        lbl.Parent = z
        regAccent(lbl, "TextColor3")
        return { frame = z, label = lbl }
    end

    local function ensureZoneFrames(needed)
        while #zoneFrames < needed do
            zoneFrames[#zoneFrames + 1] = makeZoneFrame()
        end
        for i = needed + 1, #zoneFrames do
            zoneFrames[i].frame.Visible = false
        end
    end

    local function hideAllZones()
        for _, zf in ipairs(zoneFrames) do
            zf.frame.Visible = false
        end
    end

    local function showZonesForEdge(edge, draggingKey)
        local tempPanels = {}
        for k, p in pairs(panels) do
            if k ~= draggingKey then tempPanels[k] = p end
        end

        local byEdge = { Left = {}, Right = {}, Top = {}, Bottom = {} }
        for _, p in pairs(tempPanels) do table.insert(byEdge[p.edge], p) end
        for _, arr in pairs(byEdge) do
            table.sort(arr, function(a, b) return a.order < b.order end)
        end

        local rect = { x = PAD, y = PAD, w = WIN_W - 2 * PAD, h = WIN_H - 2 * PAD }
        local leftW   = (#byEdge.Left  > 0) and SIDE_W or 0
        local rightW  = (#byEdge.Right > 0) and SIDE_W or 0
        local innerX  = rect.x + (leftW  > 0 and leftW  + GAP or 0)
        local innerW  = rect.w - (leftW  > 0 and leftW  + GAP or 0) - (rightW > 0 and rightW + GAP or 0)

        local slots = {}
        local isVertical = (edge == "Left" or edge == "Right")
        local count = #byEdge[edge]

        if isVertical then
            local each = (rect.h - GAP * count) / (count + 1)
            for i = 1, count + 1 do
                local slotY = rect.y + (i - 1) * (each + GAP)
                local zx = (edge == "Left") and rect.x or (rect.x + rect.w - SIDE_W)
                slots[#slots + 1] = { x = zx, y = slotY, w = SIDE_W, h = each }
            end
        else
            local each = (innerW - GAP * count) / (count + 1)
            for i = 1, count + 1 do
                local slotX = innerX + (i - 1) * (each + GAP)
                local zy = (edge == "Top") and rect.y or (rect.y + rect.h - SIDE_H)
                slots[#slots + 1] = { x = slotX, y = zy, w = each, h = SIDE_H }
            end
        end

        ensureZoneFrames(#slots)
        for i, sl in ipairs(slots) do
            local zf = zoneFrames[i]
            zf.frame.Position = UDim2.fromOffset(math.floor(sl.x), math.floor(sl.y))
            zf.frame.Size = UDim2.fromOffset(math.floor(sl.w), math.floor(sl.h))
            zf.frame.Visible = true
        end
    end

    local function nearestEdge(cursor)
        local mp, ms = MainFrame.AbsolutePosition, MainFrame.AbsoluteSize
        local rx = math.clamp((cursor.X - mp.X) / math.max(ms.X, 1), 0, 1)
        local ry = math.clamp((cursor.Y - mp.Y) / math.max(ms.Y, 1), 0, 1)
        local d = { Left = rx, Right = 1 - rx, Top = ry, Bottom = 1 - ry }
        local best, bestV = "Left", math.huge
        for e, vv in pairs(d) do
            if vv < bestV then best, bestV = e, vv end
        end
        local axisVal = (best == "Left" or best == "Right") and ry or rx
        return best, axisVal
    end

    local function cursorOverPanels(pos)
        local list = { tabsPanel.frame, contentPanel.frame, settingsPanel.frame }
        for _, f in ipairs(list) do
            local ap, as = f.AbsolutePosition, f.AbsoluteSize
            if pos.X >= ap.X and pos.X <= ap.X + as.X
            and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y then
                return true
            end
        end
        return false
    end

    do
        local dragging, startInput, startPos = false, nil, nil
        MainFrame.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                if cursorOverPanels(i.Position) then return end
                dragging, startInput, startPos = true, i.Position, MainFrame.Position
            end
        end)
        MainFrame.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if not alive() then return end
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
                local delta = i.Position - startInput
                MainFrame.Position = UDim2.new(
                    startPos.X.Scale, snap(startPos.X.Offset + delta.X),
                    startPos.Y.Scale, snap(startPos.Y.Offset + delta.Y)
                )
            end
        end)
    end

    do
        local dragging, startInput, startPos = false, nil, nil
        contentPanel.header.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging, startInput, startPos = true, i.Position, MainFrame.Position
            end
        end)
        contentPanel.header.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if not alive() then return end
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
                local delta = i.Position - startInput
                MainFrame.Position = UDim2.new(
                    startPos.X.Scale, snap(startPos.X.Offset + delta.X),
                    startPos.Y.Scale, snap(startPos.Y.Offset + delta.Y)
                )
            end
        end)
    end

    local function makePanelDrag(key)
        local pData = panels[key]
        local handle = pData.panel.header
        local dragging, startInput, startPos = false, nil, nil
        local lastCursor = Vector2.new()
        local lastEdge = nil

        handle.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                startInput = i.Position
                startPos = pData.panel.frame.Position
                pData.panel.frame.ZIndex = 20
                lastEdge = nil
            end
        end)
        handle.InputEnded:Connect(function(i)
            if not dragging then return end
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                pData.panel.frame.ZIndex = 1
                hideAllZones()
                local edge, axisVal = nearestEdge(lastCursor)
                local other
                for k, v in pairs(panels) do if k ~= key then other = v end end
                pData.edge = edge
                if other and other.edge == edge then
                    if axisVal < 0.5 then pData.order, other.order = 1, 2
                    else pData.order, other.order = 2, 1 end
                else
                    pData.order = 1
                end
                relayout(true)
                _Catalyst.Flags["_layout"] = getLayout()
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if not alive() then return end
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
                lastCursor = Vector2.new(i.Position.X, i.Position.Y)
                local delta = i.Position - startInput
                pData.panel.frame.Position = UDim2.new(
                    0, snap(startPos.X.Offset + delta.X),
                    0, snap(startPos.Y.Offset + delta.Y)
                )
                local edge = nearestEdge(lastCursor)
                if edge ~= lastEdge then
                    lastEdge = edge
                    hideAllZones()
                    showZonesForEdge(edge, key)
                end
            end
        end)
    end
    makePanelDrag("Tabs")
    makePanelDrag("Settings")

    local PLAYER_NAME = LocalPlayer.DisplayName or LocalPlayer.Name
    local DEFAULT_HEADSHOT = "rbxthumb://type=AvatarHeadShot&id="
        .. tostring(LocalPlayer.UserId) .. "&w=60&h=60"

    local function resolveImage(str)
        if not str or str == "" then
            return DEFAULT_HEADSHOT
        end
        local num = tonumber(str)
        if num then
            return "rbxassetid://" .. tostring(math.floor(num))
        end
        return str
    end

    local function getClientId()
        local id
        pcall(function()
            id = game:GetService("RbxAnalyticsService"):GetClientId()
        end)
        return tostring(id or "unknown")
    end

    local WM_DEFAULT_POS = UDim2.new(0, 14, 1, -68)
    local WM_DEFAULT_SCALE = 1

    local wmScale = WM_DEFAULT_SCALE
    local wmBaseW, wmBaseH = 300, 54

    local wmFrame = Instance.new("Frame")
    wmFrame.Name = "_CatalystWatermark"
    wmFrame.AnchorPoint = Vector2.new(0, 0)
    wmFrame.Size = UDim2.fromOffset(wmBaseW, wmBaseH)
    wmFrame.Position = WM_DEFAULT_POS
    wmFrame.BackgroundColor3 = Theme.Panel
    wmFrame.BorderSizePixel = 0
    wmFrame.Active = true
    wmFrame.Visible = true
    wmFrame.ZIndex = 100
    wmFrame.Parent = ScreenGui
    corner(wmFrame, 8)
    local wmStroke = stroke(wmFrame, Theme.Stroke, 1, 0.4)

    local wmUIScale = Instance.new("UIScale")
    wmUIScale.Scale = wmScale
    wmUIScale.Parent = wmFrame

    local wmImage = Instance.new("ImageLabel")
    wmImage.AnchorPoint = Vector2.new(0, 0.5)
    wmImage.Position = UDim2.new(0, 8, 0.5, 0)
    wmImage.Size = UDim2.new(0, 38, 0, 38)
    wmImage.BackgroundColor3 = Theme.Element
    wmImage.BorderSizePixel = 0
    wmImage.Image = DEFAULT_HEADSHOT
    wmImage.ScaleType = Enum.ScaleType.Crop
    wmImage.ZIndex = 101
    wmImage.Parent = wmFrame
    corner(wmImage, 8)
    local wmImgStroke = stroke(wmImage, Theme.Accent, 1.5, 0)
    regAccent(wmImgStroke, "Color")

    local wmLabel = Instance.new("TextLabel")
    wmLabel.BackgroundTransparency = 1
    wmLabel.Position = UDim2.new(0, 54, 0, 7)
    wmLabel.Size = UDim2.new(1, -62, 0, 18)
    wmLabel.Font = Enum.Font.GothamBold
    wmLabel.Text = PLAYER_NAME
    wmLabel.TextColor3 = Theme.Text
    wmLabel.TextSize = 13
    wmLabel.TextXAlignment = Enum.TextXAlignment.Left
    wmLabel.TextTruncate = Enum.TextTruncate.AtEnd
    wmLabel.ZIndex = 101
    wmLabel.Parent = wmFrame

    local wmSub = Instance.new("TextLabel")
    wmSub.BackgroundTransparency = 1
    wmSub.Position = UDim2.new(0, 54, 0, 28)
    wmSub.Size = UDim2.new(1, -62, 0, 16)
    wmSub.Font = Enum.Font.Gotham
    wmSub.Text = ""
    wmSub.TextColor3 = Theme.SubText
    wmSub.TextSize = 10
    wmSub.TextXAlignment = Enum.TextXAlignment.Left
    wmSub.TextTruncate = Enum.TextTruncate.AtEnd
    wmSub.ZIndex = 101
    wmSub.Parent = wmFrame

    onTheme(function()
        wmFrame.BackgroundColor3 = Theme.Panel
        wmLabel.TextColor3 = Theme.Text
        wmSub.TextColor3 = Theme.SubText
        wmImage.BackgroundColor3 = Theme.Element
    end)

    local function applyWmScale(s)
        wmScale = s
        wmUIScale.Scale = s
    end

    local function setWatermarkName(t)
        if t and t ~= "" then
            wmLabel.Text = t
        else
            wmLabel.Text = PLAYER_NAME
        end
    end
    local function setWatermarkImage(t)
        wmImage.Image = resolveImage(t)
    end
    local function setWatermarkVisible(v)
        wmVisible = v and true or false
        if not wmVisible then
            wmFrame.Visible = false
        else
            if streamerMode then
                wmFrame.Visible = isOpen
            else
                wmFrame.Visible = true
            end
        end
    end

    local wmDragging, wmStartInput, wmStartPos = false, nil, nil
    wmFrame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            wmDragging = true
            wmStartInput = i.Position
            wmStartPos = wmFrame.Position
        end
    end)
    wmFrame.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            wmDragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not alive() then return end
        if wmDragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - wmStartInput
            wmFrame.Position = UDim2.new(
                wmStartPos.X.Scale, wmStartPos.X.Offset + delta.X,
                wmStartPos.Y.Scale, wmStartPos.Y.Offset + delta.Y
            )
            _Catalyst.Flags["_wmpos"] = {
                sx = wmFrame.Position.X.Scale,
                ox = wmFrame.Position.X.Offset,
                sy = wmFrame.Position.Y.Scale,
                oy = wmFrame.Position.Y.Offset,
            }
        end
    end)

    taskLib.spawn(function()
        while alive() do
            local t = os.date("*t")
            local dateStr = string.format("%02d/%02d/%04d %02d:%02d:%02d",
                t.month, t.day, t.year, t.hour, t.min, t.sec)
            wmSub.Text = getClientId():sub(1, 8) .. "  |  " .. dateStr
            taskLib.wait(1)
        end
    end)

    -- Keybind List (ported from Nexonix)
    local kbListEnabled = true
    local kbRows = {}

    local kbFrame = Instance.new("Frame")
    kbFrame.Name = "_CatalystKeybinds"
    kbFrame.AnchorPoint = Vector2.new(0, 0.5)
    kbFrame.Position = UDim2.new(0, 14, 0.5, 0)
    kbFrame.Size = UDim2.new(0, 210, 0, 30)
    kbFrame.AutomaticSize = Enum.AutomaticSize.Y
    kbFrame.BackgroundColor3 = Theme.Panel
    kbFrame.BorderSizePixel = 0
    kbFrame.Active = true
    kbFrame.Visible = false
    kbFrame.ZIndex = 100
    kbFrame.Parent = ScreenGui
    corner(kbFrame, 8)
    local kbStroke = stroke(kbFrame, Theme.Stroke, 1, 0.4)

    local kbHeader = Instance.new("Frame")
    kbHeader.Size = UDim2.new(1, 0, 0, 30)
    kbHeader.BackgroundColor3 = Theme.Header
    kbHeader.BorderSizePixel = 0
    kbHeader.ClipsDescendants = true
    kbHeader.ZIndex = 101
    kbHeader.Parent = kbFrame
    corner(kbHeader, 8)

    local kbHeaderFix = Instance.new("Frame")
    kbHeaderFix.Size = UDim2.new(1, 0, 0, 8)
    kbHeaderFix.Position = UDim2.new(0, 0, 1, -8)
    kbHeaderFix.BackgroundColor3 = Theme.Header
    kbHeaderFix.BorderSizePixel = 0
    kbHeaderFix.ZIndex = 101
    kbHeaderFix.Parent = kbHeader

    local kbAccent = Instance.new("Frame")
    kbAccent.Size = UDim2.new(1, -16, 0, 2)
    kbAccent.Position = UDim2.new(0, 8, 0, 0)
    kbAccent.BackgroundColor3 = Theme.Accent
    kbAccent.BorderSizePixel = 0
    kbAccent.ZIndex = 102
    kbAccent.Parent = kbHeader
    regAccent(kbAccent, "BackgroundColor3")

    local kbTitle = Instance.new("TextLabel")
    kbTitle.BackgroundTransparency = 1
    kbTitle.Position = UDim2.new(0, 12, 0, 0)
    kbTitle.Size = UDim2.new(1, -24, 1, 0)
    kbTitle.Font = Enum.Font.GothamBold
    kbTitle.Text = "KEYBINDS"
    kbTitle.TextColor3 = Theme.Text
    kbTitle.TextSize = 12
    kbTitle.TextXAlignment = Enum.TextXAlignment.Left
    kbTitle.ZIndex = 102
    kbTitle.Parent = kbHeader

    local kbBody = Instance.new("Frame")
    kbBody.Position = UDim2.new(0, 0, 0, 30)
    kbBody.Size = UDim2.new(1, 0, 0, 0)
    kbBody.AutomaticSize = Enum.AutomaticSize.Y
    kbBody.BackgroundTransparency = 1
    kbBody.ZIndex = 101
    kbBody.Parent = kbFrame

    local kbList = Instance.new("UIListLayout")
    kbList.SortOrder = Enum.SortOrder.LayoutOrder
    kbList.Padding = UDim.new(0, 4)
    kbList.Parent = kbBody

    local kbPad = Instance.new("UIPadding")
    kbPad.PaddingTop = UDim.new(0, 8)
    kbPad.PaddingBottom = UDim.new(0, 10)
    kbPad.PaddingLeft = UDim.new(0, 12)
    kbPad.PaddingRight = UDim.new(0, 12)
    kbPad.Parent = kbBody

    onTheme(function()
        kbFrame.BackgroundColor3 = Theme.Panel
        kbHeader.BackgroundColor3 = Theme.Header
        kbHeaderFix.BackgroundColor3 = Theme.Header
        kbTitle.TextColor3 = Theme.Text
        kbStroke.Color = Theme.Stroke
    end)

    local KB_DEFAULT_POS = UDim2.new(0, 14, 0.5, 0)

    do
        local dragging, si, sp = false, nil, nil
        kbFrame.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging, si, sp = true, i.Position, kbFrame.Position
            end
        end)
        kbFrame.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                _Catalyst.Flags["_kbpos"] = {
                    sx = kbFrame.Position.X.Scale,
                    ox = kbFrame.Position.X.Offset,
                    sy = kbFrame.Position.Y.Scale,
                    oy = kbFrame.Position.Y.Offset,
                }
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if not alive() then return end
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - si
                kbFrame.Position = UDim2.new(
                    sp.X.Scale, sp.X.Offset + d.X,
                    sp.Y.Scale, sp.Y.Offset + d.Y
                )
            end
        end)
    end

        _Catalyst.Config["_kbpos"] = {
        Get = function()
            return {
                sx = kbFrame.Position.X.Scale,
                ox = kbFrame.Position.X.Offset,
                sy = kbFrame.Position.Y.Scale,
                oy = kbFrame.Position.Y.Offset,
            }
        end,
        Set = function(v)
            if type(v) == "table" and v.sx ~= nil then
                kbFrame.Position = UDim2.new(v.sx, v.ox, v.sy, v.oy)
            end
        end,
        Default = {
            sx = KB_DEFAULT_POS.X.Scale,
            ox = KB_DEFAULT_POS.X.Offset,
            sy = KB_DEFAULT_POS.Y.Scale,
            oy = KB_DEFAULT_POS.Y.Offset,
        },
    }
    _Catalyst.Flags["_kbpos"] = _Catalyst.Config["_kbpos"].Default

    local function kbRefresh()
        local shouldShow = kbListEnabled and (#kbRows > 0)
        if not shouldShow then
            kbFrame.Visible = false
            return
        end
        if streamerMode then
            kbFrame.Visible = isOpen
        else
            kbFrame.Visible = true
        end
    end

    local function keybindAdd(name, key)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 22)
        row.BackgroundTransparency = 1
        row.ZIndex = 101
        row.Parent = kbBody

        local dot = Instance.new("Frame")
        dot.AnchorPoint = Vector2.new(0, 0.5)
        dot.Position = UDim2.new(0, 0, 0.5, 0)
        dot.Size = UDim2.new(0, 7, 0, 7)
        dot.BackgroundColor3 = Theme.SubText
        dot.BorderSizePixel = 0
        dot.ZIndex = 102
        dot.Parent = row
        corner(dot, 4)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.BackgroundTransparency = 1
        nameLbl.Position = UDim2.new(0, 16, 0, 0)
        nameLbl.Size = UDim2.new(1, -86, 1, 0)
        nameLbl.Font = Enum.Font.GothamMedium
        nameLbl.Text = tostring(name)
        nameLbl.TextColor3 = Theme.SubText
        nameLbl.TextSize = 12
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.ZIndex = 102
        nameLbl.Parent = row

        local keyLbl = Instance.new("TextLabel")
        keyLbl.BackgroundTransparency = 1
        keyLbl.AnchorPoint = Vector2.new(1, 0.5)
        keyLbl.Position = UDim2.new(1, 0, 0.5, 0)
        keyLbl.Size = UDim2.new(0, 66, 1, 0)
        keyLbl.Font = Enum.Font.GothamBold
        keyLbl.Text = keyNameOf(key)
        keyLbl.TextColor3 = Theme.SubText
        keyLbl.TextSize = 12
        keyLbl.TextXAlignment = Enum.TextXAlignment.Right
        keyLbl.TextTruncate = Enum.TextTruncate.AtEnd
        keyLbl.ZIndex = 102
        keyLbl.Parent = row

        kbRows[#kbRows + 1] = row

        local entry = { active = false }
        function entry:SetActive(on)
            entry.active = on and true or false
            tween(dot, 0.15, { BackgroundColor3 = entry.active and Theme.Accent or Theme.SubText })
            tween(nameLbl, 0.15, { TextColor3 = entry.active and Theme.Text or Theme.SubText })
            tween(keyLbl, 0.15, { TextColor3 = entry.active and Theme.Text or Theme.SubText })
        end
        function entry:SetKey(k) keyLbl.Text = keyNameOf(k) end
        function entry:SetName(n) nameLbl.Text = tostring(n) end
        function entry:Remove()
            for i, r in ipairs(kbRows) do
                if r == row then table.remove(kbRows, i) break end
            end
            row:Destroy()
            kbRefresh()
        end

        onAccent(function(c)
            if entry.active then dot.BackgroundColor3 = c end
        end)
        onTheme(function()
            dot.BackgroundColor3 = entry.active and Theme.Accent or Theme.SubText
            nameLbl.TextColor3 = entry.active and Theme.Text or Theme.SubText
            keyLbl.TextColor3 = entry.active and Theme.Text or Theme.SubText
        end)

        kbRefresh()
        return entry
    end
    _Catalyst.__kbAdd = keybindAdd

    local function setKeybindListVisible(v)
        kbListEnabled = v and true or false
        kbRefresh()
    end

    local firstTab = true
    function Window:Tab(name, icon)
        local container = Instance.new("ScrollingFrame")
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.BorderSizePixel = 0
        container.ScrollBarThickness = 4
        container.CanvasSize = UDim2.new(0, 0, 0, 0)
        container.Visible = false
        container.Parent = contentPanel.body
        regAccent(container, "ScrollBarImageColor3")

        local capi = makeAPI(container)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = Theme.Element
        btn.BackgroundTransparency = 1
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.Parent = tabScroll
        corner(btn, 6)

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 3, 1, -12)
        indicator.Position = UDim2.new(0, 0, 0, 6)
        indicator.BorderSizePixel = 0
        indicator.BackgroundTransparency = 1
        indicator.BackgroundColor3 = Theme.Accent
        indicator.Parent = btn
        corner(indicator, 2)
        regAccent(indicator, "BackgroundColor3")

        local ic
        if icon then
            ic = Instance.new("ImageLabel")
            ic.BackgroundTransparency = 1
            ic.Position = UDim2.new(0, 12, 0.5, -9)
            ic.Size = UDim2.new(0, 18, 0, 18)
            ic.Image = icon
            ic.ImageColor3 = Theme.SubText
            ic.Parent = btn
        end

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, icon and 38 or 14, 0, 0)
        lbl.Size = UDim2.new(1, icon and -46 or -22, 1, 0)
        lbl.Font = Enum.Font.GothamMedium
        lbl.Text = name
        lbl.TextColor3 = Theme.SubText
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = btn

        local entry = { container = container, btn = btn, lbl = lbl, indicator = indicator, icon = ic, capi = capi }

        local function activate()
            for _, t in ipairs(tabs) do
                t.container.Visible = false
                tween(t.btn, 0.18, { BackgroundTransparency = 1 })
                tween(t.lbl, 0.18, { TextColor3 = Theme.SubText })
                tween(t.indicator, 0.18, { BackgroundTransparency = 1 })
                if t.icon then tween(t.icon, 0.18, { ImageColor3 = Theme.SubText }) end
                if t.capi and t.capi.__search then t.capi.__search("") end
            end
            container.Visible = true
            tween(btn, 0.18, { BackgroundTransparency = 0 })
            tween(lbl, 0.18, { TextColor3 = Theme.Text })
            tween(indicator, 0.18, { BackgroundTransparency = 0 })
            if ic then tween(ic, 0.18, { ImageColor3 = Theme.Accent }) end
            currentTabApi = capi
            if searchBox then searchBox.Text = "" end
        end
        entry.activate = activate
        onAccent(function(c)
            if ic and container.Visible then ic.ImageColor3 = c end
            if container.Visible then
                indicator.BackgroundColor3 = c
            end
        end)
        onTheme(function()
            btn.BackgroundColor3 = Theme.Element
            if container.Visible then
                lbl.TextColor3 = Theme.Text
                if ic then ic.ImageColor3 = Theme.Accent end
                indicator.BackgroundColor3 = Theme.Accent
                indicator.BackgroundTransparency = 0
            else
                lbl.TextColor3 = Theme.SubText
                if ic then ic.ImageColor3 = Theme.SubText end
                indicator.BackgroundTransparency = 1
            end
        end)
        btn.MouseButton1Click:Connect(activate)
        btn.MouseEnter:Connect(function()
            if not container.Visible then tween(btn, 0.12, { BackgroundTransparency = 0.6 }) end
        end)
        btn.MouseLeave:Connect(function()
            if not container.Visible then tween(btn, 0.12, { BackgroundTransparency = 1 }) end
        end)

        table.insert(tabs, entry)
        refreshTabList()
        if firstTab then firstTab = false activate() end
        return capi
    end

    local notifyHolder = Instance.new("Frame")
    notifyHolder.AnchorPoint = Vector2.new(1, 1)
    notifyHolder.Position = UDim2.new(1, -16, 1, -16)
    notifyHolder.Size = UDim2.new(0, 290, 1, -32)
    notifyHolder.BackgroundTransparency = 1
    notifyHolder.Parent = ScreenGui
    local nLayout = Instance.new("UIListLayout")
    nLayout.SortOrder = Enum.SortOrder.LayoutOrder
    nLayout.Padding = UDim.new(0, 8)
    nLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    nLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    nLayout.Parent = notifyHolder

    -- Notification (ported from Nexonix: live countdown + draining progress bar)
    function Window:Notify(title, desc, duration, color)
        duration = tonumber(duration) or 4
        color = color or Theme.Accent
        local hasDesc = desc ~= nil and desc ~= ""
        local H = hasDesc and 84 or 50

        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, 0, 0, H)
        card.BackgroundColor3 = Theme.Panel
        card.BackgroundTransparency = 1
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.Parent = notifyHolder
        corner(card, 8)
        local st = stroke(card, Theme.Stroke, 1, 1)

        local titleLbl = Instance.new("TextLabel")
        titleLbl.BackgroundTransparency = 1
        titleLbl.Position = UDim2.new(0, 14, 0, 10)
        titleLbl.Size = UDim2.new(1, -64, 0, 18)
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.Text = title or "Notice"
        titleLbl.TextColor3 = Theme.Text
        titleLbl.TextTransparency = 1
        titleLbl.TextSize = 14
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
        titleLbl.Parent = card

        local durLbl = Instance.new("TextLabel")
        durLbl.BackgroundTransparency = 1
        durLbl.AnchorPoint = Vector2.new(1, 0)
        durLbl.Position = UDim2.new(1, -14, 0, 10)
        durLbl.Size = UDim2.new(0, 44, 0, 18)
        durLbl.Font = Enum.Font.GothamMedium
        durLbl.Text = string.format("%.1fs", duration)
        durLbl.TextColor3 = Theme.SubText
        durLbl.TextTransparency = 1
        durLbl.TextSize = 12
        durLbl.TextXAlignment = Enum.TextXAlignment.Right
        durLbl.Parent = card

        local descLbl
        if hasDesc then
            descLbl = Instance.new("TextLabel")
            descLbl.BackgroundTransparency = 1
            descLbl.Position = UDim2.new(0, 14, 0, 30)
            descLbl.Size = UDim2.new(1, -28, 0, 32)
            descLbl.Font = Enum.Font.Gotham
            descLbl.Text = desc
            descLbl.TextColor3 = Theme.SubText
            descLbl.TextTransparency = 1
            descLbl.TextSize = 12
            descLbl.TextWrapped = true
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.TextYAlignment = Enum.TextYAlignment.Top
            descLbl.TextTruncate = Enum.TextTruncate.AtEnd
            descLbl.Parent = card
        end

        local barBG = Instance.new("Frame")
        barBG.AnchorPoint = Vector2.new(0, 1)
        barBG.Position = UDim2.new(0, 14, 1, -10)
        barBG.Size = UDim2.new(1, -28, 0, 4)
        barBG.BackgroundColor3 = Theme.Element
        barBG.BackgroundTransparency = 1
        barBG.BorderSizePixel = 0
        barBG.Parent = card
        corner(barBG, 2)

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 1, 0)
        bar.BackgroundColor3 = color
        bar.BackgroundTransparency = 1
        bar.BorderSizePixel = 0
        bar.Parent = barBG
        corner(bar, 2)

        tween(card, 0.3, { Size = UDim2.new(0, 290, 0, H), BackgroundTransparency = 0 }, Enum.EasingStyle.Quart)
        tween(st, 0.3, { Transparency = 0.4 })
        tween(titleLbl, 0.3, { TextTransparency = 0 })
        tween(durLbl, 0.3, { TextTransparency = 0 })
        if descLbl then tween(descLbl, 0.3, { TextTransparency = 0.1 }) end
        tween(barBG, 0.3, { BackgroundTransparency = 0 })
        tween(bar, 0.3, { BackgroundTransparency = 0 })

        tween(bar, duration, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)

        taskLib.spawn(function()
            local remaining = duration
            while remaining > 0 and card.Parent do
                taskLib.wait(0.1)
                remaining = remaining - 0.1
                if remaining < 0 then remaining = 0 end
                if durLbl.Parent then
                    durLbl.Text = string.format("%.1fs", remaining)
                end
            end
        end)

        taskLib.spawn(function()
            taskLib.wait(duration + 0.05)
            if not card.Parent then return end
            tween(card, 0.25, { Size = UDim2.new(0, 0, 0, H), BackgroundTransparency = 1 })
            tween(st, 0.25, { Transparency = 1 })
            tween(titleLbl, 0.25, { TextTransparency = 1 })
            tween(durLbl, 0.25, { TextTransparency = 1 })
            if descLbl then tween(descLbl, 0.25, { TextTransparency = 1 }) end
            tween(barBG, 0.25, { BackgroundTransparency = 1 })
            tween(bar, 0.25, { BackgroundTransparency = 1 })
            taskLib.wait(0.3)
            card:Destroy()
        end)
    end

    local function readMeta()
        local raw = FileSystem.read(ConfigFolder .. "/_meta.json")
        if raw then
            local ok, dd = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(dd) == "table" then return dd end
        end
        return {}
    end
    local function writeMeta(patch)
        local cur = readMeta()
        for k, v in pairs(patch) do cur[k] = v end
        local ok, json = pcall(function() return HttpService:JSONEncode(cur) end)
        if ok then FileSystem.write(ConfigFolder .. "/_meta.json", json) end
    end
    local function getConfigList()
        local out = {}
        for _, full in ipairs(FileSystem.list(ConfigFolder)) do
            local n = tostring(full):match("([^/\\]+)%.json$")
            if n and n ~= "_meta" then out[#out + 1] = n end
        end
        return out
    end

    local function applyAllVisuals()
        if _Catalyst._customAccent then
            setAccent(Theme.Accent)
        else
            local tn = _Catalyst.Flags["_theme"]
            local tt = Themes[tn] or Theme
            setAccent(tt.Accent or Theme.Accent)
        end
        for _, fn in ipairs(ThemeListeners) do
            pcall(fn, Theme)
        end
        relayout(true)
    end

    function Window:SaveConfig(name)
        if not name or name == "" then return false end
        local data = {}
        for flag in pairs(_Catalyst.Config) do
            data[flag] = serialize(_Catalyst.Flags[flag])
        end
        local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
        if not ok then return false end
        FileSystem.write(ConfigFolder .. "/" .. name .. ".json", json)
        writeMeta({ recent = name })
        applyAllVisuals()
        return true
    end

    function Window:LoadConfig(name)
        if not name or name == "" then return false end
        local path = ConfigFolder .. "/" .. name .. ".json"
        if not FileSystem.exists(path) then return false end
        local raw = FileSystem.read(path)
        if not raw then return false end
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok or type(data) ~= "table" then return false end
        if data["_theme"] ~= nil and _Catalyst.Config["_theme"] then
            _Catalyst._customAccent = false
            pcall(_Catalyst.Config["_theme"].Set, deserialize(data["_theme"]))
        end
        for flag, val in pairs(data) do
            if flag ~= "_theme" and flag ~= "_accent" and flag ~= "_customaccent" then
                local c = _Catalyst.Config[flag]
                if c then pcall(c.Set, deserialize(val)) end
            end
        end
        local wantsCustom = data["_customaccent"] == true
        if wantsCustom and data["_accent"] ~= nil and _Catalyst.Config["_accent"] then
            _Catalyst._customAccent = true
            _Catalyst.Flags["_customaccent"] = true
            pcall(_Catalyst.Config["_accent"].Set, deserialize(data["_accent"]))
        else
            _Catalyst._customAccent = false
            _Catalyst.Flags["_customaccent"] = false
            local tn = _Catalyst.Flags["_theme"]
            local tt = Themes[tn] or Theme
            local themeAccent = tt.Accent or Theme.Accent
            if _Catalyst.__accentSilent then
                _Catalyst.__accentSilent(themeAccent)
            end
            _Catalyst._customAccent = false
            setAccent(themeAccent)
        end
        writeMeta({ recent = name })
        applyAllVisuals()
        return true
    end

    function Window:DeleteConfig(name)
        if not name or name == "" then return false end
        FileSystem.delete(ConfigFolder .. "/" .. name .. ".json")
        return true
    end
    function Window:GetConfigs() return getConfigList() end
    function Window:ResetDefaults()
        if _Catalyst.Config["_theme"] then
            _Catalyst._customAccent = false
            pcall(_Catalyst.Config["_theme"].Set, _Catalyst.Config["_theme"].Default)
        end
        for flag, c in pairs(_Catalyst.Config) do
            if flag ~= "_theme" and flag ~= "_accent" then
                pcall(c.Set, c.Default)
            end
        end
        if _Catalyst.Config["_accent"] then
            pcall(_Catalyst.Config["_accent"].Set, _Catalyst.Config["_accent"].Default)
        end
        applyAllVisuals()
    end

    local settingsScroll = Instance.new("ScrollingFrame")
    settingsScroll.Size = UDim2.new(1, 0, 1, 0)
    settingsScroll.BackgroundTransparency = 1
    settingsScroll.BorderSizePixel = 0
    settingsScroll.ScrollBarThickness = 4
    settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    settingsScroll.Parent = settingsPanel.body
    regAccent(settingsScroll, "ScrollBarImageColor3")
    local sApi = makeAPI(settingsScroll)

    local currentName = ""
    local cfgDrop
    local accentPicker

    sApi:Section("Configuration")
    local nameBox = sApi:Textbox("Config Name", "", false, function(t) currentName = t end)
    cfgDrop = sApi:Dropdown("Saved Configs", getConfigList(), function(v)
        currentName = v
        nameBox.Set(v)
    end)
    sApi:Button("Save Config", "Write current settings to a file", function()
        if currentName == "" then
            Window:Notify("Config", "Type a config name first.")
            return
        end
        local ok = Window:SaveConfig(currentName)
        cfgDrop.Refresh(getConfigList())
        Window:Notify("Config", ok and ("Saved '" .. currentName .. "'") or "Save failed.")
    end)
    sApi:Button("Load Config", "Apply settings from the selected file", function()
        if currentName == "" then
            Window:Notify("Config", "Select or type a config name first.")
            return
        end
        local ok = Window:LoadConfig(currentName)
        Window:Notify("Config", ok and ("Loaded '" .. currentName .. "'") or "Load failed.")
    end)
    sApi:Button("Delete Config", "Remove the selected config file", function()
        if currentName == "" then return end
        Window:DeleteConfig(currentName)
        cfgDrop.Refresh(getConfigList())
        Window:Notify("Config", "Deleted '" .. currentName .. "'")
    end)
    sApi:Button("Refresh List", "Re-scan the config folder", function()
        cfgDrop.Refresh(getConfigList())
        Window:Notify("Config", "Config list refreshed.")
    end)

    local meta0 = readMeta()
    sApi:Toggle("Auto-load Recent", "Load the last used config on launch",
        meta0.autoload ~= false, function(on)
            writeMeta({ autoload = on })
        end)
    sApi:Button("Reset to Defaults", "Restore every option to default values", function()
        Window:ResetDefaults()
        Window:Notify("Config", "All settings reset to defaults.")
    end)

    sApi:Section("Appearance")
    sApi:Dropdown("UI Theme", { "GX", "Discord", "Light" }, function(v)
        _Catalyst._customAccent = false
        _Catalyst.Flags["_customaccent"] = false
        applyTheme(v)
        if accentPicker and accentPicker.SetSilent then
            accentPicker.SetSilent(Theme.Accent)
        end
    end, "_theme", "GX")

    accentPicker = sApi:Colorpicker("Accent Color", Theme.Accent, function(c)
        _Catalyst._customAccent = true
        _Catalyst.Flags["_customaccent"] = true
        setAccent(c)
    end, "_accent")

    _Catalyst.__accentSilent = accentPicker.SetSilent

    _Catalyst.Config["_customaccent"] = {
        Get     = function() return _Catalyst._customAccent and true or false end,
        Set     = function(_) end,
        Default = false,
    }
    _Catalyst.Flags["_customaccent"] = _Catalyst._customAccent and true or false

    do
        local origSet = _Catalyst.Config["_accent"].Set
        _Catalyst.Config["_accent"].Set = function(c)
            _Catalyst._customAccent = true
            _Catalyst.Flags["_customaccent"] = true
            origSet(c)
        end
    end

    sApi:Slider("UI Scale", "Resize the whole interface", 50, 150, 100, function(v)
        userScale = v / 100
        applyScale()
    end, "_uiscale", { Suffix = " %" })
    sApi:Bind("Toggle UI Key", ToggleKey, function()
        toggleUI()
    end, "_togglekey", { NoList = true })

    sApi:Section("Keybind List")
    sApi:Toggle("Show Keybind List", "Display active keybinds on screen", true, function(on)
        setKeybindListVisible(on)
    end, "_kblist")

    sApi:Section("Watermark")
    sApi:Toggle("Show Watermark", "Display the watermark overlay", true, function(on)
        setWatermarkVisible(on)
    end, "_wmshow")
    sApi:Toggle("Streamer Mode", "Hide watermark when UI is closed", false, function(on)
        streamerMode = on
        if wmVisible then
            if streamerMode then
                wmFrame.Visible = isOpen
            else
                wmFrame.Visible = true
            end
        end
    end, "_streamermode")
    sApi:Textbox("Display Name", "Custom name shown on the watermark", false, function(t)
        setWatermarkName(t)
    end, "_wmname")
    sApi:Textbox("Avatar Image", "rbxassetid number or asset url", false, function(t)
        setWatermarkImage(t)
    end, "_wmimage")
    sApi:Slider("Watermark Scale", "Resize the watermark", 50, 200, 100, function(v)
        applyWmScale(v / 100)
    end, "_wmscale", { Suffix = " %" })

    do
        _Catalyst.Config["_wmpos"] = {
            Get = function()
                return {
                    sx = wmFrame.Position.X.Scale,
                    ox = wmFrame.Position.X.Offset,
                    sy = wmFrame.Position.Y.Scale,
                    oy = wmFrame.Position.Y.Offset,
                }
            end,
            Set = function(v)
                if type(v) == "table" and v.sx ~= nil then
                    wmFrame.Position = UDim2.new(v.sx, v.ox, v.sy, v.oy)
                end
            end,
            Default = {
                sx = WM_DEFAULT_POS.X.Scale,
                ox = WM_DEFAULT_POS.X.Offset,
                sy = WM_DEFAULT_POS.Y.Scale,
                oy = WM_DEFAULT_POS.Y.Offset,
            },
        }
        _Catalyst.Flags["_wmpos"] = _Catalyst.Config["_wmpos"].Default
    end

    sApi:Button("Reset Watermark Position", "Move watermark back to default position", function()
        wmFrame.Position = WM_DEFAULT_POS
        _Catalyst.Flags["_wmpos"] = _Catalyst.Config["_wmpos"].Default
        Window:Notify("Watermark", "Position reset.")
    end)
        sApi:Button("Reset Keybind List Position", "Move keybind list back to default position", function()
        kbFrame.Position = KB_DEFAULT_POS
        _Catalyst.Flags["_kbpos"] = _Catalyst.Config["_kbpos"].Default
        Window:Notify("Keybinds", "Position reset.")
    end)

    sApi:Section("About")
    sApi:Label("_Catalyst " .. _Catalyst.Version)
    sApi:Label(FileSystem.hasIO and "File system: available" or "File system: in-memory only")
    sApi:Label(IS_MOBILE and "Mode: mobile / touch" or "Mode: desktop")

    if IS_MOBILE then
        local fab = Instance.new("TextButton")
        fab.Size = UDim2.new(0, 48, 0, 48)
        fab.Position = UDim2.new(0, 16, 0.5, -24)
        fab.BackgroundColor3 = Theme.Panel
        fab.AutoButtonColor = false
        fab.Text = "CX"
        fab.Font = Enum.Font.GothamBold
        fab.TextColor3 = Theme.Text
        fab.TextSize = 16
        fab.Parent = ScreenGui
        corner(fab, 24)
        local ring = Instance.new("UIStroke")
        ring.Thickness = 2
        ring.Parent = fab
        regAccent(ring, "Color")

        local dragging, moved, startInput, startPos = false, false, nil, nil
        fab.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging, moved = true, false
                startInput, startPos = i.Position, fab.Position
            end
        end)
        fab.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                if not moved then toggleUI() end
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if not alive() then return end
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
                local delta = i.Position - startInput
                if delta.Magnitude > 6 then moved = true end
                fab.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    local didInit = false
    function Window:Init()
        if didInit then return end
        didInit = true
        cfgDrop.Refresh(getConfigList())
        local meta = readMeta()
        if meta.autoload ~= false and meta.recent then
            local ok = Window:LoadConfig(meta.recent)
            if ok then
                currentName = meta.recent
                nameBox.Set(meta.recent)
                Window:Notify("Config", "Auto-loaded '" .. meta.recent .. "'")
            end
        end
        applyAllVisuals()
    end
    taskLib.spawn(function()
        taskLib.wait(0.4)
        if alive() and not didInit then Window:Init() end
    end)

    Window.SetAccent           = setAccent
    Window.SetTheme            = applyTheme
    Window.Toggle              = toggleUI
    Window.Relayout            = function() relayout(true) end
    Window.SetWatermarkName    = setWatermarkName
    Window.SetWatermarkImage   = setWatermarkImage
    Window.SetWatermarkVisible = setWatermarkVisible
    Window.SetKeybindListVisible = setKeybindListVisible
    Window.RefreshVisuals      = function() applyAllVisuals() end

    relayout(false)
    computeFit()
    tween(uiScale, 0.45, { Scale = targetScale() }, Enum.EasingStyle.Quart)

    return Window
end

return _Catalyst
