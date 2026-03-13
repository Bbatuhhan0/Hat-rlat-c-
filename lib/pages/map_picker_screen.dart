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
  String _currentAddress = 'Konum aranıyor...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineInitialPosition();
  }

  Future<void> _determineInitialPosition() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _currentPosition = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      await _getAddressFromLatLng(_currentPosition);
    } else {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled don't continue
      } else {
        permission = await Geolocator.checkPermission();
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
            _currentPosition = LatLng(position.latitude, position.longitude);
          } catch (e) {
            // handle error
          }
        }
      }
      await _getAddressFromLatLng(_currentPosition);
    }

    setState(() {
      _isLoading = false;
    });

    // Defer moving the map until it's built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_currentPosition, 15.0);
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
        setState(() {
          _currentAddress =
              '${place.street}, ${place.subLocality}, ${place.locality}';
          // Clean up empty strings and extra commas
          _currentAddress = _currentAddress
              .replaceAll(RegExp(r',\s*,'), ',')
              .trim();
          if (_currentAddress.startsWith(',')) {
            _currentAddress = _currentAddress.substring(1).trim();
          }
          if (_currentAddress.endsWith(',')) {
            _currentAddress = _currentAddress
                .substring(0, _currentAddress.length - 1)
                .trim();
          }
          if (_currentAddress.isEmpty) {
            _currentAddress = "Bilinmeyen Konum";
          }
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Adres bulunamadı';
      });
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
                initialZoom: 15.0,
                onPositionChanged: (MapPosition position, bool hasGesture) {
                  if (position.center != null) {
                    _currentPosition = position.center!;
                  }
                },
                // Fetch address only when map stops moving to avoid rate limits
                onMapEvent: (MapEvent event) {
                  if (event is MapEventMoveEnd) {
                    _getAddressFromLatLng(_currentPosition);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.example.hedef_takip', // Replace with your app's actual package name
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Center Pin
          if (!_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: 40.0,
                ), // Adjust to center the tip of the pin
                child: Icon(Icons.location_on, size: 50, color: Colors.red),
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
