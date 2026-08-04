local _hungerTicks = 0
local _stressTicks = 0

AddEventHandler("Characters:Client:Spawn", function()
	CreateThread(function()
		local effectCount = 0
		while plsr.State.flags.loggedIn do
			local player = PlayerPedId()
			if not plsr.State.flags.isDead then
				local val = plsr.Status.Get:Single("PLAYER_THIRST").value or 100
				if val <= 25 then
					SetPlayerSprint(PlayerId(), false)
					if val == 0 and effectCount >= 500 then
						ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.4)
						local luck = math.random(100)
						if luck <= 20 then
							SetPedToRagdoll(player, 1500, 2000, 3, true, true, false)
						end
						plsr.Damage.Apply:StandardDamage(3, false)
						effectCount = 0
					elseif effectCount >= 1000 then
						ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.2)
						effectCount = 0
					else
						effectCount = effectCount + 1
					end
				else
					SetPlayerSprint(PlayerId(), true)
					if val - 25 > 0 then
						Wait(60000)
						effectCount = 0
					end
				end
				Wait(100)
			else
				Wait(1000)
			end
		end
	end)

	CreateThread(function()
		local effectCount = 0
		while plsr.State.flags.loggedIn do
			local player = PlayerPedId()
			if not plsr.State.flags.isDead then
				local val = plsr.Status.Get:Single("PLAYER_STRESS").value or 0
				local level = math.floor(val / 25)

				if val >= 40 then
					TriggerScreenblurFadeIn(200.0 * level)

					if level == 1 then
						Wait(600)
					elseif level == 2 then
						Wait(1200)
					elseif level == 3 then
						Wait(1800)
					else
						Wait(2500)
					end

					TriggerScreenblurFadeOut(200.0 * level)
					Wait(30000 - (1000 * (15 - (level * 2))))
				else
					Wait(10000)
				end
			else
				Wait(1000)
			end
		end
	end)
end)

RegisterNetEvent("Status:Client:updateStatus", function(need, action, amount)
	if action then
		plsr.Status.Modify:Add(need, tonumber(amount or 0), 2)
	else
		plsr.Status.Modify:Remove(need, tonumber(amount or 0))
	end
end)

-- Dear lua, die.
function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == "table" then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

local _strTickRunning = false

local _stressListener = nil
local _hpListener = nil

RegisterNetEvent("Status:Client:Ticks:Stress", function()
	if plsr.State.flags.stressTicks ~= nil then
		plsr.Buffs:ApplyUniqueBuff("stress_ticks", #(plsr.State.flags.stressTicks or {}), false, {
			customMax = #(plsr.State.flags.stressTicks or {}),
		})
	end
end)

AddEventHandler("Characters:Client:Spawn", function()
	CreateThread(function()
		if _strTickRunning then
			plsr.Logger:Trace("Status", "Stress Thread Running, Skipping Creation")
			return
		end

		_strTickRunning = true
		while plsr.State.flags.loggedIn do
			if plsr.State.flags.stressTicks ~= nil then
				local cst = plsr.Status.Get:Single("PLAYER_STRESS").value
				local max = 0

				if cst <= max then
					plsr.State.flags.stressTicks = nil
				else
					local gen = plsr.State.flags.stressTicks[1] or 0
					if cst - gen < max then
						gen = cst
					end

					if cst - gen >= max then
						plsr.Logger:Trace(
							"Status",
							string.format("Stress Tick: %s (Original: %s)", gen, plsr.State.flags.stressTicks[1])
						)
						plsr.Status.Modify:Remove("PLAYER_STRESS", tonumber(gen or 0), true)
					end

					local t = plsr.State.flags.stressTicks
					table.remove(t, 1)
					if #t > 0 then
						plsr.State.flags.stressTicks = t
					else
						plsr.State.flags.stressTicks = nil
					end
				end
				Wait(10000)
			else
				Wait(1000)
			end
		end
		_strTickRunning = false
	end)
end)

function RegisterStatuses()
	plsr.Status:Register("PLAYER_THIRST", 100, "whiskey-glass", "#07bdf0", true, function(change)
		if plsr.State.flags.ignorePLAYER_THIRST then
			if plsr.State.flags.ignorePLAYER_THIRST - 1 > 0 then
				plsr.State.flags.ignorePLAYER_THIRST = plsr.State.flags.ignorePLAYER_THIRST - 1
			else
				plsr.State.flags.ignorePLAYER_THIRST = nil
			end
			return
		end

		local player = PlayerPedId()
		if IsEntityDead(player) or plsr.State.flags.isDead then
			return
		end
		if change == nil then
			change = -1
		end

		local val = plsr.Status.Get:Single("PLAYER_THIRST").value or 100
		if val + change > 100 then
			val = 100
		elseif val + change < 0 then
			val = 0
		else
			val = val + change
		end

		plsr.Status.Set:Single("PLAYER_THIRST", val)
		TriggerEvent("Status:Client:Update", "PLAYER_THIRST", val)
		thirstTick = 0
	end, {
		id = 3,
		hideHigh = true,
		order = 6,
	})

	plsr.Status:Register("PLAYER_HUNGER", 100, "drumstick-bite", "#ca5fe8", true, function(change)
		if plsr.State.flags.ignorePLAYER_HUNGER then
			if plsr.State.flags.ignorePLAYER_HUNGER - 1 > 0 then
				plsr.State.flags.ignorePLAYER_HUNGER = plsr.State.flags.ignorePLAYER_HUNGER - 1
			else
				plsr.State.flags.ignorePLAYER_HUNGER = nil
			end
			return
		end

		local player = PlayerPedId()
		if IsEntityDead(player) or plsr.State.flags.isDead then
			return
		end

		if change == nil then
			change = -1
		end

		local val = plsr.Status.Get:Single("PLAYER_HUNGER").value or 100
		if val + change > 100 then
			val = 100
		elseif val + change < 0 then
			val = 0
		else
			val = val + change
		end
		plsr.Status.Set:Single("PLAYER_HUNGER", val)
		TriggerEvent("Status:Client:Update", "PLAYER_HUNGER", val)

		if val <= 25 then
			if val > 10 then
				if (GetEntityHealth(player) - 100) > 11 then
					plsr.Damage.Apply:StandardDamage(10, false)
				end
			else
				if (GetEntityHealth(player) - 100) > 1 then
					plsr.Damage.Apply:StandardDamage(1, false)
				else
					if _hungerTicks <= 10 then
						SetFlash(0, 0, 100, 10000, 100)
						_hungerTicks = _hungerTicks + 1
					else
						-- Kill Player
					end
				end
			end
		end

		hungerTick = 0
	end, {
		id = 2,
		hideHigh = true,
		order = 5,
	})

	plsr.Status:Register("PLAYER_STRESS", 0, "brain", "#de3333", false, function(change, force)
		if _stressTicks > 1 or force then
			if plsr.State.flags.ignorePLAYER_STRESS then
				if plsr.State.flags.ignorePLAYER_STRESS - 1 > 0 then
					plsr.State.flags.ignorePLAYER_STRESS = plsr.State.flags.ignorePLAYER_STRESS - 1
				else
					plsr.State.flags.ignorePLAYER_STRESS = nil
				end
				return
			end

			_stressTicks = 0

			local player = PlayerPedId()
			if IsEntityDead(player) or plsr.State.flags.isDead then
				return
			end

			if change == nil then
				change = -1
			end

			local val = plsr.Status.Get:Single("PLAYER_STRESS").value or 0
			if val + change > 100 then
				val = 100
			elseif val + change < 0 then
				val = 0
			else
				val = val + change
			end
			plsr.Status.Set:Single("PLAYER_STRESS", val)
			TriggerEvent("Status:Client:Update", "PLAYER_STRESS", val)
		else
			_stressTicks = _stressTicks + 1
		end
	end, {
		id = 4,
		inverted = true,
		hideZero = true,
		noReset = true,
		order = 4,
	})

	plsr.Status:Register("PLAYER_DRUNK", 0, "champagne-glasses", "#9D4C0B", false, function(change, force)
		local player = PlayerPedId()
		if IsEntityDead(player) or plsr.State.flags.isDead then
			return
		end

		local val = plsr.Status.Get:Single("PLAYER_DRUNK").value or 0

		if change == nil then
			if val and val >= 25 then
				change = -10
			else
				change = -6
			end
		end

		if val + change > 100 then
			val = 100
		elseif val + change < 0 then
			val = 0
		else
			val = val + change
		end

		if val >= 10 then
			plsr.State:SetPublicClientFlag('isDrunk', val)
		end

		plsr.Status.Set:Single("PLAYER_DRUNK", val)
		TriggerEvent("Status:Client:Update", "PLAYER_DRUNK", val)
	end, {
		id = 5,
		inverted = true,
		hideZero = true,
		noReset = true,
		order = 7,
	})
end

-- RegisterCommand('testdrunk', function(src, args)
-- 	plsr.Status.Set:Single("PLAYER_DRUNK", tonumber(args[1]))
-- end)

function LoadAnimSet(animSet)
	if not HasAnimSetLoaded(animSet) then
		RequestAnimSet(animSet)
		while not HasAnimSetLoaded(animSet) do
			Wait(50)
		end
	end
end

function LoadAnimSets(animSets)
	for k, v in ipairs(animSets) do
		LoadAnimSet(v)
	end
end
