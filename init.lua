magic_api = {}

local function get_power_list(player_powers)
    local list = {}
    for power, _ in pairs(player_powers) do
        table.insert(list, power)
    end
    return list
end

local powers = {}
function magic_api.register_power(name, def)
    --[[
        def: {
            image = ...,
            description = ...,
            on_activate = function(player)...end,
            on_deactivate = function(player)...end
        }
    ]]
    def.on_activate = def.on_activate or function(player) end
    def.on_deactivate = def.on_deactivate or function(player) end
    powers[name] = def
end
function magic_api.give_player_power(player, name)
    local meta = player:get_meta()
    local player_powers = minetest.deserialize(meta:get_string("magic_api:powers")) or {}
    player_powers[name] = true
    meta:set_string("magic_api:powers", minetest.serialize(player_powers))
end
function magic_api.revoke_player_power(player, name)
    local meta = player:get_meta()
    local player_powers = minetest.deserialize(meta:get_string("magic_api:powers")) or {}
    player_powers[name] = false
    meta:set_string("magic_api:powers", minetest.serialize(player_powers))
end
local active_powers = {}
function magic_api.activate_player_power(player, name)
    local meta = player:get_meta()
    local player_powers = minetest.deserialize(meta:get_string("magic_api:powers")) or {}
    if player_powers[name] then
        active_powers[player:get_player_name()] = name
        powers[name].on_activate(player)
        return true
    end
    return false
end
function magic_api.deactivate_player_power(player, name)
    local meta = player:get_meta()
    local player_powers = minetest.deserialize(meta:get_string("magic_api:powers")) or {}
    if player_powers[name] then
        active_powers[player:get_player_name()] = nil
        powers[name].on_deactivate(player)
        return true
    end
    return false
end
function magic_api.force_activate(player, name)
    powers[name].on_activate(player)
end
function magic_api.force_deactivate(player, name)
    powers[name].on_deactivate(player)
end    

local active_players = {}
local hud_elements = {}
local selected_powers = {}
local particlespawners = {}
local function clear_magic_effect(player)
    local elements = hud_elements[player:get_player_name()]
    for _, id in pairs(elements) do
        player:hud_remove(id)
    end
    if particlespawners[player:get_player_name()] then
        minetest.delete_particlespawner(particlespawners[player:get_player_name()])
    end
end
controls.register_on_press(function(player, key)
    local name = player:get_player_name()
    if active_players[name] then
        local meta = player:get_meta()
        local power_list = get_power_list(minetest.deserialize(meta:get_string("magic_api:powers")) or {})
        if key == "aux1" then
            active_players[name] = false
            
            local same_power = power_list[selected_powers[name]] == active_powers[name]
            magic_api.deactivate_player_power(player, active_powers[name]) -- Deactivate current power
            if not same_power then
                magic_api.activate_player_power(player, power_list[selected_powers[name]])
            end
            clear_magic_effect(player)
        elseif key == "up" or key == "down" then
            -- Move up or down the list of powers (cycle)
            if key == "up" then
                selected_powers[name] = (selected_powers[name] % #power_list) + 1
            else
                selected_powers[name] = ((selected_powers[name] - 2) % #power_list) + 1
            end

            player:hud_change(hud_elements[name][2], "text", powers[power_list[selected_powers[name]]].image)
        end
        return
    end
    if key == "aux1" and player:get_player_control()["sneak"] then
        active_players[name] = true

        local bgid = player:hud_add({
            hud_elem_type = "image",
            position = {x = 0, y = 0},
            offset = {x = 0, y = 0},
            text = "bg.png",
            scale = {x = -200, y = -200}
        })
        hud_elements[name][1] = bgid

        local meta = player:get_meta()
        local power_list = get_power_list(minetest.deserialize(meta:get_string("magic_api:powers")) or {})
        if #power_list > 0 then
            selected_powers[name] = selected_powers[name] or 1
            local powerid = player:hud_add({
                hud_elem_type = "image",
                position = {x = 0.5, y = 0.5},
                offset = {x = 0, y = 0},
                text = powers[power_list[selected_powers[name]]].image
            })
            hud_elements[name][2] = powerid
        end
        
        local psid = minetest.add_particlespawner({
            amount = 50,
            time = 0,
            minpos = {x = -10, y = 0, z = -10},
            maxpos = {x = 10, y = 0, z = 10},
            minvel = {x = 0, y = 1, z = 0},
            maxvel = {x = 0, y = 1, z = 0},
            minacc = {x = 0, y = 1, z = 0},
            maxacc = {x = 0, y = 1, z = 0},
            minexptime = 2,
            maxexptime = 3,
            minsize = 1,
            maxsize = 2,
            texture = "particle.png",
            collisiondetection = false,
            attached = player,
            playername = player:get_player_name()
        })
        particlespawners[name] = psid
    end
end)

minetest.register_on_joinplayer(function(player)
    hud_elements[player:get_player_name()] = {}
    if mcl_gamemode.get_gamemode(player) == "creative" then
        for name, _ in pairs(powers) do
            magic_api.give_player_power(player, name)
        end
    end
end)
minetest.register_on_leaveplayer(function(player)
    clear_magic_effect(player)
    hud_elements[player:get_player_name()] = nil
end)