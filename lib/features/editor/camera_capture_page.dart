import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_colors.dart';

/// 应用内相机：不启动外部相机 Activity，避免魅族等 ROM 回收页面后
/// 拍照结果丢失、image_picker 一直停留在已激活状态。
class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _initializing = true;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw StateError(
          status.isPermanentlyDenied ? '相机权限已被关闭，请到系统设置开启' : '需要相机权限才能拍照',
        );
      }
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw StateError('没有找到可用的相机');
      await _start(_cameraIndex);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _start(int index) async {
    await _controller?.dispose();
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _cameraIndex = index;
      _initializing = false;
      _error = null;
    });
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (error) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('拍照失败：$error')));
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _capturing) return;
    setState(() => _initializing = true);
    try {
      await _start((_cameraIndex + 1) % _cameras.length);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null && controller.value.isInitialized)
              Center(child: CameraPreview(controller))
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onPrimary, fontSize: 14),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            Positioned(
              left: 12,
              top: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                tooltip: '关闭',
              ),
            ),
            if (_cameras.length > 1)
              Positioned(
                right: 12,
                top: 12,
                child: IconButton(
                  onPressed: _switchCamera,
                  icon: const Icon(Icons.cameraswitch_outlined),
                  color: Colors.white,
                  tooltip: '切换摄像头',
                ),
              ),
            if (_error == null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 34,
                child: Center(
                  child: GestureDetector(
                    onTap: _capturing ? null : _capture,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white24,
                      ),
                      child: _capturing
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                    ),
                  ),
                ),
              ),
            if (_initializing && _error == null)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 132,
                child: Center(
                  child: Text(
                    '相机启动中…',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
