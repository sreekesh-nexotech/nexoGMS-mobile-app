import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart'; //fix
import 'dart:developer' as developer; // For debug logging
import 'Cache_Manager.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const bool isProduction = false;
 // static const String localBaseUrl = 'http://10.147.18.122:7000';
  static const String localBaseUrl = 'https://nexogms.online/flutter/api';
  static const String productionBaseUrl = 'https://your-production-api.com';
  static const Duration requestTimeout = Duration(seconds: 30);
  
  final Logger _logger = Logger();
  String get baseUrl => isProduction ? productionBaseUrl : localBaseUrl;


  // Main request methods
  Future<http.Response> authenticatedGet(String endpoint,{
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _makeRequest(
      'GET', 
      endpoint,
      //body: null,  //fix
      headers: headers,
      queryParameters: queryParameters,
    );
  }

  Future<http.Response> authenticatedPost(
    String endpoint,{
    dynamic body,    
    Map<String, String>? headers,
  }) async {
    return _makeRequest(
      'POST',
      endpoint,
      body: body,
      headers: headers,
    );
  }

  Future<http.Response> authenticatedPut(String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    return _makeRequest(
      'PUT',
      endpoint,
      body: body,
      headers: headers,
    );
  }

  // Unified request handler
  Future<http.Response> _makeRequest(
    
    String method,
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final token = await _getAccessToken();
      final uri = Uri.parse('$baseUrl/$endpoint').replace(
        queryParameters: queryParameters?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
      developer.log('Making $method request to $uri', name: 'ApiService');
    developer.log('Headers: ${headers ?? {}}', name: 'ApiService');
    if (body != null) {
      developer.log('Body: ${body is String ? body : jsonEncode(body)}', 
          name: 'ApiService');
    }

_logger.i('API Request: $method ${uri.toString()}');

      // Execute request with timeout
      final response = await _executeRequest(
        method,
        uri,
        token: token,
        body: body,
        headers: headers,
      ).timeout(requestTimeout);//fix

_logger.i('API Response (${response.statusCode}): ${response.body}');

      // Handle token expiration
      if (response.statusCode == 401) {
        final newToken = await _refreshToken();
        if (newToken != null) {
          return await _executeRequest(
            method,
            uri,
            token: newToken,
            body: body,
            headers: headers,
          );
        }
        throw ApiException('Session expired. Please login again.', 401);
      }

      // Check for other errors
      if (response.statusCode >= 400) {
        throw ApiException(
          _parseError(response),
          response.statusCode,
        );
      }

      return response;
    } on TimeoutException {
      throw ApiException('Connection timeout. Please try again.', 408);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', 503);
    } catch (e) {
      _logger.e('Request failed', error: e);   //fix
      throw ApiException('Service unavailable. Please try again.', 500);
    }
  }

  Future<http.Response> _executeRequest(
    String method,
    Uri uri, {
    required String? token,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers, // Merge additional headers
    };

    switch (method) {
      case 'GET':
        return await http.get(uri, headers: requestHeaders);
      case 'POST':
        return await http.post(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      default:
        throw ApiException('Unsupported HTTP method', 400);
    }
  }

  // Token management
  Future<String?> _getAccessToken() async {
    try {
      final authBox = await Hive.openBox('auth');
      return authBox.get('access_token');
    } catch (e) {
      throw ApiException('Failed to access token', 500);
    }
  }

  Future<String?> _refreshToken() async {
    try {
      final authBox = await Hive.openBox('auth');
      final refreshToken = authBox.get('refresh_token');
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Authorization': 'Bearer $refreshToken'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await authBox.putAll({
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
        });
        return data['access_token'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper methods
  String _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['error'] ?? body['message'] ?? response.reasonPhrase ?? 'Unknown error';
    } catch (e) {
      return response.reasonPhrase ?? 'Unknown error (invalid response)';
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await authenticatedPost('/auth/logout', body: {});
      //final authBox = await Hive.openBox('auth');
      //await authBox.clear();
    } catch (e) {
      debugPrint('Non-critical: Logout API call failed: $e');
    }
      finally {
    // Always clear local data
    await CacheManager.clearAllCache();
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status $statusCode)';
}