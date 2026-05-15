import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/offline_storage.dart';
import '../data/sync_action.dart';
import '../services/api_service.dart';
import '../services/background_sync_service.dart';
import '../services/sync_action_dispatcher.dart';
import 'connectivity_cubit.dart';

// --- State ---
enum SyncStatus { idle, syncing, synced, error }

class SyncState extends Equatable {
  final SyncStatus status;
  final int pendingCount;
  final int syncedCount;
  final String? lastError;
  final DateTime? lastSyncAt;

  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.syncedCount = 0,
    this.lastError,
    this.lastSyncAt,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    int? syncedCount,
    String? lastError,
    DateTime? lastSyncAt,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      syncedCount: syncedCount ?? this.syncedCount,
      lastError: lastError ?? this.lastError,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pendingCount,
    syncedCount,
    lastError,
    lastSyncAt,
  ];
}

// --- Cubit ---
class SyncCubit extends Cubit<SyncState> {
  final OfflineStorage _storage;
  final ConnectivityCubit _connectivityCubit;
  StreamSubscription? _connectivitySub;
  Timer? _periodicSync;

  /// Maximum retries per action before it's considered permanently failed
  static const int maxRetries = 5;

  /// Interval between automatic sync attempts when online
  static const Duration syncInterval = Duration(minutes: 2);

  SyncCubit({
    required OfflineStorage storage,
    required ConnectivityCubit connectivityCubit,
  }) : _storage = storage,
       _connectivityCubit = connectivityCubit,
       super(const SyncState()) {
    _init();
  }

  void _init() {
    // Update pending count on startup
    _refreshPendingCount();

    // Listen to connectivity changes — auto-sync when coming back online
    _connectivitySub = _connectivityCubit.stream.listen((connState) {
      if (connState.isOnline) {
        syncNow();
      }
    });

    // Also check if currently online and sync
    if (_connectivityCubit.state.isOnline) {
      syncNow();
    }

    // Start periodic sync timer
    _periodicSync = Timer.periodic(syncInterval, (_) {
      if (_connectivityCubit.state.isOnline) {
        syncNow();
      }
    });
  }

  void _refreshPendingCount() {
    emit(state.copyWith(pendingCount: _storage.pendingCount));
  }

  // ─── Public API ───────────────────────────────────────────────

  /// Enqueues a new action and immediately attempts sync if online.
  Future<String> enqueueAction({
    required String table,
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    final id = await _storage.enqueue(
      table: table,
      actionType: actionType,
      payload: payload,
    );

    _refreshPendingCount();
    await BackgroundSyncService.scheduleOneOffSync();

    // If online, try to sync immediately
    if (_connectivityCubit.state.isOnline) {
      syncNow();
    }

    return id;
  }

  /// Triggers an immediate sync of all pending actions.
  Future<void> syncNow() async {
    if (state.status == SyncStatus.syncing) return; // Already syncing
    if (!_connectivityCubit.state.isOnline) return; // No connectivity

    final pending = _storage.getPendingActions();
    if (pending.isEmpty) {
      emit(state.copyWith(status: SyncStatus.synced, pendingCount: 0));
      return;
    }

    emit(state.copyWith(status: SyncStatus.syncing));

    int synced = 0;
    String? lastError;

    for (final action in pending) {
      if (action.retryCount >= maxRetries) {
        // Skip permanently failed actions
        continue;
      }

      try {
        await _pushToServer(action);
        await _storage.markSynced(action.id);
        synced++;
      } on ApiException catch (e) {
        // 409 Conflict = already applied on the server (idempotent) — treat as success
        if (e.statusCode == 409) {
          await _storage.markSynced(action.id);
          synced++;
        } else {
          lastError = e.toString();
          await _storage.incrementRetry(action.id);
        }
      } catch (e) {
        lastError = e.toString();
        await _storage.incrementRetry(action.id);
      }
    }

    // Cleanup synced actions
    await _storage.clearSynced();

    _refreshPendingCount();

    emit(
      state.copyWith(
        status: lastError != null ? SyncStatus.error : SyncStatus.synced,
        syncedCount: state.syncedCount + synced,
        lastError: lastError,
        lastSyncAt: DateTime.now(),
      ),
    );
  }

  /// Pushes a single action to the Supabase server.
  /// This is where the actual remote call happens.
  Future<void> _pushToServer(SyncAction action) async {
    final session = _storage.getSession();
    final accessToken = session?['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException('Missing supplier session token');
    }
    await pushSyncAction(accessToken: accessToken, action: action);
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    _periodicSync?.cancel();
    return super.close();
  }
}
