import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyudent/production_api.dart';
import 'package:oyudent/production_app.dart';

class _FakeApi extends ProductionApi {
  final calls = <String>[];
  final submissions = <Record>[];

  @override
  bool get signedIn => true;

  @override
  Future<Record> submit(
    String path,
    Record body, {
    bool authenticated = true,
  }) async {
    calls.add(path);
    submissions.add(body);
    return {
      'status_code': 'PENDING',
      'amount': 12000,
      'invoice_no': 'TEST-INVOICE',
      'bank_account_number': '000000',
    };
  }

  @override
  Future<Record?> restore() async => null;

  @override
  Future<List<Record>> list(String path, {bool authenticated = false}) async {
    final uri = Uri.parse(path);
    calls.add(path);
    return switch (uri.path) {
      'banner/list' => [
        {'id': 'banner', 'title': 'Oyudent banner'},
      ],
      'partner/list' => [
        {'id': 'brand', 'name': 'Test brand'},
      ],
      'product/list' => [
        {'id': 'product', 'name': 'Test product'},
      ],
      'course/no/list' => [
        {'id': 'onsite', 'title': 'Test workshop'},
      ],
      'course/price/list' => [
        {'id': 'price', 'name': 'Үндсэн багц', 'price': 80000},
      ],
      'training/catalog' => [
        {
          'id': 'training',
          'title': 'Test course',
          'is_point_payable': true,
          'price_point': 250,
        },
      ],
      'news/list' => [
        {'id': 'news', 'title': 'Test news'},
      ],
      _ => [],
    };
  }

  @override
  Future<Record> detail(String path, {bool authenticated = false}) async {
    calls.add(path);
    if (path == 'course/detail/onsite') {
      return {
        'id': 'onsite',
        'title': 'Test workshop',
        'is_active_registered': true,
      };
    }
    if (path == 'doctor/point/balance') return {'balance': 375};
    if (path == 'training/catalog/training') {
      return {
        'course': {
          'id': 'training',
          'title': 'Test course',
          'is_cash_payable': true,
          'price': 12000,
        },
      };
    }
    return {'name': 'Test product', 'description': 'Product API details'};
  }
}

void main() {
  testWidgets('Native home loads news and opens a product detail', (
    tester,
  ) async {
    final api = _FakeApi();
    await tester.pumpWidget(OyudentProductionApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('Oyudent banner'), findsOneWidget);
    final homeScroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const PageStorageKey('oyudent-home')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    for (
      var step = 0;
      step < 5 && find.text('Test news').evaluate().isEmpty;
      step++
    ) {
      homeScroll.position.jumpTo(homeScroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
    }
    expect(find.text('Test news'), findsOneWidget);
    homeScroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бүтээгдэхүүн').first);
    await tester.pumpAndSettle();
    expect(
      api.calls.any((path) => path.contains('is_show_landing=true')),
      isTrue,
    );
    await tester.tap(find.text('Test product'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('product/product'));
    expect(find.text('Product API details'), findsOneWidget);
  });
  testWidgets(
    'Training order requires confirmation and shows the server invoice',
    (tester) async {
      final api = _FakeApi();
      await tester.pumpWidget(OyudentProductionApp(api: api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сургалт'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test course'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сургалт авах'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Банкны шилжүүлэг · 12000 ₮'));
      await tester.pumpAndSettle();
      expect(api.submissions, isEmpty);
      await tester.tap(find.text('Баталгаажуулах'));
      await tester.pumpAndSettle();
      expect(api.submissions.single, {
        'courseId': 'training',
        'paymentType': 'CASH',
      });
      expect(find.text('TEST-INVOICE'), findsOneWidget);
    },
  );
  testWidgets('Points navigation shows the API balance and eligible courses', (
    tester,
  ) async {
    final api = _FakeApi();
    await tester.pumpWidget(OyudentProductionApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Оноо'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('doctor/point/balance'));
    expect(find.text('375'), findsOneWidget);
    expect(find.text('250 оноо'), findsOneWidget);
    expect(find.text('Бренд'), findsNothing);
  });
  testWidgets('Open classroom course submits the chosen registration package', (
    tester,
  ) async {
    final api = _FakeApi();
    await tester.pumpWidget(OyudentProductionApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Танхимын сургалт').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test workshop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бүртгүүлэх'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Үндсэн багц · 80000 ₮'));
    await tester.pumpAndSettle();
    expect(api.submissions, isEmpty);
    await tester.tap(find.text('Баталгаажуулах'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('enrollment/'));
    expect(api.submissions.single, {
      'courseId': 'onsite',
      'coursePriceId': 'price',
    });
  });
}
