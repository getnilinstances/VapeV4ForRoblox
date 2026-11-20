local FastUse
local Speed
local Last = 0

FastUse = vape.Categories.Blatant:CreateModule({
	Name = 'FastUse',
	Function = function(callback)
		if not callback then return end
		Last = os.clock()

		FastUse:Clean(runService.Heartbeat:Connect(function()
			local now = os.clock()
			local delta = now - Last
			Last = now
			if delta <= 0 or delta > 0.5 then return end

			local hands = mc.Hands
			local using = hands and hands.using
			if not using or type(using.start) ~= 'number' then return end
			if using.kind ~= 'eat' and using.kind ~= 'drink' then return end

			using.start = using.start - (Speed.Value - 1) * delta * 20
		end))
	end,
	Tooltip = 'Consumes food and potions faster'
})
Speed = FastUse:CreateSlider({
	Name = 'Speed',
	Min = 1,
	Max = 4,
	Default = 1.5,
	Decimal = 10
})
