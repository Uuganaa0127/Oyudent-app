import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'device_workspace.dart';

class AttendanceClock extends StatefulWidget {
  const AttendanceClock({super.key, required this.store, this.authenticator});

  final DeviceWorkspace store;
  final LocalAuthentication? authenticator;

  @override
  State<AttendanceClock> createState() => _AttendanceClockState();
}

class _AttendanceClockState extends State<AttendanceClock> {
  late final auth = widget.authenticator ?? LocalAuthentication();
  bool checking = false;
  String? feedback;

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> verify(bool entering) async {
    if (checking || !supported) return;
    final store = widget.store;
    setState(() {
      checking = true;
      feedback = null;
    });
    try {
      final matched = await auth.authenticate(
        localizedReason: entering
            ? 'Ирсэн цагаа бүртгүүлэхийн тулд өөрийгөө баталгаажуулна уу.'
            : 'Явсан цагаа бүртгүүлэхийн тулд өөрийгөө баталгаажуулна уу.',
        biometricOnly: true,
      );
      if (!mounted ||
          widget.store != store ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      if (!matched) {
        feedback = 'Баталгаажуулж чадсангүй. Дахин оролдоно уу.';
        return;
      }
      try {
        await store.clock(entering: entering, now: DateTime.now());
        feedback = entering
            ? 'Ирсэн цаг бүртгэгдлээ.'
            : 'Явсан цаг бүртгэгдлээ.';
      } catch (_) {
        feedback = 'Ирцийг хадгалж чадсангүй. Дахин оролдоно уу.';
      }
    } on LocalAuthException catch (error) {
      feedback = switch (error.code) {
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricsEnrolled =>
          'Утасныхаа тохиргоонд нүүр таних эсвэл хурууны хээгээ бүртгүүлнэ үү.',
        LocalAuthExceptionCode.noBiometricHardware =>
          'Энэ төхөөрөмж биометрийн баталгаажуулалт дэмжихгүй байна.',
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.userRequestedFallback =>
          'Баталгаажуулалт цуцлагдлаа. Ирц бүртгэгдээгүй.',
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          'Биометрийн эрх түгжигдсэн байна. Утсаа тайлаад дахин оролдоно уу.',
        LocalAuthExceptionCode.timeout =>
          'Баталгаажуулах хугацаа дууслаа. Дахин оролдоно уу.',
        _ =>
          'Биометрийн баталгаажуулалт түр ажиллахгүй байна. Дахин оролдоно уу.',
      };
    } on MissingPluginException {
      feedback = 'Энэ төхөөрөмж биометрийн баталгаажуулалт дэмжихгүй байна.';
    } catch (_) {
      feedback =
          'Биометрийн баталгаажуулалт түр ажиллахгүй байна. Дахин оролдоно уу.';
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final working = widget.store
        .rows('shifts')
        .any((row) => row['end'] == null);
    final today = DateTime.now();
    final type = Theme.of(context).textTheme;
    const ink = Color(0xff172840);
    const mint = Color(0xffa8e6da);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xff1c3048), Color(0xff204951)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${today.year} оны ${today.month} сарын ${today.day}',
                    style: type.labelLarge?.copyWith(color: Colors.white70),
                  ),
                ),
                const Icon(Icons.verified_user_outlined, color: mint, size: 22),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              working ? 'Ажиллаж байна' : 'Ээлж эхлээгүй',
              style: type.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              supported
                  ? 'Нүүр таних эсвэл хурууны хээгээр цагаа бүртгүүлнэ үү.'
                  : 'Ирц бүртгүүлэхийн тулд Android эсвэл iPhone дээр Oyudent аппыг нээнэ үү.',
              style: type.bodyMedium?.copyWith(color: const Color(0xffdbe7ec)),
            ),
            if (supported) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: mint,
                  foregroundColor: ink,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white70,
                ),
                onPressed: checking ? null : () => verify(!working),
                icon: checking
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.fingerprint, size: 22),
                label: Text(
                  checking
                      ? 'Баталгаажуулж байна…'
                      : working
                      ? 'Явсан цагаа бүртгүүлэх'
                      : 'Ирсэн цагаа бүртгүүлэх',
                ),
              ),
            ],
            if (feedback != null) ...[
              const SizedBox(height: 10),
              Semantics(
                liveRegion: true,
                child: Text(
                  feedback!,
                  style: type.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
