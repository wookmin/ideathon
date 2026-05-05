import 'package:camera/camera.dart';

class CameraService {
  CameraService._();

  static List<CameraDescription> _cachedCameras = const [];

  static List<CameraDescription> get cachedCameras => _cachedCameras;

  static Future<void> warmUp() async {
    if (_cachedCameras.isNotEmpty) {
      return;
    }
    try {
      _cachedCameras = await availableCameras();
    } catch (_) {
      _cachedCameras = const [];
    }
  }

  static Future<List<CameraDescription>> getCameras() async {
    if (_cachedCameras.isNotEmpty) {
      return _cachedCameras;
    }
    _cachedCameras = await availableCameras();
    return _cachedCameras;
  }
}
