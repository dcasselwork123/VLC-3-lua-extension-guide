# Installation & Build Guide

## 🎯 For End Users (Simple)

### Download & Run (Easiest)

1. **Download** the pre-built app:
   - Get `RealDebridStreamer-Windows.zip` from the releases
   - Extract the ZIP file to any folder
   - Run `RealDebridStreamer-Portable.exe`

2. **First-time Setup**:
   - The app will open
   - Click **Settings** tab
   - Enter your **Real Debrid API key** from https://real-debrid.com/apitoken
   - Enter your **TMDB API key** from https://www.themoviedb.org/settings/api
   - Click **Save Settings**
   - Click **Test Connection**

3. **Install VLC** (if not already installed):
   - Download from: https://www.videolan.org/vlc/
   - Install using default settings

4. **Start Streaming!**
   - Go to **Browse** or **Search** tab
   - Find a movie
   - Click **▶ Stream**
   - Enjoy!

---

## 🛠️ For Developers (Building from Source)

### Prerequisites

1. **Node.js** (v16 or higher)
   - Download: https://nodejs.org/
   - Install LTS version

2. **Git** (optional, for cloning)
   - Download: https://git-scm.com/

3. **VLC Media Player** (for testing)
   - Download: https://www.videolan.org/vlc/

### Build Steps

#### Windows

```bash
# 1. Extract or clone the project
cd realdebrid-app

# 2. Install dependencies
npm install

# 3. Run in development mode (for testing)
npm start

# 4. Build portable Windows executable
npm run build:win

# 5. Find the built app in dist/ folder
```

**Or use the build script:**

```bash
# Double-click build.bat
# or run in Command Prompt:
build.bat
```

The built app will be in `dist-package/` folder.

#### macOS

```bash
# 1. Install dependencies
npm install

# 2. Run in development
npm start

# 3. Build for macOS
npm run build:mac
```

#### Linux

```bash
# 1. Install dependencies
npm install

# 2. Run in development
npm start

# 3. Build for Linux
npm run build:linux
```

### Project Structure

```
realdebrid-app/
├── main.js              # Electron main process (backend)
├── renderer.js          # Frontend logic (UI interactions)
├── index.html           # Main HTML structure
├── styles.css           # Netflix-style CSS
├── package.json         # Project config & dependencies
├── build.bat            # Windows build script
├── assets/              # Icons and images
└── README.md            # Documentation
```

### Customization

#### Change App Name

Edit `package.json`:
```json
{
  "name": "your-app-name",
  "productName": "Your App Name"
}
```

#### Change App Icon

1. Create a PNG icon (512x512px recommended)
2. Save as `assets/icon.png`
3. Rebuild the app

#### Add More Torrent Sources

Edit `renderer.js` and add new search functions similar to `search-yts` and `search-piratebay`.

#### Modify UI Colors/Theme

Edit `styles.css`:
- Primary color: `#e50914` (Netflix red)
- Background: `#141414` (dark)
- Change these to customize the look

### Development Tips

#### Enable Developer Tools

In `main.js`, uncomment:
```javascript
mainWindow.webContents.openDevTools();
```

#### View Console Logs

- Main process logs: Terminal/Command Prompt
- Renderer logs: Developer Tools Console

#### Hot Reload

Changes to HTML/CSS/JS require app restart. Use:
```bash
npm start
```
and restart the app to see changes.

### Building for Distribution

#### Create ZIP Package

**Windows:**
```bash
# After running build.bat
cd dist-package
# Right-click > Send to > Compressed (zipped) folder
```

**Command line:**
```bash
powershell Compress-Archive -Path dist-package\* -DestinationPath RealDebridStreamer-Windows.zip
```

#### Create Installer (Advanced)

To create a proper Windows installer instead of portable:

1. Edit `package.json`:
```json
"build": {
  "win": {
    "target": ["nsis"]  // Change from "portable" to "nsis"
  }
}
```

2. Build:
```bash
npm run build:win
```

This creates an installer `.exe` in `dist/`.

---

## 🧪 Testing

### Test Checklist

Before distributing, test these features:

- [ ] App starts without errors
- [ ] Settings save and persist
- [ ] Real Debrid connection test works
- [ ] TMDB API loads popular movies
- [ ] Movie cards display correctly
- [ ] Search functionality works
- [ ] Clicking Stream opens VLC
- [ ] Watch history saves and displays
- [ ] Page navigation works
- [ ] Modal (movie details) opens/closes
- [ ] Toast notifications appear

### Common Build Issues

**"Cannot find module 'electron'"**
```bash
npm install
```

**"Build failed - out of memory"**
```bash
# Increase Node.js memory
set NODE_OPTIONS=--max-old-space-size=4096
npm run build:win
```

**"electron-builder not found"**
```bash
npm install --save-dev electron-builder
```

---

## 📦 Dependencies

### Runtime Dependencies

- `electron` - Desktop app framework
- `axios` - HTTP client for API calls
- `electron-store` - Persistent config storage

### Development Dependencies

- `electron-builder` - Package and build tool

### External Requirements

- VLC Media Player (user must install separately)
- Real Debrid account (user provides)
- TMDB API key (user provides)

---

## 🚀 Deployment

### GitHub Releases

1. Build the app:
```bash
npm run build:win
```

2. Create ZIP:
```bash
powershell Compress-Archive -Path dist\* -DestinationPath RealDebridStreamer-Windows.zip
```

3. Create GitHub Release:
   - Tag version (e.g., v1.0.0)
   - Upload ZIP file
   - Add release notes

### Alternative Distribution

- **Direct download**: Host ZIP on your own server
- **Portable USB**: Copy to USB drive (no installation needed)
- **Network share**: Place on shared drive for local network

---

## 🔒 Code Signing (Optional)

For production Windows apps, code signing prevents security warnings:

1. Get a code signing certificate
2. Configure in `package.json`:
```json
"win": {
  "certificateFile": "path/to/cert.pfx",
  "certificatePassword": "password"
}
```

---

## 📝 Version Management

Update version in `package.json`:
```json
{
  "version": "1.0.0"
}
```

This version appears in:
- App title bar
- About dialog
- File properties

---

## 🤝 Contributing

To contribute:

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

---

## 📞 Support

For build issues:
- Check Node.js version: `node --version`
- Check npm version: `npm --version`
- Clear cache: `npm cache clean --force`
- Reinstall: `rm -rf node_modules && npm install`

---

**Happy Building!** 🚀
