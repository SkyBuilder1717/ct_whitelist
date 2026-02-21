-- utils
function whitelist.normalize(name)
    return (name or ""):lower():gsub("^%s*(.-)%s*$", "%1")
end

function whitelist.save_storage()
    local o = { enabled = whitelist.enabled, list = whitelist.list_array }
    storage:set_string("whitelist_live:state", core.serialize(o))
end

function whitelist.load_storage()
    local s = storage:get_string("whitelist_live:state")
    if s and s ~= "" then
        local ok, t = pcall(core.deserialize, s)
        if ok and type(t) == "table" then
            whitelist.enabled = (t.enabled == nil) and true or t.enabled
            whitelist.list = {}
            whitelist.list_array = {}
            if type(t.list) == "table" then
                for _, n in pairs(t.list) do
                    local nn = whitelist.normalize(n)
                    if nn ~= "" then
                        whitelist.list[nn] = true
                        table.insert(whitelist.list_array, nn)
                    end
                end
            end
        end
    end
end

function whitelist.set_from_array(arr)
    whitelist.list = {}
    whitelist.list_array = {}
    if type(arr) == "table" then
        for _, name in pairs(arr) do
            local nn = whitelist.normalize(name)
            if nn ~= "" and not whitelist.list[nn] then
                whitelist.list[nn] = true
                table.insert(whitelist.list_array, nn)
            end
        end
    end
    whitelist.save_storage()
end

-- file parsing
function whitelist.read_whitelist_file(path)
    local fh, err = io.open(path, "r")
    if not fh then return nil, err end
    local arr = {}
    for line in fh:lines() do
        line = line:match("^(.-)%s*$") or ""
        if line:match("^%s*$") then -- skip blank
        elseif line:match("^%s*#") then -- comment
        else
            local nn = whitelist.normalize(line)
            if nn ~= "" then table.insert(arr, nn) end
        end
    end
    fh:close()
    return arr
end

function whitelist.file_mtime(path)
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

function whitelist.reload_from_file()
    if not list_file then return false, "no file" end
    local arr, err = whitelist.read_whitelist_file(list_file)
    if not arr then return false, err end
    whitelist.set_from_array(arr)
    core.log("action", "["..modname.."] whitelist reloaded from file ("..tostring(#arr).." entries)")
    return true
end

-- API
function whitelist.add_name(name)
    name = whitelist.normalize(name)
    if name == "" then return false end
    if whitelist.list[name] then return false end
    whitelist.list[name] = true
    table.insert(whitelist.list_array, name)
    whitelist.save_storage()
    return true
end

function whitelist.remove_name(name)
    name = whitelist.normalize(name)
    if not whitelist.list[name] then return false end
    whitelist.list[name] = nil
    for i,n in ipairs(whitelist.list_array) do
        if n == name then table.remove(whitelist.list_array, i); break end
    end
    whitelist.save_storage()
    return true
end

function whitelist.is_whitelisted(name)
    if not name then return false end
    return whitelist.list[whitelist.normalize(name)] == true
end
