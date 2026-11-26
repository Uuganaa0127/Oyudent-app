import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyudent/production_api.dart';
import 'package:oyudent/production_app.dart';

class _PendingHomeApi extends ProductionApi {
  final requests = <String, List<Completer<List<Record>>>>{};

  @override
  Future<Record?> restore() async => null;

  @override
  Future<List<Record>> list(String path, {bool authenticated = false}) {
    final result = Completer<List<Record>>();
    (requests[Uri.parse(path).path] ??= []).add(result);
    return result.future;
  }
}

void main() {
  testWidgets(
    'Home uses one loading indicator and retries only the failed feed',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final api = _PendingHomeApi();
      await tester.pumpWidget(OyudentProductionApp(api: api));
      final loading = find.byKey(const ValueKey('home-loading'));
      expect(loading, findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(api.requests, hasLength(4));

      api.requests['banner/list']!.single.complete([
        {'id': 'event', 'title': 'Онцлох өдөр'},
      ]);
      await tester.pump();
      await tester.pump();
      expect(find.text('Онцлох өдөр'), findsOneWidget);
      expect(loading, findsOneWidget);

      api.requests['training/catalog']!.single.complete([]);
      api.requests['course/no/list']!.single.complete([]);
      api.requests['product/list']!.single.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(loading, findsNothing);
      expect(find.text('Онцлох өдөр'), findsOneWidget);
      await tester.tap(find.text('Дахин оролдох'));
      await tester.pump();
      expect(loading, findsOneWidget);
      expect(api.requests['product/list'], hasLength(2));
      expect(api.requests['banner/list'], hasLength(1));
      api.requests['product/list']!.last.complete([]);
      await tester.pumpAndSettle();
      expect(loading, findsNothing);
      expect(find.text('Дахин оролдох'), findsNothing);
      expect(find.text('Онцлох өдөр'), findsOneWidget);
    },
  );
}
