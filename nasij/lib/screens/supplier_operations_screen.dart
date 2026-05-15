import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cubits/auth_cubit.dart';
import '../cubits/sync_cubit.dart';
import '../data/offline_storage.dart';
import '../l10n/app_localizations.dart';
import '../models/operation.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/toast_utils.dart';
import '../widgets/operation_card.dart';
import '../widgets/supplier_bottom_nav_bar.dart';

class SupplierOperationsScreen extends StatefulWidget {
  final SupplierRole role;

  const SupplierOperationsScreen({super.key, required this.role});

  @override
  State<SupplierOperationsScreen> createState() =>
      _SupplierOperationsScreenState();
}

class _SupplierOperationsScreenState extends State<SupplierOperationsScreen> {
  final List<Operation> _operations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOperations());
  }

  Future<void> _loadOperations() async {
    final authState = context.read<AuthCubit>().state;
    final l10n = AppLocalizations.of(context);
    final accessToken = authState.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final rows = await ApiService.getSupplierOperations(
        accessToken: accessToken,
        includeHistory: true,
      );
      final storage = OfflineStorage();
      for (final row in rows) {
        final id = row['id'] as String?;
        if (id != null && id.isNotEmpty) {
          await storage.saveOperation(id, row);
        }
      }
      if (!mounted) return;
      setState(() {
        _operations
          ..clear()
          ..addAll(rows.map(Operation.fromApi));
        _loading = false;
      });
    } catch (_) {
      final cached = OfflineStorage()
          .getAllOperations()
          .map(Operation.fromApi)
          .toList();
      if (!mounted) return;
      setState(() {
        _operations
          ..clear()
          ..addAll(cached);
        _loading = false;
      });
      ToastUtils.showWarning(context, l10n.tr('supplier_ops_offline_fallback'));
    }
  }

  Future<void> _cancelPending(
    Operation operation,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.tr('supplier_cancel_pending_title')),
          content: Text(l10n.tr('supplier_cancel_pending_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.tr('common_no')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.tr('common_yes')),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await _performCancel(
      operation,
      callConfirmed: false,
      reason: 'pending_cancel',
    );
  }

  Future<void> _cancelAssigned(
    Operation operation,
    AppLocalizations l10n,
  ) async {
    var didCall = false;
    final allowed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> callCollector() async {
              final phone = operation.collectorPhone;
              if (phone == null || phone.isEmpty) return;
              final uri = Uri.parse('tel:$phone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
                setDialogState(() => didCall = true);
              }
            }

            return AlertDialog(
              title: Text(l10n.tr('supplier_cancel_assigned_title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.tr('supplier_cancel_assigned_desc')),
                  const SizedBox(height: 10),
                  Text(
                    l10n
                        .tr('supplier_collector_phone')
                        .replaceAll(
                          '{phone}',
                          operation.collectorPhone ?? '--',
                        ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: callCollector,
                  child: Text(l10n.tr('supplier_call_collector')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.tr('common_no')),
                ),
                TextButton(
                  onPressed: didCall
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: Text(l10n.tr('supplier_confirm_cancel')),
                ),
              ],
            );
          },
        );
      },
    );
    if (allowed != true) return;
    await _performCancel(
      operation,
      callConfirmed: true,
      reason: 'assigned_cancel',
    );
  }

  Future<void> _performCancel(
    Operation operation, {
    required bool callConfirmed,
    required String reason,
  }) async {
    final l10n = AppLocalizations.of(context);
    final authCubit = context.read<AuthCubit>();
    final syncCubit = context.read<SyncCubit>();
    final accessToken = authCubit.state.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      ToastUtils.showError(context, l10n.tr('auth_error_generic'));
      return;
    }

    try {
      await ApiService.cancelSupplierOperation(
        accessToken: accessToken,
        operationId: operation.id,
        callConfirmed: callConfirmed,
        reason: reason,
      );
      if (!mounted) return;
      await _loadOperations();
      await authCubit.refreshSupplierProfile();
      ToastUtils.showSuccess(context, l10n.tr('supplier_cancel_success'));
    } catch (_) {
      await syncCubit.enqueueAction(
        table: 'supplier_operations',
        actionType: 'cancel',
        payload: {
          'operation_id': operation.id,
          'call_confirmed': callConfirmed,
          'reason': reason,
        },
      );
      await OfflineStorage().saveOperation(operation.id, {
        'id': operation.id,
        'status': operation.canCancelAssigned
            ? 'CANCELLED_ASSIGNED'
            : 'CANCELLED_PENDING',
        'supplier_role': operation.supplierRole,
        'quantity_count': operation.quantityCount,
        'quantity_weight_kg': operation.quantityWeightKg,
        'location_lat': null,
        'location_lng': null,
        'collector_phone': operation.collectorPhone,
        'cancel_reason': reason,
        'trust_penalty_applied': operation.canCancelAssigned ? 10 : 0,
        'created_at': operation.createdAt?.toIso8601String(),
      });
      if (!mounted) return;
      await _loadOperations();
      ToastUtils.showWarning(context, l10n.tr('supplier_cancel_saved_offline'));
    }
  }

  String _statusLabel(AppLocalizations l10n, OperationStatus status) {
    switch (status) {
      case OperationStatus.pending:
        return l10n.tr('supplier_status_pending');
      case OperationStatus.assigned:
        return l10n.tr('supplier_status_assigned');
      case OperationStatus.cancelledPending:
        return l10n.tr('supplier_status_cancelled_pending');
      case OperationStatus.cancelledAssigned:
        return l10n.tr('supplier_status_cancelled_assigned');
      case OperationStatus.completed:
        return l10n.tr('supplier_status_completed');
    }
  }

  String _quantityLabel(AppLocalizations l10n, Operation operation) {
    if (operation.quantityWeightKg != null) {
      return l10n
          .tr('supplier_quantity_weight')
          .replaceAll(
            '{value}',
            operation.quantityWeightKg!.toStringAsFixed(1),
          );
    }
    if (operation.quantityCount != null) {
      return l10n
          .tr('supplier_quantity_count')
          .replaceAll('{value}', '${operation.quantityCount}');
    }
    return l10n.tr('supplier_quantity_unknown');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = _operations
        .where((operation) => operation.isActive)
        .toList();
    final history = _operations
        .where((operation) => !operation.isActive)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tr('supplier_active_ops'),
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n
                              .tr('supplier_total')
                              .replaceAll('{count}', '${_operations.length}'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                if (_loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        l10n.tr('supplier_section_active'),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final op = active[index];
                        final createdAtText = op.createdAt != null
                            ? '${op.createdAt!.day.toString().padLeft(2,'0')}/${op.createdAt!.month.toString().padLeft(2,'0')}/${op.createdAt!.year}'
                            : '--';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: OperationCard(
                            operation: op,
                            statusLabel: _statusLabel(l10n, op.status),
                            quantityLabel: _quantityLabel(l10n, op),
                            locationLabel: l10n.tr('supplier_location_none'),
                            createdAtLabel: createdAtText,
                            collectorPhoneLabel:
                                op.collectorPhone == null
                                ? null
                                : l10n
                                      .tr('supplier_collector_phone')
                                      .replaceAll('{phone}', op.collectorPhone!),
                            actionLabel: l10n.tr('supplier_delete_operation'),
                            onActionTap: op.canCancelPending
                                ? () => _cancelPending(op, l10n)
                                : op.canCancelAssigned
                                ? () => _cancelAssigned(op, l10n)
                                : null,
                          ),
                        );
                      }, childCount: active.length),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                      child: Text(
                        l10n.tr('supplier_section_history'),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final op = history[index];
                        final createdAtText = op.createdAt != null
                            ? '${op.createdAt!.day.toString().padLeft(2,'0')}/${op.createdAt!.month.toString().padLeft(2,'0')}/${op.createdAt!.year}'
                            : '--';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: OperationCard(
                            operation: op,
                            statusLabel: _statusLabel(l10n, op.status),
                            quantityLabel: _quantityLabel(l10n, op),
                            locationLabel: l10n.tr('supplier_location_none'),
                            createdAtLabel: createdAtText,
                            collectorPhoneLabel:
                                op.collectorPhone == null
                                ? null
                                : l10n
                                      .tr('supplier_collector_phone')
                                      .replaceAll('{phone}', op.collectorPhone!),
                          ),
                        );
                      }, childCount: history.length),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SupplierBottomNavBar(currentIndex: 1),
          ),
        ],
      ),
    );
  }
}
