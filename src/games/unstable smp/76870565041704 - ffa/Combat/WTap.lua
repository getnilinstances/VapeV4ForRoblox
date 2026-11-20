local WTap
local Ticks
local ResetUntil = 0

WTap = vape.Categories.Combat:CreateModule({
	Name = 'WTap',
	Function = function(callback)
		if not callback then
			ResetUntil = 0
			return
		end

		local hook = function()
			ResetUntil = os.clock() + (Ticks.Value / 20)
		end

		store.installAttackHook()
		table.insert(store.attackPostHooks, hook)
		WTap:Clean(runService.Heartbeat:Connect(function()
			if os.clock() >= ResetUntil then return end

			local controller = mc.Controller
			local state = controller and controller.state
			if state then
				state.sprinting = false
			end
		end))
		WTap:Clean(function()
			removeHook(store.attackPostHooks, hook)
			ResetUntil = 0
		end)
	end,
	Tooltip = 'Resets your sprint for a few ticks after every hit'
})
Ticks = WTap:CreateSlider({
	Name = 'Ticks',
	Min = 1,
	Max = 4,
	Default = 1,
	Suffix = 't'
})
