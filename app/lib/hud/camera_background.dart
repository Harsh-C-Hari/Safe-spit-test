import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../main.dart' show globalCameras;

class CameraBackground extends StatefulWidget {
  const CameraBackground({super.key});

  @override
  State<CameraBackground> createState() => _CameraBackgroundState();
}

class _CameraBackgroundState extends State<CameraBackground> {
  CameraController? _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (globalCameras.isEmpty) return;

    // Try to find the back camera
    CameraDescription? backCam;
    for (var cam in globalCameras) {
      if (cam.lensDirection == CameraLensDirection.back) {
        backCam = cam;
        break;
      }
    }
    backCam ??= globalCameras.first; // Fallback

    _controller = CameraController(
      backCam,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    } catch (e) {
      debugPrint('Camera exception: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null || !_controller!.value.isInitialized) {
      // Show black background if camera isn't ready
      return Container(color: Colors.black);
    }

    // Full screen camera preview
    final size = MediaQuery.of(context).size;
    final scale = size.aspectRatio * _controller!.value.aspectRatio;

    return Transform.scale(
      scale: scale < 1 ? 1 / scale : scale,
      child: Center(
        child: CameraPreview(_controller!),
      ),
    );
  }
}
