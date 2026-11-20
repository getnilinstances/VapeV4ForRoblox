local AutoEat
local Hunger
local SearchInventory
local LastAction = 0

local function score(item)
	local def = itemDef(item)
	if def and def.kind == 'food' and type(def.food) == 'number' then
		return def.food
	end
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

AutoEat = vape.Categories.Inventory:CreateModule({
	Name = 'AutoEat',
	Function = function(callback)
		if not callback then return end

		AutoEat:Clean(runService.Heartbeat:Connect(function()
			if not entitylib.isAlive then return end
			if os.clock() - LastAction < 0.4 then return end

			local hands = mc.Hands
			if hands and hands.using then return end

			local food = lplr:GetAttribute('Food')
			if type(food) ~= 'number' or food > Hunger.Value then return end

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
	Tooltip = 'Eats the best food in your inventory when you\nare getting hungry'
})
Hunger = AutoEat:CreateSlider({
	Name = 'Hunger',
	Min = 1,
	Max = 20,
	Default = 15
})
SearchInventory = AutoEat:CreateToggle({
	Name = 'Search inventory',
	Default = true
})
