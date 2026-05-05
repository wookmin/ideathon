import 'dart:async';
import 'dart:io';

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
  bool _autoMode = false;
  bool _autoCapturing = false;
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
      _autoMode = false;
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

    var cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      cameraStatus = await Permission.camera.request();
    }
    if (!cameraStatus.isGranted) {
      if (mounted) {
        setState(() {
          _cameraError = '카메라 권한이 필요합니다.';
          _statusText = cameraStatus.isPermanentlyDenied
              ? '카메라 권한이 차단되었습니다. 설정에서 허용해 주세요.'
              : '카메라 권한이 허용되지 않았습니다.';
        });
      }
      return;
    }

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
        ResolutionPreset.medium,
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
        _statusText = '가이드에 맞춰 영수증을 비춰 주세요';
      });
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
      _autoMode = false;
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
            _statusText = '가이드에 맞춰 영수증을 비춰 주세요';
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
      _autoMode = false;
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
            _statusText = '가이드에 맞춰 영수증을 비춰 주세요';
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

  void _toggleAutoMode() {
    if (_cameraController == null || !_cameraReady || _busy) {
      if (mounted && !_busy) {
        setState(() {
          _statusText = '카메라 준비 후 자동 모드를 사용할 수 있습니다.';
        });
      }
      return;
    }
    final next = !_autoMode;
    setState(() {
      _autoMode = next;
      _statusText = next
          ? '자동 모드: 텍스트가 읽히면 자동 촬영합니다.'
          : '가이드에 맞춰 영수증을 비춰 주세요';
    });
    if (next) {
      unawaited(_runAutoCaptureLoop());
    }
  }

  Future<void> _runAutoCaptureLoop() async {
    if (_autoCapturing) {
      return;
    }
    _autoCapturing = true;
    try {
      while (mounted && _autoMode) {
        if (_busy || !_cameraReady || _cameraController == null) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          continue;
        }

        setState(() => _statusText = '자동 모드: 영수증 텍스트 확인 중...');
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (!mounted || !_autoMode || _busy) {
          continue;
        }

        try {
          final image = await _cameraController!.takePicture();
          final text = await _ocrService.extractText(image.path);
          if (!_looksLikeReceipt(text)) {
            if (mounted && _autoMode) {
              setState(() => _statusText = '자동 모드: 합계/통화를 다시 찾는 중...');
            }
            await _deleteIfPossible(image.path);
            continue;
          }

          if (!mounted) {
            return;
          }
          setState(() {
            _busy = true;
            _autoMode = false;
            _statusText = '영수증을 감지해 자동 촬영했습니다.';
          });
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReceiptScreen(imagePath: image.path, ocrText: text),
            ),
          );
          if (!mounted) {
            return;
          }
          setState(() {
            _busy = false;
            _statusText = '가이드에 맞춰 영수증을 비춰 주세요';
          });
        } catch (_) {
          if (mounted && _autoMode) {
            setState(() => _statusText = '자동 모드: 다시 시도하는 중...');
          }
        }
      }
    } finally {
      _autoCapturing = false;
    }
  }

  bool _looksLikeReceipt(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.length < 24) {
      return false;
    }
    final lineCount = normalized
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;
    if (lineCount < 3) {
      return false;
    }
    final hasAmountHint = RegExp(
      r'(합계|총액|금액|total|subtotal|amount|원|krw|usd|jpy|eur|thb|vnd)',
      caseSensitive: false,
    ).hasMatch(normalized);
    final hasNumber = RegExp(r'\d').hasMatch(normalized);
    return hasAmountHint && hasNumber;
  }

  Future<void> _deleteIfPossible(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
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
                padding: AppTheme.screenPadding.copyWith(top: 8, bottom: 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF111B6D), Color(0xFF232A7A), Color(0xFF111B6D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                        child: Row(
                          children: [
                            _CircleAction(
                              icon: Icons.close_rounded,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                            const Spacer(),
                            _CircleAction(
                              icon: _autoMode ? Icons.auto_awesome : Icons.bolt_outlined,
                              onTap: _toggleAutoMode,
                              highlighted: _autoMode,
                            ),
                          ],
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
                      const SizedBox(height: 18),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: _buildPreview(context, isReady),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ManualEntryScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('직접 입력하기'),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                        child: Row(
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
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 3),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 68,
                                    height: 68,
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
                              icon: _autoMode ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                              label: '자동',
                              onTap: _busy ? null : _toggleAutoMode,
                              highlighted: _autoMode,
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
            borderRadius: BorderRadius.circular(24),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF19A7FF), width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: child,
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: highlighted ? Colors.white : Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: highlighted ? AppTheme.primaryStrong : Colors.white,
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = highlighted ? Colors.white : Colors.white12;
    final iconColor = highlighted ? AppTheme.primaryStrong : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Ink(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 8),
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
