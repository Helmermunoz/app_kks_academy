import 'package:supabase_flutter/supabase_flutter.dart';

typedef DevelopmentRow = Map<String, dynamic>;

abstract class DevelopmentStore {
  Future<List<DevelopmentRow>> sessions(String from, String through);
  Future<void> saveReport(String workout, DevelopmentRow values, bool exists);
  Future<void> saveReview(String video, DevelopmentRow values, bool exists);
}

class SupabaseDevelopmentStore implements DevelopmentStore {
  final SupabaseClient client;
  SupabaseDevelopmentStore(this.client);

  @override
  Future<List<DevelopmentRow>> sessions(String from, String through) async {
    // Paginate instead of silently truncating a coach's roster at the API limit.
    final rows = <DevelopmentRow>[];
    for (var offset = 0; ; offset += 200) {
      final page = await client
          .from('workouts')
          .select(
            'id,athlete_id,day,title,kind,throwing_plan,location,start_time,'
            'session_reports(*),workout_completions(workout_id),'
            'session_videos(*,video_reviews(*))',
          )
          .gte('day', from)
          .lte('day', through)
          .order('day', ascending: false)
          .order('id')
          .range(offset, offset + 199);
      rows.addAll(page);
      if (page.length < 200) return rows;
    }
  }

  @override
  Future<void> saveReport(
    String workout,
    DevelopmentRow values,
    bool exists,
  ) async {
    if (exists) {
      await client
          .from('session_reports')
          .update(values)
          .eq('workout_id', workout)
          .select()
          .single();
    } else {
      await client.from('session_reports').insert({
        'workout_id': workout,
        ...values,
      });
    }
  }

  @override
  Future<void> saveReview(
    String video,
    DevelopmentRow values,
    bool exists,
  ) async {
    if (exists) {
      await client
          .from('video_reviews')
          .update(values)
          .eq('video_id', video)
          .select()
          .single();
    } else {
      await client.from('video_reviews').insert({'video_id': video, ...values});
    }
  }
}

DevelopmentRow? singleRelated(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is List && value.isNotEmpty) {
    return Map<String, dynamic>.from(value.first);
  }
  return null;
}

String developmentError(Object error) {
  if (error is PostgrestException &&
      ['42P01', '42703', 'PGRST200', 'PGRST205'].contains(error.code)) {
    return 'Falta activar el seguimiento en Supabase. Pide al administrador aplicar la migración 005.';
  }
  return 'No se pudo completar la operación. Revisa tu conexión y permisos; actualiza antes de reintentar.';
}
