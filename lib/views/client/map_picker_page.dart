import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../core/localization.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng initialCenter;

  const MapPickerPage({
    super.key,
    this.initialCenter = const LatLng(30.0444, 31.2357), // Cairo
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  String _currentAddress = "";
  String? _currentPostcode;
  bool _isReversing = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialCenter;
    _reverseGeocode(widget.initialCenter);
  }

  Future<void> _reverseGeocode(LatLng location) async {
    setState(() {
      _isReversing = true;
      _selectedLocation = location;
    });

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json&accept-language=${AppLocalization.isArabic ? "ar" : "en"}');
      final response = await http.get(url, headers: {'User-Agent': 'AngeznyApp'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentAddress = data['display_name'] ?? "";
          if (data['address'] != null) {
            _currentPostcode = data['address']['postcode']?.toString();
          }
        });
      }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
    } finally {
      setState(() => _isReversing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalization.isArabic ? 'تحديد الموقع' : 'Select Location', style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 15.0,
              onTap: (tapPosition, point) => _reverseGeocode(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.angezny.app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),
          
          // Address Panel
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_pin, color: Color(0xFF006D5B)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isReversing 
                          ? const LinearProgressIndicator(color: Color(0xFF006D5B), backgroundColor: Color(0xFFF1F5F9))
                          : Text(
                              _currentAddress.isEmpty ? (AppLocalization.isArabic ? 'جاري تحديد العنوان...' : 'Getting address...') : _currentAddress,
                              style: GoogleFonts.cairo(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _currentAddress.isEmpty || _isReversing ? null : () {
                        Navigator.pop(context, {
                          'address': _currentAddress,
                          'postcode': _currentPostcode,
                          'lat': _selectedLocation!.latitude,
                          'lng': _selectedLocation!.longitude,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D5B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(
                        AppLocalization.isArabic ? 'تأكيد الموقع' : 'Confirm Location',
                        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Map center helper (Optional: if we want to pick by dragging)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.add, size: 30, color: Colors.black26),
            ),
          ),
        ],
      ),
    );
  }
}
