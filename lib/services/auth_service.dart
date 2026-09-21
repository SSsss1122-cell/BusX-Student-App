import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _usnKey = 'logged_in_usn';

  // ---------------------------------------------
  // Login
  // ---------------------------------------------
  Future<Student?> login({
    required String usn,
    required String password,
  }) async {
    try {
      final response = await _supabase
          .from('students_new')
          .select()
          .eq('usn', usn)
          .eq('password', password)
          .eq('role', 'student')
          .maybeSingle();

      if (response == null) {
        return null;
      }

      // Remember the logged-in USN for future sessions
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usnKey, usn);

      return Student.fromMap(response);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unable to connect to server.');
    }
  }

  // ---------------------------------------------
  // Get the currently logged-in student
  // ---------------------------------------------
  Future<Student?> getCurrentStudent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usn = prefs.getString(_usnKey);

      if (usn == null || usn.isEmpty) {
        return null;
      }

      final response = await _supabase
          .from('students_new')
          .select()
          .eq('usn', usn)
          .eq('role', 'student')
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Student.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------
  // Logout
  // ---------------------------------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usnKey);
  }
}
