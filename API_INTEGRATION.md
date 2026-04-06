# API Integration for Taskflow Mobile Application

## Overview
This document provides comprehensive documentation for all API endpoints used by the Taskflow mobile application, including authentication, task management, user management, file attachments, and dashboard analytics.

## Authentication
Most endpoints require a JWT bearer token obtained from the login endpoint. Include the token in the `Authorization` header of each request:
```
Authorization: Bearer <access_token>
```

The token is stored securely on-device using `flutter_secure_storage` and automatically attached to every request by the Dio JWT interceptor. A 401 response triggers automatic force-logout.

## Base URL
```
http://10.0.2.2:8000   (Android emulator)
http://localhost:8000   (iOS simulator / desktop)
```

All endpoints are relative to the base URL. There is no versioning prefix.

---

## Status Codes

| Code | Meaning |
|------|---------|
| `200` | OK — request succeeded |
| `201` | Created — resource successfully created |
| `204` | No Content — resource deleted successfully |
| `400` | Bad Request — invalid or missing parameters |
| `401` | Unauthorized — missing or invalid token |
| `403` | Forbidden — insufficient permissions |
| `404` | Not Found — resource does not exist |
| `422` | Unprocessable Entity — validation error |
| `500` | Internal Server Error |

---

## Authentication Endpoints

### 1. Login
- **Method:** `POST`
- **Endpoint:** `/auth/login`
- **Description:** Authenticate a user with email and password. Returns a JWT access token used for all subsequent requests.
- **Authentication required:** No

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string | Yes | User's email address |
| `password` | string | Yes | User's password |

**Response `200 OK`:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**Error Responses:**
- `401 Unauthorized` — Incorrect email or password
- `422 Unprocessable Entity` — Missing or malformed fields

---

### 2. Sign Up
- **Method:** `POST`
- **Endpoint:** `/auth/signup`
- **Description:** Register a new user account. Returns the created user object.
- **Authentication required:** No

**Request Body:**
```json
{
  "email": "newuser@example.com",
  "password": "secret123",
  "full_name": "Jane Doe"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string | Yes | New user's email address |
| `password` | string | Yes | New user's password |
| `full_name` | string | Yes | New user's display name |

**Response `201 Created`:**
```json
{
  "id": 1,
  "email": "newuser@example.com",
  "full_name": "Jane Doe",
  "role": "employee",
  "is_active": true,
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Error Responses:**
- `400 Bad Request` — Email already registered
- `422 Unprocessable Entity` — Missing or malformed fields

---

## Task Management Endpoints

### 3. List Tasks
- **Method:** `GET`
- **Endpoint:** `/tasks/`
- **Description:** Retrieve a paginated list of tasks. Supports filtering by status, priority, owner, and creation date.
- **Authentication required:** Yes

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `skip` | integer | No | Number of records to skip (default: 0) |
| `limit` | integer | No | Maximum records to return (default: 100) |
| `status_filter` | string | No | Filter by status: `todo`, `in_progress`, `done`, `overdue` |
| `priority` | string | No | Filter by priority: `low`, `medium`, `high` |
| `owner_id` | integer | No | Filter by assigned user ID |
| `created_after` | string | No | ISO 8601 date — return tasks created after this date |
| `created_before` | string | No | ISO 8601 date — return tasks created before this date |

**Response `200 OK`:**
```json
[
  {
    "id": 1,
    "title": "Fix login bug",
    "description": "Users cannot log in with uppercase emails",
    "status": "in_progress",
    "priority": "high",
    "owner_id": 5,
    "created_at": "2024-01-15T08:00:00Z",
    "updated_at": "2024-01-15T09:30:00Z"
  }
]
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token

---

### 4. Get Task
- **Method:** `GET`
- **Endpoint:** `/tasks/{id}`
- **Description:** Retrieve a single task by its ID, including all associated attachments.
- **Authentication required:** Yes

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | Task ID |

**Response `200 OK`:**
```json
{
  "id": 1,
  "title": "Fix login bug",
  "description": "Users cannot log in with uppercase emails",
  "status": "in_progress",
  "priority": "high",
  "owner_id": 5,
  "created_at": "2024-01-15T08:00:00Z",
  "updated_at": "2024-01-15T09:30:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `404 Not Found` — Task does not exist

---

### 5. Create Task
- **Method:** `POST`
- **Endpoint:** `/tasks/`
- **Description:** Create a new task. `title` and `owner_id` are required; all other fields default to `todo` status and `medium` priority.
- **Authentication required:** Yes

**Request Body:**
```json
{
  "title": "Fix login bug",
  "owner_id": 5,
  "description": "Users cannot log in with uppercase emails",
  "status": "todo",
  "priority": "high"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | Yes | Task title |
| `owner_id` | integer | Yes | ID of the user assigned to the task |
| `description` | string | No | Detailed task description |
| `status` | string | No | Initial status: `todo` (default), `in_progress`, `done`, `overdue` |
| `priority` | string | No | Priority level: `low`, `medium` (default), `high` |

**Response `201 Created`:**
```json
{
  "id": 42,
  "title": "Fix login bug",
  "description": "Users cannot log in with uppercase emails",
  "status": "todo",
  "priority": "high",
  "owner_id": 5,
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T10:00:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `422 Unprocessable Entity` — Missing required fields or invalid values

---

### 6. Update Task
- **Method:** `PUT`
- **Endpoint:** `/tasks/{id}`
- **Description:** Replace all updatable fields of an existing task. Only provided fields are updated.
- **Authentication required:** Yes

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | Task ID |

**Request Body:**
```json
{
  "title": "Fix login bug (updated)",
  "description": "Also affects password reset flow",
  "status": "done",
  "priority": "high"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | No | Updated task title |
| `description` | string | No | Updated description |
| `status` | string | No | Updated status: `todo`, `in_progress`, `done`, `overdue` |
| `priority` | string | No | Updated priority: `low`, `medium`, `high` |

**Response `200 OK`:**
```json
{
  "id": 42,
  "title": "Fix login bug (updated)",
  "description": "Also affects password reset flow",
  "status": "done",
  "priority": "high",
  "owner_id": 5,
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T11:45:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `403 Forbidden` — Insufficient permissions to update this task
- `404 Not Found` — Task does not exist
- `422 Unprocessable Entity` — Invalid field values

---

### 7. Assign Task
- **Method:** `PATCH`
- **Endpoint:** `/tasks/{id}/assign`
- **Description:** Reassign a task to a different user without modifying other task fields.
- **Authentication required:** Yes (admin or manager role)

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | Task ID |

**Request Body:**
```json
{
  "owner_id": 7
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `owner_id` | integer | Yes | ID of the user to assign the task to |

**Response `200 OK`:**
```json
{
  "id": 42,
  "title": "Fix login bug",
  "description": "Users cannot log in with uppercase emails",
  "status": "in_progress",
  "priority": "high",
  "owner_id": 7,
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T12:00:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `403 Forbidden` — Only admins and managers can reassign tasks
- `404 Not Found` — Task or target user does not exist

---

### 8. Delete Task
- **Method:** `DELETE`
- **Endpoint:** `/tasks/{id}`
- **Description:** Permanently delete a task and all its associated attachments.
- **Authentication required:** Yes (admin role)

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | Task ID |

**Response `204 No Content`:** *(empty body)*

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `403 Forbidden` — Only admins can delete tasks
- `404 Not Found` — Task does not exist

---

## User Management Endpoints

### 9. List Users
- **Method:** `GET`
- **Endpoint:** `/users/`
- **Description:** Retrieve a paginated list of users. Supports filtering by role and email.
- **Authentication required:** Yes (admin or manager role)

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `skip` | integer | No | Number of records to skip (default: 0) |
| `limit` | integer | No | Maximum records to return (default: 100) |
| `role` | string | No | Filter by role: `admin`, `manager`, `employee` |
| `email` | string | No | Filter by email (partial match) |

**Response `200 OK`:**
```json
[
  {
    "id": 1,
    "email": "alice@example.com",
    "full_name": "Alice Smith",
    "role": "manager",
    "is_active": true,
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `403 Forbidden` — Insufficient permissions

---

### 10. Get User
- **Method:** `GET`
- **Endpoint:** `/users/{id}`
- **Description:** Retrieve a single user by their ID.
- **Authentication required:** Yes

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | User ID |

**Response `200 OK`:**
```json
{
  "id": 5,
  "email": "bob@example.com",
  "full_name": "Bob Jones",
  "role": "employee",
  "is_active": true,
  "created_at": "2024-01-10T08:00:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `404 Not Found` — User does not exist

---

### 11. Create User
- **Method:** `POST`
- **Endpoint:** `/users/`
- **Description:** Create a new user account. Used by admins to provision team members.
- **Authentication required:** Yes (admin role)

**Request Body:**
```json
{
  "email": "charlie@example.com",
  "password": "securepassword",
  "full_name": "Charlie Brown",
  "role": "employee",
  "is_active": true
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string | Yes | User's email address |
| `password` | string | Yes | Initial password |
| `full_name` | string | Yes | User's display name |
| `role` | string | Yes | Role: `admin`, `manager`, `employee` |
| `is_active` | boolean | No | Whether the account is active (default: `true`) |

**Response `201 Created`:**
```json
{
  "id": 10,
  "email": "charlie@example.com",
  "full_name": "Charlie Brown",
  "role": "employee",
  "is_active": true,
  "created_at": "2024-01-15T14:00:00Z"
}
```

**Error Responses:**
- `400 Bad Request` — Email already registered
- `401 Unauthorized` — Missing or invalid token
- `403 Forbidden` — Only admins can create users
- `422 Unprocessable Entity` — Missing required fields or invalid role

---

### 12. Update User
- **Method:** `PUT`
- **Endpoint:** `/users/{id}`
- **Description:** Update a user's profile or role. Only provided fields are changed.
- **Authentication required:** Yes (admin role)

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | User ID |

**Request Body:**
```json
{
  "full_name": "Charlie B.",
  "role": "manager",
  "is_active": true
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `full_name` | string | No | Updated display name |
| `email` | string | No | Updated email address |
| `role` | string | No | Updated role: `admin`, `manager`, `employee` |
| `is_active` | boolean | No | Whether the account is active |

**Response `200 OK`:**
```json
{
  "id": 10,
  "email": "charlie@example.com",
  "full_name": "Charlie B.",
  "role": "manager",
  "is_active": true,
  "created_at": "2024-01-15T14:00:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `403 Forbidden` — Only admins can update user profiles
- `404 Not Found` — User does not exist
- `422 Unprocessable Entity` — Invalid field values

---

### 13. Delete User
- **Method:** `DELETE`
- **Endpoint:** `/users/{id}`
- **Description:** Permanently delete a user account.
- **Authentication required:** Yes (admin role)

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | User ID |

**Response `204 No Content`:** *(empty body)*

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `403 Forbidden` — Only admins can delete users
- `404 Not Found` — User does not exist

---

## Attachment Endpoints

### 14. Upload Attachment
- **Method:** `POST`
- **Endpoint:** `/attachments/upload`
- **Description:** Upload a file and associate it with a task. The request must be sent as `multipart/form-data`. The client tracks upload progress via Dio's `onSendProgress` callback.
- **Authentication required:** Yes

**Request — `multipart/form-data`:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `task_id` | integer | Yes | ID of the task to attach the file to |
| `file` | file | Yes | The file to upload |

**Response `201 Created`:**
```json
{
  "id": 3,
  "filename": "screenshot.png",
  "url": "https://storage.taskflow.example.com/attachments/screenshot.png",
  "task_id": 42,
  "uploader_id": 5,
  "uploaded_at": "2024-01-15T10:30:00Z"
}
```

**Error Responses:**
- `400 Bad Request` — Missing `task_id` or `file`
- `401 Unauthorized` — Missing or invalid token
- `404 Not Found` — Task does not exist
- `422 Unprocessable Entity` — Unsupported file type or file too large

---

### 15. List Attachments
- **Method:** `GET`
- **Endpoint:** `/attachments/`
- **Description:** Retrieve a paginated list of attachments.
- **Authentication required:** Yes

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `skip` | integer | No | Number of records to skip (default: 0) |
| `limit` | integer | No | Maximum records to return (default: 100) |

**Response `200 OK`:**
```json
[
  {
    "id": 3,
    "filename": "screenshot.png",
    "url": "https://storage.taskflow.example.com/attachments/screenshot.png",
    "task_id": 42,
    "uploader_id": 5,
    "uploaded_at": "2024-01-15T10:30:00Z"
  }
]
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token

---

### 16. Get Attachment
- **Method:** `GET`
- **Endpoint:** `/attachments/{id}`
- **Description:** Retrieve metadata for a single attachment by its ID.
- **Authentication required:** Yes

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | Attachment ID |

**Response `200 OK`:**
```json
{
  "id": 3,
  "filename": "screenshot.png",
  "url": "https://storage.taskflow.example.com/attachments/screenshot.png",
  "task_id": 42,
  "uploader_id": 5,
  "uploaded_at": "2024-01-15T10:30:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `404 Not Found` — Attachment does not exist

---

### 17. Update Attachment
- **Method:** `PUT`
- **Endpoint:** `/attachments/{id}`
- **Description:** Update the filename metadata of an existing attachment.
- **Authentication required:** Yes

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | Attachment ID |

**Request Body:**
```json
{
  "filename": "renamed-screenshot.png"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `filename` | string | Yes | New filename for the attachment |

**Response `200 OK`:**
```json
{
  "id": 3,
  "filename": "renamed-screenshot.png",
  "url": "https://storage.taskflow.example.com/attachments/screenshot.png",
  "task_id": 42,
  "uploader_id": 5,
  "uploaded_at": "2024-01-15T10:30:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `404 Not Found` — Attachment does not exist
- `422 Unprocessable Entity` — Missing or invalid `filename`

---

### 18. Delete Attachment
- **Method:** `DELETE`
- **Endpoint:** `/attachments/{id}`
- **Description:** Permanently delete an attachment record and its associated file.
- **Authentication required:** Yes

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | Attachment ID |

**Response `204 No Content`:** *(empty body)*

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `403 Forbidden` — Only the uploader or an admin can delete an attachment
- `404 Not Found` — Attachment does not exist

---

## Dashboard Endpoints

### 19. Get Summary
- **Method:** `GET`
- **Endpoint:** `/dashboard/summary`
- **Description:** Retrieve aggregate task counts across all statuses.
- **Authentication required:** Yes

**Response `200 OK`:**
```json
{
  "total": 50,
  "todo": 20,
  "in_progress": 15,
  "done": 10,
  "overdue": 5
}
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token

---

### 20. Get Completion Rate
- **Method:** `GET`
- **Endpoint:** `/dashboard/completion-rate`
- **Description:** Retrieve the overall task completion percentage.
- **Authentication required:** Yes

**Response `200 OK`:**
```json
{
  "total_tasks": 50,
  "completed_tasks": 10,
  "completion_percentage": 20.0
}
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token

---

### 21. Get Tasks by Priority
- **Method:** `GET`
- **Endpoint:** `/dashboard/by-priority`
- **Description:** Retrieve a breakdown of task counts grouped by priority level.
- **Authentication required:** Yes

**Response `200 OK`:**
```json
{
  "low": 10,
  "medium": 25,
  "high": 15
}
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token

---

### 22. Get Tasks by User
- **Method:** `GET`
- **Endpoint:** `/dashboard/by-user`
- **Description:** Retrieve task counts grouped by assigned user, useful for workload distribution charts.
- **Authentication required:** Yes (admin or manager role)

**Response `200 OK`:**
```json
[
  {
    "user_id": 5,
    "email": "bob@example.com",
    "full_name": "Bob Jones",
    "task_count": 8
  },
  {
    "user_id": 7,
    "email": "diana@example.com",
    "full_name": "Diana Prince",
    "task_count": 12
  }
]
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `403 Forbidden` — Insufficient permissions

---

### 23. Get Tasks by Date Range
- **Method:** `GET`
- **Endpoint:** `/dashboard/date-range`
- **Description:** Retrieve task statistics (total and completed) within an optional date range.
- **Authentication required:** Yes

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `start_date` | string | No | ISO 8601 date (e.g. `2024-01-01`) — start of date range |
| `end_date` | string | No | ISO 8601 date (e.g. `2024-01-31`) — end of date range |

**Response `200 OK`:**
```json
{
  "start_date": "2024-01-01",
  "end_date": "2024-01-31",
  "total": 30,
  "completed": 18
}
```

**Error Responses:**
- `401 Unauthorized` — Missing or invalid token
- `422 Unprocessable Entity` — Invalid date format

---

## Endpoint Summary

| # | Method | Endpoint | Description | Auth Required |
|---|--------|----------|-------------|---------------|
| 1 | POST | `/auth/login` | Authenticate user, get JWT | No |
| 2 | POST | `/auth/signup` | Register new user | No |
| 3 | GET | `/tasks/` | List tasks (with filters) | Yes |
| 4 | GET | `/tasks/{id}` | Get single task | Yes |
| 5 | POST | `/tasks/` | Create task | Yes |
| 6 | PUT | `/tasks/{id}` | Update task | Yes |
| 7 | PATCH | `/tasks/{id}/assign` | Reassign task to user | Yes (admin/manager) |
| 8 | DELETE | `/tasks/{id}` | Delete task | Yes (admin) |
| 9 | GET | `/users/` | List users (with filters) | Yes (admin/manager) |
| 10 | GET | `/users/{id}` | Get single user | Yes |
| 11 | POST | `/users/` | Create user | Yes (admin) |
| 12 | PUT | `/users/{id}` | Update user | Yes (admin) |
| 13 | DELETE | `/users/{id}` | Delete user | Yes (admin) |
| 14 | POST | `/attachments/upload` | Upload file attachment | Yes |
| 15 | GET | `/attachments/` | List attachments | Yes |
| 16 | GET | `/attachments/{id}` | Get attachment metadata | Yes |
| 17 | PUT | `/attachments/{id}` | Update attachment filename | Yes |
| 18 | DELETE | `/attachments/{id}` | Delete attachment | Yes |
| 19 | GET | `/dashboard/summary` | Task count by status | Yes |
| 20 | GET | `/dashboard/completion-rate` | Overall completion percentage | Yes |
| 21 | GET | `/dashboard/by-priority` | Task count by priority | Yes |
| 22 | GET | `/dashboard/by-user` | Task count per user | Yes (admin/manager) |
| 23 | GET | `/dashboard/date-range` | Task stats for date range | Yes |

## Conclusion
Integrating with the Taskflow API enables seamless interaction with the mobile application, providing users with powerful tools to manage their tasks efficiently. All authenticated requests must include a valid JWT bearer token. A 401 response from any endpoint will cause the app to force-logout and redirect the user to the login screen.
