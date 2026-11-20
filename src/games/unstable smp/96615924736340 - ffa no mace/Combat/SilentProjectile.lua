local SilentProjectile
local Targets
local Range
local Angle
local Charge
local Speed
local Predict
local AutoShoot
local CircleColor
local CircleTransparency
local CircleFilled
local CircleObject
local UsingSince

local projectiles = {'arrow', 'ender_pearl', 'splash', 'trident', 'egg', 'snowball'}

local function isProjectile(id)
	local name = tostring(id):lower()
	for _, part in projectiles do
		if name:find(part, 1, true) then
			return true
		end
	end
	return false
end

local function getEye()
	local character = entitylib.character
	if character and character.Head then
		return character.Head.Position
	end

	local camera = workspace.CurrentCamera
	return camera and camera.CFrame.Position
end

local function getTarget()
	local camera = workspace.CurrentCamera
	local eye = getEye()
	if not camera or not eye or not entitylib.isAlive then return end

	local look = camera.CFrame.LookVector
	local limit = math.cos(math.rad(Angle.Value))
	local best, bestScore

	for _, entity in entitylib.List do
		local part = entity.RootPart
		if not part or not entity.Targetable then continue end
		if not Targets.Players.Enabled and entity.Player then continue end
		if not Targets.NPCs.Enabled and entity.NPC then continue end

		local delta = part.Position - eye
		local distance = delta.Magnitude
		if distance < 0.5 or distance > Range.Value then continue end
		if delta.Unit:Dot(look) < limit then continue end
		if Targets.Walls.Enabled and entitylib.Wallcheck(eye, part.Position) then continue end

		local score = delta.Unit:Dot(look) * 2 - distance / Range.Value
		if not bestScore or score > bestScore then
			best, bestScore = entity, score
		end
	end

	return best
end

local function getAimPoint(entity)
	local part = entity.RootPart
	local eye = getEye()
	local speed = Speed.Value
	local position = part.Position
	if not eye or speed <= 0 then return position end

	if Predict.Enabled then
		local travel = (position - eye).Magnitude / speed
		position = position + part.AssemblyLinearVelocity * travel
	end

	local config = mc.Config
	local tick = config and config.TICK
	local gravity = config and config.GRAVITY

	if tick and gravity and tick > 0 then
		local ticks = ((position - eye).Magnitude / speed) / tick
		position = position + Vector3.new(0, 0.5 * gravity * ticks * ticks, 0)
	end

	return position
end

local function getRedirect()
	local entity = getTarget()
	local eye = getEye()
	if not entity or not eye then return end

	local direction = getAimPoint(entity) - eye
	if direction.Magnitude < 0.1 then return end
	return direction.Unit
end

local function isCharged(hands, using, elapsed)
	if using.kind == 'crossbow' then
		local inventory = hands.inv
		local held = inventory and inventory.hotbar and inventory.hotbar[inventory.selected or 1]
		local def = itemDef(held)
		local quick = def and type(def.ench) == 'table' and tonumber(def.ench.quick_charge) or 0
		return elapsed >= (25 - 5 * quick) / 20
	end

	local power = math.min((elapsed * elapsed + elapsed * 2) / 3, 1)
	return power >= Charge.Value
end

local function updateCircle()
	if not CircleObject then return end

	local camera = workspace.CurrentCamera
	if not camera then return end

	local half = math.tan(math.rad(camera.FieldOfView / 2))
	local radius = (camera.ViewportSize.Y / 2) * math.tan(math.rad(Angle.Value)) / half
	CircleObject.Radius = math.max(radius, 1)
	CircleObject.Position = inputService:GetMouseLocation()
end

SilentProjectile = vape.Categories.Combat:CreateModule({
	Name = 'SilentProjectile',
	Function = function(callback)
		if CircleObject then
			CircleObject.Visible = callback
		end

		if not callback then
			UsingSince = nil
			return
		end

		local hook = function(payload)
			if payload.a == 'use' and payload.item and isProjectile(payload.item) then
				local redirect = getRedirect()
				if redirect then
					payload.look = redirect
				end
			end
		end

		store.installNetHook()
		table.insert(store.netHooks, hook)

		SilentProjectile:Clean(runService.RenderStepped:Connect(updateCircle))
		SilentProjectile:Clean(runService.Heartbeat:Connect(function()
			local hands = mc.Hands
			local using = hands and hands.using
			if not using or (using.kind ~= 'bow' and using.kind ~= 'crossbow') then
				UsingSince = nil
				return
			end

			if not AutoShoot.Enabled then return end
			UsingSince = UsingSince or os.clock()

			if isCharged(hands, using, os.clock() - UsingSince) and type(hands.stopUsing) == 'function' then
				UsingSince = nil
				pcall(hands.stopUsing, false)
			end
		end))
		SilentProjectile:Clean(function()
			removeHook(store.netHooks, hook)
			UsingSince = nil
		end)
	end,
	Tooltip = 'Aims projectiles at the closest target in your\nfield of view and releases bows at full charge'
})
Targets = SilentProjectile:CreateTargets({
	Players = true,
	NPCs = true
})
Range = SilentProjectile:CreateSlider({
	Name = 'Range',
	Min = 4,
	Max = 48,
	Default = 16,
	Suffix = function(val)
		return val == 1 and 'block' or 'blocks'
	end
})
Angle = SilentProjectile:CreateSlider({
	Name = 'Angle',
	Min = 5,
	Max = 180,
	Default = 40,
	Suffix = '°',
	Function = updateCircle
})
Charge = SilentProjectile:CreateSlider({
	Name = 'Min charge',
	Min = 0.1,
	Max = 1,
	Default = 0.9,
	Decimal = 100
})
Speed = SilentProjectile:CreateSlider({
	Name = 'Projectile speed',
	Min = 10,
	Max = 200,
	Default = 60,
	Suffix = 'b/s'
})
Predict = SilentProjectile:CreateToggle({
	Name = 'Predict movement',
	Default = true,
	Darker = true
})
AutoShoot = SilentProjectile:CreateToggle({
	Name = 'Auto shoot',
	Tooltip = 'Releases the bow or crossbow once it is fully charged'
})
SilentProjectile:CreateToggle({
	Name = 'Range circle',
	Function = function(callback)
		if callback then
			CircleObject = Drawing.new('Circle')
			CircleObject.Filled = CircleFilled.Enabled
			CircleObject.Color = Color3.fromHSV(CircleColor.Hue, CircleColor.Sat, CircleColor.Value)
			CircleObject.NumSides = 100
			CircleObject.Thickness = 1
			CircleObject.Transparency = 1 - CircleTransparency.Value
			CircleObject.Visible = SilentProjectile.Enabled
			updateCircle()
		else
			pcall(function()
				CircleObject.Visible = false
				CircleObject:Remove()
			end)
			CircleObject = nil
		end

		CircleColor.Object.Visible = callback
		CircleTransparency.Object.Visible = callback
		CircleFilled.Object.Visible = callback
	end
})
CircleColor = SilentProjectile:CreateColorSlider({
	Name = 'Circle color',
	Function = function(hue, sat, val)
		if CircleObject then
			CircleObject.Color = Color3.fromHSV(hue, sat, val)
		end
	end,
	Darker = true,
	Visible = false
})
CircleTransparency = SilentProjectile:CreateSlider({
	Name = 'Transparency',
	Min = 0,
	Max = 1,
	Default = 0.5,
	Decimal = 10,
	Function = function(val)
		if CircleObject then
			CircleObject.Transparency = 1 - val
		end
	end,
	Darker = true,
	Visible = false
})
CircleFilled = SilentProjectile:CreateToggle({
	Name = 'Circle filled',
	Function = function(callback)
		if CircleObject then
			CircleObject.Filled = callback
		end
	end,
	Darker = true,
	Visible = false
})
