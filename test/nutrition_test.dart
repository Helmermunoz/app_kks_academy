import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_kks_academy/nutrition_page.dart';
import 'package:app_kks_academy/nutrition_store.dart';

class MemoryNutrition implements NutritionStore {
  final rows = <NutritionRecord>[];
  NutritionRecord? savedProfile;
  @override
  Future<NutritionRecord?> profile(String athlete) async => savedProfile;
  @override
  Future<List<NutritionRecord>> measurements(String athlete) async => [...rows];
  @override
  Future<void> addMeasurement(String athlete, NutritionRecord values) async {
    rows.add({...values, 'athlete_id': athlete});
  }

  @override
  Future<void> saveProfile(
    String athlete,
    NutritionRecord values, {
    required bool exists,
  }) async {
    savedProfile = values;
  }
}

void main() {
  test(
    'Measurements accept decimal comma and reject invalid report entries',
    () {
      expect(parseMeasurement(' 18,5 '), 18.5);
      expect(validateMeasurement('weight_kg', ''), isNotNull);
      expect(validateMeasurement('weight_kg', 'NaN'), isNotNull);
      expect(validateMeasurement('body_fat_percent', '101'), isNotNull);
      expect(validateMeasurement('fat_mass_kg', '90', weight: 80), isNotNull);
      expect(validateMeasurement('body_fat_percent', ''), isNull);
      expect(
        validateMeasurement('skeletal_muscle_kg', '35,7', weight: 80),
        isNull,
      );
    },
  );
  testWidgets('New evaluations append history and persist entered values', (
    tester,
  ) async {
    final store = MemoryNutrition();
    store.rows.add({
      'measured_on': '2026-01-01',
      'weight_kg': 80,
      'body_fat_percent': 18,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: NutritionPage(store: store, athlete: 'a', athleteName: 'Alex'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar medición InBody'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('weight_kg')), '81,2');
    await tester.enterText(
      find.byKey(const ValueKey('body_fat_percent')),
      '17,5',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(store.rows.length, 2);
    expect(store.rows.last['athlete_id'], 'a');
    expect(store.rows.last['weight_kg'], 81.2);
    expect(store.rows.last['body_fat_percent'], 17.5);
    expect(store.rows.last['basal_kcal'], isNull);
    expect(
      find.text('Historial · hasta 500 mediciones recientes'),
      findsOneWidget,
    );
  });
  testWidgets('Failed save preserves the form and values', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NutritionForm(
            measurement: true,
            save: (_) async => throw Exception('offline'),
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('weight_kg')), '80');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo guardar'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
  });
  testWidgets('Nutrition page fits narrow screens and optional chart fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryNutrition();
    store.rows.addAll([
      {'measured_on': '2026-01-01', 'weight_kg': 80},
      {'measured_on': '2026-02-01', 'weight_kg': 81},
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: NutritionPage(store: store, athlete: 'a', athleteName: 'Alex'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
