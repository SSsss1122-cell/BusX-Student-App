import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Announcement>> getAnnouncements(String institutionId) async {
    final response = await _supabase
        .from('announcements')
        .select()
        .eq('institution_id', institutionId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => Announcement.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}