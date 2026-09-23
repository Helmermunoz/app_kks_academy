import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_kks_academy/main.dart';

Future<void> chooseDay(WidgetTester tester, String day) async {
  final chip = find.ancestor(
    of: find.text(day),
    matching: find.byType(ChoiceChip),
  );
  await Scrollable.ensureVisible(tester.element(chip), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Mobile calendar switches to rest day without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp(demo: true));
    await chooseDay(tester, 'Jue');
    expect(find.text('Recuperación'), findsOneWidget);
    expect(find.text('Completé mi entrenamiento'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Completing a workout preserves progress across day changes', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(demo: true));
    await tester.ensureVisible(find.text('Completé mi entrenamiento'));
    await tester.tap(find.text('Completé mi entrenamiento'));
    await tester.pumpAndSettle();
    expect(find.text('1 de 5 entrenamientos completados'), findsOneWidget);
    await chooseDay(tester, 'Mar');
    await chooseDay(tester, 'Lun');
    expect(find.text('Desmarcar entrenamiento'), findsOneWidget);
  });
}
