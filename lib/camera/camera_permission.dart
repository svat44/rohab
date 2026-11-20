import 'package:permission_handler/permission_handler.dart';

enum CameraAccess { granted, notAsked, denied }

/// Camera permission, behind an interface so tests can fake it.
abstract class CameraPermission {
  Future<CameraAccess> status();

  /// Shows the system prompt (iOS uses NSCameraUsageDescription).
  Future<CameraAccess> request();

  Future<void> openSettings();
}

class SystemCameraPermission implements CameraPermission {
  const SystemCameraPermission();

  @override
  Future<CameraAccess> status() async => _map(await Permission.camera.status);

  @override
  Future<CameraAccess> request() async =>
      _map(await Permission.camera.request());

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  static CameraAccess _map(PermissionStatus s) {
    if (s.isGranted || s.isLimited) return CameraAccess.granted;
    // Android reports "denied" before the first prompt as well; asking is
    // still allowed then. Permanently denied and restricted need Settings.
    if (s.isPermanentlyDenied || s.isRestricted) return CameraAccess.denied;
    return CameraAccess.notAsked;
  }
}

/// Always granted. Used where there is no real camera (web preview).
class GrantedCameraPermission implements CameraPermission {
  const GrantedCameraPermission();

  @override
  Future<CameraAccess> status() async => CameraAccess.granted;

  @override
  Future<CameraAccess> request() async => CameraAccess.granted;

  @override
  Future<void> openSettings() async {}
}
