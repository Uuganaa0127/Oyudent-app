import 'package:flutter/material.dart';

import 'api.dart';
import 'auth_page.dart';
import 'ui_components.dart';

class MyClinics extends StatefulWidget {
  const MyClinics({super.key});
  @override
  State<MyClinics> createState() => _MyClinicsState();
}

class _MyClinicsState extends State<MyClinics> {
  List<dynamic> clinics = [];
  bool loading = false;
  String? error, working;
  @override
  void initState() {
    super.initState();
    if (OyudentApi.instance.token != null) load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await OyudentApi.instance.request('/clinics');
      if (mounted) setState(() => clinics = result['clinics']);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> respond(String id, String decision) async {
    setState(() {
      working = id;
      error = null;
    });
    try {
      final result = await OyudentApi.instance.request(
        '/clinics/$id/respond',
        body: {'decision': decision},
      );
      if (mounted) setState(() => clinics = result['clinics']);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => working = null);
    }
  }

  Widget clinicCard(dynamic c) => HoverCard(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFDDEFF0),
                child: Icon(
                  Icons.local_hospital_outlined,
                  color: Color(0xFF5351EE),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  c['name'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(c['address']),
          const SizedBox(height: 8),
          Text('Үүрэг: ${c['role']}'),
          const SizedBox(height: 14),
          StatusBadge(
            c['status'] == 'accepted'
                ? 'Батлагдсан'
                : c['status'] == 'declined'
                ? 'Татгалзсан'
                : 'Хүлээгдэж буй',
          ),
          const SizedBox(height: 14),
          if (c['status'] == 'pending') ...[
            const Text('Тус эмнэлэг таныг эмчээр нэгдэхийг урьсан байна.'),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: working != null
                      ? null
                      : () => respond(c['id'], 'accepted'),
                  icon: const Icon(Icons.check),
                  label: Text(
                    working == c['id'] ? 'Илгээж байна…' : 'Урилга хүлээн авах',
                  ),
                ),
                OutlinedButton(
                  onPressed: working != null
                      ? null
                      : () => respond(c['id'], 'declined'),
                  child: const Text('Урилгаас татгалзах'),
                ),
              ],
            ),
          ] else if (c['status'] == 'accepted')
            const Text(
              'Та энэ эмнэлгийн эмчийн жагсаалтад нэгдсэн. Туршилтын гишүүнчлэл.',
              style: TextStyle(color: Color(0xFF5351EE)),
            ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 22),
      const Text(
        'Миний эмнэлгүүд',
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text('Эмнэлгээс ирсэн нэгдэх урилга болон таны гишүүнчлэл.'),
      const SizedBox(height: 16),
      if (OyudentApi.instance.token == null) ...[
        const Text('Урилгаа харах, эмнэлэгт нэгдэхийн тулд нэвтэрнэ үү.'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute<bool>(builder: (_) => const AuthPage()),
            );
            if (mounted && OyudentApi.instance.token != null) load();
          },
          child: const Text('Нэвтрэх / Бүртгүүлэх'),
        ),
      ] else ...[
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
            label: const Text('Шинэчлэх'),
          ),
        ),
        if (loading) const Center(child: CircularProgressIndicator()),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red)),
        if (!loading) ...[
          const Text(
            'Нэгдсэн эмнэлгүүд',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (!clinics.any((c) => c['status'] == 'accepted'))
            const Text('Одоогоор нэгдсэн эмнэлэг алга.'),
          ...clinics.where((c) => c['status'] == 'accepted').map(clinicCard),
          const SizedBox(height: 24),
          const Text(
            'Ирсэн урилгууд',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...clinics.where((c) => c['status'] != 'accepted').map(clinicCard),
        ],
      ],
      const SizedBox(height: 24),
      const Text(
        'Туршилтын эмнэлгүүд. Урилга, хариуг локал серверт таны бүртгэлтэй холбон хадгална.',
        style: TextStyle(color: Colors.black54),
      ),
    ],
  );
}
