import 'package:app_kks_academy/academy_portal.dart';
import 'package:app_kks_academy/nutrition_proposals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryProposals implements ProposalStore {
  bool qualified = false;
  final rows = <Map<String, dynamic>>[];
  final pending = <Map<String, dynamic>>[];
  final reviews = <String>[];
  @override
  Future<List<Map<String, dynamic>>> proposals(String athlete) async => rows;
  @override
  Future<List<Map<String, dynamic>>> jobs(String athlete) async => pending;
  @override
  Future<bool> qualifiedReviewer() async => qualified;
  @override
  Future<void> generate(String job) async {
    rows.add(proposal('mock'));
    pending.clear();
  }

  @override
  Future<void> review(String proposal, bool approve, String notes) async {
    reviews.add(notes);
    rows.first['status'] = approve ? 'approved' : 'rejected';
  }
}

Map<String, dynamic> proposal(String mode) => {
  'id': 'p',
  'status': 'draft',
  'generation_mode': mode,
  'source_workout_version': 2,
  'generated_at': '2026-10-11',
  'content': {
    'meals': [
      {'suggestion': 'Example meal', 'timing': 'Review timing'},
    ],
    'hydration': 'General',
    'recovery': 'Rest',
    'review_warning': 'Professional review required',
  },
};

void main() {
  testWidgets('Mock job creates a draft that qualified staff cannot approve', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryProposals()..qualified = true;
    store.pending.add({
      'id': 'j',
      'status': 'pending',
      'workout_version': 2,
      'attempts': 0,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: NutritionProposalsPage(store: store, athlete: 'a', staff: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Procesar trabajo pendiente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('EJEMPLO DE PRUEBA'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Aprobar'))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Athlete has no queue or review controls; qualified professional submits notes',
    (tester) async {
      final store = MemoryProposals()..rows.add(proposal('live'));
      await tester.pumpWidget(
        MaterialApp(
          home: NutritionProposalsPage(
            store: store,
            athlete: 'a',
            staff: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aprobar'), findsNothing);
      expect(find.byTooltip('Procesar trabajo pendiente'), findsNothing);
      store.qualified = true;
      await tester.pumpWidget(
        MaterialApp(
          home: NutritionProposalsPage(
            key: const ValueKey('reviewer'),
            store: store,
            athlete: 'a',
            staff: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Aprobar'));
      await tester.tap(find.text('Aprobar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Ingredients and timing reviewed',
      );
      await tester.tap(find.text('Confirmar revisión'));
      await tester.pumpAndSettle();
      expect(store.reviews.single, 'Ingredients and timing reviewed');
      expect(find.textContaining('approved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Workout preserves structured schedule and draft publication state',
    (tester) async {
      Map<String, dynamic>? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkoutDialog(
              nutritionEnabled: true,
              workout: {
                'day': '2026-10-11',
                'kind': 'training',
                'title': 'Mobility',
                'instructions': 'General mobility',
                'location': 'Field',
                'start_time': '16:30:00',
                'duration_minutes': 45,
                'intensity': 'moderate',
                'publication_status': 'draft',
              },
              save: (_, _, _, details) async => saved = details,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(saved?['duration_minutes'], 45);
      expect(saved?['intensity'], 'moderate');
      expect(saved?['publication_status'], 'draft');
    },
  );
}
