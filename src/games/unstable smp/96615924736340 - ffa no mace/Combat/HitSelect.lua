run(function()
	local HitSelect
	local Ratio
	local MinStrength

	HitSelect = vape.Categories.Combat:CreateModule({
		Name = 'HitSelect',
		Function = function(callback)
			if not callback then return end

			local hook = function(target)
				if not entitylib.isAlive or not target then return end

				local character = entitylib.character
				local root = character and character.RootPart
				local part = target.RootPart
				if not root or not part then return end

				-- Hold the swing back while the target is still outside the reach
				-- envelope we would actually connect at.
				local reach = (mc.Controller and mc.Controller.reach) or 3
				if (part.Position - root.Position).Magnitude > reach * Ratio.Value then
					return false
				end

				local hands = mc.Hands
				if hands and type(hands.strength) == 'function' then
					local success, strength = pcall(hands.strength)
					if success and type(strength) == 'number' and strength < MinStrength.Value then
						return false
					end
				end
			end

			store.installAttackHook()
			table.insert(store.attackHooks, hook)
			HitSelect:Clean(function()
				removeHook(store.attackHooks, hook)
			end)
		end,
		Tooltip = 'Holds your attacks back until the target is in\nrange and your cooldown is almost full'
	})
	Ratio = HitSelect:CreateSlider({
		Name = 'Range ratio',
		Min = 0.5,
		Max = 1,
		Default = 0.9,
		Decimal = 100
	})
	MinStrength = HitSelect:CreateSlider({
		Name = 'Min strength',
		Min = 0.5,
		Max = 1,
		Default = 0.95,
		Decimal = 100
	})
end)
