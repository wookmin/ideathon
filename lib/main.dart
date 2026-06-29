import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';

import 'config/theme.dart';
import 'models/receipt_analysis.dart';
import 'models/receipt_record.dart';
import 'models/travel.dart';
import 'providers/ledger_provider.dart';
import 'providers/travel_selection_provider.dart';
import 'providers/travel_provider.dart';
import 'screens/home_screen.dart';
import 'services/camera_service.dart';
import 'utils/map_plugin_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeMapPlugin();
  await initializeDateFormatting('ko');
  await CameraService.warmUp();

  await Hive.initFlutter();
  Hive
    ..registerAdapter(ReceiptItemAdapter())
    ..registerAdapter(ReceiptRecordAdapter())
    ..registerAdapter(TravelAdapter())
    ..registerAdapter(ReceiptAnalysisItemAdapter())
    ..registerAdapter(ReceiptAnalysisAdapter());

  await Hive.openBox<ReceiptRecord>(ledgerBoxName);
  await Hive.openBox<Travel>(travelBoxName);
  await Hive.openBox<String>(travelSelectionBoxName);

  runApp(const ProviderScope(child: TripReceiptApp()));
}

class TripReceiptApp extends StatelessWidget {
  const TripReceiptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JustAMoment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _AppBootstrapScreen(),
      scrollBehavior: const _NoGlowScrollBehavior(),
      builder: (context, child) {
        final clampedScaler = MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.2);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          ),
        );
      },
    );
  }
}

class _AppBootstrapScreen extends StatefulWidget {
  const _AppBootstrapScreen();

  @override
  State<_AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<_AppBootstrapScreen> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_requested) return;

    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preparePermissions();
    });
  }

  Future<void> _preparePermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;

      if (!cameraStatus.isGranted) {
        final next = await Permission.camera.request();
        if (next.isGranted) {
          await CameraService.warmUp();
        }
      } else {
        await CameraService.warmUp();
      }

      final photoStatus = await Permission.photos.status;
      if (!photoStatus.isGranted) {
        await Permission.photos.request();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
