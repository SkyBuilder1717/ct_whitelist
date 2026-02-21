local modname = core.get_current_modname()
local storage = core.get_mod_storage()

-- utils
function ct_whitelist.normalize(name)
    return (name or ""):lower():gsub("^%s*(.-)%s*$", "%1")
end

function ct_whitelist.save_storage()
    local o = { enabled = ct_whitelist.enabled, list = ct_whitelist.list_array }
    storage:set_string(modname .. ":state", core.serialize(o))
end

function ct_whitelist.load_storage()
    local s = storage:get_string(modname .. ":state")
    if s and s ~= "" then
        local ok, t = pcall(core.deserialize, s)
        if ok and type(t) == "table" then
            ct_whitelist.enabled = (t.enabled == nil) and true or t.enabled
            ct_whitelist.list = {}
            ct_whitelist.list_array = {}
            if type(t.list) == "table" then
                for _, n in pairs(t.list) do
                    local nn = ct_whitelist.normalize(n)
                    if nn ~= "" then
                        ct_whitelist.list[nn] = true
                        table.insert(ct_whitelist.list_array, nn)
                    end
                end
            end
        end
    end
end

function ct_whitelist.set_from_array(arr)
    ct_whitelist.list = {}
    ct_whitelist.list_array = {}
    if type(arr) == "table" then
        for _, name in pairs(arr) do
            local nn = ct_whitelist.normalize(name)
            if nn ~= "" and not ct_whitelist.list[nn] then
                ct_whitelist.list[nn] = true
                table.insert(ct_whitelist.list_array, nn)
            end
        end
    end
    ct_whitelist.save_storage()
end

-- file parsing
function ct_whitelist.read_whitelist_file(path)
    local fh, err = io.open(path, "r")
    if not fh then return nil, err end
    local arr = {}
    for line in fh:lines() do
        line = line:match("^(.-)%s*$") or ""
        if line:match("^%s*$") then -- skip blank
        elseif line:match("^%s*#") then -- comment
        else
            local nn = ct_whitelist.normalize(line)
            if nn ~= "" then table.insert(arr, nn) end
        end
    end
    fh:close()
    return arr
end

function ct_whitelist.file_mtime(path)
    local attr = nil
    local ok, res = pcall(function() return assert(io.open(path,"r")) end)
    if not ok then return nil end
    -- Use Lua file: seek to end to approximate mtime not available; platform may not provide mtime.
    -- Prefer to use lfs if available:
    if _G["lfs"] and lfs.attributes then
        local a = lfs.attributes(path)
        if a and a.modification then return a.modification end
    end
    -- fallback: size+time trick (not perfect). We'll return file size + current time hash to force reload on change.
    local fh = io.open(path,"r")
    if not fh then return nil end
    local content = fh:read("*a") or ""
    fh:close()
    return #content
end

function ct_whitelist.reload_from_file()
    if not list_file then return false, "no file" end
    local arr, err = ct_whitelist.read_whitelist_file(list_file)
    if not arr then return false, err end
    ct_whitelist.set_from_array(arr)
    core.log("action", "["..modname.."] whitelist reloaded from file ("..tostring(#arr).." entries)")
    return true
end

-- API
function ct_whitelist.add_name(name)
    name = ct_whitelist.normalize(name)
    if name == "" then return false end
    if ct_whitelist.list[name] then return false end
    ct_whitelist.list[name] = true
    table.insert(ct_whitelist.list_array, name)
    ct_whitelist.save_storage()
    return true
end

function ct_whitelist.remove_name(name)
    name = ct_whitelist.normalize(name)
    if not ct_whitelist.list[name] then return false end
    ct_whitelist.list[name] = nil
    for i,n in ipairs(ct_whitelist.list_array) do
        if n == name then table.remove(ct_whitelist.list_array, i); break end
    end
    ct_whitelist.save_storage()
    return true
end

function ct_whitelist.is_whitelisted(name)
    if not name then return false end

    -- ALWAYS whitelist an owner
    if name == settings:get("name") then return end

    -- privilege didn't do anything before
    if core.check_player_privs(name, "whitelist_bypass") then return true end

    return ct_whitelist.list[ct_whitelist.normalize(name)] == true
end
