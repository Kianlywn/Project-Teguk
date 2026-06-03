import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Request all necessary permissions for the app (location, camera, notification).
  static Future<void> requestAllPermissions(BuildContext context) async {
    // Request permissions for location (weather/GPS), camera (chat), and notifications
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.notification,
    ].request();

    // Log the permission statuses
    statuses.forEach((permission, status) {
      debugPrint('${permission.toString()}: $status');
    });
  }
}