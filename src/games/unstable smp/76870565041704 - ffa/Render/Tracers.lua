local Tracers
local Targets
local NearColor
local FarColor
local Fade
local FromBottom
local Range
local Folder = Instance.new('Folder')
Folder.Parent = vape.gui
local Lines = {}

local function getLine()
	for _, line in Lines do
		if not line.Visible then return line end
	end
	local line = Drawing.new('Line')
	line.Thickness = 1
	line.Transparency = 1
	table.insert(Lines, line)
	return line
end

local function hideAll()
	for _, line in Lines do
		line.Visible = false
	end
end

Tracers = vape.Categories.Render:CreateModule({
	Name = 'Tracers',
	Function = function(callback)
		if callback then
			Tracers:Clean(runService.RenderStepped:Connect(function()
				hideAll()
				if not entitylib.isAlive or not Drawing then return end

				local cam = workspace.CurrentCamera
				local origin = entitylib.character.RootPart.Position
				local screen = cam.ViewportSize

				for _, entity in entitylib.List do
					if not entity.Targetable then continue end
					if not Targets.Players.Enabled and entity.Player then continue end
					if not Targets.NPCs.Enabled and entity.NPC then continue end

					local distance = (entity.RootPart.Position - origin).Magnitude
					if distance > Range.Value then continue end

					local point, visible = cam:WorldToViewportPoint(entity.RootPart.Position)
					if not visible then continue end

					local line = getLine()
					if not line then break end

					line.Visible = true
					line.From = Vector2.new(screen.X / 2, FromBottom.Enabled and screen.Y or screen.Y / 2)
					line.To = Vector2.new(point.X, point.Y)

					local near = Color3.fromHSV(NearColor.Hue, NearColor.Sat, NearColor.Value)
					local far = Color3.fromHSV(FarColor.Hue, FarColor.Sat, FarColor.Value)
					line.Color = Fade.Enabled and near:Lerp(far, math.clamp(distance / Range.Value, 0, 1)) or near
				end
			end))
		else
			hideAll()
		end
	end,
	Tooltip = 'Draws lines from the screen to entities'
})
Targets = Tracers:CreateTargets({
	Players = true
})
NearColor = Tracers:CreateColorSlider({
	Name = 'Near Color'
})
FarColor = Tracers:CreateColorSlider({
	Name = 'Far Color',
	Darker = true
})
Fade = Tracers:CreateToggle({
	Name = 'Fade by distance',
	Default = true
})
FromBottom = Tracers:CreateToggle({
	Name = 'From bottom',
	Default = true
})
Range = Tracers:CreateSlider({
	Name = 'Range',
	Min = 16,
	Max = 500,
	Default = 128
})
