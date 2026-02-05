const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const axios = require('axios');
const fs = require('fs');

let mainWindow;
let configPath;

// Config file management (no external dependencies)
function getConfigPath() {
  if (!configPath) {
    const userDataPath = app.getPath('userData');
    configPath = path.join(userDataPath, 'config.json');
  }
  return configPath;
}

function loadConfig() {
  try {
    const data = fs.readFileSync(getConfigPath(), 'utf8');
    return JSON.parse(data);
  } catch (error) {
    return { rdApiKey: '', tmdbApiKey: '' };
  }
}

function saveConfig(config) {
  try {
    const dir = path.dirname(getConfigPath());
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(getConfigPath(), JSON.stringify(config, null, 2));
    return true;
  } catch (error) {
    console.error('Error saving config:', error);
    return false;
  }
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1000,
    minHeight: 700,
    backgroundColor: '#141414',
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      enableRemoteModule: true
    },
    icon: path.join(__dirname, 'assets', 'icon.png'),
    frame: true,
    titleBarStyle: 'default',
    title: '🏰 CasselFlix - Your Castle of Entertainment'
  });

  mainWindow.loadFile('index.html');
  
  // Open DevTools in development
  // mainWindow.webContents.openDevTools();

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (mainWindow === null) {
    createWindow();
  }
});

// ===========================
// IPC Handlers for API calls
// ===========================

// Config Management
ipcMain.handle('get-config', async () => {
  return loadConfig();
});

ipcMain.handle('save-config', async (event, config) => {
  const success = saveConfig(config);
  return { success };
});

// Real Debrid API
ipcMain.handle('rd-test-key', async (event, apiKey) => {
  try {
    const response = await axios.get('https://api.real-debrid.com/rest/1.0/user', {
      headers: { Authorization: `Bearer ${apiKey}` },
      timeout: 10000
    });
    return { success: true, username: response.data.username };
  } catch (error) {
    console.error('RD test error:', error.message);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('rd-add-magnet', async (event, { apiKey, magnet }) => {
  try {
    const formData = new URLSearchParams();
    formData.append('magnet', magnet);
    
    const response = await axios.post(
      'https://api.real-debrid.com/rest/1.0/torrents/addMagnet',
      formData,
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        timeout: 15000
      }
    );
    return { success: true, data: response.data };
  } catch (error) {
    console.error('RD add magnet error:', error.response?.data || error.message);
    return { success: false, error: error.response?.data?.error || error.message };
  }
});

ipcMain.handle('rd-get-info', async (event, { apiKey, torrentId }) => {
  try {
    const response = await axios.get(
      `https://api.real-debrid.com/rest/1.0/torrents/info/${torrentId}`,
      {
        headers: { Authorization: `Bearer ${apiKey}` },
        timeout: 10000
      }
    );
    return { success: true, data: response.data };
  } catch (error) {
    console.error('RD get info error:', error.message);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('rd-select-files', async (event, { apiKey, torrentId, fileIds }) => {
  try {
    const formData = new URLSearchParams();
    formData.append('files', fileIds);
    
    await axios.post(
      `https://api.real-debrid.com/rest/1.0/torrents/selectFiles/${torrentId}`,
      formData,
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        timeout: 10000
      }
    );
    return { success: true };
  } catch (error) {
    console.error('RD select files error:', error.message);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('rd-unrestrict', async (event, { apiKey, link }) => {
  try {
    const formData = new URLSearchParams();
    formData.append('link', link);
    
    const response = await axios.post(
      'https://api.real-debrid.com/rest/1.0/unrestrict/link',
      formData,
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        timeout: 15000
      }
    );
    return { success: true, data: response.data };
  } catch (error) {
    console.error('RD unrestrict error:', error.message);
    return { success: false, error: error.message };
  }
});

// TMDB API
ipcMain.handle('tmdb-popular', async (event, { apiKey, page }) => {
  try {
    const response = await axios.get(
      `https://api.themoviedb.org/3/movie/popular?api_key=${apiKey}&page=${page || 1}`,
      { timeout: 10000 }
    );
    return { success: true, data: response.data };
  } catch (error) {
    console.error('TMDB popular error:', error.message);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('tmdb-search', async (event, { apiKey, query }) => {
  try {
    const response = await axios.get(
      `https://api.themoviedb.org/3/search/movie?api_key=${apiKey}&query=${encodeURIComponent(query)}`,
      { timeout: 10000 }
    );
    return { success: true, data: response.data };
  } catch (error) {
    console.error('TMDB search error:', error.message);
    return { success: false, error: error.message };
  }
});

// Torrent Search APIs
ipcMain.handle('search-yts', async (event, { title, year }) => {
  try {
    let query = title;
    if (year) query += ` ${year}`;
    
    console.log('Searching YTS for:', query);
    
    const response = await axios.get(
      `https://yts.mx/api/v2/list_movies.json?query_term=${encodeURIComponent(query)}&limit=10`,
      { 
        timeout: 15000,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
      }
    );
    
    console.log('YTS response status:', response.data.status);
    
    if (response.data.data.movies && response.data.data.movies.length > 0) {
      // Return ALL movies with torrents, not just first one
      const moviesWithTorrents = response.data.data.movies.filter(m => m.torrents && m.torrents.length > 0);
      console.log('Found YTS movies:', moviesWithTorrents.length);
      return { success: true, data: moviesWithTorrents };
    }
    
    console.log('No YTS results');
    return { success: false, error: 'No results found' };
  } catch (error) {
    console.error('YTS search error:', error.message);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('search-piratebay', async (event, { title, year }) => {
  try {
    let query = title;
    if (year) query += ` ${year}`;
    
    console.log('Searching PirateBay for:', query);
    
    const response = await axios.get(
      `https://apibay.org/q.php?q=${encodeURIComponent(query)}&cat=201`,
      { 
        timeout: 15000,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
      }
    );
    
    if (response.data && response.data.length > 0 && response.data[0].name !== 'No results returned') {
      // Return multiple results, not just first one
      const torrents = response.data
        .filter(t => t.name !== 'No results returned')
        .slice(0, 10);
      console.log('Found TPB torrents:', torrents.length);
      if (torrents.length > 0) {
        console.log('First TPB torrent:', torrents[0].name);
      }
      return { success: true, data: torrents };
    }
    
    console.log('No TPB results');
    return { success: false, error: 'No results found' };
  } catch (error) {
    console.error('PirateBay search error:', error.message);
    return { success: false, error: error.message };
  }
});

console.log('Real Debrid Streamer - Main process started');
console.log('Config path:', getConfigPath());
