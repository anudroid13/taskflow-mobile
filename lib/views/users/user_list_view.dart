import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/user_list/user_list_cubit.dart';
import '../../cubits/user_list/user_list_state.dart';
import '../../models/user.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';

class UserListView extends StatefulWidget {
  const UserListView({super.key});

  @override
  State<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<UserListCubit>().fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final isAdmin =
        authState is Authenticated && authState.user.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Users' : 'Team'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.push('/users/create'),
              child: const Icon(Icons.person_add),
            )
          : null,
      body: Column(
        children: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by email...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<UserListCubit>().fetchUsers();
                    },
                  ),
                ),
                onSubmitted: (value) {
                  context.read<UserListCubit>().fetchUsers(
                        email: value.isEmpty ? null : value,
                      );
                },
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  context.read<UserListCubit>().fetchUsers(),
              child: BlocBuilder<UserListCubit, UserListState>(
                builder: (context, state) {
                  if (state is UserListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is UserListError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is UserListLoaded) {
                    if (state.users.isEmpty) {
                      return const EmptyState(
                        message: 'No users found',
                        icon: Icons.people_outline,
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        final user = state.users[index];
                        return _UserCard(
                          user: user,
                          isAdmin: isAdmin,
                          onDelete: isAdmin
                              ? () => _deleteUser(context, user)
                              : null,
                          onEdit: isAdmin
                              ? () =>
                                  context.push('/users/${user.id}/edit')
                              : null,
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(BuildContext context, User user) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete User',
      content: 'Are you sure you want to delete ${user.fullName}?',
    );
    if (confirmed && mounted) {
      context.read<UserListCubit>().deleteUser(user.id);
    }
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final bool isAdmin;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _UserCard({
    required this.user,
    required this.isAdmin,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.fullName.isNotEmpty
              ? user.fullName[0].toUpperCase()
              : '?'),
        ),
        title: Text(user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${user.email} • ${user.role.name}'),
        trailing: isAdmin
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
