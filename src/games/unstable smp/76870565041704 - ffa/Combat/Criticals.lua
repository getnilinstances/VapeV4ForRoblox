local Criticals
local OnlyFalling

Criticals = vape.Categories.Combat:CreateModule({
	Name = 'Criticals',
	Function = function(callback)
		if callback then
			Criticals:Clean(runService.Heartbeat:Connect(function()
				if not entitylib.isAlive then return end
				local controller = mc.Controller
				if not controller or not controller.state then return end
				local state = controller.state

				if OnlyFalling.Enabled and state.onGround then return end
				if state.vel and state.vel.Y > -0.1 and not state.onGround then return end
				Criticals.falling = true
			end))
		end
	end,
	Tooltip = 'Keeps your attacks counted as critical hits',
})
OnlyFalling = Criticals:CreateToggle({
	Name = 'Only falling'
})
