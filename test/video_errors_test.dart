import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_kks_academy/video_store.dart';

void main() {
  test(
    'Missing video setup is distinguished from permissions and network errors',
    () {
      expect(
        videoLoadError(
          const PostgrestException(
            message: 'internal details',
            code: 'PGRST205',
          ),
        ),
        contains('aún no está habilitado'),
      );
      expect(
        videoLoadError(
          const PostgrestException(message: 'internal details', code: '42501'),
        ),
        contains('no tiene permiso'),
      );
      expect(
        videoLoadError(
          const PostgrestException(
            message: 'internal details',
            code: 'PGRST301',
          ),
        ),
        contains('sesión necesita renovarse'),
      );
      expect(
        videoLoadError(Exception('internal details')),
        contains('conexión'),
      );
      expect(
        videoLoadError(Exception('internal details')),
        isNot(contains('internal details')),
      );
    },
  );
}
