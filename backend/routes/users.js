const express = require('express');
const fs = require('fs');
const path = require('path');
const router = express.Router();

const { authenticateToken, requireAdmin } = require('../middleware/auth');

const DATA_FILE = path.join(__dirname, '..', 'data', 'users.json');

function readUsers() {
    const data = fs.readFileSync(DATA_FILE, 'utf8');
    return JSON.parse(data);
}

function writeUsers(users) {
    fs.writeFileSync(DATA_FILE, JSON.stringify(users, null, 2));
}

// All routes require authentication
router.use(authenticateToken);

// GET /users - List all users
router.get('/', (req, res) => {
    const users = readUsers();
    res.json(users);
});

// GET /users/:id - Get a single user
router.get('/:id', (req, res) => {
    const users = readUsers();
    const user = users.find(u => u.id === parseInt(req.params.id));
    if (!user) {
        return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
});

// POST /users - Create a new user (admin only)
router.post('/', requireAdmin, (req, res) => {
    const { name, email, city, state } = req.body;
    if (!name || !email) {
        return res.status(400).json({ error: 'Name and email are required' });
    }

    const users = readUsers();
    const newUser = {
        id: users.length > 0 ? Math.max(...users.map(u => u.id)) + 1 : 1,
        name,
        email,
        city: city || '',
        state: state || ''
    };

    users.push(newUser);
    writeUsers(users);
    res.status(201).json(newUser);
});

// PUT /users/:id - Update a user (admin only)
router.put('/:id', requireAdmin, (req, res) => {
    const { name, email, city, state } = req.body;
    const users = readUsers();
    const index = users.findIndex(u => u.id === parseInt(req.params.id));

    if (index === -1) {
        return res.status(404).json({ error: 'User not found' });
    }

    users[index] = {
        ...users[index],
        ...(name && { name }),
        ...(email && { email }),
        ...(city !== undefined && { city }),
        ...(state !== undefined && { state })
    };

    writeUsers(users);
    res.json(users[index]);
});

// DELETE /users/:id - Delete a user (admin only)
router.delete('/:id', requireAdmin, (req, res) => {
    const users = readUsers();
    const index = users.findIndex(u => u.id === parseInt(req.params.id));

    if (index === -1) {
        return res.status(404).json({ error: 'User not found' });
    }

    const deleted = users.splice(index, 1)[0];
    writeUsers(users);
    res.json(deleted);
});

module.exports = router;
