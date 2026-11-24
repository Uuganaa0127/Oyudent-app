import 'package:flutter/material.dart';

import 'ui_components.dart';
import 'clinics.dart';

class PatientVisit {
  final String name, hospital, reason;
  DateTime time;
  String status;
  PatientVisit(
    this.name,
    this.hospital,
    this.reason,
    this.time, {
    this.status = 'Хүлээгдэж буй',
  });
}

class Attendance {
  final DateTime start;
  DateTime? end;
  Attendance(this.start);
}

class WorkHub extends StatefulWidget {
  const WorkHub({super.key, this.calendar = false});
  final bool calendar;
  @override
  State<WorkHub> createState() => _WorkHubState();
}

class _WorkHubState extends State<WorkHub> {
  final attendance = <Attendance>[];
  final visits = <PatientVisit>[];
  DateTime selected = DateUtils.dateOnly(DateTime.now());
  bool hrView = false;
  bool dayView = false;
  bool monthView = false;
  int section = 0;
  @override
  void initState() {
    super.initState();
    section = widget.calendar ? 1 : 0;
    final today = DateUtils.dateOnly(DateTime.now());
    visits.addAll([
      PatientVisit(
        'Жишээ өвчтөн 1',
        'Төв шүдний эмнэлэг',
        'Анхны үзлэг',
        today.add(const Duration(days: 1, hours: 14)),
      ),
      PatientVisit(
        'Жишээ өвчтөн 2',
        'Хотын эмнэлэг',
        'Давтан үзлэг',
        today.add(const Duration(days: 1, hours: 10)),
      ),
      PatientVisit(
        'Жишээ өвчтөн 3',
        'Төв шүдний эмнэлэг',
        'Шүдний зөвлөгөө',
        today.add(const Duration(hours: 11)),
        status: 'Батлагдсан',
      ),
      ...List.generate(
        5,
        (i) => PatientVisit(
          'Жишээ өвчтөн ${i + 4}',
          'Төв шүдний эмнэлэг',
          'Давтан үзлэг',
          DateTime(today.year, today.month, today.day, 9 + i),
          status: 'Батлагдсан',
        ),
      ),
    ]);
  }

  String date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  Widget title(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Text(
      text,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
  );
  void notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Attendance? get active => attendance.where((a) => a.end == null).firstOrNull;
  @override
  void didUpdateWidget(covariant WorkHub oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calendar != widget.calendar) {
      section = widget.calendar ? 1 : 0;
    }
  }

  void accept(PatientVisit request) {
    if (request.time.isBefore(DateTime.now())) {
      notice(
        'Хүсэлтийн цаг өнгөрсөн байна. Эмнэлгээс шинэ цаг авах шаардлагатай.',
      );
      return;
    }
    setState(() {
      request.status = 'Батлагдсан';
      selected = DateUtils.dateOnly(request.time);
      section = 1;
    });
    notice('${date(request.time)} ${time(request.time)} цагийг баталлаа.');
  }

  DateTime get weekStart => DateTime(
    selected.year,
    selected.month,
    selected.day - selected.weekday + 1,
  );
  List<PatientVisit> appointments(DateTime day) =>
      visits
          .where(
            (v) => v.status == 'Батлагдсан' && DateUtils.isSameDay(v.time, day),
          )
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));
  Widget monthSchedule() {
    final first = DateTime(selected.year, selected.month, 1);
    final last = DateTime(selected.year, selected.month + 1, 0);
    final offset = first.weekday - 1;
    final cells = ((offset + last.day) / 7).ceil() * 7;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Өмнөх сар',
              onPressed: () => setState(
                () => selected = DateTime(first.year, first.month - 1, 1),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${first.year} он • ${first.month} сар',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Дараах сар',
              onPressed: () => setState(
                () => selected = DateTime(first.year, first.month + 1, 1),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                setState(() => selected = DateUtils.dateOnly(DateTime.now())),
            child: const Text('Өнөөдөр'),
          ),
        ),
        const Row(
          children: [
            Expanded(child: Center(child: Text('Да'))),
            Expanded(child: Center(child: Text('Мя'))),
            Expanded(child: Center(child: Text('Лх'))),
            Expanded(child: Center(child: Text('Пү'))),
            Expanded(child: Center(child: Text('Ба'))),
            Expanded(child: Center(child: Text('Бя'))),
            Expanded(child: Center(child: Text('Ня'))),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          key: const ValueKey('month-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 70,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (ctx, i) {
            final n = i - offset + 1;
            if (n < 1 || n > last.day) return const SizedBox();
            final d = DateTime(first.year, first.month, n);
            final count = appointments(d).length;
            final active = DateUtils.isSameDay(d, selected);
            return Material(
              color: active ? const Color(0xFF5351EE) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => setState(() => selected = d),
                borderRadius: BorderRadius.circular(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$n',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white24
                              : const Color(0xFFD9EFEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            color: active
                                ? Colors.white
                                : const Color(0xFF5351EE),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        title('${date(selected)} • ${appointments(selected).length} үзлэг'),
        if (appointments(selected).isEmpty)
          const Text('Энэ өдөр цаг захиалаагүй.'),
        ...appointments(selected).map(
          (v) => HoverCard(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.schedule, color: Color(0xFF5351EE)),
              title: Text('${time(v.time)} • ${v.name}'),
              subtitle: Text('${v.hospital}\n${v.reason}'),
              isThreeLine: true,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget weekSchedule() {
    final start = weekStart;
    final days = List.generate(
      7,
      (i) => DateTime(start.year, start.month, start.day + i),
    );
    final count = days.fold<int>(0, (sum, d) => sum + appointments(d).length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            IconButton(
              tooltip: 'Өмнөх долоо хоног',
              onPressed: () => setState(
                () =>
                    selected = DateTime(start.year, start.month, start.day - 7),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${date(start)} – ${date(days.last)}',
              key: const ValueKey('week-range'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              tooltip: 'Дараах долоо хоног',
              onPressed: () => setState(
                () =>
                    selected = DateTime(start.year, start.month, start.day + 7),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
            TextButton(
              onPressed: () =>
                  setState(() => selected = DateUtils.dateOnly(DateTime.now())),
              child: const Text('Энэ долоо хоног'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '$count үзлэг • Нэг үзлэг 30 минут',
            style: const TextStyle(color: Color(0xFF5351EE)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: days
              .map(
                (d) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: DateUtils.isSameDay(d, selected)
                          ? const Color(0xFF5351EE)
                          : const Color(0xFFE1EFF3),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() {
                          selected = d;
                          dayView = true;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            children: [
                              Text(
                                [
                                  'Да',
                                  'Мя',
                                  'Лх',
                                  'Пү',
                                  'Ба',
                                  'Бя',
                                  'Ня',
                                ][d.weekday - 1],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: DateUtils.isSameDay(d, selected)
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${d.day}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: DateUtils.isSameDay(d, selected)
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${appointments(d).length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: DateUtils.isSameDay(d, selected)
                                      ? Colors.white
                                      : const Color(0xFF5351EE),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850 && !dayView;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: days
                  .where((d) => !dayView || DateUtils.isSameDay(d, selected))
                  .map((d) {
                    final today = DateUtils.isSameDay(d, DateTime.now());
                    final bookings = appointments(d);
                    return Container(
                      key: ValueKey('day-${date(d)}'),
                      width: wide
                          ? (constraints.maxWidth - 48) / 7
                          : constraints.maxWidth,
                      constraints: BoxConstraints(minHeight: wide ? 380 : 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: today ? const Color(0xFFF0F6EB) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: today
                              ? const Color(0xFF5351EE)
                              : const Color(0xFFE1E9E7),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${['Дав', 'Мяг', 'Лха', 'Пүр', 'Баа', 'Бям', 'Ням'][d.weekday - 1]} ${d.day}/${d.month}${today ? ' • Өнөөдөр' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (bookings.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                'Цаг захиалаагүй',
                                style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ...bookings.map(
                            (v) => Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Material(
                                color: const Color(0xFFDCEEEF),
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => showDialog<void>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(v.name),
                                      content: Text(
                                        '${date(v.time)} • ${time(v.time)}\n30 минут • Батлагдсан\n${v.reason}\n${v.hospital}',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Хаах'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          time(v.time),
                                          style: const TextStyle(
                                            color: Color(0xFF5351EE),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          v.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          v.reason,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'Үзлэг дээр дарж дэлгэрэнгүй мэдээллийг харна уу.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      title(widget.calendar ? 'Миний цаг захиалга' : 'Миний ажлын өдөр'),
      Text(
        widget.calendar
            ? 'Долоо хоногийн бүх үзлэг нэг дор.'
            : 'Ирцээ бүртгүүлж, ажилласан цагаа хараарай.',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 16),
      const Text(
        'Туршилтын мэдээлэл • Бодит эмнэлэгтэй холбогдоогүй',
        style: TextStyle(color: Color(0xFF5351EE)),
      ),
      const SizedBox(height: 18),
      if (widget.calendar)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Хуваарь'),
              selected: section == 1,
              onSelected: (_) => setState(() => section = 1),
            ),
            ChoiceChip(
              label: Text(
                'Өвчтөний хүсэлт (${visits.where((v) => v.status == 'Хүлээгдэж буй').length})',
              ),
              selected: section == 2,
              onSelected: (_) => setState(() => section = 2),
            ),
            ChoiceChip(
              label: const Text('Миний эмнэлгүүд'),
              selected: section == 3,
              onSelected: (_) => setState(() => section = 3),
            ),
          ],
        ),
      if (section == 3) const MyClinics(),
      if (section == 0) ...[
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Хүний нөөцийн харагдац'),
          subtitle: const Text(
            'Туршилтын горим. Бодит системд нэвтрэх эрх шаардлагатай.',
          ),
          value: hrView,
          onChanged: (v) => setState(() => hrView = v),
        ),
        title(hrView ? 'Ажилтны ирц' : 'Миний ирц'),
        HoverCard(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${attendance.map((a) => date(a.start)).toSet().length} өдөр ажилласан',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ажилласан хугацаа: ${attendance.fold<int>(0, (sum, a) => sum + (a.end ?? DateTime.now()).difference(a.start).inMinutes)} минут',
                ),
                const SizedBox(height: 10),
                Text(
                  active == null
                      ? 'Ажил дууссан'
                      : 'Ажил эхэлсэн: ${time(active!.start)}',
                ),
                if (!hrView) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => setState(() {
                      if (active == null) {
                        attendance.add(Attendance(DateTime.now()));
                      } else {
                        active!.end = DateTime.now();
                      }
                    }),
                    icon: Icon(active == null ? Icons.login : Icons.logout),
                    label: Text(active == null ? 'Ирсэн' : 'Явсан'),
                  ),
                ],
              ],
            ),
          ),
        ),
        title('Ирцийн огноо'),
        if (attendance.isEmpty)
          const Text('Ирц бүртгэгдээгүй. Ирсэн товчийг дарж бүртгүүлнэ үү.'),
        ...attendance.reversed.map(
          (a) => HoverCard(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(
                '${hrView ? 'Туршилтын эмч • ' : ''}${date(a.start)}',
              ),
              subtitle: Text(
                '${time(a.start)} → ${a.end == null ? 'Ажиллаж байна' : time(a.end!)}',
              ),
              trailing: Text(
                '${(a.end ?? DateTime.now()).difference(a.start).inMinutes} мин',
              ),
            ),
          ),
        ),
      ],
      if (section == 1) ...[
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () => setState(() {
              monthView = !monthView;
              dayView = false;
            }),
            icon: Icon(
              monthView ? Icons.view_week_outlined : Icons.calendar_month,
            ),
            label: Text(monthView ? '7 хоногийн хуваарь' : 'Сараар харах'),
          ),
        ),
        if (monthView) monthSchedule() else weekSchedule(),
      ],
      if (section == 2) ...[
        title('Эмнэлгээс ирсэн хүсэлтүүд'),
        const Text(
          'Эмнэлгээс үзлэгийн огноо, цагийг илгээнэ. Хүлээн авмагц календарьт нэмэгдэнэ.',
        ),
        const SizedBox(height: 16),
        ...visits
            .where((v) => v.hospital != 'Oyudent clinic')
            .map(
              (v) => HoverCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${v.hospital}\n${v.reason}\nХүссэн цаг: ${date(v.time)} ${time(v.time)}',
                        style: const TextStyle(height: 1.6),
                      ),
                      const SizedBox(height: 10),
                      StatusBadge(v.status),
                      if (v.status == 'Хүлээгдэж буй')
                        Wrap(
                          spacing: 12,
                          children: [
                            FilledButton(
                              onPressed: () => accept(v),
                              child: const Text('Хүлээн авах'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => v.status = 'Татгалзсан'),
                              child: const Text('Татгалзах'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    ],
  );
}
