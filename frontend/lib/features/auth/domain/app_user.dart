enum AppRole { mainAdmin, projectManager, technicalExpert }

AppRole appRoleFromString(String value) {
  switch (value) {
    case 'MAIN_ADMIN':
      return AppRole.mainAdmin;
    case 'PROJECT_MANAGER':
      return AppRole.projectManager;
    case 'TECHNICAL_EXPERT':
    default:
      return AppRole.technicalExpert;
  }
}

String appRoleToApiValue(AppRole role) {
  switch (role) {
    case AppRole.mainAdmin:
      return 'MAIN_ADMIN';
    case AppRole.projectManager:
      return 'PROJECT_MANAGER';
    case AppRole.technicalExpert:
      return 'TECHNICAL_EXPERT';
  }
}

String appRoleLabel(AppRole role) {
  switch (role) {
    case AppRole.mainAdmin:
      return 'Main Admin';
    case AppRole.projectManager:
      return 'Project Manager';
    case AppRole.technicalExpert:
      return 'Technical Expert';
  }
}

class AppUser {
  final int id;
  final String name;
  final String email;
  final AppRole role;
  final String? jobTitle;
  final String? description;
  final bool isActive;
  final List<int> projectIds;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.jobTitle,
    this.description,
    required this.isActive,
    required this.projectIds,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: appRoleFromString(json['role'] as String),
      jobTitle: json['jobTitle'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      projectIds: ((json['projectIds'] as List<dynamic>?) ?? [])
          .map((id) => id as int)
          .toList(),
    );
  }

  bool get isMainAdmin => role == AppRole.mainAdmin;
  bool get isProjectManager => role == AppRole.projectManager;
  bool get isTechnicalExpert => role == AppRole.technicalExpert;
}
