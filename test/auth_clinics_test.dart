import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyudent/auth_page.dart';
import 'package:oyudent/work_hub.dart';

void main() {
  testWidgets('Auth validates inputs and switches to registration on phone', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(320, 740));
    await t.pumpWidget(const MaterialApp(home: AuthPage()));
    await t.tap(find.widgetWithText(FilledButton, 'Нэвтрэх'));
    await t.pumpAndSettle();
    expect(find.text('Зөв имэйл оруулна уу'), findsOneWidget);
    expect(find.text('8–128 тэмдэгт оруулна уу'), findsOneWidget);
    await t.ensureVisible(find.text('Шинэ хэрэглэгч үү? Бүртгүүлэх'));
    await t.pumpAndSettle();
    await t.tap(find.text('Шинэ хэрэглэгч үү? Бүртгүүлэх'));
    await t.pumpAndSettle();
    expect(find.text('Бүртгэл үүсгэх'), findsOneWidget);
    for (final label in [
      'Утасны дугаар',
      'Регистрийн дугаар',
      'Овог',
      'Нэр',
      'Имэйл',
      'Албан тушаал',
      'Нууц үг давтах',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    final fields = find.byType(TextFormField);
    await t.enterText(fields.at(5), 'password123');
    await t.enterText(fields.at(6), 'different123');
    await t.ensureVisible(find.widgetWithText(FilledButton, 'Бүртгүүлэх'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Бүртгүүлэх'));
    await t.pumpAndSettle();
    expect(find.text('Нууц үг таарахгүй байна'), findsOneWidget);
    expect(find.text('Албан тушаалаа сонгоно уу'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.binding.setSurfaceSize(null);
  });
  testWidgets('Clinic invitations are separate from patient requests', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(390, 1000));
    await t.pumpWidget(
      const MaterialApp(home: Scaffold(body: WorkHub(calendar: true))),
    );
    await t.tap(find.text('Миний эмнэлгүүд'));
    await t.pumpAndSettle();
    expect(find.text('Нэвтрэх / Бүртгүүлэх'), findsOneWidget);
    expect(find.text('Эмнэлгээс ирсэн хүсэлтүүд'), findsNothing);
    await t.binding.setSurfaceSize(null);
  });
}
