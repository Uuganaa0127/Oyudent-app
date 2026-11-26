part of 'production_app.dart';

const _samples = <Record>[
  {
    'id': 'sample:mirror',
    'title': 'Шүдний үзлэгийн багаж',
    'price_point': 1,
    'panel': 0,
    'description': 'Толь, хямсаа, үзлэгийн зонд бүхий багц.',
  },
  {
    'id': 'sample:glasses',
    'title': 'Хамгаалалтын нүдний шил',
    'price_point': 3,
    'panel': 1,
    'description': 'Тунгалаг линзтэй хамгаалалтын шил.',
  },
  {
    'id': 'sample:model',
    'title': 'Шүдний сургалтын загвар',
    'price_point': 5,
    'panel': 2,
    'description': 'Шүдний эгнээ болон зуултыг харуулах сургалтын загвар.',
  },
];

class _SamplePhoto extends StatelessWidget {
  const _SamplePhoto(this.panel);
  final int panel;
  static final Future<ui.Image> _photo = loadPhoto();
  static Future<ui.Image> loadPhoto() async {
    final data = await rootBundle.load('assets/dental-products.png');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _photo,
    builder: (_, s) {
      if (!s.hasData) return const ColoredBox(color: Color(0xffe2ebe0));
      return CustomPaint(painter: _ProductPhotoPainter(s.data!, panel));
    },
  );
}

class _ProductPhotoPainter extends CustomPainter {
  _ProductPhotoPainter(this.image, this.panel);
  final ui.Image image;
  final int panel;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // The photograph has three portrait panels. Extend their studio backdrops
    // to fill a landscape card while keeping the entire product in frame.
    final h = image.height.toDouble();
    final w = image.width / 3;
    final (top, bottom) = const [
      (0.10, 0.91),
      (0.24, 0.78),
      (0.18, 0.81),
    ][panel];
    final src = Rect.fromLTRB(
      w * panel + 2,
      h * top,
      w * (panel + 1) - 2,
      h * bottom,
    );
    final scale = (size.width / src.width).clamp(0.0, size.height / src.height);
    final dest = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: src.width * scale,
      height: src.height * scale,
    );
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawColor(const Color(0xffe3eadd), BlendMode.srcOver);
    if (dest.left > 0) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(src.left, src.top, 1, src.height),
        Rect.fromLTRB(0, dest.top, dest.left + 0.5, dest.bottom),
        paint,
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(src.right - 1, src.top, 1, src.height),
        Rect.fromLTRB(dest.right - 0.5, dest.top, size.width, dest.bottom),
        paint,
      );
    }
    canvas.drawImageRect(image, src, dest, paint);
  }

  @override
  bool shouldRepaint(_ProductPhotoPainter old) =>
      old.panel != panel || old.image != image;
}

class _SampleProduct extends StatefulWidget {
  const _SampleProduct({required this.row, required this.store});
  final Record row;
  final DeviceWorkspace store;
  @override
  State<_SampleProduct> createState() => _SampleProductState();
}

class _SampleProductState extends State<_SampleProduct> {
  bool busy = false;
  Future<void> redeem() async {
    final product = widget.row;
    final cost = product['price_point'] as int;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Жишээ захиалга'),
        content: Text(
          '${product['title']} · $cost бонус оноо. Захиалга энэ төхөөрөмжид хадгалагдана.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Болих'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Баталгаажуулах'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || busy) return;
    setState(() => busy = true);
    try {
      await widget.store.redeemSample(
        product['id'],
        product['title'],
        cost,
        DateTime.now(),
      );
      await widget.store.removeCart(product['id']);
      if (mounted) _notice(context, 'Жишээ захиалга хадгалагдлаа.');
    } catch (_) {
      if (mounted) {
        _notice(context, 'Үлдэгдэл болон захиалгын төлөвөө шалгана уу.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final r = widget.row;
      final cost = r['price_point'] as int;
      final done = widget.store.redeemed(r['id']);
      return Scaffold(
        appBar: AppBar(title: const Text('Бүтээгдэхүүн')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _FeatureHeader(
              title: r['title'],
              kind: 'Жишээ бүтээгдэхүүн',
              icon: Icons.inventory_2_outlined,
              picture: _SamplePhoto(r['panel']),
              facts: ['$cost бонус оноо'],
            ),
            _DetailSection(title: 'Танилцуулга', child: Text(r['description'])),
            _DetailSection(
              title: 'Бонус оноо',
              child: Text('Үлдэгдэл · ${widget.store.localPoints} оноо'),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: busy || done || widget.store.localPoints < cost
                ? null
                : redeem,
            icon: Icon(done ? Icons.check : Icons.redeem),
            label: Text(
              done
                  ? 'Жишээ захиалга бүртгэгдсэн'
                  : widget.store.localPoints < cost
                  ? 'Дахин ${cost - widget.store.localPoints} бонус оноо цуглуулаарай'
                  : '$cost бонус оноогоор авах',
            ),
          ),
        ),
      );
    },
  );
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.row,
    required this.product,
    required this.onOpen,
    required this.add,
    required this.added,
  });
  final Record row;
  final bool product, added;
  final VoidCallback onOpen;
  final VoidCallback? add;
  @override
  Widget build(BuildContext context) {
    final picture = Catalog.training.image(row);
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _line),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.63,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product)
                    _SamplePhoto(row['panel'])
                  else if (picture.isNotEmpty)
                    _WebsiteImage(url: picture, icon: Icons.school)
                  else
                    const ColoredBox(
                      color: _night,
                      child: CustomPaint(
                        painter: _Contours(),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_outline_rounded,
                            color: _highlight,
                            size: 39,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _GlassPill(
                      icon: product
                          ? Icons.inventory_2_outlined
                          : Icons.play_circle_outline,
                      text: product ? 'Жишээ' : 'Сургалт',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Catalog.training.title(row),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      height: 1.18,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product
                              ? '${row['price_point']} бонус оноо'
                              : '${row['price_point']} оноо',
                          style: const TextStyle(
                            color: _brand,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: added ? 'Сагсанд байгаа' : 'Сагсанд нэмэх',
                        onPressed: add,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(added ? Icons.check : Icons.add, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
