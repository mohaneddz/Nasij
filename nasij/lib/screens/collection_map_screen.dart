import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/batch.dart';
import '../services/batch_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/nassaj_components.dart';
import '../widgets/map_bottom_nav_bar.dart';

enum LocationType { farmer, slaughterhouse, storage }

extension LocationTypeExt on LocationType {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case LocationType.farmer:
        return l10n.tr('map_type_farmer');
      case LocationType.slaughterhouse:
        return l10n.tr('map_type_slaughterhouse');
      case LocationType.storage:
        return l10n.tr('map_type_storage');
    }
  }

  IconData get icon {
    switch (this) {
      case LocationType.farmer:
        return Icons.pets;
      case LocationType.slaughterhouse:
        return Icons.content_cut;
      case LocationType.storage:
        return Icons.warehouse;
    }
  }
}

class CollectionMapScreen extends StatefulWidget {
  const CollectionMapScreen({super.key});

  @override
  State<CollectionMapScreen> createState() => _CollectionMapScreenState();
}

class _CollectionMapScreenState extends State<CollectionMapScreen> {
  final MapController _mapController = MapController();
  Batch? _selectedBatch;
  final BatchService _batchService = BatchService();
  List<Batch> _batches = [];
  bool _isLoading = true;
  String? _loadError;

  final LatLng _algeriaCenter = const LatLng(28.0339, 1.6596);
  static const double _algeriaOverviewZoom = 5.2;

  LocationType _mapSourceType(String? sourceType) {
    if (sourceType == 'C1') return LocationType.farmer;
    if (sourceType == 'C2') return LocationType.slaughterhouse;
    if (sourceType == 'C3') return LocationType.storage;
    return LocationType.farmer;
  }

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final batches = await _batchService.fetchPendingBatches();
      if (mounted) {
        setState(() {
          _batches = batches;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = error.toString();
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
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  Future<void> _callSeller(String? phone) async {
    final sanitized = (phone ?? '').trim();
    if (sanitized.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller phone is unavailable')),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: sanitized);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _algeriaCenter,
              initialZoom: _algeriaOverviewZoom,
              onTap: (_, __) => setState(() => _selectedBatch = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nasij',
              ),
              MarkerLayer(
                markers: _batches
                    .where(
                      (b) => b.locationLat != null && b.locationLng != null,
                    )
                    .map((batch) {
                      final location = LatLng(
                        batch.locationLat!,
                        batch.locationLng!,
                      );
                      final locType = _mapSourceType(batch.sourceType);
                      return Marker(
                        point: location,
                        width: 64,
                        height: 64,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedBatch = batch);
                            _mapController.move(
                              location,
                              _mapController.camera.zoom,
                            );
                          },
                          child: _PulsingMarker(icon: locType.icon),
                        ),
                      );
                    })
                    .toList(),
              ),
            ],
          ),

          // ── Top overlay ──────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NassajPageHeader(
                        title: l10n.tr('map_title'),
                        icon: Icons.blur_on,
                      ),
                      NassajFloatingIconButton(
                        icon: Icons.refresh,
                        onTap: _loadBatches,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: NassajSearchBar(hintText: l10n.tr('map_search_hint')),
                ),
              ],
            ),
          ),

          // ── Map controls ─────────────────────────────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 80,
            child: Column(
              children: [
                NassajFloatingIconButton(
                  icon: Icons.my_location,
                  onTap: () =>
                      _mapController.move(_algeriaCenter, _algeriaOverviewZoom),
                ),
                const SizedBox(height: 10),
                // Zoom controls
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderMedium),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: AppColors.textWhite),
                        onPressed: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        ),
                      ),
                      Container(
                        height: 1,
                        width: 32,
                        color: AppColors.borderSubtle,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove,
                          color: AppColors.textWhite,
                        ),
                        onPressed: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          if (!_isLoading && _loadError != null && _batches.isEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 120,
              child: NassajCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unable to load collector requests',
                      style: AppTextStyles.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: NassajButton(
                        label: 'Retry',
                        icon: Icons.refresh,
                        onPressed: _loadBatches,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Batch preview sheet ───────────────────────────
          if (_selectedBatch != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _buildBatchPreview(
                _selectedBatch!,
                l10n,
                _formatRelativeTime(_selectedBatch!),
              ),
            ),

          // ── Bottom nav ────────────────────────────────────
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MapBottomNavBar(currentIndex: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchPreview(
    Batch batch,
    AppLocalizations l10n,
    String timeLabel,
  ) {
    final locType = _mapSourceType(batch.sourceType);

    return NassajCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.borderMedium,
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          Row(
            children: [
              // Icon thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(locType.icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 6),
                    Text(batch.batchId, style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(batch.wilaya ?? '—', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          NassajDivider(),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '~1.2 km',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 40,
                child: NassajSecondaryButton(
                  label: l10n.tr('map_call'),
                  icon: Icons.call,
                  onPressed: () => _callSeller(batch.creatorPhone),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pulsing map marker ──────────────────────────────────────

class _PulsingMarker extends StatefulWidget {
  final IconData icon;
  const _PulsingMarker({required this.icon});

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Pulse ring
            Container(
              width: 48 + (24 * _controller.value),
              height: 48 + (24 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(
                  alpha: 0.5 * (1.0 - _controller.value),
                ),
              ),
            ),
            // Inner circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 18),
            ),
            // Arrow tip
            Positioned(
              bottom: -6,
              child: CustomPaint(
                painter: _TrianglePainter(color: AppColors.primary),
                size: const Size(12, 8),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
