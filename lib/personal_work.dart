part of 'production_app.dart';

class _DevicePage extends StatefulWidget {
  const _DevicePage({
    super.key,
    required this.store,
    required this.builder,
    required this.pending,
  });
  final DeviceWorkspace store;
  final Widget pending;
  final Widget Function(DeviceWorkspace) builder;
  @override
  State<_DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<_DevicePage> {
  late Future<void> ready = widget.store.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: ready,
    builder: (context, s) {
      if (s.hasError) {
        return Center(
          child: TextButton(
            onPressed: () => setState(() {
              ready = widget.store.load();
            }),
            child: const Text('Төхөөрөмжийн мэдээллийг дахин унших'),
          ),
        );
      }
      if (s.connectionState != ConnectionState.done) {
        return widget.pending;
      }
      return ListenableBuilder(
        listenable: widget.store,
        builder: (_, _) => widget.builder(widget.store),
      );
    },
  );
}

String _clockText(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
DateTime _localTime(Object? value) =>
    DateTime.parse(value.toString()).toLocal();

class _PersonalWork extends StatefulWidget {
  const _PersonalWork({required this.store});
  final DeviceWorkspace store;
  @override
  State<_PersonalWork> createState() => _PersonalWorkState();
}

class _PersonalWorkState extends State<_PersonalWork> {
  DateTime selected = DateUtils.dateOnly(DateTime.now());
  void step(int direction) {
    setState(() {
      final month = DateTime(selected.year, selected.month + direction);
      selected = DateTime(
        month.year,
        month.month,
        selected.day.clamp(
          1,
          DateUtils.getDaysInMonth(month.year, month.month),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final month = DateTime(selected.year, selected.month);
    final next = DateTime(selected.year, selected.month + 1);
    final now = DateTime.now();
    final shifts = widget.store.rows('shifts');
    final periods = <({DateTime start, DateTime end, bool active})>[];
    for (final r in shifts.reversed) {
      final start = _localTime(r['start']);
      final end = r['end'] == null ? now : _localTime(r['end']);
      if (start.isBefore(next) &&
          (end.isAfter(month) || !start.isBefore(month))) {
        periods.add((
          start: start.isBefore(month) ? month : start,
          end: end.isAfter(next) ? next : end,
          active: r['end'] == null && !now.isAfter(next),
        ));
      }
    }
    final total = periods.fold<int>(
      0,
      (v, p) => v + p.end.difference(p.start).inMinutes,
    );
    final monthBar = Row(
      children: [
        Expanded(
          child: Text(
            '${selected.year} оны ${selected.month} сар',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
          ),
        ),
        IconButton(
          tooltip: 'Өмнөх',
          onPressed: () => step(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Дараах',
          onPressed: () => step(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        const _PageHeading(title: 'Ажлын ирц', icon: Icons.fingerprint),
        AttendanceClock(store: widget.store),
        const SizedBox(height: 18),
        monthBar,
        _DetailSection(
          title: 'Ажилласан хугацаа',
          child: Text(
            '${total ~/ 60} ц ${total % 60} мин',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _brand,
            ),
          ),
        ),
        if (periods.isEmpty)
          const ListTile(title: Text('Энэ сард ирц бүртгэгдээгүй.')),
        for (final p in periods)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule, color: _brand),
            title: Text(DeviceWorkspace.day(p.start)),
            subtitle: Text(
              '${_clockText(p.start)} – ${p.active ? 'Ажиллаж байна' : (DateUtils.isSameDay(p.start, p.end) ? _clockText(p.end) : '${DeviceWorkspace.day(p.end)} ${_clockText(p.end)}')}',
            ),
          ),
      ],
    );
  }
}
