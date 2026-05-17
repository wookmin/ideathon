// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<(double, double)> getCurrentLatLng() async {
  final pos = await html.window.navigator.geolocation
      .getCurrentPosition(enableHighAccuracy: true);
  return (
    pos.coords!.latitude!.toDouble(),
    pos.coords!.longitude!.toDouble(),
  );
}
