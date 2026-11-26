import 'package:flutter/material.dart';
import 'package:oyudent/device_workspace.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oyudent/production_api.dart';
import 'package:oyudent/production_app.dart';

class _FakeApi extends ProductionApi {
  @override
  String get localOwner => 'doctor/test';
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

class _CourseTestApi extends _FakeApi {
  bool loggedIn = false;
  @override
  bool get signedIn => loggedIn;
  @override
  Future<Record?> restore() async => loggedIn ? {'first_name': 'Тест'} : null;

  @override
  Future<Record> login(String phone, String password) async {
    loggedIn = true;
    return {'first_name': 'Тест'};
  }

  @override
  Future<List<Record>> list(String path, {bool authenticated = false}) async {
    final route = Uri.parse(path).path;
    if (route == 'training/certificate/list') {
      expect(authenticated, isTrue);
      return [
        {
          'id': 'issued',
          'course_id': 'mine',
          'certificate_no': 'OY-101',
          'course_title': 'Issued certificate',
        },
      ];
    }
    if (route == 'training/my/list' || route == 'enrollment/list') {
      expect(authenticated, isTrue);
      expect(signedIn, isTrue);
      return [
        {
          'course_id': 'mine',
          'course_title': route == 'enrollment/list'
              ? 'My workshop'
              : 'My online course',
        },
      ];
    }
    if (route == 'training/catalog') {
      return [
        {'id': 'training', 'title': 'First course'},
        {'id': 'other', 'title': 'Second course'},
      ];
    }
    if (route == 'course/no/list') {
      return [
        {'id': 'onsite', 'title': 'Open session', 'is_active_registered': true},
        {
          'id': 'closed',
          'title': 'Closed session',
          'is_active_registered': false,
        },
      ];
    }
    return super.list(path, authenticated: authenticated);
  }
}

class _NoOnsiteApi extends _FakeApi {
  @override
  Future<List<Record>> list(String path, {bool authenticated = false}) {
    if (Uri.parse(path).path == 'course/no/list') {
      return Future.value([
        {'id': 'past', 'title': 'Past workshop', 'is_active_registered': false},
      ]);
    }
    return super.list(path, authenticated: authenticated);
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('Home opens the banner, course stories and product details', (
    tester,
  ) async {
    final api = _FakeApi();
    await tester.pumpWidget(OyudentProductionApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oyudent banner'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test course').first);
    await tester.pumpAndSettle();
    expect(find.text('Сургалтын стори'), findsOneWidget);
    await tester.tap(find.byTooltip('Дараагийн стори'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Клиник кейс'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Test product'),
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('oyudent-home')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Test product')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test product'));
    await tester.pumpAndSettle();
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
      await tester.tap(find.text('Сургалтад бүртгүүлэх'));
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
    final search = find.widgetWithText(TextField, 'Онооны дэлгүүрээс хайх');
    await tester.enterText(search, 'other');
    await tester.pumpAndSettle();
    expect(find.text('250 оноо'), findsNothing);
    await tester.enterText(search, 'course');
    await tester.pumpAndSettle();
    final add = find.byTooltip('Сагсанд нэмэх');
    await Scrollable.ensureVisible(tester.element(add), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Сагс'));
    await tester.pumpAndSettle();
    expect(find.text('Нийт · 250 оноо'), findsOneWidget);
    await tester.tap(find.byTooltip('Сагснаас хасах'));
    await tester.pumpAndSettle();
    expect(find.text('Сагс хоосон'), findsOneWidget);
  });
  testWidgets('Shop filters apply category and point order together', (
    tester,
  ) async {
    await tester.pumpWidget(OyudentProductionApp(api: _FakeApi()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Оноо'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Дэлгүүрийн шүүлтүүр'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Бүтээгдэхүүн'));
    await tester.tap(find.text('Ихээс бага руу'));
    await tester.tap(find.text('Харуулах'));
    await tester.pumpAndSettle();
    expect(find.text('Бүтээгдэхүүн · 3'), findsOneWidget);
    expect(find.text('250 оноо'), findsNothing);
    final expected = ['5 бонус оноо', '3 бонус оноо', '1 бонус оноо'];
    final shown = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .where(expected.contains)
        .toList();
    expect(shown, expected);
  });

  testWidgets('Open classroom course submits the chosen registration package', (
    tester,
  ) async {
    final api = _FakeApi();
    await tester.pumpWidget(OyudentProductionApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сургалт'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Танхим'));
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
  testWidgets(
    'Slides navigate on a phone and classroom applications respect registration status',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _CourseTestApi()..loggedIn = true;
      await tester.pumpWidget(OyudentProductionApp(api: api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сургалт'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Дараагийн сургалт'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      await tester.tap(find.text('Танхим'));
      await tester.pumpAndSettle();
      expect(find.text('Closed session'), findsNothing);
      final card = find
          .ancestor(
            of: find.text('Open session'),
            matching: find.byType(InkWell),
          )
          .first;
      await tester.tap(
        find.descendant(of: card, matching: find.text('Бүртгүүлэх')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Бүртгэлийн багц'), findsOneWidget);
      expect(api.submissions, isEmpty);
    },
  );

  testWidgets(
    'My Courses resumes after sign-in and shows online and classroom records',
    (tester) async {
      final api = _CourseTestApi();
      await tester.pumpWidget(OyudentProductionApp(api: api));
      await tester.pumpAndSettle();
      final nav = find.byType(NavigationBar);
      expect(
        find.descendant(of: nav, matching: find.byType(NavigationDestination)),
        findsNWidgets(4),
      );
      expect(
        find.descendant(of: nav, matching: find.text('Миний сургалт')),
        findsNothing,
      );
      await tester.tap(find.text('Сургалт'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('browse-my-courses')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Миний сургалтыг үзэхийн тулд нэвтрэх'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Утасны дугаар'),
        '99000000',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Нууц үг'),
        'fixture',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Нэвтрэх'));
      await tester.pumpAndSettle();
      expect(find.text('My online course'), findsOneWidget);
      await tester.tap(find.text('Танхим'));
      await tester.pumpAndSettle();
      expect(find.text('My workshop'), findsOneWidget);
    },
  );
  testWidgets(
    'Training exposes issued certificates and filters course searches',
    (tester) async {
      final api = _CourseTestApi()..loggedIn = true;
      await tester.pumpWidget(OyudentProductionApp(api: api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сургалт'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Онлайн сургалт хайх'),
        'Second',
      );
      await tester.pumpAndSettle();
      expect(find.text('Second course'), findsOneWidget);
      expect(find.text('First course'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('browse-my-courses')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My online course'));
      await tester.pumpAndSettle();
      expect(find.text('Issued certificate'), findsOneWidget);
    },
  );
  testWidgets('Profile library continues after sign-in and opens again', (
    tester,
  ) async {
    final api = _CourseTestApi();
    await tester.pumpWidget(OyudentProductionApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Миний профайл'));
    await tester.pumpAndSettle();
    final library = find.byKey(const ValueKey('profile-my-courses'));
    await tester.tap(library);
    await tester.pumpAndSettle();
    expect(find.text('Сургалтаа үзэхийн тулд нэвтэрнэ үү.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Утасны дугаар'),
      '99110000',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Нууц үг'),
      'fixture',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Нэвтрэх'));
    await tester.pumpAndSettle();
    expect(find.text('My online course'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(library);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Танхим'));
    await tester.pumpAndSettle();
    expect(find.text('My workshop'), findsOneWidget);
  });
  testWidgets('HR requires a supported mobile device to record attendance', (
    tester,
  ) async {
    await tester.pumpWidget(OyudentProductionApp(api: _FakeApi()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ирц'));
    await tester.pumpAndSettle();
    expect(find.text('Ирсэн цагаа бүртгүүлэх'), findsNothing);
    expect(find.textContaining('Android эсвэл iPhone'), findsOneWidget);
    expect(find.text('Энэ сард ирц бүртгэгдээгүй.'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  testWidgets(
    'Completing the matching game awards once and survives opening it again',
    (tester) async {
      final api = _CourseTestApi();
      await tester.pumpWidget(OyudentProductionApp(api: api));
      await tester.pumpAndSettle();
      final game = find.text('Өдрийн тоглоом');
      await tester.scrollUntilVisible(
        game,
        180,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('oyudent-home')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await Scrollable.ensureVisible(tester.element(game), alignment: .4);
      await tester.pumpAndSettle();
      await tester.tap(game);
      await tester.pumpAndSettle();
      final cards = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(FilledButton),
      );
      for (var first = 0; first < 6 && cards.evaluate().isNotEmpty; first++) {
        for (
          var next = first + 1;
          next < 6 && cards.evaluate().isNotEmpty;
          next++
        ) {
          if (tester.widget<FilledButton>(cards.at(first)).onPressed == null) {
            break;
          }
          if (tester.widget<FilledButton>(cards.at(next)).onPressed == null) {
            continue;
          }
          await tester.tap(cards.at(first));
          await tester.pump();
          await tester.tap(cards.at(next));
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pumpAndSettle();
        }
      }
      expect(find.text('Өнөөдрийн 1 бонус оноог авлаа'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(game);
      await tester.pumpAndSettle();
      expect(find.text('Өнөөдрийн 1 бонус оноог авлаа'), findsOneWidget);
      expect(cards, findsNothing);
    },
  );
  testWidgets(
    'Empty on-site catalog stays visible without advertising closed sessions',
    (tester) async {
      await tester.pumpWidget(OyudentProductionApp(api: _NoOnsiteApi()));
      await tester.pumpAndSettle();
      expect(find.text('Past workshop'), findsNothing);
      await tester.tap(find.text('Сургалт'));
      await tester.pumpAndSettle();
      expect(find.text('Test course'), findsOneWidget);
      await tester.tap(find.text('Танхим'));
      await tester.pumpAndSettle();
      expect(find.text('Танхимын шинэ сургалт алга'), findsOneWidget);
      expect(find.text('Past workshop'), findsNothing);
      await tester.tap(find.text('Шинэчлэх'));
      await tester.pumpAndSettle();
      expect(find.text('Танхимын шинэ сургалт алга'), findsOneWidget);
      await tester.tap(find.text('Онлайн'));
      await tester.pumpAndSettle();
      expect(find.text('Test course'), findsOneWidget);
    },
  );
  testWidgets(
    'Patient can decline a clinic request directly on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(OyudentProductionApp(api: _FakeApi()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Цаг'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('schedule-view-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Сар'));
      await tester.pumpAndSettle();
      final t = DateTime.now();
      final nextMonth = DateTime(t.year, t.month + 1);
      await tester.tap(find.byTooltip('Дараах'));
      await tester.pumpAndSettle();
      expect(
        find.text('${nextMonth.year} оны ${nextMonth.month} сар'),
        findsOneWidget,
      );
      await tester.tap(find.text('Өнөөдөр'));
      await tester.pumpAndSettle();
      expect(find.text('${t.year} оны ${t.month} сар'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('clinic-request-inbox')));
      await tester.pumpAndSettle();
      expect(find.text('Туршилтын хүсэлт'), findsOneWidget);
      expect(find.text('Шүдний үзлэг'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.ensureVisible(find.text('Татгалзах'));
      await tester.tap(find.text('Татгалзах'));
      await tester.pumpAndSettle();
      expect(find.text('Шинэ хүсэлт алга'), findsOneWidget);
      expect(find.text('Татгалзсан'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Жишээ шүдний эмнэлэг'), findsNothing);
      final restored = DeviceWorkspace('doctor/test');
      await restored.load();
      expect(restored.rows('appointments').single['status'], 'declined');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Patient approval adds the clinic request to their calendar', (
    tester,
  ) async {
    await tester.pumpWidget(OyudentProductionApp(api: _FakeApi()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Цаг'));
    await tester.pumpAndSettle();
    expect(find.text('Жишээ шүдний эмнэлэг'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('clinic-request-inbox')));
    await tester.pumpAndSettle();
    expect(find.text('Жишээ шүдний эмнэлэг'), findsOneWidget);
    expect(find.text('Код оруулах'), findsNothing);
    await tester.ensureVisible(find.text('Зөвшөөрөх'));
    await tester.tap(find.text('Зөвшөөрөх'));
    await tester.pumpAndSettle();
    final stored = DeviceWorkspace('doctor/test');
    await stored.load();
    final confirmed = stored.rows('appointments').single;
    expect(confirmed['status'], 'approved');
    await tester.tap(find.byKey(const ValueKey('schedule-view-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Жагсаалт'));
    await tester.pumpAndSettle();
    final appointment = find.text('Жишээ шүдний эмнэлэг');
    expect(appointment, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('clinic-request-inbox')));
    await tester.pumpAndSettle();
    expect(find.text('Шинэ хүсэлт алга'), findsOneWidget);
    expect(find.text('Зөвшөөрсөн'), findsOneWidget);
  });
  testWidgets(
    'Sample product uses bonus points and retains a local redemption',
    (tester) async {
      final store = DeviceWorkspace('doctor/test');
      await store.reward(DateTime.now());
      final api = _FakeApi();
      await tester.pumpWidget(OyudentProductionApp(api: api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Оноо'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Онооны дэлгүүрээс хайх'),
        'үзлэгийн багаж',
      );
      await tester.pumpAndSettle();
      final item = find.text('Шүдний үзлэгийн багаж');
      await Scrollable.ensureVisible(tester.element(item), alignment: .35);
      await tester.pumpAndSettle();
      await tester.tap(item);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 бонус оноогоор авах'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Баталгаажуулах'));
      await tester.pumpAndSettle();
      expect(find.text('Жишээ захиалга бүртгэгдсэн'), findsOneWidget);
      final saved = DeviceWorkspace('doctor/test');
      await saved.load();
      expect(saved.localPoints, 0);
      expect(saved.redeemed('sample:mirror'), isTrue);
      expect(api.submissions, isEmpty);
    },
  );
  testWidgets(
    'HR summary filters by month and divides cross-month shifts at midnight',
    (tester) async {
      final now = DateTime.now();
      final month = DateTime(now.year, now.month);
      final workspace = DeviceWorkspace('doctor/test');
      await workspace.clock(
        entering: true,
        now: month.subtract(const Duration(hours: 2)),
      );
      await workspace.clock(
        entering: false,
        now: month.add(const Duration(hours: 1)),
      );
      await tester.pumpWidget(OyudentProductionApp(api: _FakeApi()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ирц'));
      await tester.pumpAndSettle();
      expect(find.text('1 ц 0 мин'), findsOneWidget);
      await tester.tap(find.byTooltip('Өмнөх'));
      await tester.pumpAndSettle();
      expect(find.text('2 ц 0 мин'), findsOneWidget);
      expect(find.text('1 ц 0 мин'), findsNothing);
    },
  );
}
