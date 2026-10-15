import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/project_service.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../../../users/presentation/pages/user_management_page.dart';
import 'project_dashboard_page.dart';

const List<Color> _avatarPalette = [
  AppColors.primary,
  AppColors.success,
  Color(0xFF7C4DFF),
  Color(0xFFF57C00),
  Color(0xFF00897B),
];

Color projectAvatarColor(int index) {
  return _avatarPalette[index % _avatarPalette.length];
}

class Project {
  final int id;
  final String code;
  final String name;
  final String location;
  final String? description;
  final String status;
  final DateTime? updatedAt;

  const Project({
    required this.id,
    required this.code,
    required this.name,
    required this.location,
    this.description,
    required this.status,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> {
  final ProjectService _projectService = ProjectService();

  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  List<Project> _projects = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final data = await _projectService.getProjects();

      final projects = data
          .map((json) => Project.fromJson(json))
          .toList();

      if (!mounted) return;

      setState(() {
        _projects = projects;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showAddProjectDialog() async {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final descriptionController = TextEditingController();

    String selectedStatus = 'Active';
    bool isSaving = false;

    final formKey = GlobalKey<FormState>();

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              Future<void> saveProject() async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                setDialogState(() {
                  isSaving = true;
                });

                try {
                  await _projectService.createProject(
                    code: codeController.text.trim(),
                    name: nameController.text.trim(),
                    location: locationController.text.trim(),
                    description:
                        descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                    status: selectedStatus,
                  );

                  if (!dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop();

                  await _loadProjects();

                  if (!mounted) return;

                  _messengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Project created successfully',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;

                  setDialogState(() {
                    isSaving = false;
                  });

                  _messengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not create project: $e',
                      ),
                    ),
                  );
                }
              }

              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.business),
                    SizedBox(width: 10),
                    Text('New Project'),
                  ],
                ),
                content: SizedBox(
                  width: 450,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: codeController,
                            textCapitalization:
                                TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Project Code',
                              hintText: 'P003',
                              prefixIcon: Icon(Icons.tag),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter project code';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Project Name',
                              hintText: 'New Project',
                              prefixIcon: Icon(Icons.business),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter project name';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              hintText: 'Tashkent Region',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter location';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              prefixIcon: Icon(Icons.description),
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            initialValue: selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.flag),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Active',
                                child: Text('Active'),
                              ),
                              DropdownMenuItem(
                                value: 'Pending',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem(
                                value: 'Completed',
                                child: Text('Completed'),
                              ),
                              DropdownMenuItem(
                                value: 'Archived',
                                child: Text('Archived'),
                              ),
                            ],
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    if (value == null) return;

                                    setDialogState(() {
                                      selectedStatus = value;
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: isSaving ? null : saveProject,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      isSaving
                          ? 'Saving...'
                          : 'Save Project',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      codeController.dispose();
      nameController.dispose();
      locationController.dispose();
      descriptionController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        drawer: user != null ? _buildDrawer(context, user) : null,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text(
            'AI Project Hub',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No new notifications'),
                  ),
                );
              },
            ),
            if (user != null) _buildAccountMenu(context, user),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildAccountMenu(BuildContext context, AppUser user) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      onSelected: (value) async {
        if (value == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfilePage(),
            ),
          );
          return;
        }

        if (value == 'logout') {
          await ref.read(authProvider.notifier).logout();

          if (!context.mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const LoginPage(),
            ),
            (route) => false,
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                appRoleLabel(user.role),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20),
              SizedBox(width: 10),
              Text('Profile'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white,
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppUser user) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'AI Project Hub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    appRoleLabel(user.role),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Projects'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            if (user.isMainAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('User Management'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserManagementPage(),
                    ),
                  );
                },
              ),
            if (user.isProjectManager)
              ListTile(
                leading: const Icon(Icons.engineering_outlined),
                title: const Text('Technical Experts'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserManagementPage(),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfilePage(),
                  ),
                );
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();

                if (!context.mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Projects',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showAddProjectDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Project'),
              ),
            ],
          ),
        ),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load projects',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadProjects,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_projects.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadProjects,
        child: ListView(
          children: const [
            SizedBox(height: 250),
            Center(
              child: Text(
                'No projects found.',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          final avatarColor = projectAvatarColor(index);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      project.code.length >= 2
                          ? project.code.substring(0, 2).toUpperCase()
                          : project.code.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.code,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          crossAxisAlignment:
                              WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Updated: ${_formatDate(project.updatedAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            _buildStatusBadge(project.status),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDashboardPage(
                            projectId: project.id,
                            projectCode: project.code,
                            projectName: project.name,
                            projectDescription: project.description,
                            projectLocation: project.location,
                            projectStatus: project.status,
                            avatarColor: avatarColor,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy-MM-dd').format(date.toLocal());
  }

  Widget _buildStatusBadge(String status) {
    final Color color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;

      case 'Pending':
        return AppColors.warning;

      case 'Completed':
        return AppColors.primary;

      case 'Archived':
        return AppColors.textSecondary;

      default:
        return AppColors.textSecondary;
    }
  }
}