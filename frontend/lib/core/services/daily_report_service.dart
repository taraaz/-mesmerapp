import 'package:dio/dio.dart';

import 'api_client.dart';

class DailyReportService {
  static const String baseUrl = ApiClient.baseUrl;

  final Dio _dio = ApiClient.instance.dio;

  /// Builds the full URL for a stored attachment given its
  /// server-relative `filePath` (as returned by the API).
  String attachmentUrl(String filePath) {
    return '$baseUrl/uploads/$filePath';
  }

  Future<Map<String, dynamic>> createDailyReport({
    required int projectId,
    required String reportDate,
    String? weather,
    double? windSpeed,
    double? temperature,
    double? moisture,
    String? generalIssues,
    required String status,
    String? preparedBy,
    String? preparedByRole,
    String? confirmedBy,
    String? confirmedByRole,
    String? approvedBy,
    String? approvedByRole,
    required List<Map<String, dynamic>> personnel,
    required List<Map<String, dynamic>> equipment,
    required List<Map<String, dynamic>> executedWork,
    required List<Map<String, dynamic>> materials,
    required List<Map<String, dynamic>> nextDayWork,
  }) async {
    final response = await _dio.post(
      '/daily-reports',
      data: {
        'projectId': projectId,
        'reportDate': reportDate,
        'weather': weather,
        'windSpeed': windSpeed,
        'temperature': temperature,
        'moisture': moisture,
        'generalIssues': generalIssues,
        'status': status,
        'preparedBy': preparedBy,
        'preparedByRole': preparedByRole,
        'confirmedBy': confirmedBy,
        'confirmedByRole': confirmedByRole,
        'approvedBy': approvedBy,
        'approvedByRole': approvedByRole,
        'personnel': personnel,
        'equipment': equipment,
        'executedWork': executedWork,
        'materials': materials,
        'nextDayWork': nextDayWork,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> updateDailyReport({
    required int reportId,
    required String reportDate,
    String? weather,
    double? windSpeed,
    double? temperature,
    double? moisture,
    String? generalIssues,
    required String status,
    String? preparedBy,
    String? preparedByRole,
    String? confirmedBy,
    String? confirmedByRole,
    String? approvedBy,
    String? approvedByRole,
    required List<Map<String, dynamic>> personnel,
    required List<Map<String, dynamic>> equipment,
    required List<Map<String, dynamic>> executedWork,
    required List<Map<String, dynamic>> materials,
    required List<Map<String, dynamic>> nextDayWork,
  }) async {
    final response = await _dio.patch(
      '/daily-reports/$reportId',
      data: {
        'reportDate': reportDate,
        'weather': weather,
        'windSpeed': windSpeed,
        'temperature': temperature,
        'moisture': moisture,
        'generalIssues': generalIssues,
        'status': status,
        'preparedBy': preparedBy,
        'preparedByRole': preparedByRole,
        'confirmedBy': confirmedBy,
        'confirmedByRole': confirmedByRole,
        'approvedBy': approvedBy,
        'approvedByRole': approvedByRole,
        'personnel': personnel,
        'equipment': equipment,
        'executedWork': executedWork,
        'materials': materials,
        'nextDayWork': nextDayWork,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getReportsByProject(
    int projectId,
  ) async {
    final response = await _dio.get(
      '/daily-reports/project/$projectId',
    );

    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getReportById(
    int reportId,
  ) async {
    final response = await _dio.get(
      '/daily-reports/$reportId',
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> uploadAttachment({
    required int reportId,
    required String fileName,
    required List<int> bytes,
    required bool isPhoto,
  }) async {
    final formData = FormData.fromMap({
      'isPhoto': isPhoto.toString(),
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '/daily-reports/$reportId/attachments',
      data: formData,
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<void> deleteAttachment(int attachmentId) async {
    await _dio.delete(
      '/daily-reports/attachments/$attachmentId',
    );
  }
}