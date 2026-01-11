# User Management Backend

A lightweight RESTful API built with Node.js and Express to manage user data. This service provides basic CRUD (Create, Read, Update, Delete) operations and persists data to a local JSON file.

## Features

- **RESTful API**: Standard HTTP methods for managing users.
- **Data Persistence**: Uses a local JSON file (`data/users.json`) to store user records.
- **CORS Support**: Configured to allow requests from any origin, making it easy to integrate with frontends.
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

### 1. Get All Users
Retrieves a list of all registered users.

- **URL**: `/users`
- **Method**: `GET`
- **Response**: Array of user objects.

### 2. Get Single User
Retrieves details of a specific user by ID.

- **URL**: `/users/:id`
- **Method**: `GET`
- **Response**: User object or error if not found.

### 3. Create User
Adds a new user to the system.

- **URL**: `/users`
- **Method**: `POST`
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

### 4. Update User
Updates an existing user's information.

- **URL**: `/users/:id`
- **Method**: `PUT`
- **Body** (JSON): Partial or full user object.
    ```json
    {
      "city": "San Francisco"
    }
    ```
- **Response**: The updated user object.

### 5. Delete User
Removes a user from the system.

- **URL**: `/users/:id`
- **Method**: `DELETE`
- **Response**: The deleted user object.

## Configuration

- **Port**: The server listens on port `3000` by default. You can override this by setting the `PORT` environment variable.
- **Data Storage**: Data is stored in `data/users.json`. Ensure this directory and file are writable by the application.

## Project Structure

- `server.js`: Main entry point and application logic.
- `package.json`: Project dependencies and scripts.
- `data/`: Directory containing the data store.
    - `users.json`: JSON file acting as the database.
