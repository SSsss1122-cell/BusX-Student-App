import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint.dart';

class ComplaintService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch only complaints belonging to the given student
  Future<List<Complaint>> getStudentComplaints(String studentId) async {
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => Complaint.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new complaint
  Future<Complaint> createComplaint({
    required String studentId,
    required String institutionId,
    required String title,
    String? description,
    String? photoUrl,
    String? videoUrl,
  }) async {
    final response = await _supabase
        .from('complaints')
        .insert({
          'student_id': studentId,
          'institution_id': institutionId,
          'title': title,
          'description': description,
          'photo_url': photoUrl,
          'video_url': videoUrl,
          'status': 'pending',
        })
        .select()
        .single();

    return Complaint.fromMap(response);
  }

  /// Optional: upload a photo/video and return public URL
  Future<String?> uploadComplaintMedia({
    required String studentId,
    required String filePath,
    required Uint8List bytes,
    required String fileName,
    bool isVideo = false,
  }) async {
    final bucket = isVideo ? 'complaint_videos' : 'complaint_photos';
    final path = '$studentId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _supabase.storage.from(bucket).uploadBinary(path, bytes);

    return _supabase.storage.from(bucket).getPublicUrl(path);
  }
}