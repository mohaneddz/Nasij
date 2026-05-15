/// Represents a single queued action that needs to be synced to the server.
/// Each action is stored in Hive and replayed when connectivity is restored.
class SyncAction {
  /// Unique ID for this action (UUID v4)
  final String id;

  /// The Supabase table this action targets
  final String table;

  /// The type of operation: 'insert', 'update', 'delete'
  final String actionType;

  /// The payload to send (JSON-serializable map)
  final Map<String, dynamic> payload;

  /// ISO 8601 timestamp of when this action was created
  final String createdAt;

  /// Number of times this action has been retried
  final int retryCount;

  /// Whether this action has been successfully synced
  final bool isSynced;

  const SyncAction({
    required this.id,
    required this.table,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.isSynced = false,
  });

  /// Creates a copy with updated fields.
  SyncAction copyWith({int? retryCount, bool? isSynced}) {
    return SyncAction(
      id: id,
      table: table,
      actionType: actionType,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Converts to a Map for Hive storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table': table,
      'actionType': actionType,
      'payload': payload,
      'createdAt': createdAt,
      'retryCount': retryCount,
      'isSynced': isSynced,
    };
  }

  /// Creates a SyncAction from a Hive-stored Map.
  factory SyncAction.fromMap(Map<dynamic, dynamic> map) {
    return SyncAction(
      id: map['id'] as String,
      table: map['table'] as String,
      actionType: map['actionType'] as String,
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      createdAt: map['createdAt'] as String,
      retryCount: map['retryCount'] as int? ?? 0,
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }
}
