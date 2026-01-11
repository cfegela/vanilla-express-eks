# User Management Backend

A lightweight RESTful API built with Node.js and Express to manage user data. This service provides CRUD operations with JWT-based authentication and role-based access control, persisting data to local JSON files.

## Features

- **JWT Authentication**: Secure access and refresh token system with automatic token rotation.
- **Role-Based Access Control**: Admin-only endpoints for create, update, and delete operations.
- **RESTful API**: Standard HTTP methods for managing users.
- **Data Persistence**: Uses local JSON files (`data/users.json` and `data/auth-users.json`) to store data.
- **CORS Support**: Configured to allow requests from the frontend origin.
- **Zero Database Setup**: No external database required; just run and go.

## Prerequisites

- [Node.js](https://nodejs.org/) (v14 or higher recommended)
- npm (Node Package Manager)

## Installation

1.  Navigate to the backend directory:
    ```bash
    cd backend
    ```

2.  Install dependencies:
    ```bash
    npm install
    ```

3.  Create a `.env` file from the example:
    ```bash
    cp .env.example .env
    ```

4.  Update the `.env` file with secure secrets:
    ```
    JWT_ACCESS_SECRET=your-secure-random-string-at-least-32-chars
    JWT_REFRESH_SECRET=your-different-secure-random-string
    JWT_ACCESS_EXPIRY=15m
    JWT_REFRESH_EXPIRY=7d
    PORT=3000
    ```

5.  Create an admin user:
    ```bash
    npm run seed:admin admin YourSecurePassword123
    ```

## Usage

### Starting the Server

To start the server in production mode:
```bash
npm start
```

To start the server in development mode (with watch mode enabled for Node.js 18+):
```bash
npm run dev
```

The server will start on port **3000** by default (e.g., `http://localhost:3000`).

## API Endpoints

### Authentication Endpoints

#### POST /auth/login
Authenticates a user and returns tokens.

- **Body** (JSON):
    ```json
    {
      "username": "admin",
      "password": "YourSecurePassword123"
    }
    ```
- **Response**:
    ```json
    {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "user": {
        "id": "uuid",
        "username": "admin",
        "email": "admin@example.com",
        "role": "admin"
      }
    }
    ```

#### POST /auth/refresh
Exchanges a refresh token for new access and refresh tokens.

- **Body** (JSON):
    ```json
    {
      "refreshToken": "your-refresh-token"
    }
    ```
- **Response**: New `accessToken` and `refreshToken`.

#### POST /auth/logout
Invalidates the provided refresh token.

- **Body** (JSON):
    ```json
    {
      "refreshToken": "your-refresh-token"
    }
    ```

#### POST /auth/logout-all
Invalidates all refresh tokens for the authenticated user. Requires authentication.

- **Headers**: `Authorization: Bearer <access-token>`

#### GET /auth/me
Returns the authenticated user's profile. Requires authentication.

- **Headers**: `Authorization: Bearer <access-token>`
- **Response**: User object with `id`, `username`, `email`, `role`, and `lastLogin`.

### User Endpoints

All user endpoints require authentication via Bearer token in the Authorization header.

#### GET /users
Retrieves a list of all registered users.

- **Headers**: `Authorization: Bearer <access-token>`
- **Response**: Array of user objects.

#### GET /users/:id
Retrieves details of a specific user by ID.

- **Headers**: `Authorization: Bearer <access-token>`
- **Response**: User object or error if not found.

#### POST /users (Admin only)
Adds a new user to the system.

- **Headers**: `Authorization: Bearer <access-token>`
- **Body** (JSON):
    ```json
    {
      "name": "John Doe",
      "email": "john@example.com",
      "city": "New York",
      "state": "NY"
    }
    ```
- **Required Fields**: `name`, `email`
- **Response**: The created user object with an assigned `id`.

#### PUT /users/:id (Admin only)
Updates an existing user's information.

- **Headers**: `Authorization: Bearer <access-token>`
- **Body** (JSON): Partial or full user object.
    ```json
    {
      "city": "San Francisco"
    }
    ```
- **Response**: The updated user object.

#### DELETE /users/:id (Admin only)
Removes a user from the system.

- **Headers**: `Authorization: Bearer <access-token>`
- **Response**: The deleted user object.

### Health Check

#### GET /health
Returns the server health status.

- **Response**: `{ "status": "ok", "timestamp": "..." }`

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3000` |
| `JWT_ACCESS_SECRET` | Secret for signing access tokens | (required) |
| `JWT_REFRESH_SECRET` | Secret for signing refresh tokens | (required) |
| `JWT_ACCESS_EXPIRY` | Access token expiry | `15m` |
| `JWT_REFRESH_EXPIRY` | Refresh token expiry | `7d` |

## Project Structure

```
backend/
├── server.js              # Main entry point
├── package.json           # Project dependencies and scripts
├── .env.example           # Environment variables template
├── data/
│   ├── users.json         # User data (managed via API)
│   └── auth-users.json    # Authentication credentials
├── middleware/
│   └── auth.js            # JWT authentication middleware
├── routes/
│   ├── auth.js            # Authentication routes
│   └── users.js           # User CRUD routes
├── scripts/
│   └── seed-admin.js      # Admin user creation script
└── utils/
    ├── auth-store.js      # Auth data persistence utilities
    └── token-utils.js     # JWT token utilities
```

## Scripts

| Script | Command | Description |
|--------|---------|-------------|
| `start` | `npm start` | Start the server |
| `dev` | `npm run dev` | Start with watch mode |
| `seed:admin` | `npm run seed:admin <username> <password>` | Create an admin user |
