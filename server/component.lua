local _statuses = {}

CreateThread(function()
	RegisterChatCommands()
	registerUsables()
	RegisterCallbacks()

	plsr.Middleware:Add("Characters:Logout", function(source)
		local char = plsr.Fetch:CharacterSource(source)
		if char ~= nil then
			local p = promise.new()
			plsr.Callbacks:ClientCallback(source, "Status:StoreValues", {}, function(vals)
				local status = char:GetData("Status") or {}
				for k, v in pairs(vals) do
					status[k] = v
				end
				char:SetData("Status", status)
				p:resolve(true)
			end)
			Citizen.Await(p)
		end
	end, 1)
end)

STATUS = {
	Register = function(self, name, max, icon, tick, modify)
		table.insert(_statuses, {
			name = name,
			max = max,
			icon = icon,
			tick = tick,
			modify = modify,
		})
	end,
	Get = {
		All = function(self)
			return _statuses
		end,
		Single = function(self, name)
			for k, v in ipairs(_statuses) do
				if v.name == name then
					return v
				end
			end
		end,
	},
	Modify = {
		Add = function(self, source, name, value, addCd, isForced)
			plsr.Callbacks:ClientCallback(source, "Status:Modify", {
				name = name,
				value = math.abs(value),
				addCd = addCd,
				isForced = isForced,
			})
		end,
		Remove = function(self, source, name, value, addCd, isForced)
			plsr.Callbacks:ClientCallback(source, "Status:Modify", {
				name = name,
				value = -(math.abs(value)),
				addCd = addCd,
				isForced = isForced,
			})
		end,
	},
	Set = function(self, source, name, value)
		local char = plsr.Fetch:CharacterSource(source)
		if char ~= nil then
			local status = char:GetData("Status")
			if status == nil then
				status = {}
			end
			status[name] = value
			char:SetData("Status", status)
			TriggerClientEvent("Status:Client:Update", source, name, value)
		end
	end,
}

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Status", STATUS)
end)

RegisterServerEvent("Status:Server:Update", function(data)
	local char = plsr.Fetch:CharacterSource(source)
	if char ~= nil then
		local status = char:GetData("Status")
		if status == nil then
			status = {}
		end
		status[data.status] = data.value
		char:SetData("Status", status)
	end
end)

RegisterServerEvent("Status:Server:StoreAll", function(data)
	local char = plsr.Fetch:CharacterSource(source)
	if char ~= nil then
		local status = char:GetData("Status") or {}
		for k, v in pairs(data) do
			status[k] = v
		end
		char:SetData("Status", status)
	end
end)