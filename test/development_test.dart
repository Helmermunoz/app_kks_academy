import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_kks_academy/development_page.dart';
import 'package:app_kks_academy/development_store.dart';

class FakeDevelopment implements DevelopmentStore {
  bool fail = false;
  DevelopmentRow? saved;
  List<DevelopmentRow> rows = [];
  @override
  Future<List<DevelopmentRow>> sessions(String from, String through) async =>
      rows;
  @override
  Future<void> saveReport(
    String workout,
    DevelopmentRow values,
    bool exists,
  ) async {
    if (fail) throw Exception('offline');
    saved = values;
  }

  @override
  Future<void> saveReview(
    String video,
    DevelopmentRow values,
    bool exists,
  ) async {
    if (fail) throw Exception('offline');
    saved = values;
  }
}

DevelopmentRow session(
  String id, {
  DevelopmentRow? report,
  List<DevelopmentRow> clips = const [],
}) => {
  'id': id,
  'athlete_id': 'a',
  'day': '2026-09-24',
  'title': id,
  'kind': 'bullpen',
  'throwing_plan': '20 rectas',
  'session_reports': report,
  'session_videos': clips,
  'workout_completions': null,
};

Future<void> enter(WidgetTester tester, String label, String value) async {
  final target = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(target);
  await tester.enterText(target, value);
}

void main() {
  testWidgets(
    'Report rejects excess strikes and retains input after failed save',
    (tester) async {
      final store = FakeDevelopment()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionReportDialog(
              session: session('Bullpen'),
              store: store,
            ),
          ),
        ),
      );
      await enter(tester, 'Lanzamientos realizados (opcional)', '20');
      await enter(tester, 'Strikes (opcional)', '21');
      await enter(tester, 'Esfuerzo percibido, 1 a 10', '7');
      await tester.tap(find.text('Guardar resultados'));
      await tester.pumpAndSettle();
      expect(
        find.text('Los strikes no pueden superar los lanzamientos'),
        findsOneWidget,
      );
      expect(store.saved, isNull);
      await enter(tester, 'Strikes (opcional)', '15');
      await enter(tester, 'Velocidad con radar, mph (opcional)', '90,5');
      await tester.tap(find.text('Guardar resultados'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No se pudo completar'), findsOneWidget);
      expect(find.text('90,5'), findsOneWidget);
      store.fail = false;
      await tester.tap(find.text('Guardar resultados'));
      await tester.pumpAndSettle();
      expect(store.saved?['velocity_mph'], 90.5);
      expect(store.saved?['strikes'], 15);
      expect(store.saved?['planned_pitches'], isNull);
    },
  );

  testWidgets(
    'Dashboard counts only measured strike denominators and filters pending videos',
    (tester) async {
      final store = FakeDevelopment()
        ..rows = [
          session(
            'Reviewed session',
            report: {'effort': 3, 'actual_pitches': 20, 'strikes': 10},
            clips: [
              {
                'id': 'v1',
                'title': 'Reviewed clip',
                'video_reviews': {'status': 'reviewed'},
              },
            ],
          ),
          session(
            'Pending session',
            report: {'effort': 5, 'actual_pitches': 30, 'strikes': null},
            clips: [
              {'id': 'v2', 'title': 'Pending clip', 'video_reviews': null},
            ],
          ),
        ];
      await tester.pumpWidget(
        MaterialApp(
          home: DevelopmentPage(
            store: store,
            staff: true,
            athletes: const {'a': 'Alex'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('50.0% strikes'), findsOneWidget);
      expect(find.text('50 lanzamientos registrados'), findsOneWidget);
      expect(find.text('1 videos sin revisar'), findsOneWidget);
      await tester.ensureVisible(find.text('Videos por revisar'));
      await tester.tap(find.text('Videos por revisar'));
      await tester.pumpAndSettle();
      expect(find.text('Reviewed session'), findsNothing);
      expect(find.text('Pending session'), findsOneWidget);
    },
  );

  testWidgets('Athlete sees correction but cannot edit the review', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoReviewDialog(
            clip: {
              'id': 'v',
              'title': 'Bullpen',
              'video_reviews': {
                'status': 'work_on',
                'notes': 'Revisar postura',
                'at_seconds': 12,
              },
            },
            store: FakeDevelopment(),
            canEdit: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Revisar postura'), findsOneWidget);
    expect(find.text('Segundo 12 del video'), findsOneWidget);
    expect(find.text('Guardar revisión'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('Coach review survives failed save and validates correction', (
    tester,
  ) async {
    final store = FakeDevelopment()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoReviewDialog(
            clip: {
              'id': 'v',
              'title': 'Bullpen',
              'video_reviews': {'status': 'work_on'},
            },
            store: store,
            canEdit: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar revisión'));
    await tester.pumpAndSettle();
    expect(find.text('Describe la corrección'), findsOneWidget);
    await enter(tester, 'Observación del entrenador', 'Revisar apoyo');
    await enter(tester, 'Segundo del video (opcional)', '12');
    await tester.tap(find.text('Guardar revisión'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar apoyo'), findsOneWidget);
    expect(find.textContaining('No se pudo completar'), findsOneWidget);
  });

  testWidgets('Report fits narrow phone screen without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionReportDialog(
            session: session('Bullpen'),
            store: FakeDevelopment(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await enter(tester, 'Esfuerzo percibido, 1 a 10', '6');
    await tester.ensureVisible(find.text('Hubo molestias'));
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Guardar resultados'));
    await tester.pumpAndSettle();
    expect(find.text('Describe las molestias para el equipo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
