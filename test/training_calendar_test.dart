import 'package:app_kks_academy/academy_theme.dart';
import 'package:app_kks_academy/training_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder dateCell(DateTime date) =>
    find.byKey(ValueKey('training-day-${date.year}-${date.month}-${date.day}'));

Future<void> calendar(
  WidgetTester tester,
  DateTime initial, {
  Set<DateTime> workouts = const {},
}) async {
  var selected = initial;
  await tester.pumpWidget(
    MaterialApp(
      theme: academyTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (context, setState) => TrainingCalendar(
                selectedDate: selected,
                workoutDays: workouts,
                onSelected: (date) => setState(() => selected = date),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Week shows seven days across months and marks scheduled days', (
    tester,
  ) async {
    final selected = DateTime(2026, 10, 1);
    await calendar(
      tester,
      selected,
      workouts: {selected, DateTime(2026, 10, 2)},
    );
    expect(find.text('OCTUBRE 2026'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is InkWell && w.key.toString().contains('training-day-'),
      ),
      findsNWidgets(7),
    );
    expect(dateCell(DateTime(2026, 9, 28)), findsOneWidget);
    expect(dateCell(DateTime(2026, 10, 4)), findsOneWidget);
    expect(
      find.byKey(const ValueKey('training-dot-2026-10-1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('training-dot-2026-10-3')), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.selected == true &&
            (widget.properties.label ?? '').contains('1 octubre 2026'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Swipe and week arrows cross year boundaries; Hoy repositions', (
    tester,
  ) async {
    await calendar(tester, DateTime(2026, 12, 31));
    await tester.fling(
      find.byKey(const ValueKey('training-week-strip')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('ENERO 2027'), findsOneWidget);
    expect(dateCell(DateTime(2027, 1, 7)), findsOneWidget);
    await tester.tap(find.byTooltip('Semana anterior'));
    await tester.pumpAndSettle();
    expect(find.text('DICIEMBRE 2026'), findsOneWidget);
    await tester.tap(find.text('Hoy'));
    await tester.pumpAndSettle();
    expect(dateCell(DateTime.now()), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
  });

  testWidgets('Month navigation handles leap day and collapses on selection', (
    tester,
  ) async {
    await calendar(tester, DateTime(2024, 3, 1));
    await tester.tap(find.text('Ver mes ›'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('FEBRERO 2024'), findsOneWidget);
    expect(dateCell(DateTime(2024, 2, 29)), findsOneWidget);
    expect(dateCell(DateTime(2024, 2, 30)), findsNothing);
    await tester.tap(dateCell(DateTime(2024, 2, 29)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('training-month-grid')), findsNothing);
    expect(find.text('FEBRERO 2024'), findsOneWidget);
    expect(dateCell(DateTime(2024, 2, 29)), findsOneWidget);
  });

  testWidgets('Calendar fits a narrow phone in weekly and monthly modes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await calendar(tester, DateTime(2026, 10, 1));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Ver mes ›'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(dateCell(DateTime(2026, 10, 31)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
