local Reach
local Value

Reach = vape.Categories.Combat:CreateModule({
	Name = 'Reach',
	Function = function(callback)
		if not (mc.Controller and mc.Controller.state) then return end
		local base = (mc.Items and mc.Items.SWORD_REACH) or 3.0
		mc.Controller.reach = callback and (base + Value.Value) or base
	end,
	Tooltip = 'Extends melee attack reach'
})
Value = Reach:CreateSlider({
	Name = 'Range',
	Min = 0,
	Max = 4,
	Default = 2,
	Decimal = 10,
	Function = function(val)
		if Reach.Enabled and mc.Controller then
			local base = (mc.Items and mc.Items.SWORD_REACH) or 3.0
			mc.Controller.reach = base + val
		end
	end,
	Suffix = function(val)
		return val == 1 and 'block' or 'blocks'
	end
})
