import 'dart:async';

import 'package:geo_tagger/di.dart';
import 'package:geo_tagger/map_page.dart';
import 'package:geo_tagger/repositories/position_repository.dart';
import 'package:native_exif/native_exif.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Future main() async {
  setupDependencies();
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
  final PositionRepository _positionRepository = getIt<PositionRepository>();
  final _picker = ImagePicker();

  bool _isLoading = false;

  late final Future<bool> _locationCanBeFetched = _positionRepository.locationCanBeFetched();

  void _setLoadingState(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future _tagImageToCurrentPosition() async {
    if (_isLoading) {
      return false;
    }

    _setLoadingState(true);

    final pickerImage =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);

    if (pickerImage == null) {
      _setLoadingState(false);
      return;
    }

    Position? position;
    try {
      position = await _positionRepository.getCurrentPosition();
    } catch (e) {
      debugPrint(e.toString());
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

    _setLoadingState(false);

    await Share.shareXFiles([XFile(pickerImage.path)]);
  }

  Future _tagImageToMapLocation() async {
    if (_isLoading) {
      return false;
    }

    _setLoadingState(true);

    var position = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => const MapPage(),
        transitionDuration: Duration.zero,
      ),
    );

    if (position == null) {
      _setLoadingState(false);
      return;
    }

    final pickerImage = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);

    if (pickerImage == null) {
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

    _setLoadingState(false);

    await Share.shareXFiles([XFile(pickerImage.path)]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/map_sepia.jpg"),
              opacity: 0.7,
              fit: BoxFit.cover,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Image.asset(
                      "assets/pin.png",
                      alignment: Alignment.center,
                      width: 82,
                    ),
                  ),
                  FutureBuilder<bool>(
                    future: _locationCanBeFetched,
                    builder: (context, snapshot) => MaterialButton(
                      onPressed: snapshot.data == true ? _tagImageToCurrentPosition : null,
                      color: Colors.white,
                      disabledColor: Colors.white,
                      disabledElevation: 1,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: const Row(
                        children: [
                          Icon(Icons.location_on),
                          SizedBox(width: 6),
                          Text(
                            "Use my position",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  MaterialButton(
                    onPressed: _tagImageToMapLocation,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: const Row(
                      children: [
                        Icon(Icons.map),
                        SizedBox(width: 6),
                        Text(
                          "Use map location",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
