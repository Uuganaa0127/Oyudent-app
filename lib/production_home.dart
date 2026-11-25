part of 'production_app.dart';

class _Landing extends StatefulWidget {
  const _Landing({required this.api, required this.onPoints});
  final ProductionApi api;
  final VoidCallback onPoints;

  @override
  State<_Landing> createState() => _LandingState();
}

class _LandingState extends State<_Landing> {
  final banners = PageController();
  int active = 0;
  late Future<List<Record>> bannerRows = _loadBanners();
  late Map<Catalog, Future<List<Record>>> shelves = _loadShelves();

  Future<List<Record>> _loadBanners() =>
      widget.api.list('banner/list?no_paginate=1');

  Map<Catalog, Future<List<Record>>> _loadShelves() => {
    Catalog.training: widget.api.list('training/catalog?size=6'),
    Catalog.products: widget.api.list(
      'product/list?size=6&is_show_landing=true&sort=-created_at',
    ),
    Catalog.courses: widget.api
        .list('course/no/list?no_paginate=1&sort=-created_at')
        .then((rows) => _openCoursesFirst(rows).take(3).toList()),
    Catalog.news: widget.api.list('news/list?size=6&sort=-created_at'),
  };

  Future<void> _refresh() async {
    if (banners.hasClients) banners.jumpToPage(0);
    setState(() {
      active = 0;
      bannerRows = _loadBanners();
      shelves = _loadShelves();
    });
    await Future.wait(
      [bannerRows, ...shelves.values].map((future) async {
        try {
          await future;
        } catch (_) {
          /* Sections display their own status. */
        }
      }),
    );
  }

  @override
  void dispose() {
    banners.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _refresh,
    child: ListView(
      key: const PageStorageKey('oyudent-home'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _CatalogShortcuts(api: widget.api),
        Card(
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xffe9e6ff),
              child: Icon(Icons.stars_outlined, color: _brand),
            ),
            title: const Text(
              'Онооны дэлгүүр',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: const Icon(Icons.arrow_forward_rounded),
            onTap: widget.onPoints,
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<Record>>(
          future: bannerRows,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? [];
            if (rows.isEmpty &&
                snapshot.connectionState == ConnectionState.waiting) {
              return Semantics(
                label: 'Баннер уншиж байна',
                child: const _HomeSkeleton(height: 224, radius: 14),
              );
            }
            if (rows.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                SizedBox(
                  height: 224,
                  child: PageView.builder(
                    controller: banners,
                    itemCount: rows.length,
                    onPageChanged: (page) => setState(() => active = page),
                    itemBuilder: (context, index) =>
                        _HeroBanner(row: rows[index]),
                  ),
                ),
                if (rows.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${(active + 1).clamp(1, rows.length)} / ${rows.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            );
          },
        ),
        for (final entry in shelves.entries)
          _HomeShelf(
            api: widget.api,
            catalog: entry.key,
            future: entry.value,
            title: switch (entry.key) {
              Catalog.training => 'Танд зориулсан сургалтууд',
              Catalog.courses => 'Танхимын сургалт',
              Catalog.products => 'Шинэ бүтээгдэхүүн',
              Catalog.news => 'Мэдээ мэдээлэл',
              _ => entry.key.label,
            },
          ),
      ],
    ),
  );
}

class _CatalogShortcuts extends StatelessWidget {
  const _CatalogShortcuts({required this.api});
  final ProductionApi api;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 104,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      primary: false,
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final catalog = [
          Catalog.training,
          Catalog.products,
          Catalog.courses,
          Catalog.news,
        ][index];
        return SizedBox(
          width: 80,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openCatalog(context, api, catalog),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _brandGradient,
                  ),
                  child: Icon(catalog.icon, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  catalog.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.row});
  final Record row;

  @override
  Widget build(BuildContext context) {
    final title = text(row, ['title']);
    final description = text(row, ['description']);
    final photo = text(row, ['image_path']);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _WebsiteImage(url: photo, icon: Icons.photo_outlined),
          if (title.isNotEmpty || description.isNotEmpty) ...[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xdd30256b)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeShelf extends StatelessWidget {
  const _HomeShelf({
    required this.api,
    required this.catalog,
    required this.future,
    required this.title,
  });
  final ProductionApi api;
  final Catalog catalog;
  final Future<List<Record>> future;
  final String title;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Record>>(
    future: future,
    builder: (context, snapshot) {
      final rows = snapshot.data ?? [];
      final brands = catalog == Catalog.brands;
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => _openCatalog(context, api, catalog),
                  child: const Text('Бүгдийг үзэх'),
                ),
              ],
            ),
            if (rows.isNotEmpty)
              SizedBox(
                height: brands
                    ? 138
                    : catalog == Catalog.courses
                    ? 236
                    : 215,
                child: ListView.separated(
                  primary: false,
                  scrollDirection: Axis.horizontal,
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => SizedBox(
                    width: brands ? 124 : 244,
                    child: _WebStyleCard(
                      api: api,
                      catalog: catalog,
                      row: rows[index],
                      compact: true,
                    ),
                  ),
                ),
              )
            else if (snapshot.connectionState == ConnectionState.waiting)
              Semantics(
                label: '$title уншиж байна',
                child: SizedBox(
                  height: brands
                      ? 138
                      : catalog == Catalog.courses
                      ? 236
                      : 215,
                  child: ListView.separated(
                    primary: false,
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, _) => SizedBox(
                      width: brands ? 124 : 244,
                      child: _HomeCardSkeleton(brand: brands),
                    ),
                  ),
                ),
              )
            else if (snapshot.hasError)
              Text(
                _message(snapshot.error!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      );
    },
  );
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton({required this.height, this.width, this.radius = 6});
  final double height, radius;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xffe1e4f6),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _HomeCardSkeleton extends StatelessWidget {
  const _HomeCardSkeleton({required this.brand});
  final bool brand;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xffe1e4f6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HomeSkeleton(height: brand ? 74 : 121, radius: 0),
        Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeSkeleton(height: 13, width: brand ? 70 : 155),
              const SizedBox(height: 8),
              _HomeSkeleton(height: 10, width: brand ? 42 : 98),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WebStyleCard extends StatelessWidget {
  const _WebStyleCard({
    required this.api,
    required this.catalog,
    required this.row,
    this.compact = false,
  });
  final ProductionApi api;
  final Catalog catalog;
  final Record row;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final title = catalog.title(row);
    final brand = catalog == Catalog.brands;
    final summary = catalog.summary(row);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xffe1e4f6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            _push(context, _Details(api: api, catalog: catalog, row: row)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: brand
                  ? 74
                  : compact
                  ? 121
                  : 155,
              child: _WebsiteImage(
                url: catalog.image(row),
                icon: catalog.icon,
                fit: brand || catalog == Catalog.products
                    ? BoxFit.contain
                    : BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isNotEmpty ? title : catalog.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (catalog == Catalog.courses)
                    Text(
                      _registrationClosedReason(row) ?? 'Бүртгэл нээлттэй',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  if (!brand && summary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        summary,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

class _WebsiteImage extends StatelessWidget {
  const _WebsiteImage({
    required this.url,
    required this.icon,
    this.fit = BoxFit.cover,
  });
  final String url;
  final IconData icon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    final source = uri == null || url.trim().isEmpty
        ? null
        : Uri.https('oyudent.com').resolveUri(uri);
    final placeholder = ColoredBox(
      color: const Color(0xffe9e6ff),
      child: Center(child: Icon(icon, color: _brand)),
    );
    return source?.scheme != 'https'
        ? placeholder
        : Image.network(
            source.toString(),
            fit: fit,
            width: double.infinity,
            errorBuilder: (_, _, _) => placeholder,
          );
  }
}
