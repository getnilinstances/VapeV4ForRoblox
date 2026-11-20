local HitSound
local SoundId
local Volume
local Pitch
local Player

local function build()
	if Player then return end
	Player = Instance.new('Sound')
	Player.Volume = Volume.Value
	Player.PlaybackSpeed = Pitch.Value
	Player.SoundId = SoundId.Value
	Player.Parent = vape.holder
end

HitSound = vape.Categories.Utility:CreateModule({
	Name = 'HitSound',
	Function = function(callback)
		if callback then
			build()
			HitSound:Clean(Player)
		else
			if Player then
				Player:Destroy()
				Player = nil
			end
		end
	end,
	Tooltip = 'Plays a sound when you hit an entity'
})
SoundId = HitSound:CreateTextBox({
	Name = 'Sound',
	Default = 'rbxassetid://131847726193504',
	Function = function(value)
		if Player then
			Player.SoundId = value
		end
	end,
	Darker = true
})
Volume = HitSound:CreateSlider({
	Name = 'Volume',
	Min = 0,
	Max = 5,
	Default = 1,
	Decimal = 10,
	Function = function(value)
		if Player then Player.Volume = value end
	end,
	Darker = true
})
Pitch = HitSound:CreateSlider({
	Name = 'Pitch',
	Min = 0.5,
	Max = 2,
	Default = 1,
	Decimal = 100,
	Function = function(value)
		if Player then Player.PlaybackSpeed = value end
	end,
	Darker = true
})
HitSound.Play = function()
	if HitSound.Enabled and Player then
		Player:Play()
	end
end
