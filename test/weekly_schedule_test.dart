import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyudent/production_api.dart';
import 'package:oyudent/production_app.dart';

class _EmptyCatalog extends ProductionApi {
  @override
  Future<Record?> restore() async => null;

  @override
  Future<List<Record>> list(String path, {bool authenticated = false}) async =>
      [];
}

void main() {
  testWidgets(
    'Phone week shows confirmed visits across New Year with full details',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(340, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Record visit(
        String id,
        DateTime start,
        String service, {
        String status = 'approved',
      }) => {
        'id': id,
        'source': 'hospital',
        'status': status,
        'title': 'Саруул',
        'service': service,
        'hospital': 'Урт нэртэй шүдний эмнэлгийн төв салбар',
        'doctor': 'Энх эмч',
        'location': 'Өрөө 305',
        'time': start.toUtc().toIso8601String(),
        'durationMinutes': 45,
      };

      FlutterSecureStorage.setMockInitialValues({
        'oyudent.local.v1.device.appointments': jsonEncode([
          visit(
            'monday',
            DateTime(2026, 12, 28, 12),
            'Төлөвлөгөөт хяналт',
            status: 'pending',
          ),
          visit('morning', DateTime(2026, 12, 28, 9), 'Шүдний үзлэг'),
          visit('saturday', DateTime(2027, 1, 2, 15, 15), 'Шүдний цэвэрлэгээ'),
          visit('outside', DateTime(2027, 1, 4, 11), 'Дараагийн тов'),
          visit(
            'declined',
            DateTime(2026, 12, 29, 13),
            'Татгалзсан үзлэг',
            status: 'declined',
          ),
        ]),
      });
      await tester.pumpWidget(OyudentProductionApp(api: _EmptyCatalog()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Цаг'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('clinic-request-inbox')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Зөвшөөрөх'));
      await tester.tap(find.text('Зөвшөөрөх'));
      await tester.pumpAndSettle();
      expect(find.text('2026.12.28 – 2027.1.3'), findsOneWidget);
      expect(find.text('3 баталгаажсан цаг'), findsOneWidget);
      expect(find.text('09:00 – 09:45'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Шүдний үзлэг')).dy,
        lessThan(tester.getTopLeft(find.text('Төлөвлөгөөт хяналт')).dy),
      );
      final schedule = find
          .descendant(
            of: find.byKey(const ValueKey('booking-schedule')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Шүдний цэвэрлэгээ'),
        230,
        scrollable: schedule,
      );
      await tester.pumpAndSettle();
      final card = find
          .ancestor(
            of: find.text('Шүдний цэвэрлэгээ'),
            matching: find.byType(InkWell),
          )
          .first;
      for (final value in [
        '15:15 – 16:00',
        'Саруул',
        'Энх эмч',
        'Өрөө 305',
        'Урт нэртэй шүдний эмнэлгийн төв салбар',
      ]) {
        expect(
          find.descendant(of: card, matching: find.text(value)),
          findsOneWidget,
        );
      }
      expect(find.text('Татгалзсан үзлэг'), findsNothing);
      expect(find.text('Дараагийн тов'), findsNothing);
      await tester.scrollUntilVisible(
        find.byTooltip('Дараах'),
        -280,
        scrollable: schedule,
      );
      await tester.tap(find.byTooltip('Дараах'));
      await tester.pumpAndSettle();
      expect(find.text('1 сарын 4–10'), findsOneWidget);
      expect(find.text('Дараагийн тов'), findsOneWidget);
      expect(find.text('Шүдний цэвэрлэгээ'), findsNothing);
      await tester.tap(find.byTooltip('Өмнөх'));
      await tester.pumpAndSettle();
      expect(find.text('2026.12.28 – 2027.1.3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
