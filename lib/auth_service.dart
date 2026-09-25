// lib/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:idrm_video_app/device_id_helper.dart';

class AuthService {
  static const String apiBase = "https://biogramx.com/api/";

  // 1) الحصول على رقم الجهاز
  static Future<String> getDeviceSerial() async {
    final androidInfo = await DeviceIdHelper.getDeviceId();
    return androidInfo; // Android ID
  }

  static Future<({bool allowed, String reason})> checkMobileAccess({
    required String deviceSerial,
    required String courseId,
  }) async {
    final url = Uri.parse(
      "${apiBase}user/mobile/checkaccess/$deviceSerial/$courseId",
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      return (allowed: false, reason: "ServerError");
    }

    final decoded = jsonDecode(response.body);

    bool allowed = decoded["allowed"] ?? false;
    String reason = decoded["reason"] ?? "Unknown";

    return (allowed: allowed, reason: reason);
  }

  /// إرسال طلب صلاحية
  static Future<String> sendAccessRequest({
    required String courseCode,
    required String realName,
    required String mobile,
    required String userSerial,
  }) async {
    try {
      final courseId = await getCourseIdByCode(courseCode);
      if (courseId == -1) {
        return "COURSE_NOT_FOUND";
      }

      final body = jsonEncode({
        "courseId": courseId,
        "realName": realName,
        "mobile": mobile,
        "userSerial": userSerial,
        "userState": false,
        "closeProg": false,
      });

      final url = Uri.parse("${apiBase}user/add");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final result = response.body.trim().toLowerCase();
        if (result == "true") {
          return "SUCCESS";
        } else {
          return "ALREADY_EXISTS";
        }
      }

      return "SERVER_ERROR";
    } catch (_) {
      return "ERROR";
    }
  }

  // نفس GetCourseIdByCode فى VB
  static Future<int> getCourseIdByCode(String courseCode) async {
    try {
      final url = Uri.parse("${apiBase}user/courseid/$courseCode");

      final response = await http.get(url);
      if (response.statusCode != 200) return -1;

      final result = response.body.trim();
      return int.parse(result);
    } catch (_) {
      return -1;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserCourses() async {
    try {
      final String userSerial = await getDeviceSerial();

      final url = Uri.parse("${apiBase}user/allcourses/$userSerial");

      final response = await http.get(url);

      if (response.statusCode != 200) return [];

      final List data = jsonDecode(response.body);

      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // 🔥 الإصدار الحالي للتطبيق
  static const String currentVersion = "M9.0.0.0";

  static Future<bool> checkVersion() async {
    try {
      final url = Uri.parse("${apiBase}Version/versionstatus/$currentVersion");

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return false;
      }

      final result = response.body.trim().toLowerCase();

      return (result == "true" || result == "1");
    } catch (_) {
      return false;
    }
  }

  // داخل AuthService
  // ✅ تجيب "Name|Mobile" من الـ API حسب الجهاز والكورس
  static Future<String?> getContactByCourse({
    required String deviceSerial,
    required String courseId,
  }) async {
    try {
      final url = Uri.parse(
        "${apiBase}user/contact/bycourse/$deviceSerial/$courseId",
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final raw = response.body.trim();
      if (raw.isEmpty) return null;

      // مثال: MohamedElBahrawy|01221166601
      return raw;
    } catch (_) {
      return null;
    }
  }
}
