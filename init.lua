local settings = core.settings

-- global variable
local modname = core.get_current_modname()
ct_whitelist = {
    enabled = settings:get_bool(modname .. "_enabled", true),
    list = {},
    list_array = {},
    file_name = settings:get(modname .. "_file_name") or "whitelist.txt",
    check_interval = settings:get(modname .. "_delay") or 5.0,
    file_func = nil
}

if core.is_singleplayer() then
    return 
end -- just not enabling the mod

local modpath = core.get_modpath(modname)
local S = core.get_translator(modname)
local list_file = core.get_worldpath() .. "/" .. ct_whitelist.file_name

-- util and api
dofile(modpath .. "/src/util.lua")
-- load initial storage
ct_whitelist.load_storage()

-- attempt to load file initially if present
if list_file then
    local ok, _ = pcall(function()
        local fh = io.open(list_file, "r")
        if fh then
            fh:close()
            local mt = ct_whitelist.file_mtime(list_file)
            ct_whitelist.file_func = mt
            local arr, err = ct_whitelist.read_whitelist_file(list_file)
            if arr then ct_whitelist.set_from_array(arr) end
        end
    end)
end

-- privileges
core.register_privilege("whitelist_admin", {
    description = S("Can manage the whitelist"),
    give_to_singleplayer = false,
    give_to_admin = true
})
core.register_privilege("whitelist_bypass", {
    description = S("Bypass the whitelist"),
    give_to_singleplayer = false,
    give_to_admin = true
})

-- commands
core.register_chatcommand("whitelist", {
    params = "<add|remove|list|reload|enable|disable|status> [name]",
    description = S("Manage server whitelist"),
    privs = {whitelist_admin = true},
    func = function(name, param)
        local action, player_name = param:match("^(%S+)%s*(.*)$")
        if not action then
            return false -- optimized
        end
        action = action:lower()

        if action == "add" then
            if player_name == "" then return false, S("Specify player name") end
            if ct_whitelist.add_name(player_name) then
                return true, S("Added @1 to @2.", player_name, ct_whitelist.file_name)
            else
                return false, S("@1 already in @2.", player_name, ct_whitelist.file_name)
            end

        elseif action == "remove" then
            if player_name == "" then return false, S("Specify player name") end
            if ct_whitelist.remove_name(player_name) then
                return true, S("Removed @1 from @2.", player_name, ct_whitelist.file_name)
            else
                return false, S("@1 not in @2.", player_name, ct_whitelist.file_name)
            end

        elseif action == "list" then
            if #ct_whitelist.list_array == 0 then return true, S("Whitelist is empty.") end
            return true, S("Whitelist: @1", table.concat(ct_whitelist.list_array, ", "))

        elseif action == "reload" then
            if not ct_whitelist.file_name then return false, S("No text file available to reload.") end
            local ok, err = ct_whitelist.reload_from_file()
            if ok then return true, S("Reloaded from @1.", ct_whitelist.file_name) else return false, S("Reload failed: @1", tostring(err)) end
            
        elseif action == "enable" then
            ct_whitelist.enabled = true
            ct_whitelist.save_storage()
            return true, S("Whitelist enabled.")

        elseif action == "disable" then
            ct_whitelist.enabled = false
            ct_whitelist.save_storage()
            return true, S("Whitelist disabled.")

        elseif action == "status" then
            -- and why?
            local s = "enabled="..tostring(ct_whitelist.enabled).."; count="..tostring(#ct_whitelist.list_array)
            if list_file then s = s .. "; file="..list_file end
            return true, s

        else return false end
    end
})

-- prejoin check (deny early)
if core.register_on_prejoinplayer then
    core.register_on_prejoinplayer(function(name)
        if not ct_whitelist.enabled then return end
        
        -- check for whitelisting through mod func
        if ct_whitelist.is_whitelisted(name) then return end

        return S("You are not whitelisted on this server.")
    end)
else
    -- fallback: kick on join if not allowed
	core.register_on_joinplayer(function(player)
	    local pname = player:get_player_name()

	    active_tab[pname] = "inventory" -- existing inventory override
	    update_inventory(player)
	end)
end

local time = 0
-- live reload: poll file mtime
core.register_globalstep(function(dtime)
    time = time + dtime
    if time < ct_whitelist.check_interval then return end
    time = 0
    if not list_file then return end
    local ok, mt = pcall(file_func, list_file)
    if not ok then mt = nil end
    if mt and ct_whitelist.file_func ~= mt then
        ct_whitelist.file_func = mt
        local ok2, err = ct_whitelist.reload_from_file()
        if not ok2 then core.log("warning", "["..modname.."] live reload failed: "..tostring(err)) end
    end
end)
