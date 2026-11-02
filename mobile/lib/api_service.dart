import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  String baseUrl;

  ApiService({String? customUrl})
      : baseUrl = customUrl ?? defaultBaseUrl;

  static String get defaultBaseUrl {
    if (Platform.isAndroid) {
      // Android emulator default localhost alias
      return 'http://10.0.2.2:5000';
    } else {
      // iOS simulator, macOS desktop, or web
      return 'http://127.0.0.1:5000';
    }
  }

  /// Check health status of Flask server
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// Fetch complete sync payload
  Future<Map<String, dynamic>?> fetchSyncData() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/sync'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Return null on failure
    }
    return null;
  }

  /// Send full data payload to sync with Flask backend
  Future<bool> pushSyncData(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Post single attendance record
  Future<bool> recordAttendance({
    required String id,
    required String date,
    required int slot,
    required String subject,
    required String status,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/attendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'date': date,
          'slot': slot,
          'subject': subject,
          'status': status,
        }),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
