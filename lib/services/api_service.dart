import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
//import 'package:flutter/foundation.dart';

class ApiService {
  static const bool isProduction = true;
  static const String localBaseUrl = 'http://10.147.18.122:7000';
  static const String productionBaseUrl = 'https://nexogms.online/flutter/api';
 

  String get baseUrl => isProduction ? productionBaseUrl : localBaseUrl;

  Future<http.Response> authenticatedGet(String endpoint,
      {Map<String, String>? headers,
      Map<String, dynamic>? queryParameters}) async {
    return await _request('GET', endpoint,
        headers: headers, queryParameters: queryParameters);
  }

  Future<http.Response> authenticatedPost(String endpoint,
      {dynamic body, Map<String, String>? headers}) async {
    return await _request('POST', endpoint, body: body, headers: headers);
  }

  Future<http.Response> authenticatedPut(String endpoint,
      {dynamic body, Map<String, String>? headers}) async {
    return await _request('PUT', endpoint, body: body, headers: headers);
  }

  Future<http.Response> _request(String method, String endpoint,
      {dynamic body,
      Map<String, String>? headers,
      Map<String, dynamic>? queryParameters}) async {
    try {
      final token = await _getAccessToken();
      final uri = Uri.parse('$baseUrl/$endpoint').replace(
        queryParameters:
            queryParameters?.map((k, v) => MapEntry(k, v.toString())),
      );

      final response = await _sendRequest(
        method,
        uri,
        token: token,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 401) {
        print('⚠️ Access token expired. Attempting refresh...');
        final newToken = await _refreshToken();
        if (newToken != null) {
          return await _sendRequest(
            method,
            uri,
            token: newToken,
            headers: headers,
            body: body,
          );
        }
        throw Exception('Session expired');
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> _sendRequest(
    String method,
    Uri uri, {
    required String? token,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    switch (method) {
      case 'GET':
        return await http.get(uri, headers: requestHeaders);
      case 'POST':
        return await http.post(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body),
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body),
        );
      default:
        throw Exception('Unsupported HTTP method');
    }
  }

  Future<String?> _getAccessToken() async {
    final box = await Hive.openBox('auth');
    return box.get('access_token');
  }

  Future<String?> _refreshToken() async {
    final box = await Hive.openBox('auth');
    final refreshToken = box.get('refresh_token');
    if (refreshToken == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Authorization': 'Bearer $refreshToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await box.put('access_token', data['access_token']);
      await box.put('refresh_token', data['refresh_token']);
      return data['access_token'];
    }
    return null;
  }
}
