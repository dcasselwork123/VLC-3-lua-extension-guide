const { ipcRenderer } = require('electron');
const { exec } = require('child_process');
const path = require('path');

// ===========================
// State Management
// ===========================

let config = {
    rdApiKey: '',
    tmdbApiKey: ''
};

let currentPage = 1;
let currentMovies = [];
let watchHistory = [];

// ===========================
// Initialization
// ===========================

document.addEventListener('DOMContentLoaded', async () => {
    console.log('App initialized');
    
    // Load config
    await loadConfig();
    
    // Setup navigation
    setupNavigation();
    
    // Setup event listeners
    setupEventListeners();
    
    // Load watch history from localStorage
    loadWatchHistory();
});

// ===========================
// Configuration
// ===========================

async function loadConfig() {
    const loadedConfig = await ipcRenderer.invoke('get-config');
    config = loadedConfig;
    
    // Populate settings form
    if (config.rdApiKey) {
        document.getElementById('rd-api-key').value = config.rdApiKey;
    }
    if (config.tmdbApiKey) {
        document.getElementById('tmdb-api-key').value = config.tmdbApiKey;
    }
}

async function saveConfig() {
    config.rdApiKey = document.getElementById('rd-api-key').value;
    config.tmdbApiKey = document.getElementById('tmdb-api-key').value;
    
    await ipcRenderer.invoke('save-config', config);
    showToast('Settings saved successfully!', 'success');
}

// ===========================
// Navigation
// ===========================

function setupNavigation() {
    const navLinks = document.querySelectorAll('.nav-link');
    
    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const viewName = link.dataset.view;
            switchView(viewName);
            
            // Update active nav link
            navLinks.forEach(l => l.classList.remove('active'));
            link.classList.add('active');
        });
    });
}

function switchView(viewName) {
    // Hide all views
    document.querySelectorAll('.view').forEach(view => {
        view.classList.remove('active');
    });
    
    // Show selected view
    const targetView = document.getElementById(`${viewName}-view`);
    if (targetView) {
        targetView.classList.add('active');
    }
    
    // Load view-specific content
    if (viewName === 'browse') {
        loadPopularMovies(currentPage);
    }
}

// ===========================
// Event Listeners
// ===========================

function setupEventListeners() {
    // Settings
    document.getElementById('save-settings-btn').addEventListener('click', saveConfig);
    document.getElementById('test-connection-btn').addEventListener('click', testConnection);
    
    // Quick stream
    document.getElementById('stream-magnet-btn').addEventListener('click', () => {
        const magnet = document.getElementById('magnet-input').value;
        if (magnet) {
            streamMagnet(magnet);
        } else {
            showToast('Please enter a magnet link', 'error');
        }
    });
    
    // Browse pagination
    document.getElementById('prev-page-btn').addEventListener('click', () => {
        if (currentPage > 1) {
            currentPage--;
            loadPopularMovies(currentPage);
        }
    });
    
    document.getElementById('next-page-btn').addEventListener('click', () => {
        currentPage++;
        loadPopularMovies(currentPage);
    });
    
    // Search
    document.getElementById('search-btn').addEventListener('click', performSearch);
    document.getElementById('search-input').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            performSearch();
        }
    });
    
    // Modal close
    document.querySelector('.close-modal').addEventListener('click', closeModal);
    document.getElementById('movie-modal').addEventListener('click', (e) => {
        if (e.target.id === 'movie-modal') {
            closeModal();
        }
    });
}

// ===========================
// TMDB Functions
// ===========================

async function loadPopularMovies(page) {
    if (!config.tmdbApiKey) {
        showToast('Please configure TMDB API key in Settings', 'error');
        return;
    }
    
    showLoading(true);
    
    const result = await ipcRenderer.invoke('tmdb-popular', {
        apiKey: config.tmdbApiKey,
        page: page
    });
    
    showLoading(false);
    
    if (result.success) {
        currentMovies = result.data.results;
        displayMovies(currentMovies);
        document.getElementById('page-info').textContent = `Page ${page}`;
    } else {
        showToast('Failed to load movies: ' + result.error, 'error');
    }
}

async function performSearch() {
    const query = document.getElementById('search-input').value.trim();
    
    if (!query) {
        showToast('Please enter a search term', 'error');
        return;
    }
    
    if (!config.tmdbApiKey) {
        // Direct torrent search if no TMDB key
        searchAndStream(query);
        return;
    }
    
    showLoading(true);
    
    const result = await ipcRenderer.invoke('tmdb-search', {
        apiKey: config.tmdbApiKey,
        query: query
    });
    
    showLoading(false);
    
    if (result.success && result.data.results.length > 0) {
        displayMovies(result.data.results, 'search-results');
    } else {
        showToast('No results found', 'error');
    }
}

function displayMovies(movies, containerId = 'movies-grid') {
    const container = document.getElementById(containerId);
    container.innerHTML = '';
    
    if (movies.length === 0) {
        container.innerHTML = '<p class="no-results">No movies found</p>';
        return;
    }
    
    movies.forEach(movie => {
        const card = createMovieCard(movie);
        container.appendChild(card);
    });
}

function createMovieCard(movie) {
    const card = document.createElement('div');
    card.className = 'movie-card';
    
    const posterPath = movie.poster_path 
        ? `https://image.tmdb.org/t/p/w500${movie.poster_path}`
        : 'https://via.placeholder.com/200x300/333/fff?text=No+Poster';
    
    const year = movie.release_date ? movie.release_date.substring(0, 4) : 'N/A';
    const rating = movie.vote_average ? movie.vote_average.toFixed(1) : 'N/A';
    
    card.innerHTML = `
        <img src="${posterPath}" alt="${movie.title}" class="movie-poster" onerror="this.src='https://via.placeholder.com/200x300/333/fff?text=No+Poster'">
        <div class="movie-info">
            <div class="movie-title" title="${movie.title}">${movie.title}</div>
            <div class="movie-meta">
                <span>${year}</span>
                <span class="movie-rating">★ ${rating}</span>
            </div>
            <button class="stream-btn">▶ Stream</button>
        </div>
    `;
    
    // Click handler
    card.querySelector('.stream-btn').addEventListener('click', (e) => {
        e.stopPropagation();
        streamMovie(movie.title, year, posterPath, movie.overview);
    });
    
    // Show details on card click
    card.addEventListener('click', () => {
        showMovieDetails(movie);
    });
    
    return card;
}

function showMovieDetails(movie) {
    const modal = document.getElementById('movie-modal');
    const modalBody = document.getElementById('modal-body');
    
    const posterPath = movie.poster_path 
        ? `https://image.tmdb.org/t/p/w500${movie.poster_path}`
        : 'https://via.placeholder.com/300x450/333/fff?text=No+Poster';
    
    const year = movie.release_date ? movie.release_date.substring(0, 4) : 'N/A';
    const rating = movie.vote_average ? movie.vote_average.toFixed(1) : 'N/A';
    
    modalBody.innerHTML = `
        <div class="modal-header">
            <img src="${posterPath}" alt="${movie.title}" class="modal-poster" onerror="this.src='https://via.placeholder.com/300x450/333/fff?text=No+Poster'">
            <div class="modal-info">
                <h2 class="modal-title">${movie.title}</h2>
                <div class="modal-meta">
                    ${year} • <span class="modal-rating">★ ${rating}/10</span>
                </div>
                <p class="modal-overview">${movie.overview || 'No description available'}</p>
                <button class="btn btn-primary" onclick="streamMovie('${movie.title}', '${year}', '${posterPath}', '${movie.overview}'); closeModal();">
                    ▶ Stream Now
                </button>
            </div>
        </div>
    `;
    
    modal.classList.add('active');
}

function closeModal() {
    document.getElementById('movie-modal').classList.remove('active');
}

// Make functions available globally for onclick
window.streamMovie = streamMovie;
window.closeModal = closeModal;

// ===========================
// Torrent Search & Streaming
// ===========================

async function searchAndStream(title, year = null) {
    showToast('Searching for torrents...', 'success');
    console.log(`[DEBUG] Searching for torrents: "${title}" (${year})`);
    
    let allTorrents = [];
    
    // Try YTS first
    console.log('[DEBUG] Searching YTS...');
    let result = await ipcRenderer.invoke('search-yts', { title, year });
    
    if (result.success && result.data) {
        console.log(`[DEBUG] YTS found: ${result.data.torrents ? result.data.torrents.length : 0} torrents`);
        if (result.data.torrents && result.data.torrents.length > 0) {
            result.data.torrents.forEach(t => {
                allTorrents.push({
                    source: 'YTS',
                    quality: t.quality || 'Unknown',
                    size: t.size || 'Unknown',
                    seeds: t.seeds || 0,
                    hash: t.hash,
                    title: result.data.title,
                    type: t.type || 'web'
                });
            });
        }
    } else {
        console.log('[DEBUG] YTS search failed:', result.error);
    }
    
    // Try PirateBay as fallback
    console.log('[DEBUG] Searching ThePirateBay...');
    result = await ipcRenderer.invoke('search-piratebay', { title, year });
    
    if (result.success && result.data) {
        console.log(`[DEBUG] TPB found result with hash: ${result.data.info_hash}`);
        allTorrents.push({
            source: 'ThePirateBay',
            quality: 'Unknown',
            size: result.data.size || 'Unknown',
            seeds: result.data.seeders || 0,
            hash: result.data.info_hash,
            title: result.data.name,
            type: 'tpb'
        });
    } else {
        console.log('[DEBUG] TPB search failed:', result.error);
    }
    
    console.log(`[DEBUG] Total torrents found: ${allTorrents.length}`);
    
    if (allTorrents.length === 0) {
        showToast('No torrents found for: ' + title + '. Try a different title or check spelling.', 'error');
        return;
    }
    
    // Show torrent selection dialog
    showTorrentSelectionDialog(title, allTorrents);
}

function generateMagnetFromYTS(movie) {
    if (!movie.torrents || movie.torrents.length === 0) return null;
    
    // Prefer 1080p > 720p > any
    let torrent = movie.torrents.find(t => t.quality === '1080p') ||
                  movie.torrents.find(t => t.quality === '720p') ||
                  movie.torrents[0];
    
    const trackers = [
        'udp://open.demonii.com:1337/announce',
        'udp://tracker.openbittorrent.com:80',
        'udp://tracker.coppersurfer.tk:6969',
        'udp://glotorrents.pw:6969/announce',
        'udp://tracker.opentrackr.org:1337/announce',
        'udp://exodus.desync.com:6969/announce'
    ];
    
    let magnet = `magnet:?xt=urn:btih:${torrent.hash}&dn=${encodeURIComponent(movie.title)}`;
    trackers.forEach(tracker => {
        magnet += `&tr=${encodeURIComponent(tracker)}`;
    });
    
    return magnet;
}

function generateMagnetFromTPB(torrent) {
    if (!torrent.info_hash) return null;
    
    const trackers = [
        'udp://tracker.coppersurfer.tk:6969/announce',
        'udp://tracker.openbittorrent.com:80/announce',
        'udp://tracker.opentrackr.org:1337/announce'
    ];
    
    let magnet = `magnet:?xt=urn:btih:${torrent.info_hash}&dn=${encodeURIComponent(torrent.name)}`;
    trackers.forEach(tracker => {
        magnet += `&tr=${encodeURIComponent(tracker)}`;
    });
    
    return magnet;
}

async function streamMovie(title, year, poster, overview) {
    console.log(`[DEBUG] streamMovie called: ${title} (${year})`);
    addToWatchHistory(title, year, poster, overview);
    await searchAndStream(title, year);
}

// ===========================
// Torrent Selection Dialog
// ===========================

function showTorrentSelectionDialog(movieTitle, torrents) {
    const modal = document.getElementById('movie-modal');
    const modalBody = document.getElementById('modal-body');
    
    // Sort torrents by quality preference (1080p > 720p > others) and seeds
    const qualityOrder = { '2160p': 5, '1080p': 4, '720p': 3, '480p': 2 };
    torrents.sort((a, b) => {
        const qualityDiff = (qualityOrder[b.quality] || 1) - (qualityOrder[a.quality] || 1);
        if (qualityDiff !== 0) return qualityDiff;
        return (b.seeds || 0) - (a.seeds || 0);
    });
    
    let html = `
        <div class="torrent-selection">
            <h2>Select Torrent Quality</h2>
            <p class="subtitle">${movieTitle}</p>
            <div class="torrent-list">
    `;
    
    torrents.forEach((torrent, index) => {
        const qualityBadge = torrent.quality !== 'Unknown' 
            ? `<span class="quality-badge quality-${torrent.quality.toLowerCase()}">${torrent.quality}</span>`
            : '';
        
        html += `
            <div class="torrent-item" data-index="${index}">
                <div class="torrent-info">
                    <div class="torrent-header">
                        ${qualityBadge}
                        <span class="source-badge">${torrent.source}</span>
                    </div>
                    <div class="torrent-details">
                        <span class="torrent-size">📦 ${torrent.size}</span>
                        <span class="torrent-seeds">🌱 ${torrent.seeds} seeds</span>
                    </div>
                </div>
                <button class="btn btn-primary select-torrent-btn" onclick="selectTorrent(${index})">
                    ▶ Stream This
                </button>
            </div>
        `;
    });
    
    html += `
            </div>
            <button class="btn btn-secondary" onclick="closeModal()">Cancel</button>
        </div>
    `;
    
    modalBody.innerHTML = html;
    modal.classList.add('active');
    
    // Store torrents globally for selection
    window.currentTorrents = torrents;
}

function selectTorrent(index) {
    const torrents = window.currentTorrents;
    if (!torrents || !torrents[index]) {
        showToast('Invalid torrent selection', 'error');
        return;
    }
    
    const torrent = torrents[index];
    console.log(`[DEBUG] Selected torrent:`, torrent);
    
    // Generate magnet link
    const magnet = generateMagnetFromTorrent(torrent);
    
    if (!magnet) {
        showToast('Failed to generate magnet link', 'error');
        return;
    }
    
    console.log(`[DEBUG] Generated magnet:`, magnet.substring(0, 100) + '...');
    
    closeModal();
    streamMagnet(magnet);
}

function generateMagnetFromTorrent(torrent) {
    if (!torrent.hash) return null;
    
    const trackers = [
        'udp://open.demonii.com:1337/announce',
        'udp://tracker.openbittorrent.com:80',
        'udp://tracker.coppersurfer.tk:6969',
        'udp://glotorrents.pw:6969/announce',
        'udp://tracker.opentrackr.org:1337/announce',
        'udp://exodus.desync.com:6969/announce',
        'udp://tracker.leechers-paradise.org:6969/announce',
        'udp://tracker.zer0day.to:1337/announce'
    ];
    
    let magnet = `magnet:?xt=urn:btih:${torrent.hash}&dn=${encodeURIComponent(torrent.title)}`;
    trackers.forEach(tracker => {
        magnet += `&tr=${encodeURIComponent(tracker)}`;
    });
    
    return magnet;
}

// Make function available globally
window.selectTorrent = selectTorrent;

// ===========================
// Real Debrid Streaming
// ===========================

async function streamMagnet(magnet) {
    if (!config.rdApiKey) {
        showToast('Please configure Real Debrid API key in Settings', 'error');
        console.error('[ERROR] No Real Debrid API key configured');
        return;
    }
    
    console.log('[DEBUG] Starting Real Debrid streaming process...');
    showToast('Adding magnet to Real Debrid...', 'success');
    
    // Add magnet
    console.log('[DEBUG] Adding magnet to Real Debrid...');
    const addResult = await ipcRenderer.invoke('rd-add-magnet', {
        apiKey: config.rdApiKey,
        magnet: magnet
    });
    
    if (!addResult.success) {
        const errorMsg = 'Failed to add magnet: ' + (addResult.error || 'Unknown error');
        console.error('[ERROR]', errorMsg);
        console.error('[ERROR] Full response:', addResult);
        showToast(errorMsg + '. Check console for details.', 'error');
        return;
    }
    
    console.log('[DEBUG] Magnet added successfully. Torrent ID:', addResult.data.id);
    const torrentId = addResult.data.id;
    showToast('Processing torrent... (this may take 10-30 seconds)', 'success');
    
    // Wait and get info
    await sleep(2000);
    
    for (let i = 0; i < 15; i++) {
        console.log(`[DEBUG] Check ${i + 1}/15: Getting torrent info...`);
        
        const infoResult = await ipcRenderer.invoke('rd-get-info', {
            apiKey: config.rdApiKey,
            torrentId: torrentId
        });
        
        if (!infoResult.success) {
            const errorMsg = 'Failed to get torrent info: ' + (infoResult.error || 'Unknown error');
            console.error('[ERROR]', errorMsg);
            showToast(errorMsg, 'error');
            return;
        }
        
        const info = infoResult.data;
        console.log(`[DEBUG] Torrent status: ${info.status}`);
        
        if (info.status === 'waiting_files_selection') {
            console.log('[DEBUG] Torrent waiting for file selection...');
            // Select all video files
            if (info.files && info.files.length > 0) {
                console.log(`[DEBUG] Found ${info.files.length} files in torrent`);
                
                // Filter for video files (optional: select only largest file)
                const videoExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm'];
                const videoFiles = info.files.filter(f => 
                    videoExtensions.some(ext => f.path.toLowerCase().endsWith(ext))
                );
                
                let fileIds;
                if (videoFiles.length > 0) {
                    // Select only video files
                    fileIds = videoFiles.map(f => f.id).join(',');
                    console.log(`[DEBUG] Selecting ${videoFiles.length} video files:`, fileIds);
                } else {
                    // Select all files if no video files found
                    fileIds = info.files.map((_, idx) => idx + 1).join(',');
                    console.log(`[DEBUG] No video files detected, selecting all files:`, fileIds);
                }
                
                const selectResult = await ipcRenderer.invoke('rd-select-files', {
                    apiKey: config.rdApiKey,
                    torrentId: torrentId,
                    fileIds: fileIds
                });
                
                if (!selectResult.success) {
                    console.error('[ERROR] Failed to select files:', selectResult.error);
                }
                
                await sleep(3000);
                continue;
            }
        } else if (info.status === 'downloaded' || (info.links && info.links.length > 0)) {
            console.log('[DEBUG] Torrent is ready! Getting stream link...');
            // Get stream link
            if (!info.links || info.links.length === 0) {
                console.error('[ERROR] No links available in downloaded torrent');
                showToast('Torrent downloaded but no links available', 'error');
                return;
            }
            
            const link = info.links[0];
            console.log(`[DEBUG] Unrestricting link: ${link}`);
            
            const unrestrictResult = await ipcRenderer.invoke('rd-unrestrict', {
                apiKey: config.rdApiKey,
                link: link
            });
            
            if (unrestrictResult.success) {
                const streamUrl = unrestrictResult.data.download;
                console.log('[DEBUG] Stream URL obtained:', streamUrl.substring(0, 50) + '...');
                showToast('Starting playback in VLC...', 'success');
                playInVLC(streamUrl);
                return;
            } else {
                console.error('[ERROR] Failed to unrestrict link:', unrestrictResult.error);
                showToast('Failed to get stream URL: ' + unrestrictResult.error, 'error');
                return;
            }
        } else if (info.status === 'magnet_error') {
            console.error('[ERROR] Magnet error from Real Debrid');
            showToast('Real Debrid reported a magnet error. Try a different torrent.', 'error');
            return;
        } else if (info.status === 'error') {
            console.error('[ERROR] Real Debrid error status');
            showToast('Real Debrid encountered an error processing this torrent.', 'error');
            return;
        } else if (info.status === 'virus') {
            console.error('[ERROR] Torrent flagged as virus');
            showToast('This torrent was flagged as malicious by Real Debrid.', 'error');
            return;
        } else if (info.status === 'dead') {
            console.error('[ERROR] Torrent is dead (no seeders)');
            showToast('This torrent has no seeders. Try a different one.', 'error');
            return;
        }
        
        console.log(`[DEBUG] Status '${info.status}', waiting 2 seconds...`);
        await sleep(2000);
    }
    
    console.error('[ERROR] Timeout waiting for torrent (15 attempts)');
    showToast('Timeout: Torrent took too long to process. Try a different one or check your Real Debrid account.', 'error');
}

function playInVLC(url) {
    // Try to open in VLC
    let vlcCommand;
    
    if (process.platform === 'win32') {
        // Windows
        vlcCommand = `"C:\\Program Files\\VideoLAN\\VLC\\vlc.exe" "${url}"`;
        
        // Try alternative path
        exec(vlcCommand, (error) => {
            if (error) {
                vlcCommand = `"C:\\Program Files (x86)\\VideoLAN\\VLC\\vlc.exe" "${url}"`;
                exec(vlcCommand, (error2) => {
                    if (error2) {
                        showToast('Could not find VLC. Please install VLC Media Player.', 'error');
                    }
                });
            }
        });
    } else if (process.platform === 'darwin') {
        // macOS
        vlcCommand = `open -a VLC "${url}"`;
        exec(vlcCommand, (error) => {
            if (error) {
                showToast('Could not open VLC', 'error');
            }
        });
    } else {
        // Linux
        vlcCommand = `vlc "${url}"`;
        exec(vlcCommand, (error) => {
            if (error) {
                showToast('Could not open VLC', 'error');
            }
        });
    }
}

// ===========================
// Watch History
// ===========================

function loadWatchHistory() {
    const stored = localStorage.getItem('watchHistory');
    if (stored) {
        watchHistory = JSON.parse(stored);
        displayContinueWatching();
    }
}

function saveWatchHistory() {
    localStorage.setItem('watchHistory', JSON.stringify(watchHistory));
}

function addToWatchHistory(title, year, poster, overview) {
    // Remove if already exists
    watchHistory = watchHistory.filter(item => item.title !== title);
    
    // Add to beginning
    watchHistory.unshift({
        title: title,
        year: year,
        poster: poster,
        overview: overview,
        timestamp: Date.now()
    });
    
    // Limit to 50 items
    if (watchHistory.length > 50) {
        watchHistory = watchHistory.slice(0, 50);
    }
    
    saveWatchHistory();
    displayContinueWatching();
}

function displayContinueWatching() {
    if (watchHistory.length === 0) {
        document.getElementById('continue-watching-section').style.display = 'none';
        return;
    }
    
    document.getElementById('continue-watching-section').style.display = 'block';
    
    const container = document.getElementById('continue-watching-list');
    container.innerHTML = '';
    
    const recentItems = watchHistory.slice(0, 6);
    
    recentItems.forEach(item => {
        const card = document.createElement('div');
        card.className = 'movie-card';
        
        const posterUrl = item.poster || 'https://via.placeholder.com/200x300/333/fff?text=No+Poster';
        
        card.innerHTML = `
            <img src="${posterUrl}" alt="${item.title}" class="movie-poster" onerror="this.src='https://via.placeholder.com/200x300/333/fff?text=No+Poster'">
            <div class="movie-info">
                <div class="movie-title" title="${item.title}">${item.title}</div>
                <div class="movie-meta">
                    <span>${item.year}</span>
                    <span>${getTimeAgo(item.timestamp)}</span>
                </div>
                <button class="stream-btn">▶ Stream Again</button>
            </div>
        `;
        
        card.querySelector('.stream-btn').addEventListener('click', (e) => {
            e.stopPropagation();
            streamMovie(item.title, item.year, item.poster, item.overview);
        });
        
        container.appendChild(card);
    });
}

function getTimeAgo(timestamp) {
    const seconds = Math.floor((Date.now() - timestamp) / 1000);
    
    if (seconds < 3600) {
        return Math.floor(seconds / 60) + 'm ago';
    } else if (seconds < 86400) {
        return Math.floor(seconds / 3600) + 'h ago';
    } else {
        return Math.floor(seconds / 86400) + 'd ago';
    }
}

// ===========================
// Settings & Testing
// ===========================

async function testConnection() {
    const apiKey = document.getElementById('rd-api-key').value;
    
    if (!apiKey) {
        showStatus('Please enter Real Debrid API key', 'error');
        return;
    }
    
    showStatus('Testing connection...', 'success');
    
    const result = await ipcRenderer.invoke('rd-test-key', apiKey);
    
    if (result.success) {
        showStatus(`✅ Connected! Username: ${result.username}`, 'success');
    } else {
        showStatus('❌ Connection failed: ' + result.error, 'error');
    }
}

// ===========================
// UI Helpers
// ===========================

function showLoading(show) {
    const loader = document.getElementById('loading-indicator');
    if (loader) {
        loader.style.display = show ? 'block' : 'none';
    }
}

function showToast(message, type = 'success') {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.className = `toast ${type}`;
    toast.classList.add('show');
    
    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

function showStatus(message, type = 'success') {
    const status = document.getElementById('settings-status');
    status.textContent = message;
    status.className = `status-message ${type}`;
    
    setTimeout(() => {
        status.style.display = 'none';
    }, 5000);
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

console.log('Renderer loaded');
