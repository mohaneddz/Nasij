import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../cubits/auth_cubit.dart';
import '../cubits/sync_cubit.dart';
import '../data/offline_storage.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/toast_utils.dart';
import '../widgets/supplier_bottom_nav_bar.dart';

enum SupplierInputMode { countOnly, weightOnly, countOrWeight }

class SupplierDashboardScreen extends StatefulWidget {
  final SupplierRole role;

  const SupplierDashboardScreen({super.key, required this.role});

  @override
  State<SupplierDashboardScreen> createState() =>
      _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState extends State<SupplierDashboardScreen> {
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  bool _isSubmitting = false;
  static const _uuid = Uuid();

  SupplierInputMode get inputMode {
    switch (widget.role) {
      case SupplierRole.farmer:
        return SupplierInputMode.countOnly;
      case SupplierRole.producer:
        return SupplierInputMode.weightOnly;
      case SupplierRole.slaughterhouse:
        return SupplierInputMode.countOrWeight;
    }
  }

  String _descriptionKey() {
    switch (widget.role) {
      case SupplierRole.farmer:
        return 'supplier_ready_desc_farmer';
      case SupplierRole.producer:
        return 'supplier_ready_desc_producer';
      case SupplierRole.slaughterhouse:
        return 'supplier_ready_desc_slaughterhouse';
    }
  }

  String _roleTitleKey() {
    switch (widget.role) {
      case SupplierRole.farmer:
        return 'auth_role_farmer';
      case SupplierRole.producer:
        return 'auth_role_producer';
      case SupplierRole.slaughterhouse:
        return 'auth_role_slaughterhouse';
    }
  }

  IconData _roleIcon() {
    switch (widget.role) {
      case SupplierRole.farmer:
        return Icons.pets;
      case SupplierRole.producer:
        return Icons.factory_outlined;
      case SupplierRole.slaughterhouse:
        return Icons.content_cut;
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<(double?, double?)> _detectLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return (null, null);

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return (null, null);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return (position.latitude, position.longitude);
    } catch (_) {
      return (null, null);
    }
  }

  String _locationLabelKey() {
    switch (widget.role) {
      case SupplierRole.farmer:
        return 'supplier_location_farm';
      case SupplierRole.producer:
        return 'supplier_location_stock';
      case SupplierRole.slaughterhouse:
        return 'supplier_location_abattoir';
    }
  }

  /// Shows a BottomSheet with a live flutter_map preview and Share/Skip buttons.
  /// Returns true if the user accepted sharing location.
  Future<bool> _showLocationConfirmSheet(
    AppLocalizations l10n,
    double lat,
    double lng,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final point = LatLng(lat, lng);
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.55,
          decoration: const BoxDecoration(
            color: Color(0xFF161E31),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Colors.orange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.tr(_locationLabelKey()),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: point,
                      initialZoom: 14,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.nasij.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black45, blurRadius: 8),
                                ],
                              ),
                              child: const Icon(Icons.location_pin, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n.tr('common_skip'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.tr('common_share_location'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _declare(AppLocalizations l10n) async {
    final authState = context.read<AuthCubit>().state;
    final syncCubit = context.read<SyncCubit>();
    final count = int.tryParse(_countController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (inputMode == SupplierInputMode.countOnly && count == null) {
      ToastUtils.showError(context, l10n.tr('supplier_error_count_required'));
      return;
    }
    if (inputMode == SupplierInputMode.weightOnly && weight == null) {
      ToastUtils.showError(context, l10n.tr('supplier_error_weight_required'));
      return;
    }
    if (inputMode == SupplierInputMode.countOrWeight &&
        count == null &&
        weight == null) {
      ToastUtils.showError(
        context,
        l10n.tr('supplier_error_count_or_weight_required'),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Step 1: detect GPS silently
    final (rawLat, rawLng) = await _detectLocation();

    // Step 2: if location available, ask user to confirm
    double? latitude;
    double? longitude;
    if (rawLat != null && rawLng != null && mounted) {
      final shared = await _showLocationConfirmSheet(l10n, rawLat, rawLng);
      if (shared) {
        latitude = rawLat;
        longitude = rawLng;
      }
    }

    if (!mounted) return;

    try {
      final token = authState.accessToken;
      if (token == null || token.isEmpty) {
        throw ApiException('Missing supplier token');
      }
      await ApiService.createDeclaration(
        accessToken: token,
        quantityCount: count,
        quantityWeightKg: weight,
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      _countController.clear();
      _weightController.clear();
      ToastUtils.showSuccess(context, l10n.tr('supplier_declare_success'));
    } catch (_) {
      final localId = _uuid.v4();
      final payload = <String, dynamic>{
        if (count != null) 'quantity_count': count,
        if (weight != null) 'quantity_weight_kg': weight,
        if (latitude != null) 'location_lat': latitude,
        if (longitude != null) 'location_lng': longitude,
      };
      await OfflineStorage().saveDeclaration(localId, payload);
      await syncCubit.enqueueAction(
        table: 'supplier_declarations',
        actionType: 'insert',
        payload: payload,
      );
      if (!mounted) return;
      _countController.clear();
      _weightController.clear();
      ToastUtils.showWarning(
        context,
        l10n.tr('supplier_declare_saved_offline'),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurface,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: AppTheme.borderDark),
                                boxShadow: AppTheme.subtleShadow,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _roleIcon(),
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.tr(_roleTitleKey()),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.borderDark),
                                boxShadow: AppTheme.subtleShadow,
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.tr('supplier_ready'),
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
                          l10n.tr(_descriptionKey()),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _DeclarationCard(
                          inputMode: inputMode,
                          l10n: l10n,
                          countController: _countController,
                          weightController: _weightController,
                          isSubmitting: _isSubmitting,
                          onDeclare: () => _declare(l10n),
                        ),
                        const SizedBox(height: 24),
                      ],
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
            child: SupplierBottomNavBar(currentIndex: 0),
          ),
        ],
      ),
    );
  }
}

class _DeclarationCard extends StatelessWidget {
  final SupplierInputMode inputMode;
  final AppLocalizations l10n;
  final TextEditingController countController;
  final TextEditingController weightController;
  final bool isSubmitting;
  final VoidCallback onDeclare;

  const _DeclarationCard({
    required this.inputMode,
    required this.l10n,
    required this.countController,
    required this.weightController,
    required this.isSubmitting,
    required this.onDeclare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderDark),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inputMode == SupplierInputMode.countOnly)
            _buildInputField(
              icon: Icons.tag,
              hint: l10n.tr('supplier_input_count'),
              keyboardType: TextInputType.number,
              controller: countController,
            ),
          if (inputMode == SupplierInputMode.weightOnly)
            _buildInputField(
              icon: Icons.scale,
              hint: l10n.tr('supplier_input_weight'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              controller: weightController,
            ),
          if (inputMode == SupplierInputMode.countOrWeight) ...[
            _buildInputField(
              icon: Icons.tag,
              hint: l10n.tr('supplier_input_count'),
              keyboardType: TextInputType.number,
              controller: countController,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Divider(color: AppTheme.borderDark)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.tr('supplier_or_label'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppTheme.borderDark)),
              ],
            ),
            const SizedBox(height: 12),
            _buildInputField(
              icon: Icons.scale,
              hint: l10n.tr('supplier_input_weight'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              controller: weightController,
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.primaryGlow,
            ),
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onDeclare,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.tr('supplier_declare'),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String hint,
    required TextInputType keyboardType,
    required TextEditingController controller,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
