import 'package:geolocator/geolocator.dart';

Future<(double, double)> getCurrentLatLng() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) throw Exception('Location service disabled');

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permanently denied');
  }

  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  return (position.latitude, position.longitude);
}
