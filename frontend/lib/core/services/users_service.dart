import 'api_client.dart';

class UsersService {
  final _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _dio.get('/users');

    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? jobTitle,
    String? description,
    bool isActive = true,
    required List<int> projectIds,
  }) async {
    final response = await _dio.post(
      '/users',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'jobTitle': jobTitle,
        'description': description,
        'isActive': isActive,
        'projectIds': projectIds,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> updateUser({
    required int id,
    String? name,
    String? email,
    String? password,
    String? role,
    String? jobTitle,
    String? description,
    bool? isActive,
    List<int>? projectIds,
  }) async {
    final data = <String, dynamic>{};

    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (password != null && password.isNotEmpty) {
      data['password'] = password;
    }
    if (role != null) data['role'] = role;
    if (jobTitle != null) data['jobTitle'] = jobTitle;
    if (description != null) data['description'] = description;
    if (isActive != null) data['isActive'] = isActive;
    if (projectIds != null) data['projectIds'] = projectIds;

    final response = await _dio.patch(
      '/users/$id',
      data: data,
    );

    return Map<String, dynamic>.from(response.data);
  }
}
