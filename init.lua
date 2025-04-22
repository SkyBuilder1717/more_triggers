-- Please, leave a review on ContentDB!

more_triggers = {}
more_triggers.required_armor = {}

local have_armor = function(player, itemname)
	return core.get_inventory({type="detached", name=player:get_player_name().."_armor"}):contains_item("armor", itemname)
end

local armor_in_inventory = function(player)
	for _, inventory in ipairs(core.get_inventory({type="detached", name=player:get_player_name().."_armor"})) do
		local total_armor = 0
		total_armor = total_armor + 1
	end
	return total_armor
end

-- Biome trigger
awards.register_trigger("biome_visit", {
	type = "counted_key",
	progress = "@1/@2 visited biomes",
	auto_description = {"Visit an biome", "Visit @1 biomes"},
	get_key = function(self, def)
		if def.trigger.biome then
			if core.registered_biomes[def.trigger.biome] then
				return def.trigger.biome
			else
				error("That biome you specified does not exist!")
			end
		end
	end,
})
core.register_globalstep(function(dtime)
    for _, player in ipairs(core.get_connected_players()) do
       local meta = player:get_meta()
       local visited_biomes = core.deserialize(meta:get_string("trig_visited_biomes")) or {}
       local biome = core.get_biome_name(core.get_biome_data(player:get_pos()).biome)
       if table.indexof(visited_biomes, biome) == -1 then
           table.insert(visited_biomes, biome)
		   awards.notify_biome_visit(player, biome)
       end
       meta:set_string("trig_visited_biomes", core.serialize(visited_biomes))
	end
end)

-- Advanced chat trigger
awards.register_trigger("adv_chat", {
	type = "counted_key",
	progress = ("@1/@2 chat messages"),
	auto_description = { ("Send a chat message"), ("Chat @1 times") },
	get_key = function(self, def)
		if def.trigger.message then
			return def.trigger.message
		end
	end,
})
core.register_on_chat_message(function(name, message)
	local player = core.get_player_by_name(name)
	if not player:is_player() or string.find(message, "/")  then
		return
	end
	awards.notify_adv_chat(player, message)
end)

--[[
-- Armor trigger (in development)
if core.get_modpath("3d_armor") then
	awards.register_trigger("armor", {
		type = "counted_key",
		progress = "Wear an armor",
		auto_description = {"Wear an armor"},
		get_key = function(self, def)
			table.insert(more_triggers.required_armor, def.trigger.armor)
			return def.trigger.armor
		end,
	})
	core.register_globalstep(function(dtime)
		for _, player in ipairs(core.get_connected_players()) do
			local armor_ready = {}
			for i2, armor in ipairs(more_triggers.required_armor) do
				for i3, item in ipairs(armor) do
					if have_armor(player, item) then
						table.insert(armor_ready, item)
					end
				end
			end
			awards.notify_armor(player, armor_ready)
		end
	end)
end
]]--

-- Move trigger
if core.get_modpath("player_api") then
	awards.register_trigger("walk", {
		type = "counted_key",
		progress = "@1/@2 blocks passed",
		auto_description = {"Move once", "Move @1 blocks"},
		get_key = function(self, def)
			if def.trigger.animation then
				return def.trigger.animation
			end
		end,
	})
	core.register_globalstep(function(dtime)
		for _, player in ipairs(core.get_connected_players()) do
			local new_pos = player:get_pos()
			new_pos.x = math.ceil(new_pos.x)
			new_pos.z = math.ceil(new_pos.z)
			new_pos.y = math.ceil(new_pos.y)
			local old_pos = vector.from_string(player:get_meta():get_string("saved_pos"))
			if not old_pos then
				old_pos = {x = 0, y = 0, z = 0}
			end
			old_pos.x = math.ceil(old_pos.x)
			old_pos.y = math.ceil(old_pos.y)
			old_pos.z = math.ceil(old_pos.z)
			if not vector.equals(old_pos, new_pos) then
				awards.notify_walk(player, player_api.get_animation(player).animation)
				player:get_meta():set_string("saved_pos", vector.to_string(new_pos))
			end
		end
	end)
else
	awards.register_trigger("walk", {
		type = "counted",
		progress = "@1/@2 blocks passed",
		auto_description = {"Move once", "Move @1 blocks"},
	})
	core.register_globalstep(function(dtime)
		for _, player in ipairs(core.get_connected_players()) do
			local new_pos = player:get_pos()
			new_pos.x = math.ceil(new_pos.x)
			new_pos.z = math.ceil(new_pos.z)
			new_pos.y = math.ceil(new_pos.y)
			local old_pos = vector.from_string(player:get_meta():get_string("saved_pos"))
			if not old_pos then
				old_pos = {x = 0, y = 0, z = 0}
			end
			old_pos.x = math.ceil(old_pos.x)
			old_pos.y = math.ceil(old_pos.y)
			old_pos.z = math.ceil(old_pos.z)
			if not vector.equals(old_pos, new_pos) then
				awards.notify_walk(player)
				player:get_meta():set_string("saved_pos", vector.to_string(new_pos))
			end
		end
	end)
end

if core.get_modpath("mobs") then
	-- On kill mob trigger
	local function register_for_entity_death(name)
		local def = core.registered_entities[name]
		def.on_death = function(self, killer)
			if killer and killer:is_player() then
				awards.notify_mob_kill(killer, name)
			end
		end
	end
	awards.register_trigger("mob_kill", {
		type = "counted_key",
		progress = ("@1/@2 killed"),
		auto_description = {"Kill mob once", "Kill mob @1 times"},
		get_key = function(self, def)
			if def.trigger.mob then
				if core.registered_entities[def.trigger.mob] then
					register_for_entity_death(def.trigger.mob)
					return def.trigger.mob
				else
					error("The mob you specified does not exist!")
				end
			end
		end,
	})

	-- Player death from mob trigger
	awards.register_trigger("mob_death", {
		type = "counted_key",
		progress = ("@1/@2 died"),
		auto_description = {"Die from mob once", "Die from mob @1 times"},
		get_key = function(self, def)
			if def.trigger.mob then
				if core.registered_entities[def.trigger.mob] then
					return def.trigger.mob
				else
					error("The mob you specified does not exist!")
				end
			end
		end,
	})
	core.register_on_dieplayer(function(player, reason)
		core.chat_send_all(reason.object:get_entity_name())
		if reason.object and (not reason.object:is_player()) then
			awards.notify_mob_death(player, reason.object:get_entity_name())
		end
	end)
end

awards.register_award("walked",{
	title = ("walk"),
	description = ("walk 10 blocks"),
	icon = "player.png",
	difficulty = 0,
	trigger = {
		type = "walk",
		target = 10,
	}
})

awards.register_award("died",{
	title = ("die"),
	description = ("die from mese monster"),
	icon = "mobs_mese_monster_red.png",
	difficulty = 1,
	trigger = {
		type = "mob_death",
		mob = "mobs_monster:mese_arrow",
		target = 1,
	}
})