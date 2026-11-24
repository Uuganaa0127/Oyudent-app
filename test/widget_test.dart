import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyudent/main.dart';

void main() {
  testWidgets('Mongolian phone navigation and top profile', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    await t.pumpWidget(const OyudentApp());
    await t.pumpAndSettle();
    expect(find.text('Нүүр'), findsOneWidget);
    await t.tap(find.byTooltip('Миний профайл'));
    await t.pumpAndSettle();
    expect(find.text('Миний профайл'), findsOneWidget);
    await t.tap(find.text('Миний цаг').last);
    await t.pumpAndSettle();
    expect(find.text('Хуваарь'), findsOneWidget);
    await t.binding.setSurfaceSize(null);
  });
  testWidgets('Catalog separates sample active and completed courses', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1200, 1200));
    await t.pumpWidget(const OyudentApp());
    await t.tap(find.text('Сургалт').last);
    await t.pumpAndSettle();
    expect(find.text('Сургалтын сан'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Бүртгүүлсэн'), findsNothing);
    await t.tap(find.widgetWithText(OutlinedButton, 'Миний сургалтууд'));
    await t.pumpAndSettle();
    expect(find.text('Бүртгүүлсэн'), findsOneWidget);
    expect(find.text('Хүлээгдэж буй'), findsOneWidget);
    expect(find.text('Цахим сургалтууд'), findsNothing);
    await t.tap(find.text('Дууссан'));
    await t.pumpAndSettle();
    await t.tap(find.text('Гэрчилгээ үзэх'));
    await t.pumpAndSettle();
    expect(find.text('Сургалт дүүргэсэн гэрчилгээ'), findsOneWidget);
    await t.binding.setSurfaceSize(null);
  });
  testWidgets('Stories open and course detail reflects application', (t) async {
    await t.binding.setSurfaceSize(const Size(1200, 1400));
    await t.pumpWidget(const OyudentApp());
    await t.pumpAndSettle();
    await t.tap(find.text('Дэлгүүр'));
    await t.pumpAndSettle();
    expect(find.text('OYUDENT • СТОРИ'), findsWidgets);
    await t.tap(find.text('Хаах'));
    await t.pumpAndSettle();
    await t.tap(find.text('Сургалт').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Шүдний эмнэлгийн менежмент'));
    await t.pumpAndSettle();
    expect(find.text('Сургалтын дэлгэрэнгүй'), findsOneWidget);
    await t.tap(find.text('Сургалтад бүртгүүлэх'));
    await t.pumpAndSettle();
    await t.tap(find.text('Баталгаажуулах • ${String.fromCharCode(36)}49.00'));
    await t.pumpAndSettle();
    expect(find.text('Бүртгүүлсэн'), findsOneWidget);
    await t.binding.setSurfaceSize(null);
  });
  testWidgets(
    'Course search button filters slide cards and empty arrows are safe',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 1400));
      await t.pumpWidget(const OyudentApp());
      await t.tap(find.text('Сургалт').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Сургалт хайх'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).last, 'менежмент');
      await t.tap(find.widgetWithText(FilledButton, 'Хайх'));
      await t.pumpAndSettle();
      expect(find.text('Шүдний эмнэлгийн менежмент'), findsOneWidget);
      expect(find.text('Шүдний эмнэлгийн гэрэл зураг'), findsNothing);
      expect(find.byTooltip('Дараах карт'), findsNothing);
      await t.binding.setSurfaceSize(null);
    },
  );
  testWidgets('Cards slide with a finger without arrow buttons', (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HorizontalShelf(
            children: List.generate(
              3,
              (i) => SizedBox(height: 150, child: Text('Card $i')),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final before = t.getCenter(find.text('Card 0')).dx;
    await t.drag(find.byType(ListView), const Offset(-270, 0));
    await t.pumpAndSettle();
    expect(t.getCenter(find.text('Card 1')).dx, lessThan(before + 200));
    expect(find.byTooltip('Дараах карт'), findsNothing);
    await t.binding.setSurfaceSize(null);
  });
}
