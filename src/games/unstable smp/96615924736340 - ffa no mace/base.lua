local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end
local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new('BindableEvent')
		return self[index]
	end
})

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local getfontbounds = vape.Libraries.getfontbounds

local mc = {
	Config = nil, Physics = nil, Items = nil, Net = nil, Controller = nil, World = nil,
	Hands = nil, Input = nil, UIKit = nil, FX = nil, Skins = nil, WeaponSkins = nil,
	WeaponSkinFX = nil, Visuals = nil, Effects = nil, Assets = nil, Action = nil, State = nil
}
local store = {
	attackReach = 0,
	attackReachUpdate = 0,
	hand = {},
	inventory = {inventory = {}, hotbar = {}, selected = 1, offhand = nil},
	killauraTarget = nil,
	matchState = 0,
	tools = {}
}
local Reach = {}
local NoSlowdown = {}
local Killaura = {}
local BLOCK = 16

-- Attack dispatch shared by the modules: features such as hit select, hit swap
-- and wtap have to see every attack, whether it came from aura, triggerbot or a click.
store.attackHooks = {}
store.attackPostHooks = {}
store.netHooks = {}
local attackHookInstalled = false
local netHookInstalled = false

local function getShared()
	return replicatedStorage:FindFirstChild('MC')
end

local function getClient()
	local scripts = lplr:FindFirstChild('PlayerScripts')
	return scripts and scripts:FindFirstChild('MC')
end

-- The MC engine lives under ReplicatedStorage.MC (shared) and PlayerScripts.MC (client).
-- Both are required before any module touches engine state, so everything waits on this.
local function requireModule(folder, name)
	local module = folder and folder:WaitForChild(name, 30)
	if not module then return nil end
	local success, returned = pcall(require, module)
	return success and returned or nil
end

local requiredEngine = {'Config', 'Items', 'Net', 'Controller', 'World', 'Hands', 'Input'}

local function missingEngine()
	local missing = {}

	for _, name in requiredEngine do
		if not mc[name] then
			table.insert(missing, name)
		end
	end

	return missing
end

local function fillEngine()
	local sharedFolder = getShared()
	local clientFolder = getClient()

	if sharedFolder then
		mc.Config = mc.Config or requireModule(sharedFolder, 'Config')
		mc.Physics = mc.Physics or requireModule(sharedFolder, 'Physics')
		mc.Items = mc.Items or requireModule(sharedFolder, 'Items')
		mc.Effects = mc.Effects or requireModule(sharedFolder, 'Effects')
		mc.Skins = mc.Skins or requireModule(sharedFolder, 'Skins')
		mc.WeaponSkins = mc.WeaponSkins or requireModule(sharedFolder, 'WeaponSkins')
		mc.Assets = mc.Assets or sharedFolder:FindFirstChild('Assets')

		local remotes = sharedFolder:FindFirstChild('Remotes')
		if remotes then
			mc.Action = mc.Action or remotes:FindFirstChild('Action')
			mc.State = mc.State or remotes:FindFirstChild('State')
		end
	end

	if clientFolder then
		mc.Net = mc.Net or requireModule(clientFolder, 'Net')
		mc.Controller = mc.Controller or requireModule(clientFolder, 'Controller')
		mc.World = mc.World or requireModule(clientFolder, 'World')
		mc.Hands = mc.Hands or requireModule(clientFolder, 'Hands')
		mc.Input = mc.Input or requireModule(clientFolder, 'Input')
		mc.UIKit = mc.UIKit or requireModule(clientFolder, 'UIKit')
		mc.FX = mc.FX or requireModule(clientFolder, 'FX')
		mc.Visuals = mc.Visuals or requireModule(clientFolder, 'Visuals')
		mc.WeaponSkinFX = mc.WeaponSkinFX or requireModule(clientFolder, 'WeaponSkinFX')
	end

	if mc.Config and mc.Config.BLOCK then
		BLOCK = mc.Config.BLOCK
	end
end

run(function()
	fillEngine()

	-- The engine's MC folder is not always there the instant we inject. Every
	-- feature reads mc.* at call time, so keep trying instead of leaving them
	-- bound to nil modules and silently doing nothing.
	if #missingEngine() == 0 then return end

	task.spawn(function()
		local deadline = os.clock() + 120

		while os.clock() < deadline do
			task.wait(1)
			fillEngine()

			if #missingEngine() == 0 then
				if store.installAttackHook then store.installAttackHook() end
				if store.installNetHook then store.installNetHook() end
				pcall(vape.CreateNotification, vape, 'unstable smp', 'Engine connected, features are live', 4)
				return
			end
		end

		store.missingEngine = missingEngine()
		pcall(vape.CreateNotification, vape, 'unstable smp', 'Engine modules missing: ' .. table.concat(store.missingEngine, ', '), 30, 'alert')
	end)
end)

local function readItem(raw)
	if type(raw) ~= 'string' or raw == '' then return nil end
	local success, decoded = pcall(function()
		return httpService:JSONDecode(raw)
	end)
	return success and type(decoded) == 'table' and decoded or nil
end

local function getHealth(char)
	local hp = char:GetAttribute('Health')
	if type(hp) == 'number' then
		local max = char:GetAttribute('MaxHealth')
		return hp, type(max) == 'number' and max or math.max(hp, 20)
	end
	local hum = char:FindFirstChildOfClass('Humanoid')
	if hum then
		return hum.Health, hum.MaxHealth
	end
	return 0, 20
end

local function getShield(char)
	local total = 0
	for name, value in char:GetAttributes() do
		if name:find('Shield') and type(value) == 'number' and value > 0 then
			total += value
		end
	end
	return total
end

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end

local function getTableSize(tab)
	local index = 0
	for _ in tab do
		index += 1
	end
	return index
end

local frictionTable, oldfrict = {}, {}
local frictionConnection
local frictionState

local function modifyVelocity(part)
	if part:IsA('BasePart') and part.Name ~= 'HumanoidRootPart' and not oldfrict[part] then
		oldfrict[part] = part.CustomPhysicalProperties or 'none'
		part.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.2, 0.5, 1, 1)
	end
end

local function updateVelocity(force)
	local newState = getTableSize(frictionTable) > 0
	if frictionState ~= newState or force then
		if frictionConnection then
			frictionConnection:Disconnect()
		end

		if newState then
			if entitylib.isAlive then
				for _, part in entitylib.character.Character:GetDescendants() do
					modifyVelocity(part)
				end
				frictionConnection = entitylib.character.Character.DescendantAdded:Connect(modifyVelocity)
			end
		else
			for part, value in oldfrict do
				if part.Parent then
					part.CustomPhysicalProperties = value ~= 'none' and value or nil
				end
			end
			table.clear(oldfrict)
		end
	end
	frictionState = newState
end

local function getInventory()
	return mc.Hands and mc.Hands.inv or store.inventory
end

local function syncStore()
	local inventory = getInventory()
	if inventory then
		store.inventory = inventory
		local item = inventory.hotbar and inventory.hotbar[inventory.selected or 1]
		store.hand = {
			item = item,
			tool = item,
			toolType = item and item.id or 'none',
			toolName = item and item.id or 'none'
		}
	end
end

local function installAttackHook()
	local hands = mc.Hands
	if attackHookInstalled or not hands or type(hands.attack) ~= 'function' then return end
	attackHookInstalled = true

	local oldattack = hands.attack
	hands.attack = function(target, ...)
		for _, hook in store.attackHooks do
			local success, allowed = pcall(hook, target)
			if success and allowed == false then return false end
		end

		local args = table.pack(...)
		local result = oldattack(target, table.unpack(args, 1, args.n))

		for _, hook in store.attackPostHooks do
			task.spawn(hook, target)
		end

		return result
	end
end

-- Outgoing payloads go through one wrapper as well, so several modules can
-- rewrite the same packet without fighting over the Net.send reference.
local function installNetHook()
	local net = mc.Net
	if netHookInstalled or not net or type(net.send) ~= 'function' then return end
	netHookInstalled = true

	local oldsend = net.send
	net.send = function(payload)
		if type(payload) == 'table' then
			for _, hook in store.netHooks do
				pcall(hook, payload)
			end
		end

		return oldsend(payload)
	end
end

local function removeHook(list, hook)
	local index = table.find(list, hook)
	if index then
		table.remove(list, index)
	end
end

local function netSend(payload)
	local net = mc.Net
	if not net or type(net.send) ~= 'function' then return false end
	return pcall(net.send, payload)
end

local function itemDef(item)
	if type(item) ~= 'table' or not mc.Items or type(mc.Items.def) ~= 'function' then return nil end
	local success, def = pcall(mc.Items.def, item)
	return success and type(def) == 'table' and def or nil
end

local function handsRefresh()
	local hands = mc.Hands
	if not hands or type(hands.onChanged) ~= 'table' then return end
	for _, func in hands.onChanged do
		task.spawn(func)
	end
end

local function selectSlot(slot)
	local hands = mc.Hands
	if not hands or type(hands.select) ~= 'function' then return false end
	return pcall(hands.select, slot)
end

local function hotbarSlot(id)
	local inventory = getInventory()
	local hotbar = inventory and inventory.hotbar
	if not hotbar then return nil end

	for slot = 1, 9 do
		local item = hotbar[slot]
		if item and tostring(item.id):lower():find(id, 1, true) then
			return slot
		end
	end
end

local function inventorySlot(id)
	local inventory = getInventory()
	local storage = inventory and inventory.inventory
	if not storage then return nil end

	for slot, item in storage do
		if item and tostring(item.id):lower():find(id, 1, true) then
			return slot
		end
	end
end

local function freeHotbarSlot()
	local inventory = getInventory()
	local hotbar = inventory and inventory.hotbar
	if not hotbar then return nil end

	for slot = 1, 9 do
		if not hotbar[slot] then return slot end
	end

	for slot = 1, 9 do
		local item = hotbar[slot]
		local def = itemDef(item)
		local kind = def and def.kind
		if item and kind ~= 'sword' and kind ~= 'axe' and kind ~= 'mace' then
			return slot
		end
	end

	return 9
end

local function moveToHotbar(source, target)
	local inventory = getInventory()
	if not inventory or not inventory.hotbar or not inventory.inventory then return false end

	local item = inventory.inventory[source]
	if not item then return false end

	inventory.inventory[source] = inventory.hotbar[target]
	inventory.hotbar[target] = item

	netSend({a = 'inv', op = 'open'})
	task.defer(function()
		netSend({a = 'inv', op = 'key', slot = source + 10, target = target})
		task.defer(function()
			netSend({a = 'inv', op = 'close'})
		end)
	end)
	handsRefresh()
	return true
end

local function swapOffhandSlot(slot)
	local inventory = getInventory()
	if not inventory or not inventory.hotbar then return false end

	local selected = inventory.selected or 1
	if slot and slot ~= selected then
		return selectSlot(slot)
	end

	local previous = inventory.hotbar[selected]
	inventory.hotbar[selected] = inventory.offhand
	inventory.offhand = previous
	netSend({a = 'swap'})
	handsRefresh()
	return true
end

store.installAttackHook = installAttackHook
store.installNetHook = installNetHook

installAttackHook()
installNetHook()

run(function()
	local oldstart = entitylib.start
	local function customEntity(ent)
		if ent:HasTag('inventory-entity') or ent:HasTag('Corpse') then
			return
		end

		entitylib.addEntity(ent, playersService:GetPlayerFromCharacter(ent), nil)
	end

	entitylib.start = function()
		oldstart()
		if entitylib.Running then
			for _, ent in collectionService:GetTagged('entity') do
				customEntity(ent)
			end
			table.insert(entitylib.Connections, collectionService:GetInstanceAddedSignal('entity'):Connect(customEntity))
			table.insert(entitylib.Connections, collectionService:GetInstanceRemovedSignal('entity'):Connect(function(ent)
				entitylib.removeEntity(ent)
			end))
		end
	end

	entitylib.targetCheck = function(entity)
		if entity.TeamCheck then
			return entity:TeamCheck()
		end
		if entity.NPC then return true end
		if isFriend(entity.Player) then return false end
		if not select(2, whitelist:get(entity.Player)) then return false end
		return lplr:GetAttribute('Team') ~= entity.Player:GetAttribute('Team')
	end

	entitylib.getUpdateConnections = function(entity)
		local char = entity.Character
		local list = {
			char:GetAttributeChangedSignal('Health'),
			char:GetAttributeChangedSignal('MaxHealth'),
			{
				Connect = function()
					entity.Friend = entity.Player and isFriend(entity.Player) or nil
					entity.Target = entity.Player and isTarget(entity.Player) or nil
					return {Disconnect = function() end}
				end
			}
		}

		for name, value in char:GetAttributes() do
			if name:find('Shield') and type(value) == 'number' then
				table.insert(list, char:GetAttributeChangedSignal(name))
			end
		end

		return list
	end

	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end

		entitylib.EntityThreads[char] = task.spawn(function()
			local hum = char:WaitForChild('Humanoid', 10)
			local humrootpart = hum and hum:WaitForChild('RootPart', workspace.StreamingEnabled and math.huge or 10) or char:WaitForChild('PrimaryPart', 10)
			local head = char:WaitForChild('Head', 10) or humrootpart

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = getHealth(char) + getShield(char),
					Head = head,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					HipHeight = (hum.HipHeight or 0.5) + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
					MaxHealth = char:GetAttribute('MaxHealth') or 100,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					TeamCheck = teamfunc
				}

				if plr == lplr then
					entity.AirTime = tick()
					entitylib.character = entity
					entitylib.isAlive = true
					entitylib.Events.LocalAdded:Fire(entity)
				else
					entity.Targetable = entitylib.targetCheck(entity)

					for _, connection in entitylib.getUpdateConnections(entity) do
						table.insert(entity.Connections, connection:Connect(function()
							entity.Health = getHealth(char) + getShield(char)
							entity.MaxHealth = char:GetAttribute('MaxHealth') or entity.MaxHealth
							entitylib.Events.EntityUpdated:Fire(entity)
						end))
					end

					table.insert(entitylib.List, entity)
					entitylib.Events.EntityAdded:Fire(entity)
				end
			end

			entitylib.EntityThreads[char] = nil
		end)
	end

	vape:Clean(entitylib.Events.LocalAdded:Connect(updateVelocity))
end)
entitylib.start()

run(function()
	local function refresh()
		syncStore()
		if mc.Controller and mc.Controller.state then
			store.matchState = mc.Controller.state.inMatch and 2 or 0
		end
	end

	local function bindHands()
		if mc.Hands and mc.Hands.onChanged then
			table.insert(mc.Hands.onChanged, refresh)
		end
		refresh()
	end

	bindHands()
	vape:Clean(entitylib.Events.LocalAdded:Connect(bindHands))
	vape:Clean(runService.Heartbeat:Connect(refresh))
end)

run(function()
	local kills = sessioninfo:AddItem('Kills')
	local deaths = sessioninfo:AddItem('Deaths')
	local wasAlive = true

	vape:Clean(runService.Heartbeat:Connect(function()
		if not entitylib.isAlive then
			if wasAlive then
				wasAlive = false
				deaths:Increment()
			end
			return
		end

		wasAlive = true
		local health = getHealth(entitylib.character.Character)
		if health <= 0 then
			entitylib.isAlive = false
		end
	end))
end)

for _, name in {'Fly', 'LongJump', 'Jesus', 'AutoRejoin', 'Disabler', 'MurderMystery', 'Parkour', 'Wallhop', 'Invisible'} do
	vape:Remove(name)
end
