import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student.dart';

class SessionService {
  static const String _keyStudent = 'logged_in_student';

  static Future<void> saveStudent(
    Student student,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _keyStudent,
      jsonEncode(student.toMap()),
    );
  }

  static Future<Student?> getStudent() async {
    final prefs =
        await SharedPreferences.getInstance();

    final data =
        prefs.getString(_keyStudent);

    if (data == null || data.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> map =
          jsonDecode(data);

      return Student.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    return await getStudent() != null;
  }

  static Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_keyStudent);
  }
}