local FastFall
local Speed

FastFall = vape.Categories.Blatant:CreateModule({
	Name = 'FastFall',
	Function = function(callback)
		if callback then
			FastFall:Clean(runService.Heartbeat:Connect(function()
				if not entitylib.isAlive then return end
				local controller = mc.Controller
				if not controller or not controller.state then return end
				local state = controller.state
				if state.onGround or state.gliding or state.inWater then return end
				if not state.vel or state.vel.Y > -0.1 then return end

				state.vel = Vector3.new(state.vel.X, math.min(state.vel.Y, -Speed.Value), state.vel.Z)
			end))
		end
	end,
	Tooltip = 'Increases fall speed'
})
Speed = FastFall:CreateSlider({
	Name = 'Speed',
	Min = 0.5,
	Max = 10,
	Default = 3,
	Decimal = 10
})
