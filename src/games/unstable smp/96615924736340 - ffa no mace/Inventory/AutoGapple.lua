local AutoGapple
local Health
local SearchInventory
local LastAction = 0

local function score(item)
	local id = tostring(item.id):lower()
	if id:find('enchanted_golden_apple', 1, true) or id:find('enchanted_gapple', 1, true) then return 100 end
	if id:find('golden_apple', 1, true) or id:find('gapple', 1, true) then return 50 end
	return nil
end

local function findBest()
	local inventory = getInventory()
	local hotbar = inventory and inventory.hotbar
	if not hotbar then return end

	local bestItem, bestScore, source, slot

	local function consider(item, from, index)
		local value = item and score(item)
		if value and (not bestScore or value > bestScore) then
			bestItem, bestScore, source, slot = item, value, from, index
		end
	end

	for index = 1, 9 do
		consider(hotbar[index], 'hotbar', index)
	end

	if SearchInventory.Enabled and inventory.inventory then
		for index, item in inventory.inventory do
			consider(item, 'inventory', index)
		end
	end

	return bestItem, source, slot
end

AutoGapple = vape.Categories.Inventory:CreateModule({
	Name = 'AutoGapple',
	Function = function(callback)
		if not callback then return end

		AutoGapple:Clean(runService.Heartbeat:Connect(function()
			if not entitylib.isAlive then return end
			if os.clock() - LastAction < 0.4 then return end

			local hands = mc.Hands
			if hands and hands.using then return end

			local character = entitylib.character
			if character and (character.Health / math.max(character.MaxHealth, 1)) * 100 > Health.Value then return end

			local item, source, slot = findBest()
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
			local controller = mc.Controller

			if hands then
				hands.using = {
					kind = 'eat',
					hand = 'main',
					start = (controller and controller.tickCount) or 0,
					id = item.id
				}
			end

			netSend({a = 'useStart', hand = 'main', look = look, item = item.id})
			handsRefresh()
		end))
	end,
	Tooltip = 'Eats a golden apple when your health gets low'
})
Health = AutoGapple:CreateSlider({
	Name = 'Health',
	Min = 1,
	Max = 100,
	Default = 50,
	Suffix = '%'
})
SearchInventory = AutoGapple:CreateToggle({
	Name = 'Search inventory',
	Default = true
})
