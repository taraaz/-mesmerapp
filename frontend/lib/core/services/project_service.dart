import 'api_client.dart';

class ProjectService {
  final _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> getProjects() async {
    final response = await _dio.get('/projects');

    return List<Map<String, dynamic>>.from(response.data);
  }

  /// The team assigned to a project — used to populate "assign to"
  /// pickers (e.g. RFI referral) so only users with access to this
  /// project can ever be selected.
  Future<List<Map<String, dynamic>>> getProjectMembers(
    int projectId,
  ) async {
    final response = await _dio.get('/projects/$projectId/members');

    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createProject({
    required String code,
    required String name,
    required String location,
    String? description,
    String status = 'Active',
  }) async {
    final response = await _dio.post(
      '/projects',
      data: {
        'code': code,
        'name': name,
        'location': location,
        'description': description,
        'status': status,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
}
