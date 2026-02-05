# Real Debrid Streamer for VLC

A powerful VLC extension that brings Netflix-style browsing and Real Debrid torrent streaming directly into VLC Media Player.

![VLC Version](https://img.shields.io/badge/VLC-3.0%2B-orange)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS%20%7C%20Android-blue)
![License](https://img.shields.io/badge/license-Educational-green)

## ✨ Features

### 🎬 Real Debrid Integration
- **Direct Torrent Streaming**: Stream torrents instantly through Real Debrid's premium infrastructure
- **Magnet Link Support**: Paste any magnet link and start streaming immediately
- **Automatic File Selection**: Intelligently selects the best video file from multi-file torrents
- **Queue Management**: Handles torrent processing and unrestricted link generation

### 🌐 Netflix-Style Content Browsing
- **TMDB Integration**: Browse thousands of movies and TV shows with rich metadata
- **Multiple Categories**:
  - Popular Movies
  - New Releases
  - Popular TV Shows
  - Search Functionality
- **Card-Based Interface**: Navigate content like a streaming service
- **Pagination**: Browse through pages of content

### 📊 Smart Watch Tracking
- **Automatic History**: Every stream is automatically tracked
- **Watch History**: Review your recently watched content
- **Persistent Storage**: History saved locally in JSON format
- **Continue Watching**: Keep track of what you've started (UI ready for future resume feature)

### 🎧 Dialogue Boost
- **Voice Enhancement**: Boost mid-range frequencies to make dialogue clearer
- **Three Levels**: Low, Medium, High intensity options
- **Real-Time Application**: Apply during playback without restarting
- **Audio Equalization**: Automatically optimizes for speech clarity

### 🔍 Integrated Search
- **TMDB Search**: Find movies and TV shows by title
- **Automatic Torrent Matching**: Searches YTS for available torrents
- **One-Click Streaming**: Found content streams immediately via Real Debrid

### 🛠️ Configuration Management
- **Secure API Key Storage**: Store Real Debrid and TMDB API keys locally
- **JSON Configuration**: Easy-to-edit config files
- **Multi-Platform Support**: Works on Windows, Linux, macOS, and Android
- **First-Run Setup**: Guided configuration wizard

## 📋 Requirements

- **VLC Media Player**: Version 3.0 or later
- **Real Debrid Account**: Premium subscription required ([Sign up](https://real-debrid.com))
- **TMDB API Key**: Free account ([Get one](https://www.themoviedb.org/settings/api)) - Optional but recommended
- **Internet Connection**: For API calls and streaming

## 🚀 Quick Start

### 1. Installation

**Windows**:
```
Copy realdebrid-streamer.lua to:
%APPDATA%\vlc\lua\extensions\
```

**Linux**:
```bash
cp realdebrid-streamer.lua ~/.local/share/vlc/lua/extensions/
```

**macOS**:
```bash
cp realdebrid-streamer.lua ~/Library/Application\ Support/org.videolan.vlc/lua/extensions/
```

**Android**:
```
Copy to: /sdcard/Android/data/org.videolan.vlc/files/lua/extensions/
```

### 2. Get Your API Keys

**Real Debrid** (Required):
1. Login to [Real Debrid](https://real-debrid.com)
2. Go to [API Token page](https://real-debrid.com/apitoken)
3. Copy your API token

**TMDB** (Optional but recommended):
1. Create account at [TMDB](https://www.themoviedb.org)
2. Request API key at [Settings > API](https://www.themoviedb.org/settings/api)
3. Copy your API key (v3 auth)

### 3. Launch Extension

1. Restart VLC
2. Go to `View` → `Real Debrid Streamer` (or `Tools` → `Extensions`)
3. Enter your Real Debrid API key when prompted
4. Go to Settings (⚙️) to add TMDB API key

### 4. Start Streaming!

**Method A - Direct Magnet**:
- Paste a magnet link in the home screen
- Click "▶️ Stream"
- Enjoy!

**Method B - Browse & Search**:
- Click "🎬 Movies" or "📺 TV Shows"
- Browse or search for content
- Content streams automatically

## 📖 Documentation

- **[Complete Installation Guide](INSTALLATION.md)**: Detailed setup instructions for all platforms
- **[API Documentation](API_REFERENCE.md)**: Technical details about API integrations
- **[Troubleshooting Guide](INSTALLATION.md#troubleshooting)**: Common issues and solutions

## 🎯 How It Works

### Streaming Flow

```
Magnet/Torrent Input
       ↓
Real Debrid API (Add Torrent)
       ↓
Select Video Files
       ↓
Get Download Links
       ↓
Unrestrict Links (Premium Direct URL)
       ↓
VLC Playlist (Stream & Play)
```

### Content Discovery Flow

```
TMDB Browse/Search
       ↓
Get Movie/Show Metadata
       ↓
YTS Torrent Search (by title + year)
       ↓
Extract Magnet Link
       ↓
Stream via Real Debrid
       ↓
Track in Watch History
```

## 🖥️ User Interface

### Home Screen
- Quick magnet/torrent input
- Recently watched history
- Quick access buttons (Search, Browse, Settings)

### Movies/TV Shows
- Tabbed browsing (Popular, New Releases)
- Pagination controls
- List view with ratings and years

### Settings
- Real Debrid API key configuration
- TMDB API key configuration
- Dialogue boost settings (Low/Medium/High)
- API key validation

### Search
- Query input
- Media type selector (Movie/TV)
- One-click results

## 🔧 Technical Details

### APIs Used

- **Real Debrid REST API v1.0**: Torrent management and unrestricted streaming
- **TMDB API v3**: Movie and TV show metadata, search, and discovery
- **YTS API v2**: Torrent search and magnet link generation

### Technologies

- **Language**: Lua 5.1+ (VLC's embedded Lua)
- **JSON Parser**: Custom implementation (self-contained, no dependencies)
- **HTTP Client**: VLC's `vlc.stream()` API
- **UI**: VLC's `vlc.dialog()` API
- **Storage**: JSON files in VLC's data directory

### File Structure

```
realdebrid-streamer.lua      # Main extension (38KB, ~1400 lines)
INSTALLATION.md              # Installation guide
API_REFERENCE.md             # API documentation
README.md                    # This file
template-extension.lua       # Original VLC extension template
```

### Configuration Files

**Config File**: `config.json`
```json
{
  "rd_api_key": "...",
  "tmdb_api_key": "...",
  "dialogue_boost": "medium",
  "auto_subtitles": true,
  "last_updated": 1234567890
}
```

**Watch History**: `watch_history.json`
```json
[
  {
    "id": 550,
    "title": "Fight Club",
    "type": "movie",
    "timestamp": 1234567890,
    "watched": true
  }
]
```

## 🐛 Known Limitations

### VLC Lua API Constraints

- **HTTP POST**: Limited support (workaround via GET with parameters)
- **HTML Rendering**: Basic text-only in dialogs (no images or rich formatting)
- **Async Operations**: All API calls are synchronous (may cause brief UI freezes)
- **Clickable Elements**: List items can't be directly clicked (use search instead)

### Feature Limitations

- **YTS Only**: Torrent search limited to movies (YTS doesn't have TV shows)
- **Subtitle Integration**: Not fully implemented due to VLC Lua API limitations
- **Resume Playback**: Watch tracking exists but resume functionality not available
- **TV Episodes**: No season/episode selector (requires manual torrent selection)
- **Quality Selection**: Defaults to 1080p; manual selection not implemented

### Platform-Specific

- **Android**: Some VLC builds have limited Lua support
- **macOS**: Folder paths may vary by VLC build
- **Linux**: Requires proper file permissions

## 🔒 Security & Privacy

### Data Handling

- **Local Storage Only**: All data stored locally on your device
- **No Analytics**: No tracking or data collection
- **No Third-Party Servers**: Direct API calls only (Real Debrid, TMDB, YTS)

### API Key Security

- **Plaintext Storage**: Config files are JSON (use filesystem permissions for security)
- **User-Only Access**: Files stored in user-specific directories
- **Regeneration**: Can regenerate API tokens anytime on provider websites

### Recommendations

✅ Use unique passwords for Real Debrid  
✅ Enable 2FA if available  
✅ Regularly regenerate API tokens  
✅ Don't share config directory  
✅ Review and understand code before use  

## 🤝 Contributing

Contributions welcome! Areas for improvement:

- **UI/UX**: Better navigation within VLC's dialog limitations
- **Torrent Sources**: Add more public torrent APIs
- **TV Shows**: Implement season/episode selection
- **Subtitles**: Better integration with OpenSubtitles or similar
- **Performance**: Optimize API calls and caching
- **Testing**: Cross-platform testing and validation

### Development Setup

1. Clone repository
2. Edit `realdebrid-streamer.lua`
3. Copy to VLC extensions folder
4. Test in VLC with verbose logging (`vlc -vv`)
5. Submit pull request

## 📝 Testing Instructions

### Basic Functionality Test

1. **Extension Loads**:
   - Launch VLC
   - Check `View` menu for "Real Debrid Streamer"
   - Extension dialog should open

2. **API Configuration**:
   - Enter Real Debrid API key
   - Click "Test" - should show "✅ API key is valid!"
   - Enter TMDB API key
   - Save settings

3. **Direct Streaming**:
   - Find a magnet link (e.g., from YTS.mx)
   - Paste into home screen input
   - Click "▶️ Stream"
   - Should process and start playing within 5-10 seconds

4. **Browse Movies**:
   - Click "🎬 Movies"
   - Should load popular movies list
   - Try pagination (Next/Previous)

5. **Search**:
   - Click "🔍 Search"
   - Enter "Inception"
   - Select "Movie"
   - Should find and attempt to stream

6. **Dialogue Boost**:
   - Start playing any video
   - Go to Settings
   - Select "Medium" boost
   - Click "Apply"
   - Audio should change (voice clearer)

7. **Watch History**:
   - Stream a few items
   - Return to home screen
   - Check "Recently Watched" section

### Verbose Logging Test

```bash
# Run VLC with verbose output
vlc -vv 2>&1 | grep "RD Streamer"
```

Expected log messages:
- `[RD Streamer] Config loaded successfully`
- `[RD Streamer] HTTP GET: https://api.real-debrid.com...`
- `[RD Streamer] Torrent added: 12345`
- `[RD Streamer] Stream started: https://...`

## 🆘 Support

### Getting Help

1. **Read Documentation**: Check [INSTALLATION.md](INSTALLATION.md) for detailed guides
2. **Enable Logging**: Run VLC with `-vv` flag for verbose logs
3. **Check Common Issues**: Review troubleshooting section
4. **Test APIs**: Verify Real Debrid and TMDB APIs work directly

### Reporting Issues

When reporting bugs, include:
- VLC version (`vlc --version`)
- Operating system and version
- Extension version
- Error messages from logs (`Tools` → `Messages`)
- Steps to reproduce

## 📜 License

This extension is provided as-is for **educational purposes**. 

**Important Legal Notice**:
- Respect copyright laws in your jurisdiction
- Use only with content you have rights to access
- Real Debrid terms of service apply
- No warranty or guarantee provided

## 🙏 Credits

### APIs & Services
- **[VLC Media Player](https://www.videolan.org/)**: VideoLAN Organization
- **[Real Debrid](https://real-debrid.com/)**: Premium unrestricted downloader
- **[TMDB](https://www.themoviedb.org/)**: The Movie Database
- **[YTS](https://yts.mx/)**: YIFY torrents index

### Inspiration
- VLC's built-in Lua extensions
- Netflix UI/UX patterns
- Community feedback and requests

## 📊 Project Stats

- **Lines of Code**: ~1,400 (main extension)
- **File Size**: 38KB (uncompressed)
- **Dependencies**: Zero (self-contained)
- **Platforms**: 4 (Windows, Linux, macOS, Android)
- **APIs Integrated**: 3 (Real Debrid, TMDB, YTS)

## 🗺️ Roadmap

### Version 1.1 (Planned)
- [ ] Multiple torrent source support
- [ ] TV show season/episode picker
- [ ] IMDb ratings integration
- [ ] Advanced filtering (genre, year, rating)
- [ ] Better error handling and recovery

### Version 1.2 (Future)
- [ ] Trakt integration for watch sync
- [ ] Resume playback from last position
- [ ] Subtitle auto-download (OpenSubtitles)
- [ ] Custom UI themes
- [ ] Queue management improvements

### Version 2.0 (Long-term)
- [ ] Rewrite as VLC interface (more capabilities)
- [ ] Web-based UI option
- [ ] Multi-language support
- [ ] Advanced caching and performance
- [ ] Mobile app companion

## 🌟 Star This Project

If you find this extension useful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs and issues
- 💡 Suggesting new features
- 🤝 Contributing code improvements
- 📢 Sharing with others

---

**Made with ❤️ for the VLC community**

*Disclaimer: This is an independent project and is not affiliated with or endorsed by VideoLAN, Real Debrid, TMDB, or YTS.*
