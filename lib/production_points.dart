part of 'production_app.dart';

class _PointsScreen extends StatefulWidget {
  const _PointsScreen({
    required this.api,
    required this.onLogin,
    required this.store,
    super.key,
  });
  final ProductionApi api;
  final Future<void> Function() onLogin;
  final DeviceWorkspace store;

  @override
  State<_PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<_PointsScreen> {
  late Future<({Object? balance, List<Record> history, List<Record> courses})>
  _future = _load();

  Future<({Object? balance, List<Record> history, List<Record> courses})>
  _load() async {
    final result = await Future.wait([
      widget.api.signedIn
          ? widget.api.detail('doctor/point/balance', authenticated: true)
          : Future.value(<String, dynamic>{}),
      widget.api.signedIn
          ? widget.api.list(
              'doctor/point/transaction/list?size=10&sort=-created_at',
              authenticated: true,
            )
          : Future.value(<Record>[]),
      widget.api.list('training/catalog?no_paginate=1'),
    ]);
    return (
      balance: (result[0] as Record)['balance'],
      history: result[1] as List<Record>,
      courses: (result[2] as List<Record>)
          .where(
            (row) =>
                row['is_point_payable'] == true &&
                (num.tryParse(row['price_point'].toString()) ?? 0) > 0,
          )
          .toList(),
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {
      /* The screen displays the error. */
    }
  }

  String query = '';
  _RewardGroup group = _RewardGroup.all;
  _PointOrder order = _PointOrder.catalog;

  Future<void> showShopFilters() async {
    final result = await showModalBottomSheet<(_RewardGroup, _PointOrder)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ShopFilters(group: group, order: order),
    );
    if (result != null && mounted) {
      setState(() {
        group = result.$1;
        order = result.$2;
      });
    }
  }

  Future<void> openReward(Record r, bool product) async {
    await _push(
      context,
      product
          ? _SampleProduct(row: r, store: widget.store)
          : _Details(
              api: widget.api,
              catalog: Catalog.training,
              row: r,
              pointOnly: true,
              onPurchased: () => widget.store.removeCart(r['id']),
            ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _future,
    builder: (context, s) {
      final data = s.data;
      final items =
          <Record>[
                if (group != _RewardGroup.products) ...?data?.courses,
                if (group != _RewardGroup.courses) ..._samples,
              ]
              .where(
                (r) => Catalog.training
                    .title(r)
                    .toLowerCase()
                    .contains(query.trim().toLowerCase()),
              )
              .toList();
      num points(Record r) => num.tryParse('${r['price_point']}') ?? 0;
      if (order != _PointOrder.catalog) {
        items.sort((a, b) {
          final price = points(a).compareTo(points(b));
          if (price == 0) {
            return Catalog.training
                .title(a)
                .compareTo(Catalog.training.title(b));
          }
          return order == _PointOrder.lowest ? price : -price;
        });
      }
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
          children: [
            const _PageHeading(
              title: 'Онооны дэлгүүр',
              icon: Icons.stars_outlined,
            ),
            Container(
              decoration: BoxDecoration(
                color: _night,
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomPaint(
                painter: const _Contours(),
                child: Padding(
                  padding: const EdgeInsets.all(19),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Дансны оноо',
                              style: TextStyle(color: Colors.white70),
                            ),
                            if (widget.api.signedIn)
                              Text(
                                '${data?.balance ?? '—'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 33,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            else
                              TextButton(
                                onPressed: widget.onLogin,
                                style: TextButton.styleFrom(
                                  foregroundColor: _highlight,
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text('Нэвтрэх'),
                              ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 42, color: Colors.white24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              _push(context, _DailyGame(store: widget.store)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Бонус оноо',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '${widget.store.localPoints}',
                                style: const TextStyle(
                                  color: _highlight,
                                  fontSize: 33,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => query = v),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Онооны дэлгүүрээс хайх',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Дэлгүүрийн шүүлтүүр',
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  onPressed: showShopFilters,
                  icon: Badge(
                    isLabelVisible:
                        group != _RewardGroup.all ||
                        order != _PointOrder.catalog,
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${group.label} · ${items.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (s.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(),
            if (s.hasError)
              TextButton(
                onPressed: _refresh,
                child: const Text('Данс болон сургалтыг дахин ачаалах'),
              ),
            const SizedBox(height: 8),
            if (items.isEmpty && s.connectionState == ConnectionState.done)
              const Text('Хайлтад тохирох зүйл алга.'),
            LayoutBuilder(
              builder: (_, c) {
                final columns = c.maxWidth >= 800
                    ? 4
                    : c.maxWidth >= 540
                    ? 3
                    : c.maxWidth >= 300
                    ? 2
                    : 1;
                final width = (c.maxWidth - (columns - 1) * 10) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final r in items)
                      SizedBox(
                        width: width,
                        child: _RewardCard(
                          row: r,
                          product: r['panel'] != null,
                          added:
                              widget.store.inCart(r['id']) ||
                              widget.store.redeemed(r['id']),
                          onOpen: () => openReward(r, r['panel'] != null),
                          add:
                              widget.store.inCart(r['id']) ||
                                  widget.store.redeemed(r['id'])
                              ? null
                              : () async {
                                  try {
                                    await widget.store.addCart(r);
                                    if (context.mounted) {
                                      _notice(context, 'Сагсанд нэмлээ');
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      _notice(
                                        context,
                                        'Сагсыг хадгалж чадсангүй.',
                                      );
                                    }
                                  }
                                },
                        ),
                      ),
                  ],
                );
              },
            ),
            if (widget.store.rows('redemptions').isNotEmpty)
              ExpansionTile(
                title: const Text('Жишээ захиалгууд'),
                children: [
                  for (final r in widget.store.rows('redemptions').reversed)
                    ListTile(
                      title: Text(r['title']),
                      trailing: Text("${r['cost']} оноо"),
                    ),
                ],
              ),
            if (data != null && data.history.isNotEmpty)
              ExpansionTile(
                title: const Text('Онооны түүх'),
                children: [
                  for (final r in data.history)
                    ListTile(
                      title: Text(
                        text(r, ['reason', 'course_name', 'type_name']),
                      ),
                      subtitle: Text(text(r, ['issue_at', 'created_at'])),
                      trailing: Text('${r['point'] ?? '—'}'),
                    ),
                ],
              ),
          ],
        ),
      );
    },
  );
}

enum _RewardGroup {
  all('Бүгд'),
  products('Бүтээгдэхүүн'),
  courses('Сургалт');

  const _RewardGroup(this.label);
  final String label;
}

enum _PointOrder {
  catalog('Үндсэн дараалал'),
  lowest('Багаас их рүү'),
  highest('Ихээс бага руу');

  const _PointOrder(this.label);
  final String label;
}

class _ShopFilters extends StatefulWidget {
  const _ShopFilters({required this.group, required this.order});
  final _RewardGroup group;
  final _PointOrder order;
  @override
  State<_ShopFilters> createState() => _ShopFiltersState();
}

class _ShopFiltersState extends State<_ShopFilters> {
  late _RewardGroup group = widget.group;
  late _PointOrder order = widget.order;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Дэлгүүрийн шүүлтүүр',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Text('Ангилал', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final entry in _RewardGroup.values)
                ChoiceChip(
                  label: Text(entry.label),
                  selected: group == entry,
                  onSelected: (_) => setState(() => group = entry),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Оноогоор эрэмбэлэх',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          for (final entry in _PointOrder.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(entry.label),
              trailing: Icon(
                order == entry
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: order == entry ? _brand : const Color(0xff7c889b),
              ),
              selected: order == entry,
              onTap: () => setState(() => order = entry),
            ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => Navigator.pop(context, (group, order)),
            child: const Text('Харуулах'),
          ),
        ],
      ),
    ),
  );
}

class _RewardCart extends StatelessWidget {
  const _RewardCart({required this.api, required this.store});
  final ProductionApi api;
  final DeviceWorkspace store;
  @override
  Widget build(BuildContext context) {
    final items = store
        .rows('cart')
        .where((r) => !store.redeemed(r['id']))
        .toList();
    Future<void> remove(Object? id) async {
      try {
        await store.removeCart(id);
      } catch (_) {
        if (context.mounted) _notice(context, 'Сагсыг хадгалж чадсангүй.');
      }
    }

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 48, color: _brand),
            SizedBox(height: 12),
            Text('Сагс хоосон'),
            Text('Онооны дэлгүүрээс сонгоорой.'),
          ],
        ),
      );
    }
    final courseTotal = items
        .where((r) => r['panel'] == null)
        .fold<num>(0, (v, r) => v + (num.tryParse('${r['price_point']}') ?? 0));
    final sampleTotal = items
        .where((r) => r['panel'] != null)
        .fold<num>(0, (v, r) => v + (num.tryParse('${r['price_point']}') ?? 0));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (sampleTotal > 0) Text('Бонус оноо · $sampleTotal'),
        if (courseTotal > 0)
          Text(
            'Нийт · $courseTotal оноо',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        for (final r in items)
          Card(
            color: Colors.white,
            child: ListTile(
              title: Text(Catalog.training.title(r)),
              subtitle: Text(
                r['panel'] != null
                    ? '${r['price_point']} бонус оноо · Захиалах'
                    : '${r['price_point']} оноо · Захиалах',
              ),
              onTap: () => _push(
                context,
                r['panel'] != null
                    ? _SampleProduct(row: r, store: store)
                    : _Details(
                        api: api,
                        catalog: Catalog.training,
                        row: r,
                        pointOnly: true,
                        onPurchased: () => remove(r['id']),
                      ),
              ),
              trailing: IconButton(
                tooltip: 'Сагснаас хасах',
                onPressed: () => remove(r['id']),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ),
          ),
      ],
    );
  }
}

class _LearningProfile extends StatefulWidget {
  const _LearningProfile({required this.api});
  final ProductionApi api;

  @override
  State<_LearningProfile> createState() => _LearningProfileState();
}

class _LearningProfileState extends State<_LearningProfile> {
  late Future<({List<Record> owned, List<Record> catalog})> _data = _load();

  Future<({List<Record> owned, List<Record> catalog})> _load() async {
    final results = await Future.wait([
      widget.api.list('training/my/list?no_paginate=1', authenticated: true),
      widget.api.list('training/catalog?no_paginate=1'),
    ]);
    return (owned: results[0], catalog: results[1]);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton(
          onPressed: () => setState(() {
            _data = _load();
          }),
          child: const Text('Сургалтын явцыг дахин татах'),
        );
      }
      final data = snapshot.data;
      if (data == null) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        );
      }
      final complete = data.owned
          .where((row) => (row['progress_percent'] as num? ?? 0) >= 100)
          .toList();
      final completedIds = complete.map((row) => row['course_id']).toSet();
      final levels = data.catalog
          .where((row) => completedIds.contains(row['id']))
          .map((row) => text(row, ['level_name']))
          .where((name) => name.isNotEmpty)
          .toSet();
      final active = data.owned
          .where(
            (row) =>
                row['status_code'] == 'ACTIVE' &&
                !completedIds.contains(row['course_id']),
          )
          .length;
      return Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Сургалтын явц',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text('$active идэвхтэй · ${complete.length} дуусгасан'),
              if (levels.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Дуусгасан сургалтын түвшин'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final level in levels) Chip(label: Text(level)),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
