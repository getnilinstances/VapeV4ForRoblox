local AutoClicker
local CPS
local Swing
local Thread

local function AutoClick()
	if Thread then
		task.cancel(Thread)
	end

	Thread = task.spawn(function()
		repeat
			local hands = mc.Hands
			if hands and not hands.using then
				local target = mc.Controller and mc.Controller.target
				if target then
					pcall(function()
						hands.attack(target)
					end)
				elseif Swing.Enabled then
					pcall(function()
						hands.swing = os.clock()
					end)
				end
			end

			task.wait(1 / CPS.GetRandomValue())
		until not AutoClicker.Enabled
	end)
end

AutoClicker = vape.Categories.Combat:CreateModule({
	Name = 'AutoClicker',
	Function = function(callback)
		if callback then
			AutoClicker:Clean(inputService.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					AutoClick()
				end
			end))

			AutoClicker:Clean(inputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if Thread then
						task.cancel(Thread)
						Thread = nil
					end
				end
			end))
		else
			if Thread then
				task.cancel(Thread)
				Thread = nil
			end
		end
	end,
	Tooltip = 'Hold attack to automatically click'
})
CPS = AutoClicker:CreateTwoSlider({
	Name = 'CPS',
	Min = 1,
	Max = 20,
	DefaultMin = 8,
	DefaultMax = 12
})
Swing = AutoClicker:CreateToggle({
	Name = 'Swing when idle',
	Tooltip = 'Swings even when no target is in range'
})
