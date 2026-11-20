local BunnyHop
local Mode
local OldIsDown

local function wantsJump()
	if not entitylib.isAlive then return false end

	local controller = mc.Controller
	local state = controller and controller.state
	if not state or not state.onGround or state.gliding or state.inWater then return false end
	if Mode.Value == 'Sprint' and not state.sprinting then return false end

	return true
end

BunnyHop = vape.Categories.Blatant:CreateModule({
	Name = 'BunnyHop',
	Function = function(callback)
		local input = mc.Input

		if not callback then
			if input and OldIsDown and input.isDown ~= OldIsDown then
				input.isDown = OldIsDown
			end

			OldIsDown = nil
			return
		end

		if OldIsDown or not input or type(input.isDown) ~= 'function' then return end
		OldIsDown = input.isDown

		input.isDown = function(name)
			if name == 'jump' and wantsJump() then
				return true
			end

			return OldIsDown(name)
		end
	end,
	Tooltip = 'Jumps again the moment you touch the ground'
})
Mode = BunnyHop:CreateDropdown({
	Name = 'Mode',
	List = {'Always', 'Sprint'}
})
