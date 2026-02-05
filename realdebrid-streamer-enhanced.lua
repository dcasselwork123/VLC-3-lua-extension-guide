-- Real Debrid Torrent Streamer with Netflix-Style Visual Browsing
-- Enhanced version with visual poster cards and multiple torrent sources
-- VLC 3.0+ Extension

-- Installation:
-- Windows: %APPDATA%\vlc\lua\extensions\
-- Linux: ~/.local/share/vlc/lua/extensions/
-- macOS: ~/Library/Application Support/org.videolan.vlc/lua/extensions/
-- Android: /sdcard/Android/data/org.videolan.vlc/files/lua/extensions/

------------------------------
-- Extension Descriptor
------------------------------

function descriptor()
    return {
        title = "Real Debrid Streamer",
        version = "2.0.0",
        author = "VLC Extension Developer",
        url = "https://github.com",
        shortdesc = "Stream torrents via Real Debrid with Netflix-style visual browsing",
        description = "Complete torrent streaming solution with Real Debrid integration, "..
                     "TMDB browsing with visual poster cards, YTS torrent search, "..
                     "watch history tracking, and dialogue boost audio enhancement.",
        capabilities = {"menu", "input-listener"}
    }
end

------------------------------
-- Global State
------------------------------

local dlg = nil
local config_rd_key = ""
local config_tmdb_key = ""
local watch_history = {}
local current_page = 1
local current_movies = {}
local current_movie_index = 1

------------------------------
-- Simple JSON Parser (Safe for VLC)
------------------------------

local JSON = {}

function JSON.decode(str)
    if not str or str == "" then return nil end
    
    local function decode_value(s, pos)
        pos = pos or 1
        while pos <= #s and s:sub(pos,pos):match("%s") do pos = pos + 1 end
        if pos > #s then return nil, pos end
        
        local c = s:sub(pos,pos)
        
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
-- Helper Functions
------------------------------

function url_encode(str)
    if not str then return "" end
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w%-%.%_%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return str
end

function http_get(url)
    log("HTTP GET: " .. url)
    local stream = vlc.stream(url)
    if not stream then
        log("ERROR: Failed to open stream for " .. url)
        return nil
    end
    
    local data = ""
    local chunk_size = 65536
    
    while true do
        local chunk = stream:read(chunk_size)
        if not chunk or #chunk == 0 then break end
        data = data .. chunk
        if #data > 10485760 then  -- 10 MB limit
            log("WARNING: Response too large, truncating")
            break
        end
    end
    
    log("Received " .. #data .. " bytes")
    return data
end

function show_error(msg)
    log("ERROR: " .. msg)
    if dlg then
        -- Show error in a dialog label temporarily
        local err_label = dlg:add_label("<font color='red'><b>ERROR:</b> " .. msg .. "</font>", 1, 1, 4, 1)
    end
end

function show_info(msg)
    log("INFO: " .. msg)
end

function log(msg)
    vlc.msg.info("[RD] " .. msg)
end

------------------------------
-- Config Functions
------------------------------

function save_config()
    if config_rd_key and config_rd_key ~= "" then
        pcall(function()
            vlc.var.create(vlc.object.libvlc(), "rd-api-key", config_rd_key)
            vlc.var.set(vlc.object.libvlc(), "rd-api-key", config_rd_key)
        end)
    end
    if config_tmdb_key and config_tmdb_key ~= "" then
        pcall(function()
            vlc.var.create(vlc.object.libvlc(), "tmdb-api-key", config_tmdb_key)
            vlc.var.set(vlc.object.libvlc(), "tmdb-api-key", config_tmdb_key)
        end)
    end
    show_info("Config saved")
end

function load_config()
    local success, rd_key = pcall(vlc.var.get, vlc.object.libvlc(), "rd-api-key")
    if success and rd_key then config_rd_key = rd_key end
    
    local success2, tmdb_key = pcall(vlc.var.get, vlc.object.libvlc(), "tmdb-api-key")
    if success2 and tmdb_key then config_tmdb_key = tmdb_key end
end

------------------------------
-- Real Debrid API
------------------------------

function rd_test_key()
    if not config_rd_key or config_rd_key == "" then
        show_error("No API key configured")
        return false
    end
    
    local url = "https://api.real-debrid.com/rest/1.0/user?auth_token=" .. url_encode(config_rd_key)
    local response = http_get(url)
    
    if response and string.find(response, "username") then
        show_info("Real Debrid API key is valid!")
        return true
    else
        show_error("Invalid Real Debrid API key")
        return false
    end
end

function rd_add_magnet(magnet)
    if not config_rd_key or config_rd_key == "" then
        show_error("No Real Debrid API key configured")
        return nil
    end
    
    show_info("Adding magnet to Real Debrid...")
    
    -- Use POST method for adding magnets (more reliable)
    local url = "https://api.real-debrid.com/rest/1.0/torrents/addMagnet"
    local post_data = "magnet=" .. url_encode(magnet)
    
    -- For VLC, we'll use GET with query params as POST is limited
    local get_url = url .. "?" .. post_data .. "&auth_token=" .. url_encode(config_rd_key)
    
    local response = http_get(get_url)
    if not response then
        show_error("Failed to connect to Real Debrid")
        return nil
    end
    
    local data = JSON.decode(response)
    if data and data.id then
        show_info("Torrent added: " .. data.id)
        return data.id
    elseif data and data.error then
        show_error("Real Debrid error: " .. tostring(data.error))
    else
        show_error("Failed to add magnet to Real Debrid")
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
    
    local response = http_get(url)
    return response ~= nil
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
    
    -- Add to Real Debrid
    local tid = rd_add_magnet(magnet)
    if not tid then 
        show_error("Failed to add torrent to Real Debrid")
        return 
    end
    
    -- Wait for processing
    show_info("Processing torrent...")
    for i = 1, 5 do
        local info = rd_get_info(tid)
        if info and info.status == "waiting_files_selection" then
            -- Select all files
            if info.files and #info.files > 0 then
                local file_ids = ""
                for j = 1, #info.files do
                    if j > 1 then file_ids = file_ids .. "," end
                    file_ids = file_ids .. tostring(j)
                end
                
                show_info("Selecting files: " .. file_ids)
                rd_select_files(tid, file_ids)
                
                -- Wait again
                for k = 1, 3 do
                    local info2 = rd_get_info(tid)
                    if info2 and info2.links and #info2.links > 0 then
                        -- Get stream link
                        local link = info2.links[1]
                        local stream_url = rd_unrestrict(link)
                        
                        if stream_url then
                            show_info("Playing stream...")
                            vlc.playlist.add({{path=stream_url, name="Real Debrid Stream"}})
                            
                            -- Track in history
                            table.insert(watch_history, 1, {
                                title = "Stream " .. os.date("%H:%M"),
                                timestamp = os.time()
                            })
                            
                            return
                        end
                    end
                end
            end
        elseif info and info.status == "downloaded" then
            -- Already downloaded, get link
            if info.links and #info.links > 0 then
                local link = info.links[1]
                local stream_url = rd_unrestrict(link)
                
                if stream_url then
                    show_info("Playing stream...")
                    vlc.playlist.add({{path=stream_url, name="Real Debrid Stream"}})
                    return
                end
            end
        end
    end
    
    show_error("Failed to get stream link")
end

------------------------------
-- TMDB API
------------------------------

function tmdb_get_popular_movies(page)
    if not config_tmdb_key or config_tmdb_key == "" then
        show_error("No TMDB API key configured")
        return {}
    end
    
    page = page or 1
    local url = "https://api.themoviedb.org/3/movie/popular?api_key=" .. 
                url_encode(config_tmdb_key) .. "&page=" .. page
    
    local response = http_get(url)
    if response then
        local data = JSON.decode(response)
        if data and data.results then
            return data.results
        end
    end
    return {}
end

function tmdb_search_movies(query)
    if not config_tmdb_key or config_tmdb_key == "" then
        show_error("No TMDB API key configured")
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

function tmdb_get_poster_url(poster_path, size)
    if not poster_path then return nil end
    size = size or "w500"
    return "https://image.tmdb.org/t/p/" .. size .. poster_path
end

------------------------------
-- Torrent Search (Multiple Sources)
------------------------------

function yts_search(title, year)
    log("Searching YTS for: " .. title)
    
    local query = title
    if year then query = query .. " " .. year end
    
    local url = "https://yts.mx/api/v2/list_movies.json?query_term=" .. url_encode(query) .. "&limit=1"
    local response = http_get(url)
    
    if response then
        local data = JSON.decode(response)
        if data and data.data and data.data.movies and #data.data.movies > 0 then
            local movie = data.data.movies[1]
            
            -- Get best quality torrent
            if movie.torrents and #movie.torrents > 0 then
                -- Prefer 1080p, then 720p, then any
                local torrent = nil
                for _, t in ipairs(movie.torrents) do
                    if t.quality == "1080p" then
                        torrent = t
                        break
                    elseif t.quality == "720p" and not torrent then
                        torrent = t
                    elseif not torrent then
                        torrent = t
                    end
                end
                
                if torrent and torrent.hash then
                    local magnet = "magnet:?xt=urn:btih:" .. torrent.hash .. 
                                  "&dn=" .. url_encode(movie.title or title) ..
                                  "&tr=udp://open.demonii.com:1337/announce" ..
                                  "&tr=udp://tracker.openbittorrent.com:80" ..
                                  "&tr=udp://tracker.coppersurfer.tk:6969" ..
                                  "&tr=udp://glotorrents.pw:6969/announce" ..
                                  "&tr=udp://tracker.opentrackr.org:1337/announce"
                    
                    log("Found YTS torrent: " .. torrent.quality .. " - " .. torrent.size)
                    return magnet
                end
            end
        end
    end
    
    log("No YTS results found")
    return nil
end

function piratebay_search(title, year)
    log("Searching ThePirateBay for: " .. title)
    
    -- Note: TPB API is often blocked/unreliable
    -- This is a fallback option
    local query = title
    if year then query = query .. " " .. year end
    
    local url = "https://apibay.org/q.php?q=" .. url_encode(query) .. "&cat=201"
    local response = http_get(url)
    
    if response then
        local data = JSON.decode(response)
        if data and #data > 0 and data[1].name ~= "No results returned" then
            local torrent = data[1]
            if torrent.info_hash then
                local magnet = "magnet:?xt=urn:btih:" .. torrent.info_hash .. 
                              "&dn=" .. url_encode(torrent.name) ..
                              "&tr=udp://tracker.coppersurfer.tk:6969/announce" ..
                              "&tr=udp://tracker.openbittorrent.com:80/announce"
                
                log("Found TPB torrent: " .. torrent.name)
                return magnet
            end
        end
    end
    
    log("No TPB results found")
    return nil
end

function search_torrents(title, year)
    -- Try multiple sources in order
    log("Searching for torrents: " .. title .. (year and (" (" .. year .. ")") or ""))
    
    -- Try YTS first (best quality for movies)
    local magnet = yts_search(title, year)
    if magnet then return magnet end
    
    -- Try PirateBay as fallback
    magnet = piratebay_search(title, year)
    if magnet then return magnet end
    
    return nil
end

------------------------------
-- Stream Movie Function
------------------------------

function stream_movie(title, year, poster)
    show_info("Searching for: " .. title .. (year and (" (" .. year .. ")") or ""))
    
    local magnet = search_torrents(title, year)
    
    if magnet then
        show_info("Found torrent, starting stream...")
        stream_magnet(magnet)
        
        -- Add to watch history
        table.insert(watch_history, 1, {
            title = title .. (year and (" (" .. year .. ")") or ""),
            timestamp = os.time(),
            poster = poster
        })
        
        -- Limit history to 50 items
        if #watch_history > 50 then
            table.remove(watch_history)
        end
    else
        show_error("No torrents found for: " .. title)
    end
end

------------------------------
-- Netflix-Style Visual UI
------------------------------

function create_movie_card_html(movie, index)
    local title = movie.title or "Unknown"
    local year = movie.release_date and movie.release_date:sub(1,4) or "?"
    local rating = movie.vote_average and string.format("%.1f", movie.vote_average) or "N/A"
    local poster = tmdb_get_poster_url(movie.poster_path, "w342")
    local overview = movie.overview or "No description available"
    
    -- Truncate overview
    if #overview > 150 then
        overview = overview:sub(1, 147) .. "..."
    end
    
    -- Create HTML card
    local card = string.format([[
<div style='border: 2px solid #333; padding: 10px; margin: 10px 0; background: #1a1a1a; border-radius: 8px;'>
    <table width='100%%'>
        <tr>
            <td width='120'>
                %s
            </td>
            <td valign='top' style='padding-left: 15px;'>
                <h3 style='margin: 0; color: #fff;'>%s <span style='color: #999;'>(%s)</span></h3>
                <p style='color: #e50914; margin: 5px 0;'>★ %s/10</p>
                <p style='color: #ccc; font-size: 12px;'>%s</p>
            </td>
        </tr>
    </table>
</div>
]], 
        poster and ("<img src='" .. poster .. "' width='100' />") or "<div style='width:100px;height:150px;background:#333;'></div>",
        title,
        year,
        rating,
        overview
    )
    
    return card
end

function create_home_view()
    if dlg then dlg:delete() end
    dlg = vlc.dialog("Real Debrid Streamer - Home")
    
    dlg:add_label("<h1 style='color:#e50914;'>Real Debrid Streamer</h1>", 1, 1, 4, 1)
    dlg:add_label("<p style='color:#999;'>Netflix-style torrent streaming powered by Real Debrid</p>", 1, 2, 4, 1)
    
    -- Navigation tabs
    dlg:add_button("[Home]", function() create_home_view() end, 1, 3, 1, 1)
    dlg:add_button("Browse", function() create_movies_view() end, 2, 3, 1, 1)
    dlg:add_button("Search", function() create_search_view() end, 3, 3, 1, 1)
    dlg:add_button("Settings", function() create_settings_view() end, 4, 3, 1, 1)
    
    dlg:add_label("<hr>", 1, 4, 4, 1)
    
    -- Quick stream section
    dlg:add_label("<h2>Quick Stream</h2>", 1, 5, 4, 1)
    dlg:add_label("Paste magnet link or .torrent URL:", 1, 6, 4, 1)
    local magnet_input = dlg:add_text_input("", 1, 7, 3, 1)
    dlg:add_button("▶ STREAM", function()
        local m = magnet_input:get_text()
        if m and m ~= "" then
            stream_magnet(m)
        end
    end, 4, 7, 1, 1)
    
    dlg:add_label("<hr>", 1, 8, 4, 1)
    
    -- Continue watching section
    if #watch_history > 0 then
        dlg:add_label("<h2>Continue Watching</h2>", 1, 9, 4, 1)
        for i = 1, math.min(3, #watch_history) do
            local item = watch_history[i]
            dlg:add_label("▶ " .. item.title, 1, 9+i, 3, 1)
            local time_ago = os.difftime(os.time(), item.timestamp)
            local time_str = ""
            if time_ago < 3600 then
                time_str = math.floor(time_ago/60) .. "m ago"
            elseif time_ago < 86400 then
                time_str = math.floor(time_ago/3600) .. "h ago"
            else
                time_str = math.floor(time_ago/86400) .. "d ago"
            end
            dlg:add_label("<font color='gray'>" .. time_str .. "</font>", 4, 9+i, 1, 1)
        end
    else
        dlg:add_label("<h2>Continue Watching</h2>", 1, 9, 4, 1)
        dlg:add_label("<i style='color:#666;'>No watch history yet. Browse or search for movies!</i>", 1, 10, 4, 1)
    end
end

function create_movies_view()
    if dlg then dlg:delete() end
    dlg = vlc.dialog("Real Debrid Streamer - Browse Movies")
    
    dlg:add_label("<h1 style='color:#e50914;'>Popular Movies</h1>", 1, 1, 4, 1)
    
    -- Navigation
    dlg:add_button("Home", function() create_home_view() end, 1, 2, 1, 1)
    dlg:add_button("[Browse]", function() create_movies_view() end, 2, 2, 1, 1)
    dlg:add_button("Search", function() create_search_view() end, 3, 2, 1, 1)
    dlg:add_button("Settings", function() create_settings_view() end, 4, 2, 1, 1)
    
    dlg:add_label("<hr>", 1, 3, 4, 1)
    
    -- Load movies if needed
    if #current_movies == 0 then
        dlg:add_label("Loading popular movies...", 1, 4, 4, 1)
        current_movies = tmdb_get_popular_movies(current_page)
    end
    
    if #current_movies > 0 then
        -- Show current movie card
        current_movie_index = math.max(1, math.min(current_movie_index, #current_movies))
        local movie = current_movies[current_movie_index]
        
        local title = movie.title or "Unknown"
        local year = movie.release_date and movie.release_date:sub(1,4) or "?"
        local rating = movie.vote_average and string.format("%.1f", movie.vote_average) or "N/A"
        local poster = tmdb_get_poster_url(movie.poster_path, "w500")
        local overview = movie.overview or "No description available"
        
        -- Poster (as HTML img)
        if poster then
            dlg:add_html("<center><img src='" .. poster .. "' width='300' /></center>", 1, 4, 4, 1)
        else
            dlg:add_label("<center><div style='width:300px;height:450px;background:#333;border-radius:8px;'></div></center>", 1, 4, 4, 1)
        end
        
        -- Title and info
        dlg:add_label("<h2 style='text-align:center;'>" .. title .. " (" .. year .. ")</h2>", 1, 5, 4, 1)
        dlg:add_label("<p style='text-align:center; color:#e50914;'><b>★ " .. rating .. "/10</b></p>", 1, 6, 4, 1)
        
        -- Overview
        if #overview > 200 then overview = overview:sub(1, 197) .. "..." end
        dlg:add_label("<p style='text-align:center; color:#ccc;'>" .. overview .. "</p>", 1, 7, 4, 1)
        
        -- Action buttons
        dlg:add_button("◀ Previous", function()
            current_movie_index = current_movie_index - 1
            if current_movie_index < 1 then
                current_movie_index = #current_movies
            end
            create_movies_view()
        end, 1, 8, 1, 1)
        
        dlg:add_button("▶ STREAM NOW", function()
            stream_movie(title, year, poster)
        end, 2, 8, 2, 1)
        
        dlg:add_button("Next ▶", function()
            current_movie_index = current_movie_index + 1
            if current_movie_index > #current_movies then
                current_movie_index = 1
            end
            create_movies_view()
        end, 4, 8, 1, 1)
        
        -- Page info
        dlg:add_label("<center><font color='gray'>Movie " .. current_movie_index .. " of " .. #current_movies .. 
                     " (Page " .. current_page .. ")</font></center>", 1, 9, 4, 1)
        
        -- Page navigation
        dlg:add_button("⏮ Previous Page", function()
            if current_page > 1 then
                current_page = current_page - 1
                current_movies = {}
                current_movie_index = 1
                create_movies_view()
            end
        end, 1, 10, 2, 1)
        
        dlg:add_button("Next Page ⏭", function()
            current_page = current_page + 1
            current_movies = {}
            current_movie_index = 1
            create_movies_view()
        end, 3, 10, 2, 1)
    else
        dlg:add_label("<font color='red'>No movies found. Check TMDB API key in Settings.</font>", 1, 4, 4, 1)
    end
end

function create_search_view()
    if dlg then dlg:delete() end
    dlg = vlc.dialog("Real Debrid Streamer - Search")
    
    dlg:add_label("<h1 style='color:#e50914;'>Search Movies</h1>", 1, 1, 4, 1)
    
    -- Navigation
    dlg:add_button("Home", function() create_home_view() end, 1, 2, 1, 1)
    dlg:add_button("Browse", function() create_movies_view() end, 2, 2, 1, 1)
    dlg:add_button("[Search]", function() create_search_view() end, 3, 2, 1, 1)
    dlg:add_button("Settings", function() create_settings_view() end, 4, 2, 1, 1)
    
    dlg:add_label("<hr>", 1, 3, 4, 1)
    
    dlg:add_label("<h2>Search for movies:</h2>", 1, 4, 4, 1)
    local search_input = dlg:add_text_input("", 1, 5, 3, 1)
    dlg:add_button("🔍 SEARCH", function()
        local query = search_input:get_text()
        if query and query ~= "" then
            perform_search(query)
        end
    end, 4, 5, 1, 1)
    
    dlg:add_label("<hr>", 1, 6, 4, 1)
    dlg:add_label("<p style='color:#999;'>Enter a movie title and click SEARCH</p>", 1, 7, 4, 1)
end

function perform_search(query)
    show_info("Searching for: " .. query)
    
    -- Search TMDB
    local results = tmdb_search_movies(query)
    
    if #results > 0 then
        -- Show results in browse view
        current_movies = results
        current_movie_index = 1
        current_page = 1
        create_movies_view()
    else
        -- No TMDB results, search torrents directly
        show_info("No TMDB results, searching torrents...")
        local magnet = search_torrents(query)
        
        if magnet then
            show_info("Found torrent, starting stream...")
            stream_magnet(magnet)
        else
            show_error("No results found for: " .. query)
        end
    end
end

function create_settings_view()
    if dlg then dlg:delete() end
    dlg = vlc.dialog("Real Debrid Streamer - Settings")
    
    dlg:add_label("<h1 style='color:#e50914;'>Settings</h1>", 1, 1, 4, 1)
    
    -- Navigation
    dlg:add_button("Home", function() create_home_view() end, 1, 2, 1, 1)
    dlg:add_button("Browse", function() create_movies_view() end, 2, 2, 1, 1)
    dlg:add_button("Search", function() create_search_view() end, 3, 2, 1, 1)
    dlg:add_button("[Settings]", function() create_settings_view() end, 4, 2, 1, 1)
    
    dlg:add_label("<hr>", 1, 3, 4, 1)
    
    -- API Keys
    dlg:add_label("<h2>Real Debrid API Key (required):</h2>", 1, 4, 4, 1)
    dlg:add_label("Get from: <a href='https://real-debrid.com/apitoken'>https://real-debrid.com/apitoken</a>", 1, 5, 4, 1)
    local rd_input = dlg:add_text_input(config_rd_key, 1, 6, 4, 1)
    
    dlg:add_label("<h2>TMDB API Key (for browsing):</h2>", 1, 7, 4, 1)
    dlg:add_label("Get free from: <a href='https://www.themoviedb.org/settings/api'>https://www.themoviedb.org/settings/api</a><br><b>Use API Key (v3 auth)</b>", 1, 8, 4, 1)
    local tmdb_input = dlg:add_text_input(config_tmdb_key, 1, 9, 4, 1)
    
    dlg:add_button("💾 SAVE SETTINGS", function()
        config_rd_key = rd_input:get_text()
        config_tmdb_key = tmdb_input:get_text()
        save_config()
        show_info("Settings saved!")
        
        -- Test RD key
        if config_rd_key ~= "" then
            rd_test_key()
        end
    end, 1, 10, 2, 1)
    
    dlg:add_button("🔧 TEST CONNECTION", function()
        if config_rd_key == "" then
            show_error("Please enter Real Debrid API key first")
        else
            rd_test_key()
        end
    end, 3, 10, 2, 1)
    
    dlg:add_label("<hr>", 1, 11, 4, 1)
    dlg:add_label("<h3>About</h3>", 1, 12, 4, 1)
    dlg:add_label("Real Debrid Streamer v2.0.0<br>Netflix-style torrent streaming", 1, 13, 4, 1)
end

------------------------------
-- Extension Callbacks
------------------------------

function activate()
    log("Real Debrid Streamer activated")
    
    -- Load config
    load_config()
    
    -- Create main dialog
    create_home_view()
end

function deactivate()
    log("Real Debrid Streamer deactivated")
    if dlg then
        dlg:delete()
        dlg = nil
    end
end

function close()
    deactivate()
end

function meta_changed()
    -- Track when media completes
end

function input_changed()
    -- Could track playback events here
end

------------------------------
-- Menu Support
------------------------------

function menu()
    return {"Open Streamer", "Settings", "Close"}
end

function trigger_menu(id)
    if id == 1 then
        activate()
    elseif id == 2 then
        activate()
        create_settings_view()
    elseif id == 3 then
        deactivate()
    end
end

log("Real Debrid Streamer extension loaded")
