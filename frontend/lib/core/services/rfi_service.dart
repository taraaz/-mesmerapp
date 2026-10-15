import 'package:dio/dio.dart';

import 'api_client.dart';

class RfiService {
  static const String baseUrl = ApiClient.baseUrl;

  final Dio _dio = ApiClient.instance.dio;

  /// Builds the full URL for a stored RFI attachment given its
  /// server-relative `filePath` (as returned by the API).
  String attachmentUrl(String filePath) {
    return '$baseUrl/uploads/$filePath';
  }

  Future<Map<String, dynamic>> createRfi(Map<String, dynamic> payload) async {
    final response = await _dio.post('/rfis', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> updateRfi(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.patch('/rfis/$id', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getRfisByProject(
    int projectId, {
    String? status,
    int? assignedToId,
    String? rfiNumber,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _dio.get(
      '/rfis/project/$projectId',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'assignedToId': ?assignedToId,
        if (rfiNumber != null && rfiNumber.isNotEmpty)
          'rfiNumber': rfiNumber,
        'dateFrom': ?dateFrom,
        'dateTo': ?dateTo,
      },
    );

    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getRfiById(int id) async {
    final response = await _dio.get('/rfis/$id');
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> uploadAttachment({
    required int rfiId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await _dio.post(
      '/rfis/$rfiId/attachments',
      data: formData,
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<void> deleteAttachment(int attachmentId) async {
    await _dio.delete('/rfis/attachments/$attachmentId');
  }

  Future<void> deleteRfi(int id) async {
    await _dio.delete('/rfis/$id');
  }
}
