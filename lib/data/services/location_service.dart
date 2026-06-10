import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position?> getCurrentPosition({bool requestIfNotGranted = false}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!requestIfNotGranted) return null;
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    try {
      // Coba dapatkan posisi terbaru dengan timeout 5 detik
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Jika timeout atau gagal, coba ambil lokasi terakhir yang diketahui
      return await Geolocator.getLastKnownPosition();
    }
  }

  // Stream posisi secara real-time
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}
