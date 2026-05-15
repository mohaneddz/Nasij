import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../cubits/sync_cubit.dart';
import '../l10n/app_localizations.dart';
import '../models/batch.dart';
import '../services/api_service.dart';
import '../services/batch_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/nassaj_components.dart';
import '../widgets/map_bottom_nav_bar.dart';
import 'collection_map_screen.dart';

class PrioritizedOrdersScreen extends StatefulWidget {
  const PrioritizedOrdersScreen({super.key});

  @override
  State<PrioritizedOrdersScreen> createState() =>
      _PrioritizedOrdersScreenState();
}

class _PrioritizedOrdersScreenState extends State<PrioritizedOrdersScreen> {
  final BatchService _batchService = BatchService();
  List<Batch> _batches = [];
  bool _isLoading = true;
  String _filter = 'All';
  String? _loadError;
  bool _hasActiveLoad = false;
  String? _activeLoadBatchId;
  String? _acceptingBatchId;

  @override
  void initState() {
    super.initState();
    _loadScreenData();
  }

  Future<void> _loadScreenData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _batchService.fetchPendingBatches(),
        _batchService.fetchCurrentCollectorLoad(),
      ]);
      final batches = results[0] as List<Batch>;
      final activeLoad = results[1] as Batch?;
      if (mounted) {
        setState(() {
          _batches = batches;
          _hasActiveLoad = activeLoad != null;
          _activeLoadBatchId = activeLoad?.batchId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  String _formatRelativeTime(Batch batch) {
    final raw = batch.createdAt ?? batch.actionTimestamp;
    if (raw == null || raw.isEmpty) {
      return '--';
    }

    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) {
      return raw;
    }

    final now = DateTime.now();
    final diff = now.difference(parsed);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  Future<void> _acceptTask(Batch batch) async {
    final syncCubit = context.read<SyncCubit>();
    if (_hasActiveLoad) {
      NassajSnack.show(
        context,
        'You already have an active load. Cancel or complete it first.',
        isError: true,
      );
      return;
    }

    setState(() => _acceptingBatchId = batch.batchId);
    try {
      final claimed = await _batchService.claimBatch(batch.batchId);
      if (!mounted) return;
      NassajSnack.show(context, 'Task ${claimed.batchId} accepted');
      await _loadScreenData();
    } catch (error) {
      final mapped = ApiService.mapTransportException(error);
      if (mapped.message == 'auth_error_backend_unreachable' ||
          mapped.message == 'auth_error_backend_timeout') {
        await syncCubit.enqueueAction(
          table: 'collector_batches',
          actionType: 'claim',
          payload: {'batch_id': batch.batchId},
        );
        if (!mounted) return;
        setState(() {
          _hasActiveLoad = true;
          _activeLoadBatchId = batch.batchId;
          _batches = _batches.where((b) => b.batchId != batch.batchId).toList();
        });
        NassajSnack.show(
          context,
          'Offline: task queued and will sync automatically when online.',
        );
      } else {
        if (!mounted) return;
        NassajSnack.show(context, mapped.message, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _acceptingBatchId = null);
      }
    }
  }

  LocationType _mapSourceType(String? sourceType) {
    if (sourceType == 'C1') return LocationType.farmer;
    if (sourceType == 'C2') return LocationType.slaughterhouse;
    if (sourceType == 'C3') return LocationType.storage;
    return LocationType.farmer;
  }

  List<Batch> get _filteredBatches {
    if (_filter == 'Pending') {
      return _batches.where((b) => b.status == 'PENDING_PICKUP').toList();
    }
    if (_filter == 'Completed') {
      return _batches.where((b) => b.status != 'PENDING_PICKUP').toList();
    }
    return _batches;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NassajPageHeader(
                          title: l10n.tr('list_title'),
                          icon: Icons.format_list_bulleted_rounded,
                          trailing: NassajFloatingIconButton(
                            icon: Icons.tune,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Filter pills ──────────────────────
                        SizedBox(
                          height: 42,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            children: [
                              NassajFilterPill(
                                label: l10n.tr('list_filter_all'),
                                isActive: _filter == 'All',
                                onTap: () => setState(() => _filter = 'All'),
                              ),
                              const SizedBox(width: 8),
                              NassajFilterPill(
                                label: l10n.tr('list_filter_pending'),
                                isActive: _filter == 'Pending',
                                onTap: () =>
                                    setState(() => _filter = 'Pending'),
                              ),
                              const SizedBox(width: 8),
                              NassajFilterPill(
                                label: l10n.tr('list_filter_completed'),
                                isActive: _filter == 'Completed',
                                onTap: () =>
                                    setState(() => _filter = 'Completed'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Content ──────────────────────────────────
                if (_isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (_filteredBatches.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _loadError != null
                        ? NassajEmptyState(
                            icon: Icons.wifi_off_rounded,
                            title: 'Unable to load requests',
                            subtitle: _loadError!,
                            action: NassajButton(
                              label: 'Retry',
                              icon: Icons.refresh,
                              onPressed: _loadScreenData,
                            ),
                          )
                        : NassajEmptyState(
                            icon: Icons.inbox_outlined,
                            title: l10n.tr('list_filter_all'),
                            subtitle: l10n.tr('loads_no_active_jobs_desc'),
                          ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final batch = _filteredBatches[index];
                        final locType = _mapSourceType(batch.sourceType);
                        final isPending = batch.status == 'PENDING_PICKUP';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _OrderCard(
                            batch: batch,
                            locType: locType,
                            isPending: isPending,
                            l10n: l10n,
                            timeLabel: _formatRelativeTime(batch),
                            hasActiveLoad: _hasActiveLoad,
                            isAccepting: _acceptingBatchId == batch.batchId,
                            activeLoadBatchId: _activeLoadBatchId,
                            onAccept: () => _acceptTask(batch),
                          ),
                        );
                      }, childCount: _filteredBatches.length),
                    ),
                  ),
              ],
            ),
          ),

          // ── Bottom nav ──────────────────────────────────
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MapBottomNavBar(currentIndex: 1),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Batch batch;
  final LocationType locType;
  final bool isPending;
  final AppLocalizations l10n;
  final String timeLabel;
  final bool hasActiveLoad;
  final bool isAccepting;
  final String? activeLoadBatchId;
  final VoidCallback onAccept;

  const _OrderCard({
    required this.batch,
    required this.locType,
    required this.isPending,
    required this.l10n,
    required this.timeLabel,
    required this.hasActiveLoad,
    required this.isAccepting,
    required this.activeLoadBatchId,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return NassajCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: badge + time ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NassajBadge.primary(
                label: locType.localizedLabel(l10n),
                icon: locType.icon,
              ),
              Text(timeLabel, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 14),

          // ── Title ─────────────────────────────────────────
          Text(batch.batchId, style: AppTextStyles.headingMedium),
          const SizedBox(height: 6),

          // ── Location row ──────────────────────────────────
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  batch.wilaya ?? '—',
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(batch.creatorPhone ?? '--', style: AppTextStyles.bodySmall),

          // ── Metadata row ──────────────────────────────────
          if (batch.weightRawE1Kg != null || batch.sacsCount != null) ...[
            const SizedBox(height: 12),
            NassajDivider(),
            const SizedBox(height: 10),
            Row(
              children: [
                if (batch.weightRawE1Kg != null)
                  Expanded(
                    child: NassajInfoRow(
                      icon: Icons.scale_outlined,
                      label: 'WEIGHT',
                      value: '${batch.weightRawE1Kg} kg',
                    ),
                  ),
                if (batch.sacsCount != null)
                  Expanded(
                    child: NassajInfoRow(
                      icon: Icons.pets,
                      label: 'COUNT',
                      value: '${batch.sacsCount}',
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          // ── Action button ─────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: isPending
                ? hasActiveLoad
                      ? NassajSecondaryButton(
                          label: activeLoadBatchId == batch.batchId
                              ? 'Accepted on this device'
                              : 'Active load already assigned',
                          icon: Icons.lock_outline,
                          onPressed: () {},
                        )
                      : (isAccepting
                            ? NassajSecondaryButton(
                                label: 'Accepting...',
                                icon: Icons.hourglass_top,
                                onPressed: () {},
                              )
                            : NassajButton(
                                label: l10n.tr('list_accept_task'),
                                icon: Icons.check_circle_outline,
                                onPressed: onAccept,
                              ))
                : NassajSecondaryButton(
                    label: l10n.tr('list_in_progress'),
                    icon: Icons.pending_outlined,
                    onPressed: () {},
                  ),
          ),
        ],
      ),
    );
  }
}
