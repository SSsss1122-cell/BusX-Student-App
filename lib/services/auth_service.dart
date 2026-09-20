import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student.dart';

class AuthService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

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

      return Student.fromMap(response);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(
        'Unable to connect to server.',
      );
    }
  }
}