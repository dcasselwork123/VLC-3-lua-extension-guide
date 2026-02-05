# Real Debrid Streamer - Standalone Desktop App

🎬 **Netflix-style torrent streaming powered by Real Debrid**

A beautiful, standalone desktop application for Windows (and soon Android) that lets you browse and stream movies instantly using Real Debrid.

## ✨ Features

- **Netflix-Style UI**: Beautiful, modern interface with movie posters and cards
- **Real Debrid Integration**: Stream torrents instantly without downloading
- **TMDB Browse**: Browse popular movies with ratings and descriptions
- **Smart Search**: Search movies by name with automatic torrent finding
- **Watch History**: Track what you've watched with "Continue Watching"
- **VLC Player**: Uses VLC as the media player (must be installed)
- **Portable**: No installation required - just unzip and run!

## 📥 Requirements

- **Windows 10/11** (64-bit)
- **VLC Media Player** installed ([Download here](https://www.videolan.org/vlc/))
- **Real Debrid Account** ([Sign up here](https://real-debrid.com/))
- **TMDB API Key** (optional, for browsing) ([Get free key](https://www.themoviedb.org/settings/api))

## 🚀 Quick Start

### Option 1: Download Pre-built App (Recommended)

1. Download `RealDebridStreamer-Portable.exe` from Releases
2. Double-click to run (no installation needed)
3. Go to Settings tab
4. Enter your **Real Debrid API key** from https://real-debrid.com/apitoken
5. Enter your **TMDB API Key (v3 auth)** from https://www.themoviedb.org/settings/api
6. Click "Save Settings"
7. Start browsing and streaming!

### Option 2: Build from Source

```bash
# Install dependencies
npm install

# Run in development mode
npm start

# Build portable Windows app
npm run build:win
```

The built app will be in the `dist` folder.

## 🎯 How to Use

### 1. Configure API Keys

1. Open the app
2. Click **Settings** in the navigation
3. Enter your **Real Debrid API Key**
   - Get it from: https://real-debrid.com/apitoken
   - Use the "API token" shown on that page
4. Enter your **TMDB API Key**
   - Get it from: https://www.themoviedb.org/settings/api
   - Use "API Key (v3 auth)" - NOT the Read Access Token
5. Click **Save Settings**
6. Click **Test Connection** to verify

### 2. Browse Movies

1. Click **Browse** in the navigation
2. You'll see popular movies with:
   - Large movie posters
   - Title, year, and rating
   - Short description
3. Click any movie card to see full details
4. Click **▶ Stream** to watch instantly!
5. Use **Previous** and **Next** buttons to browse
6. Use **Previous Page** and **Next Page** for more movies

### 3. Search for Movies

1. Click **Search** in the navigation
2. Type a movie name (e.g., "Interstellar")
3. Click **Search** or press Enter
4. Results will show as movie cards
5. Click **▶ Stream** on any movie

### 4. Quick Stream (Direct Magnet Links)

1. Go to **Home** tab
2. Paste a magnet link in the input box
3. Click **▶ Stream**
4. The app will process it through Real Debrid and play in VLC

### 5. Continue Watching

- The **Home** tab shows your recently watched movies
- Click **▶ Stream Again** to re-watch

## 🎬 How It Works

1. **Browse/Search**: Find a movie using TMDB or search
2. **Torrent Search**: App searches YTS.mx and ThePirateBay for torrents
3. **Real Debrid**: Sends the torrent to Real Debrid for instant caching
4. **Stream URL**: Gets a direct HTTPS stream link
5. **VLC Player**: Opens the stream in VLC Media Player

No torrenting on your end - Real Debrid handles everything!

## 🔧 Troubleshooting

### "Could not find VLC"

- Make sure VLC is installed: https://www.videolan.org/vlc/
- Windows default paths:
  - `C:\Program Files\VideoLAN\VLC\vlc.exe`
  - `C:\Program Files (x86)\VideoLAN\VLC\vlc.exe`

### "Failed to add magnet"

- Check your Real Debrid API key is correct
- Make sure you have Real Debrid credits/premium active
- Some torrents may not be supported by Real Debrid

### "No torrents found"

- Try a different movie (more popular titles work better)
- Some movies may not have torrents available
- Try searching with the year (e.g., "Inception 2010")

### App won't start

- Make sure you have Windows 10/11 64-bit
- Try running as Administrator
- Check Windows Defender isn't blocking it

## 📸 Screenshots

### Home Screen
- Quick stream with magnet links
- Continue Watching section
- Clean, Netflix-style interface

### Browse Movies
- Grid of movie posters
- Ratings and year displayed
- Page navigation

### Movie Details
- Large poster image
- Full description
- One-click streaming

### Settings
- Easy API key configuration
- Connection testing
- Helpful links to get keys

## 🛠️ Technical Details

- **Framework**: Electron (for cross-platform desktop apps)
- **UI**: HTML/CSS/JavaScript (modern, responsive design)
- **APIs**: Real Debrid REST API, TMDB API v3
- **Torrent Sources**: YTS.mx, ThePirateBay (apibay.org)
- **Player**: VLC Media Player (external)
- **Storage**: Local storage for watch history, electron-store for config

## 🔐 Privacy & Security

- All API keys are stored locally on your computer
- No data is sent to any third parties except:
  - Real Debrid (for torrent processing)
  - TMDB (for movie information)
  - Torrent APIs (for magnet links)
- Watch history is stored locally only

## 📝 License

MIT License - Free to use and modify

## 🤝 Credits

- **VLC Media Player** - VideoLAN
- **Real Debrid** - Premium unrestricted downloader
- **TMDB** - The Movie Database
- **YTS.mx** - Movie torrents
- **Electron** - Cross-platform desktop apps

## 🐛 Known Issues

- VLC window opens separately (not embedded)
- Some torrents may take time to cache on Real Debrid
- ThePirateBay API (apibay.org) is sometimes unreliable

## 🚧 Future Plans

- **Android version** (coming soon!)
- **TV Shows support** with season/episode browsing
- **Download queue** management
- **Subtitle integration** (automatic fetching)
- **Multiple torrent source** additions
- **Embedded video player** (no separate VLC window)

## 💬 Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Check the troubleshooting section above

## 🌟 Enjoy!

Happy streaming! 🍿🎬
