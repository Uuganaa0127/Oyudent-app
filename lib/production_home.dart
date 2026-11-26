part of 'production_app.dart';

enum _HomeFeed {
  banners('banner/list?no_paginate=1'),
  online('training/catalog?size=6'),
  products('product/list?size=6&is_show_landing=true&sort=-created_at'),
  classroom('course/no/list?no_paginate=1&sort=-created_at');

  const _HomeFeed(this.path);
  final String path;
}

class _Landing extends StatefulWidget {
  const _Landing({required this.api, required this.gameTile});
  final Widget gameTile;
  final ProductionApi api;

  @override
  State<_Landing> createState() => _LandingState();
}

class _LandingState extends State<_Landing> {
  final banners = PageController();
  final data = <_HomeFeed, List<Record>>{};
  final errors = <_HomeFeed>{};
  Future<void>? pending;
  int active = 0;

  @override
  void initState() {
    super.initState();
    pending = _load(_HomeFeed.values);
  }

  Future<void> _load(Iterable<_HomeFeed> feeds) async {
    await Future.wait(
      feeds.map((feed) async {
        try {
          final rows = await widget.api.list(feed.path);
          if (!mounted) return;
          setState(() {
            data[feed] = feed == _HomeFeed.classroom
                ? _availableCourses(rows).take(3).toList()
                : rows;
            errors.remove(feed);
          });
        } catch (_) {
          if (mounted) {
            setState(() {
              errors.add(feed);
            });
          }
        }
      }),
    );
    if (mounted) {
      setState(() {
        pending = null;
      });
    }
  }

  Future<void> _refresh({bool retry = false}) {
    final loading = pending;
    if (loading != null) return loading;
    if (banners.hasClients) banners.jumpToPage(0);
    final refresh = _load(retry ? errors.toList() : _HomeFeed.values);
    setState(() {
      active = 0;
      pending = refresh;
    });
    return refresh;
  }

  List<_Story> get stories {
    final online = data[_HomeFeed.online] ?? [];
    final classroom = data[_HomeFeed.classroom] ?? [];
    return [
      for (var i = 0; i < online.length || i < classroom.length; i++) ...[
        if (i < online.length) (catalog: Catalog.training, row: online[i]),
        if (i < classroom.length) (catalog: Catalog.courses, row: classroom[i]),
      ],
    ];
  }

  @override
  void dispose() {
    banners.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const loader = SizedBox(
      width: 120,
      child: LinearProgressIndicator(
        key: ValueKey('home-loading'),
        semanticsLabel: 'Нүүр хуудсыг ачаалж байна',
        minHeight: 3,
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
    );
    if (pending != null && data.isEmpty && errors.isEmpty) {
      return const Center(child: loader);
    }
    final storyRows = stories;
    final bannerRows = data[_HomeFeed.banners] ?? [];
    return LayoutBuilder(
      builder: (context, bounds) {
        final wide = bounds.maxWidth >= 700;
        final gutter = _homeGutter(bounds.maxWidth);
        final sections = <Widget>[
          if (pending != null) const Center(child: loader),
          if (errors.isNotEmpty && pending == null)
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errors.length == _HomeFeed.values.length
                            ? 'Нүүр хуудсыг ачаалж чадсангүй.'
                            : 'Зарим хэсгийг ачаалж чадсангүй.',
                      ),
                    ),
                    TextButton(
                      onPressed: () => _refresh(retry: true),
                      child: const Text('Дахин оролдох'),
                    ),
                  ],
                ),
              ),
            ),
          if (storyRows.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сургалтын стори',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                _CourseStories(api: widget.api, stories: storyRows),
              ],
            ),
          if (bannerRows.isNotEmpty)
            Stack(
              children: [
                SizedBox(
                  height: ((bounds.maxWidth - 2 * gutter) * .53).clamp(
                    170.0,
                    (MediaQuery.sizeOf(context).height * .44).clamp(
                      170.0,
                      310.0,
                    ),
                  ),
                  child: PageView.builder(
                    controller: banners,
                    itemCount: bannerRows.length,
                    onPageChanged: (page) => setState(() => active = page),
                    itemBuilder: (context, index) =>
                        _HeroBanner(row: bannerRows[index]),
                  ),
                ),
                if (bannerRows.length > 1)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _GlassPill(
                      icon: Icons.photo_library_outlined,
                      text:
                          '${active.clamp(0, bannerRows.length - 1) + 1} / ${bannerRows.length}',
                    ),
                  ),
              ],
            ),
          widget.gameTile,
          for (final (feed, catalog, title) in const [
            (_HomeFeed.online, Catalog.training, 'Танд зориулсан сургалтууд'),
            (_HomeFeed.products, Catalog.products, 'Шинэ бүтээгдэхүүн'),
            (_HomeFeed.classroom, Catalog.courses, 'Танхимын сургалт'),
          ])
            if (data[feed]?.isNotEmpty == true)
              _HomeShelf(
                api: widget.api,
                catalog: catalog,
                rows: data[feed]!,
                title: title,
              ),
        ];
        return RefreshIndicator.noSpinner(
          onRefresh: _refresh,
          child: ListView.separated(
            key: const PageStorageKey('oyudent-home'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(gutter, wide ? 24 : 14, gutter, 36),
            itemCount: sections.length,
            separatorBuilder: (_, _) => SizedBox(height: wide ? 32 : 24),
            itemBuilder: (_, index) => sections[index],
          ),
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.row});
  final Record row;

  @override
  Widget build(BuildContext context) {
    final title = text(row, ['title']);
    final description = text(row, ['description']);
    final photo = text(row, ['image_path']);
    return Semantics(
      button: true,
      label: title.isEmpty ? 'Баннер үзэх' : title,
      child: InkWell(
        onTap: () => _push(context, _BannerDetail(row: row)),
        child: ClipRRect(
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
                      colors: [Colors.transparent, Color(0xdd182e49)],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 64,
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
              const Positioned(
                right: 15,
                bottom: 15,
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: _highlight,
                  child: Icon(Icons.arrow_outward, size: 18, color: _night),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeShelf extends StatelessWidget {
  const _HomeShelf({
    required this.api,
    required this.catalog,
    required this.rows,
    required this.title,
  });
  final ProductionApi api;
  final Catalog catalog;
  final List<Record> rows;
  final String title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(width: 10),
          IconButton.outlined(
            tooltip: '$title — бүгдийг үзэх',
            onPressed: () => _openCatalog(context, api, catalog),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          ),
        ],
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, bounds) {
          final width = bounds.maxWidth;
          final wide = width >= 640;
          final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final courses =
              catalog == Catalog.training || catalog == Catalog.courses;
          if (courses && !wide) {
            return _CourseSlides(
              api: api,
              catalog: catalog,
              rows: rows,
              compact: true,
            );
          }
          if (wide) {
            final columns = courses || width < 840 ? 2 : 3;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final row in rows)
                  SizedBox(
                    width: (width - (columns - 1) * 16) / columns,
                    height:
                        (courses ? 235 : 228) + 64 * (scale - 1).clamp(0, 3),
                    child: courses
                        ? _CourseSlide(api: api, catalog: catalog, row: row)
                        : _WebStyleCard(
                            api: api,
                            catalog: catalog,
                            row: row,
                            compact: true,
                          ),
                  ),
              ],
            );
          }
          return SizedBox(
            height: 228 + 80 * (scale - 1).clamp(0, 3),
            child: ListView.separated(
              primary: false,
              scrollDirection: Axis.horizontal,
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: rows.length == 1
                    ? width
                    : (width * .63).clamp(174.0, 270.0),
                child: _WebStyleCard(
                  api: api,
                  catalog: catalog,
                  row: rows[i],
                  compact: true,
                ),
              ),
            ),
          );
        },
      ),
    ],
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
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _line),
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
              padding: const EdgeInsets.all(14),
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
      color: const Color(0xffe3ebf4),
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

class _BannerDetail extends StatelessWidget {
  const _BannerDetail({required this.row});
  final Record row;
  @override
  Widget build(BuildContext context) {
    final raw = text(row, ['url']);
    final uri = _https(
      raw.startsWith('/')
          ? Uri.https('oyudent.com').resolve(raw).toString()
          : raw.contains('://')
          ? raw
          : 'https://$raw',
    );
    final title = text(row, ['title']);
    final description = text(row, ['description']);
    return Scaffold(
      appBar: AppBar(title: Text(title.isEmpty ? 'Баннер' : title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FeatureHeader(
            title: title.isEmpty ? 'Баннер' : title,
            kind: 'Онцлох',
            image: text(row, ['image_path']),
            icon: Icons.photo_library_outlined,
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(description),
            ),
          if (raw.isNotEmpty && uri != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Холбоосыг нээх'),
                onPressed: () async {
                  try {
                    if (await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    )) {
                      return;
                    }
                  } catch (_) {}
                  if (context.mounted) {
                    _notice(context, 'Холбоосыг нээж чадсангүй.');
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
