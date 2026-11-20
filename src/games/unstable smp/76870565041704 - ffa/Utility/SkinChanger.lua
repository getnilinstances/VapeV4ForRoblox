local SkinChanger
local Skin

local lastApply = 0
local original = {}
local parts = {'Skin_head', 'Skin_body', 'Skin_arm_r', 'Skin_arm_l', 'Skin_leg_r', 'Skin_leg_l'}

local function getSkinNames()
	local names = {}
	local skins = mc.Skins

	if type(skins) == 'table' then
		for name, entry in skins do
			if type(entry) == 'table' and entry.tex then
				table.insert(names, name)
			end
		end
	end

	if #names == 0 then
		table.insert(names, 'STEVE')
	end

	table.sort(names)
	return names
end

local function paintPart(part, texture)
	if not part then return end

	if not original[part] then
		original[part] = {
			textureId = part:IsA('MeshPart') and part.TextureID or nil,
			decal = part:FindFirstChildOfClass('Decal') or part:FindFirstChildOfClass('Texture')
		}
	end

	if part:IsA('MeshPart') then
		part.TextureID = texture
		return
	end

	local decal = part:FindFirstChild('SkinOverride')
	if not decal then
		decal = Instance.new('Decal')
		decal.Name = 'SkinOverride'
		decal.Face = Enum.NormalId.Front
		decal.Parent = part
	end
	decal.Texture = texture
end

local function restore()
	local character = lplr.Character
	if not character then
		table.clear(original)
		return
	end

	for part, values in original do
		if part.Parent then
			pcall(function()
				if values.textureId and part:IsA('MeshPart') then
					part.TextureID = values.textureId
				end

				local decal = part:FindFirstChild('SkinOverride')
				if decal then
					decal:Destroy()
				end

				if values.decal and values.decal.Parent then
					values.decal.Texture = values.decal.Texture
				end
			end)
		end
	end

	table.clear(original)
end

local function apply(skinName)
	local entry = mc.Skins and mc.Skins[skinName]
	if type(entry) ~= 'table' or not entry.tex then return end

	local character = lplr.Character
	if not character then return end

	for _, name in parts do
		local part = character:FindFirstChild(name, true)
		if part then
			paintPart(part, entry.tex)
		end
	end

	for _, descendant in character:GetDescendants() do
		if descendant.Name == 'SkinOverride' and descendant:IsA('Decal') then
			descendant.Texture = entry.tex
		end
	end
end

SkinChanger = vape.Categories.Utility:CreateModule({
	Name = 'SkinChanger',
	Function = function(callback)
		if not callback then
			restore()
			return
		end

		lastApply = 0
		SkinChanger:Clean(lplr.CharacterAdded:Connect(function()
			task.wait(0.5)
			if SkinChanger.Enabled then
				table.clear(original)
				lastApply = 0
			end
		end))

		SkinChanger:Clean(runService.Heartbeat:Connect(function()
			if os.clock() - lastApply < 0.5 then return end
			lastApply = os.clock()
			apply(Skin.Value)
		end))
	end,
	Tooltip = 'Applies a client side skin to your character'
})
Skin = SkinChanger:CreateDropdown({
	Name = 'Skin',
	List = getSkinNames(),
	Function = function()
		table.clear(original)
		lastApply = 0
	end
})
