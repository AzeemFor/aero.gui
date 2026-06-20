--[[
    Example: how to load and use the aero.crack UI library
    inside a LocalScript in your own game.

    Replace the URL below with your repo's raw GitHub URL once pushed.
--]]

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/AzeemFor/aero.gui/refs/heads/main/init.lua"
))()

local Window = Library:CreateWindow({
    Title     = "aero.crack",
    Logo      = "rbxassetid://8463897834",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Tab1 = Window:MakeTab("tab1")

local Group1 = Tab1:MakeGroup("group name")
Group1:AddToggle("toggle", false, function(state)
    Library:Notify("Toggle set to " .. tostring(state))
end)
Group1:AddButton("button", function()
    Library:Notify("Button clicked")
end)
Group1:AddSlider("slider", 0, 100, 35, function(value) end)

local Group2 = Tab1:MakeGroup("group name")
Group2:AddLabel("hi uhhh this is a label for idk and ty for using aero.crack")
Group2:AddKeybind("Keybind", Enum.KeyCode.K, function(key)
    Library:Notify(key.Name .. " pressed")
end)
Group2:AddDropdown("Dropdown", {"Option 1", "Option 2"}, nil, function(value)
    Library:Notify("Selected: " .. value)
end)

Library:Notify("UI initialized")
