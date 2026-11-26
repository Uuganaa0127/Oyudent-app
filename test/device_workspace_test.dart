import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyudent/device_workspace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'Appointments and open shifts survive reopening and stay with their owner',
    () async {
      final a = DeviceWorkspace('doctor/a');
      final t = DateTime(2026, 11, 18, 9, 30);
      await a.update(
        'appointments',
        (rows) => rows.add({
          'id': '1',
          'title': 'Хяналт',
          'time': t.toUtc().toIso8601String(),
        }),
      );
      await Future.wait([
        a.clock(entering: true, now: t),
        a.clock(entering: true, now: t),
      ]);
      final restored = DeviceWorkspace('doctor/a');
      await restored.load();
      expect(
        restored
            .rows('appointments')
            .singleWhere((r) => r['id'] == '1')['title'],
        'Хяналт',
      );
      expect(restored.rows('shifts').single['end'], isNull);
      await restored.clock(
        entering: false,
        now: t.add(const Duration(hours: 8)),
      );
      expect(restored.rows('shifts').single['end'], isNotNull);
      final other = DeviceWorkspace('doctor/b');
      await other.load();
      expect(
        other.rows('appointments').where((r) => r['demo'] != true),
        isEmpty,
      );
      expect(other.rows('shifts'), isEmpty);
    },
  );
  test('A sample clinic request is seeded once and each owner answers independently', () async {
    final store = DeviceWorkspace('patient/a');
    await Future.wait([store.load(), store.load()]);
    final sample = store.rows('appointments').single;
    expect(sample['demo'], isTrue);
    expect(sample['status'], 'pending');
    final responses = await Future.wait([
      store.decideRequest(sample['id'], true),
      store.decideRequest(sample['id'], false),
    ]);
    expect(responses, [true, false]);
    final reopened = DeviceWorkspace('patient/a');
    await reopened.load();
    expect(reopened.rows('appointments').single['status'], 'approved');
    expect(reopened.rows('appointments').single['time'], sample['time']);
    final other = DeviceWorkspace('patient/b');
    await other.load();
    expect(other.rows('appointments').single['status'], 'pending');
  });
  test(
    'Previously received clinic requests are preserved without adding a sample',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'oyudent.local.v1.patient%2Fa.appointments': '[{"id":"existing","source":"hospital","status":"pending","hospital":"Эмнэлэг","title":"Өвчтөн","time":"2026-11-27T01:00:00Z"}]',
      });
      final store = DeviceWorkspace('patient/a');
      await store.load();
      expect(store.rows('appointments').single['id'], 'existing');
      expect(await store.decideRequest('existing', false), isTrue);
      final reopened = DeviceWorkspace('patient/a');
      await reopened.load();
      expect(reopened.rows('appointments').single['status'], 'declined');
    },
  );
  test('Repeated wins give one local point each calendar day', () async {
    final a = DeviceWorkspace('device');
    final t = DateTime(2026, 11, 18, 23, 59);
    await Future.wait([a.reward(t), a.reward(t)]);
    final reopened = DeviceWorkspace('device');
    await reopened.load();
    await reopened.reward(t);
    expect(reopened.rows('game'), hasLength(1));
    await reopened.reward(t.add(const Duration(minutes: 1)));
    expect(reopened.rows('game'), hasLength(2));
  });
}
