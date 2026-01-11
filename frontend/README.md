# User Management Frontend

A simple vanilla JavaScript frontend application for managing users. This application provides a user interface to interact with the backend API using JWT authentication.

## Features

- **JWT Authentication**: Secure login with access and refresh tokens, automatic token refresh on expiry.
- **User List**: View a table of all registered users.
- **Create User**: Add new users with details like name, email, city, and state (admin only).
- **Edit User**: Update existing user information (admin only).
- **Delete User**: Remove users from the system (admin only).

## Technologies

- HTML5
- CSS3
- Vanilla JavaScript (ES6+)
- Fetch API for backend communication
- JWT token management with automatic refresh

## Prerequisites

- Docker (for containerized deployment) or a static file server.
- A backend API running at `http://localhost:3000` (see `../backend/README.md` for setup instructions).
- An admin user created in the backend (using `npm run seed:admin`).
- A modern web browser.

## Getting Started

### Running with Docker

The easiest way to run the frontend is with Docker Compose from the project root:

```bash
docker-compose up --build
```

Or build and run the frontend container directly:

```bash
docker build -t frontend .
docker run -p 80:80 frontend
```

The frontend uses Nginx to serve static files and will be available at `http://localhost:80`.

### Running Locally

1.  **Start the Backend**: Ensure the backend server is running and configured with JWT secrets.

2.  **Create an Admin User** (if not already done):
    ```bash
    cd ../backend
    npm run seed:admin admin YourSecurePassword123
    ```

3.  **Open the Application**:
    Serve the `frontend` directory using a static file server. For example:

    Using Python:
    ```bash
    cd frontend
    python3 -m http.server 80
    ```
    Then navigate to `http://localhost:80` in your browser.

    *Note: The backend is configured to accept requests from `http://localhost:80`. If you use a different port, update the CORS configuration in the backend.*

4.  **Login**:
    Use the admin credentials you created with the seed script:
    - **Username**: `admin` (or the username you chose)
    - **Password**: The password you set when running the seed script

## Project Structure

- `Dockerfile`: Container image definition using Nginx.
- `index.html`: Login page (Entry point).
- `users.html`: Dashboard showing the list of users.
- `add-user.html`: Form to create a new user.
- `edit-user.html`: Form to edit an existing user.
- `app.js`: Contains all the application logic, including API calls, JWT token management, and authentication.
- `styles.css`: Application styling.

## Authentication Flow

1. User enters credentials on the login page.
2. Frontend sends credentials to `/auth/login` endpoint.
3. Backend validates credentials and returns access token (short-lived) and refresh token (long-lived).
4. Frontend stores tokens in localStorage and includes the access token in all API requests.
5. When the access token expires, the frontend automatically uses the refresh token to obtain new tokens.
6. On logout, the frontend invalidates the refresh token on the backend and clears local storage.

## Configuration

The API URL is defined in `app.js`:
```javascript
const API_URL = 'http://localhost:3000';
```
If your backend is running on a different port or host, update this constant in `app.js`.
