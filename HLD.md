# High-Level Design (HLD) — TaskFlow Mobile

## 1. System Overview

TaskFlow Mobile is a cross-platform Flutter application for enterprise task management. It provides authentication, role-based navigation, task lifecycle management, file attachments with upload progress, and analytics dashboards — consuming the TaskFlow REST API backend.

**Tech Stack**: Flutter 3.7+ · Dart · BLoC/Cubit · GoRouter · Dio · FlutterSecureStorage · fl_chart · file_picker · Equatable

---

## 2. System Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                       TaskFlow Mobile App                           │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │                      Presentation Layer                      │    │
│  │                                                              │    │
│  │  ┌─────────────┐  ┌───────────────┐  ┌──────────────────┐  │    │
│  │  │   Views      │  │   Widgets     │  │   Shell Views    │  │    │
│  │  │  (Screens)   │  │  (Reusable)   │  │ (Role-based Nav) │  │    │
│  │  └──────┬───────┘  └───────┬───────┘  └────────┬─────────┘  │    │
│  └─────────┼──────────────────┼───────────────────┼─────────────┘    │
│            │                  │                   │                   │
│  ┌─────────▼──────────────────▼───────────────────▼─────────────┐    │
│  │                    State Management Layer                     │    │
│  │                                                               │    │
│  │  ┌────────────┐ ┌──────────────┐ ┌───────────┐ ┌──────────┐ │    │
│  │  │ AuthCubit  │ │TaskListCubit │ │UserCubits │ │Dashboard │ │    │
│  │  │            │ │TaskDetailCubit│ │(List/Form)│ │ Cubit    │ │    │
│  │  │            │ │TaskFormCubit │ │           │ │          │ │    │
│  │  └─────┬──────┘ └──────┬───────┘ └─────┬─────┘ └────┬─────┘ │    │
│  └────────┼───────────────┼───────────────┼────────────┼────────┘    │
│           │               │               │            │             │
│  ┌────────▼───────────────▼───────────────▼────────────▼────────┐    │
│  │                       Service Layer                           │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────────┐  │    │
│  │  │  Auth    │ │  Task    │ │  User    │ │  Dashboard     │  │    │
│  │  │  Service │ │  Service │ │  Service │ │  Service       │  │    │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬───────────┘  │    │
│  │       │             │            │            │              │    │
│  │  ┌────▼─────────────▼────────────▼────────────▼───────────┐  │    │
│  │  │  Attachment Service                                    │  │    │
│  │  └────────────────────────┬───────────────────────────────┘  │    │
│  └───────────────────────────┼──────────────────────────────────┘    │
│                              │                                       │
│  ┌───────────────────────────▼──────────────────────────────────┐    │
│  │                        Core Layer                             │    │
│  │  ┌──────────┐  ┌──────────────┐  ┌────────────┐  ┌────────┐ │    │
│  │  │ApiClient │  │SecureStorage │  │ErrorHandler│  │Constants│ │    │
│  │  │(Dio+JWT) │  │(Token/UserId)│  │(DioException│ │(URLs)  │ │    │
│  │  │          │  │              │  │ mapping)   │  │        │ │    │
│  │  └────┬─────┘  └──────────────┘  └────────────┘  └────────┘ │    │
│  └───────┼──────────────────────────────────────────────────────┘    │
└──────────┼──────────────────────────────────────────────────────────┘
           │  HTTPS / JSON
           ▼
┌──────────────────────┐
│  TaskFlow Backend    │
│  FastAPI (REST API)  │
│  Port 8000           │
└──────────────────────┘
```

---

## 3. Component Breakdown

| Component | Purpose | Technology |
|-----------|---------|------------|
| **App Entry** | Bootstrap, BloC providers, auth restoration | Flutter `main()`, `MultiBlocProvider` |
| **Router** | Declarative navigation, auth guards, role-based shells | GoRouter + `StatefulShellRoute` |
| **Auth Module** | Login, signup, session persistence, JWT decode | AuthCubit + AuthService + SecureStorage |
| **Task Module** | Task CRUD, status transitions, filtering, detail view | TaskListCubit, TaskDetailCubit, TaskFormCubit |
| **User Module** | User CRUD, search, role management | UserListCubit, UserFormCubit + UserService |
| **Attachment Module** | File upload (multipart), progress tracking, metadata CRUD | AttachmentService + file_picker |
| **Dashboard Module** | Analytics charts (pie, bar), summary cards, date range | DashboardCubit + fl_chart |
| **Navigation Shells** | Role-specific bottom navigation bars | AdminShell, ManagerShell, EmployeeShell |
| **API Client** | HTTP client, JWT interceptor, 401 force-logout | Dio singleton + interceptors |
| **Secure Storage** | Encrypted token & user ID persistence | flutter_secure_storage |
| **Error Handler** | User-friendly error messages from Dio exceptions | ErrorHandler utility class |

---

## 4. Data Flow Diagrams

### 4.1 Authentication Flow
```
User              View              AuthCubit           AuthService       SecureStorage      Backend
 │                 │                    │                    │                  │               │
 │  Enter creds    │                    │                    │                  │               │
 │────────────────→│                    │                    │                  │               │
 │                 │  login(email,pwd)  │                    │                  │               │
 │                 │───────────────────→│                    │                  │               │
 │                 │                    │  emit(AuthLoading) │                  │               │
 │                 │                    │  POST /auth/login  │                  │               │
 │                 │                    │───────────────────→│                  │               │
 │                 │                    │                    │  POST /auth/login│               │
 │                 │                    │                    │─────────────────────────────────→│
 │                 │                    │                    │  {access_token}  │               │
 │                 │                    │                    │←─────────────────────────────────│
 │                 │                    │  LoginResponse     │                  │               │
 │                 │                    │←───────────────────│                  │               │
 │                 │                    │                    │                  │               │
 │                 │                    │  setToken(token)   │                  │               │
 │                 │                    │─────────────────────────────────────→│               │
 │                 │                    │  setUserId(id)     │                  │               │
 │                 │                    │─────────────────────────────────────→│               │
 │                 │                    │                    │                  │               │
 │                 │                    │  GET /users/{id}   │                  │               │
 │                 │                    │───────────────────→│                  │               │
 │                 │                    │  User object       │                  │               │
 │                 │                    │←───────────────────│                  │               │
 │                 │                    │                    │                  │               │
 │                 │                    │  emit(Authenticated)                 │               │
 │                 │  GoRouter redirect │                    │                  │               │
 │                 │  → navigate to /   │                    │                  │               │
 │  Dashboard/Tasks│                    │                    │                  │               │
 │←────────────────│                    │                    │                  │               │
```

### 4.2 Session Restoration Flow (App Launch)
```
App Start         AuthCubit           SecureStorage       UserService       Backend
   │                 │                     │                   │               │
   │  restoreSession()                     │                   │               │
   │────────────────→│                     │                   │               │
   │                 │  getToken()         │                   │               │
   │                 │───────────────────→│                   │               │
   │                 │  getUserId()        │                   │               │
   │                 │───────────────────→│                   │               │
   │                 │                     │                   │               │
   │                 │  [if token exists]  │                   │               │
   │                 │  GET /users/{id}    │                   │               │
   │                 │────────────────────────────────────────→│               │
   │                 │                     │                   │  GET /users/  │
   │                 │                     │                   │──────────────→│
   │                 │                     │                   │  User JSON    │
   │                 │                     │                   │←──────────────│
   │                 │  emit(Authenticated)│                   │               │
   │                 │                     │                   │               │
   │                 │  [if no token]      │                   │               │
   │                 │  emit(Unauthenticated)                  │               │
   │  Show Login     │                     │                   │               │
   │←────────────────│                     │                   │               │
```

### 4.3 Task List → Detail → Status Update Flow
```
User              TaskListView      TaskDetailCubit      TaskService       Backend
 │                    │                   │                   │               │
 │  Tap task card     │                   │                   │               │
 │───────────────────→│                   │                   │               │
 │                    │  GoRouter push    │                   │               │
 │                    │  /tasks/:id       │                   │               │
 │                    │                   │                   │               │
 │                    │  loadTask(taskId) │                   │               │
 │                    │──────────────────→│                   │               │
 │                    │                   │  getTask(id)      │               │
 │                    │                   │──────────────────→│  GET /tasks/  │
 │                    │                   │                   │──────────────→│
 │                    │                   │  getAttachments() │               │
 │                    │                   │──────────────────→│               │
 │                    │                   │  getUser(ownerId) │               │
 │                    │                   │──────────────────→│               │
 │                    │                   │                   │               │
 │                    │  TaskDetailLoaded │                   │               │
 │  Detail screen     │←──────────────────│                   │               │
 │←───────────────────│                   │                   │               │
 │                    │                   │                   │               │
 │  Tap status chip   │                   │                   │               │
 │───────────────────→│  updateStatus()   │                   │               │
 │                    │──────────────────→│  PUT /tasks/{id}  │               │
 │                    │                   │──────────────────→│──────────────→│
 │                    │                   │  Updated Task     │               │
 │  Updated UI        │                   │←──────────────────│               │
 │←───────────────────│←──────────────────│                   │               │
```

### 4.4 File Upload Flow
```
User              TaskDetailView    TaskDetailCubit     AttachmentService    Backend
 │                    │                  │                    │                │
 │  Pick file         │                  │                    │                │
 │───────────────────→│                  │                    │                │
 │                    │  file_picker     │                    │                │
 │                    │  → filePath      │                    │                │
 │                    │                  │                    │                │
 │                    │  uploadFile()    │                    │                │
 │                    │─────────────────→│                    │                │
 │                    │                  │  emit(Uploading 0%)│                │
 │  Progress bar      │←─────────────────│                    │                │
 │                    │                  │  multipart POST    │                │
 │                    │                  │───────────────────→│  POST upload   │
 │                    │                  │                    │───────────────→│
 │                    │                  │  onSendProgress    │                │
 │                    │                  │  emit(Uploading N%)│                │
 │  Progress update   │←─────────────────│                    │                │
 │                    │                  │                    │  Attachment    │
 │                    │                  │                    │←───────────────│
 │                    │                  │  emit(Loaded+att)  │                │
 │  Attachment shown  │←─────────────────│                    │                │
 │←───────────────────│                  │                    │                │
```

---

## 5. Navigation Architecture

### 5.1 Route Map
```
/login          →  LoginView           (public)
/signup         →  SignupView           (public)
                                        
/               →  StatefulShellRoute   (authenticated, role-based shell)
├── /           →  TaskListView         (Branch 0: Tasks)
│   ├── tasks/create  →  TaskCreateView
│   └── tasks/:id     →  TaskDetailView
│       └── edit      →  TaskEditView
├── /users      →  UserListView         (Branch 1: Users/Team)
│   ├── create  →  UserCreateView
│   └── :id/edit →  UserEditView
└── /dashboard  →  DashboardView        (Branch 2: Dashboard)
```

### 5.2 Role-Based Shell Selection
```
┌──────────────────────────────────────────────────────────────┐
│  StatefulShellRoute.indexedStack                             │
│                                                              │
│  authState.user.role →                                       │
│    ┌─────────────────────────────────────────────────────┐   │
│    │ admin    → AdminShell                               │   │
│    │             BottomNav: Tasks | Users | Dashboard     │   │
│    ├─────────────────────────────────────────────────────┤   │
│    │ manager  → ManagerShell                             │   │
│    │             BottomNav: Tasks | Team | Dashboard      │   │
│    ├─────────────────────────────────────────────────────┤   │
│    │ employee → EmployeeShell                            │   │
│    │             BottomNav: My Tasks | Dashboard          │   │
│    └─────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

### 5.3 Auth Guard (GoRouter Redirect)
```
On every navigation:
  1. If NOT authenticated AND NOT on /login or /signup → redirect to /login
  2. If authenticated AND on /login or /signup → redirect to /
  3. Otherwise → allow navigation

Router refreshes on AuthCubit stream changes via _GoRouterRefreshStream(ChangeNotifier).
```

---

## 6. State Management Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  BlocProvider Tree (from main.dart)                             │
│                                                                 │
│  MaterialApp                                                    │
│  └── BlocProvider<AuthCubit>        ← global, app-level        │
│      └── GoRouter                                               │
│          └── StatefulShellRoute                                  │
│              ├── Branch 0 (Tasks)                                │
│              │   ├── BlocProvider<TaskListCubit>    ← per-route │
│              │   ├── BlocProvider<TaskDetailCubit>  ← per-route │
│              │   └── BlocProvider<TaskFormCubit>    ← per-route │
│              ├── Branch 1 (Users)                                │
│              │   ├── BlocProvider<UserListCubit>    ← per-route │
│              │   └── BlocProvider<UserFormCubit>    ← per-route │
│              └── Branch 2 (Dashboard)                            │
│                  └── BlocProvider<DashboardCubit>   ← per-route │
└─────────────────────────────────────────────────────────────────┘
```

| Cubit | State Classes | Lifecycle |
|-------|---------------|-----------|
| **AuthCubit** | AuthInitial → AuthLoading → Authenticated / Unauthenticated / AuthError | App-level (global) |
| **TaskListCubit** | TaskListInitial → TaskListLoading → TaskListLoaded / TaskListError | Per-route (disposed on navigate away) |
| **TaskDetailCubit** | TaskDetailInitial → TaskDetailLoading → TaskDetailLoaded / TaskDetailUploading / TaskDetailError | Per-route |
| **TaskFormCubit** | TaskFormInitial → TaskFormLoading → TaskFormSuccess / TaskFormError | Per-route |
| **UserListCubit** | UserListInitial → UserListLoading → UserListLoaded / UserListError | Per-route |
| **UserFormCubit** | UserFormInitial → UserFormLoading → UserFormSuccess / UserFormError | Per-route |
| **DashboardCubit** | DashboardInitial → DashboardLoading → DashboardLoaded / DashboardError | Per-route |

---

## 7. Security Architecture

| Layer | Mechanism | Details |
|-------|-----------|---------|
| **Token Storage** | flutter_secure_storage | AES-encrypted keychain (iOS) / EncryptedSharedPreferences (Android) |
| **JWT Handling** | Dio interceptor | Auto-attaches `Bearer` token to every request |
| **Session Expiry** | 401 force-logout | ApiClient intercepts 401 → clears storage → emits Unauthenticated |
| **Token Decode** | Client-side JWT parse | Extracts `sub` (user ID) from payload without verification (server verifies) |
| **Password Validation** | Form validators | Minimum 8 characters enforced in login/signup forms |
| **Role Enforcement** | Shell-based navigation | Employees cannot see Users tab; role-gated UI elements |
| **File Upload** | Size limit | 10 MB max file size enforced client-side before upload |
| **Error Masking** | ErrorHandler | Maps HTTP errors to user-friendly messages, never exposes raw server errors |

---

## 8. Platform Architecture

```
┌──────────────────────────────────────────────────┐
│                 Flutter Framework                 │
│              (Single Dart Codebase)               │
│                                                   │
│  ┌──────────┐  ┌──────────┐  ┌────────────────┐ │
│  │ Android  │  │   iOS    │  │  Web / Desktop │ │
│  │          │  │          │  │  (Linux/macOS/  │ │
│  │ 10.0.2.2 │  │localhost │  │   Windows)     │ │
│  │ emulator │  │ simulator│  │                │ │
│  └──────────┘  └──────────┘  └────────────────┘ │
│                                                   │
│  Platform-aware base URL via dart:io Platform    │
└──────────────────────────────────────────────────┘
```

---

## 9. API Integration Summary

| Backend Endpoint | Mobile Service | Mobile Cubit |
|------------------|---------------|--------------|
| `POST /auth/login` | AuthService.login() | AuthCubit.login() |
| `POST /auth/signup` | AuthService.signup() | AuthCubit.signup() |
| `GET /users/` | UserService.getUsers() | UserListCubit.fetchUsers() |
| `GET /users/{id}` | UserService.getUser() | AuthCubit.restoreSession() |
| `POST /users/` | UserService.createUser() | UserFormCubit.createUser() |
| `PUT /users/{id}` | UserService.updateUser() | UserFormCubit.updateUser() |
| `DELETE /users/{id}` | UserService.deleteUser() | UserListCubit.deleteUser() |
| `GET /tasks/` | TaskService.getTasks() | TaskListCubit.fetchTasks() |
| `GET /tasks/{id}` | TaskService.getTask() | TaskDetailCubit.loadTask() |
| `POST /tasks/` | TaskService.createTask() | TaskFormCubit.createTask() |
| `PUT /tasks/{id}` | TaskService.updateTask() | TaskFormCubit.updateTask() |
| `PATCH /tasks/{id}/assign` | TaskService.assignTask() | TaskFormCubit.assignTask() |
| `DELETE /tasks/{id}` | TaskService.deleteTask() | — (direct call from view) |
| `POST /attachments/upload` | AttachmentService.uploadFile() | TaskDetailCubit.uploadFile() |
| `GET /attachments/` | AttachmentService.getAttachments() | TaskDetailCubit.loadTask() |
| `PUT /attachments/{id}` | AttachmentService.updateAttachment() | — |
| `DELETE /attachments/{id}` | AttachmentService.deleteAttachment() | — |
| `GET /dashboard/summary` | DashboardService.getSummary() | DashboardCubit.fetchAll() |
| `GET /dashboard/completion-rate` | DashboardService.getCompletionRate() | DashboardCubit.fetchAll() |
| `GET /dashboard/by-priority` | DashboardService.getByPriority() | DashboardCubit.fetchAll() |
| `GET /dashboard/by-user` | DashboardService.getByUser() | DashboardCubit.fetchAll() |
| `GET /dashboard/date-range` | DashboardService.getDateRange() | DashboardCubit.fetchDateRange() |

---

## 10. Non-Functional Requirements

| Requirement | Target | Implementation |
|-------------|--------|----------------|
| Startup time | < 2s to interactive | Session restore from secure storage, no splash delay |
| Responsiveness | 60 fps UI | Material 3 widgets, Equatable for efficient rebuilds |
| Offline behavior | Graceful error messages | ErrorHandler maps connection errors to user-friendly text |
| Security | Encrypted credentials | flutter_secure_storage (Keychain / EncryptedSharedPrefs) |
| Cross-platform | Android + iOS | Platform-aware base URL, single Dart codebase |
| State management | Predictable, testable | BLoC/Cubit pattern with Equatable states |
| Testability | Unit + widget tests | Cubit DI via constructor, mockito + bloc_test |
| File upload | Progress feedback, 10MB cap | Dio multipart + onSendProgress callback |
| Theme | Light + Dark mode | Material 3 with `colorSchemeSeed`, system brightness |
