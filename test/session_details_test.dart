import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_kks_academy/session_details.dart';
import 'package:app_kks_academy/academy_portal.dart';

void main() {
  testWidgets(
    'Therapy notice includes today and future, excludes completed and past',
    (tester) async {
      final now = DateTime.now();
      String date(int offset) => DateTime(
        now.year,
        now.month,
        now.day + offset,
      ).toIso8601String().substring(0, 10);
      Map<String, dynamic> session(String id, int offset, String kind) => {
        'id': id,
        'kind': kind,
        'day': date(offset),
        'title': id,
        'start_time': '16:30:00',
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TherapyNotice(
              sessions: [
                session('Cita hoy', 0, 'therapy'),
                session('Cita futura', 5, 'therapy'),
                session('Cita pasada', -1, 'therapy'),
                session('Cita completa', 0, 'therapy'),
                session('Otra sesión', 0, 'track'),
              ],
              completed: const {'Cita completa'},
            ),
          ),
        ),
      );
      expect(find.text('Terapia agendada'), findsOneWidget);
      expect(find.textContaining('Cita hoy'), findsOneWidget);
      expect(find.textContaining('Cita futura'), findsOneWidget);
      expect(find.textContaining('Cita pasada'), findsNothing);
      expect(find.textContaining('Cita completa'), findsNothing);
      expect(find.textContaining('Otra sesión'), findsNothing);
    },
  );

  testWidgets(
    'Editing bullpen preserves its location, hour and throwing plan',
    (tester) async {
      Map<String, dynamic>? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutDialog(
              workout: const {
                'id': 'w',
                'kind': 'bullpen',
                'day': '2026-09-23',
                'title': 'Control',
                'instructions': 'Trabajo asignado',
                'location': 'Campo 2',
                'start_time': '17:15:00',
                'throwing_plan': 'Plan indicado por el entrenador',
              },
              save: (day, title, instructions, details) async {
                saved = details;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(saved?['kind'], 'bullpen');
      expect(saved?['location'], 'Campo 2');
      expect(saved?['start_time'], '17:15');
      expect(saved?['throwing_plan'], 'Plan indicado por el entrenador');
    },
  );
}
