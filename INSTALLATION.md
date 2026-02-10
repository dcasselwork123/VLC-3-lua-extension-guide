# Real Debrid Streamer - Installation & Setup Guide

## Overview
Real Debrid Streamer is a VLC extension that allows you to:
- Stream torrents directly through Real Debrid API
- Browse movies and TV shows with a Netflix-style interface
- Track your watch history
- Apply dialogue boost for better voice clarity
- Auto-fetch subtitles

## Requirements
- **VLC Media Player 3.x or later** (Windows, Linux, macOS, or Android)
- **Real Debrid Account** (Premium) - [Sign up here](https://real-debrid.com)
- **TMDB API Key** (Optional, free) - [Get one here](https://www.themoviedb.org/settings/api)

## Installation Steps

### Windows

1. **Locate VLC Extensions Folder**:
   - Open File Explorer and navigate to: `%APPDATA%\vlc\lua\extensions\`
   - If the folder doesn't exist, create it:
     - `C:\Users\YourUsername\AppData\Roaming\vlc\lua\extensions\`

2. **Copy Extension File**:
   - Copy `realdebrid-streamer.lua` to the extensions folder

3. **Restart VLC**:
   - Close and reopen VLC Media Player

4. **Verify Installation**:
   - Go to `View` → `Real Debrid Streamer` (or `Tools` → `Extensions`)
   - You should see the extension in the menu

### Linux

1. **Locate VLC Extensions Folder**:
   ```bash
   mkdir -p ~/.local/share/vlc/lua/extensions/
   ```

2. **Copy Extension File**:
   ```bash
   cp realdebrid-streamer.lua ~/.local/share/vlc/lua/extensions/
   ```

3. **Set Permissions**:
   ```bash
   chmod 644 ~/.local/share/vlc/lua/extensions/realdebrid-streamer.lua
   ```

4. **Restart VLC**:
   ```bash
   vlc
   ```

### macOS

1. **Locate VLC Extensions Folder**:
   ```bash
   mkdir -p ~/Library/Application\ Support/org.videolan.vlc/lua/extensions/
   ```

2. **Copy Extension File**:
   ```bash
   cp realdebrid-streamer.lua ~/Library/Application\ Support/org.videolan.vlc/lua/extensions/
   ```

3. **Restart VLC**

### Android (Nvidia Shield, etc.)

1. **Connect Device**:
   - Use a file manager app (like Solid Explorer or Total Commander)
   - Or connect via USB and use ADB

2. **Navigate to VLC Extensions Folder**:
   ```
   /sdcard/Android/data/org.videolan.vlc/files/lua/extensions/
   ```
   - If the folder doesn't exist, create it using your file manager

3. **Copy Extension File**:
   - Transfer `realdebrid-streamer.lua` to the extensions folder

4. **Restart VLC**

## First-Time Setup

### Step 1: Get Your Real Debrid API Key

1. **Login to Real Debrid**:
   - Go to [https://real-debrid.com](https://real-debrid.com)
   - Login with your premium account

2. **Generate API Token**:
   - Navigate to: [https://real-debrid.com/apitoken](https://real-debrid.com/apitoken)
   - Copy your API token (it looks like: `ABC123XYZ456...`)

### Step 2: Get TMDB API Key (Optional but Recommended)

1. **Create TMDB Account**:
   - Go to [https://www.themoviedb.org](https://www.themoviedb.org)
   - Sign up for a free account

2. **Request API Key**:
   - Go to Settings → API: [https://www.themoviedb.org/settings/api](https://www.themoviedb.org/settings/api)
   - Request a new API key (choose "Developer")
   - Fill in the application details (personal use is fine)
   - Copy your API key (v3 auth)

### Step 3: Configure Extension

1. **Launch Extension**:
   - In VLC, go to `View` → `Real Debrid Streamer`
   - Or `Tools` → `Extensions` → `Real Debrid Streamer`

2. **Enter API Keys**:
   - On first launch, you'll be prompted for your Real Debrid API key
   - Paste your Real Debrid API key and click "Continue"
   - Go to Settings (⚙️ button) to add your TMDB API key

3. **Test Configuration**:
   - In Settings, click "Test" next to your Real Debrid API key
   - You should see: "✅ API key is valid!"

## Usage Guide

### Streaming a Torrent/Magnet Link

**Method 1: Direct Input**
1. Open the extension (Home view)
2. Paste a magnet link in the text field
3. Click "▶️ Stream"
4. Wait for the torrent to be processed (2-5 seconds)
5. VLC will automatically start playing the stream

**Method 2: Browse and Search**
1. Click "🎬 Movies" or "📺 TV Shows"
2. Browse popular content or click "Search"
3. Enter a movie/show title
4. The extension will automatically find torrents and stream via Real Debrid

### Browsing Content

**Movies**:
- Click "🎬 Movies" tab
- Choose from:
  - **Popular**: Most popular movies right now
  - **New Releases**: Recently released movies
- Use pagination (◀️ Previous / Next ▶️) to browse

**TV Shows**:
- Click "📺 TV Shows" tab
- Browse popular TV shows
- Use search to find specific shows

### Watch History

- All streamed content is automatically tracked
- View recent history on the Home screen
- History is saved locally in VLC's data directory

### Dialogue Boost

The dialogue boost feature enhances voice clarity in movies and TV shows:

1. **Enable During Playback**:
   - Go to Settings (⚙️)
   - Select dialogue boost level:
     - **Low**: Subtle enhancement
     - **Medium**: Balanced boost (recommended)
     - **High**: Maximum voice clarity
   - Click "Apply"

2. **How It Works**:
   - Boosts mid-range frequencies (200-4000 Hz) where human voices live
   - Applies audio equalization filters
   - Works in real-time during playback

3. **Disable**:
   - Go to Settings
   - Click "Disable" button

### Search Functionality

1. Click "🔍 Search" button (Home or Movies/TV views)
2. Enter your search query
3. Select type (Movie or TV Show)
4. Click "🔍 Search"
5. Extension will:
   - Search TMDB for metadata
   - Find matching torrents on YTS
   - Stream via Real Debrid automatically

## Troubleshooting

### Extension Doesn't Appear in Menu

**Solution**:
1. Verify the file is in the correct location:
   - Windows: `%APPDATA%\vlc\lua\extensions\realdebrid-streamer.lua`
   - Linux: `~/.local/share/vlc/lua/extensions/realdebrid-streamer.lua`
   - macOS: `~/Library/Application Support/org.videolan.vlc/lua/extensions/realdebrid-streamer.lua`
2. Make sure the file has the `.lua` extension
3. Restart VLC completely
4. Check VLC logs: Run VLC with `-vv` flag to see verbose logs

### "Invalid API Key" Error

**Solution**:
1. Verify you copied the entire API token from Real Debrid
2. Make sure you have an active premium subscription
3. Test your API key directly:
   - Visit: `https://api.real-debrid.com/rest/1.0/user?auth_token=YOUR_TOKEN`
   - Should return JSON with your user info
4. Generate a new API token if needed

### No Torrents Found

**Solution**:
1. Try different search terms (simpler is better)
2. Search for popular content first to verify functionality
3. YTS only has movies (not TV shows)
4. Check if YTS is accessible in your region
5. Try entering a magnet link directly instead

### Stream Won't Play

**Solution**:
1. Verify your Real Debrid account is active
2. Check Real Debrid website for service status
3. Make sure the torrent has seeders
4. Try a different torrent/magnet link
5. Check VLC logs for errors: `Tools` → `Messages` (set Verbosity to 2)

### Dialogue Boost Not Working

**Solution**:
1. This feature requires VLC 3.x equalizer support
2. Some VLC builds may not expose equalizer to Lua
3. Try updating to the latest VLC version
4. Check if manual equalizer works: `Tools` → `Effects and Filters` → `Audio Effects` → `Equalizer`

### Config/History Not Saving

**Solution**:
1. Check write permissions on the config directory:
   - Windows: `%APPDATA%\vlc\lua\extensions\rd_streamer\`
   - Linux: `~/.config/vlc/rd_streamer/`
2. Manually create the directory if it doesn't exist
3. Run VLC with elevated permissions (as a test only)

### Android-Specific Issues

**Solution**:
1. Ensure VLC has storage permissions
2. Verify the extensions folder path is correct
3. Some Android builds may have limited Lua support
4. Try using VLC Beta from Google Play Store
5. Check if the file is readable (not corrupted during transfer)

## Advanced Configuration

### Config File Location

The extension stores configuration in JSON format:

- **Windows**: `%APPDATA%\vlc\lua\extensions\rd_streamer\config.json`
- **Linux**: `~/.config/vlc/rd_streamer/config.json`
- **macOS**: `~/Library/Application Support/vlc/rd_streamer/config.json`
- **Android**: `/sdcard/Android/data/org.videolan.vlc/files/rd_streamer/config.json`

### Config File Structure

```json
{
  "rd_api_key": "your_real_debrid_api_key",
  "tmdb_api_key": "your_tmdb_api_key",
  "dialogue_boost": "medium",
  "auto_subtitles": true,
  "last_updated": 1234567890
}
```

### Watch History Location

Watch history is stored separately:

- **Windows**: `%APPDATA%\vlc\lua\extensions\rd_streamer\watch_history.json`
- **Linux**: `~/.config/vlc/rd_streamer/watch_history.json`

### Manual Editing

You can manually edit these files with any text editor. Make sure to:
1. Close VLC before editing
2. Use valid JSON format
3. Backup the file before making changes

## Debugging

### Enable Verbose Logging

**Windows**:
```cmd
vlc.exe -vv
```

**Linux/macOS**:
```bash
vlc -vv
```

**View Logs in VLC**:
1. Go to `Tools` → `Messages`
2. Set Verbosity to 2 (Debug)
3. Look for lines starting with `[RD Streamer]`

### Common Log Messages

- `[RD Streamer] Config loaded successfully` - Config file read OK
- `[RD Streamer] RD API key valid for user: username` - API key tested OK
- `[RD Streamer] HTTP GET: https://...` - API request made
- `[RD Streamer] Torrent added: 12345` - Torrent added to Real Debrid
- `[RD Streamer] Stream started: https://...` - Streaming URL obtained

### Testing Individual Components

**Test Real Debrid API**:
```bash
curl "https://api.real-debrid.com/rest/1.0/user?auth_token=YOUR_TOKEN"
```

**Test TMDB API**:
```bash
curl "https://api.themoviedb.org/3/movie/popular?api_key=YOUR_KEY"
```

**Test YTS API**:
```bash
curl "https://yts.mx/api/v2/list_movies.json?query_term=inception"
```

## Security & Privacy

### API Key Storage

- API keys are stored locally in plaintext JSON files
- Files are only accessible to your user account
- Never share your config files or API keys
- Regenerate API keys if compromised

### Data Collection

- No data is sent to any third party except:
  - Real Debrid (for torrent streaming)
  - TMDB (for movie/TV metadata)
  - YTS (for torrent search)
- Watch history is stored locally only
- No analytics or tracking

### Recommendations

1. Use a unique password for your Real Debrid account
2. Enable 2FA on Real Debrid if available
3. Regularly regenerate API tokens
4. Don't share your VLC config directory

## Performance Tips

### Optimize Streaming

1. **Internet Speed**: Real Debrid requires good bandwidth (10+ Mbps for 1080p)
2. **Cache**: Torrents already cached on Real Debrid stream instantly
3. **Quality**: Lower quality = faster streaming start
4. **Location**: Choose content with many seeders

### UI Responsiveness

1. VLC's Lua dialog system has limitations
2. API calls may take 1-5 seconds
3. Large browse lists may be slow
4. Use search instead of browsing for better performance

## Limitations

### VLC Lua API Limitations

1. **No True POST Support**: POST requests simulated via GET
2. **Limited HTML Rendering**: Browse UI is text-based
3. **No Image Display**: Can't show movie posters in dialogs
4. **No Clickable Lists**: Items can't be clicked directly
5. **No Background Tasks**: All operations are synchronous

### API Limitations

1. **YTS**: Only has movies (no TV shows)
2. **TMDB**: Rate limited (40 requests per 10 seconds)
3. **Real Debrid**: Premium account required
4. **Torrent Selection**: Automatically selects largest video file

### Feature Limitations

1. **Subtitles**: Not fully implemented (VLC API limitations)
2. **Continue Watching**: Tracks items but no resume functionality
3. **Multi-Episode**: TV shows require manual episode selection
4. **Quality Selection**: Defaults to 1080p when available

## Roadmap / Future Enhancements

Possible future improvements:

- [ ] Better torrent search (multiple sources)
- [ ] TV show season/episode selector
- [ ] Resume playback from last position
- [ ] Subtitle auto-download integration
- [ ] Trakt integration for watch tracking
- [ ] IMDb ratings display
- [ ] Advanced filtering (genre, year, rating)
- [ ] Queue management
- [ ] Download history
- [ ] Custom CSS themes for dialogs

## Support & Contributing

### Getting Help

1. Check this guide first
2. Review the troubleshooting section
3. Enable verbose logging and check for errors
4. Open an issue on GitHub with:
   - VLC version
   - Operating system
   - Error messages from logs
   - Steps to reproduce

### Contributing

Contributions welcome! Areas for improvement:

- Better UI/UX within VLC's limitations
- Additional torrent sources
- TV show episode handling
- Subtitle integration
- Bug fixes and optimizations

## Credits

- **VLC Media Player**: VideoLAN Organization
- **Real Debrid**: Real-Debrid SAS
- **TMDB**: The Movie Database
- **YTS**: YTS.mx torrent index

## License

This extension is provided as-is for educational purposes. Use responsibly and respect copyright laws in your jurisdiction.

## Changelog

### Version 1.0.0 (2024-02-05)
- Initial release
- Real Debrid API integration
- TMDB browsing
- YTS torrent search
- Watch history tracking
- Dialogue boost feature
- Netflix-style UI structure
