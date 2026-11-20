local ShieldBreaker

ShieldBreaker = vape.Categories.Combat:CreateModule({
	Name = 'ShieldBreaker',
	Function = function(callback)
		if not callback then return end

		local hook = function(payload)

			if payload.a == 'attack' then
				if type(payload.st) == 'table' then
					payload.st.swap = true
					payload.st.predicted = true
				else
					payload.swap = true
				end
			end
		end

		store.installNetHook()
		table.insert(store.netHooks, hook)
		ShieldBreaker:Clean(function()
			removeHook(store.netHooks, hook)
		end)
	end,
	Tooltip = 'Flags your attacks as shield breaking strikes so they\ngo through raised shields'
})
