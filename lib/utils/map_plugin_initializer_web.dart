import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';

void initializeMapPlugin() {
  GoogleMapsFlutterPlatform.instance = GoogleMapsPlugin();
}
