# aero.crack UI Library

A Linoria-style Roblox UI library — blocky, squared, flat dark theme.
No rounded corners, thin 1px borders, monospace text, drag-to-resize window.

> **Use only inside games/places you own or have permission to modify.**
> This library renders UI for your own experience. It does not inject into,
> or modify, games you don't control.

## Features

- Draggable main window (instant drag, no tween)
- Draggable watermark (tweened/smooth drag)
- Resizable window (drag the bottom-right grip)
- Toggle, Button, Slider, Label, Keybind, Dropdown elements
- Dropdown closed by default, opens/closes on click
- Slide-out notifications (swipe right + fade)
- Configurable show/hide hotkey (default: Right Shift)
- Custom title + logo image per window

## Installation

Push `init.lua` to a public GitHub repo, then load it with `loadstring` +
`HttpGet`, pointed at the **raw** file URL:

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/<your-username>/<your-repo>/main/init.lua"
))()
```

Replace `<your-username>/<your-repo>` with your actual GitHub path once
you've pushed this repo. You can find the raw URL on GitHub by opening
`init.lua` and clicking the **Raw** button.

## Usage

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/<your-username>/<your-repo>/main/init.lua"
))()

local Window = Library:CreateWindow({
    Title     = "aero.crack",
    Logo      = "rbxassetid://8463897834", -- your decal/image asset id
    ToggleKey = Enum.KeyCode.RightShift,    -- optional, defaults to RightShift
})

local Tab = Window:MakeTab("tab1")

local Group1 = Tab:MakeGroup("group name")
Group1:AddToggle("toggle", false, function(state)
    print("toggle:", state)
end)
Group1:AddButton("button", function()
    print("button clicked")
end)
Group1:AddSlider("slider", 0, 100, 35, function(value)
    print("slider:", value)
end)

local Group2 = Tab:MakeGroup("group name")
Group2:AddLabel("hi uhhh this is a label for idk and ty for using aero.crack")
Group2:AddKeybind("Keybind", Enum.KeyCode.K, function(key)
    print(key.Name, "pressed")
end)
Group2:AddDropdown("Dropdown", {"Option 1", "Option 2"}, nil, function(value)
    print("selected:", value)
end)

Library:Notify("UI initialized", 3) -- text, duration (seconds)
```

## API Reference

### `Library:CreateWindow(config)`
| Field | Type | Default | Description |
|---|---|---|---|
| `Title` | string | `"aero.crack"` | Window + watermark title |
| `Logo` | string | `"rbxassetid://8463897834"` | Image asset id shown next to the title |
| `ToggleKey` | `Enum.KeyCode` | `Enum.KeyCode.RightShift` | Key that shows/hides the window |

Returns a `Window` object.

### `Window:MakeTab(name)`
Returns a `Tab` object.

### `Tab:MakeGroup(name)`
Returns a `Group` object.

### Group methods
- `Group:AddToggle(text, default, callback(state))` → `{Set, Get}`
- `Group:AddButton(text, callback())`
- `Group:AddSlider(text, min, max, default, callback(value))` → `{Set, Get}`
- `Group:AddLabel(text)`
- `Group:AddKeybind(text, defaultKeyCode, callback(keyCode))` → `{Set, Get}`
- `Group:AddDropdown(text, optionsList, default, callback(value))` → `{Set, Get, Refresh}`

### `Library:Notify(text, duration)`
Shows a slide-in/slide-out notification in the top-right corner.

### `Window:Destroy()`
Removes the window and its watermark from the screen.

## License

MIT — see `LICENSE`.
