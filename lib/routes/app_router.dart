import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../cubits/dashboard/dashboard_cubit.dart';
import '../cubits/task_detail/task_detail_cubit.dart';
import '../cubits/task_form/task_form_cubit.dart';
import '../cubits/task_list/task_list_cubit.dart';
import '../cubits/user_form/user_form_cubit.dart';
import '../cubits/user_list/user_list_cubit.dart';
import '../models/user.dart';
import '../views/auth/login_view.dart';
import '../views/auth/signup_view.dart';
import '../views/dashboard/dashboard_view.dart';
import '../views/shell/admin_shell.dart';
import '../views/shell/employee_shell.dart';
import '../views/shell/manager_shell.dart';
import '../views/tasks/task_create_view.dart';
import '../views/tasks/task_detail_view.dart';
import '../views/tasks/task_edit_view.dart';
import '../views/tasks/task_list_view.dart';
import '../views/users/user_create_view.dart';
import '../views/users/user_edit_view.dart';
import '../views/users/user_list_view.dart';

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    refreshListenable: _GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isAuthenticated = authState is Authenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupView(),
      ),

      // Authenticated shell routes — picks shell based on user role
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final authState = authCubit.state;
          if (authState is! Authenticated) {
            return const LoginView();
          }
          switch (authState.user.role) {
            case UserRole.admin:
              return AdminShell(navigationShell: navigationShell);
            case UserRole.manager:
              return ManagerShell(navigationShell: navigationShell);
            case UserRole.employee:
              return EmployeeShell(navigationShell: navigationShell);
          }
        },
        branches: [
          // Branch 0: Tasks
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => BlocProvider(
                  create: (_) => TaskListCubit(),
                  child: const TaskListView(),
                ),
                routes: [
                  GoRoute(
                    path: 'tasks/create',
                    builder: (context, state) => BlocProvider(
                      create: (_) => TaskFormCubit(),
                      child: const TaskCreateView(),
                    ),
                  ),
                  GoRoute(
                    path: 'tasks/:id',
                    builder: (context, state) {
                      final taskId =
                          int.parse(state.pathParameters['id']!);
                      return BlocProvider(
                        create: (_) => TaskDetailCubit(),
                        child: TaskDetailView(taskId: taskId),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) {
                          final taskId =
                              int.parse(state.pathParameters['id']!);
                          return BlocProvider(
                            create: (_) => TaskFormCubit(),
                            child: TaskEditView(taskId: taskId),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Branch 1: Users / Team (hidden for employee via shell)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/users',
                builder: (context, state) => BlocProvider(
                  create: (_) => UserListCubit(),
                  child: const UserListView(),
                ),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => BlocProvider(
                      create: (_) => UserFormCubit(),
                      child: const UserCreateView(),
                    ),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) {
                      final userId =
                          int.parse(state.pathParameters['id']!);
                      return BlocProvider(
                        create: (_) => UserFormCubit(),
                        child: UserEditView(userId: userId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => BlocProvider(
                  create: (_) => DashboardCubit(),
                  child: const DashboardView(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Converts a Stream into a Listenable for GoRouter refreshListenable.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
