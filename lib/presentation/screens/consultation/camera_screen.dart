import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:teguk/data/services/camera_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  bool _isInit = false;
  String? _capturedImagePath;
  bool _isCompressing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _cameraService.initialize();
    if (mounted) {
      setState(() {
        _isInit = _cameraService.isInitialized;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final path = await _cameraService.takePicture();
    if (path != null && mounted) {
      setState(() {
        _capturedImagePath = path;
      });
    }
  }

  Future<void> _switchCamera() async {
    setState(() => _isInit = false);
    await _cameraService.switchCamera();
    if (mounted) {
      setState(() => _isInit = true);
    }
  }

  Future<void> _sendPicture() async {
    if (_capturedImagePath == null) return;
    
    setState(() => _isCompressing = true);
    
    try {
      final file = File(_capturedImagePath!);
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 75,
      );
      
      if (compressedBytes != null && mounted) {
        final base64String = 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
        Navigator.pop(context, base64String);
      } else {
        if (mounted) {
          setState(() => _isCompressing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memproses gambar')),
          );
        }
      }
    } catch (e) {
      debugPrint('Compress error: $e');
      if (mounted) {
        setState(() => _isCompressing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memproses gambar')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _capturedImagePath == null
            ? _buildCameraPreview()
            : _buildImagePreview(),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: CameraPreview(_cameraService.controller!),
          ),
        ),
        Container(
          height: 120,
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 32),
                onPressed: _switchCamera,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Expanded(
          child: Image.file(
            File(_capturedImagePath!),
            fit: BoxFit.contain,
          ),
        ),
        Container(
          height: 120,
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() => _capturedImagePath = null);
                },
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text('Batal', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              ElevatedButton.icon(
                onPressed: _isCompressing ? null : _sendPicture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: _isCompressing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_isCompressing ? 'Memproses...' : 'Kirim'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
