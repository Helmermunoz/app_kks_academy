import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_kks_academy/academy_repository.dart';
import 'package:app_kks_academy/main.dart';

class FakeAcademy extends AcademyRepository {
  String? current = 'athlete-a';
  String role = 'athlete';
  bool failSave = false;
  bool failLoad = false;
  bool temporary = false;
  final events = StreamController<String?>.broadcast();
  final done = <String>{};
  final rows = <Record>[
    {
      'id': 'workout-a',
      'athlete_id': 'athlete-a',
      'day': '2026-09-23',
      'title': 'Control de lanzamiento',
      'instructions': '3 series de 10 repeticiones. Descansa 60 segundos.',
    },
  ];
  @override
  String? get userId => current;
  @override
  Stream<String?> get sessions => events.stream;
  @override
  Future<void> signIn(String email, String password) async {
    current = 'athlete-a';
    events.add(current);
  }

  @override
  Future<void> signOut() async {
    current = null;
    events.add(null);
  }

  @override
  Future<Record> profile() async {
    if (failLoad) throw Exception('offline');
    return {
      'id': current,
      'name': 'Alex',
      'role': role,
      'must_change_password': temporary,
    };
  }

  @override
  Future<List<Record>> people() async => [
    {'id': 'athlete-a', 'name': 'Alex', 'role': 'athlete'},
    if (role == 'admin')
      {'id': 'coach-a', 'name': 'Entrenador A', 'role': 'coach'},
  ];
  @override
  Future<List<Record>> assignments() async => [];
  @override
  Future<void> assign(String coach, String athlete, bool assigned) async {}
  @override
  Future<void> changePassword(String password) async {
    temporary = false;
  }

  @override
  Future<void> createAccount(
    String name,
    String email,
    String password,
    String role,
  ) async {}
  @override
  Future<List<Record>> workouts(String athlete) async =>
      rows.where((r) => r['athlete_id'] == athlete).toList();
  @override
  Future<Set<String>> completions(String athlete) async => {...done};
  @override
  Future<void> complete(String athlete, String workout, bool value) async {
    if (failSave) throw Exception('offline');
    value ? done.add(workout) : done.remove(workout);
  }

  @override
  Future<void> saveWorkout(
    String athlete,
    String? id,
    String day,
    String title,
    String instructions,
  ) async {
    if (failSave) throw Exception('offline');
    rows.add({
      'id': 'new',
      'athlete_id': athlete,
      'day': day,
      'title': title,
      'instructions': instructions,
    });
  }
}

void main() {
  late FakeAcademy repo;
  setUp(() {
    repo = FakeAcademy();
  });
  tearDown(() async {
    await repo.events.close();
  });

  testWidgets(
    'Missing configuration never presents a private account as active',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.text('Estamos preparando tu academia'), findsOneWidget);
      expect(find.text('Explorar demostración'), findsOneWidget);
      expect(find.text('Control de lanzamiento'), findsNothing);
    },
  );

  testWidgets(
    'Athlete can persist completion and sign out without staff controls',
    (tester) async {
      await tester.pumpWidget(MyApp(repository: repo));
      await tester.pumpAndSettle();
      expect(find.text('Agregar entrenamiento'), findsNothing);
      expect(find.text('Crear cuenta'), findsNothing);
      await tester.ensureVisible(find.text('Completé mi entrenamiento'));
      await tester.tap(find.text('Completé mi entrenamiento'));
      await tester.pumpAndSettle();
      expect(repo.done, contains('workout-a'));
      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue,
      );
      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Control de lanzamiento'), findsNothing);
    },
  );

  testWidgets('Failed completion remains pending and can be retried', (
    tester,
  ) async {
    repo.failSave = true;
    await tester.pumpWidget(MyApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Completé mi entrenamiento'));
    await tester.tap(find.text('Completé mi entrenamiento'));
    await tester.pumpAndSettle();
    expect(repo.done, isEmpty);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    expect(find.textContaining('No se pudo guardar'), findsOneWidget);
  });

  testWidgets('Coach saves an assigned workout on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    repo.role = 'coach';
    repo.current = 'coach-a';
    await tester.pumpWidget(MyApp(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('Crear cuenta'), findsNothing);
    await tester.ensureVisible(find.text('Agregar entrenamiento'));
    await tester.tap(find.text('Agregar entrenamiento'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del entrenamiento'),
      'Movilidad',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ejercicios e indicaciones'),
      'Dos series de cinco repeticiones',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repo.rows.last['athlete_id'], 'athlete-a');
    expect(repo.rows.last['title'], 'Movilidad');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Temporary password blocks the plan until changed', (
    tester,
  ) async {
    repo.temporary = true;
    await tester.pumpWidget(MyApp(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('Elige tu contraseña personal'), findsOneWidget);
    expect(find.text('Control de lanzamiento'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nueva contraseña'),
      'new-password-123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar contraseña'),
      'new-password-123',
    );
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();
    expect(find.text('Control de lanzamiento'), findsOneWidget);
  });

  testWidgets('Loading failure offers retry without displaying old data', (
    tester,
  ) async {
    repo.failLoad = true;
    await tester.pumpWidget(MyApp(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    repo.failLoad = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Control de lanzamiento'), findsOneWidget);
  });
}
