enum OperationStatus {
  pending,
  assigned,
  cancelledPending,
  cancelledAssigned,
  completed,
}

class Operation {
  final String id;
  final String statusRaw;
  final String supplierRole;
  final int? quantityCount;
  final double? quantityWeightKg;
  final double? locationLat;
  final double? locationLng;
  final String? collectorPhone;
  final String? cancelReason;
  final int trustPenaltyApplied;
  final int? trustScoreAfter;
  final DateTime? createdAt;
  final DateTime? cancelledAt;

  Operation({
    required this.id,
    required this.statusRaw,
    required this.supplierRole,
    this.quantityCount,
    this.quantityWeightKg,
    this.locationLat,
    this.locationLng,
    this.collectorPhone,
    this.cancelReason,
    this.trustPenaltyApplied = 0,
    this.trustScoreAfter,
    this.createdAt,
    this.cancelledAt,
  });

  OperationStatus get status {
    switch (statusRaw) {
      case 'ASSIGNED':
        return OperationStatus.assigned;
      case 'CANCELLED_PENDING':
        return OperationStatus.cancelledPending;
      case 'CANCELLED_ASSIGNED':
        return OperationStatus.cancelledAssigned;
      case 'COMPLETED':
        return OperationStatus.completed;
      case 'PENDING':
      default:
        return OperationStatus.pending;
    }
  }

  bool get isActive =>
      status == OperationStatus.pending || status == OperationStatus.assigned;

  bool get canCancelPending => status == OperationStatus.pending;

  bool get canCancelAssigned => status == OperationStatus.assigned;

  bool get hasLocation => locationLat != null && locationLng != null;

  /// Short human-readable ID: last 8 chars of UUID prefixed with #
  String get shortId => '#${id.length > 8 ? id.substring(id.length - 8) : id}';

  factory Operation.fromApi(Map<String, dynamic> map) {
    final locationLatRaw = map['location_lat'];
    final locationLngRaw = map['location_lng'];
    final locationLat = locationLatRaw is num
        ? locationLatRaw.toDouble()
        : double.tryParse('${locationLatRaw ?? ''}');
    final locationLng = locationLngRaw is num
        ? locationLngRaw.toDouble()
        : double.tryParse('${locationLngRaw ?? ''}');

    return Operation(
      id: map['id'] as String,
      statusRaw: (map['status'] as String?) ?? 'PENDING',
      supplierRole: (map['supplier_role'] as String?) ?? '',
      quantityCount: (map['quantity_count'] as num?)?.toInt(),
      quantityWeightKg: (map['quantity_weight_kg'] as num?)?.toDouble(),
      locationLat: locationLat,
      locationLng: locationLng,
      collectorPhone: map['collector_phone'] as String?,
      cancelReason: map['cancel_reason'] as String?,
      trustPenaltyApplied: (map['trust_penalty_applied'] as num?)?.toInt() ?? 0,
      trustScoreAfter: (map['trust_score_after'] as num?)?.toInt(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.tryParse(map['cancelled_at'] as String)
          : null,
    );
  }
}
