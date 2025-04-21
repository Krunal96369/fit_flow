import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/local_storage_service.dart';

/// Provider for the permission service
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// Service for managing app permissions
class PermissionService {
  /// Save the list of permissions that have been requested
  Future<void> saveRequestedPermissions(Set<Permission> permissions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionValues = permissions.map((p) => p.value).toList();
      await prefs.setString(
        PreferenceKeys.permissionsRequested,
        jsonEncode(permissionValues),
      );
    } catch (e) {
      debugPrint('Error saving requested permissions: $e');
    }
  }

  /// Get the list of permissions that have been requested
  Future<Set<Permission>> getRequestedPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedList = prefs.getString(PreferenceKeys.permissionsRequested);

      if (encodedList == null) {
        return <Permission>{};
      }

      final List<dynamic> permissionValues = jsonDecode(encodedList);
      return permissionValues.map((v) => Permission.byValue(v)).toSet();
    } catch (e) {
      debugPrint('Error getting requested permissions: $e');
      return <Permission>{};
    }
  }

  /// Check if a specific permission is granted
  Future<bool> checkPermission(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Request a specific permission and save it to the list of requested permissions
  Future<bool> requestPermission(Permission permission) async {
    final status = await permission.request();

    if (status.isGranted) {
      final requestedPermissions = await getRequestedPermissions();
      await saveRequestedPermissions({...requestedPermissions, permission});
      return true;
    }

    return false;
  }

  /// Check if permissions have been requested during onboarding
  Future<bool> havePermissionsBeenRequested() async {
    final requestedPermissions = await getRequestedPermissions();
    return requestedPermissions.isNotEmpty;
  }

  /// Open app settings
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
