part of 'production_app.dart';

enum _ScheduleView {
  week(
    '7 хоног',
    'Долоо хоногийн бүх үзлэгийг өдрөөр харах',
    Icons.view_week_outlined,
  ),
  month('Сар', 'Сарыг бүхэлд нь харах', Icons.calendar_month_outlined),
  agenda(
    'Жагсаалт',
    'Сарын бүх товыг огноогоор харах',
    Icons.view_agenda_outlined,
  );

  const _ScheduleView(this.label, this.hint, this.icon);
  final String label, hint;
  final IconData icon;
}

const _weekdays = [
  'Даваа',
  'Мягмар',
  'Лхагва',
  'Пүрэв',
  'Баасан',
  'Бямба',
  'Ням',
];
const _shortDays = ['Да', 'Мя', 'Лх', 'Пү', 'Ба', 'Бя', 'Ня'];
const _bookingTint = Color(0xffe9f2f4);
const _bookingMuted = Color(0xff536778);

class _ClinicBooking extends StatefulWidget {
  const _ClinicBooking({required this.store});
  final DeviceWorkspace store;
  @override
  State<_ClinicBooking> createState() => _ClinicBookingState();
}

class _ClinicBookingState extends State<_ClinicBooking> {
  DateTime day = DateUtils.dateOnly(DateTime.now());
  _ScheduleView view = _ScheduleView.week;

  Future<void> openInbox() async {
    final accepted = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(builder: (_) => _ClinicInbox(store: widget.store)),
    );
    if (mounted && accepted != null) {
      setState(() => day = DateUtils.dateOnly(accepted));
      _notice(context, 'Эмнэлгийн цагийг баталгаажууллаа.');
    }
  }

  Future<void> chooseView() async {
    final choice = await showModalBottomSheet<_ScheduleView>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Хуваарийн харагдац',
                style: Theme.of(sheet).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              for (final option in _ScheduleView.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    selected: option == view,
                    selectedTileColor: _bookingTint,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    leading: Icon(option.icon),
                    title: Text(
                      option.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(option.hint),
                    trailing: option == view
                        ? const Icon(Icons.check_circle_rounded)
                        : null,
                    onTap: () => Navigator.pop(sheet, option),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice != null && mounted) setState(() => view = choice);
  }

  void step(int delta) => setState(() {
    if (view == _ScheduleView.week) {
      day = DateUtils.addDaysToDate(day, delta * 7);
    } else {
      final month = DateTime(day.year, day.month + delta);
      day = DateTime(
        month.year,
        month.month,
        day.day.clamp(1, DateUtils.getDaysInMonth(month.year, month.month)),
      );
    }
  });

  Future<void> editLegacyVisit(LocalRow item) async {
    final updated = await showDialog<LocalRow>(
      context: context,
      builder: (_) => _VisitEditor(item: item),
    );
    if (updated == null || !mounted) return;
    try {
      await widget.store.update('appointments', (rows) {
        rows.removeWhere((r) => r['id'] == updated['id']);
        if (updated['remove'] != true) rows.add(updated);
      });
      if (mounted && updated['time'] != null) {
        setState(() => day = DateUtils.dateOnly(_localTime(updated['time'])));
      }
    } catch (_) {
      if (mounted) {
        _notice(context, 'Цагийг хадгалж чадсангүй. Дахин оролдоно уу.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.store.rows('appointments');
    final pending = all
        .where((r) => r['source'] == 'hospital' && r['status'] == 'pending')
        .length;
    final approved =
        all
            .where(
              (r) => r['source'] != 'hospital' || r['status'] == 'approved',
            )
            .toList()
          ..sort(
            (a, b) => _localTime(a['time']).compareTo(_localTime(b['time'])),
          );
    final weekly = view == _ScheduleView.week;
    final agenda = view == _ScheduleView.agenda;
    final monday = DateUtils.addDaysToDate(day, 1 - day.weekday);
    final weekDays = List.generate(
      7,
      (i) => DateUtils.addDaysToDate(monday, i),
    );
    final visitsByDay = <String, List<LocalRow>>{};
    for (final visit in approved) {
      final date = DeviceWorkspace.day(_localTime(visit['time']));
      (visitsByDay[date] ??= []).add(visit);
    }
    final weekCount = weekDays.fold<int>(
      0,
      (sum, date) =>
          sum + (visitsByDay[DeviceWorkspace.day(date)]?.length ?? 0),
    );
    final shown = approved.where((r) {
      final when = _localTime(r['time']);
      return agenda
          ? DateUtils.isSameMonth(day, when)
          : DateUtils.isSameDay(day, when);
    }).toList();
    final theme = Theme.of(context).textTheme;
    final today = DateTime.now();
    return ListView(
      key: const ValueKey('booking-schedule'),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        Text(
          'Миний цаг',
          style: theme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 14),
        _InboxBanner(
          key: const ValueKey('clinic-request-inbox'),
          pending: pending,
          onTap: openInbox,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Миний хуваарь',
                style: theme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.6,
                ),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('schedule-view-picker'),
              onPressed: chooseView,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _ink,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: Icon(view.icon, size: 17),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(view.label),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (weekly) ...[
          _WeekRangeHeader(
            first: monday,
            last: weekDays.last,
            count: weekCount,
            onPrevious: () => step(-1),
            onNext: () => step(1),
            onToday: weekDays.any((d) => DateUtils.isSameDay(d, today))
                ? null
                : () => setState(() => day = DateUtils.dateOnly(today)),
          ),
          const SizedBox(height: 16),
          for (final date in weekDays)
            _WeekDaySchedule(
              date: date,
              visits: visitsByDay[DeviceWorkspace.day(date)] ?? const [],
              onEdit: editLegacyVisit,
            ),
        ] else ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _line),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${day.year} оны ${day.month} сар',
                          style: theme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!DateUtils.isSameDay(day, today))
                        TextButton(
                          onPressed: () =>
                              setState(() => day = DateUtils.dateOnly(today)),
                          child: const Text('Өнөөдөр'),
                        ),
                      IconButton(
                        tooltip: 'Өмнөх',
                        onPressed: () => step(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      IconButton(
                        tooltip: 'Дараах',
                        onPressed: () => step(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  if (!agenda)
                    _BookingCalendar(
                      day: day,
                      scheduled: visitsByDay.keys.toSet(),
                      onDay: (d) => setState(() => day = d),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            agenda
                ? 'Энэ сарын тов'
                : '${_weekdays[day.weekday - 1]}, ${day.month} сарын ${day.day}',
            style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            _BookingEmpty(
              icon: Icons.event_available_rounded,
              title: 'Баталгаажсан цаг алга',
              detail: agenda
                  ? 'Энэ сарын баталгаажсан тов энд харагдана.'
                  : 'Эмнэлгээс ирсэн хүсэлтийг зөвшөөрөхөд цаг энд харагдана.',
            ),
          for (final item in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BookedVisit(
                item: item,
                includeDate: agenda,
                edit: item['source'] == 'hospital'
                    ? null
                    : () => editLegacyVisit(item),
              ),
            ),
        ],
      ],
    );
  }
}

class _InboxBanner extends StatelessWidget {
  const _InboxBanner({super.key, required this.pending, required this.onTap});
  final int pending;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xff213a58),
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _EnvelopeLines())),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.mark_email_unread_outlined,
                        color: Color(0xffbfeae9),
                        size: 25,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Эмнэлгийн хүсэлт',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pending == 0
                            ? 'Танд ирсэн цагийн хүсэлтүүд'
                            : '$pending хүсэлт хариу хүлээж байна',
                        style: const TextStyle(
                          color: Color(0xffd2e3ec),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xffd1eeee),
                  foregroundColor: Color(0xff18384d),
                  child: Icon(Icons.arrow_forward_rounded, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EnvelopeLines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0x2466c5ce);
    canvas.translate(size.width * .83, size.height * .49);
    canvas.rotate(-.32);
    for (final w in [65.0, 92.0, 119.0, 146.0]) {
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: w,
        height: w * .66,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        pen,
      );
      final flap = Path()
        ..moveTo(rect.left + 4, rect.top + 4)
        ..lineTo(0, rect.height * .10)
        ..lineTo(rect.right - 4, rect.top + 4);
      canvas.drawPath(flap, pen);
    }
  }

  @override
  bool shouldRepaint(_EnvelopeLines oldDelegate) => false;
}

class _WeekRangeHeader extends StatelessWidget {
  const _WeekRangeHeader({
    required this.first,
    required this.last,
    required this.count,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });
  final DateTime first, last;
  final int count;
  final VoidCallback onPrevious, onNext;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final range = first.year != last.year
        ? '${first.year}.${first.month}.${first.day} – ${last.year}.${last.month}.${last.day}'
        : first.month != last.month
        ? '${first.month} сарын ${first.day} – ${last.month} сарын ${last.day}'
        : '${first.month} сарын ${first.day}–${last.day}';
    final total = count == 0
        ? 'Баталгаажсан цаг алга'
        : '$count баталгаажсан цаг';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    range,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Өмнөх',
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  tooltip: 'Дараах',
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            Text(
              first.year == last.year ? '${first.year} он · $total' : total,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: _bookingMuted),
            ),
            if (onToday != null)
              TextButton.icon(
                onPressed: onToday,
                icon: const Icon(Icons.today_rounded, size: 16),
                label: const Text('Энэ долоо хоног'),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekDaySchedule extends StatelessWidget {
  const _WeekDaySchedule({
    required this.date,
    required this.visits,
    required this.onEdit,
  });
  final DateTime date;
  final List<LocalRow> visits;
  final ValueChanged<LocalRow> onEdit;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.isSameDay(date, DateTime.now());
    final type = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label:
                '${date.month} сарын ${date.day}, ${_weekdays[date.weekday - 1]}${today ? ', өнөөдөр' : ''}',
            excludeSemantics: true,
            child: SizedBox(
              width: 51,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: today ? _brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _shortDays[date.weekday - 1],
                        style: type.labelSmall?.copyWith(
                          color: today ? Colors.white : _bookingMuted,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: type.titleLarge?.copyWith(
                          color: today ? Colors.white : _ink,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: visits.isEmpty
                ? Container(
                    alignment: Alignment.centerLeft,
                    constraints: const BoxConstraints(minHeight: 47),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _line)),
                    ),
                    child: Text(
                      'Товгүй',
                      style: type.bodySmall?.copyWith(color: _bookingMuted),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, visit) in visits.indexed) ...[
                        if (index > 0) const SizedBox(height: 8),
                        _BookedVisit(
                          item: visit,
                          includeDate: false,
                          edit: visit['source'] == 'hospital'
                              ? null
                              : () => onEdit(visit),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookingCalendar extends StatelessWidget {
  const _BookingCalendar({
    required this.day,
    required this.scheduled,
    required this.onDay,
  });
  final DateTime day;
  final Set<String> scheduled;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context) {
    final anchor = DateTime(day.year, day.month);
    final first = DateUtils.addDaysToDate(anchor, 1 - anchor.weekday);
    final weeks =
        ((anchor.weekday -
            1 +
            DateUtils.getDaysInMonth(day.year, day.month) +
            6) ~/
        7);
    return Column(
      children: [
        Row(
          children: [
            for (final n in _shortDays)
              Expanded(
                child: Center(
                  child: Text(
                    n,
                    style: const TextStyle(fontSize: 12, color: _bookingMuted),
                  ),
                ),
              ),
          ],
        ),
        for (var row = 0; row < weeks; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final d = DateUtils.addDaysToDate(first, row * 7 + col);
                      final isSelected = DateUtils.isSameDay(d, day);
                      final has = scheduled.contains(DeviceWorkspace.day(d));
                      final isToday = DateUtils.isSameDay(d, DateTime.now());
                      return Semantics(
                        selected: isSelected,
                        button: true,
                        label:
                            '${DeviceWorkspace.day(d)}${has ? ' · Цаг захиалгатай' : ''}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 1,
                            vertical: 2,
                          ),
                          child: Material(
                            color: isSelected
                                ? _brand
                                : isToday
                                ? _bookingTint
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => onDay(d),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${d.day}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected || isToday
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : day.month == d.month
                                            ? _ink
                                            : _bookingMuted,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                      child: has
                                          ? Center(
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : _brand,
                                                ),
                                                child: const SizedBox(
                                                  width: 4,
                                                  height: 4,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _BookingEmpty extends StatelessWidget {
  const _BookingEmpty({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title, detail;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: _bookingTint,
          foregroundColor: _brand,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  color: _bookingMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BookedVisit extends StatelessWidget {
  const _BookedVisit({
    required this.item,
    required this.includeDate,
    required this.edit,
  });
  final LocalRow item;
  final bool includeDate;
  final VoidCallback? edit;

  @override
  Widget build(BuildContext context) {
    final start = _localTime(item['time']);
    final duration = int.tryParse('${item['durationMinutes']}') ?? 0;
    final end =
        DateTime.tryParse('${item['end']}')?.toLocal() ??
        (duration > 0 ? start.add(Duration(minutes: duration)) : null);
    final time = <String>[
      if (includeDate) '${start.month} сарын ${start.day} · ',
      _clockText(start),
      if (end != null && end.isAfter(start)) ...[
        ' – ',
        if (!DateUtils.isSameDay(start, end)) '${end.month}/${end.day} ',
        _clockText(end),
      ],
    ].join();
    final clinic = item['source'] == 'hospital';
    final hospital = text(item, ['hospital']);
    final title = text(item, ['title']);
    final service = text(item, ['service']);
    final patientName = text(item, ['patient', 'patient_name']);
    final patient = patientName.isNotEmpty
        ? patientName
        : (clinic && title != service ? title : '');
    final doctor = text(item, ['doctor']);
    final location = text(item, ['location']);
    final primary = clinic ? (service.isEmpty ? hospital : service) : title;
    final type = Theme.of(context).textTheme;
    final details = <(IconData, String, String)>[
      if (clinic && hospital.isNotEmpty && hospital != primary)
        (Icons.local_hospital_outlined, 'Эмнэлэг', hospital),
      if (patient.isNotEmpty) (Icons.person_outline_rounded, 'Өвчтөн', patient),
      if (doctor.isNotEmpty) (Icons.badge_outlined, 'Эмч', doctor),
      if (location.isNotEmpty) (Icons.place_outlined, 'Байршил', location),
    ];
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _line),
      ),
      child: InkWell(
        onTap: edit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      time,
                      style: type.labelLarge?.copyWith(
                        color: _brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (edit != null)
                    const Icon(
                      Icons.edit_outlined,
                      color: _bookingMuted,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                primary.isEmpty ? 'Үзлэг' : primary,
                style: type.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              for (final (icon, label, value) in details)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Semantics(
                    label: '$label: $value',
                    excludeSemantics: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(icon, size: 15, color: _bookingMuted),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            value,
                            style: type.bodySmall?.copyWith(
                              color: _bookingMuted,
                            ),
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
    );
  }
}

class _ClinicInbox extends StatefulWidget {
  const _ClinicInbox({required this.store});
  final DeviceWorkspace store;
  @override
  State<_ClinicInbox> createState() => _ClinicInboxState();
}

class _ClinicInboxState extends State<_ClinicInbox> {
  String? saving;

  Future<void> decide(LocalRow row, bool accept) async {
    if (saving != null) return;
    final id = row['id'] as String;
    setState(() => saving = id);
    try {
      final changed = await widget.store.decideRequest(id, accept);
      if (!mounted || !changed) return;
      if (accept) {
        Navigator.pop(context, _localTime(row['time']));
      } else {
        _notice(context, 'Цагийн хүсэлтээс татгалзлаа.');
      }
    } catch (_) {
      if (mounted) {
        _notice(context, 'Хариуг хадгалж чадсангүй. Дахин оролдоно уу.');
      }
    } finally {
      if (mounted) setState(() => saving = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Эмнэлгийн хүсэлт')),
    body: SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final requests =
              widget.store
                  .rows('appointments')
                  .where((r) => r['source'] == 'hospital')
                  .toList()
                ..sort(
                  (a, b) =>
                      _localTime(a['time']).compareTo(_localTime(b['time'])),
                );
          final pending = requests
              .where((r) => r['status'] == 'pending')
              .toList();
          final answered = requests
              .where(
                (r) => r['status'] == 'approved' || r['status'] == 'declined',
              )
              .toList()
              .reversed;
          final type = Theme.of(context).textTheme;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Text('Ирсэн хүсэлт', style: type.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    'Эмнэлгийн санал болгосон цагийг зөвшөөрөхөд таны хуваарьт нэмэгдэнэ.',
                    style: type.bodyMedium?.copyWith(color: _bookingMuted),
                  ),
                  const SizedBox(height: 20),
                  if (pending.isEmpty)
                    const _BookingEmpty(
                      icon: Icons.mark_email_read_outlined,
                      title: 'Шинэ хүсэлт алга',
                      detail: 'Хариу хүлээж буй цагийн хүсэлт энд харагдана.',
                    ),
                  for (final row in pending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RequestCard(
                        row: row,
                        saving: saving == row['id'],
                        onAccept: saving == null
                            ? () => decide(row, true)
                            : null,
                        onDecline: saving == null
                            ? () => decide(row, false)
                            : null,
                      ),
                    ),
                  if (answered.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text('Хариу өгсөн', style: type.titleMedium),
                    const SizedBox(height: 10),
                    for (final row in answered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RequestCard(row: row),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.row,
    this.onAccept,
    this.onDecline,
    this.saving = false,
  });
  final LocalRow row;
  final VoidCallback? onAccept, onDecline;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    final time = _localTime(row['time']);
    final pending = row['status'] == 'pending';
    final doctor = text(row, ['doctor']);
    final service = text(row, ['service']);
    final title = text(row, ['title']);
    final minutes = row['durationMinutes'];
    final timeLabel = minutes is int && minutes > 0
        ? '${_clockText(time)}–${_clockText(time.add(Duration(minutes: minutes)))}'
        : _clockText(time);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: _bookingTint,
                foregroundColor: _brand,
                child: Icon(Icons.local_hospital_outlined, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text(row, ['hospital']), style: type.titleMedium),
                    if (row['demo'] == true)
                      Text(
                        'Туршилтын хүсэлт',
                        style: type.labelMedium?.copyWith(color: _bookingMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _line),
          ),
          Text(
            service.isEmpty ? 'Үзлэгийн цаг' : service,
            style: type.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '${time.month} сарын ${time.day}, ${_weekdays[time.weekday - 1]} · $timeLabel',
            style: type.bodyMedium?.copyWith(color: _ink),
          ),
          if (doctor.isNotEmpty)
            Text(
              'Эмч · $doctor',
              style: type.bodyMedium?.copyWith(color: _bookingMuted),
            ),
          if (title.isNotEmpty && title != service)
            Text(
              'Өвчтөн · $title',
              style: type.bodyMedium?.copyWith(color: _bookingMuted),
            ),
          const SizedBox(height: 16),
          if (pending)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: Text(saving ? 'Хадгалж байна…' : 'Зөвшөөрөх'),
                ),
                OutlinedButton(
                  onPressed: onDecline,
                  child: const Text('Татгалзах'),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  row['status'] == 'approved'
                      ? Icons.event_available_rounded
                      : Icons.event_busy_outlined,
                  color: row['status'] == 'approved' ? _brand : _bookingMuted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  row['status'] == 'approved' ? 'Зөвшөөрсөн' : 'Татгалзсан',
                  style: type.labelLarge,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _VisitEditor extends StatefulWidget {
  const _VisitEditor({required this.item});
  final LocalRow item;
  @override
  State<_VisitEditor> createState() => _VisitEditorState();
}

class _VisitEditorState extends State<_VisitEditor> {
  late final title = TextEditingController(
    text: widget.item['title'] as String?,
  );
  late DateTime start = _localTime(widget.item['time']);
  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Цаг засах'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Захиалгын нэр'),
          ),
          TextButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: start,
                firstDate: DateTime(1900),
                lastDate: DateTime(2200),
              );
              if (d != null && mounted) {
                setState(
                  () => start = DateTime(
                    d.year,
                    d.month,
                    d.day,
                    start.hour,
                    start.minute,
                  ),
                );
              }
            },
            icon: const Icon(Icons.calendar_month),
            label: Text(DeviceWorkspace.day(start)),
          ),
          TextButton.icon(
            onPressed: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(start),
              );
              if (t != null && mounted) {
                setState(
                  () => start = DateTime(
                    start.year,
                    start.month,
                    start.day,
                    t.hour,
                    t.minute,
                  ),
                );
              }
            },
            icon: const Icon(Icons.schedule),
            label: Text(_clockText(start)),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () =>
            Navigator.pop(context, {'id': widget.item['id'], 'remove': true}),
        child: const Text('Устгах'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Болих'),
      ),
      FilledButton(
        onPressed: title.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, {
                ...widget.item,
                'title': title.text.trim(),
                'time': start.toUtc().toIso8601String(),
              }),
        child: const Text('Хадгалах'),
      ),
    ],
  );
}
