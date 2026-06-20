--[[
    aero.crack UI Library
    Linoria-style interface (blocky, squared, no rounded corners)

    For use inside a Roblox game/place you own and control.
    Distributed via GitHub + loadstring(game:HttpGet(...)).

    ------------------------------------------------------------
    USAGE
    ------------------------------------------------------------
    local Library = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/<you>/<repo>/main/init.lua"
    ))()

    local Window = Library:CreateWindow({
        Title = "aero.crack",
        Logo  = "rbxassetid://8463897834", -- your decal/image id
    })

    local Tab    = Window:MakeTab("tab1")
    local Group  = Tab:MakeGroup("group name")

    Group:AddToggle("toggle", false, function(state) end)
    Group:AddButton("button", function() end)
    Group:AddSlider("slider", 0, 100, 35, function(value) end)
    ------------------------------------------------------------
--]]

local Players          = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- THEME -- flat slate/grey, square corners, thin 1px borders,
-- no gradients, no rounded corners anywhere.
----------------------------------------------------------------
local Theme = {
    Background  = Color3.fromRGB(28, 28, 32),
    Header      = Color3.fromRGB(24, 24, 27),
    Border      = Color3.fromRGB(55, 58, 68),
    GroupBg     = Color3.fromRGB(20, 20, 23),
    Accent      = Color3.fromRGB(140, 155, 210),
    ElementBg   = Color3.fromRGB(32, 32, 36),
    Text        = Color3.fromRGB(220, 220, 225),
    SubText     = Color3.fromRGB(150, 155, 170),
    White       = Color3.fromRGB(240, 240, 245),
}

local FONT      = Enum.Font.Code
local FONT_BOLD = Enum.Font.Code

local DEFAULT_TITLE = "aero.crack"
local DEFAULT_LOGO  = "rbxassetid://8463897834"
local MIN_SIZE       = Vector2.new(420, 320)

----------------------------------------------------------------
-- UTILITY
----------------------------------------------------------------
local function create(class, props, children)
    local inst = Instance.new(class)
    for prop, value in pairs(props or {}) do
        inst[prop] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

-- Instant (non-tweened) drag.
local function makeDraggable(handle, target)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Tweened drag -- smooth follow, used for the watermark.
local function makeDraggableTweened(handle, target, tweenTime)
    tweenTime = tweenTime or 0.12
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            TweenService:Create(target, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad), {
                Position = newPos
            }):Play()
        end
    end)
end

-- Corner-grip resize. Direct Size assignment (no tween), clamped to minSize.
local function makeResizable(handle, target, minSize)
    minSize = minSize or MIN_SIZE
    local resizing = false
    local dragStart, startSize

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            dragStart = input.Position
            startSize = target.Size

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newWidth  = math.max(minSize.X, startSize.X.Offset + delta.X)
            local newHeight = math.max(minSize.Y, startSize.Y.Offset + delta.Y)
            target.Size = UDim2.new(
                startSize.X.Scale, newWidth,
                startSize.Y.Scale, newHeight
            )
        end
    end)
end

----------------------------------------------------------------
-- LIBRARY
----------------------------------------------------------------
local Library = {}
Library.__index = Library

-- Internal: builds the ScreenGui + watermark + notification stack.
-- Shared across all windows created from this loaded copy of the library.
local ScreenGui = create("ScreenGui", {
    Name = "AeroCrackUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100,
})
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = PlayerGui
end

local NotifHolder = create("Frame", {
    Name = "Notifications",
    Size = UDim2.new(0, 300, 1, -40),
    Position = UDim2.new(1, -320, 0, 20),
    BackgroundTransparency = 1,
    Parent = ScreenGui,
})
create("UIListLayout", {
    Padding = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = NotifHolder,
})

function Library:Notify(text, duration)
    duration = duration or 3

    local notif = create("Frame", {
        Size = UDim2.new(0, 260, 0, 36),
        BackgroundColor3 = Theme.Header,
        BorderSizePixel = 1,
        BorderColor3 = Theme.Border,
        ClipsDescendants = true,
        Parent = NotifHolder,
    })

    local label = create("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        Font = FONT,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    notif.Position = UDim2.new(1, 50, 0, 0)
    notif.BackgroundTransparency = 1
    label.TextTransparency = 1

    TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0,
    }):Play()
    TweenService:Create(label, TweenInfo.new(0.25), {TextTransparency = 0}):Play()

    task.delay(duration, function()
        local exitTween = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 200, 0, 0),
            BackgroundTransparency = 1,
        })
        TweenService:Create(label, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
        exitTween:Play()
        exitTween.Completed:Connect(function()
            notif:Destroy()
        end)
    end)
end

----------------------------------------------------------------
-- Library:CreateWindow({ Title = "...", Logo = "rbxassetid://..." })
----------------------------------------------------------------
function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or DEFAULT_TITLE
    local logoId = config.Logo or DEFAULT_LOGO
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift

    -- Watermark, scoped per window, labeled with the window title.
    local Watermark = create("Frame", {
        Name = "Watermark",
        Size = UDim2.new(0, 150, 0, 28),
        Position = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Theme.Header,
        BorderSizePixel = 1,
        BorderColor3 = Theme.Border,
        Parent = ScreenGui,
    })
    create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Watermark,
    })
    makeDraggableTweened(Watermark, Watermark, 0.12)

    -- Main window.
    local Window = create("Frame", {
        Name = "Window",
        Size = UDim2.new(0, 620, 0, 460),
        Position = UDim2.new(0, 240, 0, 110),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 1,
        BorderColor3 = Theme.Border,
        ClipsDescendants = true,
        Parent = ScreenGui,
    })

    local Header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Header,
        BorderSizePixel = 1,
        BorderColor3 = Theme.Border,
        Parent = Window,
    })

    local Logo = create("ImageLabel", {
        Name = "Logo",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 12, 0.5, -9),
        BackgroundTransparency = 1,
        Image = logoId,
        ImageColor3 = Theme.Accent,
        Parent = Header,
    })

    create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 38, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        Font = FONT_BOLD,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
    })

    makeDraggable(Header, Window)

    local TabBar = create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(0, 110, 1, -41),
        Position = UDim2.new(0, 0, 0, 41),
        BackgroundColor3 = Theme.Header,
        BorderSizePixel = 1,
        BorderColor3 = Theme.Border,
        Parent = Window,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabBar,
    })

    local TabContainer = create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -111, 1, -41),
        Position = UDim2.new(0, 111, 0, 41),
        BackgroundTransparency = 1,
        Parent = Window,
    })

    local ResizeGrip = create("TextButton", {
        Name = "ResizeGrip",
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(1, -14, 1, -14),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = Window,
    })
    makeResizable(ResizeGrip, Window, MIN_SIZE)

    -- Toggle UI visibility (default: Right Shift, configurable via ToggleKey).
    local uiVisible = true
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == toggleKey then
            uiVisible = not uiVisible
            Window.Visible = uiVisible
        end
    end)

    ------------------------------------------------------------
    -- WindowObj API
    ------------------------------------------------------------
    local WindowObj = {}
    WindowObj.Tabs = {}

    function WindowObj:MakeTab(name)
        local TabButton = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Theme.Header,
            BorderSizePixel = 1,
            BorderColor3 = Theme.Border,
            Text = name,
            TextColor3 = Theme.Text,
            Font = FONT,
            TextSize = 13,
            AutoButtonColor = false,
            Parent = TabBar,
        })

        local TabPage = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = TabContainer,
        })

        create("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TabPage,
        })
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = TabPage,
        })

        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(WindowObj.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundColor3 = Theme.Header
            end
            TabPage.Visible = true
            TabButton.BackgroundColor3 = Theme.Background
        end)

        local isFirst = #WindowObj.Tabs == 0
        TabPage.Visible = isFirst
        TabButton.BackgroundColor3 = isFirst and Theme.Background or Theme.Header

        table.insert(WindowObj.Tabs, {Button = TabButton, Page = TabPage})

        local Tab = {}

        function Tab:MakeGroup(groupName)
            local Group = create("Frame", {
                Size = UDim2.new(1, 0, 0, 40),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.GroupBg,
                BorderSizePixel = 1,
                BorderColor3 = Theme.Border,
                Parent = TabPage,
            })

            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                Text = groupName,
                TextColor3 = Theme.Text,
                Font = FONT_BOLD,
                TextSize = 13,
                Parent = Group,
            })

            local Content = create("Frame", {
                Size = UDim2.new(1, -20, 0, 0),
                Position = UDim2.new(0, 10, 0, 28),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = Group,
            })
            create("UIListLayout", {
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Content,
            })
            create("UIPadding", {PaddingBottom = UDim.new(0, 10), Parent = Content})

            local GroupObj = {}

            ------------------------------------------------
            -- TOGGLE
            ------------------------------------------------
            function GroupObj:AddToggle(text, default, callback)
                callback = callback or function() end
                local state = default or false

                local Holder = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Parent = Content,
                })

                local Box = create("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 0, 0.5, -7),
                    BackgroundColor3 = Theme.ElementBg,
                    BorderSizePixel = 1,
                    BorderColor3 = Theme.Border,
                    Parent = Holder,
                })

                create("TextLabel", {
                    Size = UDim2.new(1, -90, 1, 0),
                    Position = UDim2.new(0, 22, 0, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.SubText,
                    Font = FONT,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Holder,
                })

                local Click = create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = Holder,
                })

                local function render()
                    Box.BackgroundColor3 = state and Theme.White or Theme.ElementBg
                end

                Click.MouseButton1Click:Connect(function()
                    state = not state
                    render()
                    callback(state)
                end)

                render()
                return {
                    Set = function(_, v) state = v; render(); callback(state) end,
                    Get = function() return state end,
                }
            end

            ------------------------------------------------
            -- BUTTON
            ------------------------------------------------
            function GroupObj:AddButton(text, callback)
                callback = callback or function() end

                local Btn = create("TextButton", {
                    Size = UDim2.new(0, 100, 0, 22),
                    BackgroundColor3 = Theme.ElementBg,
                    BorderSizePixel = 1,
                    BorderColor3 = Theme.Border,
                    Text = text,
                    TextColor3 = Theme.Text,
                    Font = FONT,
                    TextSize = 12,
                    AutoButtonColor = false,
                    Parent = Content,
                })

                Btn.MouseButton1Click:Connect(function()
                    Btn.BackgroundColor3 = Theme.Accent
                    task.delay(0.1, function()
                        Btn.BackgroundColor3 = Theme.ElementBg
                    end)
                    callback()
                end)

                return Btn
            end

            ------------------------------------------------
            -- SLIDER
            ------------------------------------------------
            function GroupObj:AddSlider(text, min, max, default, callback)
                callback = callback or function() end
                min, max = min or 0, max or 100
                local value = math.clamp(default or min, min, max)

                local Holder = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent = Content,
                })

                create("TextLabel", {
                    Size = UDim2.new(1, -40, 0, 14),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.SubText,
                    Font = FONT,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Holder,
                })

                local ValueLabel = create("TextLabel", {
                    Size = UDim2.new(0, 40, 0, 14),
                    Position = UDim2.new(1, -40, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(value),
                    TextColor3 = Theme.SubText,
                    Font = FONT,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = Holder,
                })

                local Bar = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 14),
                    Position = UDim2.new(0, 0, 0, 18),
                    BackgroundColor3 = Theme.ElementBg,
                    BorderSizePixel = 1,
                    BorderColor3 = Theme.Border,
                    Parent = Holder,
                })

                local Fill = create("Frame", {
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Parent = Bar,
                })

                local dragging = false

                local function setFromX(xPos)
                    local rel = math.clamp((xPos - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + (max - min) * rel)
                    Fill.Size = UDim2.new(rel, 0, 1, 0)
                    ValueLabel.Text = tostring(value)
                    callback(value)
                end

                Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        setFromX(input.Position.X)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch) then
                        setFromX(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                return {
                    Set = function(_, v)
                        value = math.clamp(v, min, max)
                        local rel = (value - min) / (max - min)
                        Fill.Size = UDim2.new(rel, 0, 1, 0)
                        ValueLabel.Text = tostring(value)
                        callback(value)
                    end,
                    Get = function() return value end,
                }
            end

            ------------------------------------------------
            -- LABEL
            ------------------------------------------------
            function GroupObj:AddLabel(text)
                return create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 28),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.SubText,
                    Font = FONT,
                    TextSize = 12,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Parent = Content,
                })
            end

            ------------------------------------------------
            -- KEYBIND
            ------------------------------------------------
            function GroupObj:AddKeybind(text, default, callback)
                callback = callback or function() end
                local currentKey = default or Enum.KeyCode.K
                local listening = false

                local Holder = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundColor3 = Theme.ElementBg,
                    BorderSizePixel = 1,
                    BorderColor3 = Theme.Border,
                    Parent = Content,
                })

                create("TextLabel", {
                    Size = UDim2.new(1, -46, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.SubText,
                    Font = FONT,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Holder,
                })

                local KeyBtn = create("TextButton", {
                    Size = UDim2.new(0, 32, 0, 16),
                    Position = UDim2.new(1, -38, 0.5, -8),
                    BackgroundColor3 = Theme.GroupBg,
                    BorderSizePixel = 1,
                    BorderColor3 = Theme.Border,
                    Text = currentKey.Name,
                    TextColor3 = Theme.Text,
                    Font = FONT,
                    TextSize = 11,
                    Parent = Holder,
                })

                KeyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    KeyBtn.Text = "..."
                end)

                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        KeyBtn.Text = currentKey.Name
                        listening = false
                        return
                    end
                    if not gameProcessed and input.KeyCode == currentKey then
                        callback(currentKey)
                    end
                end)

                return {
                    Set = function(_, key) currentKey = key; KeyBtn.Text = key.Name end,
                    Get = function() return currentKey end,
                }
            end

            ------------------------------------------------
            -- DROPDOWN (closed by default)
            ------------------------------------------------
            function GroupObj:AddDropdown(text, options, default, callback)
                callback = callback or function() end
                options = options or {}
                local selected = default or options[1]
                local open = false

                local Holder = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 22),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                    Parent = Content,
                })

                local Header2 = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundColor3 = Theme.ElementBg,
                    BorderSizePixel = 1,
                    BorderColor3 = Theme.Border,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = Holder,
                })

                create("TextLabel", {
                    Size = UDim2.new(1, -26, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.SubText,
                    Font = FONT,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Header2,
                })

                local Arrow = create("TextLabel", {
                    Size = UDim2.new(0, 18, 1, 0),
                    Position = UDim2.new(1, -20, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "v",
                    TextColor3 = Theme.SubText,
                    Font = FONT,
                    TextSize = 12,
                    Parent = Header2,
                })

                local OptionsFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 24),
                    BackgroundColor3 = Theme.GroupBg,
                    BorderSizePixel = 1,
                    BorderColor3 = Theme.Border,
                    ClipsDescendants = true,
                    Parent = Holder,
                })

                create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = OptionsFrame,
                })

                local optionButtons = {}

                local function refreshHighlight()
                    for optText, btn in pairs(optionButtons) do
                        btn.TextColor3 = (optText == selected) and Theme.Accent or Theme.SubText
                    end
                end

                local function rebuildOptions(list)
                    for _, c in ipairs(OptionsFrame:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    optionButtons = {}

                    for _, optText in ipairs(list) do
                        local OptBtn = create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 22),
                            BackgroundTransparency = 1,
                            Text = optText,
                            TextColor3 = (optText == selected) and Theme.Accent or Theme.SubText,
                            Font = FONT,
                            TextSize = 12,
                            Parent = OptionsFrame,
                        })
                        optionButtons[optText] = OptBtn

                        OptBtn.MouseButton1Click:Connect(function()
                            selected = optText
                            refreshHighlight()
                            callback(selected)
                            open = false
                            OptionsFrame.Size = UDim2.new(1, 0, 0, 0)
                            Arrow.Text = "v"
                        end)
                    end
                end

                rebuildOptions(options)

                Header2.MouseButton1Click:Connect(function()
                    open = not open
                    local targetHeight = open and (#options * 22) or 0
                    OptionsFrame.Size = UDim2.new(1, 0, 0, targetHeight)
                    Arrow.Text = open and "^" or "v"
                end)

                return {
                    Set = function(_, value) selected = value; refreshHighlight(); callback(selected) end,
                    Get = function() return selected end,
                    Refresh = function(_, newOptions) options = newOptions; rebuildOptions(newOptions) end,
                }
            end

            return GroupObj
        end

        return Tab
    end

    function WindowObj:Destroy()
        Window:Destroy()
        Watermark:Destroy()
    end

    Logo.BackgroundTransparency = 1

    return WindowObj
end

return Library
