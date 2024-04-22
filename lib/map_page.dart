import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geo_tagger/repositories/position_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'di.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<StatefulWidget> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final PositionRepository _positionRepository = getIt<PositionRepository>();

  Completer<GoogleMapController>? _mapController;
  CameraPosition? _currentCameraPosition;
  Set<Marker> _mapMarkers = {};
  LatLng _mapLocation = const LatLng(0, 0);

  Future<CameraPosition> _determineInitialPosition() async {
    if (_currentCameraPosition != null) {
      return _currentCameraPosition!;
    }

    LatLng latLang;
    try {
      final currentPosition = await _positionRepository.getCurrentPosition();
      latLang = LatLng(currentPosition.latitude, currentPosition.longitude);
    } catch (e) {
      latLang = const LatLng(0, 0);
    }

    final initialCameraPosition = CameraPosition(
      target: latLang,
      zoom: 14.4746,
    );

    _mapLocation = latLang;
    _currentCameraPosition = initialCameraPosition;
    _mapMarkers.add(
        Marker(markerId: const MarkerId("1"), position: latLang, alpha: 0.7));
    return initialCameraPosition;
  }

  @override
  Widget build(BuildContext context) {
    _mapController = Completer<GoogleMapController>();

    return FutureBuilder<CameraPosition>(
      future: _determineInitialPosition(),
      builder: (context, snapshot) {
        Widget? content;
        if (snapshot.hasData && snapshot.data != null) {
          content = Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                markers: _mapMarkers,
                myLocationButtonEnabled: true,
                initialCameraPosition: snapshot.data!,
                onMapCreated: (GoogleMapController controller) {
                  _mapController?.complete(controller);
                },
                onCameraMove: (position) => _currentCameraPosition = position,
                onTap: (argument) => setState(() {
                  _mapLocation = argument;
                  _mapMarkers = {
                    Marker(
                        markerId: const MarkerId("1"),
                        position: argument,
                        alpha: 0.7),
                  };
                }),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  color: Colors.transparent,
                  child: Material(
                    elevation: 1,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              "${_mapLocation.latitude}\n${_mapLocation.longitude}"),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(
                              Icons.verified,
                              size: 48,
                            ),
                            onPressed: () =>
                                Navigator.pop(context, _mapLocation),
                            color: Colors.orange,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          // ignore: prefer_const_constructors
          content = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning,
                  size: 82,
                  color: Colors.orange,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text("An error occurred: ${snapshot.error}"),
                ),
                MaterialButton(
                  onPressed: () => Navigator.pop(context),
                  color: Colors.white,
                  child: const Text("Close"),
                ),
              ],
            ),
          );
        } else {
          content = const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

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
              child: content,
            ),
          ),
        );
      },
    );
  }
}
