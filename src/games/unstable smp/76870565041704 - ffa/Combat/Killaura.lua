local Killaura
local Targets
local Sort
local Range
local AngleSlider
local MaxTargets
local Mouse
local GUI
local BoxAttackColor
local Face
local AttackDelay = 0
local Boxes = {}

local sortmethods = {
	Distance = function(origin, entity)
		return (entity.RootPart.Position - origin).Magnitude
	end,
	Health = function(_, entity)
		return entity.Health
	end,
	Angle = function(origin, entity, facing)
		local delta = (entity.RootPart.Position - origin) * Vector3.new(1, 0, 1)
		return math.acos(facing:Dot(delta.Unit))
	end
}

local function collectTargets(facing)
	local selfpos = entitylib.character.RootPart.Position
	local list = {}

	for _, entity in entitylib.List do
		if not entity.Targetable then continue end
		if not Targets.Players.Enabled and entity.Player then continue end
		if not Targets.NPCs.Enabled and entity.NPC then continue end

		local delta = entity.RootPart.Position - selfpos
		if delta.Magnitude > Range.Value then continue end
		if Targets.Walls.Enabled and entitylib.Wallcheck(selfpos, entity.RootPart.Position) then continue end

		local angle = math.acos(facing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
		if angle > (math.rad(AngleSlider.Value) / 2) then continue end

		table.insert(list, entity)
	end

	local method = sortmethods[Sort.Value]
	if method then
		table.sort(list, function(a, b)
			return method(selfpos, a, facing) < method(selfpos, b, facing)
		end)
	end

	while #list > MaxTargets.Value do
		table.remove(list)
	end

	return list
end

Killaura = vape.Categories.Combat:CreateModule({
	Name = 'Killaura',
	Function = function(callback)
		if callback then
			repeat
				local attacked = {}
				local hands, controller = mc.Hands, mc.Controller

				if entitylib.isAlive and hands and controller and not hands.using then
					local pressed = not Mouse.Enabled or inputService:IsMouseButtonPressed(0)
					local blocked = GUI.Enabled and controller.locked

					if pressed and not blocked then
						local facing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
						local targets = collectTargets(facing)

						if #targets > 0 then
							table.insert(attacked, {Entity = targets[1], Check = BoxAttackColor})
							targetinfo.Targets[targets[1]] = os.clock() + 1

							if AttackDelay < tick() then
								AttackDelay = tick() + 0.11
								if vape.ThreadFix then
									setthreadidentity(8)
								end

								pcall(function()
									hands.attack(targets[1])
								end)

								if Face.Enabled then
									local pos = targets[1].RootPart.Position * Vector3.new(1, 0, 1)
									entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position, Vector3.new(pos.X, entitylib.character.RootPart.Position.Y + 0.001, pos.Z))
								end
							end
						end
					end
				end

				for index, box in Boxes do
					box.Adornee = attacked[index] and attacked[index].Entity.RootPart or nil
					if box.Adornee then
						box.Color3 = Color3.fromHSV(attacked[index].Check.Hue, attacked[index].Check.Sat, attacked[index].Check.Value)
						box.Transparency = 1 - attacked[index].Check.Opacity
					end
				end

				task.wait(#attacked > 0 and #attacked * 0.05 or 0.016)
			until not Killaura.Enabled
		else
			for _, box in Boxes do
				box.Adornee = nil
			end
		end
	end,
	Tooltip = 'Attack players around you\nwithout aiming at them.'
})
Targets = Killaura:CreateTargets({
	Players = true,
	NPCs = true
})
Range = Killaura:CreateSlider({
	Name = 'Attack range',
	Min = 1,
	Max = 8,
	Default = 4.5,
	Decimal = 10,
	Suffix = function(val)
		return val == 1 and 'block' or 'blocks'
	end
})
AngleSlider = Killaura:CreateSlider({
	Name = 'Max angle',
	Min = 1,
	Max = 360,
	Default = 360
})
MaxTargets = Killaura:CreateSlider({
	Name = 'Max targets',
	Min = 1,
	Max = 5,
	Default = 1
})
Sort = Killaura:CreateDropdown({
	Name = 'Target Mode',
	List = {'Distance', 'Health', 'Angle'}
})
Mouse = Killaura:CreateToggle({Name = 'Require mouse down'})
GUI = Killaura:CreateToggle({Name = 'GUI check'})
Face = Killaura:CreateToggle({Name = 'Face target'})
Killaura:CreateToggle({
	Name = 'Show target',
	Function = function(callback)
		BoxAttackColor.Object.Visible = callback
		if callback then
			for index = 1, 5 do
				local box = Instance.new('BoxHandleAdornment')
				box.Adornee = nil
				box.AlwaysOnTop = true
				box.Size = Vector3.new(3, 5, 3)
				box.CFrame = CFrame.new(0, -0.5, 0)
				box.ZIndex = 0
				box.Parent = vape.holder
				Boxes[index] = box
			end
		else
			for _, box in Boxes do
				box:Destroy()
			end
			table.clear(Boxes)
		end
	end
})
BoxAttackColor = Killaura:CreateColorSlider({
	Name = 'Attack Color',
	Darker = true,
	DefaultOpacity = 0.5,
	Visible = false
})
