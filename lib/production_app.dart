import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'production_api.dart';

part 'production_flows.dart';
part 'production_home.dart';
part 'production_points.dart';

const _brand = Color(0xff5351ee);
const _ink = Color(0xff252851);
const _background = Color(0xfff0f3ff);
const _brandGradient = LinearGradient(
  colors: [Color(0xff6657ea), Color(0xff27b8df)],
);

class OyudentProductionApp extends StatelessWidget {
  const OyudentProductionApp({super.key, this.api});
  final ProductionApi? api;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Oyudent',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _brand),
      scaffoldBackgroundColor: _background,
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: _ink,
        displayColor: _ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffe1e4f6)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.white24,
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: Colors.white),
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
    home: _OyudentHome(api: api),
  );
}

enum Catalog {
  news('Мэдээ', 'news/list', Icons.article_outlined),
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
      text(row, ['title', 'mn_name', 'name', 'course_title']);
  String summary(Record row) => text(row, [
    'short_desc',
    'short_body',
    'description',
    'location',
    'country_name',
  ]);
  String image(Record row) => text(row, [
    'cover_image_url',
    'thumbnail',
    'image_path',
    'coverImageUrl',
  ]);

  String? details(String id) => switch (this) {
    news => 'news/list?id=$id',
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
  final deadline = DateTime.tryParse(course['end_date']?.toString() ?? '');
  if (deadline != null && DateTime.now().isAfter(deadline)) {
    return 'Бүртгэлийн хугацаа дууссан';
  }
  return null;
}

List<Record> _openCoursesFirst(List<Record> rows) => [
  ...rows.where((row) => _registrationClosedReason(row) == null),
  ...rows.where((row) => _registrationClosedReason(row) != null),
];

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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 68,
      title: tab == 0
          ? const Text(
              'oyudent',
              style: TextStyle(
                color: _brand,
                fontWeight: FontWeight.w900,
                fontSize: 28,
              ),
            )
          : Text(['Oyudent', 'Онооны дэлгүүр', 'Сургалт', 'Профайл'][tab]),
      actions: [
        if (tab != 3)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Миний профайл',
              onPressed: () => setState(() => tab = 3),
              icon: const CircleAvatar(
                backgroundColor: Color(0xffe1e5ff),
                child: Icon(Icons.person_outline, color: _brand),
              ),
            ),
          ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: IndexedStack(
          index: tab,
          children: [
            _Landing(api: api, onPoints: () => setState(() => tab = 1)),
            if (tab == 1)
              _PointsScreen(api: api, onLogin: () => setState(() => tab = 3))
            else
              const SizedBox.shrink(),
            _Training(api: api),
            _Profile(api: api),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _brandGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x305957da),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: NavigationBar(
            height: 66,
            selectedIndex: tab,
            onDestinationSelected: (index) => setState(() => tab = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Нүүр',
              ),
              NavigationDestination(
                icon: Icon(Icons.stars_outlined),
                label: 'Оноо',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                label: 'Сургалт',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Профайл',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Training extends StatelessWidget {
  const _Training({required this.api});
  final ProductionApi api;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        const TabBar(
          tabs: [
            Tab(text: 'Онлайн'),
            Tab(text: 'Танхим'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _CatalogList(api: api, catalog: Catalog.training),
              _CatalogList(api: api, catalog: Catalog.courses),
            ],
          ),
        ),
      ],
    ),
  );
}

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

class _CatalogListState extends State<_CatalogList> {
  late Future<List<Record>> _rows = _load();
  String _query = '';

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
    return widget.catalog == Catalog.courses ? _openCoursesFirst(rows) : rows;
  }

  Future<void> _refresh() async {
    final request = _load();
    setState(() => _rows = request);
    try {
      await request;
    } catch (_) {
      // The error is rendered by the list.
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Record>>(
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
        return Center(
          child: TextButton(
            onPressed: _refresh,
            child: const Text('Мэдээлэл алга · Шинэчлэх'),
          ),
        );
      }
      final catalog = widget.catalog;
      final searchable = [
        Catalog.products,
        Catalog.courses,
        Catalog.training,
        Catalog.brands,
        Catalog.news,
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
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: '${catalog.label} хайх',
                ),
              ),
            ),
          if (filtered.isEmpty)
            const Expanded(
              child: Center(child: Text('Хайлтад тохирох мэдээлэл алга.')),
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
                    if ([
                      Catalog.news,
                      Catalog.products,
                      Catalog.training,
                      Catalog.courses,
                    ].contains(catalog)) {
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
                        subtitle: description.isEmpty
                            ? null
                            : Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _Details(
                              api: widget.api,
                              catalog: catalog,
                              row: row,
                            ),
                          ),
                        ),
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
  });
  final ProductionApi api;
  final Catalog catalog;
  final Record row;
  final bool pointOnly;

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
    if (widget.catalog == Catalog.news) {
      final items = await widget.api.list(path);
      return items.isEmpty ? widget.row : items.first;
    }
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
            return _Retry(
              error: snapshot.error!,
              retry: () => setState(() => _detail = _load()),
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
                    if (cover.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _Cover(
                          url: cover,
                          icon: catalog.icon,
                          size: 132,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      catalog.title(row),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (text(row, ['level_name', 'levelName']).isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: Text(text(row, ['level_name', 'levelName'])),
                        ),
                      ),
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(description),
                      ),
                    if (catalog == Catalog.enrollments)
                      _EnrollmentReceipt(data: row),
                    if (catalog == Catalog.certificates)
                      _CertificateView(data: row),
                    if (catalog == Catalog.courses ||
                        catalog == Catalog.training ||
                        (catalog == Catalog.myTraining &&
                            widget.row['status_code'] == 'PENDING'))
                      _CourseActions(
                        api: widget.api,
                        catalog: catalog,
                        data: row,
                        id: _id,
                        pointOnly: widget.pointOnly,
                      ),
                    if (row['price'] != null &&
                        (catalog == Catalog.training ||
                            catalog == Catalog.myTraining))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('${row['price']} ₮'),
                      ),
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
                        if (mounted) setState(() => _detail = _load());
                      },
                      enrolled:
                          catalog == Catalog.myTraining &&
                          widget.row['status_code'] == 'ACTIVE',
                    ),
                  ],
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
  const _Profile({required this.api});
  final ProductionApi api;

  @override
  State<_Profile> createState() => _ProfileState();
}

class _ProfileState extends State<_Profile> {
  final _phone = TextEditingController();
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
      }
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
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
            _LearningProfile(api: widget.api),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Catalog.myTraining.icon),
              title: Text(Catalog.myTraining.label),
              onTap: () =>
                  _openCatalog(context, widget.api, Catalog.myTraining),
            ),
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
