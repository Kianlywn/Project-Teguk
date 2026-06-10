import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Request all necessary permissions for the app upfront.
  static Future<void> requestAllPermissions(BuildContext context) async {
    // Request permissions for:
    // - location: weather/GPS
    // - camera: chat photo
    // - notification: water reminders
    // - activityRecognition: pedometer/step counter
    // - scheduleExactAlarm: precise reminder scheduling (Android 12+)
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.activityRecognition,
      Permission.notification,
    ].request();

    // Log the permission statuses
    statuses.forEach((permission, status) {
      debugPrint('${permission.toString()}: $status');
    });
  }
}
