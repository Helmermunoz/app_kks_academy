import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_kks_academy/academy_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  for (final scenario in ['material', 'unchanged', 'function_unavailable']) {
    test(
      'Publication processing: $scenario',
      () async {
        var saves = 0, invocations = 0;
        final processed = Completer<void>();
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((request) async {
          await request.drain<void>();
          request.response.headers.contentType = ContentType.json;
          final path = request.uri.path;
          Object response;
          if (path.endsWith('/workouts') && request.method == 'GET') {
            response = {'version': 1};
          } else if (path.endsWith('/workouts')) {
            saves++;
            response = {
              'id': 'workout-test',
              'version': scenario == 'unchanged' ? 1 : 2,
              'publication_status': 'published',
            };
          } else if (path.endsWith('/nutrition_jobs')) {
            response = {'id': 'job-test'};
          } else if (path.endsWith('/nutrition-assistant')) {
            invocations++;
            request.response.statusCode = scenario == 'function_unavailable'
                ? 503
                : 200;
            response = {'status': 'test_response'};
          } else {
            request.response.statusCode = 404;
            response = {'error': 'unexpected_path'};
          }
          request.response.write(jsonEncode(response));
          await request.response.close();
          if (path.endsWith('/nutrition-assistant') && !processed.isCompleted) {
            processed.complete();
          }
        });
        final client = SupabaseClient(
          'http://127.0.0.1:${server.port}',
          'sb_publishable_test_fixture',
        );
        addTearDown(() async {
          await client.dispose();
          await server.close(force: true);
        });
        await SupabaseAcademyRepository(client).saveWorkout(
          'athlete-test',
          'workout-test',
          '2026-10-11',
          'General',
          'Mobility',
        );
        expect(saves, 1);
        if (scenario != 'unchanged') {
          await processed.future.timeout(const Duration(seconds: 5));
          expect(invocations, 1);
        } else {
          expect(invocations, 0);
        }
      },
      skip: !nutritionAssistantEnabled
          ? 'Run with --dart-define=ENABLE_NUTRITION_ASSISTANT=true'
          : false,
    );
  }
}
