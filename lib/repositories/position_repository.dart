import 'package:geolocator/geolocator.dart';

class PositionRepository {
  Future<bool> locationCanBeFetched() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return [LocationPermission.always, LocationPermission.whileInUse].contains(permission) && enabled;
  }

  Future<Position> getCurrentPosition() async {
    if (!await locationCanBeFetched()) {
      throw("Location cannot be accessed.");
    }

    final position = await Geolocator.getCurrentPosition();
    return position;
  }
}