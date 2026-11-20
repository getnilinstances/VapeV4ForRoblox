local NoJumpDelay

NoJumpDelay = vape.Categories.Blatant:CreateModule({
	Name = 'NoJumpDelay',
	Function = function(callback)
		if not callback then return end

		NoJumpDelay:Clean(runService.Heartbeat:Connect(function()
			local controller = mc.Controller
			local state = controller and controller.state
			if not state then return end

			state.jumpDelay = 0
		end))
	end,
	Tooltip = 'Removes the short delay between two jumps'
})
