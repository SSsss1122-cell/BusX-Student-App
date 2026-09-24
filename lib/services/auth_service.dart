import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';
import 'session_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Student?> login({
    required String usn,
    required String password,
  }) async {
    final row = await _supabase
        .from('students_new')
        .select(
          'id, full_name, usn, branch, phone, email, role, '
          'institution_id, current_interval_id, routes, semester, route_id',
        )
        .eq('usn', usn)
        .eq('password', password)
        .maybeSingle();

    if (row == null) return null;

    // Cache institution name
    try {
      final inst = await _supabase
          .from('institutions')
          .select('name') // ⚠️ adjust if column is different
          .eq('id', row['institution_id'])
          .maybeSingle();
      if (inst != null && inst['name'] != null) {
        await SessionService.saveInstitutionName(inst['name'] as String);
      }
    } catch (_) {}

    return Student.fromMap(row);
  }
}