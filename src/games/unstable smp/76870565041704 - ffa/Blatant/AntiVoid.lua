run(function()
	local AntiVoid
	local Height
	local Safe = Vector3.zero
	local LastAction = 0

	AntiVoid = vape.Categories.Blatant:CreateModule({
		Name = 'AntiVoid',
		Function = function(callback)
			if not callback then
				Safe = Vector3.zero
				return
			end

			AntiVoid:Clean(runService.Heartbeat:Connect(function()
				if not entitylib.isAlive then return end

				local character = entitylib.character
				local root = character and character.RootPart
				local controller = mc.Controller
				local state = controller and controller.state
				if not root or not state then return end

				local position = typeof(state.pos) == 'Vector3' and state.pos or root.Position
				if state.onGround and position.Y > Height.Value then
					Safe = position
					return
				end

				if position.Y > Height.Value then return end
				if os.clock() - LastAction < 0.5 then return end
				LastAction = os.clock()

				if typeof(state.pos) == 'Vector3' and Safe.Y > Height.Value then
					state.pos = Safe + Vector3.new(0, 3, 0)
					state.prev = state.pos
					state.fallDistance = 0

					if typeof(state.vel) == 'Vector3' then
						state.vel = Vector3.zero
					end
				elseif typeof(state.vel) == 'Vector3' then
					state.vel = Vector3.new(state.vel.X, 4, state.vel.Z)
				end
			end))
		end,
		Tooltip = 'Puts you back on the last block you stood on\nbefore you drop out of the world'
	})
	Height = AntiVoid:CreateSlider({
		Name = 'Height',
		Min = -64,
		Max = 32,
		Default = -20
	})
end)
