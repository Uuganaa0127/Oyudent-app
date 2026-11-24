import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyudent/work_hub.dart';

void main() {
  testWidgets('Week supports multiple patients and request acceptance', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1200, 1400));
    await t.pumpWidget(
      const MaterialApp(home: Scaffold(body: WorkHub(calendar: true))),
    );
    await t.pumpAndSettle();
    expect(find.text('Жишээ өвчтөн 4'), findsOneWidget);
    expect(find.text('Жишээ өвчтөн 8'), findsOneWidget);
    await t.tap(find.text('Өвчтөний хүсэлт (2)'));
    await t.pumpAndSettle();
    await t.tap(find.text('Хүлээн авах').first);
    await t.pumpAndSettle();
    expect(find.text('Жишээ өвчтөн 1'), findsOneWidget);
    await t.binding.setSurfaceSize(null);
  });
  testWidgets('Month view shows a calendar and supports month navigation', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(390, 1000));
    await t.pumpWidget(
      const MaterialApp(home: Scaffold(body: WorkHub(calendar: true))),
    );
    await t.tap(find.text('Сараар харах'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('month-grid')), findsOneWidget);
    final now = DateTime.now();
    expect(find.text('${now.year} он • ${now.month} сар'), findsOneWidget);
    await t.tap(find.byTooltip('Дараах сар'));
    await t.pumpAndSettle();
    final next = DateTime(now.year, now.month + 1);
    expect(find.text('${next.year} он • ${next.month} сар'), findsOneWidget);
    await t.binding.setSurfaceSize(null);
  });
}
