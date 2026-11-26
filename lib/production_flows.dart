part of 'production_app.dart';

List<Record> _records(Object? value) =>
    value is List ? value.whereType<Record>().toList() : [];

Uri? _https(String value) {
  final uri = Uri.tryParse(value);
  return uri?.scheme == 'https' && uri!.host.isNotEmpty && uri.userInfo.isEmpty
      ? uri
      : null;
}

Future<void> _push(BuildContext context, Widget page) =>
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => page));

void _notice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _SignupScreen extends StatefulWidget {
  const _SignupScreen({required this.api});
  final ProductionApi api;

  @override
  State<_SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<_SignupScreen> {
  static const labels = {
    'lastName': 'Овог',
    'firstName': 'Нэр',
    'registerNumber': 'Регистр',
    'position': 'Мэргэжил',
    'username': 'Утасны дугаар',
    'email': 'Имэйл',
    'password': 'Нууц үг',
  };
  final form = GlobalKey<FormState>();
  final fields = {for (final key in labels.keys) key: TextEditingController()};
  bool busy = false;

  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  String? validate(String key, String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return 'Талбарыг бөглөнө үү';
    if (key == 'username' && !RegExp(r'^(\+976)?\d{8}$').hasMatch(value)) {
      return 'Дугаараа шалгана уу';
    }
    if (key == 'email' && !RegExp(r'^\S+@\S+\.\S+$').hasMatch(value)) {
      return 'Имэйлээ шалгана уу';
    }
    if (key == 'registerNumber' &&
        !RegExp(r'^[А-ЯӨҮA-Z]{2}\d{8}$').hasMatch(value.toUpperCase())) {
      return 'Регистрээ шалгана уу';
    }
    if (key == 'password' && value.length < 6) {
      return '6 ба түүнээс олон тэмдэгт оруулна уу';
    }
    return null;
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await widget.api.submit('doctor/signup', {
        for (final entry in fields.entries)
          entry.key: switch (entry.key) {
            'password' => entry.value.text,
            'registerNumber' => entry.value.text.trim().toUpperCase(),
            _ => entry.value.text.trim(),
          },
      }, authenticated: false);
      if (!mounted) return;
      _notice(context, 'Бүртгэлийн хүсэлт илгээгдлээ.');
      Navigator.pop(context);
    } catch (error) {
      if (mounted) _notice(context, _message(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Бүртгүүлэх')),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final entry in labels.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  enabled: !busy,
                  controller: fields[entry.key],
                  decoration: InputDecoration(labelText: entry.value),
                  obscureText: entry.key == 'password',
                  keyboardType: switch (entry.key) {
                    'username' => TextInputType.phone,
                    'email' => TextInputType.emailAddress,
                    _ => TextInputType.text,
                  },
                  validator: (value) => validate(entry.key, value),
                ),
              ),
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Илгээж байна…' : 'Бүртгүүлэх'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CourseActions extends StatefulWidget {
  const _CourseActions({
    required this.api,
    required this.catalog,
    required this.data,
    required this.id,
    this.pointOnly = false,
    this.startOnOpen = false,
    this.onPurchased,
  });
  final ProductionApi api;
  final Catalog catalog;
  final Record data;
  final String id;
  final bool pointOnly, startOnOpen;
  final VoidCallback? onPurchased;

  @override
  State<_CourseActions> createState() => _CourseActionsState();
}

class _CourseActionsState extends State<_CourseActions> {
  bool busy = false;
  bool enrolled = false;
  Record? purchase;

  @override
  void initState() {
    super.initState();
    if (widget.startOnOpen &&
        widget.catalog == Catalog.courses &&
        _registrationClosedReason(widget.data) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _start();
      });
    }
  }

  Future<bool> _confirm(String label) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(label),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Болих'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Баталгаажуулах'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _start() async {
    if (busy || widget.id.isEmpty) return;
    setState(() => busy = true);
    try {
      if (!widget.api.signedIn) {
        await _push(
          context,
          Scaffold(
            appBar: AppBar(title: const Text('Профайл')),
            body: _Profile(api: widget.api, returnAfterLogin: true),
          ),
        );
        if (!mounted || !widget.api.signedIn) return;
      }
      if (widget.catalog == Catalog.courses) {
        final prices = await widget.api.list(
          Uri(
            path: 'course/price/list',
            queryParameters: {'no_paginate': '1', 'course_id': widget.id},
          ).toString(),
        );
        if (!mounted) return;
        final choice = await _pick(
          'Бүртгэлийн багц',
          prices,
          (p) => '${p['name'] ?? ''} · ${p['price'] ?? '—'} ₮',
        );
        if (choice == null ||
            !mounted ||
            !await _confirm('Сургалтын бүртгэл илгээх')) {
          return;
        }
        await widget.api.submit('enrollment/', {
          'courseId': widget.id,
          'coursePriceId': choice['id'],
        });
        if (!mounted) return;
        setState(() => enrolled = true);
        _openCatalog(context, widget.api, Catalog.enrollments);
        return;
      }
      final choices = [
        if (!widget.pointOnly && widget.data['is_cash_payable'] == true)
          {
            'id': 'CASH',
            'label': 'Банкны шилжүүлэг · ${widget.data['price']} ₮',
          },
        if (widget.data['is_point_payable'] == true)
          {'id': 'POINT', 'label': 'Оноо · ${widget.data['price_point']}'},
      ];
      final choice = await _pick(
        'Төлбөрийн хэлбэр',
        choices,
        (p) => p['label'].toString(),
      );
      if (choice == null ||
          !mounted ||
          !await _confirm(choice['label'].toString())) {
        return;
      }
      final result = await widget.api.submit('training/purchase', {
        'courseId': widget.id,
        'paymentType': choice['id'],
      });
      widget.onPurchased?.call();
      if (mounted) setState(() => purchase = result);
    } catch (error) {
      if (mounted) _notice(context, _message(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<Record?> _pick(
    String title,
    List<Record> choices,
    String Function(Record) label,
  ) async {
    if (choices.isEmpty) {
      _notice(context, 'Сонгох боломжтой багц алга.');
      return null;
    }
    return showModalBottomSheet<Record>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(title, style: Theme.of(sheet).textTheme.titleMedium),
            ),
            for (final choice in choices)
              ListTile(
                title: Text(label(choice)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(sheet, choice),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = purchase ?? widget.data;
    final pending =
        result['status_code'] == 'PENDING' &&
        (purchase != null || widget.catalog == Catalog.myTraining);
    if (pending) {
      return Card(
        margin: const EdgeInsets.only(top: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Төлбөр хүлээгдэж байна',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              for (final item in {
                'Дүн': '${result['amount'] ?? result['price'] ?? '—'} ₮',
                'Данс': result['bank_account_number'],
                'Хүлээн авагч': result['bank_account_name'],
                'Гүйлгээний утга': result['invoice_no'],
              }.entries)
                if (item.value != null && item.value.toString().isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(item.key),
                    subtitle: SelectableText(item.value.toString()),
                    trailing: IconButton(
                      tooltip: 'Хуулах',
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: item.value.toString()),
                        );
                        if (context.mounted) _notice(context, 'Хууллаа');
                      },
                    ),
                  ),
            ],
          ),
        ),
      );
    }
    if (enrolled) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.check_circle_outline),
        title: Text('Бүртгэлийн хүсэлт илгээгдлээ'),
      );
    }
    if (purchase?['status_code'] == 'ACTIVE') {
      return FilledButton(
        onPressed: () => _openCatalog(context, widget.api, Catalog.myTraining),
        child: const Text('Миний сургалт'),
      );
    }
    if (widget.catalog == Catalog.courses) {
      final reason = _registrationClosedReason(widget.data);
      if (reason != null) {
        return FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.lock_outline),
          label: Text('Бүртгүүлэх · $reason'),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: FilledButton(
        onPressed: busy ? null : _start,
        child: Text(
          busy
              ? 'Түр хүлээнэ үү…'
              : widget.catalog == Catalog.courses
              ? 'Бүртгүүлэх'
              : 'Сургалтад бүртгүүлэх',
        ),
      ),
    );
  }
}

String _certificateDate(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null || date.year < 1900) return '';
  final clinicDate = date.toUtc().add(const Duration(hours: 8));
  return '${clinicDate.year}.${clinicDate.month.toString().padLeft(2, '0')}.${clinicDate.day.toString().padLeft(2, '0')}';
}

Uri? _enrollmentCertificate(Record data) {
  if (data['certificated'] != true) return null;
  final file = text(data, ['certificate_file']);
  if (file.isEmpty) return null;
  final parsed = Uri.tryParse(file);
  if (parsed == null) return null;
  if (parsed.hasScheme) return _https(file);
  return _https(Uri.https('oyudent.com', '/uploads/uploads/$file').toString());
}

class _AttendanceCertificate extends StatelessWidget {
  const _AttendanceCertificate({required this.data, required this.uri});
  final Record data;
  final Uri uri;

  Future<void> _open(BuildContext context) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // A missing viewer and a failed launch use the same feedback.
    }
    if (context.mounted) {
      _notice(context, 'Сертификатын файлыг нээж чадсангүй.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final issued = _certificateDate(data['certificated_at']);
    return Card(
      elevation: 0,
      color: const Color(0xffeeebff),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              color: _brand,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Сургалтын сертификат',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (issued.isNotEmpty) Text('Олгосон өдөр · $issued'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _open(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Сертификат үзэх'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentReceipt extends StatelessWidget {
  const _EnrollmentReceipt({required this.data});
  final Record data;

  @override
  Widget build(BuildContext context) {
    final certificate = _enrollmentCertificate(data);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (certificate != null)
            _AttendanceCertificate(data: data, uri: certificate),
          for (final item in {
            'Сургалтын өдөр': _certificateDate(data['start_date']),
            'Төлөв': data['status_name'],
            'Багц': data['price_name'],
            'Дүн': data['price_price'] == null
                ? null
                : '${data['price_price']} ₮',
            'Банкны данс': data['bank_account_number'],
          }.entries)
            if (item.value != null && item.value.toString().isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(item.key),
                subtitle: SelectableText(item.value.toString()),
              ),
        ],
      ),
    );
  }
}

class _CourseCertificates extends StatefulWidget {
  const _CourseCertificates({
    required this.api,
    required this.courseId,
    required this.modules,
  });
  final ProductionApi api;
  final String courseId;
  final List<Record> modules;
  @override
  State<_CourseCertificates> createState() => _CourseCertificatesState();
}

class _CourseCertificatesState extends State<_CourseCertificates> {
  late Future<List<Record>> issued = load();
  Future<List<Record>> load() async {
    final all = await widget.api.list(
      'training/certificate/list?no_paginate=1',
      authenticated: true,
    );
    final modules = widget.modules
        .map((m) => m['id']?.toString())
        .whereType<String>()
        .toSet();
    return all.where((c) {
      final course =
          c['course_id'] ??
          c['courseId'] ??
          (c['course'] is Record ? c['course']['id'] : null);
      if (course != null) return course.toString() == widget.courseId;
      return modules.contains((c['module_id'] ?? c['moduleId'])?.toString());
    }).toList();
  }

  @override
  Widget build(BuildContext context) => _DetailSection(
    title: 'Сертификат',
    child: FutureBuilder(
      future: issued,
      builder: (context, s) {
        if (s.hasError) {
          return TextButton(
            onPressed: () => setState(() {
              issued = load();
            }),
            child: const Text('Сертификатыг дахин ачаалах'),
          );
        }
        if (!s.hasData) return const LinearProgressIndicator();
        if (s.data!.isEmpty) {
          return const Text('Энэ сургалтын сертификат хараахан олгогдоогүй.');
        }
        return Column(
          children: [
            for (final cert in s.data!)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.workspace_premium, color: _brand),
                title: Text(
                  text(cert, ['module_title', 'course_title']).isEmpty
                      ? 'Олгосон сертификат'
                      : text(cert, ['module_title', 'course_title']),
                ),
                subtitle: Text(text(cert, ['certificate_no'])),
                trailing: const Icon(Icons.arrow_outward),
                onTap: () => _push(
                  context,
                  _Details(
                    api: widget.api,
                    catalog: Catalog.certificates,
                    row: cert,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _CertificateView extends StatelessWidget {
  const _CertificateView({required this.data});
  final Record data;

  @override
  Widget build(BuildContext context) {
    final name = text(data, ['doctor_name']);
    final no = text(data, ['certificate_no']);
    final date = _certificateDate(data['issued_at']);
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xfffcfcf3),
        border: Border.all(color: const Color(0xffb4c6ad)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffd1d9bb)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              size: 44,
              color: _brand,
            ),
            const SizedBox(height: 8),
            const Text(
              'Сертификат',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 26,
                color: _night,
              ),
            ),
            const SizedBox(height: 14),
            if (name.isNotEmpty)
              SelectableText(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            for (final value in [data['course_title'], data['module_title']])
              if (value is String && value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SelectableText(value, textAlign: TextAlign.center),
                ),
            const Divider(height: 28),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (no.isNotEmpty) SelectableText(no),
                if (date.isNotEmpty) Text(date),
                if (data['score'] != null) Text("${data['score']}%"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizScreen extends StatefulWidget {
  const _QuizScreen({required this.api, required this.module});
  final ProductionApi api;
  final Record module;

  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
  String get route =>
      'training/quiz/${Uri.encodeComponent(widget.module['id'].toString())}';
  late Future<Record> future = widget.api.detail(route, authenticated: true);
  final answers = <String, Set<String>>{};
  Record? result;
  bool busy = false;

  Future<void> send(List<Record> questions) async {
    if (busy || questions.any((q) => answers[q['id']]?.isNotEmpty != true)) {
      return;
    }
    setState(() => busy = true);
    try {
      final outcome = await widget.api.submit('$route/submit', {
        'answers': [
          for (final q in questions)
            {'questionId': q['id'], 'answerIds': answers[q['id']]!.toList()},
        ],
      });
      if (mounted) setState(() => result = outcome);
    } catch (error) {
      if (mounted) _notice(context, _message(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Шалгалт')),
    body: FutureBuilder<Record>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) {
          return _Retry(
            error: snap.error!,
            retry: () => setState(
              () => future = widget.api.detail(route, authenticated: true),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final questions = _records(snap.data!['questions']);
        final report = result;
        final certificate = report?['certificate'];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (report != null) ...[
              Text(
                report['is_passed'] == true ? 'Тэнцлээ' : 'Дахин оролдоорой',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('${report['score']}%'),
              if (certificate is Record)
                Text('Сертификат № ${certificate['certificate_no']}'),
              if (report['is_passed'] != true)
                OutlinedButton(
                  onPressed: () => setState(() {
                    result = null;
                    answers.clear();
                  }),
                  child: const Text('Дахин өгөх'),
                ),
            ] else ...[
              if (questions.isEmpty) const Text('Асуулт байхгүй байна.'),
              for (final q in questions)
                _Question(
                  question: q,
                  selected: answers[q['id']] ?? {},
                  enabled: !busy,
                  onChange: (selection) =>
                      setState(() => answers[q['id'].toString()] = selection),
                ),
              if (questions.isNotEmpty)
                FilledButton(
                  onPressed:
                      busy ||
                          questions.any(
                            (q) => answers[q['id']]?.isNotEmpty != true,
                          )
                      ? null
                      : () => send(questions),
                  child: const Text('Шалгалт илгээх'),
                ),
            ],
          ],
        );
      },
    ),
  );
}

class _Question extends StatelessWidget {
  const _Question({
    required this.question,
    required this.selected,
    required this.enabled,
    required this.onChange,
  });
  final Record question;
  final Set<String> selected;
  final bool enabled;
  final ValueChanged<Set<String>> onChange;

  @override
  Widget build(BuildContext context) {
    final multiple = question['question_type'] == 'MULTI';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              text(question, ['question']),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final option in _records(question['answers']))
            CheckboxListTile(
              title: Text(text(option, ['answer'])),
              value: selected.contains(option['id'].toString()),
              onChanged: !enabled
                  ? null
                  : (checked) {
                      final id = option['id'].toString();
                      final next = multiple ? {...selected} : <String>{};
                      if (checked == true) {
                        next.add(id);
                      } else {
                        next.remove(id);
                      }
                      onChange(next);
                    },
            ),
        ],
      ),
    );
  }
}

class _LessonScreen extends StatefulWidget {
  const _LessonScreen({required this.api, required this.lesson});
  final ProductionApi api;
  final Record lesson;

  @override
  State<_LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<_LessonScreen> {
  String get route =>
      'training/lesson/${Uri.encodeComponent(widget.lesson['id'].toString())}';
  VideoPlayerController? player;
  late Future<void> ready = _load();
  List<Record> checkpoints = [];
  final answered = <String>{};
  Record? active;
  Set<String> selection = {};
  bool busy = false;
  bool completed = false;
  String? feedback;

  Future<void> _load() async {
    final results = await Future.wait([
      widget.api.detail('$route/video', authenticated: true),
      widget.api.list('$route/checkpoints', authenticated: true),
    ]);
    if (!mounted) return;
    final video = results.first as Record;
    final uri = _https(text(video, ['url']));
    if (uri == null) throw const ApiError('Видеоны хаяг олдсонгүй.');
    checkpoints = results.last as List<Record>;
    answered.addAll(
      checkpoints
          .where((q) => q['is_completed'] == true)
          .map((q) => q['id'].toString()),
    );
    completed = widget.lesson['is_completed'] == true;
    final controller = VideoPlayerController.networkUrl(uri);
    player = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      final resume = (widget.lesson['position_sec'] as num?)?.toInt() ?? 0;
      if (resume > 0 && resume < controller.value.duration.inSeconds) {
        await controller.seekTo(Duration(seconds: resume));
      }
      if (!mounted) return;
      controller.addListener(_check);
    } catch (_) {
      if (mounted) {
        player = null;
        await controller.dispose();
      }
      rethrow;
    }
  }

  void _check() {
    final controller = player;
    if (controller == null || active != null || !controller.value.isPlaying) {
      return;
    }
    final position = controller.value.position.inSeconds;
    for (final question in checkpoints) {
      if (!answered.contains(question['id'].toString()) &&
          position >= ((question['trigger_sec'] as num?)?.toInt() ?? 0)) {
        setState(() {
          active = question;
          selection = {};
          feedback = null;
        });
        controller.pause();
        break;
      }
    }
  }

  Future<void> _answer({bool skip = false}) async {
    final question = active;
    if (question == null || busy || (!skip && selection.isEmpty)) return;
    setState(() => busy = true);
    try {
      final id = Uri.encodeComponent(question['id'].toString());
      final response = await widget.api.submit('$route/checkpoint/$id/submit', {
        'answerIds': skip ? <String>[] : selection.toList(),
        'skipped': skip,
      });
      if (!mounted) return;
      if (response['correct'] == true || response['completed'] == true) {
        setState(() {
          answered.add(question['id'].toString());
          active = null;
          feedback = null;
        });
        await player?.play();
      } else {
        setState(() => feedback = 'Хариултаа дахин шалгана уу.');
      }
    } catch (error) {
      if (mounted) setState(() => feedback = _message(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _save(bool finish) async {
    final controller = player;
    if (busy || controller == null) return;
    setState(() => busy = true);
    try {
      final seconds = controller.value.position.inSeconds;
      await widget.api.submit('$route/progress', {
        'positionSec': seconds,
        'watchedSec': seconds,
        'completed': finish,
      });
      if (!mounted) return;
      if (finish) setState(() => completed = true);
      _notice(context, finish ? 'Хичээл дууслаа' : 'Явц хадгалагдлаа');
    } catch (error) {
      if (mounted) _notice(context, _message(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    player?.removeListener(_check);
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(text(widget.lesson, ['title']))),
    body: FutureBuilder<void>(
      future: ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Retry(
            error: snapshot.error!,
            retry: () => setState(() {
              ready = _load();
            }),
          );
        }
        final controller = player;
        if (snapshot.connectionState != ConnectionState.done ||
            controller == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final question = active;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            VideoProgressIndicator(
              controller,
              allowScrubbing: question == null,
            ),
            if (question != null) ...[
              const SizedBox(height: 16),
              _Question(
                question: question,
                selected: selection,
                enabled: !busy,
                onChange: (value) => setState(() => selection = value),
              ),
              if (feedback != null) Text(feedback!),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: busy || selection.isEmpty ? null : _answer,
                    child: const Text('Хариулах'),
                  ),
                  if (question['allow_skip'] == true &&
                      question['is_required'] != true)
                    OutlinedButton(
                      onPressed: busy ? null : () => _answer(skip: true),
                      child: const Text('Алгасах'),
                    ),
                ],
              ),
            ] else
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final missing = checkpoints.any(
                    (q) =>
                        !answered.contains(q['id'].toString()) &&
                        (q['is_required'] == true || q['allow_skip'] != true),
                  );
                  final atEnd =
                      value.position >=
                      value.duration - const Duration(seconds: 1);
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: value.isPlaying ? 'Түр зогсоох' : 'Тоглуулах',
                        onPressed: value.isPlaying
                            ? controller.pause
                            : controller.play,
                        icon: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : () => _save(false),
                        child: const Text('Явц хадгалах'),
                      ),
                      if (!completed)
                        FilledButton(
                          onPressed: busy || !atEnd || missing
                              ? null
                              : () => _save(true),
                          child: const Text('Дуусгах'),
                        )
                      else
                        const Text('Дууссан'),
                    ],
                  );
                },
              ),
          ],
        );
      },
    ),
  );
}
