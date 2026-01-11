const API_URL = 'http://localhost:3000';

// Demo credentials
const DEMO_USER = {
    username: 'admin',
    password: 'password123'
};

// Auth helpers
function isLoggedIn() {
    return sessionStorage.getItem('isLoggedIn') === 'true';
}

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

// Login handling
function handleLogin(event) {
    event.preventDefault();

    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    const errorMessage = document.getElementById('error-message');

    if (username === DEMO_USER.username && password === DEMO_USER.password) {
        sessionStorage.setItem('isLoggedIn', 'true');
        sessionStorage.setItem('username', username);
        window.location.href = 'users.html';
    } else {
        errorMessage.textContent = 'Invalid username or password';
    }
}

function handleLogout() {
    sessionStorage.removeItem('isLoggedIn');
    sessionStorage.removeItem('username');
    window.location.href = 'index.html';
}

// User CRUD operations
async function fetchUsers() {
    const loadingEl = document.getElementById('loading');
    const emptyEl = document.getElementById('empty');

    loadingEl.style.display = 'block';
    try {
        const response = await fetch(`${API_URL}/users`);
        if (!response.ok) throw new Error('Failed to fetch users');
        const users = await response.json();
        renderUsers(users);
    } catch (error) {
        showError(error.message);
    } finally {
        loadingEl.style.display = 'none';
    }
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
            <td>${user.id}</td>
            <td>${user.name}</td>
            <td>${user.email}</td>
            <td>${user.city || ''}</td>
            <td>${user.state || ''}</td>
            <td class="actions">
                <a href="edit-user.html?id=${user.id}" class="btn btn-small">Edit</a>
                <button class="btn btn-small btn-danger" onclick="deleteUser(${user.id})">Delete</button>
            </td>
        `;
        usersBody.appendChild(row);
    });
}

async function fetchUser(id) {
    const response = await fetch(`${API_URL}/users/${id}`);
    if (!response.ok) throw new Error('User not found');
    return response.json();
}

async function createUser(name, email, city, state) {
    const response = await fetch(`${API_URL}/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, city, state })
    });
    if (!response.ok) throw new Error('Failed to create user');
    return response.json();
}

async function updateUser(id, name, email, city, state) {
    const response = await fetch(`${API_URL}/users/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, city, state })
    });
    if (!response.ok) throw new Error('Failed to update user');
    return response.json();
}

async function deleteUser(id) {
    if (!confirm('Are you sure you want to delete this user?')) return;

    try {
        const response = await fetch(`${API_URL}/users/${id}`, {
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

// Initialize
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
