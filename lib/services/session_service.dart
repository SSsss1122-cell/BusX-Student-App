import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';

class SessionService {
  static const _kStudentJson = 'student_json';
  static const _kUsn = 'logged_in_usn';
  static const _kInstName = 'institution_name';

  // ------------------------------------------------------------
  // SAVE STUDENT
  // ------------------------------------------------------------
  static Future<void> saveStudent(Student student) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStudentJson, jsonEncode(student.toMap()));
    if (student.usn != null) {
      await prefs.setString(_kUsn, student.usn!);
    }
  }

  // ------------------------------------------------------------
  // GET FULL STUDENT
  // ------------------------------------------------------------
  static Future<Student?> getStudent() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kStudentJson);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return Student.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------
  // CONVENIENCE GETTERS
  // ------------------------------------------------------------
  static Future<String?> getStudentId() async {
    final student = await getStudent();
    return student?.id;
  }

  static Future<String?> getInstitutionId() async {
    final student = await getStudent();
    return student?.institutionId;
  }

  static Future<String?> getUsn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUsn);
  }

  // ------------------------------------------------------------
  // INSTITUTION NAME (cached after login)
  // ------------------------------------------------------------
  static Future<String?> getInstitutionName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kInstName);
  }

  static Future<void> saveInstitutionName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kInstName, name);
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStudentJson);
    await prefs.remove(_kUsn);
    await prefs.remove(_kInstName);
  }

  static Future<void> clear() => logout();
}