part of 'production_app.dart';

class _DailyGame extends StatefulWidget {
  const _DailyGame({required this.store});
  final DeviceWorkspace store;
  @override
  State<_DailyGame> createState() => _DailyGameState();
}

class _DailyGameState extends State<_DailyGame> {
  final cards = [0, 1, 2, 0, 1, 2]..shuffle();
  final matched = <int>{};
  int? first, second;
  bool saving = false;
  Future<void> reveal(int i) async {
    if (saving || first == i || second != null || matched.contains(i)) return;
    if (first == null) {
      setState(() => first = i);
      return;
    }
    setState(() => second = i);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() {
      if (cards[first!] == cards[i]) matched.addAll([first!, i]);
      first = null;
      second = null;
    });
    if (matched.length == cards.length) await award();
  }

  Future<void> award() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.store.reward(DateTime.now());
    } catch (_) {
      if (mounted) {
        _notice(context, 'Бонус оноог хадгалж чадсангүй. Дахин оролдоно уу.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.store
        .rows('game')
        .any((r) => r['day'] == DeviceWorkspace.day(DateTime.now()));
    const symbols = [
      Icons.spa_outlined,
      Icons.star_outline,
      Icons.favorite_outline,
    ];
    const labels = ['Навч', 'Од', 'Зүрх'];
    return Scaffold(
      appBar: AppBar(title: const Text('Өдрийн тоглоом')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(22),
            children: [
              Icon(
                done ? Icons.stars_rounded : Icons.extension_outlined,
                size: 52,
                color: _brand,
              ),
              const SizedBox(height: 12),
              Text(
                done ? 'Өнөөдрийн 1 бонус оноог авлаа' : 'Ижил дүрсийг олоорой',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                done
                    ? 'Дараагийн тоглоом маргааш нээгдэнэ.'
                    : 'Гурван хосыг тааруулж 1 бонус оноо цуглуулаарай.',
                textAlign: TextAlign.center,
              ),
              if (!done) ...[
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < cards.length; i++)
                      Builder(
                        builder: (context) {
                          final shown =
                              first == i || second == i || matched.contains(i);
                          return Semantics(
                            label: shown ? labels[cards[i]] : 'Карт ${i + 1}',
                            button: true,
                            child: FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                backgroundColor: shown ? _highlight : _night,
                                foregroundColor: shown ? _night : Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xffd7ecde,
                                ),
                                disabledForegroundColor: _brand,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                              onPressed: matched.contains(i) || saving
                                  ? null
                                  : () => reveal(i),
                              child: Icon(
                                shown
                                    ? symbols[cards[i]]
                                    : Icons.blur_on_rounded,
                                size: 30,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                if (matched.length == cards.length)
                  FilledButton(
                    onPressed: saving ? null : award,
                    child: const Text('Бонус оноо хадгалах'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
