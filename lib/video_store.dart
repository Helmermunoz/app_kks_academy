import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'video_file.dart';

class VideoStore {
  final SupabaseClient client;
  VideoStore(this.client);
  Future<List<Map<String, dynamic>>> list({String? workoutId}) async {
    var query = client.from('session_videos').select();
    if (workoutId != null) query = query.eq('workout_id', workoutId);
    return await query.order('created_at', ascending: false).limit(100);
  }

  Future<String> playback(String path) =>
      client.storage.from('session-videos').createSignedUrl(path, 3600);
  Future<void> upload(String workout, String title, VideoFile file) async {
    if (file.bytes.isEmpty ||
        file.bytes.length > 50 * 1024 * 1024 ||
        !['video/mp4', 'video/webm', 'video/quicktime'].contains(file.type)) {
      throw Exception('Selecciona MP4, WebM o MOV de hasta 50 MB.');
    }
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Inicia sesión de nuevo.');
    final random = Random.secure();
    final token = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final extension = file.type == 'video/mp4'
        ? 'mp4'
        : file.type == 'video/webm'
        ? 'webm'
        : 'mov';
    final path = '${user.id}/$workout/$token.$extension';
    await client.storage
        .from('session-videos')
        .uploadBinary(
          path,
          file.bytes,
          fileOptions: FileOptions(contentType: file.type, upsert: false),
        );
    try {
      await client.from('session_videos').insert({
        'workout_id': workout,
        'object_path': path,
        'title': title.trim(),
      });
    } catch (_) {
      // If the metadata committed but the response was lost, the policy prevents deleting a published clip.
      try {
        await client.storage.from('session-videos').remove([path]);
      } catch (_) {
        /* Keep original failure. */
      }
      rethrow;
    }
  }
}
