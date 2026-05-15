import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'hive_boxes.dart';
import 'sync_action.dart';

/// Manages all local Hive storage operations.
/// This is the single source of truth for offline data.
class OfflineStorage {
  static final OfflineStorage _instance = OfflineStorage._internal();
  factory OfflineStorage() => _instance;
  OfflineStorage._internal();

  static const _uuid = Uuid();

  bool _initialized = false;

  /// Initializes Hive and opens all required boxes.
  /// Must be called once before any data operations (in main.dart).
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Open all boxes
    for (final boxName in HiveBoxes.all) {
      await Hive.openBox(boxName);
    }

    _initialized = true;
  }

  // ─── Sync Queue ───────────────────────────────────────────────

  Box get _syncBox => Hive.box(HiveBoxes.syncQueue);

  /// Enqueues a new action to be synced later.
  /// Returns the generated action ID.
  Future<String> enqueue({
    required String table,
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    final id = _uuid.v4();
    final action = SyncAction(
      id: id,
      table: table,
      actionType: actionType,
      payload: payload,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    await _syncBox.put(id, action.toMap());
    return id;
  }

  /// Returns all pending (un-synced) actions, ordered by creation time.
  List<SyncAction> getPendingActions() {
    final actions = <SyncAction>[];
    for (final key in _syncBox.keys) {
      final map = _syncBox.get(key);
      if (map != null) {
        final action = SyncAction.fromMap(Map<dynamic, dynamic>.from(map));
        if (!action.isSynced) {
          actions.add(action);
        }
      }
    }
    actions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return actions;
  }

  /// Returns the total count of pending actions.
  int get pendingCount {
    int count = 0;
    for (final key in _syncBox.keys) {
      final map = _syncBox.get(key);
      if (map != null) {
        final action = SyncAction.fromMap(Map<dynamic, dynamic>.from(map));
        if (!action.isSynced) count++;
      }
    }
    return count;
  }

  /// Marks an action as synced.
  Future<void> markSynced(String actionId) async {
    final map = _syncBox.get(actionId);
    if (map != null) {
      final action = SyncAction.fromMap(Map<dynamic, dynamic>.from(map));
      await _syncBox.put(actionId, action.copyWith(isSynced: true).toMap());
    }
  }

  /// Increments the retry count for a failed action.
  Future<void> incrementRetry(String actionId) async {
    final map = _syncBox.get(actionId);
    if (map != null) {
      final action = SyncAction.fromMap(Map<dynamic, dynamic>.from(map));
      await _syncBox.put(
        actionId,
        action.copyWith(retryCount: action.retryCount + 1).toMap(),
      );
    }
  }

  /// Removes a synced action from the queue (cleanup).
  Future<void> removeAction(String actionId) async {
    await _syncBox.delete(actionId);
  }

  /// Clears all synced actions from the queue.
  Future<void> clearSynced() async {
    final keysToRemove = <dynamic>[];
    for (final key in _syncBox.keys) {
      final map = _syncBox.get(key);
      if (map != null) {
        final action = SyncAction.fromMap(Map<dynamic, dynamic>.from(map));
        if (action.isSynced) keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      await _syncBox.delete(key);
    }
  }

  // ─── Operations (Collection Requests) ─────────────────────────

  Box get _opsBox => Hive.box(HiveBoxes.operations);

  /// Saves an operation locally.
  Future<void> saveOperation(String id, Map<String, dynamic> data) async {
    await _opsBox.put(id, data);
  }

  /// Retrieves a single operation by ID.
  Map<String, dynamic>? getOperation(String id) {
    final raw = _opsBox.get(id);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  /// Retrieves all locally stored operations.
  List<Map<String, dynamic>> getAllOperations() {
    return _opsBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Deletes an operation locally.
  Future<void> deleteOperation(String id) async {
    await _opsBox.delete(id);
  }

  // ─── Declarations (Supplier Count/Weight) ─────────────────────

  Box get _declBox => Hive.box(HiveBoxes.declarations);

  /// Saves a declaration locally.
  Future<void> saveDeclaration(String id, Map<String, dynamic> data) async {
    await _declBox.put(id, data);
  }

  /// Retrieves all locally stored declarations.
  List<Map<String, dynamic>> getAllDeclarations() {
    return _declBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Deletes a declaration locally.
  Future<void> deleteDeclaration(String id) async {
    await _declBox.delete(id);
  }

  // ─── User Session ─────────────────────────────────────────────

  Box get _sessionBox => Hive.box(HiveBoxes.userSession);

  /// Saves user session for offline access.
  Future<void> saveSession(Map<String, dynamic> sessionData) async {
    await _sessionBox.put('current', sessionData);
  }

  /// Retrieves cached user session.
  Map<String, dynamic>? getSession() {
    final raw = _sessionBox.get('current');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  /// Clears user session (on logout).
  Future<void> clearSession() async {
    await _sessionBox.delete('current');
  }

  // ─── Full Reset ───────────────────────────────────────────────

  /// Clears ALL local data (useful for full logout / debug).
  Future<void> clearAll() async {
    for (final boxName in HiveBoxes.all) {
      final box = Hive.box(boxName);
      await box.clear();
    }
  }
}
