const fs = require('fs');
const path = require('path');

const AUTH_FILE = path.join(__dirname, '..', 'data', 'auth-users.json');

function readAuthData() {
    try {
        const data = fs.readFileSync(AUTH_FILE, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        return { users: [], refreshTokens: [] };
    }
}

function writeAuthData(data) {
    fs.writeFileSync(AUTH_FILE, JSON.stringify(data, null, 2));
}

function findUserByUsername(username) {
    const data = readAuthData();
    return data.users.find(u => u.username === username);
}

function findUserById(id) {
    const data = readAuthData();
    return data.users.find(u => u.id === id);
}

function saveRefreshToken(tokenHash, userId, expiresAt, deviceInfo = null) {
    const data = readAuthData();
    data.refreshTokens.push({
        token: tokenHash,
        userId,
        expiresAt,
        createdAt: new Date().toISOString(),
        deviceInfo
    });
    writeAuthData(data);
}

function findRefreshToken(tokenHash) {
    const data = readAuthData();
    return data.refreshTokens.find(t => t.token === tokenHash);
}

function deleteRefreshToken(tokenHash) {
    const data = readAuthData();
    data.refreshTokens = data.refreshTokens.filter(t => t.token !== tokenHash);
    writeAuthData(data);
}

function deleteAllUserRefreshTokens(userId) {
    const data = readAuthData();
    data.refreshTokens = data.refreshTokens.filter(t => t.userId !== userId);
    writeAuthData(data);
}

function cleanExpiredTokens() {
    const data = readAuthData();
    const now = new Date();
    data.refreshTokens = data.refreshTokens.filter(t => new Date(t.expiresAt) > now);
    writeAuthData(data);
}

module.exports = {
    readAuthData,
    writeAuthData,
    findUserByUsername,
    findUserById,
    saveRefreshToken,
    findRefreshToken,
    deleteRefreshToken,
    deleteAllUserRefreshTokens,
    cleanExpiredTokens
};
