import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../cubits/auth_cubit.dart';
import '../data/offline_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();

  static String get configuredBaseUrl {
    final configuredBase = dotenv.env['MOBILE_API_BASE_URL']?.trim();
    return (configuredBase == null || configuredBase.isEmpty)
        ? 'http://10.0.2.2:8001/api'
        : configuredBase;
  }

  static Uri _uri(String path, {Map<String, String>? queryParameters}) {
    return Uri.parse(
      '$configuredBaseUrl$path',
    ).replace(queryParameters: queryParameters);
  }

  static String _supplierRoleValue(SupplierRole role) {
    switch (role) {
      case SupplierRole.farmer:
        return 'farmer';
      case SupplierRole.producer:
        return 'producer';
      case SupplierRole.slaughterhouse:
        return 'slaughterhouse';
    }
  }

  static Map<String, String> _jsonHeaders({String? bearerToken}) {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (bearerToken != null && bearerToken.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $bearerToken';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _decodeResponse(
    http.Response response,
  ) async {
    final raw = response.body.trim();
    dynamic data;
    try {
      data = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
    } on FormatException {
      throw ApiException('Unexpected server response');
    }
    if (response.statusCode >= 400) {
      final detail = data is Map<String, dynamic>
          ? (data['detail'] ?? data['message'])
          : null;
      throw ApiException(
        (detail is String && detail.isNotEmpty) ? detail : 'Request failed',
        statusCode: response.statusCode,
      );
    }
    if (data is! Map<String, dynamic>) {
      throw ApiException('Unexpected server response');
    }
    return data;
  }

  static ApiException mapTransportException(Object error) {
    if (error is ApiException) {
      return error;
    }
    if (error is TimeoutException) {
      return ApiException('auth_error_backend_timeout');
    }
    if (error is SocketException || error is http.ClientException) {
      return ApiException('auth_error_backend_unreachable');
    }
    if (error is FormatException) {
      return ApiException('auth_error_invalid_server_url');
    }
    return ApiException('auth_error_generic');
  }

  static Future<void> requestSupplierOtp({
    required String phone,
    required SupplierRole supplierRole,
    String? fullName,
    String? wilaya,
  }) async {
    final response = await http
        .post(
          _uri('/auth/supplier/request-otp'),
          headers: _jsonHeaders(),
          body: jsonEncode({
            'phone': phone.trim(),
            'supplier_role': _supplierRoleValue(supplierRole),
            'full_name': fullName ?? '',
            'wilaya': wilaya ?? '',
          }),
        )
        .timeout(const Duration(seconds: 30));
    try {
      await _decodeResponse(response);
    } catch (error) {
      throw mapTransportException(error);
    }
  }

  static Future<Map<String, dynamic>> verifySupplierOtp({
    required String phone,
    required SupplierRole supplierRole,
    required String otpCode,
    String? fullName,
    String? wilaya,
  }) async {
    final response = await http
        .post(
          _uri('/auth/supplier/verify-otp'),
          headers: _jsonHeaders(),
          body: jsonEncode({
            'phone': phone.trim(),
            'supplier_role': _supplierRoleValue(supplierRole),
            'otp_code': otpCode,
            'full_name': fullName ?? '',
            'wilaya': wilaya ?? '',
          }),
        )
        .timeout(const Duration(seconds: 30));
    try {
      return _decodeResponse(response);
    } catch (error) {
      throw mapTransportException(error);
    }
  }

  static Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function(String token) requestFn, {
    required String initialToken,
  }) async {
    final storage = OfflineStorage();
    final session = storage.getSession();
    var currentToken = session?['accessToken'] as String? ?? initialToken;

    var response = await requestFn(currentToken);
    if (response.statusCode == 401) {
      final refreshToken = session?['refreshToken'] as String?;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final refreshRes = await http
              .post(
                _uri('/auth/refresh'),
                headers: _jsonHeaders(),
                body: jsonEncode({'refresh_token': refreshToken}),
              )
              .timeout(const Duration(seconds: 30));

          if (refreshRes.statusCode == 200) {
            final raw = refreshRes.body.trim();
            final data = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
            final newAccessToken = data['access_token'] as String?;
            final newRefreshToken = data['refresh_token'] as String?;
            if (newAccessToken != null && newRefreshToken != null) {
              session!['accessToken'] = newAccessToken;
              session['refreshToken'] = newRefreshToken;
              await storage.saveSession(session);
              response = await requestFn(newAccessToken);
            }
          }
        } catch (_) {}
      }
    }
    return response;
  }

  static Future<Map<String, dynamic>> getSupplierProfile({
    required String accessToken,
  }) async {
    final response = await _authenticatedRequest(
      (token) => http
          .get(_uri('/suppliers/me'), headers: _jsonHeaders(bearerToken: token))
          .timeout(const Duration(seconds: 30)),
      initialToken: accessToken,
    );
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> createDeclaration({
    required String accessToken,
    int? quantityCount,
    double? quantityWeightKg,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _authenticatedRequest(
      (token) => http
          .post(
            _uri('/suppliers/declarations'),
            headers: _jsonHeaders(bearerToken: token),
            body: jsonEncode({
              if (quantityCount != null) 'quantity_count': quantityCount,
              if (quantityWeightKg != null)
                'quantity_weight_kg': quantityWeightKg,
              if (latitude != null) 'location_lat': latitude,
              if (longitude != null) 'location_lng': longitude,
            }),
          )
          .timeout(const Duration(seconds: 30)),
      initialToken: accessToken,
    );
    return _decodeResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getSupplierOperations({
    required String accessToken,
    required bool includeHistory,
  }) async {
    final response = await _authenticatedRequest(
      (token) => http
          .get(
            _uri(
              '/suppliers/operations',
              queryParameters: {'include_history': includeHistory.toString()},
            ),
            headers: _jsonHeaders(bearerToken: token),
          )
          .timeout(const Duration(seconds: 30)),
      initialToken: accessToken,
    );
    final raw = response.body.trim();
    final data = raw.isEmpty ? <dynamic>[] : jsonDecode(raw);
    if (response.statusCode >= 400) {
      final detail = data is Map<String, dynamic> ? data['detail'] : null;
      throw ApiException(
        detail is String && detail.isNotEmpty
            ? detail
            : 'Failed to load operations',
        statusCode: response.statusCode,
      );
    }
    if (data is! List) {
      throw ApiException('Unexpected operations response');
    }
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Future<Map<String, dynamic>> employeeLogin({
    required String phone,
    required String password,
  }) async {
    final response = await http
        .post(
          _uri('/auth/employee/login'),
          headers: _jsonHeaders(),
          body: jsonEncode({'phone': phone.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 30));
    try {
      return _decodeResponse(response);
    } catch (error) {
      throw mapTransportException(error);
    }
  }

  static Future<Map<String, dynamic>> cancelSupplierOperation({
    required String accessToken,
    required String operationId,
    required bool callConfirmed,
    String? reason,
  }) async {
    final response = await _authenticatedRequest(
      (token) => http
          .post(
            _uri('/suppliers/operations/$operationId/cancel'),
            headers: _jsonHeaders(bearerToken: token),
            body: jsonEncode({
              'reason': reason ?? '',
              'call_confirmed': callConfirmed,
            }),
          )
          .timeout(const Duration(seconds: 30)),
      initialToken: accessToken,
    );
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> claimCollectorBatch({
    required String accessToken,
    required String batchId,
  }) async {
    final response = await _authenticatedRequest(
      (token) => http
          .post(
            _uri('/batches/$batchId/claim'),
            headers: _jsonHeaders(bearerToken: token),
          )
          .timeout(const Duration(seconds: 30)),
      initialToken: accessToken,
    );
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> cancelCollectorBatchClaim({
    required String accessToken,
    required String batchId,
  }) async {
    final response = await _authenticatedRequest(
      (token) => http
          .post(
            _uri('/batches/$batchId/cancel-claim'),
            headers: _jsonHeaders(bearerToken: token),
          )
          .timeout(const Duration(seconds: 30)),
      initialToken: accessToken,
    );
    return _decodeResponse(response);
  }
}
