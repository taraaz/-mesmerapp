import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/project_service.dart';
import '../../../../core/services/users_service.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../auth/domain/app_user.dart';

/// Serves both the Main Admin's "User Management" screen (full role
/// choices, all projects) and the Project Manager's "Technical Experts"
/// screen (role locked to Technical Expert, projects limited to the
/// PM's own). The backend already scopes `/users` and `/projects` to
/// what the caller is allowed to see, so one page covers both.
class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() =>
      _UserManagementPageState();
}

class _UserManagementPageState
    extends ConsumerState<UserManagementPage> {
  static final RegExp _emailPattern =
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final UsersService _usersService = UsersService();
  final ProjectService _projectService = ProjectService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool get _isProjectManager =>
      ref.read(authProvider).user?.isProjectManager ?? false;

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _usersService.getUsers(),
        _projectService.getProjects(),
      ]);

      if (!mounted) return;

      setState(() {
        _users = results[0];
        _projects = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load users: ${_extractErrorMessage(e)}';
        _isLoading = false;
      });
    }
  }

  String _extractErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;

      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }

      if (data is Map && data['message'] is List) {
        return (data['message'] as List).join(', ');
      }

      if (e.response?.statusCode != null) {
        return 'Server error (${e.response?.statusCode})';
      }

      return e.message ?? 'Network error';
    }

    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isPm = _isProjectManager;
    final title = isPm ? 'Technical Experts' : 'User Management';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.person_add_alt),
        label: Text(isPm ? 'New Technical Expert' : 'New User'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline,
                size: 60,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              const Text(
                'No users yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          return _buildUserCard(_users[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final bool isActive = user['isActive'] as bool? ?? true;
    final String role = user['role'] as String;
    final List<dynamic> projectIds =
        (user['projectIds'] as List<dynamic>?) ?? [];

    final projectNames = projectIds
        .map((id) => _projects.firstWhere(
              (p) => p['id'] == id,
              orElse: () => const {'name': '?'},
            )['name'] as String)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showUserDialog(existingUser: user),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      (user['name'] as String).isNotEmpty
                          ? (user['name'] as String)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user['email'] as String,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _badge(
                    isActive ? 'Active' : 'Inactive',
                    isActive
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _badge(appRoleLabel(appRoleFromString(role)),
                      AppColors.primary),
                  if ((user['jobTitle'] as String?)?.isNotEmpty ==
                      true)
                    _badge(
                      user['jobTitle'] as String,
                      AppColors.warning,
                    ),
                  ...projectNames.map(
                    (name) => _badge(name, AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _showUserDialog({
    Map<String, dynamic>? existingUser,
  }) async {
    final isEditing = existingUser != null;
    final isPm = _isProjectManager;

    final nameController = TextEditingController(
      text: existingUser?['name'] as String? ?? '',
    );
    final emailController = TextEditingController(
      text: existingUser?['email'] as String? ?? '',
    );
    final passwordController = TextEditingController();
    final jobTitleController = TextEditingController(
      text: existingUser?['jobTitle'] as String? ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingUser?['description'] as String? ?? '',
    );

    AppRole selectedRole = isPm
        ? AppRole.technicalExpert
        : appRoleFromString(
            existingUser?['role'] as String? ?? 'TECHNICAL_EXPERT',
          );

    bool isActive = existingUser?['isActive'] as bool? ?? true;

    final existingProjectIds =
        ((existingUser?['projectIds'] as List<dynamic>?) ?? [])
            .map((id) => id as int)
            .toSet();

    final selectedProjectIds = Set<int>.from(existingProjectIds);

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              Future<void> save() async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                setDialogState(() => isSaving = true);

                try {
                  if (isEditing) {
                    await _usersService.updateUser(
                      id: existingUser['id'] as int,
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                      role: appRoleToApiValue(selectedRole),
                      jobTitle: jobTitleController.text.trim(),
                      description: descriptionController.text.trim(),
                      isActive: isActive,
                      projectIds: selectedProjectIds.toList(),
                    );
                  } else {
                    await _usersService.createUser(
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                      role: appRoleToApiValue(selectedRole),
                      jobTitle: jobTitleController.text.trim(),
                      description: descriptionController.text.trim(),
                      isActive: isActive,
                      projectIds: selectedProjectIds.toList(),
                    );
                  }

                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();

                  await _loadData();

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'User updated successfully'
                            : 'User created successfully',
                      ),
                    ),
                  );
                } catch (e) {
                  setDialogState(() => isSaving = false);

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not save user: ${_extractErrorMessage(e)}',
                      ),
                    ),
                  );
                }
              }

              return AlertDialog(
                title: Text(isEditing ? 'Edit User' : 'New User'),
                content: SizedBox(
                  width: 480,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Please enter a name'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter an email';
                              }
                              if (!_emailPattern.hasMatch(value.trim())) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: isEditing
                                  ? 'Password (leave blank to keep)'
                                  : 'Password',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (isEditing) return null;
                              if (value == null || value.length < 6) {
                                return 'At least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<AppRole>(
                            initialValue: selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              border: OutlineInputBorder(),
                            ),
                            items: (isPm
                                    ? [AppRole.technicalExpert]
                                    : AppRole.values)
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(appRoleLabel(role)),
                                  ),
                                )
                                .toList(),
                            onChanged: isPm
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setDialogState(
                                      () => selectedRole = value,
                                    );
                                  },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: jobTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Job Title / Technical Speciality',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            value: isActive,
                            onChanged: (value) {
                              setDialogState(() => isActive = value);
                            },
                            title: const Text('Active'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Project Access',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_projects.isEmpty)
                            const Text(
                              'No projects available to assign.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            )
                          else
                            ..._projects.map((project) {
                              final id = project['id'] as int;
                              return CheckboxListTile(
                                value:
                                    selectedProjectIds.contains(id),
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      selectedProjectIds.add(id);
                                    } else {
                                      selectedProjectIds.remove(id);
                                    }
                                  });
                                },
                                title: Text(
                                  project['name'] as String,
                                ),
                                subtitle: Text(
                                  project['code'] as String,
                                ),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: isSaving ? null : save,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(isSaving ? 'Saving...' : 'Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      jobTitleController.dispose();
      descriptionController.dispose();
    }
  }
}
