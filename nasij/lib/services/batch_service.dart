import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/offline_storage.dart';
import '../models/batch.dart';
import 'api_service.dart';

class BatchService {
  static const Duration _requestTimeout = Duration(seconds: 30);

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    return Uri.parse(
      '${ApiService.configuredBaseUrl}$path',
    ).replace(queryParameters: queryParameters);
  }

  String? _accessToken() {
    final session = OfflineStorage().getSession();
    final token = session?['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Map<String, String> _jsonHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (includeAuth) {
      final token = _accessToken();
      if (token != null) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> _get(Uri uri, {bool includeAuth = true}) async {
    return http
        .get(uri, headers: _jsonHeaders(includeAuth: includeAuth))
        .timeout(_requestTimeout);
  }

  Future<http.Response> _post(
    Uri uri, {
    required Map<String, dynamic> body,
    bool includeAuth = true,
  }) async {
    return http
        .post(
          uri,
          headers: _jsonHeaders(includeAuth: includeAuth),
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);
  }

  Future<http.Response> _patch(
    Uri uri, {
    required Map<String, dynamic> body,
    bool includeAuth = true,
  }) async {
    return http
        .patch(
          uri,
          headers: _jsonHeaders(includeAuth: includeAuth),
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);
  }

  String _errorMessage(http.Response response, {required String fallback}) {
    final raw = response.body.trim();
    if (raw.isEmpty) {
      return fallback;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'] ?? decoded['message'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {}
    return fallback;
  }

  List<dynamic> _decodeList(
    http.Response response, {
    required String fallback,
  }) {
    final raw = response.body.trim();
    if (response.statusCode >= 400) {
      throw ApiException(
        _errorMessage(response, fallback: fallback),
        statusCode: response.statusCode,
      );
    }
    if (raw.isEmpty) {
      return <dynamic>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw ApiException('Unexpected server response');
    }
    return decoded;
  }

  Map<String, dynamic> _decodeMap(
    http.Response response, {
    required String fallback,
  }) {
    final raw = response.body.trim();
    if (response.statusCode >= 400) {
      throw ApiException(
        _errorMessage(response, fallback: fallback),
        statusCode: response.statusCode,
      );
    }
    if (raw.isEmpty) {
      throw ApiException('Unexpected server response');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Unexpected server response');
    }
    return decoded;
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _currentUserId() {
    final session = OfflineStorage().getSession();
    final userId = session?['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }

  Future<List<Batch>> fetchBatches({
    String? status,
    String? wilaya,
    String? collectorId,
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (wilaya != null && wilaya.isNotEmpty) {
      queryParams['wilaya'] = wilaya;
    }
    if (collectorId != null && collectorId.isNotEmpty) {
      queryParams['collector_id'] = collectorId;
    }

    final response = await _get(
      _uri(
        '/batches',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      ),
    );
    final items = _decodeList(response, fallback: 'Failed to load batches');
    return items
        .map((item) => Batch.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Batch?> fetchCurrentCollectorLoad() async {
    final collectorId = _currentUserId();
    if (collectorId == null) {
      return null;
    }
    final loads = await fetchBatches(
      status: 'COLLECTED_BY_BUYER',
      collectorId: collectorId,
    );
    if (loads.isEmpty) {
      return null;
    }
    return loads.first;
  }

  Future<List<Batch>> fetchPendingBatches({String? wilaya}) async {
    final queryParams = <String, String>{};
    if (wilaya != null && wilaya.isNotEmpty) {
      queryParams['wilaya'] = wilaya;
    }

    final response = await _get(
      _uri(
        '/batches/pending',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      ),
    );
    final items = _decodeList(
      response,
      fallback: 'Failed to load pending batches',
    );
    return items
        .map((item) => Batch.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Batch> fetchBatch(String batchId) async {
    final response = await _get(_uri('/batches/$batchId'));
    final map = _decodeMap(response, fallback: 'Failed to load batch');
    return Batch.fromJson(map);
  }

  Future<Batch> collectBatch(String batchId, Map<String, dynamic> body) async {
    final purchasePrice = _asDouble(
      body['purchase_price_dzd'] ?? body['price_dzd'] ?? body['price'],
    );
    final weightRaw = _asDouble(
      body['weight_raw_e1_kg'] ?? body['raw_weight_kg'] ?? body['weight_kg'],
    );
    if (purchasePrice == null || weightRaw == null || weightRaw <= 0) {
      throw ApiException(
        'Missing required collection payload (price and weight are required)',
      );
    }

    final payload = <String, dynamic>{
      'purchase_price_dzd': purchasePrice,
      'weight_raw_e1_kg': weightRaw,
      if (_asInt(body['sacs_count']) != null)
        'sacs_count': _asInt(body['sacs_count']),
      if (_asInt(body['proprete_score']) != null)
        'proprete_score': _asInt(body['proprete_score']),
      if ((body['type_de_laine'] as String?)?.isNotEmpty == true)
        'type_de_laine': body['type_de_laine'],
      if ((body['collector_id'] as String?)?.isNotEmpty == true)
        'collector_id': body['collector_id'],
      if ((body['action_timestamp'] as String?)?.isNotEmpty == true)
        'action_timestamp': body['action_timestamp'],
    };

    final response = await _post(
      _uri('/batches/$batchId/collect'),
      body: payload,
    );
    final map = _decodeMap(response, fallback: 'Failed to collect batch');
    return Batch.fromJson(map);
  }

  Future<Batch> claimBatch(String batchId) async {
    final response = await _post(
      _uri('/batches/$batchId/claim'),
      body: <String, dynamic>{},
    );
    final map = _decodeMap(response, fallback: 'Failed to accept task');
    return Batch.fromJson(map);
  }

  Future<Batch> cancelClaim(String batchId) async {
    final response = await _post(
      _uri('/batches/$batchId/cancel-claim'),
      body: <String, dynamic>{},
    );
    final map = _decodeMap(response, fallback: 'Failed to cancel active load');
    return Batch.fromJson(map);
  }

  Future<Batch> d1Intake(String batchId, Map<String, dynamic> body) async {
    final receivedWeight = _asDouble(
      body['weight_received_d1_kg'] ??
          body['d1_weight'] ??
          body['weight_raw_e1_kg'] ??
          body['actual_weight_kg'],
    );
    if (receivedWeight == null || receivedWeight <= 0) {
      throw ApiException('Missing intake weight');
    }

    final payload = <String, dynamic>{
      'weight_received_d1_kg': receivedWeight,
      if ((body['stockage_zone'] as String?)?.isNotEmpty == true)
        'stockage_zone': body['stockage_zone'],
      if ((body['action_timestamp'] as String?)?.isNotEmpty == true)
        'action_timestamp': body['action_timestamp'],
    };

    final response = await _patch(
      _uri('/batches/$batchId/d1-intake'),
      body: payload,
    );
    final map = _decodeMap(response, fallback: 'Failed to record D1 intake');
    return Batch.fromJson(map);
  }

  Future<Batch> d1Clean(String batchId, Map<String, dynamic> body) async {
    final postCleanWeight = _asDouble(
      body['weight_after_handclean_kg'] ??
          body['post_cleaned_weight_kg'] ??
          body['post_cleaned_weight'] ??
          body['cleaned_weight_kg'],
    );
    if (postCleanWeight == null || postCleanWeight <= 0) {
      throw ApiException('Missing post-cleaning weight');
    }

    final payload = <String, dynamic>{
      'weight_after_handclean_kg': postCleanWeight,
      if (_asDouble(body['taux_matiere_vegetale_percent']) != null)
        'taux_matiere_vegetale_percent': _asDouble(
          body['taux_matiere_vegetale_percent'],
        ),
      if (_asDouble(body['temperature_tas_celsius']) != null)
        'temperature_tas_celsius': _asDouble(body['temperature_tas_celsius']),
      if ((body['classification'] as String?)?.isNotEmpty == true)
        'classification': body['classification'],
      if ((body['action_timestamp'] as String?)?.isNotEmpty == true)
        'action_timestamp': body['action_timestamp'],
    };

    final response = await _patch(
      _uri('/batches/$batchId/d1-clean'),
      body: payload,
    );
    final map = _decodeMap(response, fallback: 'Failed to record D1 cleaning');
    return Batch.fromJson(map);
  }

  Future<void> shipBatches(List<String> batchIds) async {
    for (final batchId in batchIds) {
      // Depot dispatch: mark as in-transit to washer (AT_D2_LAVAGE)
      // Does NOT call the /d2-wash endpoint — that is the washer's job.
      final response = await _patch(
        _uri('/batches/$batchId'),
        body: <String, dynamic>{
          'status': 'AT_D2_LAVAGE',
          'action_timestamp': DateTime.now().toIso8601String(),
        },
      );
      _decodeMap(response, fallback: 'Failed to ship batch $batchId');
    }
  }

  /// Washer receives a batch from D1 — marks it AT_D2_LAVAGE so it appears
  /// in the wash queue without starting the actual wash process.
  Future<Batch> washerReceive(String batchId) async {
    final response = await _patch(
      _uri('/batches/$batchId'),
      body: <String, dynamic>{
        'status': 'AT_D2_LAVAGE',
        'annex_metadata': {
          'washer_received_at': DateTime.now().toIso8601String(),
        },
        'action_timestamp': DateTime.now().toIso8601String(),
      },
    );
    final map = _decodeMap(response, fallback: 'Failed to receive batch at washer');
    return Batch.fromJson(map);
  }

  Future<Batch> d2Wash(String batchId, Map<String, dynamic> body) async {
    double? cleanWeight = _asDouble(
      body['weight_clean_d2_kg'] ??
          body['weight_clean_kg'] ??
          body['clean_weight_kg'],
    );

    if (cleanWeight == null || cleanWeight <= 0) {
      final batch = await fetchBatch(batchId);
      cleanWeight = batch.weightAfterHandcleanKg ?? batch.weightRawE1Kg;
    }
    if (cleanWeight == null || cleanWeight <= 0) {
      throw ApiException('Missing clean weight for D2 wash');
    }

    String? finalDestination = body['final_destination'] as String?;
    final classification = (body['classification'] as String?)?.toUpperCase();
    if (finalDestination == null || finalDestination.isEmpty) {
      if (classification == 'D4') {
        finalDestination = 'D4_ENGRAIS';
      } else if (classification == 'D3') {
        finalDestination = 'D3_TEXTILES';
      } else {
        finalDestination = 'D3_TEXTILES';
      }
    }

    final payload = <String, dynamic>{
      'weight_clean_d2_kg': cleanWeight,
      'final_destination': finalDestination,
      if (_asDouble(body['humidite_sortie_percent']) != null)
        'humidite_sortie_percent': _asDouble(body['humidite_sortie_percent']),
      if (_asDouble(body['ph_laine']) != null)
        'ph_laine': _asDouble(body['ph_laine']),
      if (_asDouble(body['water_temp_celsius']) != null)
        'water_temp_celsius': _asDouble(body['water_temp_celsius']),
      if ((body['detergent_type'] as String?)?.isNotEmpty == true)
        'detergent_type': body['detergent_type'],
      if ((body['action_timestamp'] as String?)?.isNotEmpty == true)
        'action_timestamp': body['action_timestamp'],
    };

    final response = await _patch(
      _uri('/batches/$batchId/d2-wash'),
      body: payload,
    );
    final map = _decodeMap(response, fallback: 'Failed to record D2 wash');
    return Batch.fromJson(map);
  }

  Future<Batch> transformIntake(String batchId, Map<String, dynamic> body) async {
    final response = await _patch(
      _uri('/batches/$batchId/transform-intake'),
      body: body,
    );
    final map = _decodeMap(response, fallback: 'Failed to record transform intake');
    return Batch.fromJson(map);
  }

  Future<Batch> transform(String batchId, Map<String, dynamic> body) async {
    final productType = (body['product_type'] as String?)?.trim();
    if (productType == null || productType.isEmpty) {
      throw ApiException('Missing product_type');
    }

    final payload = <String, dynamic>{
      'product_type': productType,
      if (_asDouble(body['fiber_length_mm']) != null)
        'fiber_length_mm': _asDouble(body['fiber_length_mm']),
      if (_asDouble(body['finesse_micron']) != null)
        'finesse_micron': _asDouble(body['finesse_micron']),
      if (_asDouble(body['humidity_percent']) != null)
        'humidity_percent': _asDouble(body['humidity_percent']),
      if (_asDouble(body['target_density_kg_m3']) != null)
        'target_density_kg_m3': _asDouble(body['target_density_kg_m3']),
      if (_asInt(body['total_units_produced']) != null)
        'total_units_produced': _asInt(body['total_units_produced']),
      if (_asDouble(body['total_finished_weight_kg']) != null)
        'total_finished_weight_kg': _asDouble(body['total_finished_weight_kg']),
      if ((body['action_timestamp'] as String?)?.isNotEmpty == true)
        'action_timestamp': body['action_timestamp'],
    };

    final response = await _patch(
      _uri('/batches/$batchId/transform'),
      body: payload,
    );
    final map = _decodeMap(response, fallback: 'Failed to record transform');
    return Batch.fromJson(map);
  }
}
