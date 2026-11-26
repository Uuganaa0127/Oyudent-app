part of 'production_app.dart';

const _night = Color(0xff182e49);
const _highlight = Color(0xffb5e8df);
const _line = Color(0xffdce4ec);

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Container(
    width: 31,
    height: 31,
    decoration: BoxDecoration(
      color: _night,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Center(
      child: Transform.rotate(
        angle: -.56,
        child: Container(
          width: 18,
          height: 12,
          decoration: BoxDecoration(
            border: Border.all(color: _highlight, width: 3.4),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ),
  );
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 10, 16, 14),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xffe2e9f9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: _brand),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 25,
              height: 1.12,
              letterSpacing: -.8,
              fontWeight: FontWeight.w800,
              color: _night,
            ),
          ),
        ),
      ],
    ),
  );
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xe01b304b),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white30),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _highlight),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Contour lines echo the orbit in the Oyudent mark.
class _Contours extends CustomPainter {
  const _Contours();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width * .83, size.height * .59);
    canvas.rotate(-.47);
    final pen = Paint()
      ..color = const Color(0x407fa7da)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 12; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 72 + i * 28,
          height: 32 + i * 14,
        ),
        pen,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Contours oldDelegate) => false;
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.onTap, this.played = false});
  final VoidCallback onTap;
  final bool played;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xffe3f0ed),
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xffc7e3db),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox.square(
                dimension: 46,
                child: Icon(Icons.style_rounded, color: _brand, size: 23),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Өдрийн тоглоом',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: _ink, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    played ? 'Өнөөдрийн бонус оноог авсан' : '+1 бонус оноо',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: const Color(0xff33665f)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              played
                  ? Icons.check_circle_outline_rounded
                  : Icons.arrow_forward_rounded,
              size: 20,
              color: _brand,
            ),
          ],
        ),
      ),
    ),
  );
}

class _FeatureHeader extends StatelessWidget {
  const _FeatureHeader({
    required this.title,
    required this.kind,
    required this.icon,
    this.image = '',
    this.facts = const [],
    this.picture,
  });
  final String title, kind, image;
  final IconData icon;
  final List<String> facts;
  final Widget? picture;
  @override
  Widget build(BuildContext context) {
    final visual =
        picture ??
        (image.isEmpty
            ? null
            : _WebsiteImage(url: image, icon: icon, fit: BoxFit.contain));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: _night),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (visual != null)
                  ColoredBox(
                    color: Colors.white,
                    child: SizedBox(
                      height: (MediaQuery.sizeOf(context).width * .60).clamp(
                        196.0,
                        330.0,
                      ),
                      child: visual,
                    ),
                  ),
                CustomPaint(
                  painter: const _Contours(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: _highlight, size: 16),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                kind,
                                style: const TextStyle(
                                  color: _highlight,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 25,
                            height: 1.13,
                            letterSpacing: -.7,
                          ),
                        ),
                        if (facts.isNotEmpty) ...[
                          const SizedBox(height: 11),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final f in facts)
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: const BorderSide(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            child,
          ],
        ),
      ),
    ),
  );
}

/// A line illustration fills course covers when the publisher has no photograph.
class _MolarArt extends CustomPainter {
  const _MolarArt();
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final scale = (size.width < size.height ? size.width : size.height) / 120;
    canvas.scale(scale);
    canvas.rotate(.13);
    final outline = Path()
      ..moveTo(-3, -30)
      ..cubicTo(-26, -46, -51, -32, -43, -9)
      ..cubicTo(-40, 3, -34, 7, -32, 22)
      ..cubicTo(-30, 49, -20, 60, -15, 39)
      ..cubicTo(-10, 15, -6, 7, 2, 9)
      ..cubicTo(9, 12, 10, 26, 14, 37)
      ..cubicTo(24, 63, 32, 40, 32, 20)
      ..cubicTo(33, 4, 43, -7, 42, -19)
      ..cubicTo(41, -39, 21, -44, 5, -32)
      ..quadraticBezierTo(0, -28, -3, -30)
      ..close();
    canvas.drawPath(
      outline,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffedfaff), Color(0xff95cacf), Color(0xff576696)],
        ).createShader(const Rect.fromLTWH(-46, -46, 94, 104)),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..color = const Color(0xffdbeaf5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.save();
    canvas.clipPath(outline);
    final pen = Paint()
      ..color = const Color(0x886b7f98)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75;
    for (int i = 0; i < 12; i++) {
      final offset = i * 4.7;
      canvas.drawPath(
        Path()
          ..moveTo(-50, -31 + offset)
          ..cubicTo(-27, -50 + offset, -15, -9 + offset, 4, -22 + offset)
          ..cubicTo(16, -31 + offset, 36, -30 + offset, 49, -33 + offset),
        pen,
      );
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MolarArt oldDelegate) => false;
}
