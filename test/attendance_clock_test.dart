import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:oyudent/attendance_clock.dart';
import 'package:oyudent/device_workspace.dart';

class _DeviceAuth extends Fake implements LocalAuthentication {
  final attempts = <Completer<bool>>[];

  @override
  dynamic noSuchMethod(Invocation call) {
    if (call.memberName == #authenticate) {
      expect(call.namedArguments[#biometricOnly], isTrue);
      expect(call.namedArguments[#localizedReason], isNotEmpty);
      final response = Completer<bool>();
      attempts.add(response);
      return response.future;
    }
    return super.noSuchMethod(call);
  }
}

void main() {
  testWidgets('Clock-in and clock-out each require a fresh device match', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = DeviceWorkspace('bio-test');
    await store.load();
    final device = _DeviceAuth();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: store,
            builder: (_, _) =>
                AttendanceClock(store: store, authenticator: device),
          ),
        ),
      ),
    );
    final start = find.text('Ирсэн цагаа бүртгүүлэх');
    final end = find.text('Явсан цагаа бүртгүүлэх');
    await tester.tap(start);
    await tester.tap(start);
    await tester.pump();
    expect(device.attempts.length, 1);
    expect(store.rows('shifts'), isEmpty);
    device.attempts.last.completeError(
      const LocalAuthException(code: LocalAuthExceptionCode.userCanceled),
    );
    await tester.pumpAndSettle();
    expect(store.rows('shifts'), isEmpty);
    expect(find.textContaining('цуцлагдлаа'), findsOneWidget);

    await tester.tap(start);
    device.attempts.last.completeError(
      const LocalAuthException(
        code: LocalAuthExceptionCode.noBiometricsEnrolled,
      ),
    );
    await tester.pumpAndSettle();
    expect(store.rows('shifts'), isEmpty);
    expect(find.textContaining('тохиргоонд'), findsOneWidget);

    await tester.tap(start);
    device.attempts.last.complete(true);
    await tester.pumpAndSettle();
    expect(store.rows('shifts').single['end'], isNull);
    expect(end, findsOneWidget);

    await tester.tap(end);
    device.attempts.last.complete(false);
    await tester.pumpAndSettle();
    expect(store.rows('shifts').single['end'], isNull);
    expect(find.textContaining('Баталгаажуулж чадсангүй'), findsOneWidget);

    await tester.tap(end);
    device.attempts.last.complete(true);
    await tester.pumpAndSettle();
    final saved = DeviceWorkspace('bio-test');
    await saved.load();
    expect(saved.rows('shifts').single['end'], isNotNull);
    expect(start, findsOneWidget);
    expect(device.attempts.length, 5);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('A biometric response after leaving the screen cannot clock in', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = DeviceWorkspace('cancel-test');
    await store.load();
    final device = _DeviceAuth();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceClock(store: store, authenticator: device),
        ),
      ),
    );
    await tester.tap(find.text('Ирсэн цагаа бүртгүүлэх'));
    await tester.pumpWidget(const SizedBox.shrink());
    device.attempts.single.complete(true);
    await tester.pumpAndSettle();
    expect(store.rows('shifts'), isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
