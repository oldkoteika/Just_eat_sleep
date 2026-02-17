import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'pending_events_ops_box';
const _keyList = 'pending_ops_list';

/// Операция в очереди: add, update, remove.
enum PendingOpType { add, update, remove }

/// Одна операция: JSON с type, payload (event json или eventId), createdAt.
Map<String, dynamic> _createOp(PendingOpType type, dynamic payload, DateTime createdAt) {
  return {
    'type': type.name,
    'payload': payload,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Локальное хранилище очереди неотправленных операций с событиями.
class PendingEventsOpsStorage {
  PendingEventsOpsStorage._();

  static Future<Box<dynamic>> _openBox() => Hive.openBox(_boxName);

  static Future<List<Map<String, dynamic>>> getOps() async {
    final box = await _openBox();
    final data = box.get(_keyList);
    if (data is! List) return [];
    return data
        .map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Future<void> addAddOp(Map<String, dynamic> eventJson) async {
    final ops = await getOps();
    ops.add(_createOp(PendingOpType.add, eventJson, DateTime.now()));
    await _saveOps(ops);
  }

  static Future<void> addUpdateOp(Map<String, dynamic> eventJson) async {
    final ops = await getOps();
    ops.add(_createOp(PendingOpType.update, eventJson, DateTime.now()));
    await _saveOps(ops);
  }

  static Future<void> addRemoveOp(String eventId) async {
    final ops = await getOps();
    ops.add(_createOp(PendingOpType.remove, eventId, DateTime.now()));
    await _saveOps(ops);
  }

  static Future<void> removeOpAt(int index) async {
    final ops = await getOps();
    if (index >= 0 && index < ops.length) {
      ops.removeAt(index);
      await _saveOps(ops);
    }
  }

  static Future<void> _saveOps(List<Map<String, dynamic>> ops) async {
    final box = await _openBox();
    await box.put(_keyList, ops);
  }
}
