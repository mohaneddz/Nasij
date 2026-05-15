class Batch {
  final String batchId;
  final String? sourceType;
  final String? breed;
  final String? wilaya;
  final String? status;
  final String? creatorId;
  final String? creatorPhone;
  final String? creatorFullName;
  final String? collectorId;
  final String? collectorPhone;
  final String? collectorFullName;
  final double? purchasePriceDzd;
  final String? typeDeLaine;
  final int? propreteScore;
  final int? sacsCount;
  final double? weightRawE1Kg;
  final double? weightAfterHandcleanKg;
  final double? weightCleanD2Kg;
  final String? stockageZone;
  final String? classification;
  final double? temperatureTasCelsius;
  final double? tauxMatiereVegetalePercent;
  final double? humiditeSortiePercent;
  final double? phLaine;
  final double? fiberLengthMm;
  final double? finesseMicron;
  final double? humidityPercent;
  final String? finalDestination;
  final bool? isReadyForSale;
  final double? locationLat;
  final double? locationLng;
  final Map<String, dynamic>? annexMetadata;
  final double? wasteRemovedKg;
  final double? skinRemovedKg;
  final String? actionTimestamp;
  final String? syncedAt;
  final String? createdAt;

  // Convenience getters for step-specific weights
  double? get c1Weight => weightRawE1Kg;
  double? get d1Weight => weightAfterHandcleanKg;
  double? get d2Weight => weightCleanD2Kg;

  Batch({
    required this.batchId,
    this.sourceType,
    this.breed,
    this.wilaya,
    this.status,
    this.creatorId,
    this.creatorPhone,
    this.creatorFullName,
    this.collectorId,
    this.collectorPhone,
    this.collectorFullName,
    this.purchasePriceDzd,
    this.typeDeLaine,
    this.propreteScore,
    this.sacsCount,
    this.weightRawE1Kg,
    this.weightAfterHandcleanKg,
    this.weightCleanD2Kg,
    this.stockageZone,
    this.classification,
    this.temperatureTasCelsius,
    this.tauxMatiereVegetalePercent,
    this.humiditeSortiePercent,
    this.phLaine,
    this.fiberLengthMm,
    this.finesseMicron,
    this.humidityPercent,
    this.finalDestination,
    this.isReadyForSale,
    this.locationLat,
    this.locationLng,
    this.annexMetadata,
    this.wasteRemovedKg,
    this.skinRemovedKg,
    this.actionTimestamp,
    this.syncedAt,
    this.createdAt,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    final annex = json['annex_metadata'] as Map<String, dynamic>? ?? {};
    return Batch(
      batchId: json['batch_id'] as String,
      sourceType: json['source_type'] as String?,
      breed: json['breed'] as String?,
      wilaya: json['wilaya'] as String?,
      status: json['status'] as String?,
      creatorId: json['creator_id'] as String?,
      creatorPhone: json['creator_phone'] as String?,
      creatorFullName: json['creator_full_name'] as String?,
      collectorId: json['collector_id'] as String?,
      collectorPhone: json['collector_phone'] as String?,
      collectorFullName: json['collector_full_name'] as String?,
      purchasePriceDzd: (json['purchase_price_dzd'] as num?)?.toDouble(),
      typeDeLaine: json['type_de_laine'] as String?,
      propreteScore: json['proprete_score'] as int?,
      sacsCount: json['sacs_count'] as int?,
      weightRawE1Kg: (json['weight_raw_e1_kg'] as num?)?.toDouble(),
      weightAfterHandcleanKg: (json['weight_after_handclean_kg'] as num?)
          ?.toDouble(),
      weightCleanD2Kg: (json['weight_clean_d2_kg'] as num?)?.toDouble(),
      stockageZone: json['stockage_zone'] as String?,
      classification: json['classification'] as String?,
      temperatureTasCelsius: (json['temperature_tas_celsius'] as num?)
          ?.toDouble(),
      tauxMatiereVegetalePercent:
          (json['taux_matiere_vegetale_percent'] as num?)?.toDouble(),
      humiditeSortiePercent: (json['humidite_sortie_percent'] as num?)
          ?.toDouble(),
      phLaine: (json['ph_laine'] as num?)?.toDouble(),
      fiberLengthMm: (json['fiber_length_mm'] as num?)?.toDouble(),
      finesseMicron: (json['finesse_micron'] as num?)?.toDouble(),
      humidityPercent: (json['humidity_percent'] as num?)?.toDouble(),
      finalDestination: json['final_destination'] as String?,
      isReadyForSale: json['is_ready_for_sale'] as bool?,
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      annexMetadata: json['annex_metadata'] as Map<String, dynamic>?,
      // These are stored in annex_metadata since they are not top-level DB columns
      wasteRemovedKg: (json['waste_removed_kg'] as num?)?.toDouble()
          ?? (annex['waste_removed_kg'] as num?)?.toDouble(),
      skinRemovedKg: (json['skin_removed_kg'] as num?)?.toDouble()
          ?? (annex['skin_removed_kg'] as num?)?.toDouble(),
      actionTimestamp: json['action_timestamp'] as String?,
      syncedAt: json['synced_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_id': batchId,
      'source_type': sourceType,
      'breed': breed,
      'wilaya': wilaya,
      'status': status,
      'creator_id': creatorId,
      'creator_phone': creatorPhone,
      'creator_full_name': creatorFullName,
      'collector_id': collectorId,
      'collector_phone': collectorPhone,
      'collector_full_name': collectorFullName,
      'purchase_price_dzd': purchasePriceDzd,
      'type_de_laine': typeDeLaine,
      'proprete_score': propreteScore,
      'sacs_count': sacsCount,
      'weight_raw_e1_kg': weightRawE1Kg,
      'weight_after_handclean_kg': weightAfterHandcleanKg,
      'weight_clean_d2_kg': weightCleanD2Kg,
      'stockage_zone': stockageZone,
      'classification': classification,
      'temperature_tas_celsius': temperatureTasCelsius,
      'taux_matiere_vegetale_percent': tauxMatiereVegetalePercent,
      'humidite_sortie_percent': humiditeSortiePercent,
      'ph_laine': phLaine,
      'fiber_length_mm': fiberLengthMm,
      'finesse_micron': finesseMicron,
      'humidity_percent': humidityPercent,
      'final_destination': finalDestination,
      'is_ready_for_sale': isReadyForSale,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'annex_metadata': annexMetadata,
      'waste_removed_kg': wasteRemovedKg,
      'skin_removed_kg': skinRemovedKg,
      'action_timestamp': actionTimestamp,
      'synced_at': syncedAt,
      'created_at': createdAt,
    };
  }
}
