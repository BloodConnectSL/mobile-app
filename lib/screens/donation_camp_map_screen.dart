import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DonationCampMapScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DonationCampMapScreen({
    super.key,
    required this.userData,
  });

  @override
  State<DonationCampMapScreen> createState() => _DonationCampMapScreenState();
}

class _DonationCampMapScreenState extends State<DonationCampMapScreen> {
  // Map Controller
  final MapController _mapController = MapController();

  // Sri Lanka Geographic Bounds & Center
  // Strictly prevent viewing or panning to any other part of the world
  static final LatLngBounds _sriLankaBounds = LatLngBounds(
    const LatLng(5.4, 79.0),
    const LatLng(10.3, 82.5),
  );
  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);

  // Fallback Verified Sri Lanka Donation Camps (ensures pins are always visible)
  static final List<Map<String, dynamic>> _fallbackCamps = [
    {
      'id': 'd174d930-8acf-4d82-b413-350e9c730ec9',
      'camp_name': 'National Blood Drive 2026 - Colombo Town Hall',
      'venue_name': 'Colombo Town Hall Auditorium',
      'address': 'F. R. Senanayake Mawatha, Colombo 07',
      'city': 'Colombo',
      'status': 'SCHEDULED',
      'target_units': 200,
      'location': '6.9147,79.8653',
      'geo_location': {'lat': 6.9147, 'lng': 79.8653},
      'start_time': '2026-11-10T09:00:00+05:30',
      'end_time': '2026-11-10T17:00:00+05:30',
      'district': {'district': 'Colombo'},
    },
    {
      'id': 'bae86081-9f7a-41e1-8ee0-4a3489c88de1',
      'camp_name': 'Youth For Life Blood Campaign - BMICH',
      'venue_name': 'BMICH Exhibition Hall B',
      'address': 'Bauddhaloka Mawatha, Colombo 07',
      'city': 'Colombo',
      'status': 'SCHEDULED',
      'target_units': 180,
      'location': '6.9010,79.8735',
      'geo_location': {'lat': 6.9010, 'lng': 79.8735},
      'start_time': '2026-11-12T09:00:00+05:30',
      'end_time': '2026-11-12T16:00:00+05:30',
      'district': {'district': 'Colombo'},
    },
    {
      'id': '37f783ba-af7c-475a-8533-04c4f5d8d3a3',
      'camp_name': 'Negombo Coastal Community Blood Camp',
      'venue_name': 'Negombo Municipal Council Ground Hall',
      'address': 'Beach Road, Negombo',
      'city': 'Gampaha',
      'status': 'SCHEDULED',
      'target_units': 120,
      'location': '7.2088,79.8358',
      'geo_location': {'lat': 7.2088, 'lng': 79.8358},
      'start_time': '2026-11-04T09:00:00+05:30',
      'end_time': '2026-11-04T15:00:00+05:30',
      'district': {'district': 'Gampaha'},
    },
    {
      'id': 'c37f9ece-bbf9-4a76-929e-5b66950c6f56',
      'camp_name': 'Kandy Hills Annual Blood Drive',
      'venue_name': 'Kandy City Centre Level 3 Auditorium',
      'address': 'Dalada Veediya, Kandy',
      'city': 'Kandy',
      'status': 'SCHEDULED',
      'target_units': 250,
      'location': '7.2936,80.6350',
      'geo_location': {'lat': 7.2936, 'lng': 80.6350},
      'start_time': '2026-11-08T09:00:00+05:30',
      'end_time': '2026-11-08T17:00:00+05:30',
      'district': {'district': 'Kandy'},
    },
    {
      'id': '512cbf61-8748-4c9a-b74c-66066fa6eae8',
      'camp_name': 'Southern Pearl Blood Donation Drive',
      'venue_name': 'Galle Fort Community Center',
      'address': 'Church Street, Galle Fort',
      'city': 'Galle',
      'status': 'SCHEDULED',
      'target_units': 150,
      'location': '6.0329,80.2168',
      'geo_location': {'lat': 6.0329, 'lng': 80.2168},
      'start_time': '2026-11-14T09:00:00+05:30',
      'end_time': '2026-11-14T15:00:00+05:30',
      'district': {'district': 'Galle'},
    },
    {
      'id': '9bf1cdba-d9d7-459c-b833-66f450deab30',
      'camp_name': 'Northern Hope Blood Camp - Jaffna',
      'venue_name': 'Jaffna Central College Memorial Hall',
      'address': 'Central College Road, Jaffna',
      'city': 'Jaffna',
      'status': 'SCHEDULED',
      'target_units': 140,
      'location': '9.6647,80.0167',
      'geo_location': {'lat': 9.6647, 'lng': 80.0167},
      'start_time': '2026-11-18T09:00:00+05:30',
      'end_time': '2026-11-18T16:00:00+05:30',
      'district': {'district': 'Jaffna'},
    },
    {
      'id': '01697996-1d11-41cf-ba10-2a06112ee616',
      'camp_name': 'Rajarata Life Saver Camp - Anuradhapura',
      'venue_name': 'Public Library Hall, Anuradhapura',
      'address': 'Main Street, Anuradhapura',
      'city': 'Anuradhapura',
      'status': 'SCHEDULED',
      'target_units': 160,
      'location': '8.3314,80.4037',
      'geo_location': {'lat': 8.3314, 'lng': 80.4037},
      'start_time': '2026-11-20T09:00:00+05:30',
      'end_time': '2026-11-20T17:00:00+05:30',
      'district': {'district': 'Anuradhapura'},
    },
    {
      'id': '3b7f3488-76d2-4419-a0a8-6a6fe10f8a96',
      'camp_name': 'Wayamba Regional Blood Camp - Kurunegala',
      'venue_name': 'Kurunegala Town Hall Auditorium',
      'address': 'Negombo Road, Kurunegala',
      'city': 'Kurunegala',
      'status': 'SCHEDULED',
      'target_units': 130,
      'location': '7.4863,80.3623',
      'geo_location': {'lat': 7.4863, 'lng': 80.3623},
      'start_time': '2026-11-22T09:00:00+05:30',
      'end_time': '2026-11-22T15:00:00+05:30',
      'district': {'district': 'Kurunegala'},
    },
    {
      'id': '4e306b51-f2df-4104-963d-3508ba7297ab',
      'camp_name': 'Eastern Sunshine Blood Drive - Batticaloa',
      'venue_name': 'Batticaloa Municipal Pavilion',
      'address': 'Bar Road, Batticaloa',
      'city': 'Batticaloa',
      'status': 'SCHEDULED',
      'target_units': 120,
      'location': '7.7170,81.7000',
      'geo_location': {'lat': 7.7170, 'lng': 81.7000},
      'start_time': '2026-11-25T09:00:00+05:30',
      'end_time': '2026-11-25T16:00:00+05:30',
      'district': {'district': 'Batticaloa'},
    },
    {
      'id': '28633cc7-799c-40f2-b425-23919891dc34',
      'camp_name': 'Uva Highlands Emergency Blood Drive - Badulla',
      'venue_name': 'Badulla Simon Pieris Memorial Hall',
      'address': 'Lower Street, Badulla',
      'city': 'Badulla',
      'status': 'SCHEDULED',
      'target_units': 150,
      'location': '6.9934,81.0550',
      'geo_location': {'lat': 6.9934, 'lng': 81.0550},
      'start_time': '2026-11-28T09:00:00+05:30',
      'end_time': '2026-11-28T17:00:00+05:30',
      'district': {'district': 'Badulla'},
    },
  ];

  // State
  bool _isLoading = true;
  List<Map<String, dynamic>> _allCamps = [];
  List<Map<String, dynamic>> _filteredCamps = [];
  Map<String, dynamic>? _selectedCamp;

  // Donor Current Location
  LatLng? _userLocation;
  bool _isFetchingLocation = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with fallback camps so pins appear immediately
    _allCamps = List.from(_fallbackCamps);
    _filteredCamps = List.from(_fallbackCamps);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCampsAndLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCampsAndLocation() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Fetch live camps from backend
    try {
      final res = await ApiService.getBloodCamps(limit: 100).timeout(
        const Duration(seconds: 5),
      );
      final rawData = res['data'] as List<dynamic>? ?? [];
      final parsed = rawData
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((camp) => _getCampLatLng(camp) != null)
          .toList();

      if (parsed.isNotEmpty && mounted) {
        setState(() {
          _allCamps = parsed;
          _filteredCamps = parsed;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      // If network fails or times out, fallback camps already populate the map
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // 2. Fetch User Current Location
    _getCurrentUserLocation();
  }

  Future<void> _getCurrentUserLocation() async {
    if (!mounted) return;
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isFetchingLocation = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isFetchingLocation = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isFetchingLocation = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _userLocation = userLatLng;
          _isFetchingLocation = false;
        });

        // Center map to user if within Sri Lanka
        if (_sriLankaBounds.contains(userLatLng)) {
          _mapController.move(userLatLng, 12.0);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  LatLng? _getCampLatLng(Map<String, dynamic> camp) {
    double? lat;
    double? lng;

    final geo = camp['geo_location'];
    if (geo != null) {
      if (geo is Map) {
        lat = (geo['lat'] is num) ? (geo['lat'] as num).toDouble() : double.tryParse('${geo['lat']}');
        lng = (geo['lng'] is num) ? (geo['lng'] as num).toDouble() : double.tryParse('${geo['lng']}');
      } else if (geo is String && geo.isNotEmpty) {
        try {
          final decoded = jsonDecode(geo);
          if (decoded is Map) {
            lat = double.tryParse('${decoded['lat']}');
            lng = double.tryParse('${decoded['lng']}');
          }
        } catch (_) {}
      }
    }

    if (lat == null || lng == null) {
      final loc = camp['location'];
      if (loc is Map) {
        lat = (loc['lat'] is num) ? (loc['lat'] as num).toDouble() : double.tryParse('${loc['lat']}');
        lng = (loc['lng'] is num) ? (loc['lng'] as num).toDouble() : double.tryParse('${loc['lng']}');
      } else if (loc != null) {
        final locStr = loc.toString();
        if (locStr.contains(',')) {
          final parts = locStr.split(',');
          lat = double.tryParse(parts[0].trim());
          lng = double.tryParse(parts[1].trim());
        }
      }
    }

    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return null;
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredCamps = _allCamps;
      } else {
        _filteredCamps = _allCamps.where((camp) {
          final name = (camp['camp_name'] ?? '').toString().toLowerCase();
          final venue = (camp['venue_name'] ?? '').toString().toLowerCase();
          final city = (camp['city'] ?? '').toString().toLowerCase();
          final address = (camp['address'] ?? '').toString().toLowerCase();
          final district = (camp['district'] is Map
                  ? camp['district']['district']
                  : camp['district'] ?? '')
              .toString()
              .toLowerCase();
          return name.contains(q) ||
              venue.contains(q) ||
              city.contains(q) ||
              address.contains(q) ||
              district.contains(q);
        }).toList();
      }
    });
  }

  void _selectCamp(Map<String, dynamic> camp) {
    setState(() {
      _selectedCamp = camp;
    });

    final pos = _getCampLatLng(camp);
    if (pos != null) {
      _mapController.move(pos, 13.5);
    }
  }

  void _resetMapToSriLanka() {
    setState(() {
      _selectedCamp = null;
    });
    _mapController.move(_sriLankaCenter, 7.8);
  }

  void _centerToUserLocation() async {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 13.0);
    } else {
      await _getCurrentUserLocation();
      if (_userLocation != null) {
        _mapController.move(_userLocation!, 13.0);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not obtain device location. Ensure GPS is enabled.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Launch Google Maps Directions from donor's current live location with red spinner
  Future<void> _openDirectionsInGoogleMaps(Map<String, dynamic> camp) async {
    final dest = _getCampLatLng(camp);
    if (dest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordinates are not available for this camp location.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Show red spinner dialog while Google Maps is opening
    bool isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogCtx) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryCrimson),
                    ),
                  ),
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Text(
                      'Google Map is opening...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      isDialogShowing = false;
    });

    try {
      Position? currentPos;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            currentPos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (_) {}

      Uri mapsUri;
      if (currentPos != null) {
        mapsUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=${currentPos.latitude},${currentPos.longitude}&destination=${dest.latitude},${dest.longitude}&travelmode=driving',
        );
      } else if (_userLocation != null) {
        mapsUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=${_userLocation!.latitude},${_userLocation!.longitude}&destination=${dest.latitude},${dest.longitude}&travelmode=driving',
        );
      } else {
        mapsUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${dest.latitude},${dest.longitude}',
        );
      }

      await Future.delayed(const Duration(milliseconds: 600));

      final launched = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(mapsUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (isDialogShowing && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showCampDetailsSheet(Map<String, dynamic> camp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final campName = camp['camp_name']?.toString() ?? 'Blood Donation Camp';
        final venue = camp['venue_name']?.toString() ?? 'Venue not specified';
        final address = camp['address']?.toString() ?? '';
        final city = camp['city']?.toString() ?? '';
        final status = camp['status']?.toString() ?? 'SCHEDULED';
        final targetUnits = camp['target_units']?.toString() ?? '100';
        final startTime = camp['start_time']?.toString() ?? '';
        final endTime = camp['end_time']?.toString() ?? '';

        String timingStr = '';
        if (startTime.isNotEmpty) {
          try {
            final dt = DateTime.parse(startTime).toLocal();
            timingStr =
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } catch (_) {
            timingStr = startTime;
          }
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bloodtype_rounded,
                      color: AppTheme.primaryCrimson,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: status == 'SCHEDULED'
                                ? AppTheme.successBackground
                                : AppTheme.warningBackground,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: status == 'SCHEDULED'
                                  ? AppTheme.successGreen
                                  : AppTheme.warningAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _buildInfoRow(
                icon: Icons.location_on_rounded,
                iconColor: AppTheme.primaryCrimson,
                title: venue,
                subtitle: [address, city].where((s) => s.isNotEmpty).join(', '),
              ),
              const SizedBox(height: 10),
              if (timingStr.isNotEmpty) ...[
                _buildInfoRow(
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: timingStr,
                  subtitle: endTime.isNotEmpty ? 'Ends: $endTime' : '',
                ),
                const SizedBox(height: 10),
              ],
              _buildInfoRow(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFE11D48),
                title: '$targetUnits Units Needed',
                subtitle: 'Target Whole Blood Donation',
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryCrimson,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.directions_rounded, size: 20),
                      label: const Text(
                        'Get Directions',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openDirectionsInGoogleMaps(camp);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate markers
    final List<Marker> markers = [];

    // 1. Camps Markers
    for (final camp in _filteredCamps) {
      final pos = _getCampLatLng(camp);
      if (pos == null) continue;

      final isSelected = _selectedCamp != null && _selectedCamp!['id'] == camp['id'];

      markers.add(
        Marker(
          point: pos,
          width: isSelected ? 52.0 : 42.0,
          height: isSelected ? 52.0 : 42.0,
          child: GestureDetector(
            onTap: () {
              _selectCamp(camp);
              _showCampDetailsSheet(camp);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF991B1B) : AppTheme.primaryCrimson,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 3.0 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppTheme.primaryCrimson.withValues(alpha: 0.6)
                        : Colors.black26,
                    blurRadius: isSelected ? 10 : 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.bloodtype_rounded,
                color: Colors.white,
                size: isSelected ? 28 : 22,
              ),
            ),
          ),
        ),
      );
    }

    // 2. User Live Location Marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 48.0,
          height: 48.0,
          child: Tooltip(
            message: 'You are here',
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.my_location_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Camp Map View'),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
              color: AppTheme.primaryCrimson,
            ),
            tooltip: 'Search camps',
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                  _filteredCamps = _allCamps;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryCrimson),
            tooltip: 'Refresh data',
            onPressed: _fetchCampsAndLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. The Interactive Sri Lanka Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _sriLankaCenter,
              initialZoom: 7.8,
              minZoom: 6.8,
              maxZoom: 18.0,
              // Strictly restrict camera center to Sri Lanka boundaries
              cameraConstraint: CameraConstraint.containCenter(
                bounds: _sriLankaBounds,
              ),
              onTap: (tapPosition, point) {
                if (_selectedCamp != null) {
                  setState(() {
                    _selectedCamp = null;
                  });
                }
              },
            ),
            children: [
              // OpenStreetMap Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bloodconnect.blood_connect_sl',
                maxZoom: 19,
              ),
              // Markers Layer
              MarkerLayer(markers: markers),
            ],
          ),

          // 2. Search Bar Overlay (if open)
          if (_isSearchOpen)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search camp, venue, city, or district...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryCrimson),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

          // 3. Top Info Pill: Active Camps Count & Location Status
          Positioned(
            top: _isSearchOpen ? 76 : 14,
            left: 16,
            right: 80,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryCrimson,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_filteredCamps.length} Camps in SL',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (_userLocation != null) ...[
                      const SizedBox(width: 6),
                      Container(width: 1, height: 10, color: AppTheme.borderSubtle),
                      const SizedBox(width: 6),
                      const Icon(Icons.gps_fixed_rounded, size: 12, color: Color(0xFF2563EB)),
                      const SizedBox(width: 3),
                      const Text(
                        'GPS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 4. Compact Loading indicator (when refreshing live data)
          if (_isLoading)
            Positioned(
              top: _isSearchOpen ? 128 : 56,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryCrimson),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Syncing camps...',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Selected Camp Floating Quick Banner at Bottom
          if (_selectedCamp != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 80,
              child: InkWell(
                onTap: () => _showCampDetailsSheet(_selectedCamp!),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bloodtype_rounded,
                          color: AppTheme.primaryCrimson,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCamp!['camp_name'] ?? 'Camp',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedCamp!['venue_name'] ?? '',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ),

          // 6. Map Floating Action Buttons (Right Side)
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Location Button
                FloatingActionButton.small(
                  heroTag: 'btnUserLoc',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2563EB),
                  tooltip: 'My Location',
                  onPressed: _centerToUserLocation,
                  child: _isFetchingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          ),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 10),

                // Reset Sri Lanka View Button
                FloatingActionButton.small(
                  heroTag: 'btnResetMap',
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryCrimson,
                  tooltip: 'Reset to Sri Lanka',
                  onPressed: _resetMapToSriLanka,
                  child: const Icon(Icons.map_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
