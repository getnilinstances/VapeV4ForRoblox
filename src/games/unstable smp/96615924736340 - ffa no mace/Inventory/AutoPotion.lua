local AutoPotion
local Health
local SearchInventory
local LastAction = 0
local harmful = {'poison', 'harming', 'weakness', 'slowness', 'blindness', 'decay'}

local function score(item)
	local id = tostring(item.id):lower()
	for _, word in harmful do
		if id:find(word, 1, true) then return nil end
	end

	local value
	if id:find('instant_health', 1, true) then
		value = 100
	elseif id:find('healing', 1, true) then
		value = 95
	elseif id:find('regeneration', 1, true) then
		value = 80
	elseif id:find('absorption', 1, true) then
		value = 60
	end

	if not value then return nil end
	if id:find('splash', 1, true) then value = value - 10 end
	if id:find('lingering', 1, true) then value = value - 30 end
	return value
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

local function lookVector()
	local camera = workspace.CurrentCamera
	return camera and camera.CFrame.LookVector or Vector3.new(0, 0, -1)
end

local function startDrinking(item)
	local hands = mc.Hands
	local controller = mc.Controller
	if hands then
		hands.using = {
			kind = 'eat',
			hand = 'main',
			start = (controller and controller.tickCount) or 0,
			id = item.id
		}
	end

	netSend({a = 'useStart', hand = 'main', look = lookVector(), item = item.id})
	handsRefresh()
end

AutoPotion = vape.Categories.Inventory:CreateModule({
	Name = 'AutoPotion',
	Function = function(callback)
		if not callback then return end

		AutoPotion:Clean(runService.Heartbeat:Connect(function()
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

			if tostring(item.id):lower():find('splash', 1, true) then
				netSend({a = 'use', hand = 'main', look = lookVector(), item = item.id})
			else
				startDrinking(item)
			end
		end))
	end,
	Tooltip = 'Drinks or throws a healing potion when you get low'
})
Health = AutoPotion:CreateSlider({
	Name = 'Health',
	Min = 1,
	Max = 100,
	Default = 50,
	Suffix = '%'
})
SearchInventory = AutoPotion:CreateToggle({
	Name = 'Search inventory',
	Default = true
})
