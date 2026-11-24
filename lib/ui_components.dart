import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class SwipeBehavior extends MaterialScrollBehavior {
  const SwipeBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final approved =
        status == 'Батлагдсан' ||
        status == 'Бүртгүүлсэн' ||
        status == 'Дууссан';
    final declined = status == 'Татгалзсан';
    final color = approved
        ? const Color(0xFF047857)
        : declined
        ? const Color(0xFFBE123C)
        : const Color(0xFFB45309);
    return Semantics(
      label: 'Төлөв: $status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          border: Border.all(color: color.withValues(alpha: .3)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              approved
                  ? Icons.check_circle_outline
                  : declined
                  ? Icons.cancel_outlined
                  : Icons.schedule_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HoverCard extends StatefulWidget {
  const HoverCard({
    super.key,
    this.child,
    this.color,
    this.shape,
    this.elevation = 0,
    this.clipBehavior = Clip.none,
  });
  final Widget? child;
  final Color? color;
  final ShapeBorder? shape;
  final double? elevation;
  final Clip clipBehavior;
  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool hover = false, pressed = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hover = true),
    onExit: (_) => setState(() => hover = false),
    child: Listener(
      onPointerDown: (_) => setState(() => pressed = true),
      onPointerUp: (_) => setState(() => pressed = false),
      onPointerCancel: (_) => setState(() => pressed = false),
      child: AnimatedScale(
        scale: pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 150),
        child: Card(
          elevation: hover ? 6 : widget.elevation,
          shadowColor: const Color(0x225F54DB),
          surfaceTintColor: const Color(0xFFE6E9FF),
          color: hover ? const Color(0xFFFAFAFF) : widget.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(
              color: hover ? const Color(0xFF9992F5) : const Color(0xFFE2E5FA),
              width: hover ? 1.5 : 1,
            ),
          ),
          clipBehavior: widget.clipBehavior,
          child: widget.child,
        ),
      ),
    ),
  );
}
