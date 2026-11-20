local Velocity
local Horizontal
local Vertical

Velocity = vape.Categories.Blatant:CreateModule({
	Name = 'Velocity',
	Function = function(callback)
		if callback then
			Velocity:Clean(runService.Heartbeat:Connect(function()
				if not entitylib.isAlive then return end
				local controller = mc.Controller
				if not controller or not controller.state then return end
				local state = controller.state

				local vel = state.knockback
				if not vel then return end

				state.knockback = Vector3.new(
					vel.X * Horizontal.Value,
					vel.Y * Vertical.Value,
					vel.Z * Horizontal.Value
				)
			end))
		end
	end,
	Tooltip = 'Reduces knockback taken'
})
Horizontal = Velocity:CreateSlider({
	Name = 'Horizontal',
	Min = 0,
	Max = 1,
	Default = 0,
	Decimal = 100
})
Vertical = Velocity:CreateSlider({
	Name = 'Vertical',
	Min = 0,
	Max = 1,
	Default = 0,
	Decimal = 100
})
