-- Real Debrid Streamer - Simplified for VLC Compatibility
-- No file I/O, no os.execute - works within VLC's security sandbox
-- All configuration stored in memory (enter API keys each time)

------------------------------
-- Extension Descriptor
------------------------------
function descriptor()
    return {
        title = "Real Debrid Streamer",
        version = "1.1",
        author = "VLC Extension",
        url = "https://github.com",
        shortdesc = "Stream torrents via Real Debrid",
        description = "Stream torrents through Real Debrid API with search and browse features"
    }
end

------------------------------
-- Global Variables
------------------------------
local dlg = nil
local config_rd_key = ""
local config_tmdb_key = ""

------------------------------
-- JSON Parser (Simplified)
------------------------------
local JSON = {}

function JSON.decode(str)
    if not str or str == "" then return nil end
    
    -- Simple JSON parser for basic objects and arrays
    local function parse_value(s, pos)
        local c = s:sub(pos, pos)
        
        if c == '"' then
            -- Parse string
            local start = pos + 1
            local endpos = s:find('"', start, true)
            if endpos then
                return s:sub(start, endpos - 1), endpos + 1
            end
        elseif c == '{' then
            -- Parse object
            local obj = {}
            pos = pos + 1
            while pos <= #s do
                -- Skip whitespace
                while s:sub(pos, pos):match("%s") do pos = pos + 1 end
                if s:sub(pos, pos) == '}' then return obj, pos + 1 end
                
                -- Get key
                local key, newpos = parse_value(s, pos)
                pos = newpos
                
                -- Skip : and whitespace
                while s:sub(pos, pos):match('[%s:]') do pos = pos + 1 end
                
                -- Get value
                local value, newpos2 = parse_value(s, pos)
                obj[key] = value
                pos = newpos2
                
                -- Skip , and whitespace
                while s:sub(pos, pos):match('[%s,]') do pos = pos + 1 end
            end
            return obj, pos
        elseif c == '[' then
            -- Parse array
            local arr = {}
            pos = pos + 1
            while pos <= #s do
                while s:sub(pos, pos):match("%s") do pos = pos + 1 end
                if s:sub(pos, pos) == ']' then return arr, pos + 1 end
                
                local value, newpos = parse_value(s, pos)
                table.insert(arr, value)
                pos = newpos
                
                while s:sub(pos, pos):match('[%s,]') do pos = pos + 1 end
            end
            return arr, pos
        elseif c:match("%d") or c == "-" then
            -- Parse number
            local numstr = s:match("^-?%d+%.?%d*", pos)
            return tonumber(numstr), pos + #numstr
        elseif s:sub(pos, pos + 3) == "true" then
            return true, pos + 4
        elseif s:sub(pos, pos + 4) == "false" then
            return false, pos + 5
        elseif s:sub(pos, pos + 3) == "null" then
            return nil, pos + 4
        end
        
        return nil, pos + 1
    end
    
    local result, _ = parse_value(str, 1)
    return result
end

------------------------------
-- Utility Functions
------------------------------

function url_encode(str)
    if not str then return "" end
    str = tostring(str)
    str = str:gsub("([^%w _%%%-%.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    str = str:gsub(" ", "+")
    return str
end

function http_get(url)
    local stream = vlc.stream(url)
    if not stream then return nil end
    
    local data = ""
    while true do
        local chunk = stream:read(65536)
        if not chunk or #chunk == 0 then break end
        data = data .. chunk
    end
    
    return data
end

function show_msg(title, message)
    vlc.msg.info("[RD] " .. message)
end

------------------------------
-- Real Debrid Functions
------------------------------

function rd_add_magnet(magnet)
    if not config_rd_key or config_rd_key == "" then
        show_msg("Error", "No API key configured")
        return nil
    end
    
    local url = "https://api.real-debrid.com/rest/1.0/torrents/addMagnet?magnet=" .. 
                url_encode(magnet) .. "&auth_token=" .. url_encode(config_rd_key)
    
    local response = http_get(url)
    if response then
        local data = JSON.decode(response)
        if data and data.id then
            return data.id
        end
    end
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
    
    http_get(url)
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
    show_msg("Info", "Adding torrent to Real Debrid...")
    
    local torrent_id = rd_add_magnet(magnet)
    if not torrent_id then
        show_msg("Error", "Failed to add magnet")
        return
    end
    
    show_msg("Info", "Getting torrent info...")
    
    -- Simple wait (count to simulate delay)
    local count = 0
    while count < 1000000 do count = count + 1 end
    
    local info = rd_get_info(torrent_id)
    if not info then
        show_msg("Error", "Failed to get torrent info")
        return
    end
    
    -- Select video files
    if info.files then
        local file_ids = {}
        for i, file in ipairs(info.files) do
            local path = file.path or ""
            if path:match("%.mp4$") or path:match("%.mkv$") or path:match("%.avi$") then
                table.insert(file_ids, tostring(file.id))
            end
        end
        
        if #file_ids > 0 then
            rd_select_files(torrent_id, table.concat(file_ids, ","))
            
            -- Wait again
            count = 0
            while count < 1000000 do count = count + 1 end
            
            info = rd_get_info(torrent_id)
        end
    end
    
    -- Get stream link
    if info.links and #info.links > 0 then
        local stream_url = rd_unrestrict(info.links[1])
        if stream_url then
            vlc.playlist.add({{path = stream_url}})
            show_msg("Success", "Stream started!")
            return
        end
    end
    
    show_msg("Error", "No streamable links found")
end

------------------------------
-- TMDB Functions
------------------------------

function tmdb_search(query)
    if not config_tmdb_key or config_tmdb_key == "" then
        return {}
    end
    
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
-- YTS Functions
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

function yts_get_magnet(movie, quality)
    quality = quality or "1080p"
    
    if movie.torrents then
        for _, torrent in ipairs(movie.torrents) do
            if torrent.quality == quality then
                local hash = torrent.hash
                local title = url_encode(movie.title or "movie")
                return "magnet:?xt=urn:btih:" .. hash .. "&dn=" .. title .. 
                       "&tr=udp://open.demonii.com:1337/announce&tr=udp://tracker.openbittorrent.com:80"
            end
        end
    end
    return nil
end

------------------------------
-- UI Functions
------------------------------

function show_main_dialog()
    if dlg then dlg:delete() end
    
    dlg = vlc.dialog("Real Debrid Streamer")
    
    dlg:add_label("<b>Real Debrid Torrent Streamer</b>", 1, 1, 3, 1)
    
    -- API Key section
    dlg:add_label("Real Debrid API Key:", 1, 2, 3, 1)
    local rd_input = dlg:add_text_input(config_rd_key, 1, 3, 3, 1)
    
    dlg:add_label("TMDB API Key (optional):", 1, 4, 3, 1)
    local tmdb_input = dlg:add_text_input(config_tmdb_key, 1, 5, 3, 1)
    
    dlg:add_button("Save Keys", function()
        config_rd_key = rd_input:get_text()
        config_tmdb_key = tmdb_input:get_text()
        show_msg("Info", "Keys saved for this session")
    end, 1, 6, 1, 1)
    
    -- Magnet input
    dlg:add_label("<hr>", 1, 7, 3, 1)
    dlg:add_label("Magnet Link:", 1, 8, 3, 1)
    local magnet_input = dlg:add_text_input("", 1, 9, 2, 1)
    
    dlg:add_button("Stream", function()
        local magnet = magnet_input:get_text()
        if magnet and magnet ~= "" then
            stream_magnet(magnet)
        end
    end, 3, 9, 1, 1)
    
    -- Search section
    dlg:add_label("<hr>", 1, 10, 3, 1)
    dlg:add_label("Search Movie:", 1, 11, 3, 1)
    local search_input = dlg:add_text_input("", 1, 12, 2, 1)
    
    dlg:add_button("Search", function()
        local query = search_input:get_text()
        if query and query ~= "" then
            search_and_stream(query)
        end
    end, 3, 12, 1, 1)
    
    dlg:add_label("<hr>", 1, 13, 3, 1)
    dlg:add_button("Close", function()
        vlc.deactivate()
    end, 1, 14, 3, 1)
end

function search_and_stream(query)
    show_msg("Info", "Searching for: " .. query)
    
    -- Search TMDB
    local results = tmdb_search(query)
    
    if #results > 0 then
        local movie = results[1]
        local title = movie.title or "Unknown"
        
        show_msg("Info", "Found: " .. title)
        
        -- Search YTS for torrents
        local torrents = yts_search(title)
        
        if #torrents > 0 then
            local torrent = torrents[1]
            local magnet = yts_get_magnet(torrent, "1080p")
            
            if magnet then
                stream_magnet(magnet)
            else
                show_msg("Error", "No magnet link found")
            end
        else
            show_msg("Error", "No torrents found")
        end
    else
        show_msg("Error", "No results found")
    end
end

------------------------------
-- VLC Callbacks
------------------------------

function activate()
    show_msg("Info", "Real Debrid Streamer activated")
    show_main_dialog()
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

function menu()
    return {"Open Streamer", "About"}
end

function trigger_menu(id)
    if id == 1 then
        activate()
    elseif id == 2 then
        show_msg("About", "Real Debrid Streamer v1.1")
    end
end
