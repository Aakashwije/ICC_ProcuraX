import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../services/meeting_location_service.dart';
import '../../../theme.dart';

/// Result returned by [LocationPickerScreen] to the calling page.
class LocationPickerResult {
  final String address;
  final double latitude;
  final double longitude;

  const LocationPickerResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

/// Full-screen location picker with:
/// - Embedded Google Map with draggable marker
/// - Google Places autocomplete search bar
/// - "Use My Location" button
/// - Confirm button
class LocationPickerScreen extends StatefulWidget {
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  GoogleMapController? _mapController;

  // Selected location
  LatLng? _selectedLatLng;
  String? _selectedAddress;

  // Places autocomplete suggestions
  List<_PlaceSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  // Loading states
  bool _isLoadingLocation = false;
  bool _isLoadingPlace = false;
  bool _isReverseGeocoding = false;
  bool _locationPermissionGranted = false;

  // Default camera position (Colombo, Sri Lanka as fallback)
  static const LatLng _defaultPosition = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialAddress ?? '';

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLatLng = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _selectedAddress = widget.initialAddress;
    }

    // Check and request location permission after the screen builds
    _requestLocationPermission();
  }

  /// Request location permission with a nice flow:
  /// 1. Check current status
  /// 2. If denied, request it
  /// 3. Update the map to show "my location" blue dot if granted
  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationPicker] Location services disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        if (mounted) {
          setState(() => _locationPermissionGranted = true);
        }
      }
    } catch (e) {
      debugPrint('[LocationPicker] Permission error: $e');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Google Places Autocomplete ──────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final predictions = await MeetingLocationService.getPlacePredictions(
        query,
        latitude: _selectedLatLng?.latitude,
        longitude: _selectedLatLng?.longitude,
      );

      if (!mounted) return;
      setState(() {
        _suggestions = predictions
            .map(
              (p) => _PlaceSuggestion(
                placeId: p.placeId,
                mainText: p.mainText,
                secondaryText: p.secondaryText,
                fullDescription: p.fullDescription,
              ),
            )
            .where((s) => s.placeId.isNotEmpty)
            .toList();
        _showSuggestions = _suggestions.isNotEmpty;
      });
    });
  }

  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    setState(() {
      _isLoadingPlace = true;
      _showSuggestions = false;
      _searchController.text = suggestion.mainText;
    });
    _searchFocusNode.unfocus();

    final details = await MeetingLocationService.getPlaceDetails(
      suggestion.placeId,
    );

    if (!mounted) return;

    if (details != null) {
      final lat = details.latitude;
      final lng = details.longitude;
      final address = details.formattedAddress.isNotEmpty
          ? details.formattedAddress
          : suggestion.fullDescription;

      if (lat != null && lng != null) {
        final latLng = LatLng(lat, lng);
        setState(() {
          _selectedLatLng = latLng;
          _selectedAddress = address;
          _searchController.text = address;
          _isLoadingPlace = false;
        });
        _animateToPosition(latLng);
        return;
      }
    }

    // Fallback: use geocoding
    await _geocodeAddress(suggestion.fullDescription);
    setState(() => _isLoadingPlace = false);
  }

  // ── Geocoding fallback ──────────────────────────────────────────────────

  Future<void> _geocodeAddress(String address) async {
    try {
      final locations = await geo.locationFromAddress(address);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _selectedLatLng = latLng;
          _selectedAddress = address;
          _searchController.text = address;
        });
        _animateToPosition(latLng);
      }
    } catch (_) {}
  }

  // ── Reverse Geocoding (from map tap / drag) ─────────────────────────────

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() {
      _selectedLatLng = latLng;
      _isReverseGeocoding = true;
    });

    try {
      final placemarks = await geo.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty)
            p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
            p.administrativeArea!,
          if (p.country != null && p.country!.isNotEmpty) p.country!,
        ];
        final address = parts.join(', ');
        setState(() {
          _selectedAddress = address;
          _searchController.text = address;
          _isReverseGeocoding = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _selectedAddress =
            '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
        _searchController.text = _selectedAddress!;
        _isReverseGeocoding = false;
      });
    }
  }

  // ── Current Location ────────────────────────────────────────────────────

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    _searchFocusNode.unfocus();

    final position = await MeetingLocationService.getCurrentLocation();

    if (!mounted) return;

    if (position != null) {
      final latLng = LatLng(position.latitude, position.longitude);
      _animateToPosition(latLng);
      await _reverseGeocode(latLng);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get your location. Check permissions.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) setState(() => _isLoadingLocation = false);
  }

  // ── Map helpers ─────────────────────────────────────────────────────────

  void _animateToPosition(LatLng latLng) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: 16)),
    );
  }

  void _onMapTap(LatLng latLng) {
    _searchFocusNode.unfocus();
    setState(() => _showSuggestions = false);
    _reverseGeocode(latLng);
  }

  void _onMarkerDragEnd(LatLng latLng) {
    _reverseGeocode(latLng);
  }

  // ── Confirm ─────────────────────────────────────────────────────────────

  void _confirm() {
    if (_selectedLatLng == null || _selectedAddress == null) return;
    Navigator.pop(
      context,
      LocationPickerResult(
        address: _selectedAddress!,
        latitude: _selectedLatLng!.latitude,
        longitude: _selectedLatLng!.longitude,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final initialCameraPosition = CameraPosition(
      target: _selectedLatLng ?? _defaultPosition,
      zoom: _selectedLatLng != null ? 16 : 12,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Google Map ────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _selectedLatLng != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLatLng!,
                      draggable: true,
                      onDragEnd: _onMarkerDragEnd,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                    ),
                  }
                : {},
          ),

          // ── Top search bar + suggestions ──────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                if (_showSuggestions) _buildSuggestionsList(),
              ],
            ),
          ),

          // ── Bottom panel with location info + buttons ─────────────────
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomPanel()),

          // ── My Location FAB ───────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: _isLoadingLocation ? null : _useCurrentLocation,
              backgroundColor: Colors.white,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.black87,
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              onTap: () {
                if (_suggestions.isNotEmpty) {
                  setState(() => _showSuggestions = true);
                }
              },
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          if (_isLoadingPlace)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _suggestions = [];
                  _showSuggestions = false;
                });
              },
              icon: const Icon(Icons.close, size: 20),
              color: Colors.grey,
            ),
        ],
      ),
    );
  }

  // ── Suggestions List ────────────────────────────────────────────────────

  Widget _buildSuggestionsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, indent: 52, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final s = _suggestions[index];
          return ListTile(
            dense: true,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.place_rounded,
                color: primaryBlue,
                size: 18,
              ),
            ),
            title: Text(
              s.mainText,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: s.secondaryText.isNotEmpty
                ? Text(
                    s.secondaryText,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () => _selectSuggestion(s),
          );
        },
      ),
    );
  }

  // ── Bottom Panel ────────────────────────────────────────────────────────

  Widget _buildBottomPanel() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Selected location info
          if (_selectedLatLng != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isReverseGeocoding
                              ? 'Getting address...'
                              : (_selectedAddress ?? 'Location selected'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF2E7D32),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedLatLng!.latitude.toStringAsFixed(5)}, '
                          '${_selectedLatLng!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: primaryBlue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search for a place, tap the map, or use your current location',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (_selectedLatLng != null && !_isReverseGeocoding)
                  ? _confirm
                  : null,
              icon: const Icon(Icons.check_rounded),
              label: const Text(
                'Use This Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal model for a place suggestion.
class _PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullDescription;

  const _PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullDescription,
  });
}
