part of 'production_app.dart';

class _PointsScreen extends StatefulWidget {
  const _PointsScreen({required this.api, required this.onLogin});
  final ProductionApi api;
  final VoidCallback onLogin;

  @override
  State<_PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<_PointsScreen> {
  late Future<({Object? balance, List<Record> history, List<Record> courses})>
  _future = _load();

  Future<({Object? balance, List<Record> history, List<Record> courses})>
  _load() async {
    if (!widget.api.signedIn) {
      return (balance: null, history: <Record>[], courses: <Record>[]);
    }
    final result = await Future.wait([
      widget.api.detail('doctor/point/balance', authenticated: true),
      widget.api.list(
        'doctor/point/transaction/list?size=10&sort=-created_at',
        authenticated: true,
      ),
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
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {
      /* The screen displays the error. */
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.api.signedIn) {
      return Center(
        child: FilledButton(
          onPressed: widget.onLogin,
          child: const Text('Нэвтрэх'),
        ),
      );
    }
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Retry(error: snapshot.error!, retry: _refresh);
        }
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: _brandGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Боломжит оноо',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      '${data.balance ?? '—'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Оноогоор авах сургалт',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (data.courses.isEmpty) const Text('Одоогоор сургалт алга.'),
              for (final course in data.courses)
                Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(Catalog.training.title(course)),
                    subtitle: Text('${course['price_point']} оноо'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await _push(
                        context,
                        _Details(
                          api: widget.api,
                          catalog: Catalog.training,
                          row: course,
                          pointOnly: true,
                        ),
                      );
                      if (mounted) await _refresh();
                    },
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Онооны түүх',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (data.history.isEmpty) const Text('Гүйлгээ алга.'),
              for (final row in data.history)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    text(row, ['reason', 'course_name', 'type_name']),
                  ),
                  subtitle: Text(text(row, ['issue_at', 'created_at'])),
                  trailing: Text('${row['point'] ?? '—'}'),
                ),
            ],
          ),
        );
      },
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
          onPressed: () => setState(() => _data = _load()),
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
