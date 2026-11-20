local AutoTotem
local Health
local SearchInventory
local LastAction = 0

local function healthPercent()
	local character = entitylib.character
	if not character then return 100 end
	return (character.Health / math.max(character.MaxHealth, 1)) * 100
end

AutoTotem = vape.Categories.Inventory:CreateModule({
	Name = 'AutoTotem',
	Function = function(callback)
		if not callback then return end

		AutoTotem:Clean(runService.Heartbeat:Connect(function()
			if not entitylib.isAlive then return end
			if os.clock() - LastAction < 0.15 then return end

			local inventory = getInventory()
			if not inventory or not inventory.hotbar then return end

			local offhand = inventory.offhand
			if offhand and tostring(offhand.id):lower() == 'totem_of_undying' then return end
			if healthPercent() > Health.Value then return end

			local slot = hotbarSlot('totem_of_undying')
			if slot then
				LastAction = os.clock()

				if inventory.selected == slot then
					swapOffhandSlot(nil)
				else
					swapOffhandSlot(slot)
				end

				return
			end

			if not SearchInventory.Enabled then return end

			local stored = inventorySlot('totem_of_undying')
			if not stored then return end

			local target = freeHotbarSlot()
			if target then
				LastAction = os.clock()
				moveToHotbar(stored, target)
			end
		end))
	end,
	Tooltip = 'Moves a totem of undying into your offhand\nwhen your health gets low'
})
Health = AutoTotem:CreateSlider({
	Name = 'Health',
	Min = 1,
	Max = 100,
	Default = 100,
	Suffix = '%'
})
SearchInventory = AutoTotem:CreateToggle({
	Name = 'Search inventory',
	Default = true
})
