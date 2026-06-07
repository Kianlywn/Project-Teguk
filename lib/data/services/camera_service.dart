import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  // Inisialisasi kamera
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      // Default pakai kamera belakang
      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      debugPrint('Camera init error: $e');
    }
  }

  // Ganti antara kamera depan & belakang
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    final currentLens = _controller?.description.lensDirection;
    CameraDescription newCamera = currentLens == CameraLensDirection.back
        ? _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => _cameras.first,
          )
        : _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => _cameras.first,
          );

    await _controller?.dispose();
    _controller = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
  }

  // Ambil foto → return path file
  Future<String?> takePicture() async {
    if (_controller == null || !_isInitialized) return null;
    if (!_controller!.value.isInitialized) return null;

    try {
      final XFile file = await _controller!.takePicture();
      return file.path;
    } catch (e) {
      debugPrint('Take picture error: $e');
      return null;
    }
  }

  // Dispose controller waktu screen ditutup
  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}
