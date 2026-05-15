import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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

class MyLoadsScreen extends StatefulWidget {
  const MyLoadsScreen({super.key});

  @override
  State<MyLoadsScreen> createState() => _MyLoadsScreenState();
}

class _MyLoadsScreenState extends State<MyLoadsScreen> {
  Batch? _activeJob;
  final BatchService _batchService = BatchService();
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadActiveJobs();
  }

  Future<void> _loadActiveJobs() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final activeLoad = await _batchService.fetchCurrentCollectorLoad();
      if (mounted) {
        setState(() {
          _activeJob = activeLoad;
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
    final raw = batch.actionTimestamp ?? batch.createdAt;
    if (raw == null || raw.isEmpty) {
      return 'TBD';
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

  Future<void> _cancelCurrentJob(Batch job) async {
    final syncCubit = context.read<SyncCubit>();
    try {
      await _batchService.cancelClaim(job.batchId);
      if (!mounted) return;
      setState(() => _activeJob = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current job cancelled'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadActiveJobs();
    } catch (error) {
      final mapped = ApiService.mapTransportException(error);
      if (mapped.message == 'auth_error_backend_unreachable' ||
          mapped.message == 'auth_error_backend_timeout') {
        await syncCubit.enqueueAction(
          table: 'collector_batches',
          actionType: 'cancel_claim',
          payload: {'batch_id': job.batchId},
        );
        if (!mounted) return;
        setState(() => _activeJob = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Offline: cancellation queued and will sync automatically.',
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mapped.message)));
      }
    }
  }

  void _cancelJob(AppLocalizations l10n) {
    final activeJob = _activeJob;
    if (activeJob == null) {
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.tr('loads_cancel_confirm_title'),
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          l10n.tr('loads_cancel_confirm_body'),
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.tr('loads_keep_job'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          NassajDangerButton(
            label: l10n.tr('loads_cancel_job'),
            icon: Icons.cancel_outlined,
            height: 40,
            onPressed: () {
              Navigator.pop(ctx);
              _cancelCurrentJob(activeJob);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _contactSite(String? phone, AppLocalizations l10n) async {
    final sanitized = (phone ?? '').trim();
    if (sanitized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller phone is unavailable')),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: sanitized);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.tr('loads_calling_site'),
            style: AppTextStyles.bodyMedium,
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  void _showFinishModal(Batch job) {
    final weightCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 28,
            right: 28,
            top: 28,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.borderMedium,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Text('Finish Collection', style: AppTextStyles.headingLarge),
                const SizedBox(height: 6),
                Text(
                  'Record final measurements before generating the QR code.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 28),

                // Weight input
                NassajSectionLabel(label: 'ACTUAL WEIGHT (KG)'),
                const SizedBox(height: 10),
                NassajInput(
                  controller: weightCtrl,
                  hintText: 'e.g. 250.5',
                  prefixIcon: Icons.scale_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 24),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: NassajButton(
                    label: 'Complete & Generate QR',
                    icon: Icons.qr_code,
                    onPressed: () async {
                      final weight = double.tryParse(weightCtrl.text);
                      if (weight == null) {
                        NassajSnack.show(
                          context,
                          'Please enter a valid weight',
                          isError: true,
                        );
                        return;
                      }
                      try {
                        await _batchService.d1Intake(job.batchId, {
                          'weight_raw_e1_kg': weight,
                        });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showQrSheet(job);
                          _loadActiveJobs();
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          NassajSnack.show(ctx, 'Error: $e', isError: true);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  void _showQrSheet(Batch job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Text('Batch QR Code', style: AppTextStyles.headingMedium),
              const SizedBox(height: 6),
              Text(
                'Show this to the Depot Worker for intake scanning',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              NassajCard(
                padding: const EdgeInsets.all(16),
                borderColor: AppColors.primaryBorder,
                child: QrImageView(
                  data: job.batchId,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ID: ${job.batchId}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: NassajSecondaryButton(
                  label: 'Close',
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    child: NassajPageHeader(
                      title: l10n.tr('loads_title'),
                      icon: Icons.local_shipping_outlined,
                      trailing: NassajFloatingIconButton(
                        icon: Icons.notifications_outlined,
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

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
                else if (_activeJob != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverToBoxAdapter(
                      child: _buildActiveJobContent(_activeJob!, l10n),
                    ),
                  )
                else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _loadError != null
                        ? NassajEmptyState(
                            icon: Icons.wifi_off_rounded,
                            title: 'Unable to load jobs',
                            subtitle: _loadError!,
                            action: NassajButton(
                              label: 'Retry',
                              icon: Icons.refresh,
                              onPressed: _loadActiveJobs,
                            ),
                          )
                        : NassajEmptyState(
                            icon: Icons.local_shipping_outlined,
                            title: l10n.tr('loads_no_active_jobs'),
                            subtitle: l10n.tr('loads_no_active_jobs_desc'),
                            action: NassajButton(
                              label: l10n.tr('loads_find_jobs'),
                              icon: Icons.map_outlined,
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) =>
                                      const CollectionMapScreen(),
                                  transitionDuration: Duration.zero,
                                ),
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),

          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MapBottomNavBar(currentIndex: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobContent(Batch job, AppLocalizations l10n) {
    return Column(
      children: [
        // ── Main job card ────────────────────────────────────
        NassajCard(
          borderColor: AppColors.primaryBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge + ID
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NassajBadge.success(
                    label: l10n.tr('loads_active_job'),
                    icon: Icons.circle,
                  ),
                  Text('ID: ${job.batchId}', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 16),

              // Breed / title
              Text(job.breed ?? '—', style: AppTextStyles.headingLarge),
              const SizedBox(height: 8),

              // Location
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.wilaya ?? '—',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(job.creatorPhone ?? '--', style: AppTextStyles.bodySmall),

              // Mini tracking map
              if (job.locationLat != null && job.locationLng != null) ...[
                const SizedBox(height: 16),
                _buildTrackingMap(
                  LatLng(job.locationLat!, job.locationLng!),
                  l10n,
                ),
              ],

              const SizedBox(height: 18),

              // Contact button
              SizedBox(
                width: double.infinity,
                child: NassajButton(
                  label: l10n.tr('loads_contact_site'),
                  icon: Icons.phone,
                  onPressed: () => _contactSite(job.creatorPhone, l10n),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Info cards row ────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: NassajCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.tr('loads_load_type'),
                      style: AppTextStyles.captionAllCaps,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.typeDeLaine ?? '—',
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NassajCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.scale_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.tr('loads_sheep_count'),
                      style: AppTextStyles.captionAllCaps,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.sacsCount ?? 0}',
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Pickup slot card ──────────────────────────────────
        NassajCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tr('loads_pickup_slot'),
                      style: AppTextStyles.captionAllCaps,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRelativeTime(job),
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Complete task ─────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: NassajSecondaryButton(
            label: 'Finish & Generate QR',
            icon: Icons.qr_code_2,
            height: 52,
            onPressed: () => _showFinishModal(job),
          ),
        ),
        const SizedBox(height: 10),

        // ── Cancel ────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: NassajDangerButton(
            label: l10n.tr('loads_cancel_job'),
            icon: Icons.cancel_outlined,
            height: 52,
            onPressed: () => _cancelJob(l10n),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingMap(LatLng sellerLocation, AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: sellerLocation,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.nasij',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: sellerLocation,
                      width: 80,
                      height: 80,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              l10n.tr('loads_seller'),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 8,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Follow button overlay
            Positioned(
              top: 8,
              right: 8,
              child: NassajFloatingIconButton(
                icon: Icons.my_location,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.tr('loads_following_seller'),
                        style: AppTextStyles.bodySmall,
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
