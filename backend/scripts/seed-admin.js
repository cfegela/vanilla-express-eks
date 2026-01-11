require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const path = require('path');

const AUTH_FILE = path.join(__dirname, '..', 'data', 'auth-users.json');

async function seedAdmin() {
    const username = process.argv[2] || 'admin';
    const password = process.argv[3];

    if (!password) {
        console.error('Usage: node seed-admin.js <username> <password>');
        console.error('Example: node seed-admin.js admin MySecureP@ss123');
        process.exit(1);
    }

    if (password.length < 8) {
        console.error('Error: Password must be at least 8 characters');
        process.exit(1);
    }

    const passwordHash = await bcrypt.hash(password, 12);

    let data = { users: [], refreshTokens: [] };

    if (fs.existsSync(AUTH_FILE)) {
        data = JSON.parse(fs.readFileSync(AUTH_FILE, 'utf8'));
    }

    const existingUser = data.users.find(u => u.username === username);
    if (existingUser) {
        console.error(`Error: User '${username}' already exists`);
        process.exit(1);
    }

    const newUser = {
        id: uuidv4(),
        username,
        passwordHash,
        email: `${username}@example.com`,
        role: 'admin',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        lastLogin: null
    };

    data.users.push(newUser);
    fs.writeFileSync(AUTH_FILE, JSON.stringify(data, null, 2));

    console.log(`Admin user '${username}' created successfully`);
    console.log(`User ID: ${newUser.id}`);
}

seedAdmin().catch(console.error);
