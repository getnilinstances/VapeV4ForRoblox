local KeepSprint

KeepSprint = vape.Categories.Blatant:CreateModule({
	Name = 'KeepSprint',
	Function = function(callback)
		if callback then
			KeepSprint:Clean(runService.Heartbeat:Connect(function()
				if not entitylib.isAlive then return end
				local controller = mc.Controller
				if not controller or not controller.state then return end

				if not controller.state.sprinting then
					controller.state.sprinting = true
				end
			end))
		end
	end,
	Tooltip = 'Keeps sprint applied while attacking'
})
