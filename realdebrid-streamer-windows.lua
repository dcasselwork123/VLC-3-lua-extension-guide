-- Real Debrid Torrent Streamer with Netflix-Style Browsing
-- VLC Extension for streaming torrents via Real Debrid API
-- Features: Torrent streaming, TMDB browsing, watch tracking, dialogue boost
-- Compatible with VLC 3.x+ on Windows/Android

--[[
INSTALLATION:
1. Copy this file to VLC's lua/extensions folder:
   - Windows: %APPDATA%\vlc\lua\extensions\
   - Linux: ~/.local/share/vlc/lua/extensions/
   - macOS: ~/Library/Application Support/org.videolan.vlc/lua/extensions/
   - Android: /sdcard/Android/data/org.videolan.vlc/files/lua/extensions/
2. Restart VLC
3. Access via: View > Real Debrid Streamer or Tools > Extensions

FIRST RUN:
- You'll be prompted for your Real Debrid API key (get from https://real-debrid.com/apitoken)
- Optional: TMDB API key for browsing (get free from https://www.themoviedb.org/settings/api)
]]--

------------------------------
-- Extension Descriptor
------------------------------
function descriptor()
    return {
        title = "Real Debrid Streamer",
        version = "1.0.0",
        author = "VLC Extension Developer",
        url = 'https://github.com',
        shortdesc = "Stream torrents via Real Debrid with Netflix-style browsing",
        description = "Stream torrents through Real Debrid API, browse TMDB content, track watched items, and apply dialogue boost audio enhancement.",
        capabilities = {"menu", "input-listener", "playing-listener", "meta-listener"}
    }
end

------------------------------
-- Global Variables
------------------------------
local dlg = nil  -- Main dialog
local config = {}  -- Configuration storage
local watch_history = {}  -- Watch tracking
local current_view = "home"  -- Current UI view
local current_page = 1  -- Pagination
local browse_data = {}  -- Cached browse data
local current_item = nil  -- Currently selected item
local dialogue_boost_enabled = false
local dialogue_boost_level = "medium"

-- API endpoints
local RD_API_BASE = "https://api.real-debrid.com/rest/1.0"
local TMDB_API_BASE = "https://api.themoviedb.org/3"
local YTS_API_BASE = "https://yts.mx/api/v2"

-- Config file paths (will be set in init)
local config_dir = nil
local config_file = nil
local watch_file = nil

------------------------------
-- JSON Utilities (Self-contained)
------------------------------
local JSON = {}

-- Encode Lua table to JSON string
function JSON.encode(obj)
    local function encode_value(val)
        local val_type = type(val)
        
        if val_type == "string" then
            return '"' .. val:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
        elseif val_type == "number" then
            return tostring(val)
        elseif val_type == "boolean" then
            return val and "true" or "false"
        elseif val_type == "table" then
            local is_array = true
            local max_index = 0
            
            for k, _ in pairs(val) do
                if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                    is_array = false
                    break
                end
                max_index = math.max(max_index, k)
            end
            
            if is_array and max_index == #val then
                local items = {}
                for i = 1, #val do
                    table.insert(items, encode_value(val[i]))
                end
                return "[" .. table.concat(items, ",") .. "]"
            else
                local items = {}
                for k, v in pairs(val) do
                    table.insert(items, encode_value(tostring(k)) .. ":" .. encode_value(v))
                end
                return "{" .. table.concat(items, ",") .. "}"
            end
        elseif val_type == "nil" then
            return "null"
        else
            return '"' .. tostring(val) .. '"'
        end
    end
    
    return encode_value(obj)
end

-- Decode JSON string to Lua table
function JSON.decode(str)
    if not str or str == "" then return nil end
    
    local pos = 1
    
    local function decode_error(msg)
        error("JSON decode error at position " .. pos .. ": " .. msg)
    end
    
    local function skip_whitespace()
        while pos <= #str do
            local c = str:sub(pos, pos)
            if c ~= " " and c ~= "\t" and c ~= "\n" and c ~= "\r" then
                break
            end
            pos = pos + 1
        end
    end
    
    local function decode_string()
        if str:sub(pos, pos) ~= '"' then
            decode_error("Expected string")
        end
        pos = pos + 1
        
        local result = ""
        while pos <= #str do
            local c = str:sub(pos, pos)
            
            if c == '"' then
                pos = pos + 1
                return result
            elseif c == "\\" then
                pos = pos + 1
                if pos > #str then decode_error("Unexpected end in string escape") end
                
                local escape = str:sub(pos, pos)
                if escape == '"' or escape == "\\" or escape == "/" then
                    result = result .. escape
                elseif escape == "b" then result = result .. "\b"
                elseif escape == "f" then result = result .. "\f"
                elseif escape == "n" then result = result .. "\n"
                elseif escape == "r" then result = result .. "\r"
                elseif escape == "t" then result = result .. "\t"
                elseif escape == "u" then
                    pos = pos + 1
                    local hex = str:sub(pos, pos + 3)
                    pos = pos + 3
                    result = result .. string.char(tonumber(hex, 16))
                else
                    decode_error("Invalid escape sequence")
                end
                pos = pos + 1
            else
                result = result .. c
                pos = pos + 1
            end
        end
        
        decode_error("Unterminated string")
    end
    
    local function decode_number()
        local start_pos = pos
        
        if str:sub(pos, pos) == "-" then pos = pos + 1 end
        
        if pos > #str or not str:sub(pos, pos):match("%d") then
            decode_error("Invalid number")
        end
        
        while pos <= #str and str:sub(pos, pos):match("%d") do
            pos = pos + 1
        end
        
        if pos <= #str and str:sub(pos, pos) == "." then
            pos = pos + 1
            if pos > #str or not str:sub(pos, pos):match("%d") then
                decode_error("Invalid number")
            end
            while pos <= #str and str:sub(pos, pos):match("%d") do
                pos = pos + 1
            end
        end
        
        if pos <= #str and (str:sub(pos, pos) == "e" or str:sub(pos, pos) == "E") then
            pos = pos + 1
            if pos <= #str and (str:sub(pos, pos) == "+" or str:sub(pos, pos) == "-") then
                pos = pos + 1
            end
            if pos > #str or not str:sub(pos, pos):match("%d") then
                decode_error("Invalid number")
            end
            while pos <= #str and str:sub(pos, pos):match("%d") do
                pos = pos + 1
            end
        end
        
        return tonumber(str:sub(start_pos, pos - 1))
    end
    
    local function decode_value()
        skip_whitespace()
        
        if pos > #str then decode_error("Unexpected end of JSON") end
        
        local c = str:sub(pos, pos)
        
        if c == '"' then
            return decode_string()
        elseif c == "{" then
            return decode_object()
        elseif c == "[" then
            return decode_array()
        elseif c == "t" then
            if str:sub(pos, pos + 3) ~= "true" then decode_error("Invalid literal") end
            pos = pos + 4
            return true
        elseif c == "f" then
            if str:sub(pos, pos + 4) ~= "false" then decode_error("Invalid literal") end
            pos = pos + 5
            return false
        elseif c == "n" then
            if str:sub(pos, pos + 3) ~= "null" then decode_error("Invalid literal") end
            pos = pos + 4
            return nil
        elseif c == "-" or c:match("%d") then
            return decode_number()
        else
            decode_error("Unexpected character: " .. c)
        end
    end
    
    function decode_object()
        if str:sub(pos, pos) ~= "{" then decode_error("Expected '{'") end
        pos = pos + 1
        
        local obj = {}
        skip_whitespace()
        
        if pos <= #str and str:sub(pos, pos) == "}" then
            pos = pos + 1
            return obj
        end
        
        while true do
            skip_whitespace()
            local key = decode_string()
            skip_whitespace()
            
            if pos > #str or str:sub(pos, pos) ~= ":" then
                decode_error("Expected ':'")
            end
            pos = pos + 1
            
            local value = decode_value()
            obj[key] = value
            
            skip_whitespace()
            if pos > #str then decode_error("Unexpected end of object") end
            
            local c = str:sub(pos, pos)
            if c == "}" then
                pos = pos + 1
                return obj
            elseif c == "," then
                pos = pos + 1
            else
                decode_error("Expected ',' or '}'")
            end
        end
    end
    
    function decode_array()
        if str:sub(pos, pos) ~= "[" then decode_error("Expected '['") end
        pos = pos + 1
        
        local arr = {}
        skip_whitespace()
        
        if pos <= #str and str:sub(pos, pos) == "]" then
            pos = pos + 1
            return arr
        end
        
        while true do
            local value = decode_value()
            table.insert(arr, value)
            
            skip_whitespace()
            if pos > #str then decode_error("Unexpected end of array") end
            
            local c = str:sub(pos, pos)
            if c == "]" then
                pos = pos + 1
                return arr
            elseif c == "," then
                pos = pos + 1
            else
                decode_error("Expected ',' or ']'")
            end
        end
    end
    
    return decode_value()
end

------------------------------
-- Utility Functions
------------------------------

-- Logging function
function log(msg)
    vlc.msg.info("[RD Streamer] " .. tostring(msg))
end

-- Error dialog
function show_error(message)
    if dlg then
        vlc.dialog.dialog_message("Error", message)
    end
    log("ERROR: " .. message)
end

-- URL encode
function url_encode(str)
    if not str then return "" end
    str = tostring(str)
    str = str:gsub("\n", "\r\n")
    str = str:gsub("([^%w %-%_%.])",
        function(c) return string.format("%%%02X", string.byte(c)) end)
    str = str:gsub(" ", "+")
    return str
end

-- HTTP GET request
function http_get(url, headers)
    log("HTTP GET: " .. url)
    
    local stream = vlc.stream(url)
    if not stream then
        log("Failed to open stream: " .. url)
        return nil
    end
    
    local data = ""
    while true do
        local chunk = stream:read(65536)
        if not chunk or #chunk == 0 then break end
        data = data .. chunk
    end
    
    return data
end

-- HTTP POST request (simulated via GET with data in URL for VLC limitations)
function http_post(url, post_data, headers)
    log("HTTP POST: " .. url)
    
    -- VLC's stream doesn't support POST directly, so we use a workaround
    -- For Real Debrid API, most endpoints support GET as well
    local full_url = url
    if post_data then
        local params = {}
        for k, v in pairs(post_data) do
            table.insert(params, url_encode(k) .. "=" .. url_encode(v))
        end
        full_url = url .. "?" .. table.concat(params, "&")
    end
    
    return http_get(full_url, headers)
end

-- Initialize config directory
function init_config()
    -- Determine VLC config directory based on OS
    local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""
    
    -- Try to detect OS
    if package.config:sub(1,1) == "\\" then
        -- Windows
        config_dir = os.getenv("APPDATA") .. "\\vlc\\lua\\extensions\\rd_streamer"
    else
        -- Unix-like (Linux, macOS, Android)
        if home:find("/storage/emulated") then
            -- Android
            config_dir = "/sdcard/Android/data/org.videolan.vlc/files/rd_streamer"
        else
            -- Linux/macOS
            config_dir = home .. "/.config/vlc/rd_streamer"
        end
    end
    
    config_file = config_dir .. "/config.json"
    watch_file = config_dir .. "/watch_history.json"
    
    -- Create directory (VLC doesn't provide mkdir, so we'll handle missing dir gracefully)
    log("Config directory: " .. config_dir)
end

-- Load config from file
function load_config()
    init_config()
    
    local file = io.open(config_file, "r")
    if file then
        local content = file:read("*all")
        file:close()
        
        local success, result = pcall(JSON.decode, content)
        if success and result then
            config = result
            log("Config loaded successfully")
            return true
        else
            log("Failed to parse config file")
        end
    else
        log("Config file not found, using defaults")
    end
    
    -- Default config
    config = {
        rd_api_key = "",
        tmdb_api_key = "",
        dialogue_boost = "medium",
        auto_subtitles = true,
        last_updated = os.time()
    }
    return false
end

-- Save config to file
function save_config()
    -- Create directory if it doesn't exist (attempt to create via io)
    local dir_file = io.open(config_dir .. "/test", "w")
    if dir_file then
        dir_file:close()
        os.remove(config_dir .. "/test")
    end
    
    local file = io.open(config_file, "w")
    if file then
        file:write(JSON.encode(config))
        file:close()
        log("Config saved successfully")
        return true
    else
        log("Failed to save config file")
        return false
    end
end

-- Load watch history
function load_watch_history()
    local file = io.open(watch_file, "r")
    if file then
        local content = file:read("*all")
        file:close()
        
        local success, result = pcall(JSON.decode, content)
        if success and result then
            watch_history = result
            log("Watch history loaded: " .. #watch_history .. " items")
            return true
        end
    end
    
    watch_history = {}
    return false
end

-- Save watch history
function save_watch_history()
    local file = io.open(watch_file, "w")
    if file then
        file:write(JSON.encode(watch_history))
        file:close()
        log("Watch history saved")
        return true
    else
        log("Failed to save watch history")
        return false
    end
end

-- Add item to watch history
function add_to_history(item_id, title, media_type, timestamp)
    local entry = {
        id = item_id,
        title = title,
        type = media_type,
        timestamp = timestamp or os.time(),
        watched = true
    }
    
    -- Remove existing entry if present
    for i, hist in ipairs(watch_history) do
        if hist.id == item_id then
            table.remove(watch_history, i)
            break
        end
    end
    
    table.insert(watch_history, 1, entry)
    
    -- Keep only last 100 items
    while #watch_history > 100 do
        table.remove(watch_history)
    end
    
    save_watch_history()
end

------------------------------
-- Real Debrid API Functions
------------------------------

-- Test RD API key
function test_rd_api_key(api_key)
    if not api_key or api_key == "" then
        return false, "API key is empty"
    end
    
    local url = RD_API_BASE .. "/user?auth_token=" .. url_encode(api_key)
    local response = http_get(url)
    
    if response then
        local success, data = pcall(JSON.decode, response)
        if success and data and data.id then
            log("RD API key valid for user: " .. (data.username or "unknown"))
            return true, data.username
        end
    end
    
    return false, "Invalid API key or connection error"
end

-- Add magnet to Real Debrid
function rd_add_magnet(magnet_uri, api_key)
    local url = RD_API_BASE .. "/torrents/addMagnet"
    local post_data = {
        magnet = magnet_uri,
        auth_token = api_key
    }
    
    local response = http_post(url, post_data)
    if response then
        local success, data = pcall(JSON.decode, response)
        if success and data and data.id then
            log("Torrent added: " .. data.id)
            return data.id
        end
    end
    
    return nil
end

-- Get torrent info
function rd_get_torrent_info(torrent_id, api_key)
    local url = RD_API_BASE .. "/torrents/info/" .. torrent_id .. "?auth_token=" .. url_encode(api_key)
    local response = http_get(url)
    
    if response then
        local success, data = pcall(JSON.decode, response)
        if success and data then
            return data
        end
    end
    
    return nil
end

-- Select files from torrent
function rd_select_files(torrent_id, file_ids, api_key)
    local url = RD_API_BASE .. "/torrents/selectFiles/" .. torrent_id
    local post_data = {
        files = file_ids,
        auth_token = api_key
    }
    
    local response = http_post(url, post_data)
    return response ~= nil
end

-- Unrestrict link (get direct download URL)
function rd_unrestrict_link(link, api_key)
    local url = RD_API_BASE .. "/unrestrict/link"
    local post_data = {
        link = link,
        auth_token = api_key
    }
    
    local response = http_post(url, post_data)
    if response then
        local success, data = pcall(JSON.decode, response)
        if success and data and data.download then
            log("Unrestricted link: " .. data.download)
            return data.download
        end
    end
    
    return nil
end

-- Stream torrent via Real Debrid (main function)
function stream_via_realdebrid(magnet_uri)
    if not config.rd_api_key or config.rd_api_key == "" then
        show_error("Please configure your Real Debrid API key first")
        return false
    end
    
    -- Step 1: Add magnet
    local torrent_id = rd_add_magnet(magnet_uri, config.rd_api_key)
    if not torrent_id then
        show_error("Failed to add magnet to Real Debrid")
        return false
    end
    
    -- Step 2: Wait for torrent info (simple delay)
    log("Waiting for torrent info...")
    os.execute("sleep 2")  -- Wait 2 seconds
    
    -- Step 3: Get torrent info
    local torrent_info = rd_get_torrent_info(torrent_id, config.rd_api_key)
    if not torrent_info then
        show_error("Failed to get torrent info")
        return false
    end
    
    -- Step 4: Select files (select all video files)
    if torrent_info.files then
        local file_ids = {}
        for i, file in ipairs(torrent_info.files) do
            local path = file.path or ""
            if path:match("%.mp4$") or path:match("%.mkv$") or path:match("%.avi$") then
                table.insert(file_ids, tostring(file.id))
            end
        end
        
        if #file_ids > 0 then
            local files_str = table.concat(file_ids, ",")
            rd_select_files(torrent_id, files_str, config.rd_api_key)
            
            -- Wait for selection
            os.execute("sleep 2")
            
            -- Get updated info
            torrent_info = rd_get_torrent_info(torrent_id, config.rd_api_key)
        end
    end
    
    -- Step 5: Get links
    if torrent_info.links and #torrent_info.links > 0 then
        local link = torrent_info.links[1]
        
        -- Step 6: Unrestrict link
        local stream_url = rd_unrestrict_link(link, config.rd_api_key)
        if stream_url then
            -- Step 7: Play in VLC
            vlc.playlist.add({{path = stream_url}})
            log("Stream started: " .. stream_url)
            return true
        end
    end
    
    show_error("No streamable links found in torrent")
    return false
end

------------------------------
-- TMDB API Functions
------------------------------

-- Get popular movies
function tmdb_get_popular_movies(page)
    if not config.tmdb_api_key or config.tmdb_api_key == "" then
        return {}
    end
    
    page = page or 1
    local url = TMDB_API_BASE .. "/movie/popular?api_key=" .. url_encode(config.tmdb_api_key) .. "&page=" .. page
    local response = http_get(url)
    
    if response then
        local success, data = pcall(JSON.decode, response)
        if success and data and data.results then
            return data.results
        end
    end
    
    return {}
end

-- Get popular TV shows
function tmdb_get_popular_tv(page)
    if not config.tmdb_api_key or config.tmdb_api_key == "" then
        return {}
    end
    
    page = page or 1
    local url = TMDB_API_BASE .. "/tv/popular?api_key=" .. url_encode(config.tmdb_api_key) .. "&page=" .. page
    local response = http_get(url)
    
    if response then
        local success, data = pcall(JSON.decode, response)
        if success and data and data.results then
            return data.results
        end
    end
    
    return {}
end

-- Get new releases (movies)
function tmdb_get_new_releases(page)
    if not config.tmdb_api_key or config.tmdb_api_key == "" then
        return {}
    end
    
    page = page or 1
    local url = TMDB_API_BASE .. "/movie/now_playing?api_key=" .. url_encode(config.tmdb_api_key) .. "&page=" .. page
    local response = http_get(url)
    
    if response then
        local success, data = pcall(JSON.decode, response)
        if success and data and data.results then
            return data.results
        end
    end
    
    return {}
end

-- Search TMDB
function tmdb_search(query, media_type)
    if not config.tmdb_api_key or config.tmdb_api_key == "" then
        return {}
    end
    
    media_type = media_type or "movie"
    local url = TMDB_API_BASE .. "/search/" .. media_type .. "?api_key=" .. url_encode(config.tmdb_api_key) .. "&query=" .. url_encode(query)
    local response = http_get(url)
    
    if response then
        local success, data = pcall(JSON.decode, response)
        if success and data and data.results then
            return data.results
        end
    end
    
    return {}
end

-- Get movie/show details
function tmdb_get_details(id, media_type)
    if not config.tmdb_api_key or config.tmdb_api_key == "" then
        return nil
    end
    
    media_type = media_type or "movie"
    local url = TMDB_API_BASE .. "/" .. media_type .. "/" .. id .. "?api_key=" .. url_encode(config.tmdb_api_key)
    local response = http_get(url)
    
    if response then
        local success, data = pcall(JSON.decode, response)
        if success and data then
            return data
        end
    end
    
    return nil
end

------------------------------
-- Torrent Search Functions (YTS)
------------------------------

-- Search YTS for movies
function yts_search(query, year)
    local url = YTS_API_BASE .. "/list_movies.json?query_term=" .. url_encode(query)
    if year then
        url = url .. "&year=" .. year
    end
    
    local response = http_get(url)
    if response then
        local success, data = pcall(JSON.decode, response)
        if success and data and data.data and data.data.movies then
            return data.data.movies
        end
    end
    
    return {}
end

-- Get magnet from YTS movie
function yts_get_magnet(movie_data, quality)
    quality = quality or "1080p"
    
    if movie_data.torrents then
        for _, torrent in ipairs(movie_data.torrents) do
            if torrent.quality == quality then
                local hash = torrent.hash
                local title = url_encode(movie_data.title_long or movie_data.title)
                return "magnet:?xt=urn:btih:" .. hash .. "&dn=" .. title .. "&tr=udp://open.demonii.com:1337/announce&tr=udp://tracker.openbittorrent.com:80&tr=udp://tracker.coppersurfer.tk:6969&tr=udp://glotorrents.pw:6969/announce&tr=udp://tracker.opentrackr.org:1337/announce"
            end
        end
    end
    
    return nil
end

------------------------------
-- Dialogue Boost Functions
------------------------------

-- Apply dialogue boost filter
function apply_dialogue_boost(level)
    level = level or "medium"
    
    -- VLC equalizer presets for voice enhancement
    -- Boost mid-frequencies (200-4000 Hz) where dialogue lives
    local preamps = {
        low = {-3, -2, 0, 2, 3, 2, 0, -1, -2, -3},
        medium = {-5, -3, 0, 4, 6, 4, 0, -2, -3, -4},
        high = {-7, -5, 0, 6, 8, 6, 0, -3, -5, -6}
    }
    
    local preset = preamps[level] or preamps.medium
    
    -- Try to apply equalizer (VLC 3.x may have limited Lua access)
    local success = pcall(function()
        vlc.equalizer.enable()
        for i, amp in ipairs(preset) do
            vlc.equalizer.setamp(i - 1, amp)
        end
        vlc.equalizer.setpreamp(2)
    end)
    
    if success then
        log("Dialogue boost applied: " .. level)
        dialogue_boost_enabled = true
        dialogue_boost_level = level
    else
        log("Failed to apply dialogue boost (may not be supported in this VLC version)")
    end
end

-- Disable dialogue boost
function disable_dialogue_boost()
    local success = pcall(function()
        vlc.equalizer.disable()
    end)
    
    if success then
        log("Dialogue boost disabled")
        dialogue_boost_enabled = false
    end
end

------------------------------
-- UI Functions
------------------------------

-- Create main dialog
function create_main_dialog()
    if dlg then
        dlg:delete()
    end
    
    dlg = vlc.dialog("Real Debrid Streamer")
    
    -- Title
    dlg:add_label("<h2>Real Debrid Torrent Streamer</h2>", 1, 1, 4, 1)
    
    -- Tab buttons
    dlg:add_button("Home", function() show_home_view() end, 1, 2, 1, 1)
    dlg:add_button("Movies", function() show_movies_view() end, 2, 2, 1, 1)
    dlg:add_button("TV Shows", function() show_tv_view() end, 3, 2, 1, 1)
    dlg:add_button("Settings", function() show_settings_view() end, 4, 2, 1, 1)
    
    -- Content area (will be populated based on view)
    dlg:add_html("<div id='content'></div>", 1, 3, 4, 8)
    
    -- Show home view by default
    show_home_view()
end

-- Show home view
function show_home_view()
    current_view = "home"
    
    if not dlg then return end
    
    -- Recreate dialog with home content
    dlg:delete()
    dlg = vlc.dialog("Real Debrid Streamer - Home")
    
    dlg:add_label("<h2>Home</h2>", 1, 1, 4, 1)
    
    -- Quick actions
    dlg:add_label("<b>Stream from Magnet/Torrent:</b>", 1, 2, 4, 1)
    local magnet_input = dlg:add_text_input("", 1, 3, 3, 1)
    dlg:add_button("Stream", function()
        local magnet = magnet_input:get_text()
        if magnet and magnet ~= "" then
            stream_via_realdebrid(magnet)
        else
            show_error("Please enter a magnet link or torrent URL")
        end
    end, 4, 3, 1, 1)
    
    dlg:add_label("<hr>", 1, 4, 4, 1)
    
    -- Watch history
    dlg:add_label("<b>Recently Watched:</b>", 1, 5, 4, 1)
    
    if #watch_history > 0 then
        local history_text = "<ul>"
        for i = 1, math.min(5, #watch_history) do
            local item = watch_history[i]
            history_text = history_text .. "<li>" .. item.title .. " (" .. item.type .. ")</li>"
        end
        history_text = history_text .. "</ul>"
        dlg:add_html(history_text, 1, 6, 4, 3)
    else
        dlg:add_label("No watch history yet. Start browsing!", 1, 6, 4, 1)
    end
    
    dlg:add_label("<hr>", 1, 9, 4, 1)
    
    -- Navigation
    dlg:add_button("Search", function() show_search_dialog() end, 1, 10, 1, 1)
    dlg:add_button("Browse", function() show_movies_view() end, 2, 10, 1, 1)
    dlg:add_button("Settings", function() show_settings_view() end, 3, 10, 1, 1)
    dlg:add_button("Close", function() vlc.deactivate() end, 4, 10, 1, 1)
end

-- Show movies view
function show_movies_view()
    current_view = "movies"
    
    if not dlg then return end
    
    dlg:delete()
    dlg = vlc.dialog("Real Debrid Streamer - Movies")
    
    dlg:add_label("<h2>Movies</h2>", 1, 1, 4, 1)
    
    -- Fetch popular movies
    dlg:add_label("Loading popular movies...", 1, 2, 4, 1)
    
    -- Tabs
    dlg:add_button("Popular", function() load_movies("popular") end, 1, 3, 1, 1)
    dlg:add_button("New Releases", function() load_movies("new") end, 2, 3, 1, 1)
    dlg:add_button("Search", function() show_search_dialog() end, 3, 3, 1, 1)
    dlg:add_button("← Back", function() show_home_view() end, 4, 3, 1, 1)
    
    -- Movie list (will be populated)
    dlg:add_html("<div id='movie-list'>Loading...</div>", 1, 4, 4, 6)
    
    -- Pagination
    dlg:add_button("Previous", function() prev_page() end, 1, 10, 1, 1)
    dlg:add_label("Page 1", 2, 10, 2, 1)
    dlg:add_button("Next ▶️", function() next_page() end, 4, 10, 1, 1)
    
    -- Load popular movies by default
    load_movies("popular")
end

-- Show TV shows view
function show_tv_view()
    current_view = "tv"
    
    if not dlg then return end
    
    dlg:delete()
    dlg = vlc.dialog("Real Debrid Streamer - TV Shows")
    
    dlg:add_label("<h2>TV Shows</h2>", 1, 1, 4, 1)
    
    dlg:add_button("Popular", function() load_tv("popular") end, 1, 2, 1, 1)
    dlg:add_button("Search", function() show_search_dialog() end, 2, 2, 1, 1)
    dlg:add_button("← Back", function() show_home_view() end, 4, 2, 1, 1)
    
    dlg:add_html("<div id='tv-list'>Loading...</div>", 1, 3, 4, 7)
    
    dlg:add_button("Previous", function() prev_page() end, 1, 10, 1, 1)
    dlg:add_label("Page 1", 2, 10, 2, 1)
    dlg:add_button("Next ▶️", function() next_page() end, 4, 10, 1, 1)
    
    load_tv("popular")
end

-- Show settings view
function show_settings_view()
    if not dlg then return end
    
    dlg:delete()
    dlg = vlc.dialog("Real Debrid Streamer - Settings")
    
    dlg:add_label("<h2>Settings</h2>", 1, 1, 4, 1)
    
    -- Real Debrid API Key
    dlg:add_label("<b>Real Debrid API Key:</b>", 1, 2, 4, 1)
    local rd_key_input = dlg:add_text_input(config.rd_api_key or "", 1, 3, 3, 1)
    dlg:add_button("Test", function()
        local key = rd_key_input:get_text()
        local valid, msg = test_rd_api_key(key)
        if valid then
            show_error("API key is valid! User: " .. (msg or "unknown"))
            config.rd_api_key = key
            save_config()
        else
            show_error("" .. msg)
        end
    end, 4, 3, 1, 1)
    
    dlg:add_label("<small>Get your API key from: https://real-debrid.com/apitoken</small>", 1, 4, 4, 1)
    
    -- TMDB API Key
    dlg:add_label("<b>TMDB API Key (optional):</b>", 1, 5, 4, 1)
    local tmdb_key_input = dlg:add_text_input(config.tmdb_api_key or "", 1, 6, 4, 1)
    dlg:add_label("<small>Get free API key from: https://www.themoviedb.org/settings/api</small>", 1, 7, 4, 1)
    
    -- Dialogue Boost
    dlg:add_label("<b>Dialogue Boost:</b>", 1, 8, 4, 1)
    local boost_dropdown = dlg:add_dropdown(1, 9, 2, 1)
    
    dlg:add_button("Apply", function()
        local level = boost_dropdown:get_value()
        apply_dialogue_boost(level)
    end, 3, 9, 1, 1)
    
    dlg:add_button("Disable", function()
        disable_dialogue_boost()
    end, 4, 9, 1, 1)
    
    -- Save button
    dlg:add_button("Save Settings", function()
        config.rd_api_key = rd_key_input:get_text()
        config.tmdb_api_key = tmdb_key_input:get_text()
        save_config()
        show_error("Settings saved!")
    end, 1, 10, 2, 1)
    
    dlg:add_button("← Back", function() show_home_view() end, 3, 10, 2, 1)
end

-- Show search dialog
function show_search_dialog()
    if not dlg then return end
    
    dlg:delete()
    dlg = vlc.dialog("Search")
    
    dlg:add_label("<h3>Search</h3>", 1, 1, 4, 1)
    
    dlg:add_label("Query:", 1, 2, 1, 1)
    local search_input = dlg:add_text_input("", 2, 2, 2, 1)
    
    dlg:add_label("Type:", 1, 3, 1, 1)
    local type_dropdown = dlg:add_dropdown(2, 3, 2, 1)
    
    dlg:add_button("Search", function()
        local query = search_input:get_text()
        local search_type = type_dropdown:get_value() or "movie"
        
        if query and query ~= "" then
            perform_search(query, search_type)
        end
    end, 4, 2, 1, 2)
    
    dlg:add_button("← Back", function() show_home_view() end, 1, 4, 4, 1)
end

-- Load movies
function load_movies(category)
    category = category or "popular"
    
    local movies = {}
    if category == "popular" then
        movies = tmdb_get_popular_movies(current_page)
    elseif category == "new" then
        movies = tmdb_get_new_releases(current_page)
    end
    
    browse_data = movies
    display_browse_items(movies, "movie")
end

-- Load TV shows
function load_tv(category)
    category = category or "popular"
    
    local shows = {}
    if category == "popular" then
        shows = tmdb_get_popular_tv(current_page)
    end
    
    browse_data = shows
    display_browse_items(shows, "tv")
end

-- Display browse items (movies/TV)
function display_browse_items(items, media_type)
    if not dlg or not items then return end
    
    -- Create a simple list view
    local html = "<ul>"
    
    for i, item in ipairs(items) do
        local title = item.title or item.name or "Unknown"
        local year = ""
        if item.release_date then
            year = " (" .. item.release_date:sub(1, 4) .. ")"
        elseif item.first_air_date then
            year = " (" .. item.first_air_date:sub(1, 4) .. ")"
        end
        
        local rating = item.vote_average or "N/A"
        
        html = html .. "<li><b>" .. title .. "</b>" .. year .. " - " .. rating .. "/10</li>"
    end
    
    html = html .. "</ul>"
    
    -- Note: VLC's HTML widget is limited, so we can't make items clickable
    -- Users will need to use search to find specific titles
end

-- Perform search
function perform_search(query, media_type)
    local results = tmdb_search(query, media_type)
    
    if #results > 0 then
        local result = results[1]  -- Take first result
        local title = result.title or result.name or "Unknown"
        
        -- Search for torrent
        local year = nil
        if result.release_date then
            year = result.release_date:sub(1, 4)
        end
        
        local torrents = yts_search(title, year)
        
        if #torrents > 0 then
            local torrent = torrents[1]
            local magnet = yts_get_magnet(torrent, "1080p")
            
            if magnet then
                stream_via_realdebrid(magnet)
                add_to_history(result.id, title, media_type, os.time())
            else
                show_error("No torrent found for: " .. title)
            end
        else
            show_error("No torrents found for: " .. title)
        end
    else
        show_error("No results found for: " .. query)
    end
end

-- Pagination
function next_page()
    current_page = current_page + 1
    
    if current_view == "movies" then
        load_movies("popular")
    elseif current_view == "tv" then
        load_tv("popular")
    end
end

function prev_page()
    if current_page > 1 then
        current_page = current_page - 1
        
        if current_view == "movies" then
            load_movies("popular")
        elseif current_view == "tv" then
            load_tv("popular")
        end
    end
end

------------------------------
-- VLC Extension Callbacks
------------------------------

function activate()
    log("Real Debrid Streamer activated")
    
    -- Load configuration
    load_config()
    load_watch_history()
    
    -- Check if API key is configured
    if not config.rd_api_key or config.rd_api_key == "" then
        -- Prompt for API key
        local key_dlg = vlc.dialog("Real Debrid Setup")
        key_dlg:add_label("Welcome to Real Debrid Streamer!", 1, 1, 3, 1)
        key_dlg:add_label("Please enter your Real Debrid API key:", 1, 2, 3, 1)
        
        local key_input = key_dlg:add_text_input("", 1, 3, 3, 1)
        
        key_dlg:add_button("Continue", function()
            local key = key_input:get_text()
            if key and key ~= "" then
                config.rd_api_key = key
                save_config()
                key_dlg:delete()
                create_main_dialog()
            else
                show_error("API key is required")
            end
        end, 1, 4, 1, 1)
        
        key_dlg:add_button("Skip", function()
            key_dlg:delete()
            create_main_dialog()
        end, 2, 4, 1, 1)
    else
        create_main_dialog()
    end
end

function deactivate()
    log("Real Debrid Streamer deactivated")
    
    if dlg then
        dlg:delete()
        dlg = nil
    end
end

function close()
    vlc.deactivate()
end

function input_changed()
    -- Track when media starts playing
    if vlc.input.is_playing() then
        local item = vlc.input.item()
        if item and current_item then
            log("Now playing: " .. (item:name() or "unknown"))
        end
    end
end

function playing_changed()
    -- Monitor playback state changes
end

function meta_changed()
    -- Monitor metadata changes
end

function menu()
    return {
        "Open Streamer",
        "Settings",
        "Search"
    }
end

function trigger_menu(id)
    if id == 1 then
        activate()
    elseif id == 2 then
        activate()
        show_settings_view()
    elseif id == 3 then
        activate()
        show_search_dialog()
    end
end

------------------------------
-- Initialization
------------------------------
log("Real Debrid Streamer extension loaded")
