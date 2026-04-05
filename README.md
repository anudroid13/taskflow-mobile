# taskflow-mobile

# Smart Task Management App

## Overview
A cross-platform Flutter mobile app for enterprise task management with role-based access control, productivity dashboards, and seamless integration with the TaskFlow backend API.

## Project Goals
- Intuitive mobile interface for task management
- Role-based views (Admin, Manager, Employee)
- Real-time dashboard with productivity metrics
- Secure authentication with JWT token storage
- File attachment support for tasks

## Features
- Authentication (login/signup with JWT)
- Role-based navigation shells (Admin, Manager, Employee)
- Task CRUD with status, priority, and assignment
- Dashboard with charts and analytics (fl_chart)
- User management (Admin)
- File attachments to tasks
- Secure token storage (flutter_secure_storage)

## Tech Stack
- **Framework:** Flutter (SDK ^3.7.2)
- **State Management:** flutter_bloc / Cubit
- **Networking:** Dio
- **Routing:** go_router
- **Charts:** fl_chart
- **Storage:** flutter_secure_storage

## Folder Structure
```
taskflow-mobile/
  lib/
    main.dart
    core/
      api_client.dart
      constants.dart
      error_handler.dart
      secure_storage.dart
    models/
      attachment.dart
      dashboard.dart
      login_response.dart
      task.dart
      user.dart
    services/
      attachment_service.dart
      auth_service.dart
      dashboard_service.dart
      task_service.dart
      user_service.dart
    routes/
      app_router.dart
    cubits/
      auth/
      dashboard/
      task_detail/
      task_form/
      task_list/
      user_form/
      user_list/
    views/
      auth/
        login_view.dart
        signup_view.dart
      dashboard/
        dashboard_view.dart
      shell/
        admin_shell.dart
        employee_shell.dart
        manager_shell.dart
      tasks/
        task_create_view.dart
        task_detail_view.dart
        task_edit_view.dart
        task_list_view.dart
      users/
        user_create_view.dart
        user_edit_view.dart
        user_list_view.dart
    widgets/
      confirm_dialog.dart
      empty_state.dart
      loading_overlay.dart
      priority_tag.dart
      status_badge.dart
  test/
    widget_test.dart
  pubspec.yaml
  README.md
```

## Quick Setup
1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Clone the repo: `git clone https://github.com/anudroid13/taskflow-mobile.git`
3. Install dependencies: `flutter pub get`
4. Run the app: `flutter run`

## Backend
This app connects to the [taskflow-backend](https://github.com/anudroid13/taskflow-backend) API. Make sure the backend is running before using the app.

- **Android emulator:** connects to `http://10.0.2.2:8000`
- **iOS simulator / desktop:** connects to `http://localhost:8000`

## Testing
- `flutter test`

## Future Enhancements
- Push notifications
- Offline mode with local caching
- Dark theme support
- AI-powered task suggestions
