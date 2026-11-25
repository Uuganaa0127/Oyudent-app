import 'dart:convert';

import 'package:flutter/material.dart';

import 'work_hub.dart';
import 'production_app.dart';
import 'ui_components.dart';
import 'api.dart';
import 'auth_page.dart';
import 'classroom.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const demo = bool.fromEnvironment('OYUDENT_DEMO');
  runApp(demo ? const OyudentApp() : const OyudentProductionApp());
}

const teal = Color(0xFF5351EE);

class OyudentApp extends StatelessWidget {
  const OyudentApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Oyudent',
    scrollBehavior: const SwipeBehavior(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: teal),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF252851),
        displayColor: const Color(0xFF252851),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.all(4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE1E4F6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE1E4F6)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.white24,
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: Colors.white),
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F3FF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF0F3FF),
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundBuilder: (context, states, child) => Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: states.contains(WidgetState.disabled)
                    ? [const Color(0xFFB9BED9), const Color(0xFFCDD5E7)]
                    : [const Color(0xFF5750ED), const Color(0xFF22C8E9)],
              ),
            ),
            child: child,
          ),
        ),
      ),
    ),
    home: const DentalApp(),
  );
}

class DentalApp extends StatefulWidget {
  const DentalApp({super.key});
  @override
  State<DentalApp> createState() => _DentalAppState();
}

class _DentalAppState extends State<DentalApp> {
  int page = 0, coins = 250;
  bool done = false;
  final redeemed = <String>{};
  String rewardFilter = 'Бүгд';
  final pointCart = <String, (int, bool)>{};
  String? lastCheckIn;
  bool walletReady = false, claiming = false;
  String get today => DateTime.now().toIso8601String().split('T').first;
  Future<void> loadWallet() async {
    try {
      final raw = await OyudentApi.instance.storage.read(
        key: 'oyudent.demo.wallet',
      );
      if (raw != null && mounted) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          coins = data['coins'] as int;
          lastCheckIn = data['lastCheckIn'] as String?;
          redeemed.addAll(List<String>.from(data['redeemed'] ?? []));
          enrolled.addAll(redeemed.where(online.contains));
        });
      }
    } catch (_) {
      /* Storage can be unavailable in widget tests. */
    }
    if (mounted) setState(() => walletReady = true);
  }

  Future<void> saveWallet() => OyudentApi.instance.storage.write(
    key: 'oyudent.demo.wallet',
    value: jsonEncode({
      'coins': coins,
      'lastCheckIn': lastCheckIn,
      'redeemed': redeemed.toList(),
    }),
  );
  Future<void> dailyCheckIn() async {
    if (!walletReady || claiming || lastCheckIn == today) return;
    setState(() => claiming = true);
    final day = today;
    try {
      await OyudentApi.instance.storage.write(
        key: 'oyudent.demo.wallet',
        value: jsonEncode({
          'coins': coins + 25,
          'lastCheckIn': day,
          'redeemed': redeemed.toList(),
        }),
      );
      if (!mounted) return;
      setState(() {
        coins += 25;
        lastCheckIn = day;
      });
      message('+25 оноо нэмэгдлээ. Маргааш дахин ирээрэй!');
    } catch (_) {
      message('Оноог хадгалж чадсангүй. Дахин оролдоно уу.');
    } finally {
      if (mounted) setState(() => claiming = false);
    }
  }

  Future<void> showDailyCheckIn() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) {
          final claimed = lastCheckIn == today;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            title: Row(
              children: [
                const Expanded(child: Text('Өдөр тутмын урамшуулал')),
                IconButton(
                  tooltip: 'Хаах',
                  onPressed: claiming ? null : () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFE1DAFF), Color(0xFFBFF2FF)],
                      ),
                    ),
                    child: Icon(
                      claimed
                          ? Icons.check_circle_rounded
                          : Icons.stars_rounded,
                      size: 64,
                      color: teal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '+25 оноо',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: teal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    claimed
                        ? 'Өнөөдрийн урамшууллаа авлаа! Маргааш дахин ирээрэй.'
                        : 'Өнөөдрийн урамшууллаа аваад хүссэн бүтээгдэхүүн, сургалтдаа зарцуулаарай.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Үлдэгдэл: $coins оноо',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: claimed
                      ? () => Navigator.pop(ctx)
                      : claiming || !walletReady
                      ? null
                      : () async {
                          final task = dailyCheckIn();
                          refresh(() {});
                          await task;
                          if (ctx.mounted) refresh(() {});
                        },
                  child: Text(
                    claimed
                        ? 'Боллоо'
                        : claiming
                        ? 'Хадгалж байна…'
                        : '25 оноо авах',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> openPointCart() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          final total = pointCart.values.fold(0, (sum, item) => sum + item.$1);
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * .8,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Онооны сагс',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (pointCart.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Таны сагс хоосон байна.'),
                      ),
                    ...pointCart.entries.toList().map(
                      (entry) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.key),
                        subtitle: Text('${entry.value.$1} оноо • 1 ширхэг'),
                        trailing: IconButton(
                          tooltip: 'Сагснаас хасах',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() => pointCart.remove(entry.key));
                            update(() {});
                          },
                        ),
                      ),
                    ),
                    const Divider(),
                    Text(
                      'Нийт: $total оноо',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Таны үлдэгдэл: $coins оноо'),
                    if (total > coins)
                      Text(
                        '${total - coins} оноо дутуу байна',
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 18),
                    const Text(
                      'Баталгаажуулснаар оноо хасагдана. Туршилтын урамшуулал.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed:
                          pointCart.isEmpty ||
                              total > coins ||
                              claiming ||
                              !walletReady
                          ? null
                          : () async {
                              final items = Map<String, (int, bool)>.from(
                                pointCart,
                              );
                              if (items.keys.any(redeemed.contains) ||
                                  total > coins) {
                                return;
                              }
                              setState(() {
                                coins -= total;
                                for (final item in items.entries) {
                                  redeemed.add(item.key);
                                  orders.add(
                                    '${item.key} • ${item.value.$1} оноо',
                                  );
                                  if (item.value.$2) enrolled.add(item.key);
                                }
                                pointCart.clear();
                              });
                              Navigator.pop(ctx);
                              try {
                                await saveWallet();
                              } catch (_) {
                                message(
                                  'Урамшуулал авлаа. Энэ төхөөрөмжид хадгалж чадсангүй.',
                                );
                                return;
                              }
                              message('Урамшууллууд амжилттай авлаа.');
                            },
                      child: const Text('Оноогоор баталгаажуулах'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  final enrolled = <String>{
        'Шүдний эмнэлгийн гэрэл зураг',
        'Дижитал шүдний эмчилгээ',
      },
      completed = <String>{'Дижитал шүдний эмчилгээ'};
  final requests = <String, String>{
    'Клиникийн гэрэл зургийн дадлага': 'Хүлээгдэж буй',
    'Шүдний эмнэлгийн багийн ажиллагаа': 'Батлагдсан',
    'Өвчтөнтэй харилцах ур чадвар': 'Татгалзсан',
  };
  bool myCourses = false;
  String clientName = 'Туршилтын эмч';
  final orders = <String>[];
  final online = [
    'Шүдний эмнэлгийн гэрэл зураг',
    'Дижитал шүдний эмчилгээ',
    'Шүдний эмнэлгийн менежмент',
  ];
  final onsite = [
    'Клиникийн гэрэл зургийн дадлага',
    'Шүдний эмнэлгийн багийн ажиллагаа',
    'Өвчтөнтэй харилцах ур чадвар',
  ];
  final products = [
    'Шүдний үзлэгийн багаж',
    'Хамгаалалтын нүдний шил',
    'Шүдний сургалтын загвар',
  ];
  Widget heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );
  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> purchase(String name, int price, {bool course = false}) async {
    bool use = false;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          final discount = use
              ? (coins < price * 100 ? coins : price * 100)
              : 0;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Үнэ: \$$price USD'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('$coins койн ашиглах'),
                    subtitle: const Text('100 койн = 1 ам.доллар'),
                    value: use,
                    onChanged: (v) => update(() => use = v),
                  ),
                  const Text('Туршилтын захиалга. Бодит төлбөр авахгүй.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        coins -= discount;
                        if (course) enrolled.add(name);
                        orders.add(name);
                      });
                      saveWallet().catchError((_) {});
                      Navigator.pop(ctx);
                      message('Захиалга амжилттай.');
                    },
                    child: Text(
                      'Баталгаажуулах • \$${(price - discount / 100).toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void onsiteDetails(String name) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ТАНХИМЫН СУРГАЛТ',
                style: TextStyle(color: teal, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Байршил: Oyudent сургалтын төв (туршилт)\nХугацаа: Хагас өдөр\nОгноо: Удахгүй зарлана\nТөлбөр: Туршилтын бүртгэл үнэгүй',
                style: TextStyle(height: 1.8),
              ),
              const SizedBox(height: 16),
              const Text(
                'Хөтөлбөр',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Багшийн танилцуулга, хамтарсан дасгал, тохиолдлын хэлэлцүүлэг болон асуулт хариулт. Шүдний эмч, оюутнуудад зориулсан жишээ хөтөлбөр.',
              ),
              const SizedBox(height: 16),
              Text(
                'Төлөв: ${requests[name] ?? 'Бүртгүүлээгүй'}',
                style: const TextStyle(
                  color: teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (requests[name] == null || requests[name] == 'Татгалзсан')
                FilledButton(
                  onPressed: () {
                    setState(() => requests[name] = 'Хүлээгдэж буй');
                    Navigator.pop(ctx);
                    message(
                      'Хүсэлт илгээгдлээ. Зохион байгуулагчийн шийдвэрийг хүлээнэ үү.',
                    );
                  },
                  child: const Text('Бүртгүүлэх хүсэлт илгээх'),
                ),
              const SizedBox(height: 10),
              const Text(
                'Туршилтын бүртгэл. Бодит сургалтын эрх үүсгэхгүй.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  void certificate(String name) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Сургалт дүүргэсэн гэрчилгээ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, size: 70, color: teal),
          const SizedBox(height: 18),
          const Text('OYUDENT'),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Туршилтын хичээлийг дүүргэснийг батлав.\nАлбан ёсны мэргэжлийн гэрчилгээ биш.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Хаах'),
        ),
      ],
    ),
  );
  String courseId(String name) => name == online[0]
      ? 'clinical-photography'
      : name == online[1]
      ? 'digital-dentistry'
      : 'practice-management';
  void lesson(String name) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => Classroom(
        courseId: courseId(name),
        title: name,
        onComplete: () => setState(() {
          if (completed.add(name)) {
            coins += 25;
            saveWallet().catchError((_) {});
          }
          done = true;
          myCourses = true;
        }),
        onRelated: (n) => courseDetails(n),
      ),
    ),
  );
  @override
  void initState() {
    super.initState();
    restoreSession();
    loadWallet();
  }

  Future<void> restoreSession() async {
    try {
      await OyudentApi.instance.restore();
      if (mounted) {
        setState(() {
          if (OyudentApi.instance.user != null) {
            clientName = OyudentApi.instance.user!['name'];
          }
        });
      }
    } catch (_) {
      /* Offline: retain stored token for a later retry. */
    }
  }

  Future<void> signIn() async {
    await Navigator.push(
      context,
      MaterialPageRoute<bool>(builder: (_) => const AuthPage()),
    );
    if (mounted) {
      setState(() {
        if (OyudentApi.instance.user != null) {
          clientName = OyudentApi.instance.user!['name'];
        }
      });
    }
  }

  Widget courseCard(String name, {bool physical = false}) => HoverCard(
    elevation: 0,
    color: Colors.white,
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: Icon(
        physical ? Icons.location_on_outlined : Icons.play_circle_outline,
        color: teal,
        size: 32,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        physical
            ? 'Танхимд • Дэлгэрэнгүй ба бүртгэл'
            : 'Цахим • Жишээ хичээл • 49 USD',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => physical
          ? onsiteDetails(name)
          : enrolled.contains(name)
          ? completed.contains(name)
                ? certificate(name)
                : lesson(name)
          : purchase(name, 49, course: true),
    ),
  );
  Widget productVisual(int index) => SizedBox(
    height: 230,
    child: LayoutBuilder(
      builder: (context, c) => ClipRect(
        child: OverflowBox(
          maxWidth: c.maxWidth * 3,
          minWidth: c.maxWidth * 3,
          alignment: Alignment(index.toDouble() - 1, 0),
          child: Image.asset(
            'assets/dental-products.png',
            width: c.maxWidth * 3,
            height: 230,
            fit: BoxFit.fill,
            semanticLabel: products[index],
          ),
        ),
      ),
    ),
  );
  Widget tiles(List<Widget> children) => LayoutBuilder(
    builder: (context, c) => Wrap(
      spacing: 18,
      runSpacing: 18,
      children: children
          .map(
            (w) => SizedBox(
              width: c.maxWidth > 800
                  ? (c.maxWidth - 36) / 3
                  : c.maxWidth > 520
                  ? (c.maxWidth - 18) / 2
                  : c.maxWidth,
              child: w,
            ),
          )
          .toList(),
    ),
  );
  Widget productCard(int index, {bool sale = false}) => HoverCard(
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFDFE5DF)),
    ),
    child: InkWell(
      onTap: () =>
          purchase(products[index], sale ? 18 + index * 12 : 24 + index * 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          productVisual(index),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale ? 'ХЯМДРАЛ' : 'ЭМНЭЛГИЙН ХЭРЭГСЭЛ',
                  style: const TextStyle(
                    fontSize: 11,
                    color: teal,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  products[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '${sale ? 18 + index * 12 : 24 + index * 12} USD',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (sale)
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          '${24 + index * 12} USD',
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward, color: teal),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => purchase(
                      products[index],
                      sale ? 18 + index * 12 : 24 + index * 12,
                    ),
                    child: const Text('Худалдан авах'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget discoveryCard(String name, int index, {bool physical = false}) =>
      HoverCard(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFDFE5DF)),
        ),
        child: InkWell(
          onTap: () => courseDetails(name, physical: physical),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                color: [
                  const Color(0xFFE6E6FF),
                  const Color(0xFFE1EAF5),
                  const Color(0xFFE2F2FF),
                ][index % 3],
                child: Stack(
                  children: [
                    Positioned(
                      right: 18,
                      bottom: -16,
                      child: Icon(
                        [
                          Icons.camera_alt_outlined,
                          Icons.desktop_windows_outlined,
                          Icons.groups_outlined,
                        ][index % 3],
                        size: 130,
                        color: teal.withValues(alpha: .2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'oyudent\nDENTAL EDUCATION',
                        style: TextStyle(
                          color: teal,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      physical ? 'ТАНХИМЫН СУРГАЛТ' : 'ЦАХИМ СУРГАЛТ',
                      style: const TextStyle(
                        fontSize: 11,
                        color: teal,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (physical && requests[name] != null)
                      StatusBadge(requests[name]!)
                    else if (!physical && enrolled.contains(name))
                      StatusBadge(
                        completed.contains(name) ? 'Дууссан' : 'Бүртгүүлсэн',
                      ),
                    const SizedBox(height: 8),
                    Text(
                      physical
                          ? 'Дадлага • Бүртгэлийн хүсэлт'
                          : 'Өөрийн хэмнэлээр • Жишээ хичээл',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      (physical
                              ? requests.containsKey(name)
                              : enrolled.contains(name))
                          ? 'Бүртгүүлсэн • Дэлгэрэнгүй'
                          : 'Дэлгэрэнгүй үзэх →',
                      style: const TextStyle(
                        color: teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  String productSearch = '', courseSearch = '';
  final viewedStories = <int>{};
  Future<void> openSearch(
    String label,
    String value,
    ValueChanged<String> changed,
  ) async {
    String draft = value;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextFormField(
          autofocus: true,
          initialValue: value,
          textInputAction: TextInputAction.search,
          onChanged: (v) => draft = v,
          onFieldSubmitted: (v) => Navigator.pop(ctx, v),
          decoration: InputDecoration(
            hintText: label,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Цэвэрлэх'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, draft),
            icon: const Icon(Icons.search),
            label: const Text('Хайх'),
          ),
        ],
      ),
    );
    if (result != null && mounted) changed(result);
  }

  Widget searchField(
    String label,
    String value,
    ValueChanged<String> changed,
  ) => OutlinedButton(
    key: ValueKey('$label-$page'),
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: const BorderSide(color: Color(0xFFD7E6E9)),
    ),
    onPressed: () => openSearch(label, value, changed),
    child: Row(
      children: [
        const Icon(Icons.search),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value.isEmpty ? label : value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: value.isEmpty ? Colors.black54 : teal),
          ),
        ),
        const SizedBox(width: 8),
        const Text('Хайх', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
  Widget storyRow() => SizedBox(
    height: 112,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (_, i) => const SizedBox(width: 16),
      itemBuilder: (_, i) => InkWell(
        onTap: () {
          setState(() => viewedStories.add(i));
          showDialog<void>(
            context: context,
            builder: (ctx) => Dialog(
              child: SizedBox(
                width: 380,
                height: 510,
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: PageController(initialPage: i),
                        itemCount: 4,
                        onPageChanged: (v) =>
                            setState(() => viewedStories.add(v)),
                        itemBuilder: (ctx, j) => Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6551DE), Color(0xFF2DB7DE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(
                                  4,
                                  (k) => Expanded(
                                    child: Container(
                                      height: 4,
                                      margin: const EdgeInsets.only(right: 4),
                                      color: k == j
                                          ? Colors.white
                                          : Colors.white30,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'OYUDENT • СТОРИ',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const Spacer(),
                              Icon(
                                [
                                  Icons.school_outlined,
                                  Icons.shopping_bag_outlined,
                                  Icons.groups_outlined,
                                  Icons.event_available,
                                ][j],
                                size: 80,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                [
                                  'Шинэ мэдлэг',
                                  'Эмнэлгийн хэрэгсэл',
                                  'Танхимын дадлага',
                                  'Таны ажлын өдөр',
                                ][j],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                [
                                  'Цахим сургалтын сангаас өөрийн дараагийн хичээлийг сонгоорой.',
                                  'Шинэ бүтээгдэхүүн, хямдралтай хэрэгслүүдтэй танилцаарай.',
                                  'Бүртгүүлэх хүсэлтээ илгээж, шийдвэрийг Миний сургалтуудаас хараарай.',
                                  'Өвчтөний цаг, эмнэлгээс ирсэн хүсэлтүүд нэг дор.',
                                ][j],
                                style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.6,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${j + 1} / 4 • Хажуу тийш гүйлгэнэ үү',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Хаах'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: SizedBox(
          width: 78,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: viewedStories.contains(i)
                        ? [Colors.grey.shade300, Colors.grey.shade400]
                        : [const Color(0xFF6D5CED), const Color(0xFF27BCE1)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 31,
                  backgroundColor: Colors.white,
                  child: Icon(
                    [
                      Icons.school_outlined,
                      Icons.shopping_bag_outlined,
                      Icons.groups_outlined,
                      Icons.event_available,
                    ][i],
                    color: teal,
                    size: 29,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ['Сургалт', 'Дэлгүүр', 'Дадлага', 'Цаг захиалга'][i],
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  void courseDetails(String name, {bool physical = false}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, refresh) {
              final applied = physical
                  ? requests.containsKey(name)
                  : enrolled.contains(name);
              return Scaffold(
                appBar: AppBar(title: const Text('Сургалтын дэлгэрэнгүй')),
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Container(
                          height: 190,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E8FF),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            physical
                                ? Icons.groups_outlined
                                : Icons.school_outlined,
                            size: 90,
                            color: teal,
                          ),
                        ),
                        heading(
                          name,
                          physical
                              ? 'Танхимын сургалт • Oyudent'
                              : 'Цахим сургалт • Oyudent',
                        ),
                        if (applied)
                          Chip(
                            label: Text(
                              physical
                                  ? 'Бүртгүүлсэн • ${requests[name]}'
                                  : 'Бүртгүүлсэн',
                            ),
                          ),
                        heading(
                          'Сургалтын тухай',
                          'Шүдний эмч, оюутнуудад зориулсан мэргэжлийн хөгжлийн жишээ сургалт.',
                        ),
                        const Text(
                          'Зорилгоо тодорхойлох, ажлын урсгалаа сайжруулах, багтайгаа туршлага солилцох дадлагуудтай танилцана.',
                        ),
                        heading(
                          'Хөтөлбөр',
                          'Танилцуулга • Жишээ хичээл • Бие даалт',
                        ),
                        Text(
                          physical
                              ? 'Байршил: Oyudent сургалтын төв\nОгноо: Удахгүй зарлана\nХүсэлт: Үнэгүй туршилтын бүртгэл'
                              : 'Өөрийн хэмнэлээр суралцана\nҮнэ: 49 USD\nТуршилтын хичээл ба жишээ гэрчилгээ',
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () async {
                            if (physical) {
                              if (!applied) {
                                setState(
                                  () => requests[name] = 'Хүлээгдэж буй',
                                );
                                refresh(() {});
                              }
                            } else if (applied) {
                              Navigator.pop(ctx);
                              completed.contains(name)
                                  ? certificate(name)
                                  : lesson(name);
                            } else {
                              await purchase(name, 49, course: true);
                              if (ctx.mounted) refresh(() {});
                            }
                          },
                          child: Text(
                            physical
                                ? applied
                                      ? 'Бүртгүүлсэн'
                                      : 'Бүртгүүлэх хүсэлт илгээх'
                                : applied
                                ? completed.contains(name)
                                      ? 'Гэрчилгээ үзэх'
                                      : 'Хичээлээ үргэлжлүүлэх'
                                : 'Сургалтад бүртгүүлэх',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Туршилтын мэдээлэл. Бодит төлбөр, сургалтын эрх үүсгэхгүй.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
  Widget home() => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      storyRow(),
      const SizedBox(height: 18),
      InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() => page = 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE9E6FF),
                child: Icon(Icons.stars_rounded, color: teal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Онооны дэлгүүр',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$coins оноо • Өөртөө урамшуулал сонгоорой',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: teal),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      searchField(
        'Бүтээгдэхүүн хайх',
        productSearch,
        (v) => setState(() => productSearch = v),
      ),
      const SizedBox(height: 24),
      HomeSlides(onExplore: () => setState(() => page = 1)),
      heading(
        'Танд зориулсан сургалтууд',
        'Мэдлэгээ дараагийн түвшинд хүргээрэй',
      ),
      searchField(
        'Сургалт хайх',
        courseSearch,
        (v) => setState(() => courseSearch = v),
      ),
      const SizedBox(height: 12),
      HorizontalShelf(
        children: online.indexed
            .where(
              (n) => n.$2.toLowerCase().contains(courseSearch.toLowerCase()),
            )
            .map((n) => discoveryCard(n.$2, n.$1))
            .toList(),
      ),
      heading('Шинэ бүтээгдэхүүн', 'Таны эмнэлгийн өдөр тутмын хэрэгцээнд'),
      HorizontalShelf(
        children: products.indexed
            .where(
              (n) => n.$2.toLowerCase().contains(productSearch.toLowerCase()),
            )
            .map((n) => productCard(n.$1))
            .toList(),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Бүтээгдэхүүний зураг нь хиймэл оюунаар үүсгэсэн жишээ дүрслэл.',
          style: TextStyle(fontSize: 11, color: Colors.black45),
        ),
      ),
      heading('Онцлох хямдрал', 'Чанартай хэрэгсэл, илүү боломжийн үнэ'),
      HorizontalShelf(
        children: products.indexed
            .where(
              (n) => n.$2.toLowerCase().contains(productSearch.toLowerCase()),
            )
            .map((n) => productCard(n.$1, sale: true))
            .toList(),
      ),
      heading(
        'Танхимд хамтдаа суралцъя',
        'Дадлага хийж, мэргэжил нэгтнүүдтэйгээ туршлага солилцоорой',
      ),
      HorizontalShelf(
        children: onsite.indexed
            .where(
              (n) => n.$2.toLowerCase().contains(courseSearch.toLowerCase()),
            )
            .map((n) => discoveryCard(n.$2, n.$1, physical: true))
            .toList(),
      ),
      const SizedBox(height: 30),
    ],
  );
  Widget enrolledCard(String name, {String? status, bool finished = false}) =>
      HoverCard(
        elevation: 0,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFDDE5DC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 130,
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE1E7FF), Color(0xFFF2F4FF)],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    finished
                        ? Icons.workspace_premium_outlined
                        : status != null
                        ? Icons.groups_outlined
                        : Icons.school_outlined,
                    size: 54,
                    color: teal,
                  ),
                  const Spacer(),
                  const Text(
                    'OYUDENT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: teal,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status != null ? 'ТАНХИМЫН СУРГАЛТ' : 'ЦАХИМ СУРГАЛТ',
                    style: const TextStyle(
                      color: teal,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (status != null)
                    StatusBadge(status)
                  else ...[
                    LinearProgressIndicator(
                      value: finished ? 1 : 0,
                      backgroundColor: const Color(0xFFE8E9FF),
                      color: teal,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      finished
                          ? '100% • Дууссан'
                          : 'Эхлэхэд бэлэн • 1 жишээ хичээл',
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => status != null
                          ? onsiteDetails(name)
                          : finished
                          ? certificate(name)
                          : lesson(name),
                      child: Text(
                        status != null
                            ? 'Бүртгэлийн дэлгэрэнгүй'
                            : finished
                            ? 'Гэрчилгээ үзэх'
                            : 'Үргэлжлүүлэн суралцах',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  Widget learning() => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 12,
        children: [
          Text(
            myCourses ? 'Миний сургалтууд' : 'Сургалтын сан',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() => myCourses = !myCourses),
            icon: Icon(
              myCourses ? Icons.explore_outlined : Icons.school_outlined,
            ),
            label: Text(myCourses ? 'Сургалтын сан руу' : 'Миний сургалтууд'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        myCourses ? 'Таны бүртгэл, суралцах явц, гэрчилгээ нэг дор.' : 'Цахим мэдлэгээс танхимын дадлага хүртэл. Өөрт тохирох сургалтаа сонгоорой.',
        style: const TextStyle(color: Colors.black54, fontSize: 16),
      ),
      const SizedBox(height: 24),
      if (myCourses) ...[
        const Text(
          'Жишээ бүртгэлүүд • Туршилтын мэдээлэл',
          style: TextStyle(color: teal, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          children: [
            ChoiceChip(
              label: const Text('Бүртгүүлсэн'),
              selected: !done,
              onSelected: (_) => setState(() => done = false),
            ),
            ChoiceChip(
              label: const Text('Дууссан'),
              selected: done,
              onSelected: (_) => setState(() => done = true),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (done)
          HorizontalShelf(
            children: completed
                .map((n) => enrolledCard(n, finished: true))
                .toList(),
          )
        else
          HorizontalShelf(
            children: [
              ...enrolled
                  .where((n) => !completed.contains(n))
                  .map((n) => enrolledCard(n)),
              ...requests.entries.map(
                (r) => enrolledCard(r.key, status: r.value),
              ),
            ],
          ),
      ] else ...[
        searchField(
          'Сургалт хайх',
          courseSearch,
          (v) => setState(() => courseSearch = v),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_stories_outlined, size: 44, color: teal),
              SizedBox(width: 18),
              Expanded(
                child: Text(
                  'Мэргэжлийн хөгжлийн дараагийн алхмаа эндээс эхлүүлээрэй.',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        heading('Цахим сургалтууд', 'Хаанаас ч, өөрийн хэмнэлээр суралцаарай'),
        HorizontalShelf(
          children: online.indexed
              .where(
                (n) => n.$2.toLowerCase().contains(courseSearch.toLowerCase()),
              )
              .map((n) => discoveryCard(n.$2, n.$1))
              .toList(),
        ),
        heading(
          'Танхимын сургалтууд',
          'Багштай хамт дадлага хийж, туршлага солилцоорой',
        ),
        HorizontalShelf(
          children: onsite.indexed
              .where(
                (n) => n.$2.toLowerCase().contains(courseSearch.toLowerCase()),
              )
              .map((n) => discoveryCard(n.$2, n.$1, physical: true))
              .toList(),
        ),
      ],
      const SizedBox(height: 30),
    ],
  );

  Widget pointShop() => ListView(
    key: const PageStorageKey("point-shop"),
    padding: const EdgeInsets.all(22),
    children: [
      heading(
        'Онооны дэлгүүр',
        'Суралцсан мэдлэгээ шинэ боломжоор урамшуулаарай.',
      ),
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: openPointCart,
          icon: const Icon(Icons.shopping_bag_outlined),
          label: Text('Сагс (${pointCart.length})'),
        ),
      ),
      const SizedBox(height: 14),
      HoverCard(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Өдөр тутмын урамшуулал',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Өдөр бүр бүртгүүлээд +25 оноо аваарай. Эмнэлгийн ирцээс тусдаа.',
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: !walletReady || claiming || lastCheckIn == today
                    ? null
                    : showDailyCheckIn,
                icon: Icon(
                  lastCheckIn == today
                      ? Icons.check_circle_outline
                      : Icons.calendar_today,
                ),
                label: Text(
                  claiming
                      ? 'Хадгалж байна…'
                      : lastCheckIn == today
                      ? 'Өнөөдрийн +25 оноог авсан'
                      : 'Өнөөдөр бүртгүүлэх • +25 оноо',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Төхөөрөмжийн огноогоор өдөрт нэг удаа.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFE0DDFF), Color(0xFFD9F5FF)],
          ),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-.4, -.5),
                  colors: [Colors.white, Color(0xFFBDEBFF), Color(0xFFC5B8F7)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x226F69D4),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.stars_rounded, size: 64, color: teal),
            ),
            const SizedBox(height: 18),
            Text(
              '$coins',
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
            ),
            const Text(
              'ТАНЫ ОНОО',
              style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Сургалтаа дуусгаад +25 оноо цуглуулаарай.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 8,
        children: ['Бүгд', 'Бүтээгдэхүүн', 'Сургалт']
            .map(
              (f) => ChoiceChip(
                label: Text(f),
                selected: rewardFilter == f,
                onSelected: (_) => setState(() => rewardFilter = f),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) {
          final rewards =
              [
                (products[0], 100, false, 0),
                (products[1], 180, false, 1),
                (products[2], 500, false, 2),
                (online[2], 200, true, -1),
              ].where(
                (r) =>
                    rewardFilter == 'Бүгд' ||
                    (rewardFilter == 'Сургалт') == r.$3,
              );
          final columns = constraints.maxWidth > 900
              ? 3
              : constraints.maxWidth > 600
              ? 2
              : 1;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: rewards.map((r) {
              final obtained =
                  redeemed.contains(r.$1) || (r.$3 && enrolled.contains(r.$1));
              return SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 16) / columns,
                child: HoverCard(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (r.$3)
                        Container(
                          height: 230,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFE4DDFF), Color(0xFFDCF6FF)],
                            ),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 90,
                            color: teal,
                          ),
                        )
                      else
                        productVisual(r.$4),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.$3 ? 'ЦАХИМ СУРГАЛТ' : 'БҮТЭЭГДЭХҮҮН',
                              style: const TextStyle(
                                color: teal,
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              r.$1,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '✦ ${r.$2} оноо',
                              style: const TextStyle(
                                fontSize: 22,
                                color: teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed:
                                    obtained ||
                                        pointCart.containsKey(r.$1) ||
                                        !walletReady ||
                                        claiming
                                    ? null
                                    : () {
                                        setState(
                                          () => pointCart[r.$1] = (r.$2, r.$3),
                                        );
                                        message('Сагсанд нэмлээ.');
                                      },
                                child: Text(
                                  obtained
                                      ? 'Авсан'
                                      : pointCart.containsKey(r.$1)
                                      ? 'Сагсанд нэмсэн'
                                      : 'Сагсанд нэмэх',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      heading('Миний урамшуулал', 'Оноогоор авсан бүтээгдэхүүн, сургалтууд'),
      if (redeemed.isEmpty) const Text('Та хараахан урамшуулал аваагүй байна.'),
      ...redeemed.map(
        (r) => HoverCard(
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: teal),
            title: Text(r),
            subtitle: const Text('Амжилттай авсан'),
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Туршилтын оноо, урамшуулал энэ төхөөрөмжид хадгалагдана. Сагс түр хадгалагдана. Бодит хүргэлт, төлбөр үүсэхгүй.',
        style: TextStyle(color: Colors.black54, fontSize: 12),
      ),
    ],
  );

  Widget profile() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      heading(
        'Миний профайл',
        OyudentApi.instance.user?['email'] ?? 'Oyudent • Зочин',
      ),
      if (OyudentApi.instance.user == null)
        FilledButton.icon(
          onPressed: signIn,
          icon: const Icon(Icons.login),
          label: const Text('Нэвтрэх / Бүртгүүлэх'),
        )
      else
        OutlinedButton.icon(
          onPressed: () async {
            try {
              await OyudentApi.instance.logout();
            } catch (_) {
              message(
                'Сервертэй холбогдоогүй. Энэ төхөөрөмжийн сессийг цэвэрлэлээ.',
              );
            }
            if (mounted) setState(() => clientName = 'Туршилтын эмч');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Гарах'),
        ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: clientName,
        decoration: const InputDecoration(
          labelText: 'Таны нэр',
          prefixIcon: Icon(Icons.person_outline),
        ),
        onChanged: (v) => setState(
          () => clientName = v.trim().isEmpty ? 'Туршилтын эмч' : v.trim(),
        ),
      ),
      const SizedBox(height: 18),
      const CircleAvatar(
        radius: 40,
        backgroundColor: Color(0xFFE1E5FF),
        child: Icon(Icons.person_outline, size: 46, color: teal),
      ),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6553ED), Color(0xFF5351EE)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'МИНИЙ ХЭТЭВЧ',
              style: TextStyle(color: Colors.white70, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            Text(
              '✦ $coins койн',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '100 койн = 1 ам.доллар',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.redeem_rounded, color: teal),
        title: const Text('Онооны дэлгүүр'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => setState(() => page = 5),
      ),
      ListTile(
        title: const Text('Миний сургалтууд'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => setState(() {
          page = 1;
          myCourses = true;
          done = false;
        }),
      ),
      ListTile(
        title: const Text('Дууссан сургалт ба гэрчилгээ'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => setState(() {
          page = 1;
          myCourses = true;
          done = true;
        }),
      ),
      heading('Захиалгын түүх', 'Туршилтын худалдан авалтууд'),
      ...orders.map((o) => ListTile(title: Text(o))),
      heading(
        'Бүртгэлийн төлөв турших',
        'Зөвхөн загварын туршилт. Бодит зөвшөөрөл биш.',
      ),
      ...requests.entries.map(
        (r) => HoverCard(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.key,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: StatusBadge(r.value),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Туршилтын төлөв өөрчлөх',
                      onSelected: (v) => setState(() => requests[r.key] = v),
                      itemBuilder: (_) =>
                          ['Хүлээгдэж буй', 'Батлагдсан', 'Татгалзсан']
                              .map(
                                (v) => PopupMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Мэдээлэл түр санах ойд хадгалагдана. Аппыг дахин ачаалахад арилна. Төлбөр, сургалт, өвчтөний мэдээлэл бүгд туршилтынх.',
        style: TextStyle(color: Colors.black54),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 76,
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'oyudent',
          style: TextStyle(
            color: teal,
            fontWeight: FontWeight.w900,
            fontSize: 28,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => page = 5),
          child: Text(
            '✦ $coins',
            style: const TextStyle(color: teal, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          tooltip: 'Миний профайл',
          onPressed: () => setState(() => page = 4),
          icon: const CircleAvatar(
            backgroundColor: Color(0xFFE1E5FF),
            child: Icon(Icons.person_outline, color: teal),
          ),
        ),
        SizedBox(
          width: MediaQuery.sizeOf(context).width < 500 ? 76 : 140,
          child: Text(
            clientName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: IndexedStack(
          index: page == 5
              ? 4
              : page == 4
              ? 3
              : page >= 2
              ? 2
              : page,
          children: [
            home(),
            learning(),
            WorkHub(calendar: page == 2),
            profile(),
            pointShop(),
          ],
        ),
      ),
    ),
    bottomNavigationBar: Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF6657EA), Color(0xFF27B8DF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x305957DA),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: page == 5
            ? 4
            : page == 4
            ? 0
            : page,
        onDestinationSelected: (v) => setState(() => page = v == 4 ? 5 : v),
        indicatorColor: Colors.white24,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Нүүр'),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            label: 'Сургалт',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Миний цаг',
          ),
          NavigationDestination(icon: Icon(Icons.badge_outlined), label: 'Ирц'),
          NavigationDestination(
            icon: Icon(Icons.stars_outlined),
            label: 'Оноо',
          ),
        ],
      ),
    ),
  );
}

class HorizontalShelf extends StatefulWidget {
  const HorizontalShelf({super.key, required this.children});
  final List<Widget> children;
  @override
  State<HorizontalShelf> createState() => _HorizontalShelfState();
}

class _HorizontalShelfState extends State<HorizontalShelf> {
  final controller = ScrollController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final width = c.maxWidth < 500 ? c.maxWidth * .88 : 340.0;
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.swipe_left_outlined,
                  size: 17,
                  color: Colors.black45,
                ),
                SizedBox(width: 8),
                Text(
                  'Хуруугаараа гүйлгэж үзээрэй',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
          if (widget.children.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Илэрц олдсонгүй.'),
            )
          else
            SizedBox(
              height:
                  540 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.8),
              child: ListView.separated(
                controller: controller,
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: widget.children.length,
                separatorBuilder: (_, i) => const SizedBox(width: 16),
                itemBuilder: (_, i) => SizedBox(
                  width: width,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: widget.children[i],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class HomeSlides extends StatefulWidget {
  const HomeSlides({super.key, required this.onExplore});
  final VoidCallback onExplore;
  @override
  State<HomeSlides> createState() => _HomeSlidesState();
}

class _HomeSlidesState extends State<HomeSlides> {
  final controller = PageController();
  int current = 0;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 470,
        child: PageView.builder(
          controller: controller,
          itemCount: 3,
          onPageChanged: (v) => setState(() => current = v),
          itemBuilder: (context, i) => Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  [const Color(0xFFE0DEFF), const Color(0xFFD7F2FF)],
                  [const Color(0xFFDCE8FF), const Color(0xFFE8E0FF)],
                  [const Color(0xFFE6DFFF), const Color(0xFFDDEEFF)],
                ][i],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: 5,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-.4, -.5),
                        colors: [
                          Colors.white,
                          Color(0xFFBDEBFF),
                          Color(0xFFC5B8F7),
                        ],
                      ),
                      border: Border.all(color: Colors.white54, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x226F69D4),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      [
                        Icons.school_outlined,
                        Icons.medical_services_outlined,
                        Icons.groups_outlined,
                      ][i],
                      size: 72,
                      color: const Color(0xFF6A6BCD),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        'СУРАЛЦ. ХӨГЖ. БҮТЭЭ.',
                        'ТАНЫ ЭМНЭЛГИЙН ХЭРЭГЦЭЭ',
                        'ХАМТДАА СУРАЛЦЪЯ',
                      ][i],
                      style: const TextStyle(
                        color: Color(0xFF6860C4),
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      [
                        'Мэдлэг бол таны\nхамгийн том хөрөнгө.',
                        'Илүү сайн хэрэгсэл.\nИлүү тав тухтай ажил.',
                        'Цахимаас танхимд.\nМэдлэгээс дадлагад.',
                      ][i],
                      style: const TextStyle(
                        color: Color(0xFF292855),
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      [
                        'Шүдний эмчийн мэргэжлийн хөгжлийг\nOyudent-тэй нэг алхам урагшлуул.',
                        'Шинэ бүтээгдэхүүн, онцлох хямдрал.\nДоорх цуглуулгуудаас сонгоорой.',
                        'Мэргэжил нэгтнүүдтэйгээ туршлага\nсолилцож, хамтдаа хөгжөөрэй.',
                      ][i],
                      style: const TextStyle(
                        color: Color(0xFF60628B),
                        height: 1.6,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: widget.onExplore,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Сургалтуудтай танилцах'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (i) => Semantics(
            label: 'Слайд ${i + 1}',
            button: true,
            child: InkWell(
              onTap: () => controller.animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 7,
                width: current == i ? 28 : 8,
                decoration: BoxDecoration(
                  color: current == i ? teal : const Color(0xFFD7DCF4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
