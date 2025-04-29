import 'package:hive/hive.dart';
import 'api_service.dart';
import 'dart:convert';

class ProfileService {
  static const _profileBox = 'profile_data';
  static const _lastSyncKey = 'last_profile_sync';
  static const _fieldTimestampsPrefix = 'field_ts_';
  
  /// Fetches profile with strict sync checking
  static Future<Map<String, dynamic>> getProfile({bool forceRefresh = false}) async {
    final box = await Hive.openBox(_profileBox);
    
    try {
      // Case 1: First visit after login or forced refresh
      if (forceRefresh || !box.containsKey('profile')) {
        return _fetchFullProfile(box);
      }

      // Case 2: Check if updates exist via changelog
      final lastSync = box.get(_lastSyncKey, defaultValue: '');
      if (lastSync.isEmpty) return box.get('profile');

      // First try lightweight sync check
      try {
        final hasChanges = await _checkForChanges(lastSync);
        if (!hasChanges) {
          return box.get('profile');
        }
      } catch (e) {
        // If sync check fails, proceed to full refresh
        print('Sync check failed, proceeding with full refresh: $e');
      }

      // Case 3: Changes detected - fetch fresh data
      return _fetchFullProfile(box);
    } catch (e) {
      // Fallback to cache if available
      if (box.containsKey('profile')) {
        return box.get('profile');
      }
      rethrow;
    }
  }

  /// Lightweight check for changes using sync endpoint
  static Future<bool> _checkForChanges(String lastSync) async {
    final response = await ApiService().authenticatedGet(
      'customer/profile/sync',
      queryParameters: {'last_sync': lastSync},
    );
    
    final data = jsonDecode(response.body);
    return data['sync_required'] ?? true;
  }

  /// Fetches complete profile data
  static Future<Map<String, dynamic>> _fetchFullProfile(Box box) async {
    final response = await ApiService().authenticatedGet('customer/profile');
    final data = Map<String, dynamic>.from(jsonDecode(response.body));
    
    await box.put('profile', data);
    await box.put(_lastSyncKey, DateTime.now().toIso8601String());
    
    // Clear field timestamps since we have fresh data
    await _clearFieldTimestamps(box);
    
    return data;
  }

  /// Updates profile with delta changes (kept your existing implementation)
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    final box = await Hive.openBox(_profileBox);
    final currentProfile = Map<String, dynamic>.from(box.get('profile', defaultValue: {}));

    final changedFields = _getChangedFields(currentProfile, updates);
    if (changedFields.isEmpty) return currentProfile;

    try {
      // Optimistic update
      final newProfile = {...currentProfile, ...updates};
      await box.put('profile', newProfile);

      final response = await ApiService().authenticatedPut(
        'customer/profile',
        body: {
          ..._extractChangedData(updates, changedFields),
          'fields': changedFields,
          'client_last_updated': currentProfile['last_updated_on'],
        },
      );

      final result = jsonDecode(response.body);
      if (!_isValidUpdateResponse(result)) {
        throw FormatException('Invalid server response format');
      }

      final updatedFields = (result['updated_fields'] as List<dynamic>).cast<String>();
      await _updateSyncMetadata(box, updatedFields);
      
      return {
        ...newProfile,
        'last_updated_on': result['last_updated_on'],
        '_synced_fields': updatedFields
      };
    } catch (e) {
      await box.put('profile', currentProfile);
      if (e is ConflictException) {
        await box.put(_lastSyncKey, DateTime.now().toIso8601String());
      }
      rethrow;
    }
  }

  // --- Helper Methods ---
  static List<String> _getChangedFields(Map<String, dynamic> oldData, Map<String, dynamic> newData) {
    return newData.keys
        .where((key) => oldData[key] != newData[key])
        .map((key) => key.toString())
        .toList();
  }

  static Map<String, dynamic> _extractChangedData(Map<String, dynamic> data, List<String> fields) {
    return fields.fold<Map<String, dynamic>>({}, (result, field) {
      return data.containsKey(field) ? {...result, field: data[field]} : result;
    });
  }

  static Future<void> _updateSyncMetadata(Box box, List<String> updatedFields) async {
    final now = DateTime.now().toIso8601String();
    await box.put(_lastSyncKey, now);
    await _updateFieldTimestamps(box, updatedFields);
  }

  static Future<void> _updateFieldTimestamps(Box box, List<String> fields) async {
    final now = DateTime.now().toIso8601String();
    for (final field in fields) {
      await box.put('$_fieldTimestampsPrefix$field', now);
    }
  }

  static Future<void> _clearFieldTimestamps(Box box) async {
    final keysToRemove = box.keys
        .where((k) => k.startsWith(_fieldTimestampsPrefix))
        .toList();
    
    for (final key in keysToRemove) {
      await box.delete(key);
    }
  }

  static bool _isValidUpdateResponse(Map<String, dynamic> response) {
    return response.containsKey('updated_fields') &&
           response['updated_fields'] is List &&
           response.containsKey('last_updated_on');
  }
}

class ConflictException implements Exception {
  final Map<String, dynamic> serverData;
  ConflictException(this.serverData);
} 