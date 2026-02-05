-- Real Debrid Streamer - Full Version with Netflix UI
-- Uses VLC variables for config storage (allowed by sandbox)
-- Version 1.2 - Full Featured

------------------------------
-- Extension Descriptor
------------------------------
function descriptor()
    return {
        title = "Real Debrid Streamer",
        version = "1.2",
        author = "VLC Extension",
        url = "https://github.com",
        shortdesc = "Stream torrents via Real Debrid - Netflix UI",
        description = "Full-featured torrent streaming with Netflix-style browsing, TMDB integration, and watch tracking",
        capabilities = {"menu", "input-listener"}
    }
end

------------------------------
-- Global Variables  
------------------------------
local dlg = nil
local config_rd_key = ""
local config_tmdb_key = ""
local current_view = "home"
local browse_cache = {}
local watch_history = {}

------------------------------
-- Minimal JSON Parser
------------------------------
local JSON = {}

function JSON.decode(str)
    if not str or str == "" then return nil end
    
    -- Ultra-simple JSON decoder for Real Debrid/TMDB responses
    local function decode_value(s, pos)
        while pos <= #s and s:sub(pos,pos):match("%s") do pos = pos + 1 end
        if pos > #s then return nil, pos end
        
        local c = s:sub(pos, pos)
        
        if c == '"' then
            local endpos = pos + 1
            while endpos <= #s and s:sub(endpos,endpos) ~= '"' do
                if s:sub(endpos,endpos) == '\\' then endpos = endpos + 1 end
                endpos = endpos + 1
            end
            return s:sub(pos+1, endpos-1), endpos + 1
            
        elseif c == '{' then
            local obj = {}
            pos = pos + 1
            while pos <= #s do
                while pos <= #s and s:sub(pos,pos):match("%s") do pos = pos + 1 end
                if s:sub(pos,pos) == '}' then return obj, pos + 1 end
                
                local key, newpos = decode_value(s, pos)
                pos = newpos
                while pos <= #s and (s:sub(pos,pos):match("%s") or s:sub(pos,pos) == ':') do pos = pos + 1 end
                
                local value
                value, pos = decode_value(s, pos)
                if key then obj[key] = value end
                
                while pos <= #s and (s:sub(pos,pos):match("%s") or s:sub(pos,pos) == ',') do pos = pos + 1 end
            end
            return obj, pos
            
        elseif c == '[' then
            local arr = {}
            pos = pos + 1
            while pos <= #s do
                while pos <= #s and s:sub(pos,pos):match("%s") do pos = pos + 1 end
                if s:sub(pos,pos) == ']' then return arr, pos + 1 end
                
                local value
                value, pos = decode_value(s, pos)
                table.insert(arr, value)
                
                while pos <= #s and (s:sub(pos,pos):match("%s") or s:sub(pos,pos) == ',') do pos = pos + 1 end
            end
            return arr, pos
            
        elseif c:match("[%d%-]") then
            local numstr = s:match("^-?%d+%.?%d*", pos)
            return tonumber(numstr), pos + #numstr
            
        elseif s:sub(pos, pos+3) == "true" then
            return true, pos + 4
        elseif s:sub(pos, pos+4) == "false" then
            return false, pos + 5
        elseif s:sub(pos, pos+3) == "null" then
            return nil, pos + 4
        end
        
        return nil, pos + 1
    end
    
    local result, _ = decode_value(str, 1)
    return result
end

------------------------------
-- Utility Functions
------------------------------

function url_encode(str)
    if not str then return "" end
    str = tostring(str):gsub("([^%w _%%%-%.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "+")
    return str
end

function http_get(url)
    vlc.msg.info("[RD] HTTP GET: " .. url)
    
    local stream = vlc.stream(url)
    if not stream then
        vlc.msg.err("[RD] Failed to open stream")
        return nil
    end
    
    local data = ""
    local chunk_size = 65536
    local max_size = 10485760  -- 10MB max
    
    while #data < max_size do
        local chunk = stream:read(chunk_size)
        if not chunk or #chunk == 0 then break end
        data = data .. chunk
    end
    
    vlc.msg.info("[RD] Received " .. #data .. " bytes")
    return data
end

function show_error(msg)
    vlc.msg.err("[RD] " .. msg)
    if dlg then
        -- Try to show in UI if possible
        local err_label = dlg:add_label("<font color='red'><b>Error: " .. msg .. "</b></font>", 1, 20, 4, 1)
    end
end

function show_info(msg)
    vlc.msg.info("[RD] " .. msg)
end

------------------------------
-- Config Functions (using VLC variables)
------------------------------

function save_config()
    -- VLC variables should persist in some builds
    if config_rd_key and config_rd_key ~= "" then
        vlc.var.create(vlc.object.libvlc(), "rd-api-key", config_rd_key)
        vlc.var.set(vlc.object.libvlc(), "rd-api-key", config_rd_key)
    end
    if config_tmdb_key and config_tmdb_key ~= "" then
        vlc.var.create(vlc.object.libvlc(), "tmdb-api-key", config_tmdb_key)
        vlc.var.set(vlc.object.libvlc(), "tmdb-api-key", config_tmdb_key)
    end
    show_info("Config saved to VLC variables")
end

function load_config()
    -- Try to load from VLC variables
    local success, rd_key = pcall(vlc.var.get, vlc.object.libvlc(), "rd-api-key")
    if success and rd_key then
        config_rd_key = rd_key
    end
    
    local success2, tmdb_key = pcall(vlc.var.get, vlc.object.libvlc(), "tmdb-api-key")
    if success2 and tmdb_key then
        config_tmdb_key = tmdb_key
    end
end

------------------------------
-- Real Debrid API
------------------------------

function rd_add_magnet(magnet)
    if not config_rd_key or config_rd_key == "" then
        show_error("No Real Debrid API key configured")
        return nil
    end
    
    show_info("Adding magnet to Real Debrid...")
    
    local url = "https://api.real-debrid.com/rest/1.0/torrents/addMagnet?magnet=" .. 
                url_encode(magnet) .. "&auth_token=" .. url_encode(config_rd_key)
    
    local response = http_get(url)
    if not response then
        show_error("Failed to connect to Real Debrid")
        return nil
    end
    
    local data = JSON.decode(response)
    if data and data.id then
        show_info("Torrent added: " .. data.id)
        return data.id
    end
    
    show_error("Failed to add magnet")
    return nil
end

function rd_get_info(torrent_id)
    local url = "https://api.real-debrid.com/rest/1.0/torrents/info/" .. 
                torrent_id .. "?auth_token=" .. url_encode(config_rd_key)
    
    local response = http_get(url)
    if response then
        return JSON.decode(response)
    end
    return nil
end

function rd_select_files(torrent_id, file_ids)
    local url = "https://api.real-debrid.com/rest/1.0/torrents/selectFiles/" .. 
                torrent_id .. "?files=" .. file_ids .. "&auth_token=" .. url_encode(config_rd_key)
    return http_get(url) ~= nil
end

function rd_unrestrict(link)
    local url = "https://api.real-debrid.com/rest/1.0/unrestrict/link?link=" .. 
                url_encode(link) .. "&auth_token=" .. url_encode(config_rd_key)
    
    local response = http_get(url)
    if response then
        local data = JSON.decode(response)
        if data and data.download then
            return data.download
        end
    end
    return nil
end

function stream_magnet(magnet)
    show_info("Starting stream process...")
    
    local tid = rd_add_magnet(magnet)
    if not tid then return end
    
    -- Simple busy-wait delay
    show_info("Waiting for torrent processing...")
    for i=1,5000000 do end
    
    local info = rd_get_info(tid)
    if not info then
        show_error("Failed to get torrent info")
        return
    end
    
    -- Select video files
    if info.files then
        local ids = {}
        for _, f in ipairs(info.files) do
            local p = f.path or ""
            if p:match("%.mp4$") or p:match("%.mkv$") or p:match("%.avi$") then
                table.insert(ids, tostring(f.id))
            end
        end
        
        if #ids > 0 then
            show_info("Selecting " .. #ids .. " video files...")
            rd_select_files(tid, table.concat(ids, ","))
            
            for i=1,5000000 do end
            info = rd_get_info(tid)
        end
    end
    
    -- Get stream URL
    if info.links and #info.links > 0 then
        show_info("Getting stream URL...")
        local stream_url = rd_unrestrict(info.links[1])
        
        if stream_url then
            show_info("Starting playback!")
            vlc.playlist.add({{path = stream_url, name = "Real Debrid Stream"}})
            vlc.playlist.play()
            return true
        end
    end
    
    show_error("No streamable links found")
    return false
end

------------------------------
-- TMDB API
------------------------------

function tmdb_get_popular_movies()
    if not config_tmdb_key or config_tmdb_key == "" then return {} end
    
    local url = "https://api.themoviedb.org/3/movie/popular?api_key=" .. url_encode(config_tmdb_key)
    local response = http_get(url)
    
    if response then
        local data = JSON.decode(response)
        if data and data.results then
            return data.results
        end
    end
    return {}
end

function tmdb_search(query)
    if not config_tmdb_key or config_tmdb_key == "" then return {} end
    
    local url = "https://api.themoviedb.org/3/search/movie?api_key=" .. 
                url_encode(config_tmdb_key) .. "&query=" .. url_encode(query)
    local response = http_get(url)
    
    if response then
        local data = JSON.decode(response)
        if data and data.results then
            return data.results
        end
    end
    return {}
end

------------------------------
-- YTS API
------------------------------

function yts_search(title)
    local url = "https://yts.mx/api/v2/list_movies.json?query_term=" .. url_encode(title)
    local response = http_get(url)
    
    if response then
        local data = JSON.decode(response)
        if data and data.data and data.data.movies then
            return data.data.movies
        end
    end
    return {}
end

function yts_get_magnet(movie)
    if movie.torrents and #movie.torrents > 0 then
        local torrent = movie.torrents[1]  -- Use first available quality
        local hash = torrent.hash
        local title = url_encode(movie.title or "movie")
        return "magnet:?xt=urn:btih:" .. hash .. "&dn=" .. title .. 
               "&tr=udp://open.demonii.com:1337/announce&tr=udp://tracker.openbittorrent.com:80"
    end
    return nil
end

------------------------------
-- Netflix-Style UI
------------------------------

function create_home_view()
    if dlg then dlg:delete() end
    dlg = vlc.dialog("Real Debrid Streamer - Home")
    
    dlg:add_label("<h1>Real Debrid Streamer</h1>", 1, 1, 4, 1)
    dlg:add_label("<i>Netflix-style torrent streaming</i>", 1, 2, 4, 1)
    
    -- Navigation tabs
    dlg:add_button("[Home]", function() create_home_view() end, 1, 3, 1, 1)
    dlg:add_button("Movies", function() create_movies_view() end, 2, 3, 1, 1)
    dlg:add_button("Search", function() create_search_view() end, 3, 3, 1, 1)
    dlg:add_button("Settings", function() create_settings_view() end, 4, 3, 1, 1)
    
    dlg:add_label("<hr>", 1, 4, 4, 1)
    
    -- Quick stream section
    dlg:add_label("<b>Quick Stream</b>", 1, 5, 4, 1)
    dlg:add_label("Paste magnet link:", 1, 6, 4, 1)
    local magnet_input = dlg:add_text_input("", 1, 7, 3, 1)
    dlg:add_button("STREAM", function()
        local m = magnet_input:get_text()
        if m and m ~= "" then
            stream_magnet(m)
        end
    end, 4, 7, 1, 1)
    
    dlg:add_label("<hr>", 1, 8, 4, 1)
    
    -- Watch history
    dlg:add_label("<b>Recently Watched</b>", 1, 9, 4, 1)
    if #watch_history > 0 then
        for i = 1, math.min(3, #watch_history) do
            dlg:add_label("- " .. watch_history[i].title, 1, 9+i, 4, 1)
        end
    else
        dlg:add_label("<i>No watch history yet</i>", 1, 10, 4, 1)
    end
end

function create_movies_view()
    if dlg then dlg:delete() end
    dlg = vlc.dialog("Real Debrid Streamer - Movies")
    
    dlg:add_label("<h1>Popular Movies</h1>", 1, 1, 4, 1)
    
    -- Navigation
    dlg:add_button("Home", function() create_home_view() end, 1, 2, 1, 1)
    dlg:add_button("[Movies]", function() create_movies_view() end, 2, 2, 1, 1)
    dlg:add_button("Search", function() create_search_view() end, 3, 2, 1, 1)
    dlg:add_button("Settings", function() create_settings_view() end, 4, 2, 1, 1)
    
    dlg:add_label("<hr>", 1, 3, 4, 1)
    
    -- Load popular movies
    dlg:add_label("Loading popular movies...", 1, 4, 4, 1)
    
    local movies = tmdb_get_popular_movies()
    
    if #movies > 0 then
        dlg:add_label("Found " .. #movies .. " movies:", 1, 5, 4, 1)
        
        for i = 1, math.min(10, #movies) do
            local movie = movies[i]
            local title = movie.title or "Unknown"
            local year = movie.release_date and movie.release_date:sub(1,4) or "?"
            local rating = movie.vote_average or "N/A"
            
            local row = 5 + i
            dlg:add_label(title .. " (" .. year .. ") - Rating: " .. rating, 1, row, 3, 1)
            dlg:add_button("Stream", function()
                stream_movie(title, year)
            end, 4, row, 1, 1)
        end
    else
        dlg:add_label("<font color='red'>No movies found. Check TMDB API key in Settings.</font>", 1, 5, 4, 1)
    end
end

function create_search_view()
    if dlg then dlg:delete() end
    dlg = vlc.dialog("Real Debrid Streamer - Search")
    
    dlg:add_label("<h1>Search</h1>", 1, 1, 4, 1)
    
    -- Navigation
    dlg:add_button("Home", function() create_home_view() end, 1, 2, 1, 1)
    dlg:add_button("Movies", function() create_movies_view() end, 2, 2, 1, 1)
    dlg:add_button("[Search]", function() create_search_view() end, 3, 2, 1, 1)
    dlg:add_button("Settings", function() create_settings_view() end, 4, 2, 1, 1)
    
    dlg:add_label("<hr>", 1, 3, 4, 1)
    
    dlg:add_label("Search for movies:", 1, 4, 4, 1)
    local search_input = dlg:add_text_input("", 1, 5, 3, 1)
    dlg:add_button("SEARCH", function()
        local query = search_input:get_text()
        if query and query ~= "" then
            perform_search(query)
        end
    end, 4, 5, 1, 1)
    
    dlg:add_label("<hr>", 1, 6, 4, 1)
    dlg:add_label("Results will appear here...", 1, 7, 4, 1)
end

function create_settings_view()
    if dlg then dlg:delete() end
    dlg = vlc.dialog("Real Debrid Streamer - Settings")
    
    dlg:add_label("<h1>Settings</h1>", 1, 1, 4, 1)
    
    -- Navigation
    dlg:add_button("Home", function() create_home_view() end, 1, 2, 1, 1)
    dlg:add_button("Movies", function() create_movies_view() end, 2, 2, 1, 1)
    dlg:add_button("Search", function() create_search_view() end, 3, 2, 1, 1)
    dlg:add_button("[Settings]", function() create_settings_view() end, 4, 2, 1, 1)
    
    dlg:add_label("<hr>", 1, 3, 4, 1)
    
    -- API Keys
    dlg:add_label("<b>Real Debrid API Key (required):</b>", 1, 4, 4, 1)
    dlg:add_label("Get from: https://real-debrid.com/apitoken", 1, 5, 4, 1)
    local rd_input = dlg:add_text_input(config_rd_key, 1, 6, 4, 1)
    
    dlg:add_label("<b>TMDB API Key (for browsing):</b>", 1, 7, 4, 1)
    dlg:add_label("Get free from: https://www.themoviedb.org/settings/api", 1, 8, 4, 1)
    local tmdb_input = dlg:add_text_input(config_tmdb_key, 1, 9, 4, 1)
    
    dlg:add_button("SAVE SETTINGS", function()
        config_rd_key = rd_input:get_text()
        config_tmdb_key = tmdb_input:get_text()
        save_config()
        show_info("Settings saved!")
    end, 1, 10, 4, 1)
end

function stream_movie(title, year)
    show_info("Searching torrents for: " .. title)
    
    local torrents = yts_search(title)
    
    if #torrents > 0 then
        local magnet = yts_get_magnet(torrents[1])
        if magnet then
            table.insert(watch_history, 1, {title = title, year = year, timestamp = os.time()})
            stream_magnet(magnet)
        else
            show_error("No magnet link found")
        end
    else
        show_error("No torrents found for: " .. title)
    end
end

function perform_search(query)
    show_info("Searching for: " .. query)
    
    local results = tmdb_search(query)
    
    if #results > 0 then
        -- Rebuild dialog with results
        if dlg then dlg:delete() end
        dlg = vlc.dialog("Search Results")
        
        dlg:add_label("<h2>Results for: " .. query .. "</h2>", 1, 1, 4, 1)
        dlg:add_button("Back", function() create_search_view() end, 1, 2, 4, 1)
        dlg:add_label("<hr>", 1, 3, 4, 1)
        
        for i = 1, math.min(10, #results) do
            local movie = results[i]
            local title = movie.title or "Unknown"
            local year = movie.release_date and movie.release_date:sub(1,4) or "?"
            
            local row = 3 + i
            dlg:add_label(title .. " (" .. year .. ")", 1, row, 3, 1)
            dlg:add_button("Stream", function()
                stream_movie(title, year)
            end, 4, row, 1, 1)
        end
    else
        show_error("No results found")
    end
end

------------------------------
-- VLC Callbacks
------------------------------

function activate()
    show_info("Real Debrid Streamer activated")
    load_config()
    
    if not config_rd_key or config_rd_key == "" then
        -- First run - show settings
        create_settings_view()
    else
        create_home_view()
    end
end

function deactivate()
    if dlg then
        dlg:delete()
        dlg = nil
    end
end

function close()
    vlc.deactivate()
end

function input_changed()
    -- Track playback events
    if vlc.input and vlc.input.is_playing then
        local is_playing = vlc.input.is_playing()
        if is_playing then
            show_info("Playback started")
        end
    end
end

function menu()
    return {"Open Streamer", "Settings", "About"}
end

function trigger_menu(id)
    if id == 1 then
        activate()
    elseif id == 2 then
        create_settings_view()
    elseif id == 3 then
        show_info("Real Debrid Streamer v1.2 - Full Featured")
    end
end
