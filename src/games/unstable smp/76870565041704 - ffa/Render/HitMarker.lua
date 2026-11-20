local HitMarker
local Color
local CritColor
local Size
local Thickness
local Gap
local Duration
local Lines = {}
local ShownUntil = 0
local Critical = false

local offsets = {
	Vector2.new(-1, -1),
	Vector2.new(1, -1),
	Vector2.new(1, 1),
	Vector2.new(-1, 1)
}

local function ensureLines()
	if not Drawing then return end

	for index = #Lines + 1, 4 do
		local line = Drawing.new('Line')
		line.Visible = false
		Lines[index] = line
	end
end

local function hideLines()
	for _, line in Lines do
		line.Visible = false
		pcall(function()
			line:Remove()
		end)
	end

	table.clear(Lines)
end

local function show()
	local hands = mc.Hands
	local controller = mc.Controller
	local state = controller and controller.state
	local strength = 0

	if hands and type(hands.strength) == 'function' then
		local success, value = pcall(hands.strength)
		strength = success and tonumber(value) or 0
	end

	local falling = state and type(state.fallDistance) == 'number' and state.fallDistance > 0
	Critical = falling or strength >= 0.99
	ShownUntil = os.clock() + Duration.Value
	ensureLines()
end

local function update()
	if not Drawing then return end

	local remain = ShownUntil - os.clock()
	local visible = remain > 0
	local center = inputService:GetMouseLocation()
	local pick = Critical and CritColor or Color
	local color = Color3.fromHSV(pick.Hue, pick.Sat, pick.Value)

	for index, line in Lines do
		line.Visible = visible
		if visible then
			local direction = offsets[index]
			line.From = center + direction * Gap.Value
			line.To = center + direction * (Gap.Value + Size.Value)
			line.Color = color
			line.Thickness = Thickness.Value
			line.Transparency = math.clamp(remain / math.max(Duration.Value, 0.001), 0, 1)
		end
	end
end

HitMarker = vape.Categories.Render:CreateModule({
	Name = 'HitMarker',
	Function = function(callback)
		if not callback then
			hideLines()
			return
		end

		local hook = function(target)
			if not target then return end

			show()
		end

		store.installAttackHook()
		table.insert(store.attackPostHooks, hook)
		HitMarker:Clean(runService.RenderStepped:Connect(update))
		HitMarker:Clean(function()
			removeHook(store.attackPostHooks, hook)
			hideLines()
		end)
	end,
	Tooltip = 'Draws a marker around the crosshair every time\nyour attack lands'
})
Color = HitMarker:CreateColorSlider({
	Name = 'Color'
})
CritColor = HitMarker:CreateColorSlider({
	Name = 'Crit color',
	Darker = true
})
Size = HitMarker:CreateSlider({
	Name = 'Size',
	Min = 2,
	Max = 20,
	Default = 8
})
Thickness = HitMarker:CreateSlider({
	Name = 'Thickness',
	Min = 1,
	Max = 4,
	Default = 2
})
Gap = HitMarker:CreateSlider({
	Name = 'Gap',
	Min = 0,
	Max = 20,
	Default = 4
})
Duration = HitMarker:CreateSlider({
	Name = 'Duration',
	Min = 0.05,
	Max = 1,
	Default = 0.15,
	Decimal = 100
})
