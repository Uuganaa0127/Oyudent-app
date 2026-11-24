import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'api.dart';
import 'auth_page.dart';

class Classroom extends StatefulWidget {
  const Classroom({
    super.key,
    required this.courseId,
    required this.title,
    required this.onComplete,
    required this.onRelated,
  });
  final String courseId, title;
  final VoidCallback onComplete;
  final ValueChanged<String> onRelated;
  @override
  State<Classroom> createState() => _ClassroomState();
}

class _ClassroomState extends State<Classroom> {
  Map<String, dynamic>? course, quiz, result;
  String? error, quizError;
  bool busy = true, submitting = false, quizLoading = false, rewarded = false;
  int selected = 0;
  final done = <String>{};
  final answers = <String, int>{};
  List<Map<String, dynamic>> get lessons => course == null
      ? []
      : [
          for (final m in course!['modules'])
            for (final l in m['lessons']) Map<String, dynamic>.from(l),
        ];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await OyudentApi.instance.request(
        '/courses/${Uri.encodeComponent(widget.courseId)}',
      );
      if (mounted) setState(() => course = data);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = 'Хичээл татахад алдаа гарлаа. Туршилтын сервер ажиллаж байгаа эсэхийг шалгана уу.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> loadQuiz() async {
    if (quiz != null || quizLoading) return;
    setState(() {
      quizLoading = true;
      quizError = null;
    });
    try {
      final data = await OyudentApi.instance.request(
        '/courses/${Uri.encodeComponent(widget.courseId)}/quiz',
      );
      if (mounted) setState(() => quiz = data);
    } catch (e) {
      if (mounted) {
        setState(
          () => quizError = 'Шалгалтыг татаж чадсангүй. Дахин оролдоно уу.',
        );
      }
    } finally {
      if (mounted) setState(() => quizLoading = false);
    }
  }

  void choose(int i) {
    setState(() => selected = i);
    if (lessons[i]['type'] == 'quiz') loadQuiz();
  }

  void markDone() {
    setState(() => done.add(lessons[selected]['id']));
    checkComplete();
  }

  void checkComplete() {
    if (!rewarded && lessons.every((l) => done.contains(l['id']))) {
      rewarded = true;
      widget.onComplete();
    }
  }

  Future<void> submitQuiz() async {
    if (quiz == null || answers.length != (quiz!['questions'] as List).length) {
      return;
    }
    if (OyudentApi.instance.token == null) {
      await Navigator.push(
        context,
        MaterialPageRoute<bool>(builder: (_) => const AuthPage()),
      );
      if (!mounted || OyudentApi.instance.token == null) return;
    }
    setState(() {
      submitting = true;
      quizError = null;
    });
    try {
      final data = await OyudentApi.instance.request(
        '/courses/${Uri.encodeComponent(widget.courseId)}/quiz/submit',
        body: {'answers': answers},
      );
      if (mounted) {
        setState(() => result = data);
        if (data['passed'] == true) markDone();
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => quizError = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Widget moduleList() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Хөтөлбөр',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      LinearProgressIndicator(
        value: lessons.isEmpty ? 0 : done.length / lessons.length,
      ),
      const SizedBox(height: 8),
      Text('${done.length}/${lessons.length} дэд хичээл дууссан'),
      const SizedBox(height: 16),
      for (final m in course!['modules'])
        ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          title: Text(
            m['title'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            for (final l in m['lessons'])
              ListTile(
                selected: lessons[selected]['id'] == l['id'],
                selectedTileColor: const Color(0xFFDDEFF0),
                leading: Icon(
                  done.contains(l['id'])
                      ? Icons.check_circle
                      : l['type'] == 'quiz'
                      ? Icons.quiz_outlined
                      : l['type'] == 'video'
                      ? Icons.play_circle_outline
                      : Icons.article_outlined,
                ),
                title: Text(l['title']),
                onTap: () =>
                    choose(lessons.indexWhere((x) => x['id'] == l['id'])),
              ),
          ],
        ),
      const SizedBox(height: 20),
      const Text(
        'Холбоотой сургалтууд',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      for (final r in course!['related'])
        ListTile(
          title: Text(r['title']),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pop(context);
            widget.onRelated(r['title']);
          },
        ),
    ],
  );
  Widget content() {
    final l = lessons[selected];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l['title'],
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (l['type'] == 'video')
          LessonVideo(key: ValueKey(l['id']), url: l['videoUrl']),
        const SizedBox(height: 12),
        Text(l['description'] ?? '', style: const TextStyle(height: 1.7)),
        const SizedBox(height: 20),
        if (l['type'] == 'quiz') ...[
          if (quizLoading) const Center(child: CircularProgressIndicator()),
          if (quizError != null)
            Text(quizError!, style: const TextStyle(color: Colors.red)),
          if (quiz == null && !quizLoading)
            TextButton(onPressed: loadQuiz, child: const Text('Шалгалт татах')),
          if (quiz != null) ...[
            const Text(
              'Серверээс ирсэн шалгалт',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            for (final q in quiz!['questions'])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q['prompt'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    for (int i = 0; i < (q['options'] as List).length; i++)
                      CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        value: answers[q['id']] == i,
                        title: Text(q['options'][i]),
                        onChanged: submitting
                            ? null
                            : (_) => setState(() {
                                answers[q['id']] = i;
                                result = null;
                              }),
                      ),
                  ],
                ),
              ),
            FilledButton(
              onPressed:
                  submitting ||
                      answers.length != (quiz!['questions'] as List).length
                  ? null
                  : submitQuiz,
              child: Text(submitting ? 'Шалгаж байна…' : 'Хариултаа шалгуулах'),
            ),
          ],
          if (result != null)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                '${result!['score']}/${result!['total']} • ${result!['feedback']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ] else
          FilledButton.icon(
            onPressed: done.contains(l['id']) ? null : markDone,
            icon: const Icon(Icons.check),
            label: Text(
              done.contains(l['id'])
                  ? 'Дууссан'
                  : 'Хичээлийг дуусгасан гэж тэмдэглэх',
            ),
          ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          children: [
            OutlinedButton(
              onPressed: selected > 0 ? () => choose(selected - 1) : null,
              child: const Text('Өмнөх хичээл'),
            ),
            FilledButton(
              onPressed: selected < lessons.length - 1
                  ? () => choose(selected + 1)
                  : null,
              child: const Text('Дараах хичээл'),
            ),
          ],
        ),
        if (rewarded)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              'Сургалт дууслаа! Гэрчилгээг Миний сургалтууд → Дууссан хэсгээс харна уу.',
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    body: busy
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!),
                  TextButton(
                    onPressed: load,
                    child: const Text('Дахин оролдох'),
                  ),
                ],
              ),
            ),
          )
        : LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: c.maxWidth > 850
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 300, child: moduleList()),
                            const SizedBox(width: 28),
                            Expanded(child: content()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExpansionTile(
                              title: const Text('Дэд хичээлүүдийг харах'),
                              children: [moduleList()],
                            ),
                            const SizedBox(height: 16),
                            content(),
                          ],
                        ),
                ),
              ),
            ),
          ),
  );
}

class LessonVideo extends StatefulWidget {
  const LessonVideo({super.key, required this.url});
  final String url;
  @override
  State<LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends State<LessonVideo> {
  VideoPlayerController? controller;
  String? error;
  bool loading = false;
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> start() async {
    setState(() {
      loading = true;
      error = null;
    });
    final uri = Uri.tryParse(widget.url);
    if (uri == null || uri.scheme != 'https') {
      setState(() {
        error = 'Видео HTTPS холбоос шаардлагатай.';
        loading = false;
      });
      return;
    }
    final v = VideoPlayerController.networkUrl(uri);
    controller = v;
    try {
      await v.initialize().timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() => loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Видео ачаалагдсангүй. Дахин оролдоно уу.';
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = controller;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: v != null && v.value.isInitialized
              ? v.value.aspectRatio
              : 16 / 9,
          child: Container(
            color: const Color(0xFF6553ED),
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : error != null
                ? Center(
                    child: TextButton(
                      onPressed: () async {
                        await controller?.dispose();
                        controller = null;
                        start();
                      },
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : v == null || !v.value.isInitialized
                ? Center(
                    child: FilledButton.icon(
                      onPressed: start,
                      icon: const Icon(Icons.play_circle),
                      label: const Text('Видео ачаалах'),
                    ),
                  )
                : VideoPlayer(v),
          ),
        ),
        if (v != null && v.value.isInitialized)
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: v,
            builder: (context, value, _) => Column(
              children: [
                VideoProgressIndicator(
                  v,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    IconButton(
                      tooltip: value.isPlaying ? 'Түр зогсоох' : 'Тоглуулах',
                      onPressed: () => value.isPlaying ? v.pause() : v.play(),
                      icon: Icon(
                        value.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                    Text(
                      '${value.position.inSeconds} / ${value.duration.inSeconds} сек',
                    ),
                    IconButton(
                      tooltip: 'Дуу',
                      onPressed: () => v.setVolume(value.volume == 0 ? 1 : 0),
                      icon: Icon(
                        value.volume == 0 ? Icons.volume_off : Icons.volume_up,
                      ),
                    ),
                    DropdownButton<double>(
                      value: value.playbackSpeed,
                      items: [.5, 1.0, 1.5, 2.0]
                          .map(
                            (x) => DropdownMenuItem(
                              value: x,
                              child: Text('${x}x'),
                            ),
                          )
                          .toList(),
                      onChanged: (x) {
                        if (x != null) v.setPlaybackSpeed(x);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
