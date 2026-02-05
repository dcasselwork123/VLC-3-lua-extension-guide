#!/bin/bash

echo "=========================================="
echo "Real Debrid Streamer - Package Creator"
echo "=========================================="
echo ""

# Create package directory
PACKAGE_DIR="RealDebridStreamer-Source"
ZIP_NAME="RealDebridStreamer-Source.zip"

echo "[1/3] Creating package directory..."
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy all necessary files
echo "[2/3] Copying files..."
cp package.json "$PACKAGE_DIR/"
cp main.js "$PACKAGE_DIR/"
cp renderer.js "$PACKAGE_DIR/"
cp index.html "$PACKAGE_DIR/"
cp styles.css "$PACKAGE_DIR/"
cp README.md "$PACKAGE_DIR/"
cp INSTALLATION.md "$PACKAGE_DIR/"
cp build.bat "$PACKAGE_DIR/"

# Copy assets
cp -r assets "$PACKAGE_DIR/" 2>/dev/null || mkdir "$PACKAGE_DIR/assets"

# Create .gitignore
cat > "$PACKAGE_DIR/.gitignore" << 'EOF'
node_modules/
dist/
dist-package/
*.log
.DS_Store
EOF

echo "[3/3] Creating ZIP archive..."
if command -v zip &> /dev/null; then
    zip -r "$ZIP_NAME" "$PACKAGE_DIR"
    echo ""
    echo "=========================================="
    echo "SUCCESS!"
    echo "=========================================="
    echo ""
    echo "Package created: $ZIP_NAME"
    echo "Size: $(du -h "$ZIP_NAME" | cut -f1)"
    echo ""
    echo "This ZIP contains:"
    echo "  - Complete source code"
    echo "  - All configuration files"
    echo "  - README and installation guide"
    echo "  - Build scripts"
    echo ""
    echo "Users can:"
    echo "  1. Extract the ZIP"
    echo "  2. Run: npm install"
    echo "  3. Run: npm start (to test)"
    echo "  4. Run: npm run build:win (to build)"
    echo ""
else
    echo "ZIP command not found. Package directory created at: $PACKAGE_DIR"
    echo "Please manually zip this folder."
fi

# Also create a quick start script
cat > "$PACKAGE_DIR/QUICKSTART.txt" << 'EOF'
QUICK START GUIDE
==================

FOR END USERS:
--------------
If you just want to USE the app:
1. Wait for a pre-built release
2. Download the .exe file
3. Run it!

FOR DEVELOPERS:
---------------
If you want to BUILD the app:

1. Install Node.js from: https://nodejs.org/
2. Open Command Prompt in this folder
3. Run: npm install
4. Run: npm start (to test)
5. Run: npm run build:win (to build)
6. Find built app in dist/ folder

REQUIREMENTS:
-------------
- Node.js (v16 or higher)
- VLC Media Player (for playing streams)
- Real Debrid account
- TMDB API key (optional, for browsing)

MORE INFO:
----------
See README.md for full documentation
See INSTALLATION.md for detailed build instructions

SUPPORT:
--------
- Check INSTALLATION.md for troubleshooting
- Open an issue on GitHub for bugs
EOF

echo "Package complete!"
