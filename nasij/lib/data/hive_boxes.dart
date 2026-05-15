/// Central registry of all Hive box names used across the app.
/// Keeps box naming consistent and avoids magic strings.
class HiveBoxes {
  HiveBoxes._();

  /// Stores the sync queue entries (pending actions to push to server)
  static const String syncQueue = 'sync_queue';

  /// Stores collection requests / operations
  static const String operations = 'operations';

  /// Stores supplier declarations (count/weight submissions)
  static const String declarations = 'declarations';

  /// Stores user session data for offline access
  static const String userSession = 'user_session';

  /// All box names for batch initialization
  static const List<String> all = [
    syncQueue,
    operations,
    declarations,
    userSession,
  ];
}
