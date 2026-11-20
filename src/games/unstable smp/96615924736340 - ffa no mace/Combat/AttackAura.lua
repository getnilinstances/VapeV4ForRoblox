local AttackAura
local Targets
local Range
local MinStrength
local Smooth
local AutoSwing
local Rotation
local LastAttackTick = -math.huge

local function getController()
	return mc.Controller
end

local function getEye()
	local character = entitylib.character
	if character and character.Head then
		return character.Head.Position
	end

	local camera = workspace.CurrentCamera
	return camera and camera.CFrame.Position
end

local function getLook()
	local controller = getController()
	if controller and type(controller.look) == 'function' then
		local success, look = pcall(controller.look)
		if success and typeof(look) == 'Vector3' then
			return look
		end
	end

	local camera = workspace.CurrentCamera
	return camera and camera.CFrame.LookVector or Vector3.new(0, 0, -1)
end

local function getAimPoint(entity)
	local part = entity.RootPart
	if not part then return end

	local head = entity.Head
	local feet = part.Position - Vector3.new(0, entity.HipHeight or 3, 0)
	if head then
		return feet:Lerp(head.Position + Vector3.new(0, 0.5, 0), 0.85)
	end

	return part.Position
end

local function isHitBlocked(eye, entity)
	local character = entity.Character
	if not character or character:GetAttribute('Using') ~= 'shield' then
		return false
	end

	local part = entity.RootPart
	if not part then return false end

	local toEye = eye - part.Position
	local flat = Vector3.new(toEye.X, 0, toEye.Z)
	if flat.Magnitude < 0.01 then return false end

	local look = part.CFrame.LookVector
	return flat:Dot(Vector3.new(look.X, 0, look.Z)) > 0
end

local function findTarget(throughWalls)
	local eye = getEye()
	if not eye then return end

	local look = getLook()
	local limit = Range.Value * BLOCK
	local best, bestScore

	for _, entity in entitylib.List do
		local part = entity.RootPart
		if part and entity.Targetable then
			local skip = (entity.Player and not Targets.Players.Enabled) or (entity.NPC and not Targets.NPCs.Enabled)
			local aim = not skip and getAimPoint(entity)

			if aim then
				local delta = aim - eye
				local distance = delta.Magnitude

				if distance >= 0.5 and distance <= limit and (throughWalls or not entitylib.Wallcheck(eye, aim)) then
					local score = delta.Unit:Dot(look) * 2 - distance / limit
					if not bestScore or score > bestScore then
						best, bestScore = {entity = entity, aim = aim}, score
					end
				end
			end
		end
	end

	return best
end

local function aimAt(position, alpha)
	local controller = getController()
	local eye = getEye()
	if not controller or not eye then return end
	if type(controller.yaw) ~= 'number' or type(controller.pitch) ~= 'number' then return end

	local to = position - eye
	local wantYaw = math.atan2(-to.X, -to.Z)
	local wantPitch = math.atan2(to.Y, math.sqrt(to.X * to.X + to.Z * to.Z))
	local delta = wantYaw - controller.yaw
	delta = (delta + math.pi) % (math.pi * 2) - math.pi
	local k = math.clamp(alpha, 0, 1)

	controller.yaw = controller.yaw + delta * k
	controller.pitch = math.clamp(controller.pitch + (wantPitch - controller.pitch) * k, -math.pi / 2, math.pi / 2)
end

local function canAttack()
	local hands = mc.Hands
	if not hands or hands.using then return false end

	local inventory = getInventory()
	local item = inventory and inventory.hotbar and inventory.hotbar[inventory.selected or 1]
	local def = itemDef(item)
	local kind = def and def.kind

	return kind ~= 'shield' and kind ~= 'eat' and kind ~= 'bow' and kind ~= 'crossbow' and kind ~= 'spyglass'
end

local function attack(best)
	local controller = getController()
	local state = controller and controller.state
	local hands = mc.Hands
	if not state or not hands or not canAttack() then return end
	if controller.tickCount == LastAttackTick then return end

	local success, strength = pcall(hands.strength)
	if not success or type(strength) ~= 'number' or strength < MinStrength.Value then return end

	local entity = best.entity
	local id = entity.Character and entity.Character:GetAttribute('EntityId')
	local eye = getEye()
	if not id or not eye then return end

	local st = {
		fall = state.fallDistance,
		ground = state.onGround,
		sprint = state.sprinting,
		water = state.inWater,
		gliding = state.gliding,
		vel = state.vel,
		look = getLook(),
		swap = false,
		pos = state.pos,
		predicted = not isHitBlocked(eye, entity)
	}

	if not netSend({a = 'attack', target = id, st = st}) then return end

	hands.swing = os.clock()
	hands.attackReset = controller.tickCount
	LastAttackTick = controller.tickCount

	for _, hook in store.attackPostHooks do
		task.spawn(hook, entity.Character)
	end
end

AttackAura = vape.Categories.Combat:CreateModule({
	Name = 'AttackAura',
	Function = function(callback)
		LastAttackTick = -math.huge
		if not callback then return end

		AttackAura:Clean(runService.RenderStepped:Connect(function(dt)
			local controller = getController()
			local state = controller and controller.state
			if not state or controller.locked or controller.frozen then return end

			local best = findTarget(not Targets.Walls.Enabled)
			if not best then return end

			if Rotation.Enabled then
				local alpha = 1 - math.exp(-math.max(Smooth.Value, 0.15) * dt * 60)
				aimAt(best.aim, alpha)
			end

			if AutoSwing.Enabled then
				attack(best)
			end
		end))
	end,
	Tooltip = 'Attacks players in range through the engine attack\npacket, with optional silent rotation'
})
Targets = AttackAura:CreateTargets({
	Players = true,
	NPCs = true
})
Range = AttackAura:CreateSlider({
	Name = 'Range',
	Min = 1,
	Max = 8,
	Default = 4,
	Suffix = 'b'
})
MinStrength = AttackAura:CreateSlider({
	Name = 'Min strength',
	Min = 0.1,
	Max = 1,
	Default = 0.9,
	Decimal = 100
})
Smooth = AttackAura:CreateSlider({
	Name = 'Smooth',
	Min = 0.15,
	Max = 1,
	Default = 0.5,
	Decimal = 100
})
AutoSwing = AttackAura:CreateToggle({
	Name = 'Auto swing',
	Default = true
})
Rotation = AttackAura:CreateToggle({
	Name = 'Rotation',
	Default = true
})
