const express = require('express');
const bcrypt = require('bcrypt');
const router = express.Router();

const {
    findUserByUsername,
    findUserById,
    saveRefreshToken,
    findRefreshToken,
    deleteRefreshToken,
    deleteAllUserRefreshTokens,
    readAuthData,
    writeAuthData
} = require('../utils/auth-store');

const {
    generateAccessToken,
    generateRefreshToken,
    hashToken
} = require('../utils/token-utils');

const { authenticateToken } = require('../middleware/auth');

// POST /auth/login
router.post('/login', async (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ error: 'Username and password required' });
    }

    const user = findUserByUsername(username);
    if (!user) {
        return res.status(401).json({ error: 'Invalid credentials' });
    }

    const validPassword = await bcrypt.compare(password, user.passwordHash);
    if (!validPassword) {
        return res.status(401).json({ error: 'Invalid credentials' });
    }

    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken();
    const refreshTokenHash = hashToken(refreshToken);

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    saveRefreshToken(
        refreshTokenHash,
        user.id,
        expiresAt.toISOString(),
        req.headers['user-agent']
    );

    const data = readAuthData();
    const userIndex = data.users.findIndex(u => u.id === user.id);
    data.users[userIndex].lastLogin = new Date().toISOString();
    writeAuthData(data);

    res.json({
        accessToken,
        refreshToken,
        user: {
            id: user.id,
            username: user.username,
            email: user.email,
            role: user.role
        }
    });
});

// POST /auth/refresh
router.post('/refresh', async (req, res) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
        return res.status(400).json({ error: 'Refresh token required' });
    }

    const tokenHash = hashToken(refreshToken);
    const storedToken = findRefreshToken(tokenHash);

    if (!storedToken) {
        return res.status(403).json({ error: 'Invalid refresh token' });
    }

    if (new Date(storedToken.expiresAt) < new Date()) {
        deleteRefreshToken(tokenHash);
        return res.status(403).json({ error: 'Refresh token expired' });
    }

    const user = findUserById(storedToken.userId);
    if (!user) {
        deleteRefreshToken(tokenHash);
        return res.status(403).json({ error: 'User not found' });
    }

    deleteRefreshToken(tokenHash);

    const newAccessToken = generateAccessToken(user);
    const newRefreshToken = generateRefreshToken();
    const newRefreshTokenHash = hashToken(newRefreshToken);

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    saveRefreshToken(
        newRefreshTokenHash,
        user.id,
        expiresAt.toISOString(),
        req.headers['user-agent']
    );

    res.json({
        accessToken: newAccessToken,
        refreshToken: newRefreshToken
    });
});

// POST /auth/logout
router.post('/logout', (req, res) => {
    const { refreshToken } = req.body;

    if (refreshToken) {
        const tokenHash = hashToken(refreshToken);
        deleteRefreshToken(tokenHash);
    }

    res.json({ message: 'Logged out successfully' });
});

// POST /auth/logout-all
router.post('/logout-all', authenticateToken, (req, res) => {
    deleteAllUserRefreshTokens(req.user.userId);
    res.json({ message: 'Logged out from all devices' });
});

// GET /auth/me
router.get('/me', authenticateToken, (req, res) => {
    const user = findUserById(req.user.userId);
    if (!user) {
        return res.status(404).json({ error: 'User not found' });
    }

    res.json({
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
        lastLogin: user.lastLogin
    });
});

module.exports = router;
