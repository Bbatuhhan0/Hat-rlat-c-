import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(
    41.0082,
    28.9784,
  ); // Default to Istanbul
  LatLng? _userLocation;
  StreamSubscription<Position>? _positionStream;
  String _currentAddress = 'Konum aranıyor...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineInitialPosition();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _determineInitialPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          _userLocation = LatLng(position.latitude, position.longitude);

          // Start continuous tracking for "aktif konum"
          _positionStream =
              Geolocator.getPositionStream(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.bestForNavigation,
                  distanceFilter: 10,
                ),
              ).listen((Position newPos) {
                if (mounted) {
                  setState(() {
                    _userLocation = LatLng(newPos.latitude, newPos.longitude);
                  });
                }
              });
        } catch (e) {
          // ignore
        }
      }
    }

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _currentPosition = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
    } else if (_userLocation != null) {
      _currentPosition = _userLocation!;
    }

    await _getAddressFromLatLng(_currentPosition);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    // Defer moving the map until it's built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(_currentPosition, 16.0);
      }
    });
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            List<String> addressParts = [];

            if (place.street != null && place.street!.isNotEmpty) {
              addressParts.add(place.street!);
            } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
              addressParts.add(place.thoroughfare!);
            }

            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              addressParts.add(place.subLocality!);
            }

            if (place.locality != null && place.locality!.isNotEmpty) {
              addressParts.add(place.locality!);
            } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
              addressParts.add(place.subAdministrativeArea!);
            }

            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
              addressParts.add(place.administrativeArea!);
            }

            // Remove duplicates automatically
            addressParts = addressParts.toSet().toList();

            _currentAddress = addressParts.join(', ');

            if (_currentAddress.isEmpty) {
              _currentAddress = "Bilinmeyen Konum";
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = 'Adres bulunamadı';
        });
      }
    }
  }

  void _moveToUserLocation() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 16.0);
      _currentPosition = _userLocation!;
      _getAddressFromLatLng(_userLocation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seç'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, {
                'latitude': _currentPosition.latitude,
                'longitude': _currentPosition.longitude,
                'address': _currentAddress,
              });
            },
            tooltip: 'Konumu Onayla',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_isLoading)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 16.0,
                onPositionChanged: (MapPosition position, bool hasGesture) {
                  if (position.center != null) {
                    _currentPosition = position.center!;
                  }
                },
                onMapEvent: (MapEvent event) {
                  if (event is MapEventMoveEnd) {
                    _getAddressFromLatLng(_currentPosition);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.hedef_takip',
                ),
                if (_userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _userLocation!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                          child: Center(
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Exact Center Pin Setup - Tips exactly align with Map Center
          if (!_isLoading)
            const IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: 50.0,
                  ), // Icon size is 50, pushing bottom 50 moves the visual tip exactly to the map center.
                  child: Icon(Icons.location_on, size: 50, color: Colors.red),
                ),
              ),
            ),

          // My Location Button
          if (!_isLoading)
            Positioned(
              bottom: 110,
              right: 20,
              child: FloatingActionButton(
                heroTag: "myLocation",
                backgroundColor: Colors.white,
                onPressed: _moveToUserLocation,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),

          // Address Card
          if (!_isLoading)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
