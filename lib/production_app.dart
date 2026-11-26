import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'production_api.dart';
import 'device_workspace.dart';
import 'attendance_clock.dart';

import 'dart:ui' as ui;
part 'visual_system.dart';
part 'mobile_theme.dart';
part 'rewards.dart';
part 'personal_work.dart';
part 'clinic_booking.dart';
part 'daily_game.dart';
part 'course_stories.dart';

part 'production_flows.dart';
part 'production_home.dart';
part 'production_points.dart';
part 'course_slides.dart';

const _brand = Color(0xff176b71);
const _ink = Color(0xff172840);
const _background = Color(0xfff3f6fa);

class OyudentProductionApp extends StatelessWidget {
  const OyudentProductionApp({super.key, this.api});
  final ProductionApi? api;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Oyudent',
    debugShowCheckedModeBanner: false,
    theme: _mobileTheme,
    home: _OyudentHome(api: api),
  );
}

enum Catalog {
  brands('Бренд', 'partner/list', Icons.storefront_outlined),
  courses('Танхимын сургалт', 'course/no/list', Icons.event_outlined),
  training('Онлайн сургалт', 'training/catalog', Icons.play_circle_outline),
  products('Бүтээгдэхүүн', 'product/list', Icons.inventory_2_outlined),
  myTraining('Миний сургалт', 'training/my/list', Icons.school_outlined),
  enrollments(
    'Миний танхимын сургалт',
    'enrollment/list',
    Icons.event_available_outlined,
  ),
  certificates(
    'Сертификат',
    'training/certificate/list',
    Icons.workspace_premium_outlined,
  );

  const Catalog(this.label, this.path, this.icon);
  final String label, path;
  final IconData icon;

  String title(Record row) =>
      text(row, ['title', 'mn_name', 'name', 'course_title', 'course_name']);
  String summary(Record row) => text(row, [
    'short_desc',
    'short_body',
    'description',
    'location',
    'country_name',
  ]);
  String image(Record row) {
    final main = text(row, [
      'mainImage',
      'cover_image_url',
      'imagePath',
      'thumbnail',
      'image_path',
      'coverImageUrl',
      'image_path1',
      'image_path2',
    ]);
    if (main.isNotEmpty) return main;
    for (final photo in _records(row['images'])) {
      final url = text(photo, ['imagePath', 'image_path']);
      if (url.isNotEmpty) return url;
    }
    return '';
  }

  String? details(String id) => switch (this) {
    courses => 'course/detail/$id',
    training || myTraining => 'training/catalog/$id',
    products => 'product/$id',
    brands || enrollments => null,
    certificates => 'training/certificate/$id',
  };
}

String text(Record row, List<String> keys) {
  for (final key in keys) {
    final value = row[key];
    if (value is String && value.trim().isNotEmpty) {
      return value
          .replaceAll(
            RegExp(r'<(?:br\s*/?|/p|/div|/li)>', caseSensitive: false),
            '\n',
          )
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .trim();
    }
  }
  return '';
}

String? _registrationClosedReason(Record course) {
  if (course['is_active_registered'] == false) return 'Бүртгэл идэвхгүй';
  final remaining = num.tryParse(
    '${course['remaining_seats'] ?? course['available_seats']}',
  );
  if (remaining != null && remaining <= 0) return 'Суудал дүүрсэн';
  final deadline = DateTime.tryParse(course['end_date']?.toString() ?? '');
  if (deadline != null && DateTime.now().isAfter(deadline)) {
    return 'Бүртгэлийн хугацаа дууссан';
  }
  return null;
}

List<Record> _availableCourses(List<Record> rows) =>
    rows.where((r) => _registrationClosedReason(r) == null).toList();

String _message(Object error) =>
    error is ApiError ? error.message : 'Холболтоо шалгаад дахин оролдоно уу.';

class _OyudentHome extends StatefulWidget {
  const _OyudentHome({this.api});
  final ProductionApi? api;

  @override
  State<_OyudentHome> createState() => _OyudentHomeState();
}

class _OyudentHomeState extends State<_OyudentHome> {
  late final api = widget.api ?? ProductionApi();
  int tab = 0;
  int sessionRevision = 0;
  late final Future<void> session = api.restore().then<void>(
    (_) {},
    onError: (Object _) {},
  );

  Future<void> profile({bool forLogin = false}) async {
    await session;
    if (!mounted) return;
    await _push(
      context,
      Scaffold(
        appBar: AppBar(title: const Text('Профайл')),
        body: _Profile(api: api, returnAfterLogin: forLogin),
      ),
    );
    if (mounted) setState(() => sessionRevision++);
  }

  final Map<String, DeviceWorkspace> _workspaces = {};
  DeviceWorkspace get workspace {
    final owner = api.signedIn ? api.localOwner : 'device';
    if (owner == null) throw StateError('Account identity unavailable');
    return _workspaces.putIfAbsent(owner, () => DeviceWorkspace(owner));
  }

  Widget localPage(
    Widget Function(DeviceWorkspace) builder, {
    Widget pending = const Center(child: CircularProgressIndicator()),
  }) => FutureBuilder<void>(
    future: session,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return pending;
      }
      if (api.signedIn && api.localOwner == null) {
        return Center(
          child: TextButton(
            onPressed: profile,
            child: const Text('Профайлаа шалгах'),
          ),
        );
      }
      return _DevicePage(
        key: ValueKey(workspace.owner),
        store: workspace,
        builder: builder,
        pending: pending,
      );
    },
  );
  Future<void> cart() async {
    await session;
    if (!mounted) return;
    await _push(
      context,
      Scaffold(
        appBar: AppBar(title: const Text('Сагс')),
        body: localPage((store) => _RewardCart(api: api, store: store)),
      ),
    );
    if (mounted) setState(() => sessionRevision++);
  }

  Future<void> openLibrary() async {
    await session;
    if (!mounted) return;
    await _push(
      context,
      _LibraryPage(api: api, onLogin: () => profile(forLogin: true)),
    );
  }

  void attendance() => _push(
    context,
    Scaffold(
      appBar: AppBar(title: const Text('Хүний нөөц')),
      body: localPage((store) => _PersonalWork(store: store)),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 68,
      centerTitle: false,
      titleSpacing: 0,
      title: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gutter = _homeGutter(constraints.maxWidth);
              final actionStyle = IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _ink,
                minimumSize: const Size.square(44),
                side: const BorderSide(color: _line),
              );
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: Row(
                  children: [
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _BrandMark(),
                              SizedBox(width: 8),
                              Text(
                                'oyudent',
                                style: TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.4,
                                  fontSize: 25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _brand,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(44, 44),
                      ),
                      onPressed: attendance,
                      icon: const Icon(Icons.fingerprint, size: 20),
                      label: const Text('Ирц'),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Сагс',
                      style: actionStyle,
                      onPressed: cart,
                      icon: const Icon(Icons.shopping_bag_outlined),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Миний профайл',
                      style: actionStyle,
                      onPressed: () => profile(),
                      icon: const Icon(Icons.person_outline_rounded),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: IndexedStack(
          index: tab,
          children: [
            _Landing(
              api: api,
              gameTile: localPage(
                (store) => _GameTile(
                  played: store
                      .rows('game')
                      .any(
                        (r) => r['day'] == DeviceWorkspace.day(DateTime.now()),
                      ),
                  onTap: () => _push(context, _DailyGame(store: store)),
                ),
                pending: const SizedBox.shrink(),
              ),
            ),
            if (tab == 1)
              _CourseBrowse(api: api, onMyCourses: openLibrary)
            else
              const SizedBox.shrink(),
            if (tab == 2)
              localPage((s) => _ClinicBooking(store: s))
            else
              const SizedBox.shrink(),
            if (tab == 3)
              localPage(
                (s) => _PointsScreen(
                  key: ValueKey(sessionRevision),
                  api: api,
                  store: s,
                  onLogin: () => profile(forLogin: true),
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    ),
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: NavigationBar(
              height: 68,
              selectedIndex: tab,
              onDestinationSelected: (value) => setState(() => tab = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Нүүр',
                ),
                NavigationDestination(
                  icon: Icon(Icons.school_outlined),
                  selectedIcon: Icon(Icons.school),
                  label: 'Сургалт',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Цаг',
                ),
                NavigationDestination(
                  icon: Icon(Icons.stars_outlined),
                  selectedIcon: Icon(Icons.stars_rounded),
                  label: 'Оноо',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CourseBrowse extends StatelessWidget {
  const _CourseBrowse({required this.api, required this.onMyCourses});
  final ProductionApi api;
  final VoidCallback onMyCourses;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 16, 12),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 5,
          spacing: 12,
          children: [
            Text(
              'Сургалтууд',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
                color: _ink,
              ),
            ),
            TextButton.icon(
              key: const ValueKey('browse-my-courses'),
              onPressed: onMyCourses,
              icon: const Icon(Icons.collections_bookmark_outlined, size: 17),
              label: const Text('Миний сургалт'),
              style: TextButton.styleFrom(
                foregroundColor: _brand,
                backgroundColor: const Color(0xffe2efef),
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: _CourseFormats(
          online: _CatalogList(api: api, catalog: Catalog.training),
          classroom: _CatalogList(api: api, catalog: Catalog.courses),
        ),
      ),
    ],
  );
}

class _CourseFormats extends StatelessWidget {
  const _CourseFormats({required this.online, required this.classroom});
  final Widget online, classroom;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xffe6ecf1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: TabBar(
                dividerColor: Colors.transparent,
                dividerHeight: 0,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140d2b42),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: _brand,
                unselectedLabelColor: const Color(0xff4b5d71),
                labelStyle: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                splashBorderRadius: BorderRadius.circular(14),
                tabs: const [
                  _CourseFormatTab(Icons.smart_display_outlined, 'Онлайн'),
                  _CourseFormatTab(Icons.location_city_rounded, 'Танхим'),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: TabBarView(children: [online, classroom])),
      ],
    ),
  );
}

class _CourseFormatTab extends StatelessWidget {
  const _CourseFormatTab(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 46),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}

class _LibraryPage extends StatefulWidget {
  const _LibraryPage({required this.api, this.onLogin});
  final ProductionApi api;
  final Future<void> Function()? onLogin;
  @override
  State<_LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<_LibraryPage> {
  Future<void> login() async {
    await widget.onLogin?.call();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Миний сургалт')),
    body: SafeArea(
      child: widget.api.signedIn
          ? _myCourseFormats(widget.api)
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Color(0xffe5e8fb),
                      child: Icon(
                        Icons.collections_bookmark_outlined,
                        size: 27,
                        color: Color(0xff51579b),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Бүртгүүлсэн сургалт болон сертификатаа эндээс үзээрэй.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: widget.onLogin == null ? null : login,
                      icon: const Icon(Icons.login),
                      label: const Text('Миний сургалтыг үзэхийн тулд нэвтрэх'),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}

Widget _myCourseFormats(ProductionApi api) => _CourseFormats(
  online: _CatalogList(api: api, catalog: Catalog.myTraining),
  classroom: _CatalogList(api: api, catalog: Catalog.enrollments),
);

void _openCatalog(BuildContext context, ProductionApi api, Catalog catalog) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(catalog.label)),
        body: _CatalogList(api: api, catalog: catalog),
      ),
    ),
  );
}

class _CatalogList extends StatefulWidget {
  const _CatalogList({required this.api, required this.catalog, this.supplier});
  final ProductionApi api;
  final Catalog catalog;
  final String? supplier;

  @override
  State<_CatalogList> createState() => _CatalogListState();
}

class _CatalogListState extends State<_CatalogList>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Record>> _rows = _load();
  final _search = TextEditingController();
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Record>> _load() async {
    final query = <String, String>{'no_paginate': '1'};
    if (widget.catalog == Catalog.products) {
      if (widget.supplier != null) {
        query['supplier_id'] = widget.supplier!;
      } else {
        query['is_show_landing'] = 'true';
      }
    }
    final rows = await widget.api.list(
      Uri(path: widget.catalog.path, queryParameters: query).toString(),
      authenticated:
          widget.catalog == Catalog.myTraining ||
          widget.catalog == Catalog.certificates ||
          widget.catalog == Catalog.enrollments,
    );
    return widget.catalog == Catalog.courses ? _availableCourses(rows) : rows;
  }

  Future<void> _refresh() async {
    final request = _load();
    setState(() {
      _rows = request;
    });
    try {
      await request;
    } catch (_) {
      // The error is rendered by the list.
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Record>>(
      future: _rows,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _Retry(error: snapshot.error!, retry: _refresh);
        }
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          if (widget.catalog == Catalog.courses) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 31,
                      backgroundColor: Color(0xffe4e8fa),
                      child: Icon(
                        Icons.event_outlined,
                        color: Color(0xff505b98),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Танхимын шинэ сургалт алга',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: _ink, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Шинэчлэх'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: TextButton(
              onPressed: _refresh,
              child: Text(
                widget.catalog == Catalog.certificates
                    ? 'Олгосон сертификат алга · Шинэчлэх'
                    : switch (widget.catalog) {
                        Catalog.myTraining =>
                          'Онлайн сургалт бүртгэгдээгүй · Шинэчлэх',
                        Catalog.enrollments =>
                          'Танхимын сургалт бүртгэгдээгүй · Шинэчлэх',
                        _ => 'Мэдээлэл алга · Шинэчлэх',
                      },
              ),
            ),
          );
        }
        final catalog = widget.catalog;
        final searchable = [
          Catalog.products,
          Catalog.courses,
          Catalog.training,
          Catalog.brands,
          Catalog.certificates,
          Catalog.enrollments,
          Catalog.myTraining,
        ].contains(catalog);
        final filtered = rows
            .where(
              (row) => catalog
                  .title(row)
                  .toLowerCase()
                  .contains(_query.trim().toLowerCase()),
            )
            .toList();
        return Column(
          children: [
            if (searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Хайлтыг цэвэрлэх',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                    hintText: '${catalog.label} хайх',
                  ),
                ),
              ),
            if (filtered.isEmpty)
              const Expanded(
                child: Center(child: Text('Хайлтад тохирох мэдээлэл алга.')),
              )
            else if (catalog == Catalog.training || catalog == Catalog.courses)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _CourseSlides(
                        key: ValueKey((catalog, _query)),
                        api: widget.api,
                        catalog: catalog,
                        rows: filtered,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final row = filtered[index];
                      if (catalog == Catalog.products) {
                        return _WebStyleCard(
                          api: widget.api,
                          catalog: catalog,
                          row: row,
                        );
                      }
                      final title = catalog.title(row);
                      final description = catalog == Catalog.enrollments
                          ? [
                              _certificateDate(row['start_date']),
                              text(row, ['status_name']),
                              if (row['certificated'] == true) 'Сертификаттай',
                            ].where((value) => value.isNotEmpty).join(' · ')
                          : catalog.summary(row);
                      final progress = catalog == Catalog.myTraining
                          ? num.tryParse('${row['progress_percent']}')
                                ?.clamp(0, 100)
                          : null;
                      return Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: _Cover(
                            url: catalog.image(row),
                            icon: catalog.icon,
                            size: 58,
                          ),
                          title: Text(
                            title.isEmpty ? catalog.label : title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: progress != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Сургалтын явц · ${progress.round()}%',
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: progress / 100,
                                    ),
                                  ],
                                )
                              : description.isEmpty
                              ? null
                              : Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await _push(
                              context,
                              _Details(
                                api: widget.api,
                                catalog: catalog,
                                row: row,
                              ),
                            );
                            if (mounted &&
                                (catalog == Catalog.myTraining ||
                                    catalog == Catalog.enrollments)) {
                              await _refresh();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.icon, required this.size});
  final String url;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.https('oyudent.com').resolve(url);
    final placeholder = ColoredBox(
      color: const Color(0xffedf4f1),
      child: Center(child: Icon(icon, color: _brand)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty || uri.scheme != 'https'
            ? placeholder
            : Image.network(
                uri.toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _Details extends StatefulWidget {
  const _Details({
    required this.api,
    required this.catalog,
    required this.row,
    this.pointOnly = false,
    this.applyOnOpen = false,
    this.onPurchased,
  });
  final ProductionApi api;
  final Catalog catalog;
  final Record row;
  final bool pointOnly, applyOnOpen;
  final VoidCallback? onPurchased;

  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details> {
  String get _id =>
      (widget.catalog == Catalog.myTraining
              ? widget.row['course_id'] ?? widget.row['courseId']
              : widget.row['id'])
          ?.toString() ??
      '';
  late Future<Record> _detail = _load();

  Future<Record> _load() async {
    if (_id.isEmpty) return widget.row;
    final enrolled =
        widget.catalog == Catalog.myTraining &&
        widget.row['status_code'] == 'ACTIVE';
    final id = Uri.encodeComponent(_id);
    final path = enrolled ? 'training/learn/$id' : widget.catalog.details(id);
    if (path == null) return widget.row;
    final detail = await widget.api.detail(
      path,
      authenticated: enrolled || widget.catalog == Catalog.certificates,
    );
    final nested = detail['course'] ?? detail['product'];
    return {...widget.row, ...detail, if (nested is Record) ...nested};
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    return Scaffold(
      appBar: AppBar(title: Text(catalog.label)),
      body: FutureBuilder<Record>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final retry = _Retry(
              error: snapshot.error!,
              retry: () => setState(() {
                _detail = _load();
              }),
            );
            if (catalog != Catalog.myTraining) return retry;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _FeatureHeader(
                  title: catalog.title(widget.row),
                  kind: catalog.label,
                  icon: catalog.icon,
                  image: catalog.image(widget.row),
                ),
                _CourseCertificates(
                  api: widget.api,
                  courseId: _id,
                  modules: _records(widget.row['modules']),
                ),
                retry,
              ],
            );
          }
          final row = snapshot.data ?? widget.row;
          final description = text(row, [
            'body',
            'full_desc',
            'description',
            'short_desc',
            'short_body',
            'location',
          ]);
          final cover = catalog.image(row);
          return Column(
            children: [
              Expanded(
                flex: 1,
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _FeatureHeader(
                      title: catalog.title(row).isEmpty
                          ? catalog.label
                          : catalog.title(row),
                      kind: catalog.label,
                      icon: catalog.icon,
                      image: cover,
                      facts: [
                        if (text(row, [
                          'level_name',
                          'levelName',
                          'category_name',
                          'categoryName',
                        ]).isNotEmpty)
                          text(row, [
                            'level_name',
                            'levelName',
                            'category_name',
                            'categoryName',
                          ]),
                        if (row['lesson_count'] != null)
                          '${row['lesson_count']} хичээл',
                        if (catalog == Catalog.courses &&
                            _certificateDate(row['start_date']).isNotEmpty)
                          _certificateDate(row['start_date']),
                        if (row['price'] != null && catalog != Catalog.products)
                          '${row['price']} ₮',
                      ],
                    ),
                    if (catalog == Catalog.myTraining)
                      _CourseCertificates(
                        api: widget.api,
                        courseId: _id,
                        modules: _records(row['modules']),
                      ),
                    if (description.isNotEmpty)
                      _DetailSection(
                        title: 'Танилцуулга',
                        child: Text(
                          description,
                          style: const TextStyle(height: 1.55),
                        ),
                      ),
                    if (catalog == Catalog.products &&
                        _records(row['variants']).isNotEmpty)
                      _DetailSection(
                        title: 'Хувилбарууд',
                        child: Column(
                          children: [
                            for (final variant in _records(row['variants']))
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.layers_outlined),
                                title: Text(
                                  [
                                    text(variant, ['sizeName', 'unitName']),
                                    text(variant, ['colorName']),
                                    text(variant, ['sku']),
                                  ].where((v) => v.isNotEmpty).join(' · '),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (catalog == Catalog.enrollments)
                      _EnrollmentReceipt(data: row),
                    if (catalog == Catalog.certificates)
                      _CertificateView(data: row),
                    if (_records(row['modules']).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          'Дэд сургалтууд',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ..._courseOutline(
                      context,
                      row,
                      api: widget.api,
                      onReturn: () {
                        if (mounted) {
                          setState(() {
                            _detail = _load();
                          });
                        }
                      },
                      enrolled:
                          catalog == Catalog.myTraining &&
                          widget.row['status_code'] == 'ACTIVE',
                    ),
                  ],
                ),
              ),
              if (catalog == Catalog.courses ||
                  catalog == Catalog.training ||
                  (catalog == Catalog.myTraining &&
                      widget.row['status_code'] == 'PENDING'))
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * .48,
                        ),
                        child: SingleChildScrollView(
                          child: _CourseActions(
                            pointOnly: widget.pointOnly,
                            onPurchased: widget.onPurchased,
                            api: widget.api,
                            catalog: catalog,
                            data: row,
                            id: _id,
                            startOnOpen: widget.applyOnOpen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (catalog == Catalog.brands && _id.isNotEmpty)
                Expanded(
                  child: _CatalogList(
                    api: widget.api,
                    catalog: Catalog.products,
                    supplier: _id,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

List<Widget> _courseOutline(
  BuildContext context,
  Record row, {
  required ProductionApi api,
  required bool enrolled,
  required VoidCallback onReturn,
}) {
  return _records(row['modules']).map((module) {
    final lessons = _records(module['lessons']);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(text(module, ['title'])),
      subtitle: Text(
        enrolled
            ? '${lessons.where((lesson) => lesson['is_completed'] == true).length}/${lessons.length} хичээл'
            : '${lessons.length} хичээл',
      ),
      children: [
        for (final lesson in lessons)
          ListTile(
            title: Text(text(lesson, ['title'])),
            leading: Icon(
              lesson['is_completed'] == true
                  ? Icons.check_circle_outline
                  : Icons.play_circle_outline,
            ),
            enabled: enrolled || lesson['is_preview'] == true,
            onTap: () async {
              if (enrolled) {
                await _push(context, _LessonScreen(api: api, lesson: lesson));
                onReturn();
                return;
              }
              final uri = _https(text(lesson, ['video_url', 'videoUrl']));
              if (uri != null) {
                _push(
                  context,
                  _PreviewVideo(uri: uri, title: text(lesson, ['title'])),
                );
              }
            },
          ),
        if (enrolled && (module['question_count'] as num? ?? 0) > 0)
          ListTile(
            leading: const Icon(Icons.task_alt),
            title: const Text('Шалгалт'),
            onTap: () => _push(context, _QuizScreen(api: api, module: module)),
          ),
      ],
    );
  }).toList();
}

class _PreviewVideo extends StatefulWidget {
  const _PreviewVideo({required this.uri, required this.title});
  final Uri uri;
  final String title;
  @override
  State<_PreviewVideo> createState() => _PreviewVideoState();
}

class _PreviewVideoState extends State<_PreviewVideo> {
  late final _player = VideoPlayerController.networkUrl(widget.uri);
  late final _ready = _player.initialize();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Видеог нээж чадсангүй.'));
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: _player.value.aspectRatio,
              child: VideoPlayer(_player),
            ),
            VideoProgressIndicator(_player, allowScrubbing: true),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _player,
              builder: (context, value, _) => IconButton(
                tooltip: value.isPlaying ? 'Түр зогсоох' : 'Тоглуулах',
                onPressed: value.isPlaying ? _player.pause : _player.play,
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_message(error), textAlign: TextAlign.center),
          TextButton(onPressed: retry, child: const Text('Дахин оролдох')),
        ],
      ),
    ),
  );
}

class _Profile extends StatefulWidget {
  const _Profile({required this.api, this.returnAfterLogin = false});
  final bool returnAfterLogin;
  final ProductionApi api;

  @override
  State<_Profile> createState() => _ProfileState();
}

class _ProfileState extends State<_Profile> {
  final _phone = TextEditingController();
  final _phoneFocus = FocusNode();
  bool _libraryAfterLogin = false;
  final _password = TextEditingController();
  Record? _profile;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final profile = await widget.api.restore();
      if (mounted) setState(() => _profile = profile);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeSession({required bool logout}) async {
    if (_busy ||
        (!logout && (_phone.text.trim().isEmpty || _password.text.isEmpty))) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (logout) {
        await widget.api.logout();
        if (mounted) setState(() => _profile = null);
      } else {
        final profile = await widget.api.login(
          _phone.text.trim(),
          _password.text,
        );
        if (!mounted) return;
        _password.clear();
        setState(() => _profile = profile);
        if (widget.returnAfterLogin) {
          Navigator.pop(context);
        } else if (_libraryAfterLogin) {
          _libraryAfterLogin = false;
          await _openLibrary();
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLibrary() async {
    if (!widget.api.signedIn) {
      setState(() => _libraryAfterLogin = true);
      _phoneFocus.requestFocus();
      return;
    }
    await _push(context, _LibraryPage(api: widget.api));
  }

  @override
  void dispose() {
    _phone.dispose();
    _phoneFocus.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return AutofillGroup(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (profile != null) ...[
            Text(
              text(profile, [
                'fullName',
                'firstName',
                'first_name',
                'username',
              ]),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
          if (!widget.returnAfterLogin)
            Padding(
              padding: EdgeInsets.only(
                top: profile == null ? 0 : 12,
                bottom: profile == null ? 20 : 0,
              ),
              child: Material(
                color: const Color(0xffe7edf9),
                borderRadius: BorderRadius.circular(20),
                child: ListTile(
                  key: const ValueKey('profile-my-courses'),
                  enabled: !_busy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: const CircleAvatar(
                    foregroundColor: Color(0xff4f5794),
                    backgroundColor: Colors.white,
                    child: Icon(Icons.collections_bookmark_outlined),
                  ),
                  title: const Text(
                    'Миний сургалт',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    _libraryAfterLogin
                        ? 'Сургалтаа үзэхийн тулд нэвтэрнэ үү.'
                        : 'Бүртгэл, сургалтын явц, сертификат',
                  ),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: _openLibrary,
                ),
              ),
            ),
          if (profile != null) ...[
            _LearningProfile(api: widget.api),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Catalog.certificates.icon),
              title: Text(Catalog.certificates.label),
              onTap: () =>
                  _openCatalog(context, widget.api, Catalog.certificates),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Catalog.enrollments.icon),
              title: Text(Catalog.enrollments.label),
              onTap: () =>
                  _openCatalog(context, widget.api, Catalog.enrollments),
            ),
            OutlinedButton(
              onPressed: _busy ? null : () => _changeSession(logout: true),
              child: const Text('Гарах'),
            ),
          ] else ...[
            Text('Нэвтрэх', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: _phone,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(labelText: 'Утасны дугаар'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Нууц үг'),
              onSubmitted: (_) => _changeSession(logout: false),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : () => _changeSession(logout: false),
              child: const Text('Нэвтрэх'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _push(context, _SignupScreen(api: widget.api)),
              child: const Text('Бүртгүүлэх'),
            ),
          ],
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}
