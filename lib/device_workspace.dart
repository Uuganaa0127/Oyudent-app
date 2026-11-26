import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef LocalRow = Map<String, dynamic>;

/// Personal work and rewards stay on this device, separately for each account.
class DeviceWorkspace extends ChangeNotifier {
  DeviceWorkspace(this.owner);
  final String owner;
  static const _storage = FlutterSecureStorage();
  final _rows = <String, List<LocalRow>>{};
  Future<void>? _loading;
  Future<void> _queue = Future.value();
  List<LocalRow> rows(String name) =>
      List.unmodifiable(_rows[name] ?? const []);
  String _key(String name) =>
      'oyudent.local.v1.${Uri.encodeComponent(owner)}.$name';
  static const sections = [
    'appointments',
    'shifts',
    'game',
    'cart',
    'redemptions',
  ];
  Future<void> load() => _loading ??= _read().catchError((Object e) {
    _loading = null;
    throw e;
  });
  Future<void> _read() async {
    await Future.wait(
      sections.map((name) async {
        final saved = await _storage.read(key: _key(name));
        final records = saved == null
            ? <LocalRow>[]
            : (jsonDecode(saved) as List).cast<LocalRow>();
        // Keep the example and its response in one account-scoped record.
        if (name == 'appointments' &&
            !records.any((r) => r['source'] == 'hospital')) {
          final today = DateTime.now();
          final start = DateTime(
            today.year,
            today.month,
            today.day + 1,
            10,
            30,
          );
          records.add({
            'id': 'sample-clinic-consultation-v1',
            'demo': true,
            'source': 'hospital',
            'status': 'pending',
            'hospital': 'Жишээ шүдний эмнэлэг',
            'title': 'Шүдний үзлэг',
            'service': 'Шүдний үзлэг',
            'doctor': 'Б. Саруул',
            'durationMinutes': 30,
            'time': start.toUtc().toIso8601String(),
          });
          await _storage.write(key: _key(name), value: jsonEncode(records));
        }
        _rows[name] = records;
      }),
    );
  }

  Future<void> update(String name, void Function(List<LocalRow>) change) {
    final action = _queue.then((_) async {
      await load();
      final next = rows(name).map((r) => LocalRow.from(r)).toList();
      change(next);
      await _storage.write(key: _key(name), value: jsonEncode(next));
      _rows[name] = next;
      notifyListeners();
    });
    _queue = action.catchError((Object _) {});
    return action;
  }

  static String day(DateTime t) =>
      t.toLocal().toIso8601String().substring(0, 10);
  Future<void> reward(DateTime now) => update('game', (list) {
    final today = day(now);
    if (!list.any((r) => r['day'] == today)) list.add({'day': today});
  });
  Future<void> clock({required bool entering, required DateTime now}) =>
      update('shifts', (list) {
        final active = list.where((r) => r['end'] == null).lastOrNull;
        if (entering && active == null) {
          list.add({'start': now.toUtc().toIso8601String()});
        }
        if (!entering && active != null) {
          final start = DateTime.parse(active['start']);
          if (now.isBefore(start)) throw StateError('time');
          active['end'] = now.toUtc().toIso8601String();
        }
      });
  int get localPoints =>
      rows('game').length -
      rows('redemptions').fold<int>(0, (sum, r) => sum + (r['cost'] as int));
  bool redeemed(String id) => rows('redemptions').any((r) => r['id'] == id);
  Future<void> redeemSample(String id, String title, int cost, DateTime now) =>
      update('redemptions', (claims) {
        if (cost <= 0 ||
            claims.any((r) => r['id'] == id) ||
            localPoints < cost) {
          throw StateError('unavailable');
        }
        claims.add({
          'id': id,
          'title': title,
          'cost': cost,
          'time': now.toUtc().toIso8601String(),
        });
      });
  Future<bool> decideRequest(String id, bool approved) async {
    var changed = false;
    await update('appointments', (rows) {
      final request = rows
          .where(
            (row) =>
                row['id'] == id &&
                row['source'] == 'hospital' &&
                row['status'] == 'pending',
          )
          .firstOrNull;
      if (request == null) return;
      request['status'] = approved ? 'approved' : 'declined';
      changed = true;
    });
    return changed;
  }

  bool inCart(Object? id) => rows('cart').any((r) => r['id'] == id);
  Future<void> addCart(LocalRow item) => update('cart', (list) {
    if (item['id'] != null && !list.any((r) => r['id'] == item['id'])) {
      list.add(item);
    }
  });
  Future<void> removeCart(Object? id) =>
      update('cart', (list) => list.removeWhere((r) => r['id'] == id));
}
