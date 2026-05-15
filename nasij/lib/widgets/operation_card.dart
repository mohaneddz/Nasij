import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../models/operation.dart';
import '../utils/app_theme.dart';

class OperationCard extends StatelessWidget {
  final Operation operation;
  final String statusLabel;
  final String quantityLabel;
  final String locationLabel;
  final String createdAtLabel;
  final String? collectorPhoneLabel;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const OperationCard({
    super.key,
    required this.operation,
    required this.statusLabel,
    required this.quantityLabel,
    required this.locationLabel,
    required this.createdAtLabel,
    this.collectorPhoneLabel,
    this.actionLabel,
    this.onActionTap,
  });

  Color get _statusColor {
    switch (operation.status) {
      case OperationStatus.pending:
        return Colors.orange;
      case OperationStatus.assigned:
        return Colors.green;
      case OperationStatus.cancelledPending:
      case OperationStatus.cancelledAssigned:
        return Colors.redAccent;
      case OperationStatus.completed:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero quantity block ─────────────────────────────
          _QuantityHero(operation: operation, statusLabel: statusLabel, statusColor: _statusColor),

          // ── Map thumbnail (if location exists) ─────────────
          if (operation.hasLocation)
            _MapThumbnail(lat: operation.locationLat!, lng: operation.locationLng!),

          // ── Details footer ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Short ID + date row
                Row(
                  children: [
                    Text(
                      operation.shortId,
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white38,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      createdAtLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                if (collectorPhoneLabel != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 13, color: Colors.white38),
                      const SizedBox(width: 6),
                      Text(
                        collectorPhoneLabel!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ],
                if (!operation.hasLocation) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_off_outlined, size: 13, color: Colors.white24),
                      const SizedBox(width: 6),
                      Text(
                        locationLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ],
                if (actionLabel != null && onActionTap != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onActionTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        actionLabel!,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero quantity display ─────────────────────────────────────────────────────

class _QuantityHero extends StatelessWidget {
  final Operation operation;
  final String statusLabel;
  final Color statusColor;

  const _QuantityHero({
    required this.operation,
    required this.statusLabel,
    required this.statusColor,
  });

  String get _value {
    if (operation.quantityCount != null && operation.quantityWeightKg != null) {
      return '${operation.quantityCount}';
    }
    if (operation.quantityCount != null) {
      return '${operation.quantityCount}';
    }
    if (operation.quantityWeightKg != null) {
      return operation.quantityWeightKg!.toStringAsFixed(1);
    }
    return '--';
  }

  String get _unit {
    if (operation.quantityWeightKg != null && operation.quantityCount == null) {
      return 'kg';
    }
    if (operation.quantityCount != null) return 'têtes';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.10),
            const Color(0xFF161E31),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _value,
                  style: GoogleFonts.inter(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  _unit,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor.withOpacity(0.7),
                  ),
                ),
                if (operation.quantityWeightKg != null &&
                    operation.quantityCount != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${operation.quantityWeightKg!.toStringAsFixed(1)} kg',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini flutter_map thumbnail ────────────────────────────────────────────────

class _MapThumbnail extends StatelessWidget {
  final double lat;
  final double lng;

  const _MapThumbnail({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);
    return SizedBox(
      height: 130,
      child: IgnorePointer(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 13,
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
                  width: 32,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 6),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
