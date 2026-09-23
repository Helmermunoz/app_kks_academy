import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_kks_academy/main.dart';

void main() {
  testWidgets('Mobile calendar switches to rest day without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Jue'));
    await tester.tap(find.text('Jue'));
    await tester.pumpAndSettle();
    expect(find.text('Recuperación'), findsOneWidget);
    expect(find.text('Completé mi entrenamiento'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Completing a workout preserves progress across day changes', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Completé mi entrenamiento'));
    await tester.tap(find.text('Completé mi entrenamiento'));
    await tester.pumpAndSettle();
    expect(find.text('1 de 5 entrenamientos completados'), findsOneWidget);
    await tester.ensureVisible(find.text('Mar'));
    await tester.tap(find.text('Mar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lun'));
    await tester.pumpAndSettle();
    expect(find.text('Desmarcar entrenamiento'), findsOneWidget);
  });
}
