import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/timetable_slot.dart';
import '../../services/mess_service.dart';

/// Lightweight Hive-backed cache for the two highest-value data sets:
/// timetable slots and the mess menu.
///
/// Both boxes are opened in main.dart before runApp(). All methods are
/// synchronous reads (instant) or async writes (fire-and-forget from providers).
///
/// Keys:
///   Timetable : `slots_<uid>`  and  `ts_<uid>`  (ISO-8601 timestamp)
///   Mess menu : `menu_<parity>`  and  `ts_<parity>`
class LocalCacheService {
  static const String _timetableBox = 'timetable_cache';
  static const String _messBox = 'mess_cache';

  // ─── Timetable ─────────────────────────────────────────────────────────────

  /// Persist [slots] for the given [uid]. Called after every live Firestore fetch.
  static Future<void> writeTimetable(
      String uid, List<TimetableSlot> slots) async {
    final box = Hive.box<String>(_timetableBox);
    final encoded = jsonEncode(slots.map((s) => {...s.toMap(), 'id': s.id}).toList());
    await box.put('slots_$uid', encoded);
    await box.put('ts_$uid', DateTime.now().toIso8601String());
  }

  /// Return cached slots + timestamp, or null if nothing is cached for [uid].
  static ({List<TimetableSlot> slots, DateTime lastUpdated})? readTimetable(
      String uid) {
    final box = Hive.box<String>(_timetableBox);
    final raw = box.get('slots_$uid');
    final ts = box.get('ts_$uid');
    if (raw == null || ts == null) return null;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final slots = list
          .map((e) => TimetableSlot.fromMap(
              Map<String, dynamic>.from(e as Map), e['id'] as String? ?? ''))
          .toList();
      return (slots: slots, lastUpdated: DateTime.parse(ts));
    } catch (_) {
      return null;
    }
  }

  /// Remove cached timetable for [uid] (called on sign-out).
  static Future<void> clearTimetable(String uid) async {
    final box = Hive.box<String>(_timetableBox);
    await box.delete('slots_$uid');
    await box.delete('ts_$uid');
  }

  // ─── Mess menu ──────────────────────────────────────────────────────────────

  /// Persist [messState] under the [parity] key ('even' or 'odd').
  static Future<void> writeMessMenu(String parity, MessState messState) async {
    final box = Hive.box<String>(_messBox);
    final menuJson = messState.weeklyMenu.map(
      (day, menu) => MapEntry(day, menu.toMap()),
    );
    final encoded = jsonEncode({
      'weeklyMenu': menuJson,
      'isEvenWeek': messState.isEvenWeek,
    });
    await box.put('menu_$parity', encoded);
    await box.put('ts_$parity', DateTime.now().toIso8601String());
  }

  /// Return cached [MessState] + timestamp, or null if nothing cached.
  /// [isAdmin] is passed in because it is never cached (it's a live auth claim).
  static ({MessState state, DateTime lastUpdated})? readMessMenu(
      String parity, {required bool isAdmin}) {
    final box = Hive.box<String>(_messBox);
    final raw = box.get('menu_$parity');
    final ts = box.get('ts_$parity');
    if (raw == null || ts == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final menuMap = (decoded['weeklyMenu'] as Map<String, dynamic>).map(
        (day, menuData) => MapEntry(
            day, MessMenu.fromMap(Map<String, dynamic>.from(menuData as Map))),
      );
      final state = MessState(
        weeklyMenu: menuMap,
        isAdmin: isAdmin,
        isEvenWeek: decoded['isEvenWeek'] as bool? ?? false,
        fromCache: true,
        lastUpdated: DateTime.parse(ts),
      );
      return (state: state, lastUpdated: DateTime.parse(ts));
    } catch (_) {
      return null;
    }
  }

  /// Remove cached mess menu for a given parity.
  static Future<void> clearMessMenu(String parity) async {
    final box = Hive.box<String>(_messBox);
    await box.delete('menu_$parity');
    await box.delete('ts_$parity');
  }
}
