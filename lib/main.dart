import 'package:flutter/cupertino.dart';
import 'package:native_exif/native_exif.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const GeoTagger());
}

class GeoTagger extends StatelessWidget {
  const GeoTagger({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoTagger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _picker = ImagePicker();
  String _result = "Tap to tag";
  bool _isLoading = false;

  Future<Position> _determinePosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw ('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw ('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _setLoadingState(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future _tagImage(BuildContext context) async {
    if (_isLoading) {
      return false;
    }

    _setLoadingState(true);

    final pickerImage =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);

    if (pickerImage == null) {
      _result = "Tap to tag";
      _setLoadingState(false);
      return;
    }

    Position? position;
    try {
      position = await _determinePosition();
    } catch (e) {
      debugPrint(e.toString());
      _result = "Error";
      _setLoadingState(false);
      return;
    }

    var exif = await Exif.fromPath(pickerImage.path);

    final lat = position.latitude;
    final long = position.longitude;

    await exif.writeAttributes({
      'GPSLatitude': lat,
      'GPSLatitudeRef': lat > 0 ? "N" : "S",
      'GPSLongitude': long,
      'GPSLongitudeRef': long > 0 ? "E" : "W"
    });

    await exif.close();

    _result = "Tagged to\n(${position.latitude}, ${position.longitude})";
    _setLoadingState(false);

    await Share.shareXFiles([XFile(pickerImage.path)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MaterialButton(
        onPressed: () async => await _tagImage(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Image.asset(
                    "assets/pin.png",
                    alignment: Alignment.center,
                    width: 82,
                  ),
                ),
                _isLoading
                    ? const SizedBox(
                        height: 48,
                        width: 48,
                        child: CircularProgressIndicator(color: Colors.black),
                      )
                    : SizedBox(
                        height: 48,
                        child: Text(_result,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18)),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
