const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const Store = require('electron-store');
const axios = require('axios');

// Initialize config store
const store = new Store();

let mainWindow;

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
    titleBarStyle: 'default'
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
  return {
    rdApiKey: store.get('rdApiKey', ''),
    tmdbApiKey: store.get('tmdbApiKey', '')
  };
});

ipcMain.handle('save-config', async (event, config) => {
  store.set('rdApiKey', config.rdApiKey);
  store.set('tmdbApiKey', config.tmdbApiKey);
  return { success: true };
});

// Real Debrid API
ipcMain.handle('rd-test-key', async (event, apiKey) => {
  try {
    const response = await axios.get('https://api.real-debrid.com/rest/1.0/user', {
      headers: { Authorization: `Bearer ${apiKey}` }
    });
    return { success: true, username: response.data.username };
  } catch (error) {
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
        }
      }
    );
    return { success: true, data: response.data };
  } catch (error) {
    return { success: false, error: error.response?.data?.error || error.message };
  }
});

ipcMain.handle('rd-get-info', async (event, { apiKey, torrentId }) => {
  try {
    const response = await axios.get(
      `https://api.real-debrid.com/rest/1.0/torrents/info/${torrentId}`,
      {
        headers: { Authorization: `Bearer ${apiKey}` }
      }
    );
    return { success: true, data: response.data };
  } catch (error) {
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
        }
      }
    );
    return { success: true };
  } catch (error) {
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
        }
      }
    );
    return { success: true, data: response.data };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

// TMDB API
ipcMain.handle('tmdb-popular', async (event, { apiKey, page }) => {
  try {
    const response = await axios.get(
      `https://api.themoviedb.org/3/movie/popular?api_key=${apiKey}&page=${page || 1}`
    );
    return { success: true, data: response.data };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('tmdb-search', async (event, { apiKey, query }) => {
  try {
    const response = await axios.get(
      `https://api.themoviedb.org/3/search/movie?api_key=${apiKey}&query=${encodeURIComponent(query)}`
    );
    return { success: true, data: response.data };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

// Torrent Search APIs
ipcMain.handle('search-yts', async (event, { title, year }) => {
  try {
    let query = title;
    if (year) query += ` ${year}`;
    
    const response = await axios.get(
      `https://yts.mx/api/v2/list_movies.json?query_term=${encodeURIComponent(query)}&limit=1`
    );
    
    if (response.data.data.movies && response.data.data.movies.length > 0) {
      const movie = response.data.data.movies[0];
      return { success: true, data: movie };
    }
    
    return { success: false, error: 'No results found' };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('search-piratebay', async (event, { title, year }) => {
  try {
    let query = title;
    if (year) query += ` ${year}`;
    
    const response = await axios.get(
      `https://apibay.org/q.php?q=${encodeURIComponent(query)}&cat=201`
    );
    
    if (response.data && response.data.length > 0 && response.data[0].name !== 'No results returned') {
      return { success: true, data: response.data[0] };
    }
    
    return { success: false, error: 'No results found' };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

console.log('Real Debrid Streamer - Main process started');
