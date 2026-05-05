import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/theme.dart';
import '../services/camera_service.dart';
import '../services/ocr_service.dart';
import '../widgets/main_bottom_nav.dart';
import 'manual_entry_screen.dart';
import 'receipt_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _busy = false;
  String _statusText = '카메라를 준비하고 있습니다...';
  String? _cameraError;
  Future<void>? _cameraInitFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraInitFuture = _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) {
      return;
    }
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      unawaited(_disposeCamera());
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _cameraInitFuture = _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    await _disposeCamera();
    setState(() {
      _cameraReady = false;
      _cameraError = null;
      _statusText = '카메라를 준비하고 있습니다...';
    });

    try {
      final cameras = await CameraService.getCameras();
      final selected = cameras.where((camera) {
        return camera.lensDirection == CameraLensDirection.back;
      }).firstOrNull ??
          cameras.firstOrNull;

      if (selected == null) {
        throw Exception('사용 가능한 카메라가 없습니다.');
      }

      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      setState(() {
        _cameraReady = true;
        _statusText = '영수증을 가이드 라인에 맞춰 촬영해 주세요';
      });
    } on CameraException catch (error) {
      final cameraStatus = await Permission.camera.status;
      if (mounted) {
        setState(() {
          _cameraReady = false;
          _cameraError = '카메라를 열지 못했습니다.';
          _statusText = _cameraStatusMessage(
            permissionStatus: cameraStatus,
            errorCode: error.code,
            errorDescription: error.description,
          );
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _cameraReady = false;
          _cameraError = '카메라를 열지 못했습니다.';
          _statusText = error.toString();
        });
      }
    }
  }

  String _cameraStatusMessage({
    required PermissionStatus permissionStatus,
    required String errorCode,
    String? errorDescription,
  }) {
    if (permissionStatus.isPermanentlyDenied) {
      return '카메라 권한이 차단되었습니다. 설정에서 허용해 주세요.';
    }
    if (permissionStatus.isDenied || permissionStatus.isRestricted) {
      return '카메라 권한이 허용되지 않았습니다.';
    }
    if (errorCode.contains('CameraAccessDenied')) {
      return '카메라 접근이 거부되었습니다. iPhone 설정에서 권한을 다시 확인해 주세요.';
    }
    if (errorCode.contains('CameraAccessRestricted')) {
      return '이 기기에서는 카메라 접근이 제한되어 있습니다.';
    }
    if (errorCode.contains('CameraAccess')) {
      return '카메라 접근 오류가 발생했습니다. 설정 변경 후에는 flutter run으로 다시 연결해 주세요.';
    }
    return errorDescription?.trim().isNotEmpty == true
        ? errorDescription!
        : '카메라 초기화에 실패했습니다.';
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }

  Future<void> _handleGalleryPick() async {
    setState(() {
      _busy = true;
      _statusText = '갤러리 불러오는 중...';
    });
    try {
      var photosStatus = await Permission.photos.status;
      if (photosStatus.isDenied) {
        photosStatus = await Permission.photos.request();
      }
      if (!photosStatus.isGranted && !photosStatus.isLimited) {
        if (mounted) {
          setState(() {
            _statusText = photosStatus.isPermanentlyDenied
                ? '사진 접근 권한이 차단되었습니다. 설정에서 허용해 주세요.'
                : '사진 접근 권한이 필요합니다.';
          });
        }
        return;
      }
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null || !mounted) {
        return;
      }
      await _processImage(image.path);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          if (_cameraReady) {
            _statusText = '영수증을 가이드 라인에 맞춰 촬영해 주세요';
          }
        });
      }
    }
  }

  Future<void> _handleManualCapture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _busy) {
      if (mounted) {
        setState(() {
          _statusText = '카메라가 아직 준비되지 않았습니다.';
        });
      }
      return;
    }
    setState(() {
      _busy = true;
      _statusText = '영수증 촬영 중...';
    });
    try {
      final image = await _cameraController!.takePicture();
      if (!mounted) {
        return;
      }
      await _processImage(image.path);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          if (_cameraReady) {
            _statusText = '영수증을 가이드 라인에 맞춰 촬영해 주세요';
          }
        });
      }
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() => _statusText = 'OCR 텍스트 추출 중...');
    final text = await _ocrService.extractText(imagePath);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(imagePath: imagePath, ocrText: text),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeCamera());
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _cameraController != null && _cameraController!.value.isInitialized;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppTheme.screenPadding.copyWith(top: 14, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '영수증 스캔 / 직접 입력',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: AppTheme.screenPadding.copyWith(top: 4, bottom: 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF111B6D), Color(0xFF232A7A), Color(0xFF111B6D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _RoundIconButton(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusText,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (_cameraError != null) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _initializeCamera,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                  ),
                                  child: const Text('다시 시도'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: openAppSettings,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primaryStrong,
                                  ),
                                  child: const Text('설정 열기'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _buildPreview(context, isReady),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _BottomAction(
                              icon: Icons.image_rounded,
                              label: '갤러리',
                              onTap: _busy ? null : _handleGalleryPick,
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _busy ? null : _handleManualCapture,
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 4),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _busy ? Colors.white24 : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            _BottomAction(
                              icon: Icons.edit_note_rounded,
                              label: '직접 입력',
                              onTap: _busy
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ManualEntryScreen(),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const MainBottomNav(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, bool isReady) {
    if (_cameraError != null) {
      return _PreviewShell(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _cameraError!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!isReady) {
      return _PreviewShell(
        child: FutureBuilder<void>(
          future: _cameraInitFuture,
          builder: (context, snapshot) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          },
        ),
      );
    }

    return _PreviewShell(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: CameraPreview(_cameraController!),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GuideFramePainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewShell extends StatelessWidget {
  const _PreviewShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF19A7FF), width: 3.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: child,
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Ink(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 30.0;
    const strokeWidth = 4.0;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawLine(rect.topLeft, rect.topLeft.translate(cornerLength, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(0, cornerLength), paint);

    canvas.drawLine(rect.topRight, rect.topRight.translate(-cornerLength, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight.translate(0, cornerLength), paint);

    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(cornerLength, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(0, -cornerLength), paint);

    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(-cornerLength, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(0, -cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
