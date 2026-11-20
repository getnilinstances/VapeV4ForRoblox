local Surround
local Material

local offsets = {
	Vector3.new(1, 0, 0),
	Vector3.new(-1, 0, 0),
	Vector3.new(0, 0, 1),
	Vector3.new(0, 0, -1)
}
local lastPlace = 0

local function place()
	local character = entitylib.character
	local root = character and character.RootPart
	if not root then return end

	local controller = mc.Controller
	local state = controller and controller.state
	if state and not state.onGround then return end

	local id = Material.Value == 'Obsidian' and 'obsidian' or 'cobweb'
	local slot = hotbarSlot(id)
	if not slot then return end

	local inventory = getInventory()
	local previous = inventory and inventory.selected
	if not selectSlot(slot) then return end

	local origin = root.Position
	task.defer(function()
		for _, offset in offsets do
			local cell = Vector3.new(math.floor(origin.X + offset.X), math.floor(origin.Y - 1), math.floor(origin.Z + offset.Z))
			local look = (cell + Vector3.new(0.5, 0.5, 0.5) - origin).Unit
			netSend({a = 'use', hand = 'main', look = look, item = id, cell = cell})
		end

		task.delay(0.05, function()
			if previous then
				selectSlot(previous)
			end
		end)
	end)
end

Surround = vape.Categories.Combat:CreateModule({
	Name = 'Surround',
	Function = function(callback)
		if not callback then return end

		Surround:Clean(runService.Heartbeat:Connect(function()
			if not entitylib.isAlive then return end
			if os.clock() - lastPlace < 0.3 then return end

			lastPlace = os.clock()
			place()
		end))
	end,
	Tooltip = 'Places blocks around your feet to trap whoever\nis pushing you'
})
Material = Surround:CreateDropdown({
	Name = 'Material',
	List = {'Obsidian', 'Cobweb'}
})
