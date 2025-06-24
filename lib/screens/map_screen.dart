
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../service/addRating.dart';
import 'dart:async';
import '../service/cbfHaversine.dart';
import '../service/collaboratifBasedApi.dart';
import '../service/contentBasedApi.dart';
import 'components/card.dart';
import 'detail_screen.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart' as loc;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final Set<String> likedPlaces = {};
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  List<dynamic> _allPlaces = [];
  List<dynamic> _suggestions = [];
  dynamic _selectedPlace;
  List<dynamic> _recommendationList = [];
  bool _showRecommendations = false;
  String _currentRecommendationType = '';
  bool _isFabExpanded = false;
  bool _showRouteSelector = false;
  LatLng? _routeStartPoint;
  LatLng? _routeEndPoint;


  GoogleMapController? _mapController;
  Completer<GoogleMapController> _controller = Completer();


  bool _isLoading = false;

  // Tambahan untuk warna marker rekomendasi
  final double _cbfMarkerColor = BitmapDescriptor.hueOrange;
  final double _collaborativeMarkerColor = BitmapDescriptor.hueMagenta;
  final double _cbfHaversineMarkerColor = BitmapDescriptor.hueGreen;
  final double _defaultMarkerColor = BitmapDescriptor.hueAzure;

  BitmapDescriptor? _defaultIcon;
  BitmapDescriptor? _cbfIcon;
  BitmapDescriptor? _collaborativeIcon;
  BitmapDescriptor? _cbfHaversineIcon;

  // Tambahan variabel untuk polylines dan lokasi user
  Set<Polyline> _polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};
  LatLng? _userLocation;
  loc.LocationData? currentLocation;
  bool _routeVisible = false;
  LatLng? _startPoint;
  LatLng? _endPoint;

  // Pre-loaded recommendation data
  List<dynamic> _preloadedCBFRecommendations = [];
  List<dynamic> _preloadedCollaborativeRecommendations = [];
  bool _isLoadingRecommendations = true;
  bool _isRefreshing = false;

  // CBF + Haversine data
  List<dynamic> _cbfHaversineRecommendations = [];
  bool _isLoadingCBFHaversine = false;
  bool _hasCBFHaversineData = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Define colors for the theme
  final Color _primaryColor = const Color(0xFF009688); // Teal
  final Color _accentColor = const Color(0xFF4DB6AC); // Light Teal
  final Color _backgroundColor = Colors.white;
  final Color _textColor = const Color(0xFF263238); // Dark Blue Grey
  final Color _secondaryTextColor = const Color(0xFF607D8B); // Blue Grey


  @override
  void initState() {
    super.initState();
    _loadMarkersFromJson();
    _preloadRecommendations();

    _createMarkerIcons();



    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuint,
    ));

    // Start the animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Fungsi untuk membuat ikon marker yang berbeda
  void _createMarkerIcons() async {
    _defaultIcon = BitmapDescriptor.defaultMarkerWithHue(_defaultMarkerColor);
    _cbfIcon = BitmapDescriptor.defaultMarkerWithHue(_cbfMarkerColor);
    _collaborativeIcon = BitmapDescriptor.defaultMarkerWithHue(_collaborativeMarkerColor);
    _cbfHaversineIcon = BitmapDescriptor.defaultMarkerWithHue(_cbfHaversineMarkerColor);
  }


  // Fungsi untuk mendapatkan lokasi user
  Future<void> _getUserCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Izin lokasi ditolak.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Izin lokasi ditolak secara permanen. Harap ubah di pengaturan.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      // Validasi koordinat tidak null dan valid
      if (position.latitude.isFinite &&
          position.longitude.isFinite) {

        setState(() {
        });

        if (_userLocation != null) {
          setState(() {
            _markers.add(
              Marker(
                markerId: const MarkerId("user_location"),
                position: _userLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: const InfoWindow(title: "My Location"),
              ),
            );
          });

          // Validasi mapController sebelum digunakan
          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_userLocation!, 14.0),
            );
          } else {
            print("Map controller belum siap");
            // Coba lagi setelah delay
            Future.delayed(Duration(milliseconds: 500), () {
              if (mapController != null && _userLocation != null) {
                mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_userLocation!, 14.0),
                );
              }
            });
          }
        }
      } else {
        print("Koordinat tidak valid: lat=${position.latitude}, lng=${position.longitude}");
      }
    } catch (e) {
      print("Gagal mendapatkan lokasi: $e");
    }
  }

  Future<GoogleMapController> get _mapControllerFuture async {
    return _controller.future;
  }

  Future<void> _getUserCurrentLocationWithAwait() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Izin lokasi ditolak.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Izin lokasi ditolak secara permanen. Harap ubah di pengaturan.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      if (position.latitude.isFinite &&
          position.longitude.isFinite) {

        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });

        if (_userLocation != null) {
          setState(() {
            _markers.add(
              Marker(
                markerId: const MarkerId("user_location"),
                position: _userLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: const InfoWindow(title: "My Location"),
              ),
            );
          });

          // Tunggu sampai controller siap
          try {
            GoogleMapController controller = await _mapControllerFuture;
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(_userLocation!, 14.0),
            );
          } catch (e) {
            print("Error waiting for map controller: $e");
          }
        }
      }
    } catch (e) {
      print("Gagal mendapatkan lokasi: $e");
    }
  }


  // Fungsi untuk menggambar rute
  Future<void> _getRoutePoints(LatLng start, LatLng destination) async {
    setState(() {
      _polylines.clear();
      _startPoint = start;
      _endPoint = destination;
      _routeVisible = true;
    });

    try {
      // Membuat objek PolylinePoints
      PolylinePoints polylinePoints = PolylinePoints();

      // Menggunakan format metode yang sesuai dengan API terbaru
      // Mengubah mode menjadi "motorcycling" untuk rute motor
      PolylineResult result = await polylinePoints
          .getRouteBetweenCoordinates(
          googleApiKey: "AIzaSyDzUgC1LAbAoMv3XpEpkTdYWORTXjVmvCY",
          request: PolylineRequest(
            origin: PointLatLng(start.latitude, start.longitude),
            destination: PointLatLng(destination.latitude, destination.longitude),
            mode: TravelMode.driving, // Google API tidak langsung mendukung mode motor, kita gunakan driving

            avoidHighways: true, // Lebih sesuai untuk motor
            avoidTolls: true, // Lebih sesuai untuk motor
          )
      );

      List<LatLng> polylineCoordinates = [];

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        print("Failed to get route points: ${result.errorMessage}");

        // Tambahkan garis lurus jika API tidak mengembalikan rute
        polylineCoordinates = [start, destination];
      }

      PolylineId id = const PolylineId("route");
      // Mengubah style polyline menjadi lebih menyerupai rute jalan
      Polyline polyline = Polyline(
        polylineId: id,
        color: _primaryColor,
        points: polylineCoordinates,
        width: 5, // Sedikit lebih tebal
        startCap: Cap.roundCap, // Ujung garis bulat
        endCap: Cap.roundCap,
        jointType: JointType.round, // Sambungan garis bulat
        geodesic: true, // Mengikuti kelengkungan bumi
        // Hapus patterns untuk menghilangkan garis putus-putus
      );

      setState(() {
        _polylines.add(polyline);
      });
    } catch (e) {
      print("Error getting route: $e");

      // Tambahkan garis lurus jika terjadi error
      PolylineId id = const PolylineId("route");
      Polyline polyline = Polyline(
        polylineId: id,
        color: _primaryColor,
        points: [start, destination],
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );

      setState(() {
        _polylines.add(polyline);
      });
    }
  }


  Widget _buildRouteSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Route Planner',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: _secondaryTextColor),
                onPressed: () {
                  setState(() {
                    _showRouteSelector = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Start point selector
          DropdownButtonFormField<LatLng>(
            decoration: InputDecoration(
              labelText: 'Start Point',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.location_on, color: _primaryColor),
            ),
            value: _routeStartPoint,
            items: [
              if (_userLocation != null)
                DropdownMenuItem(
                  value: _userLocation,
                  child: Text('My Location'),
                ),
              ..._allPlaces.map((place) {
                return DropdownMenuItem(
                  value: LatLng(place['latitude'], place['longitude']),
                  child: Text(place['title']),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _routeStartPoint = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // End point selector
          DropdownButtonFormField<LatLng>(
            decoration: InputDecoration(
              labelText: 'Destination',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.flag, color: _primaryColor),
            ),
            value: _routeEndPoint,
            items: _allPlaces.map((place) {
              return DropdownMenuItem(
                value: LatLng(place['latitude'], place['longitude']),
                child: Text(place['title']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _routeEndPoint = value;
              });
            },
          ),
          const SizedBox(height: 24),
          // Submit button
          ElevatedButton.icon(
            onPressed: () {
              if (_routeStartPoint != null && _routeEndPoint != null) {
                _getRoutePoints(_routeStartPoint!, _routeEndPoint!);
                setState(() {
                  _showRouteSelector = false;
                });
                // Center map on route
                mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(
                      (_routeStartPoint!.latitude + _routeEndPoint!.latitude) / 2,
                      (_routeStartPoint!.longitude + _routeEndPoint!.longitude) / 2,
                    ),
                    13.0,
                  ),
                );
              }
            },
            icon: Icon(Icons.directions_bike),
            label: Text('Show Motorcycle Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    ).animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }



// 6. Add a route options FAB to the build method

  // Fungsi untuk menghapus rute
  void _clearRoute() {
    setState(() {
      _polylines.clear();
      _routeVisible = false;
      _startPoint = null;
      _endPoint = null;
    });
  }

  // Modifikasi pada fungsi _handleCBFRecommendation

  // Modifikasi pada fungsi _onMapCreated
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _controller.complete(controller);

    // Panggil _getUserCurrentLocation setelah map siap
    _getUserCurrentLocation();
  }




  Future<void> _preloadRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingRecommendations = false;
      });
      return;
    }

    try {
      // Load CBF recommendations
      final cbfResponse = await getRecommendationCBF(user.email!);
      if (cbfResponse != null && cbfResponse['recommendations'] != null) {
        _preloadedCBFRecommendations = cbfResponse['recommendations'] as List<dynamic>;
      }

      // Load Collaborative recommendations
      final collaborativeRecommendations = await getRecommendationWisata(user.email!);
      if (collaborativeRecommendations.isNotEmpty) {
        _preloadedCollaborativeRecommendations = collaborativeRecommendations;
      }
    } catch (e) {
      print('Error preloading recommendations: $e');
    } finally {
      setState(() {
        _isLoadingRecommendations = false;
      });
    }
  }

  Future<void> _refreshRecommendations() async {
    setState(() {
      _isRefreshing = true;
    });

    await _preloadRecommendations();

    setState(() {
      _isRefreshing = false;
    });

    _showSuccessSnackBar('Recommendations refreshed!');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text(
              message,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.all(12),
      ),
    );
  }

  void _onSearchChanged(String query) {
    final results = _allPlaces
        .where((place) =>
        place['title'].toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();

    setState(() {
      _suggestions = results;
    });
  }

  void _onSuggestionTap(dynamic place) {
    _focusNode.unfocus();
    _searchController.text = place['title'];
    setState(() {
      _suggestions = [];
      _selectedPlace = place;
      _showRecommendations = false;
      _recommendationList = [];
      _currentRecommendationType = '';
      _hasCBFHaversineData = false;
      _cbfHaversineRecommendations = [];
    });

    final target = LatLng(place['latitude'], place['longitude']);
    mapController.animateCamera(CameraUpdate.newLatLng(target));

    // Animate the bottom sheet
    _slideController.reset();
    _slideController.forward();
  }

  void _handleCBFRecommendation() {
    if (_preloadedCBFRecommendations.isEmpty) {
      _showSuccessSnackBar('CBF recommendations not available');
      return;
    }

    final recommendations = _preloadedCBFRecommendations;
    final recommendedIds = recommendations.map((r) => r['placeId']).toSet();

    final updatedMarkers = _allPlaces.map((data) {
      final isRecommended = recommendedIds.contains(data['placeId']);
      return Marker(
        markerId: MarkerId(data['placeId'].toString()),
        position: LatLng(data['latitude'], data['longitude']),
        icon: isRecommended ? BitmapDescriptor.defaultMarkerWithHue(_cbfMarkerColor) : BitmapDescriptor.defaultMarkerWithHue(_defaultMarkerColor),
        infoWindow: InfoWindow(title: data['title'], snippet: data['city']),
        onTap: () {
          setState(() {
            _selectedPlace = data;
            _showRecommendations = false;
            _recommendationList = [];
            _currentRecommendationType = '';
            _hasCBFHaversineData = false;
            _cbfHaversineRecommendations = [];
          });

          // Animate the bottom sheet
          _slideController.reset();
          _slideController.forward();

          // Remove automatic route creation on marker tap
          // Routes now created only through the route planner
        },
      );
    }).toSet();

    // Tambahkan marker lokasi user jika ada
    if (_userLocation != null) {
      updatedMarkers.add(
        Marker(
          markerId: const MarkerId("user_location"),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "My Location"),
        ),
      );
    }

    setState(() {
      _selectedPlace = null;
      _markers = updatedMarkers;
      _recommendationList = recommendations;
      _showRecommendations = true;
      _currentRecommendationType = 'CBF';
      _clearRoute(); // Clear any existing routes
    });

    // Animate the bottom sheet
    _slideController.reset();
    _slideController.forward();
  }

// Similarly, update _handleCollaborativeRecommendation function:

  void _handleCollaborativeRecommendation() {
    if (_preloadedCollaborativeRecommendations.isEmpty) {
      _showSuccessSnackBar('Collaborative recommendations not available');
      return;
    }

    final recommendations = _preloadedCollaborativeRecommendations;
    final recommendedIds = recommendations.map((r) => r['placeId']).toSet();

    final updatedMarkers = _allPlaces.map((data) {
      final isRecommended = recommendedIds.contains(data['placeId']);
      return Marker(
        markerId: MarkerId(data['placeId'].toString()),
        position: LatLng(data['latitude'], data['longitude']),
        icon: isRecommended ? BitmapDescriptor.defaultMarkerWithHue(_collaborativeMarkerColor) : BitmapDescriptor.defaultMarkerWithHue(_defaultMarkerColor),
        infoWindow: InfoWindow(title: data['title'], snippet: data['city']),
        onTap: () {
          setState(() {
            _selectedPlace = data;
            _showRecommendations = false;
            _recommendationList = [];
            _currentRecommendationType = '';
            _hasCBFHaversineData = false;
            _cbfHaversineRecommendations = [];
          });

          // Animate the bottom sheet
          _slideController.reset();
          _slideController.forward();

          // Remove automatic route creation on marker tap
          // Routes now created only through the route planner
        },
      );
    }).toSet();

    // Tambahkan marker lokasi user jika ada
    if (_userLocation != null) {
      updatedMarkers.add(
        Marker(
          markerId: const MarkerId("user_location"),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "My Location"),
        ),
      );
    }

    setState(() {
      _selectedPlace = null;
      _markers = updatedMarkers;
      _recommendationList = recommendations;
      _showRecommendations = true;
      _currentRecommendationType = 'Collaborative';
      _clearRoute(); // Clear any existing routes
    });

    // Animate the bottom sheet
    _slideController.reset();
    _slideController.forward();
  }

// Also update the _loadMarkersFromJson function to remove automatic route display:

  Future<void> _loadMarkersFromJson() async {
    final String jsonString = await rootBundle.loadString('assets/data.json');
    final List<dynamic> jsonData = json.decode(jsonString);

    final markers = jsonData.map((data) {
      return Marker(
        markerId: MarkerId(data['placeId'].toString()),
        position: LatLng(data['latitude'], data['longitude']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: data['title'], snippet: data['city']),
        onTap: () {
          setState(() {
            _selectedPlace = data;
            _showRecommendations = false;
            _recommendationList = [];
            _currentRecommendationType = '';
            _hasCBFHaversineData = false;
            _cbfHaversineRecommendations = [];
          });

          // Trigger animation for the bottom sheet
          _slideController.reset();
          _slideController.forward();

          // Remove automatic route creation on marker tap
          // Routes now created only through the route planner
        },
      );
    }).toSet();

    setState(() {
      _markers = markers;
      _allPlaces = jsonData;
    });
  }
  // Modifikasi pada fungsi _handleCBFHaversineRecommendation
  Future<void> _handleCBFHaversineRecommendation() async {
    if (_selectedPlace == null) return;

    setState(() {
      _isLoadingCBFHaversine = true;
    });

    final response = await getRecommendationCBFHaversine(_selectedPlace['title']);

    setState(() {
      _isLoadingCBFHaversine = false;
    });

    if (response == null || response['recommendations'] == null) {
      _showSuccessSnackBar('CBF + Haversine recommendations not available');
      return;
    }

    final recommendations = (response['recommendations'] as List<dynamic>);
    final recommendedIds = recommendations.map((r) => r['placeId']).toSet();

    // Update markers with haversine recommendations
    final updatedMarkers = _allPlaces.map((data) {
      final isRecommended = recommendedIds.contains(data['placeId']);
      return Marker(
        markerId: MarkerId(data['placeId'].toString()),
        position: LatLng(data['latitude'], data['longitude']),
        icon: isRecommended ? BitmapDescriptor.defaultMarkerWithHue(_cbfHaversineMarkerColor) : BitmapDescriptor.defaultMarkerWithHue(_defaultMarkerColor),
        infoWindow: InfoWindow(title: data['title'], snippet: data['city']),
        onTap: () {
          setState(() {
            _selectedPlace = data;
            _showRecommendations = false;
            _recommendationList = [];
            _currentRecommendationType = '';
            _hasCBFHaversineData = false;
            _cbfHaversineRecommendations = [];
          });

          // Animate the bottom sheet
          _slideController.reset();
          _slideController.forward();

          // Remove automatic route creation on marker tap
          // Routes now created only through the route planner
        },
      );
    }).toSet();

    // Tambahkan marker lokasi user jika ada
    if (_userLocation != null) {
      updatedMarkers.add(
        Marker(
          markerId: const MarkerId("user_location"),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "My Location"),
        ),
      );
    }

    setState(() {
      _markers = updatedMarkers;
      _cbfHaversineRecommendations = recommendations;
      _hasCBFHaversineData = true;
    });

    // Animate the recommendations
    _fadeController.reset();
    _fadeController.forward();
  }

  @override
  // Now let's modify the build method to include these new widgets.
// Replace or modify the build method in the _MapScreenState class:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-8.7327938, 115.4508319),
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            mapType: MapType.normal,
            // onTap: _onMapTap, // Add map tap listener to select destination
          ),

          // Custom search bar
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Material(
              elevation: 4,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                style: TextStyle(color: _textColor, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search or tap on map for destination...',
                  hintStyle: TextStyle(color: _secondaryTextColor.withOpacity(0.7)),
                  prefixIcon: Icon(Icons.search, color: _primaryColor),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: _primaryColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _suggestions = [];
                      });
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: _backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                ),
              ),
            ).animate()
                .fadeIn(duration: const Duration(milliseconds: 500))
                .slideY(begin: -0.2, end: 0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutQuad),
          ),

          // Loading indicator when fetching recommendations
          if (_isLoadingRecommendations)
            Positioned(
              top: 100,
              left: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitFoldingCube(
                      color: _primaryColor,
                      size: 20.0,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Loading recommendations...',
                      style: TextStyle(color: _textColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ).animate()
                  .fadeIn(duration: const Duration(milliseconds: 600))
                  .slideY(begin: -0.1, end: 0),
            ),

          // Search suggestions
          if (_suggestions.isNotEmpty)
            Positioned(
              top: 90,
              left: 15,
              right: 15,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _suggestions.length > 5 ? 5 : _suggestions.length, // Limit to 5 suggestions
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.withOpacity(0.2),
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final place = _suggestions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _primaryColor.withOpacity(0.1),
                        child: Icon(Icons.place, color: _primaryColor),
                      ),
                      title: Text(
                        place['title'] ?? "Unknown",
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        place['city'] ?? "Unknown Location",
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => _onSuggestionTap(place),
                    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
                  },
                ),
              ).animate().fade().scale(
                alignment: Alignment.topCenter,
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
                duration: const Duration(milliseconds: 200),
              ),
            ),

          // Multi-action expandable FAB on right side
          Positioned(
            bottom: 30,
            right: 16,
            child: _buildExpandableFAB(),
          ),

          // Clear route button if route is visible
          if (_routeVisible)
            Positioned(
              bottom: 150,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'clear_route',
                onPressed: _clearRoute,
                backgroundColor: Colors.red,
                mini: true,
                child: const Icon(Icons.clear),
              ).animate()
                  .fadeIn()
                  .scale(),
            ),

          // Route selector popup
          if (_showRouteSelector)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: _buildRouteSelector(),
            ),

          if (_showRecommendations && _recommendationList.isNotEmpty)
            _buildDraggableSheet(showSelectedPlace: false)
          else if (_selectedPlace != null)
            _buildDraggableSheet(showSelectedPlace: true),
        ],
      ),
    );
  }

  Widget _buildDraggableSheet({required bool showSelectedPlace}) {
    return SlideTransition(
      position: _slideAnimation,
      child: DraggableScrollableSheet(
        initialChildSize: 0.25,
        minChildSize: 0.2,
        maxChildSize: 0.7,
        builder: (context, scrollController) {
          return _buildRecommendationSheet(scrollController,
              showSelectedPlace: showSelectedPlace);
        },
      ),
    );
  }

  Widget _buildRecommendationSheet(ScrollController scrollController,
      {required bool showSelectedPlace}) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle and header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Sheet header - different based on content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: !showSelectedPlace
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Recommended Places ($_currentRecommendationType)",
                          style: TextStyle(
                            fontSize: 20,
                            color: _textColor,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Refresh button
                      ElevatedButton.icon(
                        onPressed: _isRefreshing ? null : _refreshRecommendations,
                        icon: _isRefreshing
                            ? SizedBox(
                          width: 18,
                          height: 18,
                          child: SpinKitFadingCircle(
                            color: Colors.white,
                            size: 18.0,
                          ),
                        )
                            : const Icon(Icons.refresh, size: 18),
                        label: Text(_isRefreshing ? "Refreshing" : "Refresh"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      // Close button
                      IconButton(
                        onPressed: _closeDraggableSheet,
                        icon: const Icon(Icons.close, size: 24),
                        color: _secondaryTextColor,
                        tooltip: 'Close',
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Selected Place",
                              style: TextStyle(
                                fontSize: 20,
                                color: _textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedPlace != null)
                              Text(
                                _selectedPlace['title'] ?? "Unknown",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _secondaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!_hasCBFHaversineData)
                        ElevatedButton(
                          onPressed: _isLoadingCBFHaversine ? null : _handleCBFHaversineRecommendation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoadingCBFHaversine
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SpinKitFoldingCube(
                                color: Colors.white,
                                size: 16.0,
                              ),
                              const SizedBox(width: 8),
                              const Text('Loading...'),
                            ],
                          )
                              : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.travel_explore, size: 18),
                              SizedBox(width: 8),
                              Text('CBF + Haversine'),
                            ],
                          ),
                        ),
                      // Close button
                      IconButton(
                        onPressed: _closeDraggableSheet,
                        icon: const Icon(Icons.close, size: 24),
                        color: _secondaryTextColor,
                        tooltip: 'Close',
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                // Content based on what to show
                if (showSelectedPlace && _selectedPlace != null) ...[
                  // Show selected place or CBF + Haversine recommendations
                  if (_hasCBFHaversineData && _cbfHaversineRecommendations.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                Icon(Icons.recommend, color: _primaryColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Similar Places Nearby",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: _textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 290,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _cbfHaversineRecommendations.length,
                              itemBuilder: (context, index) {
                                return _buildAnimatedPlaceCard(
                                  _cbfHaversineRecommendations[index],
                                  index,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildSelectedPlaceDetail(_selectedPlace),
                ],

                if (_showRecommendations && _recommendationList.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 290,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recommendationList.length,
                      itemBuilder: (context, index) {
                        return _buildAnimatedPlaceCard(_recommendationList[index], index);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to handle map tap

  // Add this method to handle closing the draggable sheet
  void _closeDraggableSheet() {
    // Reverse the slide animation to hide the sheet
    _slideController.reverse();

    // Reset any necessary state variables when closing
    setState(() {
      _showRecommendations = false;
      if (_hasCBFHaversineData) {
        _hasCBFHaversineData = false;
        _cbfHaversineRecommendations.clear();
      }
    });
  }

  Widget _buildSelectedPlaceDetail(Map<String, dynamic> place) {
    final name = place['title'] ?? 'Nama tidak tersedia';
    final category = place['categories'] ?? 'Kategori tidak tersedia';
    final rating = double.tryParse(place['totalScore'].toString()) ?? 0.0;
    final address = place['address'] ?? 'Alamat tidak tersedia';
    final description = place['description'] ?? 'Deskripsi tidak tersedia';
    final price = place['price'].toString();
    final image = (place['imageUrl'] == null || place['imageUrl'] == '' || place['imageUrl'] == '-')
        ? 'assets/defaultBG.png'
        : place['imageUrl'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image with gradient overlay and rating badge
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    image,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: SpinKitPulse(
                            color: _primaryColor,
                            size: 50.0,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: Colors.grey.shade400,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sell, color: _primaryColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Rp $price',
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate()
              .fadeIn(duration: const Duration(milliseconds: 600))
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

          // Title and category
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 14,
                            color: _secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 14,
                              color: _secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(
                          name: name,
                          location: place['id'] ?? 'Unknown',
                          address: place['address'] ?? 'Unknown',
                          category: category,
                          price: price,
                          facility: place['activity'] ?? 'Unknown',
                          day: place['day'] == 1 ? 'Buka Setiap Hari' : 'Tidak Buka Setiap Hari',
                          time: place['time'] == 1 ? 'Buka 24 Jam' : 'Tidak 24 Jam',
                          description: place['description'] ?? 'Unknown',
                          rating: rating,
                          imagePath: image,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ).animate()
              .fadeIn(delay: const Duration(milliseconds: 200))
              .slideX(begin: 0.05, end: 0),

          // Address with icon
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  size: 18,
                  color: _primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      fontSize: 14,
                      color: _secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ).animate()
              .fadeIn(delay: const Duration(milliseconds: 300))
              .slideX(begin: 0.05, end: 0),

          // Description
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
          ).animate()
              .fadeIn(delay: const Duration(milliseconds: 400))
              .slideX(begin: 0.05, end: 0),

          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: _secondaryTextColor,
              height: 1.5,
            ),
          ).animate()
              .fadeIn(delay: const Duration(milliseconds: 500))
              .slideX(begin: 0.05, end: 0),

          // View details button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(
                      name: name,
                      location: place['id'] ?? 'Unknown',
                      address: place['address'] ?? 'Unknown',
                      category: category,
                      price: price,
                      facility: place['activity'] ?? 'Unknown',
                      day: place['day'] == 1 ? 'Buka Setiap Hari' : 'Tidak Buka Setiap Hari',
                      time: place['time'] == 1 ? 'Buka 24 Jam' : 'Tidak 24 Jam',
                      description: place['description'] ?? 'Unknown',
                      rating: rating,
                      imagePath: image,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(double.infinity, 54),
                elevation: 3,
                shadowColor: _primaryColor.withOpacity(0.5),
              ),
              child: const Text(
                'View Full Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ).animate()
              .fadeIn(delay: const Duration(milliseconds: 600))
              .scale(delay: const Duration(milliseconds: 300)),
        ],
      ),
    );
  }

  Widget _buildAnimatedPlaceCard(Map<String, dynamic> place, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, left: 4, top: 4, bottom: 4),
      child: _buildPlaceCard(place),
    ).animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index), duration: const Duration(milliseconds: 400))
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    final name = place['title'] ?? 'Nama tidak tersedia';
    final category = place['categories'] ?? 'Kategori tidak tersedia';
    final rating = double.tryParse(place['totalScore'].toString()) ?? 0.0;
    final price = place['price'].toString();
    final image = (place['imageUrl'] == null || place['imageUrl'] == '' || place['imageUrl'] == '-')
        ? 'assets/defaultBG.png'
        : place['imageUrl'];

    // Method untuk memindahkan kamera ke lokasi yang dipilih (di dalam _buildPlaceCard)
    void moveToLocation() async {
      try {
        // Ambil koordinat dari place data
        double? latitude = place['latitude'];
        double? longitude = place['longitude'];

        // Coba ambil dari berbagai kemungkinan key untuk koordinat
        if (place['latitude'] != null && place['longitude'] != null) {
          latitude = double.tryParse(place['latitude'].toString());
          longitude = double.tryParse(place['longitude'].toString());
        } else if (place['lat'] != null && place['lng'] != null) {
          latitude = double.tryParse(place['lat'].toString());
          longitude = double.tryParse(place['lng'].toString());
        } else if (place['location'] != null && place['location'] is Map) {
          final location = place['location'] as Map;
          latitude = double.tryParse(location['latitude']?.toString() ?? '');
          longitude = double.tryParse(location['longitude']?.toString() ?? '');
        }

        // Debug: Print data place untuk melihat struktur data
        print('Place data: $place');
        print('Latitude: $latitude, Longitude: $longitude');

        if (latitude != null && longitude != null) {
          // Dapatkan controller dengan cara yang benar
          GoogleMapController controller;
          if (_mapController != null) {
            controller = _mapController!;
          } else {
            // Wait for the controller to be initialized
            controller = await _controller.future;
            _mapController = controller;
          }

          // Pindahkan kamera ke lokasi
          final LatLng targetLocation = LatLng(latitude, longitude);

          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: targetLocation,
                zoom: 16.0,
              ),
            ),
          );

          // Tambahkan marker untuk lokasi yang dipilih (opsional)
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId('selected_${place['id']}'),
                position: targetLocation,
                infoWindow: InfoWindow(
                  title: place['title'] ?? 'Selected Location',
                  snippet: place['address'] ?? '',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ),
            );
          });

          // Tutup draggable sheet (opsional)
          _closeDraggableSheet();

          // Tampilkan snackbar konfirmasi
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved to ${place['title'] ?? 'selected location'}'),
              duration: const Duration(seconds: 2),
              backgroundColor: _primaryColor,
            ),
          );
        } else {
          // Jika koordinat tidak tersedia, tampilkan pesan error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location coordinates not available for this place'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        print('Error moving to location: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move to location: ${e.toString()}'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }


    return SizedBox(
      width: 220,
      child: Stack(
        children: [
          // Main card content
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(
                    name: name,
                    location: place['id'] ?? 'Unknown',
                    address: place['address'] ?? 'Unknown',
                    category: category,
                    price: price,
                    facility: place['activity'] ?? 'Unknown',
                    day: place['day'] == 1 ? 'Buka Setiap Hari' : 'Tidak Buka Setiap Hari',
                    time: place['time'] == 1 ? 'Buka 24 Jam' : 'Tidak 24 Jam',
                    description: place['description'] ?? 'Unknown',
                    rating: rating,
                    imagePath: image,
                  ),
                ),
              );
            },
            child: heightCard(
              title: name,
              subtitle: category,
              rating: rating,
              price: price,
              image: image,
              isLiked: likedPlaces.contains(name),
              onLikeToggle: () async {
                final user = FirebaseAuth.instance.currentUser;
                final email = user?.email;
                if (email == null) return false;

                final placeId = place['id'];
                final newLikeStatus = !likedPlaces.contains(name);

                final success = await postComment(
                  placeId: placeId,
                  email: email,
                  like: newLikeStatus,
                );

                if (success) {
                  setState(() {
                    if (newLikeStatus) {
                      likedPlaces.add(name);
                    } else {
                      likedPlaces.remove(name);
                      _recommendationList.removeWhere((p) => p['title'] == name);
                    }
                  });
                }

                return success;
              },
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildExpandableFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Location button - FIXED
        if (_isFabExpanded)
          FloatingActionButton(
            heroTag: 'location',
            mini: true,
            onPressed: () async {
              if (_userLocation != null) {
                try {
                  // Get the correct controller
                  GoogleMapController controller;
                  if (_mapController != null) {
                    controller = _mapController!;
                  } else {
                    controller = await _controller.future;
                    _mapController = controller;
                  }

                  await controller.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      _userLocation!,
                      17.0,
                    ),
                  );
                } catch (e) {
                  print('Error moving to user location: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to move to your location'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                _getUserCurrentLocation();
              }
              setState(() {
                _isFabExpanded = false;
              });
            },
            backgroundColor: _primaryColor,
            child: const Icon(Icons.my_location),
          ).animate()
              .fadeIn(delay: const Duration(milliseconds: 100))
              .slideY(begin: 0.3, end: 0),

        // Content-based recommendation button
        if (_isFabExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: FloatingActionButton(
              heroTag: 'cbf',
              mini: true,
              onPressed: () {
                _handleCBFRecommendation();
                setState(() {
                  _isFabExpanded = false;
                });
              },
              backgroundColor: _currentRecommendationType == 'CBF'
                  ? Colors.amber
                  : _primaryColor.withOpacity(0.8),
              child: const Icon(Icons.recommend),
            ).animate()
                .fadeIn(delay: const Duration(milliseconds: 200))
                .slideY(begin: 0.3, end: 0),
          ),

        // Collaborative recommendation button
        if (_isFabExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: FloatingActionButton(
              heroTag: 'collaborative',
              mini: true,
              onPressed: () {
                _handleCollaborativeRecommendation();
                setState(() {
                  _isFabExpanded = false;
                });
              },
              backgroundColor: _currentRecommendationType == 'Collaborative'
                  ? Colors.teal
                  : _primaryColor.withOpacity(0.8),
              child: const Icon(Icons.group),
            ).animate()
                .fadeIn(delay: const Duration(milliseconds: 300))
                .slideY(begin: 0.3, end: 0),
          ),

        // Route planning button
        if (_isFabExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: FloatingActionButton(
              heroTag: 'route',
              mini: true,
              onPressed: () {
                _handleRoutePlanning();
                setState(() {
                  _isFabExpanded = false;
                });
              },
              backgroundColor: _routeVisible
                  ? Colors.green
                  : _primaryColor.withOpacity(0.8),
              child: const Icon(Icons.route),
            ).animate()
                .fadeIn(delay: const Duration(milliseconds: 400))
                .slideY(begin: 0.3, end: 0),
          ),

        // Main FAB that toggles expansion
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: FloatingActionButton(
            heroTag: 'main',
            onPressed: () {
              setState(() {
                _isFabExpanded = !_isFabExpanded;
              });
            },
            backgroundColor: _primaryColor,
            child: Icon(_isFabExpanded ? Icons.close : Icons.menu),
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getPlaceInfoFromPosition(LatLng position) async {
    // In a real implementation, you would use the Geocoding API
    // For now, we'll just return placeholder data
    await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay

    return {
      'title': 'Location at ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
      'address': 'Selected location on map',
      'city': 'Unknown City',
      'rating': 0.0,
    };
  }
  void _handleRoutePlanning() {
    if (_selectedPlace == null && _userLocation == null) {
      // Show message to select a place first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a destination first')),
      );
      return;
    }

    setState(() {
      _showRouteSelector = true;
    });
  }

}