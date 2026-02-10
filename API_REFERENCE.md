# API Reference - Real Debrid Streamer

This document provides technical details about the APIs used in the Real Debrid Streamer VLC extension.

## Table of Contents

1. [Real Debrid API](#real-debrid-api)
2. [TMDB API](#tmdb-api)
3. [YTS API](#yts-api)
4. [Internal Functions](#internal-functions)
5. [Configuration Format](#configuration-format)

---

## Real Debrid API

Base URL: `https://api.real-debrid.com/rest/1.0`

### Authentication

All requests require an API token appended as a query parameter:
```
?auth_token=YOUR_API_KEY
```

### Endpoints Used

#### 1. User Info
**Endpoint**: `/user`  
**Method**: GET  
**Purpose**: Validate API key and get user information

**Request**:
```
GET https://api.real-debrid.com/rest/1.0/user?auth_token=YOUR_KEY
```

**Response**:
```json
{
  "id": 12345,
  "username": "johndoe",
  "email": "john@example.com",
  "points": 1000,
  "locale": "en",
  "avatar": "https://...",
  "type": "premium",
  "premium": 1234567890,
  "expiration": "2025-12-31T23:59:59.000Z"
}
```

**Extension Function**: `test_rd_api_key(api_key)`

---

#### 2. Add Magnet
**Endpoint**: `/torrents/addMagnet`  
**Method**: POST (simulated via GET in extension)  
**Purpose**: Add a magnet link to Real Debrid

**Request**:
```
POST https://api.real-debrid.com/rest/1.0/torrents/addMagnet
Body: magnet=magnet:?xt=urn:btih:...&auth_token=YOUR_KEY
```

**Response**:
```json
{
  "id": "ABCD1234EFGH5678",
  "uri": "https://api.real-debrid.com/rest/1.0/torrents/info/ABCD1234EFGH5678"
}
```

**Extension Function**: `rd_add_magnet(magnet_uri, api_key)`

---

#### 3. Torrent Info
**Endpoint**: `/torrents/info/{id}`  
**Method**: GET  
**Purpose**: Get detailed information about a torrent

**Request**:
```
GET https://api.real-debrid.com/rest/1.0/torrents/info/ABCD1234?auth_token=YOUR_KEY
```

**Response**:
```json
{
  "id": "ABCD1234EFGH5678",
  "filename": "Movie.2024.1080p.mkv",
  "hash": "abc123...",
  "bytes": 2147483648,
  "host": "real-debrid.com",
  "split": 2000,
  "progress": 100,
  "status": "downloaded",
  "added": "2024-02-05T10:30:00.000Z",
  "links": [
    "https://real-debrid.com/d/ABC123..."
  ],
  "ended": "2024-02-05T10:35:00.000Z",
  "files": [
    {
      "id": 1,
      "path": "/Movie.2024.1080p.mkv",
      "bytes": 2147483648,
      "selected": 1
    }
  ]
}
```

**Extension Function**: `rd_get_torrent_info(torrent_id, api_key)`

---

#### 4. Select Files
**Endpoint**: `/torrents/selectFiles/{id}`  
**Method**: POST  
**Purpose**: Select which files to download from a multi-file torrent

**Request**:
```
POST https://api.real-debrid.com/rest/1.0/torrents/selectFiles/ABCD1234
Body: files=1,3,5&auth_token=YOUR_KEY
```

**Response**:
```
HTTP 204 No Content
```

**Extension Function**: `rd_select_files(torrent_id, file_ids, api_key)`

**Note**: The extension automatically selects all video files (mp4, mkv, avi)

---

#### 5. Unrestrict Link
**Endpoint**: `/unrestrict/link`  
**Method**: POST  
**Purpose**: Convert a Real Debrid link to a direct streaming URL

**Request**:
```
POST https://api.real-debrid.com/rest/1.0/unrestrict/link
Body: link=https://real-debrid.com/d/...&auth_token=YOUR_KEY
```

**Response**:
```json
{
  "id": "ABC123",
  "filename": "Movie.2024.1080p.mkv",
  "mimeType": "video/x-matroska",
  "filesize": 2147483648,
  "link": "https://real-debrid.com/d/...",
  "host": "1fichier.com",
  "chunks": 16,
  "crc": 1,
  "download": "https://direct-download-url.real-debrid.com/...",
  "streamable": 1
}
```

**Extension Function**: `rd_unrestrict_link(link, api_key)`

**Important**: The `download` field contains the actual streaming URL used by VLC.

---

### Rate Limits

- **No official published limits** for premium users
- Extension implements 2-second delays between requests
- Recommended: Max 10 requests per second

---

## TMDB API

Base URL: `https://api.themoviedb.org/3`

### Authentication

API key passed as query parameter:
```
?api_key=YOUR_TMDB_KEY
```

### Endpoints Used

#### 1. Popular Movies
**Endpoint**: `/movie/popular`  
**Method**: GET  
**Purpose**: Get list of popular movies

**Request**:
```
GET https://api.themoviedb.org/3/movie/popular?api_key=YOUR_KEY&page=1
```

**Response**:
```json
{
  "page": 1,
  "results": [
    {
      "id": 550,
      "title": "Fight Club",
      "original_title": "Fight Club",
      "overview": "A ticking-time-bomb insomniac...",
      "release_date": "1999-10-15",
      "poster_path": "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
      "backdrop_path": "/fCayJrkfRaCRCTh8GqN30f8oyQF.jpg",
      "genre_ids": [18],
      "vote_average": 8.4,
      "vote_count": 26280,
      "popularity": 61.416,
      "adult": false
    }
  ],
  "total_pages": 500,
  "total_results": 10000
}
```

**Extension Function**: `tmdb_get_popular_movies(page)`

---

#### 2. Popular TV Shows
**Endpoint**: `/tv/popular`  
**Method**: GET  
**Purpose**: Get list of popular TV shows

**Request**:
```
GET https://api.themoviedb.org/3/tv/popular?api_key=YOUR_KEY&page=1
```

**Response**:
```json
{
  "page": 1,
  "results": [
    {
      "id": 1396,
      "name": "Breaking Bad",
      "original_name": "Breaking Bad",
      "overview": "When Walter White, a chemistry teacher...",
      "first_air_date": "2008-01-20",
      "poster_path": "/ggFHVNu6YYI5L9pCfOacjizRGt.jpg",
      "backdrop_path": "/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg",
      "genre_ids": [18, 80],
      "vote_average": 8.9,
      "vote_count": 12450,
      "popularity": 451.156
    }
  ],
  "total_pages": 500,
  "total_results": 10000
}
```

**Extension Function**: `tmdb_get_popular_tv(page)`

---

#### 3. Now Playing Movies
**Endpoint**: `/movie/now_playing`  
**Method**: GET  
**Purpose**: Get movies currently in theaters

**Request**:
```
GET https://api.themoviedb.org/3/movie/now_playing?api_key=YOUR_KEY&page=1
```

**Response**: Same format as Popular Movies

**Extension Function**: `tmdb_get_new_releases(page)`

---

#### 4. Search Movies
**Endpoint**: `/search/movie`  
**Method**: GET  
**Purpose**: Search for movies by title

**Request**:
```
GET https://api.themoviedb.org/3/search/movie?api_key=YOUR_KEY&query=inception
```

**Response**: Same format as Popular Movies

**Extension Function**: `tmdb_search(query, "movie")`

---

#### 5. Search TV Shows
**Endpoint**: `/search/tv`  
**Method**: GET  
**Purpose**: Search for TV shows by title

**Request**:
```
GET https://api.themoviedb.org/3/search/tv?api_key=YOUR_KEY&query=breaking%20bad
```

**Response**: Same format as Popular TV Shows

**Extension Function**: `tmdb_search(query, "tv")`

---

#### 6. Movie Details
**Endpoint**: `/movie/{id}`  
**Method**: GET  
**Purpose**: Get detailed information about a specific movie

**Request**:
```
GET https://api.themoviedb.org/3/movie/550?api_key=YOUR_KEY
```

**Response**:
```json
{
  "id": 550,
  "title": "Fight Club",
  "tagline": "Mischief. Mayhem. Soap.",
  "overview": "A ticking-time-bomb insomniac...",
  "runtime": 139,
  "release_date": "1999-10-15",
  "budget": 63000000,
  "revenue": 100853753,
  "genres": [
    {"id": 18, "name": "Drama"}
  ],
  "production_companies": [
    {"id": 508, "name": "Regency Enterprises"}
  ],
  "vote_average": 8.4,
  "vote_count": 26280,
  "imdb_id": "tt0137523"
}
```

**Extension Function**: `tmdb_get_details(id, "movie")`

---

### Rate Limits

- **40 requests per 10 seconds** per IP
- Extension doesn't implement rate limiting (user-driven requests)
- Consider caching results for better performance

---

## YTS API

Base URL: `https://yts.mx/api/v2`

**Note**: YTS only provides movie torrents (no TV shows)

### Endpoints Used

#### 1. List Movies
**Endpoint**: `/list_movies.json`  
**Method**: GET  
**Purpose**: Search for movies and get torrent information

**Request**:
```
GET https://yts.mx/api/v2/list_movies.json?query_term=inception&year=2010
```

**Response**:
```json
{
  "status": "ok",
  "status_message": "Query was successful",
  "data": {
    "movie_count": 1,
    "limit": 20,
    "page_number": 1,
    "movies": [
      {
        "id": 5683,
        "url": "https://yts.mx/movies/inception-2010",
        "imdb_code": "tt1375666",
        "title": "Inception",
        "title_long": "Inception (2010)",
        "year": 2010,
        "rating": 8.8,
        "runtime": 148,
        "genres": ["Action", "Sci-Fi", "Thriller"],
        "summary": "A thief who steals corporate secrets...",
        "synopsis": "Dom Cobb is a skilled thief...",
        "language": "English",
        "mpa_rating": "PG-13",
        "background_image": "https://yts.mx/assets/images/movies/...",
        "medium_cover_image": "https://yts.mx/assets/images/movies/...",
        "large_cover_image": "https://yts.mx/assets/images/movies/...",
        "torrents": [
          {
            "url": "https://yts.mx/torrent/download/...",
            "hash": "B5B5F5757576B5B5F5757576B5B5F575",
            "quality": "720p",
            "type": "web",
            "seeds": 150,
            "peers": 20,
            "size": "1.2 GB",
            "size_bytes": 1288490189,
            "date_uploaded": "2015-10-30 01:05:56",
            "date_uploaded_unix": 1446166056
          },
          {
            "url": "https://yts.mx/torrent/download/...",
            "hash": "A4A4E4646464A4A4E4646464A4A4E464",
            "quality": "1080p",
            "type": "web",
            "seeds": 300,
            "peers": 50,
            "size": "2.4 GB",
            "size_bytes": 2576980378,
            "date_uploaded": "2015-10-30 01:10:56",
            "date_uploaded_unix": 1446166256
          }
        ]
      }
    ]
  }
}
```

**Extension Function**: `yts_search(query, year)`

---

#### Magnet Link Generation

YTS doesn't directly provide magnet links, so the extension generates them:

**Format**:
```
magnet:?xt=urn:btih:{HASH}&dn={TITLE}&tr={TRACKER1}&tr={TRACKER2}...
```

**Trackers Used**:
- `udp://open.demonii.com:1337/announce`
- `udp://tracker.openbittorrent.com:80`
- `udp://tracker.coppersurfer.tk:6969`
- `udp://glotorrents.pw:6969/announce`
- `udp://tracker.opentrackr.org:1337/announce`

**Extension Function**: `yts_get_magnet(movie_data, quality)`

**Example Output**:
```
magnet:?xt=urn:btih:A4A4E4646464A4A4E4646464A4A4E464&dn=Inception%20(2010)&tr=udp://open.demonii.com:1337/announce&tr=udp://tracker.openbittorrent.com:80
```

---

### Rate Limits

- No official rate limits published
- API is publicly accessible
- Consider implementing respectful request patterns

---

## Internal Functions

### JSON Parser

**Self-contained JSON encoder/decoder** (no external dependencies)

#### JSON.encode(table)

Converts Lua table to JSON string.

**Usage**:
```lua
local data = {name = "John", age = 30, active = true}
local json_str = JSON.encode(data)
-- Result: '{"name":"John","age":30,"active":true}'
```

**Supported Types**:
- String → JSON string (with escaping)
- Number → JSON number
- Boolean → JSON boolean
- Table (array) → JSON array
- Table (object) → JSON object
- nil → JSON null

---

#### JSON.decode(string)

Converts JSON string to Lua table.

**Usage**:
```lua
local json_str = '{"name":"John","age":30}'
local data = JSON.decode(json_str)
-- Result: {name = "John", age = 30}
```

**Error Handling**:
```lua
local success, result = pcall(JSON.decode, json_string)
if success then
    -- result contains decoded table
else
    -- result contains error message
end
```

---

### HTTP Functions

#### http_get(url, headers)

Performs HTTP GET request using VLC's stream API.

**Usage**:
```lua
local response = http_get("https://api.example.com/data")
if response then
    local data = JSON.decode(response)
end
```

**Implementation**:
- Uses `vlc.stream(url)` to open connection
- Reads data in 64KB chunks
- Returns complete response body as string
- Returns `nil` on failure

---

#### http_post(url, post_data, headers)

Simulates HTTP POST by appending data to URL (VLC Lua limitation).

**Usage**:
```lua
local data = {key = "value", auth_token = "abc123"}
local response = http_post("https://api.example.com/endpoint", data)
```

**Note**: Due to VLC Lua limitations, POST is simulated via GET. Most Real Debrid endpoints accept GET with query parameters.

---

### Utility Functions

#### url_encode(string)

URL-encodes a string for safe use in URLs.

**Usage**:
```lua
local encoded = url_encode("Hello World!")
-- Result: "Hello+World%21"
```

---

#### log(message)

Logs message to VLC console with extension prefix.

**Usage**:
```lua
log("Torrent added successfully")
-- Output: [RD Streamer] Torrent added successfully
```

---

#### show_error(message)

Displays error dialog to user and logs error.

**Usage**:
```lua
show_error("Invalid API key")
-- Shows VLC dialog with error message
```

---

### Configuration Functions

#### load_config()

Loads configuration from JSON file.

**Returns**: `true` if loaded, `false` if not found or error

**Default Config**:
```lua
{
    rd_api_key = "",
    tmdb_api_key = "",
    dialogue_boost = "medium",
    auto_subtitles = true,
    last_updated = os.time()
}
```

---

#### save_config()

Saves current configuration to JSON file.

**Returns**: `true` if saved, `false` on error

---

#### load_watch_history()

Loads watch history from JSON file.

**Returns**: `true` if loaded, `false` if not found

---

#### save_watch_history()

Saves watch history to JSON file.

**Returns**: `true` if saved, `false` on error

---

#### add_to_history(item_id, title, media_type, timestamp)

Adds item to watch history (limited to 100 items).

**Usage**:
```lua
add_to_history(550, "Fight Club", "movie", os.time())
```

---

## Configuration Format

### config.json

**Location**:
- Windows: `%APPDATA%\vlc\lua\extensions\rd_streamer\config.json`
- Linux: `~/.config/vlc/rd_streamer/config.json`
- macOS: `~/Library/Application Support/vlc/rd_streamer/config.json`
- Android: `/sdcard/Android/data/org.videolan.vlc/files/rd_streamer/config.json`

**Structure**:
```json
{
  "rd_api_key": "ABCDEFG1234567890",
  "tmdb_api_key": "1234567890abcdefg",
  "dialogue_boost": "medium",
  "auto_subtitles": true,
  "last_updated": 1707134400
}
```

**Fields**:
- `rd_api_key` (string): Real Debrid API token
- `tmdb_api_key` (string): TMDB API key (v3)
- `dialogue_boost` (string): "low", "medium", or "high"
- `auto_subtitles` (boolean): Enable auto subtitle fetch (not fully implemented)
- `last_updated` (number): Unix timestamp of last update

---

### watch_history.json

**Location**: Same directory as config.json

**Structure**:
```json
[
  {
    "id": 550,
    "title": "Fight Club",
    "type": "movie",
    "timestamp": 1707134400,
    "watched": true
  },
  {
    "id": 1396,
    "title": "Breaking Bad",
    "type": "tv",
    "timestamp": 1707134300,
    "watched": true
  }
]
```

**Fields**:
- `id` (number): TMDB ID
- `title` (string): Movie/show title
- `type` (string): "movie" or "tv"
- `timestamp` (number): Unix timestamp when watched
- `watched` (boolean): Always true (for future partial watch tracking)

**Limits**: Maximum 100 entries (oldest removed)

---

## VLC Lua API Reference

### vlc.dialog

Used for creating UI dialogs.

**Methods**:
- `vlc.dialog(title)` - Create new dialog
- `dialog:add_label(text, x, y, w, h)` - Add text label
- `dialog:add_button(text, func, x, y, w, h)` - Add button
- `dialog:add_text_input(default, x, y, w, h)` - Add text input
- `dialog:add_html(html, x, y, w, h)` - Add HTML widget (limited)
- `dialog:add_dropdown(x, y, w, h)` - Add dropdown menu
- `dialog:delete()` - Close dialog

---

### vlc.stream

Used for HTTP requests.

**Usage**:
```lua
local stream = vlc.stream(url)
if stream then
    local data = stream:read(65536)  -- Read 64KB
end
```

---

### vlc.playlist

Used for managing VLC playlist.

**Methods**:
- `vlc.playlist.add(items)` - Add items to playlist
- `vlc.playlist.play()` - Start playback
- `vlc.playlist.stop()` - Stop playback

---

### vlc.config

Used for VLC configuration (not heavily used in extension).

---

### vlc.input

Used for accessing current media input.

**Methods**:
- `vlc.input.is_playing()` - Check if media is playing
- `vlc.input.item()` - Get current media item

---

## Error Handling

### Common Error Codes

**Real Debrid API**:
- `401` - Invalid API key
- `403` - Forbidden (account issue)
- `503` - Service unavailable
- `402` - Payment required (premium expired)

**TMDB API**:
- `401` - Invalid API key
- `404` - Resource not found
- `429` - Rate limit exceeded

**Extension Errors**:
- "API key is empty" - No API key configured
- "Invalid API key or connection error" - Authentication failed
- "Failed to add magnet" - Real Debrid rejected magnet
- "No torrents found" - YTS search returned no results
- "No streamable links found" - Torrent has no video files

---

## Performance Considerations

### API Call Timing

- Real Debrid: ~500-2000ms per request
- TMDB: ~200-1000ms per request
- YTS: ~300-1500ms per request

### Optimization Tips

1. **Cache TMDB results** - Store popular movies/shows locally
2. **Batch operations** - Minimize sequential API calls
3. **User feedback** - Show loading indicators
4. **Error recovery** - Implement retry logic
5. **Rate limiting** - Add delays between requests

---

## Security Notes

### API Key Storage

- Stored in plaintext (filesystem permissions provide security)
- No encryption implemented (VLC Lua has no crypto libraries)
- Consider external key management for sensitive deployments

### HTTPS

- All API calls use HTTPS
- VLC handles SSL/TLS verification
- No custom certificate validation

### Data Privacy

- No telemetry or tracking
- All data stays local
- Direct API calls (no proxy servers)

---

## Future API Enhancements

### Planned Integrations

- **OpenSubtitles API**: Automatic subtitle download
- **Trakt API**: Cross-device watch sync
- **IMDb API**: Additional ratings and metadata
- **Multiple Torrent Sources**: RARBG, 1337x, ThePirateBay

### Planned Features

- Better error messages with retry options
- Caching layer for API responses
- Background API calls (if VLC supports)
- Websocket support for real-time updates

---

**Last Updated**: February 5, 2025  
**API Versions**: Real Debrid v1.0, TMDB v3, YTS v2
