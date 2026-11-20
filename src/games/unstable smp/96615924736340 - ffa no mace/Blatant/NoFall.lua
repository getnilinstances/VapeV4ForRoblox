local NoFall
local LastTick = 0

NoFall = vape.Categories.Blatant:CreateModule({
	Name = 'NoFall',
	Function = function(callback)
		if callback then
			NoFall:Clean(runService.Heartbeat:Connect(function()
				if not entitylib.isAlive then return end
				local controller = mc.Controller
				if not controller or not controller.state then return end
				local state = controller.state
				if os.clock() - LastTick < 0.1 then return end

				LastTick = os.clock()
				if state.fallDistance then
					state.fallDistance = 0
				end
			end))
		end
	end,
	Tooltip = 'Prevents fall damage'
})
