import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'login.dart';

class GeofenceScreen extends StatefulWidget {
  @override
  _GeofenceScreenState createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  final MapController _mapController = MapController();
  LatLng? _dogLocation; // Real-time dog GPS location
  LatLng? _geofenceCenter; // Geofence center location
  double _radius = 150; // Geofence radius in meters
  double _zoom = 15.0; // Default map zoom level
  bool _isOutsideGeofence = false; // Flag if dog has breached geofence
  bool _isFirstTime = false; // Flag for first-time geofence creation
  String? _lastGeofenceStatus;
  bool _isDisposed = false; // Prevent setState after widget is disposed

  final Distance _distanceCalc = Distance();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _listenToDogLocation();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Fetch geofence details from Firebase
  void _fetchInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If not logged in, redirect to login screen
      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
      return;
    }

    final geofenceRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/dog/geofence',
    );
    // Load geofence details
    final snapshot = await geofenceRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      final lat = double.tryParse(data['lat'].toString());
      final lng = double.tryParse(data['lng'].toString());
      final radius = double.tryParse(data['radius'].toString());

      if (lat != null && lng != null) {
        _geofenceCenter = LatLng(lat, lng);
      }

      if (radius != null && radius >= 50 && radius <= 500) {
        _radius = radius;
      }
      // Check if dog's current location breaches the geofence
      if (_geofenceCenter != null && _dogLocation != null) {
        _checkGeofenceBreach(_dogLocation!);
      }
    } else {
      // First time using geofence
      _isFirstTime = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Long press on the map to set a geofence center'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      });
    }

    setState(() {});
  }

  // Listen to dog's real-time GPS updates from Firebase
  void _listenToDogLocation() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
      return;
    }

    final ref = FirebaseDatabase.instance.ref('users/${user.uid}/dog/location');

    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && data['lat'] != null && data['lng'] != null) {
        final lat = double.tryParse(data['lat'].toString());
        final lng = double.tryParse(data['lng'].toString());

        if (lat != null && lng != null) {
          final newLocation = LatLng(lat, lng);

          if (!_isDisposed) {
            setState(() {
              _dogLocation = newLocation;
            });
          }

          // Slight delay before moving map
          Future.delayed(Duration(milliseconds: 300), () {
            if (_dogLocation != null && !_isDisposed) {
              _mapController.move(_dogLocation!, _zoom);
            }
          });

          if (_geofenceCenter != null) {
            _checkGeofenceBreach(newLocation);
          }
        }
      }
    });
  }

  // Save geofence center and radius to Firebase
  Future<void> _saveGeofenceCenterAndRadius(LatLng center) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref('users/${user.uid}/dog/geofence');

    await ref.set({
      'lat': center.latitude,
      'lng': center.longitude,
      'radius': _radius,
    });

    setState(() {
      _geofenceCenter = center;
      _isFirstTime = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Geofence created successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Save updated radius value to Firebase
  Future<void> _saveRadius(double radius) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Redirect to login screen
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
      return;
    }

    final ref = FirebaseDatabase.instance.ref('users/${user.uid}/dog/geofence');
    await ref.update({'radius': _radius});
  }

  // Handle long-press to set or change geofence center
  void _onMapLongPress(TapPosition pos, LatLng latlng) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          _isFirstTime ? 'Set Geofence Center' : 'Change Geofence Center',
        ),
        content: Text(
          _isFirstTime
              ? 'Do you want to create your geofence here?'
              : 'Do you want to change the geofence center to this location?',
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Save'),
            onPressed: () {
              Navigator.pop(context);
              _saveGeofenceCenterAndRadius(latlng);
            },
          ),
        ],
      ),
    );
  }

  void _checkGeofenceBreach(LatLng currentLocation) async {
    if (_geofenceCenter == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final double distance = _distanceCalc.as(
      LengthUnit.Meter,
      _geofenceCenter!,
      currentLocation,
    );

    final breachRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/dog/geofenceBreaches',
    );
    final timestamp = DateTime.now().toIso8601String();

    // Dog exited geofence
    if (distance > _radius && _lastGeofenceStatus != 'outside') {
      _lastGeofenceStatus = 'outside';

      setState(() {
        _isOutsideGeofence = true;
      });

      await breachRef.push().set({
        'time': timestamp,
        'location': '${currentLocation.latitude}, ${currentLocation.longitude}',
        'status': 'breached',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚨 Dog is outside the safe area!'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 6),
        ),
      );
    }
    // Dog returned to geofence
    else if (distance <= _radius && _lastGeofenceStatus != 'inside') {
      _lastGeofenceStatus = 'inside';

      setState(() {
        _isOutsideGeofence = false;
      });

      await breachRef.push().set({
        'time': timestamp,
        'location': '${currentLocation.latitude}, ${currentLocation.longitude}',
        'status': 'returned',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Dog returned to the safe area!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dogLocation == null && _geofenceCenter == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Dog Location & Geofence")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final currentCenter = _geofenceCenter ?? _dogLocation;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[300],
        foregroundColor: Colors.white,
        title: Text("Dog Location & Geofence"),
        actions: [
    IconButton(
      icon: Icon(Icons.refresh),
      tooltip: 'Refresh Geofence',
      onPressed: () {
        _fetchInitialData();
         _listenToDogLocation();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔄 Refreshed geofence and dog location'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    ),
  ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Map area
              Expanded(
                child: currentCenter == null
                    ? Center(child: CircularProgressIndicator())
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: currentCenter,
                          initialZoom: _zoom,
                          onLongPress: _onMapLongPress,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.savindya.MobileApp',
                          ),

                          // Dog location marker
                          if (_dogLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _dogLocation!,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.pets,
                                    size: 30,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),

                          // Geofence circle
                          if (_geofenceCenter != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _geofenceCenter!,
                                  radius: _radius,
                                  useRadiusInMeter: true,
                                  color: _isOutsideGeofence
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.green.withOpacity(0.3),
                                  borderColor: _isOutsideGeofence
                                      ? Colors.red
                                      : Colors.green,
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),
                        ],
                      ),
              ),

              // Radius slider
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text("Geofence Radius: ${_radius.toInt()} meters"),
                    Slider(
                      min: 50,
                      max: 500,
                      divisions: 9,
                      value: _radius,
                      label: '${_radius.toInt()} m',
                      onChanged: (value) {
                        setState(() {
                          _radius = value;
                        });
                        _saveRadius(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Zoom Buttons
          Positioned(
            bottom: 140,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoomIn",
                  mini: true,
                  onPressed: () {
                    if (_dogLocation != null) {
                      setState(() {
                        _zoom += 1;
                        _mapController.move(_dogLocation!, _zoom);
                      });
                    }
                  },
                  child: Icon(Icons.zoom_in),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  mini: true,
                  onPressed: () {
                    if (_dogLocation != null) {
                      setState(() {
                        _zoom -= 1;
                        _mapController.move(_dogLocation!, _zoom);
                      });
                    }
                  },
                  child: Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
