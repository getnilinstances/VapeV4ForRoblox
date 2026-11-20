local HitSwap
local HoldTicks
local PreviousSlot
local RestoreAt

local function findAxe()
	local inventory = getInventory()
	local hotbar = inventory and inventory.hotbar
	if not hotbar then return nil end

	for slot = 1, 9 do
		local def = itemDef(hotbar[slot])
		if def and (def.kind == 'axe' or def.disablesShield) then
			return slot
		end
	end
end

HitSwap = vape.Categories.Combat:CreateModule({
	Name = 'HitSwap',
	Function = function(callback)
		if not callback then return end

		local hook = function()
			if RestoreAt then return end

			local inventory = getInventory()
			if not inventory or not inventory.hotbar then return end

			local selected = inventory.selected or 1
			local def = itemDef(inventory.hotbar[selected])
			if not def or def.kind ~= 'sword' then return end

			local slot = findAxe()
			if not slot or slot == selected then return end

			PreviousSlot = selected
			if not selectSlot(slot) then
				PreviousSlot = nil
				return
			end

			RestoreAt = os.clock() + (HoldTicks.Value / 20)
		end

		store.installAttackHook()
		table.insert(store.attackPostHooks, hook)
		HitSwap:Clean(runService.Heartbeat:Connect(function()
			if not RestoreAt or os.clock() < RestoreAt then return end

			if PreviousSlot then
				selectSlot(PreviousSlot)
			end

			PreviousSlot = nil
			RestoreAt = nil
		end))
		HitSwap:Clean(function()
			removeHook(store.attackPostHooks, hook)

			if RestoreAt and PreviousSlot then
				selectSlot(PreviousSlot)
			end

			PreviousSlot = nil
			RestoreAt = nil
		end)
	end,
	Tooltip = 'Swaps to a shield breaking axe right after a sword\nhit and swaps back a few ticks later'
})
HoldTicks = HitSwap:CreateSlider({
	Name = 'Hold ticks',
	Min = 1,
	Max = 6,
	Default = 2,
	Suffix = 't'
})
