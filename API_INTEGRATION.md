# API Integration Documentation

## Overview
This document provides comprehensive documentation of the REST API endpoints for the Taskflow Mobile application.

## Authentication

### Endpoint: `POST /api/auth/login`
- **Description**: Authenticate a user and return an access token.
- **Request Body**:
  - `username`: string
  - `password`: string
- **Response**:
  - `token`: string

### Endpoint: `POST /api/auth/logout`
- **Description**: Log out the authenticated user.
- **Response**:
  - `message`: string

## Tasks

### Endpoint: `GET /api/tasks`
- **Description**: Retrieve a list of tasks.
- **Response**:
  - `tasks`: array of task objects

### Endpoint: `POST /api/tasks`
- **Description**: Create a new task.
- **Request Body**:
  - `title`: string
  - `description`: string
  - `deadline`: string (optional)
- **Response**:
  - `task`: task object

### Endpoint: `GET /api/tasks/{id}`
- **Description**: Retrieve a specific task by ID.
- **Response**:
  - `task`: task object

### Endpoint: `PUT /api/tasks/{id}`
- **Description**: Update a specific task by ID.
- **Request Body**:
  - `title`: string (optional)
  - `description`: string (optional)
  - `completed`: boolean (optional)
- **Response**:
  - `task`: updated task object

### Endpoint: `DELETE /api/tasks/{id}`
- **Description**: Delete a specific task by ID.
- **Response**:
  - `message`: string

## Users

### Endpoint: `GET /api/users`
- **Description**: Retrieve a list of users.
- **Response**:
  - `users`: array of user objects

### Endpoint: `POST /api/users`
- **Description**: Create a new user.
- **Request Body**:
  - `username`: string
  - `password`: string
- **Response**:
  - `user`: user object

### Endpoint: `GET /api/users/{id}`
- **Description**: Retrieve a specific user by ID.
- **Response**:
  - `user`: user object

### Endpoint: `PUT /api/users/{id}`
- **Description**: Update a specific user by ID.
- **Request Body**:
  - `username`: string (optional)
  - `password`: string (optional)
- **Response**:
  - `user`: updated user object

### Endpoint: `DELETE /api/users/{id}`
- **Description**: Delete a specific user by ID.
- **Response**:
  - `message`: string

## Attachments

### Endpoint: `POST /api/attachments`
- **Description**: Upload an attachment.
- **Request Body**:
  - `file`: binary
- **Response**:
  - `attachment`: attachment object

### Endpoint: `GET /api/attachments/{id}`
- **Description**: Retrieve a specific attachment by ID.
- **Response**:
  - `attachment`: attachment object

### Endpoint: `DELETE /api/attachments/{id}`
- **Description**: Delete a specific attachment by ID.
- **Response**:
  - `message`: string

## Dashboard

### Endpoint: `GET /api/dashboard/stats`
- **Description**: Retrieve statistics for the dashboard.
- **Response**:
  - `stats`: dashboard statistics object

### Endpoint: `GET /api/dashboard/tasks`
- **Description**: Retrieve tasks for the dashboard.
- **Response**:
  - `tasks`: array of task objects with dashboard view formatting.

### Endpoint: `GET /api/dashboard/users`
- **Description**: Retrieve user statistics for the dashboard.
- **Response**:
  - `users`: array of user statistics objects.