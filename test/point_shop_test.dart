import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oyudent/main.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('Daily check-in persists and cannot be claimed twice', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 1000));
    await t.pumpWidget(const OyudentApp());
    await t.pumpAndSettle();
    await t.tap(find.text('Оноо'));
    await t.pumpAndSettle();
    await t.tap(find.text('Өнөөдөр бүртгүүлэх • +25 оноо'));
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await t.tap(find.text('25 оноо авах'));
    await t.pumpAndSettle();
    await t.tap(find.text('Боллоо'));
    await t.pumpAndSettle();
    expect(find.text('✦ 275'), findsOneWidget);
    expect(find.text('Өнөөдрийн +25 оноог авсан'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(const OyudentApp());
    await t.pumpAndSettle();
    await t.tap(find.text('Оноо'));
    await t.pumpAndSettle();
    expect(find.text('✦ 275'), findsOneWidget);
    final button = t.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Өнөөдрийн +25 оноог авсан'),
    );
    expect(button.onPressed, isNull);
    expect(t.takeException(), isNull);
    await t.binding.setSurfaceSize(null);
  });
  testWidgets('Cart checks total, removes items, and redeems once', (t) async {
    await t.binding.setSurfaceSize(const Size(1200, 1800));
    await t.pumpWidget(const OyudentApp());
    await t.pumpAndSettle();
    await t.tap(find.text('Оноо'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Сагсанд нэмэх').first);
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Сагсанд нэмэх').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Сагс (2)'));
    await t.pumpAndSettle();
    expect(find.text('Нийт: 280 оноо'), findsOneWidget);
    expect(
      t
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Оноогоор баталгаажуулах'),
          )
          .onPressed,
      isNull,
    );
    await t.tap(find.byTooltip('Сагснаас хасах').last);
    await t.pumpAndSettle();
    expect(find.text('Нийт: 100 оноо'), findsOneWidget);
    await t.tap(find.text('Оноогоор баталгаажуулах'));
    await t.pumpAndSettle();
    expect(find.text('✦ 150'), findsOneWidget);
    expect(find.text('Сагс (0)'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Авсан'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.binding.setSurfaceSize(null);
  });
}
