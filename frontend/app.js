const API_URL = 'http://localhost:3000';

// ==================== TOKEN MANAGEMENT ====================

function getAccessToken() {
    return localStorage.getItem('accessToken');
}

function getRefreshToken() {
    return localStorage.getItem('refreshToken');
}

function setTokens(accessToken, refreshToken) {
    localStorage.setItem('accessToken', accessToken);
    localStorage.setItem('refreshToken', refreshToken);
}

function clearTokens() {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('user');
}

function setUser(user) {
    localStorage.setItem('user', JSON.stringify(user));
}

function getUser() {
    const user = localStorage.getItem('user');
    return user ? JSON.parse(user) : null;
}

function isLoggedIn() {
    return !!getAccessToken();
}

// ==================== API WRAPPER WITH AUTO-REFRESH ====================

async function apiRequest(url, options = {}) {
    const accessToken = getAccessToken();

    const headers = {
        'Content-Type': 'application/json',
        ...options.headers
    };

    if (accessToken) {
        headers['Authorization'] = `Bearer ${accessToken}`;
    }

    let response = await fetch(url, { ...options, headers });

    if (response.status === 401) {
        const data = await response.json();

        if (data.code === 'TOKEN_EXPIRED') {
            const refreshed = await refreshAccessToken();

            if (refreshed) {
                headers['Authorization'] = `Bearer ${getAccessToken()}`;
                response = await fetch(url, { ...options, headers });
            } else {
                handleAuthError();
                throw new Error('Session expired. Please login again.');
            }
        } else {
            handleAuthError();
            throw new Error('Authentication required');
        }
    }

    return response;
}

async function refreshAccessToken() {
    const refreshToken = getRefreshToken();

    if (!refreshToken) {
        return false;
    }

    try {
        const response = await fetch(`${API_URL}/auth/refresh`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ refreshToken })
        });

        if (!response.ok) {
            return false;
        }

        const data = await response.json();
        setTokens(data.accessToken, data.refreshToken);
        return true;
    } catch (error) {
        console.error('Token refresh failed:', error);
        return false;
    }
}

function handleAuthError() {
    clearTokens();
    window.location.href = 'index.html';
}

// ==================== AUTH FUNCTIONS ====================

function getCurrentPage() {
    const path = window.location.pathname.split('/').pop() || 'index';
    return path.replace('.html', '').replace('add-', 'add_').replace('edit-', 'edit_');
}

function checkAuth() {
    const currentPage = getCurrentPage();
    const protectedPages = ['users', 'add_user', 'edit_user'];

    if (protectedPages.includes(currentPage) && !isLoggedIn()) {
        window.location.href = 'index.html';
    } else if ((currentPage === 'index' || currentPage === '') && isLoggedIn()) {
        window.location.href = 'users.html';
    }
}

async function handleLogin(event) {
    event.preventDefault();

    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    const errorMessage = document.getElementById('error-message');
    const submitBtn = event.target.querySelector('button[type="submit"]');

    submitBtn.disabled = true;
    submitBtn.textContent = 'Logging in...';

    try {
        const response = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || 'Login failed');
        }

        setTokens(data.accessToken, data.refreshToken);
        setUser(data.user);
        window.location.href = 'users.html';
    } catch (error) {
        errorMessage.textContent = error.message;
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Login';
    }
}

async function handleLogout() {
    const refreshToken = getRefreshToken();

    try {
        await fetch(`${API_URL}/auth/logout`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ refreshToken })
        });
    } catch (error) {
        console.error('Logout error:', error);
    } finally {
        clearTokens();
        window.location.href = 'index.html';
    }
}

// ==================== USER CRUD OPERATIONS ====================

async function fetchUsers() {
    const loadingEl = document.getElementById('loading');

    loadingEl.style.display = 'block';
    try {
        const response = await apiRequest(`${API_URL}/users`);
        if (!response.ok) throw new Error('Failed to fetch users');
        const users = await response.json();
        renderUsers(users);
    } catch (error) {
        showError(error.message);
    } finally {
        loadingEl.style.display = 'none';
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function renderUsers(users) {
    const usersBody = document.getElementById('usersBody');
    const usersTable = document.getElementById('usersTable');
    const emptyEl = document.getElementById('empty');

    usersBody.innerHTML = '';

    if (users.length === 0) {
        usersTable.style.display = 'none';
        emptyEl.style.display = 'block';
        return;
    }

    usersTable.style.display = 'table';
    emptyEl.style.display = 'none';

    users.forEach(user => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${escapeHtml(String(user.id))}</td>
            <td>${escapeHtml(user.name)}</td>
            <td>${escapeHtml(user.email)}</td>
            <td>${escapeHtml(user.city || '')}</td>
            <td>${escapeHtml(user.state || '')}</td>
            <td class="actions">
                <a href="edit-user.html?id=${user.id}" class="btn btn-small">Edit</a>
                <button class="btn btn-small btn-danger" onclick="deleteUser(${user.id})">Delete</button>
            </td>
        `;
        usersBody.appendChild(row);
    });
}

async function fetchUser(id) {
    const response = await apiRequest(`${API_URL}/users/${id}`);
    if (!response.ok) throw new Error('User not found');
    return response.json();
}

async function createUser(name, email, city, state) {
    const response = await apiRequest(`${API_URL}/users`, {
        method: 'POST',
        body: JSON.stringify({ name, email, city, state })
    });
    if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to create user');
    }
    return response.json();
}

async function updateUser(id, name, email, city, state) {
    const response = await apiRequest(`${API_URL}/users/${id}`, {
        method: 'PUT',
        body: JSON.stringify({ name, email, city, state })
    });
    if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to update user');
    }
    return response.json();
}

async function deleteUser(id) {
    if (!confirm('Are you sure you want to delete this user?')) return;

    try {
        const response = await apiRequest(`${API_URL}/users/${id}`, {
            method: 'DELETE'
        });
        if (!response.ok) throw new Error('Failed to delete user');
        fetchUsers();
    } catch (error) {
        showError(error.message);
    }
}

async function handleAddUser(event) {
    event.preventDefault();
    clearError();

    const name = document.getElementById('name').value.trim();
    const email = document.getElementById('email').value.trim();
    const city = document.getElementById('city').value.trim();
    const state = document.getElementById('state').value.trim();

    try {
        await createUser(name, email, city, state);
        window.location.href = 'users.html';
    } catch (error) {
        showError(error.message);
    }
}

async function loadEditUser() {
    const params = new URLSearchParams(window.location.search);
    const userId = params.get('id');

    if (!userId) {
        window.location.href = 'users.html';
        return;
    }

    try {
        const user = await fetchUser(userId);
        document.getElementById('userId').value = user.id;
        document.getElementById('name').value = user.name;
        document.getElementById('email').value = user.email;
        document.getElementById('city').value = user.city || '';
        document.getElementById('state').value = user.state || '';
    } catch (error) {
        showError(error.message);
    }
}

async function handleEditUser(event) {
    event.preventDefault();
    clearError();

    const userId = document.getElementById('userId').value;
    const name = document.getElementById('name').value.trim();
    const email = document.getElementById('email').value.trim();
    const city = document.getElementById('city').value.trim();
    const state = document.getElementById('state').value.trim();

    try {
        await updateUser(userId, name, email, city, state);
        window.location.href = 'users.html';
    } catch (error) {
        showError(error.message);
    }
}

function showError(message) {
    const errorMessage = document.getElementById('error-message');
    if (errorMessage) {
        errorMessage.textContent = message;
    }
}

function clearError() {
    const errorMessage = document.getElementById('error-message');
    if (errorMessage) {
        errorMessage.textContent = '';
    }
}

// ==================== INITIALIZATION ====================

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();

    const currentPage = getCurrentPage();

    if (currentPage === 'index' || currentPage === '') {
        const loginForm = document.getElementById('loginForm');
        if (loginForm) {
            loginForm.addEventListener('submit', handleLogin);
        }
    }

    if (currentPage === 'users') {
        const logoutBtn = document.getElementById('logoutBtn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', handleLogout);
        }

        const user = getUser();
        if (user) {
            const headerEl = document.querySelector('.header h1');
            if (headerEl) {
                headerEl.insertAdjacentHTML('afterend',
                    `<span class="user-info">Logged in as: ${escapeHtml(user.username)}</span>`
                );
            }
        }

        fetchUsers();
    }

    if (currentPage === 'add_user') {
        const addUserForm = document.getElementById('addUserForm');
        if (addUserForm) {
            addUserForm.addEventListener('submit', handleAddUser);
        }
    }

    if (currentPage === 'edit_user') {
        const editUserForm = document.getElementById('editUserForm');
        if (editUserForm) {
            editUserForm.addEventListener('submit', handleEditUser);
            loadEditUser();
        }
    }
});
