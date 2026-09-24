import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_interval.dart';

class FeesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch intervals only for the logged-in student
  Future<List<StudentInterval>> getStudentIntervals(String studentId) async {
    final response = await _supabase
        .from('student_intervals')
        .select()
        .eq('student_id', studentId)
        .order('interval_number', ascending: true);

    return (response as List)
        .map((e) => StudentInterval.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}