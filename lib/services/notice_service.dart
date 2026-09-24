import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notice.dart';

class NoticeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Notice>> getStudentNotices({
    required String institutionId,
    required String studentId,
  }) async {
    final response = await _supabase
        .from('notices')
        .select()
        .eq('institution_id', institutionId)
        .eq('is_active', true)
        // broadcast (student_id IS NULL) OR targeted to me
        .or('student_id.is.null,student_id.eq.$studentId')
        .order('created_at', ascending: false);

    final list = (response as List)
        .map((e) => Notice.fromMap(e as Map<String, dynamic>))
        .toList();

    // Filter expired in Dart (simple, reliable)
    return list
        .where((n) =>
            n.expiryDate == null || n.expiryDate!.isAfter(DateTime.now()))
        .toList();
  }
}