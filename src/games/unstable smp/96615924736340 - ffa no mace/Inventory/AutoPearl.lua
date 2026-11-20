run(function()
	local AutoPearl
	local Health
	local Distance
	local SearchInventory
	local LastAction = 0

	local function isPearl(item)
		local id = tostring(item.id):lower()
		return id:find('ender_pearl', 1, true) or id:find('enderpearl', 1, true)
	end

	local function findPearl()
		local inventory = getInventory()
		local hotbar = inventory and inventory.hotbar
		if not hotbar then return end

		for index = 1, 9 do
			if isPearl(hotbar[index]) then
				return hotbar[index], 'hotbar', index
			end
		end

		if SearchInventory.Enabled and inventory.inventory then
			for index, item in inventory.inventory do
				if isPearl(item) then
					return item, 'inventory', index
				end
			end
		end
	end

	local function closestTarget()
		local character = entitylib.character
		local root = character and character.RootPart
		if not root then return nil end

		local closest
		for _, entity in entitylib.List do
			local part = entity.RootPart
			if part and entity.Targetable then
				local distance = (part.Position - root.Position).Magnitude
				if not closest or distance < closest then
					closest = distance
				end
			end
		end

		return closest
	end

	AutoPearl = vape.Categories.Inventory:CreateModule({
		Name = 'AutoPearl',
		Function = function(callback)
			if not callback then return end

			AutoPearl:Clean(runService.Heartbeat:Connect(function()
				if not entitylib.isAlive then return end
				if os.clock() - LastAction < 0.5 then return end

				local hands = mc.Hands
				if hands and hands.using then return end

				local character = entitylib.character
				local low = character and (character.Health / math.max(character.MaxHealth, 1)) * 100 <= Health.Value
				local closest = closestTarget()

				if not low and not (closest and closest > Distance.Value) then return end

				local item, source, slot = findPearl()
				if not item then return end
				LastAction = os.clock()

				if source == 'inventory' then
					local target = freeHotbarSlot()
					if target then moveToHotbar(slot, target) end
					return
				end

				if not selectSlot(slot) then return end

				local camera = workspace.CurrentCamera
				local look = camera and camera.CFrame.LookVector or Vector3.new(0, 0, -1)
				netSend({a = 'use', hand = 'main', look = Vector3.new(look.X, look.Y + 0.4, look.Z).Unit, item = item.id})
			end))
		end,
		Tooltip = 'Throws an ender pearl away from a fight when your\nhealth gets low or the enemy is far away'
	})
	Health = AutoPearl:CreateSlider({
		Name = 'Health',
		Min = 1,
		Max = 100,
		Default = 40,
		Suffix = '%'
	})
	Distance = AutoPearl:CreateSlider({
		Name = 'Distance',
		Min = 5,
		Max = 60,
		Default = 20,
		Suffix = function(val)
			return val == 1 and 'block' or 'blocks'
		end
	})
	SearchInventory = AutoPearl:CreateToggle({
		Name = 'Search inventory',
		Default = true
	})
end)
