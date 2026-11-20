local NoSlowdown
local Sneak
local UseItem
local Web
local OldMultiplier

NoSlowdown = vape.Categories.Blatant:CreateModule({
	Name = 'NoSlowdown',
	Function = function(callback)
		frictionTable.NoSlowdown = callback or nil
		updateVelocity()

		local controller = mc.Controller
		if not controller then return end

		if callback then
			OldMultiplier = controller.useSpeedMultiplier
			controller.useSpeedMultiplier = function()
				return 1
			end

			NoSlowdown:Clean(runService.Heartbeat:Connect(function()
				if not entitylib.isAlive then return end
				local state = controller.state
				if not state then return end

				if Sneak.Enabled and state.sneaking then
					state.sneaking = false
				end

				if UseItem.Enabled and state.usingItem then
					state.slowMultiplier = 1
				end
			end))
		else
			if OldMultiplier then
				controller.useSpeedMultiplier = OldMultiplier
				OldMultiplier = nil
			end
		end
	end,
	Tooltip = 'Removes movement slowdown from using items'
})
Sneak = NoSlowdown:CreateToggle({
	Name = 'Sneak',
	Default = true
})
UseItem = NoSlowdown:CreateToggle({
	Name = 'Use item',
	Default = true
})
Web = NoSlowdown:CreateToggle({
	Name = 'Cobweb',
	Default = true
})
