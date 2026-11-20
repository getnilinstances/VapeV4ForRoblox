run(function()
	local Backtrack
	local BufferSlider
	local HoldSlider
	local Visualize
	local VisualizeColor
	local HoldKey
	local Buffer = {}
	local SpoofPosition
	local SpoofUntil
	local OldState
	local Lines = {}
	local LastSample = 0

	local function spoof(position)
		if not SpoofPosition or not SpoofUntil then return position end

		local remain = (SpoofUntil - os.clock()) / math.max(HoldSlider.Value / 20, 0.001)
		if remain <= 0 then
			SpoofPosition = nil
			SpoofUntil = nil
			return position
		end

		return position:Lerp(SpoofPosition, math.clamp(remain, 0, 1))
	end

	local function installStateHook()
		local net = mc.Net
		if OldState or not net or type(net.state) ~= 'function' then return end

		OldState = net.state
		net.state = function(state)
			if SpoofPosition and type(state) == 'table' and typeof(state.p) == 'Vector3' then
				local clone = table.clone(state)
				clone.p = spoof(clone.p)
				return OldState(clone)
			end

			return OldState(state)
		end
	end

	local function removeStateHook()
		local net = mc.Net
		if net and OldState then
			if net.state == OldState then
				OldState = nil
				return
			end

			net.state = OldState
		end

		OldState = nil
	end

	local function clearLines()
		for _, line in Lines do
			line.Visible = false
		end
	end

	local function updateVisuals()
		clearLines()
		if not Visualize.Enabled or not SpoofPosition then return end

		local camera = workspace.CurrentCamera
		local point, visible = camera and camera:WorldToViewportPoint(SpoofPosition)
		if not visible then return end

		local center = Vector2.new(point.X, point.Y)
		local size = 10
		local offsets = {Vector2.new(-size, -size), Vector2.new(size, -size), Vector2.new(size, size), Vector2.new(-size, size)}
		local color = Color3.fromHSV(VisualizeColor.Hue, VisualizeColor.Sat, VisualizeColor.Value)

		for index, line in Lines do
			line.From = center + offsets[index]
			line.To = center + offsets[index % 4 + 1]
			line.Color = color
			line.Thickness = 1
			line.Transparency = 1
			line.Visible = true
		end
	end

	Backtrack = vape.Categories.Combat:CreateModule({
		Name = 'Backtrack',
		Function = function(callback)
			if not callback then
				removeStateHook()
				clearLines()
				table.clear(Buffer)
				SpoofPosition = nil
				SpoofUntil = nil
				return
			end

			if Drawing then
				for _ = 1, 4 do
					local line = Drawing.new('Line')
					line.Visible = false
					table.insert(Lines, line)
				end
			end

			local hook = function(payload)
				if SpoofPosition and payload.a == 'state' and typeof(payload.p) == 'Vector3' then
					payload.p = spoof(payload.p)
				end
			end

			store.installNetHook()
			installStateHook()
			table.insert(store.netHooks, hook)

			Backtrack:Clean(HoldKey.Triggered:Connect(function(isDown)
				if not isDown then
					SpoofUntil = nil
					return
				end

				if #Buffer == 0 then return end

				SpoofPosition = Buffer[#Buffer]
				SpoofUntil = os.clock() + (HoldSlider.Value / 20)
			end))

			Backtrack:Clean(runService.Heartbeat:Connect(function()
				if not entitylib.isAlive then return end
				if os.clock() - LastSample < 0.05 then return end

				local character = entitylib.character
				local root = character and character.RootPart
				if not root then return end

				LastSample = os.clock()
				table.insert(Buffer, 1, root.Position)

				while #Buffer > BufferSlider.Value do
					table.remove(Buffer)
				end
			end))

			Backtrack:Clean(runService.RenderStepped:Connect(updateVisuals))
			Backtrack:Clean(function()
				removeHook(store.netHooks, hook)
				removeStateHook()
				clearLines()
				table.clear(Buffer)
				SpoofPosition = nil
				SpoofUntil = nil
			end)
		end,
		Tooltip = 'Keeps a small position buffer and replays it while\nyou hold the key, pulling your hitbox back'
	})
	BufferSlider = Backtrack:CreateSlider({
		Name = 'Buffer',
		Min = 2,
		Max = 10,
		Default = 5,
		Suffix = 't'
	})
	HoldSlider = Backtrack:CreateSlider({
		Name = 'Hold',
		Min = 1,
		Max = 8,
		Default = 3,
		Suffix = 't'
	})
	Visualize = Backtrack:CreateToggle({
		Name = 'Visualize',
		Function = function(callback)
			VisualizeColor.Object.Visible = callback
		end
	})
	VisualizeColor = Backtrack:CreateColorSlider({
		Name = 'Visualize color',
		Darker = true,
		Visible = false
	})
	HoldKey = Backtrack:CreateBind({
		Name = 'Hold key',
		Default = {'X'},
		Hold = true
	})
end)
