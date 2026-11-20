local NameTags
local Targets
local Color
local Background
local Health
local Distance
local Teammates
local Reference = {}
local Folder = Instance.new('Folder')
Folder.Parent = vape.gui

local function build(entity)
	local tag = Instance.new('BillboardGui')
	tag.Name = 'VapeNameTag'
	tag.Size = UDim2.fromOffset(180, 40)
	tag.StudsOffset = Vector3.new(0, 2.1, 0)
	tag.AlwaysOnTop = true
	tag.LightInfluence = 0
	tag.Adornee = entity.Head
	tag.Parent = entity.Character

	local frame = Instance.new('Frame')
	frame.BackgroundColor3 = Color3.new()
	frame.BackgroundTransparency = 1 - Background.Value
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromOffset(160, 32)
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, 0)
	frame.Parent = tag

	local name = Instance.new('TextLabel')
	name.BackgroundTransparency = 1
	name.TextSize = 12
	name.TextColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
	name.TextStrokeTransparency = 0
	name.TextStrokeColor3 = Color3.new()
	name.Size = UDim2.new(1, -4, 0, 14)
	name.Position = UDim2.new(0, 2, 0, 1)
	name.Text = ''
	name.Parent = frame

	local hpBg = Instance.new('Frame')
	hpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	hpBg.BorderSizePixel = 0
	hpBg.Size = UDim2.new(1, -4, 0, 4)
	hpBg.Position = UDim2.new(0, 2, 0, 17)
	hpBg.Parent = frame

	local hpFill = Instance.new('Frame')
	hpFill.BorderSizePixel = 0
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.Parent = hpBg

	local info = Instance.new('TextLabel')
	info.BackgroundTransparency = 1
	info.TextSize = 9
	info.TextColor3 = Color3.fromRGB(200, 200, 200)
	info.TextStrokeTransparency = 0
	info.TextStrokeColor3 = Color3.new()
	info.Size = UDim2.new(1, -4, 0, 10)
	info.Position = UDim2.new(0, 2, 0, 22)
	info.Text = ''
	info.Parent = frame

	Reference[entity] = {gui = tag, name = name, hpBg = hpBg, hpFill = hpFill, info = info, frame = frame}
end

local function remove(entity)
	local tag = Reference[entity]
	if tag then
		tag.gui:Destroy()
		Reference[entity] = nil
	end
end

NameTags = vape.Categories.Render:CreateModule({
	Name = 'NameTags',
	Function = function(callback)
		if callback then
			NameTags:Clean(entitylib.Events.EntityRemoved:Connect(remove))
			NameTags:Clean(entitylib.Events.EntityAdded:Connect(function(entity)
				if Reference[entity] then remove(entity) end
				if Teammates.Enabled and (not entity.Targetable) and (not entity.Friend) then return end
				build(entity)
			end))
			NameTags:Clean(runService.Heartbeat:Connect(function()
				if not entitylib.isAlive then return end
				local origin = entitylib.character.RootPart.Position

				for entity, tag in Reference do
					if not entity.Character.Parent then
						remove(entity)
						continue
					end

					local pct = math.clamp(entity.Health / math.max(entity.MaxHealth, 1), 0, 1)
					tag.name.Text = entity.Player and entity.Player.DisplayName or entity.Character.Name
					tag.name.TextColor3 = entitylib.getEntityColor(entity) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)

					if Health.Enabled then
						tag.hpBg.Visible = true
						tag.hpFill.Size = UDim2.new(pct, 0, 1, 0)
						tag.hpFill.BackgroundColor3 = Color3.fromHSV(math.clamp(pct, 0, 1) / 2.5, 0.89, 0.75)
					else
						tag.hpBg.Visible = false
					end

					local parts = {}
					if Distance.Enabled then
						table.insert(parts, math.floor((entity.RootPart.Position - origin).Magnitude) .. 'm')
					end
					tag.info.Text = table.concat(parts, ' · ')
					tag.info.Visible = #parts > 0
				end
			end))

			for _, entity in entitylib.List do
				if Reference[entity] then remove(entity) end
				if Teammates.Enabled and (not entity.Targetable) and (not entity.Friend) then continue end
				build(entity)
			end
		else
			for entity in Reference do
				remove(entity)
			end
		end
	end,
	Tooltip = 'Renders nametags on entities through walls'
})
Targets = NameTags:CreateTargets({
	Players = true,
	Function = function()
		if NameTags.Enabled then
			NameTags:Toggle()
			NameTags:Toggle()
		end
	end
})
Color = NameTags:CreateColorSlider({
	Name = 'Player Color',
	DefaultSat = 0
})
Background = NameTags:CreateSlider({
	Name = 'Transparency',
	Min = 0,
	Max = 1,
	Default = 0.35,
	Decimal = 100
})
Health = NameTags:CreateToggle({
	Name = 'Health',
	Default = true
})
Distance = NameTags:CreateToggle({
	Name = 'Distance',
	Default = true
})
Teammates = NameTags:CreateToggle({
	Name = 'Priority Only',
	Default = true,
	Tooltip = 'Hides teammates & non targetable entities'
})
