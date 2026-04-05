# Low-Level Design (LLD) — TaskFlow Mobile

## 1. Module Dependency Graph

```
main.dart
 ├── core/api_client.dart         (Dio singleton)
 ├── cubits/auth/auth_cubit.dart  (global state)
 ├── cubits/auth/auth_state.dart
 └── routes/app_router.dart
      ├── cubits/task_list/       (per-route providers)
      ├── cubits/task_detail/
      ├── cubits/task_form/
      ├── cubits/user_list/
      ├── cubits/user_form/
      ├── cubits/dashboard/
      ├── views/auth/login_view.dart
      ├── views/auth/signup_view.dart
      ├── views/tasks/task_list_view.dart
      ├── views/tasks/task_detail_view.dart
      ├── views/tasks/task_create_view.dart
      ├── views/tasks/task_edit_view.dart
      ├── views/users/user_list_view.dart
      ├── views/users/user_create_view.dart
      ├── views/users/user_edit_view.dart
      ├── views/dashboard/dashboard_view.dart
      └── views/shell/{admin,manager,employee}_shell.dart

core/api_client.dart       → core/constants.dart, core/secure_storage.dart
core/secure_storage.dart   → core/constants.dart, flutter_secure_storage
core/error_handler.dart    → dio (DioException)
core/constants.dart        → dart:io (Platform)

services/auth_service.dart       → core/api_client.dart, models/login_response.dart, models/user.dart
services/task_service.dart       → core/api_client.dart, models/task.dart
services/user_service.dart       → core/api_client.dart, models/user.dart
services/attachment_service.dart → core/api_client.dart, models/attachment.dart
services/dashboard_service.dart  → core/api_client.dart, models/dashboard.dart

cubits/auth/auth_cubit.dart         → services/auth_service.dart, services/user_service.dart, core/secure_storage.dart, core/error_handler.dart
cubits/task_list/task_list_cubit.dart → services/task_service.dart, core/error_handler.dart
cubits/task_detail/task_detail_cubit.dart → services/task_service.dart, services/attachment_service.dart, services/user_service.dart, core/error_handler.dart
cubits/task_form/task_form_cubit.dart → services/task_service.dart, core/error_handler.dart
cubits/user_list/user_list_cubit.dart → services/user_service.dart, core/error_handler.dart
cubits/user_form/user_form_cubit.dart → services/user_service.dart, core/error_handler.dart
cubits/dashboard/dashboard_cubit.dart → services/dashboard_service.dart, core/error_handler.dart

models/user.dart            (standalone, equatable)
models/task.dart            (standalone, equatable)
models/attachment.dart      (standalone, equatable)
models/login_response.dart  (standalone, equatable)
models/dashboard.dart       (standalone, equatable)
```

---

## 2. Model Definitions

### 2.1 User Model (`models/user.dart`)
```dart
enum UserRole { admin, manager, employee }

class User extends Equatable {
  final int id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
}
```

**JSON mapping:**
| Dart Field | JSON Key | Type |
|------------|----------|------|
| `id` | `id` | `int` |
| `email` | `email` | `String` |
| `fullName` | `full_name` | `String` |
| `role` | `role` | `String` → `UserRole` enum |
| `isActive` | `is_active` | `bool` |
| `createdAt` | `created_at` | `String` → `DateTime.parse()` |

**Helper:** `userRoleFromString(String)` → `UserRole` (defaults to `employee`)

### 2.2 Task Model (`models/task.dart`)
```dart
enum TaskStatus { todo, in_progress, done, overdue }
enum TaskPriority { low, medium, high }

class Task extends Equatable {
  final int id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final int ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<TaskStatus> get validTransitions;  // computed property
}
```

**JSON mapping:**
| Dart Field | JSON Key | Type |
|------------|----------|------|
| `id` | `id` | `int` |
| `title` | `title` | `String` |
| `description` | `description` | `String?` |
| `status` | `status` | `String` → `TaskStatus` |
| `priority` | `priority` | `String` → `TaskPriority` |
| `ownerId` | `owner_id` | `int` |
| `createdAt` | `created_at` | `String` → `DateTime` |
| `updatedAt` | `updated_at` | `String` → `DateTime` |

**Helpers:** `taskStatusFromString(String)`, `taskPriorityFromString(String)`

### 2.3 Task Status State Machine (Client-Side)
```
            ┌──────────┐
            │   todo   │
            └────┬─────┘
                 │
                 ▼
            ┌──────────┐
     ┌──────│in_progress│──────┐
     │      └──────────┘      │
     │                        │
     ▼                        ▼
┌──────────┐           ┌──────────┐
│   todo   │           │   done   │
│ (revert) │           │(terminal)│
└──────────┘           └──────────┘

┌──────────┐
│ overdue  │───────→ in_progress
│          │
└──────────┘
```

| From | `validTransitions` |
|------|-------------------|
| `todo` | `[in_progress]` |
| `in_progress` | `[done, todo]` |
| `done` | `[]` (terminal) |
| `overdue` | `[in_progress]` |

### 2.4 Attachment Model (`models/attachment.dart`)
```dart
class Attachment extends Equatable {
  final int id;
  final String filename;
  final String url;
  final int taskId;
  final int uploaderId;
  final DateTime uploadedAt;
}
```

| Dart Field | JSON Key | Type |
|------------|----------|------|
| `id` | `id` | `int` |
| `filename` | `filename` | `String` |
| `url` | `url` | `String` |
| `taskId` | `task_id` | `int` |
| `uploaderId` | `uploader_id` | `int` |
| `uploadedAt` | `uploaded_at` | `String` → `DateTime` |

### 2.5 LoginResponse Model (`models/login_response.dart`)
```dart
class LoginResponse extends Equatable {
  final String accessToken;   // ← "access_token"
  final String tokenType;     // ← "token_type"
}
```

### 2.6 Dashboard Models (`models/dashboard.dart`)

| Class | Fields | JSON Source |
|-------|--------|-------------|
| `DashboardSummary` | total, todo, inProgress(`in_progress`), done, overdue | `/dashboard/summary` |
| `CompletionRate` | totalTasks(`total_tasks`), completedTasks(`completed_tasks`), completionPercentage(`completion_percentage`) | `/dashboard/completion-rate` |
| `PriorityBreakdown` | low, medium, high | `/dashboard/by-priority` |
| `UserTaskCount` | userId(`user_id`), email, fullName(`full_name`), taskCount(`task_count`) | `/dashboard/by-user` |
| `DateRangeStats` | startDate(`start_date`), endDate(`end_date`), total, completed | `/dashboard/date-range` |

---

## 3. Core Layer Specifications

### 3.1 ApiClient (`core/api_client.dart`)
```
Pattern:     Singleton (factory constructor)
HTTP Client: Dio with BaseOptions

BaseOptions:
  baseUrl:        Platform.isAndroid ? "http://10.0.2.2:8000" : "http://localhost:8000"
  connectTimeout: 15s
  receiveTimeout: 15s
  sendTimeout:    30s
  headers:        {"Content-Type": "application/json"}

Interceptors:
  onRequest:  Read token from SecureStorage → attach "Authorization: Bearer {token}"
  onError:    If 401 → SecureStorage.clearAll() → onForceLogout?.call()

Public:
  Dio dio                           // exposed for services
  void Function()? onForceLogout    // set by main.dart → AuthCubit.logout()
```

### 3.2 SecureStorage (`core/secure_storage.dart`)
```
Backend:  FlutterSecureStorage (Keychain on iOS, EncryptedSharedPreferences on Android)
Keys:     "access_token" (AppConstants.tokenKey)
          "user_id"      (AppConstants.userIdKey)

Static Methods:
  setToken(String token)     → write tokenKey
  getToken() → String?      → read tokenKey
  setUserId(String userId)   → write userIdKey
  getUserId() → String?     → read userIdKey
  clearAll()                 → deleteAll
```

### 3.3 ErrorHandler (`core/error_handler.dart`)
```
Static Methods:
  getMessage(dynamic error) → String

DioException Mapping:
  connectionTimeout / sendTimeout / receiveTimeout → "Connection timed out…"
  connectionError                                  → "No internet connection…"
  cancel                                           → "Request was cancelled."
  badResponse                                      → _handleStatusCode()

HTTP Status Code Mapping:
  400 → detail ?? "Bad request."
  401 → "Session expired. Please log in again."
  403 → "You don't have permission…"
  404 → detail ?? "Resource not found."
  409 → detail ?? "Conflict: resource already exists."
  413 → "File is too large. Maximum size is 10 MB."
  422 → Extract first validation error msg, or detail, or "Validation error."
  429 → "Too many attempts. Please try again later."
  500 → "Server error. Please try again later."
  *   → detail ?? "Something went wrong."
```

### 3.4 Constants (`core/constants.dart`)
```dart
class AppConstants {
  static String get baseUrl     // Platform-aware: Android emulator vs localhost
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout    = Duration(seconds: 30);
  static const int maxFileSize         = 10 * 1024 * 1024;  // 10 MB
  static const String tokenKey        = 'access_token';
  static const String userIdKey       = 'user_id';
}
```

---

## 4. Service Layer Specifications

### 4.1 AuthService (`services/auth_service.dart`)
```dart
class AuthService {
  final Dio _dio = ApiClient().dio;

  Future<LoginResponse> login(String email, String password)
  // POST /auth/login  body: {email, password}  → LoginResponse.fromJson()

  Future<User> signup(String email, String password, String fullName)
  // POST /auth/signup body: {email, password, full_name}  → User.fromJson()
}
```

### 4.2 TaskService (`services/task_service.dart`)
```dart
class TaskService {
  final Dio _dio = ApiClient().dio;

  Future<List<Task>> getTasks({skip, limit, statusFilter, priority, ownerId, createdAfter, createdBefore})
  // GET /tasks/  query: {skip, limit, status_filter, priority, owner_id, created_after, created_before}

  Future<Task> getTask(int id)
  // GET /tasks/{id}

  Future<Task> createTask({title, description?, status?, priority?, ownerId})
  // POST /tasks/  body: {title, owner_id, description?, status?, priority?}

  Future<Task> updateTask(int id, Map<String, dynamic> data)
  // PUT /tasks/{id}  body: data

  Future<Task> assignTask(int taskId, int ownerId)
  // PATCH /tasks/{taskId}/assign  body: {owner_id: ownerId}

  Future<void> deleteTask(int id)
  // DELETE /tasks/{id}
}
```

### 4.3 UserService (`services/user_service.dart`)
```dart
class UserService {
  final Dio _dio = ApiClient().dio;

  Future<List<User>> getUsers({skip, limit, role?, email?})
  // GET /users/  query: {skip, limit, role?, email?}

  Future<User> getUser(int id)
  // GET /users/{id}

  Future<User> createUser({email, password, fullName, role, isActive})
  // POST /users/  body: {email, password, full_name, role, is_active}

  Future<User> updateUser(int id, Map<String, dynamic> data)
  // PUT /users/{id}  body: data

  Future<void> deleteUser(int id)
  // DELETE /users/{id}
}
```

### 4.4 AttachmentService (`services/attachment_service.dart`)
```dart
class AttachmentService {
  final Dio _dio = ApiClient().dio;

  Future<Attachment> uploadFile(String filePath, String fileName, int taskId, {onSendProgress?})
  // POST /attachments/upload  multipart: {task_id, file: MultipartFile}

  Future<List<Attachment>> getAttachments({skip, limit})
  // GET /attachments/  query: {skip, limit}

  Future<Attachment> getAttachment(int id)
  // GET /attachments/{id}

  Future<Attachment> updateAttachment(int id, String filename)
  // PUT /attachments/{id}  body: {filename}

  Future<void> deleteAttachment(int id)
  // DELETE /attachments/{id}
}
```

### 4.5 DashboardService (`services/dashboard_service.dart`)
```dart
class DashboardService {
  final Dio _dio = ApiClient().dio;

  Future<DashboardSummary> getSummary()
  // GET /dashboard/summary

  Future<CompletionRate> getCompletionRate()
  // GET /dashboard/completion-rate

  Future<PriorityBreakdown> getByPriority()
  // GET /dashboard/by-priority

  Future<List<UserTaskCount>> getByUser()
  // GET /dashboard/by-user

  Future<DateRangeStats> getDateRange({startDate?, endDate?})
  // GET /dashboard/date-range  query: {start_date?, end_date?}
}
```

---

## 5. Cubit State Machine Specifications

### 5.1 AuthCubit
```
                    ┌─────────────┐
           app start│ AuthInitial │
                    └──────┬──────┘
                           │ restoreSession()
                    ┌──────▼──────┐
                    │ AuthLoading │
                    └──────┬──────┘
                ┌──────────┼──────────┐
         token found    no token    error
                │          │          │
         ┌──────▼──────┐ ┌▼────────────────┐
         │Authenticated│ │ Unauthenticated  │
         │(user, token)│ └─────────────────┘
         └──────┬──────┘         ▲
                │ logout()       │
                └────────────────┘
```

**Methods:**
```dart
login(String email, String password)
  1. emit(AuthLoading)
  2. AuthService.login(email, password) → LoginResponse
  3. SecureStorage.setToken(token)
  4. _extractUserIdFromToken(token) → userId (decode JWT base64 payload → sub)
  5. SecureStorage.setUserId(userId)
  6. UserService.getUser(userId) → User
  7. emit(Authenticated(user, token))
  catch → emit(AuthError(ErrorHandler.getMessage(e)))

signup(String email, String password, String fullName)
  1. emit(AuthLoading)
  2. AuthService.signup(email, password, fullName)
  3. login(email, password)  // auto-login
  catch → emit(AuthError(...))

restoreSession()
  1. SecureStorage.getToken() → token?
  2. SecureStorage.getUserId() → userIdStr?
  3. if null → emit(Unauthenticated)
  4. UserService.getUser(int.parse(userIdStr)) → User
  5. emit(Authenticated(user, token))
  catch → SecureStorage.clearAll() → emit(Unauthenticated)

logout()
  1. SecureStorage.clearAll()
  2. emit(Unauthenticated)

_extractUserIdFromToken(String token) → int
  1. Split token by '.'
  2. base64Url decode parts[1]
  3. JSON decode → map['sub'] → int.parse()
```

### 5.2 TaskListCubit
```
┌────────────────┐  fetchTasks()  ┌─────────────────┐
│TaskListInitial │──────────────→│TaskListLoading  │
└────────────────┘               └────────┬─────────┘
                                    ┌─────┴──────┐
                                success        error
                                    │              │
                           ┌────────▼───────┐ ┌───▼──────────┐
                           │TaskListLoaded  │ │TaskListError  │
                           │(List<Task>)    │ │(String msg)   │
                           └────────────────┘ └───────────────┘
```

**Method:**
```dart
fetchTasks({statusFilter?, priority?, ownerId?, createdAfter?, createdBefore?})
  1. emit(TaskListLoading)
  2. TaskService.getTasks(filters...) → List<Task>
  3. emit(TaskListLoaded(tasks))
  catch → emit(TaskListError(ErrorHandler.getMessage(e)))
```

### 5.3 TaskDetailCubit
```
┌──────────────────┐  loadTask()  ┌───────────────────┐
│TaskDetailInitial │─────────────→│TaskDetailLoading  │
└──────────────────┘              └─────────┬──────────┘
                                     ┌──────┴───────┐
                                  success         error
                                     │                │
                            ┌────────▼────────┐  ┌───▼──────────────┐
                            │TaskDetailLoaded │  │TaskDetailError   │
                            │(task,attachments│  │(String msg)      │
                            │ owner?)         │  └──────────────────┘
                            └────────┬────────┘
                                     │ uploadFile()
                            ┌────────▼─────────────┐
                            │TaskDetailUploading   │
                            │(task,attachments,    │
                            │ progress: 0 → 1.0)  │
                            └────────┬─────────────┘
                                     │ complete
                            ┌────────▼────────┐
                            │TaskDetailLoaded │
                            │(+new attachment)│
                            └─────────────────┘
```

**Methods:**
```dart
loadTask(int taskId)
  1. emit(TaskDetailLoading)
  2. TaskService.getTask(taskId) → Task
  3. AttachmentService.getAttachments() → filter by taskId
  4. UserService.getUser(task.ownerId) → User (owner)
  5. emit(TaskDetailLoaded(task, taskAttachments, owner))

updateStatus(int taskId, String newStatus)
  1. TaskService.updateTask(taskId, {status: newStatus}) → Task
  2. Preserve current attachments
  3. emit(TaskDetailLoaded(updatedTask, attachments))

uploadFile(int taskId, String filePath, String fileName)
  1. emit(TaskDetailUploading(task, attachments, progress: 0))
  2. AttachmentService.uploadFile(filePath, fileName, taskId,
       onSendProgress: (sent, total) → emit(Uploading progress: sent/total))
  3. Append new attachment to list
  4. emit(TaskDetailLoaded(task, updatedAttachments))
```

### 5.4 TaskFormCubit
```
┌────────────────┐  createTask() / updateTask()  ┌─────────────────┐
│TaskFormInitial │──────────────────────────────→│TaskFormLoading  │
└────────────────┘                               └────────┬─────────┘
                                                    ┌─────┴──────┐
                                                 success       error
                                                    │              │
                                            ┌───────▼────────┐ ┌──▼──────────────┐
                                            │TaskFormSuccess │ │TaskFormError    │
                                            └────────────────┘ │(String msg)     │
                                                               └─────────────────┘
```

**Methods:**
```dart
createTask({title, description?, priority?, ownerId})
  1. emit(TaskFormLoading)
  2. TaskService.createTask(...) → Task
  3. emit(TaskFormSuccess)

updateTask(int taskId, Map<String, dynamic> data)
  1. emit(TaskFormLoading)
  2. TaskService.updateTask(taskId, data)
  3. emit(TaskFormSuccess)

assignTask(int taskId, int ownerId)
  1. emit(TaskFormLoading)
  2. TaskService.assignTask(taskId, ownerId)
  3. emit(TaskFormSuccess)
```

### 5.5 UserListCubit
```dart
fetchUsers({role?, email?})
  1. emit(UserListLoading)
  2. UserService.getUsers(role, email) → List<User>
  3. emit(UserListLoaded(users))

deleteUser(int userId)
  1. UserService.deleteUser(userId)
  2. fetchUsers()  // refresh list
```

### 5.6 UserFormCubit
```dart
createUser({email, password, fullName, role, isActive})
  1. emit(UserFormLoading)
  2. UserService.createUser(...)
  3. emit(UserFormSuccess)

updateUser(int userId, Map<String, dynamic> data)
  1. emit(UserFormLoading)
  2. UserService.updateUser(userId, data)
  3. emit(UserFormSuccess)
```

### 5.7 DashboardCubit
```dart
fetchAll(UserRole role)
  1. emit(DashboardLoading)
  2. Future.wait([getSummary(), getCompletionRate(), getByPriority()])
  3. If admin/manager → getByUser() → userCounts
  4. emit(DashboardLoaded(summary, completionRate, priorityBreakdown, userCounts?))

fetchDateRange(UserRole role, {startDate?, endDate?})
  1. DashboardService.getDateRange(startDate, endDate) → DateRangeStats
  2. Merge with current DashboardLoaded state
  3. emit(DashboardLoaded(..., dateRangeStats))
```

---

## 6. Routing Specifications

### 6.1 GoRouter Configuration
```dart
GoRouter createRouter(AuthCubit authCubit) → GoRouter

refreshListenable: _GoRouterRefreshStream(authCubit.stream)
  → Converts BLoC Stream to ChangeNotifier for GoRouter

redirect: (context, state) →
  if (!authenticated && !authRoute) → "/login"
  if (authenticated && authRoute) → "/"
  else → null (no redirect)
```

### 6.2 Route Table

| Path | View Widget | BlocProvider | Guard |
|------|-------------|-------------|-------|
| `/login` | `LoginView` | — (uses global AuthCubit) | Public |
| `/signup` | `SignupView` | — (uses global AuthCubit) | Public |
| `/` | `TaskListView` | `TaskListCubit` | Authenticated |
| `/tasks/create` | `TaskCreateView` | `TaskFormCubit` | Authenticated |
| `/tasks/:id` | `TaskDetailView(taskId)` | `TaskDetailCubit` | Authenticated |
| `/tasks/:id/edit` | `TaskEditView(taskId)` | `TaskFormCubit` | Authenticated |
| `/users` | `UserListView` | `UserListCubit` | Authenticated |
| `/users/create` | `UserCreateView` | `UserFormCubit` | Authenticated |
| `/users/:id/edit` | `UserEditView(userId)` | `UserFormCubit` | Authenticated |
| `/dashboard` | `DashboardView` | `DashboardCubit` | Authenticated |

### 6.3 StatefulShellRoute Branches
```
Branch 0: Tasks     → path: "/"         (root)
Branch 1: Users     → path: "/users"
Branch 2: Dashboard → path: "/dashboard"
```

### 6.4 _GoRouterRefreshStream
```dart
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
```
Bridges BLoC's `Stream<AuthState>` to GoRouter's `Listenable` interface for reactive navigation.

---

## 7. View Layer Specifications

### 7.1 LoginView (`views/auth/login_view.dart`)
```
Type:       StatefulWidget
State:      _formKey (GlobalKey<FormState>), _emailController, _passwordController, _obscurePassword
Cubit:      AuthCubit (from context)
Listeners:  BlocListener<AuthCubit, AuthState>
              Authenticated → context.go('/')
              AuthError → SnackBar (red)
UI:         Form with email (EmailField + validator) + password (obscured) + Login button
            TextButton → context.go('/signup')
Submit:     validate form → authCubit.login(email, password)
```

### 7.2 SignupView (`views/auth/signup_view.dart`)
```
Type:       StatefulWidget
State:      _formKey, _fullNameController, _emailController, _passwordController, _confirmPasswordController
Cubit:      AuthCubit (from context)
Validation: fullName required, email format, password ≥ 8 chars, confirm == password
Submit:     authCubit.signup(email, password, fullName) → auto-login
Navigation: TextButton → context.go('/login')
```

### 7.3 TaskListView (`views/tasks/task_list_view.dart`)
```
Type:       StatefulWidget
State:      _selectedStatus, _selectedPriority filter state
Cubit:      TaskListCubit (from context)
Lifecycle:  initState → _loadTasks() based on user role (employee filters by ownerId)
UI:         - AppBar with title
            - Filter chips (status: all/todo/in_progress/done/overdue, priority: all/low/medium/high)
            - RefreshIndicator wrapping ListView of task cards
            - Each card shows: title, status badge (color-coded), priority tag, owner info
            - FloatingActionButton → context.go('/tasks/create')
BlocBuilder: TaskListLoading → CircularProgressIndicator
             TaskListLoaded → ListView.builder
             TaskListError → error text + retry button
```

### 7.4 TaskDetailView (`views/tasks/task_detail_view.dart`)
```
Constructor: TaskDetailView({required int taskId})
Cubit:       TaskDetailCubit (from context)
Lifecycle:   initState → cubit.loadTask(taskId)
UI Sections:
  1. Header: title, description
  2. Info row: status badge, priority tag, owner name
  3. Status update: Wrap of ActionChips for each validTransition → cubit.updateStatus()
  4. Attachments list: ListTile per attachment (filename, upload date)
  5. Upload button: file_picker → cubit.uploadFile()
  6. Edit button (admin/manager) → context.go('/tasks/$taskId/edit')
  7. Delete button (admin only) → TaskService.deleteTask() → context.go('/')
States:
  TaskDetailLoading → shimmer/spinner
  TaskDetailLoaded → full detail layout
  TaskDetailUploading → LinearProgressIndicator(value: progress)
  TaskDetailError → error message
```

### 7.5 TaskCreateView (`views/tasks/task_create_view.dart`)
```
Type:       StatefulWidget
Cubit:      TaskFormCubit (from context)
Fields:     title (required), description, priority dropdown, assignee dropdown
Logic:      Employee → ownerId locked to self
            Admin/Manager → loads user list for assignee dropdown
Submit:     cubit.createTask(title, description, priority, ownerId)
Listener:   TaskFormSuccess → context.pop()
            TaskFormError → SnackBar
```

### 7.6 TaskEditView (`views/tasks/task_edit_view.dart`)
```
Constructor: TaskEditView({required int taskId})
Cubit:       TaskFormCubit (from context)
Lifecycle:   Loads current task data to pre-fill form
Fields:      title, description, status (validTransitions only), priority, assignee
Submit:      cubit.updateTask(taskId, data)
```

### 7.7 UserListView (`views/users/user_list_view.dart`)
```
Type:       StatefulWidget
Cubit:      UserListCubit (from context)
UI:         - AppBar with title
            - Search field (admin: by email)
            - RefreshIndicator + ListView of user cards
            - Each card: full name, email, role badge, active indicator
            - PopupMenuButton (admin): Edit / Delete
            - FAB (admin only): → context.go('/users/create')
Manager:    Read-only team view (no FAB, no edit/delete)
```

### 7.8 UserCreateView (`views/users/user_create_view.dart`)
```
Type:       StatefulWidget
Cubit:      UserFormCubit (from context)
Fields:     fullName, email, password (≥ 8), role dropdown (admin/manager/employee)
Submit:     cubit.createUser(email, password, fullName, role)
Listener:   UserFormSuccess → context.pop()
```

### 7.9 UserEditView (`views/users/user_edit_view.dart`)
```
Constructor: UserEditView({required int userId})
Cubit:       UserFormCubit (from context)
Fields:      fullName, password (optional change), role dropdown, is_active toggle
Submit:      cubit.updateUser(userId, data)
```

### 7.10 DashboardView (`views/dashboard/dashboard_view.dart`)
```
Type:       StatefulWidget
Cubit:      DashboardCubit (from context)
Lifecycle:  initState → cubit.fetchAll(authState.user.role)
UI Sections:
  1. Summary cards: Column of metric cards (total, todo, in_progress, done, overdue)
  2. Completion rate: PieChart (fl_chart) — done vs remaining
  3. Priority breakdown: BarChart (fl_chart) — low/medium/high
  4. Team overview (admin/manager): ListView of UserTaskCount cards
  5. Date range picker: two DatePicker buttons + fetch → stats card
```

### 7.11 Shell Views
```
AdminShell(navigationShell):
  Scaffold(
    body: navigationShell,
    bottomNavigationBar: NavigationBar(
      destinations: [Tasks, Users, Dashboard],
      selectedIndex: navigationShell.currentIndex
    ),
    appBar: AppBar(actions: [Logout IconButton])
  )

ManagerShell(navigationShell):
  Same structure, destinations: [Tasks, Team, Dashboard]

EmployeeShell(navigationShell):
  Same structure, destinations: [My Tasks, Dashboard]
  (Users branch hidden — 2 tabs only)
```

---

## 8. Dependency Injection Pattern

All cubits use **constructor injection** with optional parameters defaulting to concrete service instances:

```dart
class TaskListCubit extends Cubit<TaskListState> {
  final TaskService _taskService;

  TaskListCubit({TaskService? taskService})
      : _taskService = taskService ?? TaskService(),
        super(TaskListInitial());
}
```

This allows:
- **Production**: `TaskListCubit()` → uses real service
- **Testing**: `TaskListCubit(taskService: MockTaskService())` → injected mock

All services use `ApiClient().dio` (singleton) — no injection needed at service level.

---

## 9. Error Handling Strategy

```
┌──────────────────┐
│  Backend Error   │
│  (HTTP Response) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     401 only
│  Dio Interceptor │──────────────→ SecureStorage.clearAll()
│  (ApiClient)     │                onForceLogout() → Unauthenticated
└────────┬─────────┘
         │ DioException
         ▼
┌──────────────────┐
│  Cubit catch(e)  │
│                  │
│  ErrorHandler    │
│  .getMessage(e)  │
│  → String        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  emit(ErrorState │
│  (message))      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  BlocListener    │
│  → SnackBar      │
│  (red background)│
└──────────────────┘
```

---

## 10. File Upload Pipeline

```dart
// 1. User picks file via file_picker
final result = await FilePicker.platform.pickFiles();
final filePath = result.files.single.path;
final fileName = result.files.single.name;

// 2. Cubit initiates upload
TaskDetailCubit.uploadFile(taskId, filePath, fileName);

// 3. Creates multipart form data
FormData.fromMap({
  'task_id': taskId,
  'file': await MultipartFile.fromFile(filePath, filename: fileName),
});

// 4. POST with progress tracking
_dio.post('/attachments/upload',
  data: formData,
  onSendProgress: (sent, total) → emit(Uploading(progress: sent/total))
);

// 5. Server returns Attachment JSON → appended to state
```

**Constraints:**
- Max file size: 10 MB (server-enforced, client constant)
- Upload timeout: 30s (`sendTimeout`)
- Progress: real-time via Dio `onSendProgress` callback

---

## 11. JWT Token Handling

### 11.1 Token Lifecycle
```
Login         → receive access_token
              → store in SecureStorage
              → decode payload to extract user ID
              → store user ID in SecureStorage

Every Request → Dio interceptor reads token from SecureStorage
              → attaches "Authorization: Bearer {token}" header

401 Response  → Dio interceptor clears SecureStorage
              → calls onForceLogout → AuthCubit.logout()
              → GoRouter redirects to /login

App Restart   → restoreSession() reads token + userId from SecureStorage
              → fetches user profile to validate
              → if valid → Authenticated; else → clear + Unauthenticated
```

### 11.2 Client-Side JWT Decode
```dart
_extractUserIdFromToken(String token) → int
  1. token.split('.') → [header, payload, signature]
  2. base64Url.normalize(payload) → padded base64
  3. base64Url.decode → bytes → utf8.decode → JSON string
  4. json.decode → Map → map['sub'] → int.parse()
```
**Note:** Client does NOT verify JWT signature — the server validates tokens on every request.

---

## 12. Package Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_bloc` | ^9.1.1 | Cubit/BLoC state management |
| `equatable` | ^2.0.8 | Value equality for states and models |
| `go_router` | ^17.0.0 | Declarative routing with auth guards |
| `dio` | ^5.9.2 | HTTP client with interceptors |
| `flutter_secure_storage` | ^10.0.0 | Encrypted credential storage |
| `fl_chart` | >=0.66.0 <1.1.0 | Pie charts, bar charts for dashboard |
| `file_picker` | ^11.0.1 | Native file picker for attachments |
| `intl` | ^0.20.2 | Date formatting |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

**Dev Dependencies:**
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | sdk | Widget testing framework |
| `flutter_lints` | ^5.0.0 | Lint rules |
| `bloc_test` | ^10.0.0 | Cubit/BLoC testing utilities |
| `mockito` | ^5.5.0 | Mock generation for unit tests |
| `build_runner` | ^2.7.1 | Code generation (mockito mocks) |
