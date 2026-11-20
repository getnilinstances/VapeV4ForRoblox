local TriggerBot
local Range
local Strength
local Crosshair
local Delay = 0

TriggerBot = vape.Categories.Combat:CreateModule({
	Name = 'TriggerBot',
	Function = function(callback)
		if callback then
			TriggerBot:Clean(runService.Heartbeat:Connect(function()
				if not entitylib.isAlive or Delay > os.clock() then return end
				local hands, controller = mc.Hands, mc.Controller
				if not hands or not controller or hands.using then return end

				local best
				local eye = entitylib.character.RootPart.Position
				local facing = workspace.CurrentCamera.CFrame.LookVector

				for _, entity in entitylib.List do
					if not entity.Targetable then continue end
					local delta = entity.RootPart.Position - eye
					if delta.Magnitude > Range.Value then continue end

					local dot = facing:Dot(delta.Unit)
					if Crosshair.Enabled and dot < 0.995 then continue end
					if not best or delta.Magnitude < (best.RootPart.Position - eye).Magnitude then
						best = entity
					end
				end

				if best and hands.strength and hands.strength() >= Strength.Value then
					Delay = os.clock() + 0.05
					pcall(function()
						hands.attack(best)
					end)
				end
			end))
		end
	end,
	Tooltip = 'Attacks the entity under your crosshair'
})
Range = TriggerBot:CreateSlider({
	Name = 'Range',
	Min = 1,
	Max = 8,
	Default = 4.5,
	Decimal = 10,
	Suffix = function(val)
		return val == 1 and 'block' or 'blocks'
	end
})
Strength = TriggerBot:CreateSlider({
	Name = 'Min strength',
	Min = 0.1,
	Max = 1,
	Default = 0.9,
	Decimal = 100,
	Darker = true
})
Crosshair = TriggerBot:CreateToggle({
	Name = 'Require crosshair',
	Default = true
})
