# User Management Frontend

A simple vanilla JavaScript frontend application for managing users. This application provides a user interface to interact with the backend API.

## Features

- **Authentication**: Simple client-side login (Demo credentials).
- **User List**: View a table of all registered users.
- **Create User**: Add new users with details like name, email, city, and state.
- **Edit User**: Update existing user information.
- **Delete User**: Remove users from the system.

## Technologies

- HTML5
- CSS3
- Vanilla JavaScript (ES6+)
- Fetch API for backend communication

## Prerequisites

- A backend API running at `http://localhost:3000` (see `../backend/README.md` if available, or check `../backend/` directory).
- A modern web browser.

## Getting Started

1.  **Start the Backend**: Ensure the backend server is running.
2.  **Open the Application**:
    You can serve the `frontend` directory using a static file server. For example:

    Using Python:
    ```bash
    cd frontend
    python3 -m http.server 8000
    ```
    Then navigate to `http://localhost:8000` in your browser.

    *Note: Simply opening `index.html` directly in the browser might encounter CORS issues depending on the backend configuration.*

3.  **Login**:
    Use the following demo credentials:
    - **Username**: `admin`
    - **Password**: `password123`

## Project Structure

- `index.html`: Login page (Entry point).
- `users.html`: Dashboard showing the list of users.
- `add-user.html`: Form to create a new user.
- `edit-user.html`: Form to edit an existing user.
- `app.js`: Contains all the application logic, including API calls and authentication.
- `styles.css`: Application styling.

## Configuration

The API URL is defined in `app.js`:
```javascript
const API_URL = 'http://localhost:3000';
```
If your backend is running on a different port or host, update this constant in `app.js`.
