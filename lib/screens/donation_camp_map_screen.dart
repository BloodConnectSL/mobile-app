import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
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
      'target_unit_type': 'WHOLE_BLOOD',
      'location': '6.9147,79.8653',
      'geo_location': {'lat': 6.9147, 'lng': 79.8653},
      'start_time': '2026-11-10T09:00:00+05:30',
      'end_time': '2026-11-10T17:00:00+05:30',
      'district': {'district': 'Colombo'},
      'province': {'province': 'Western'},
      'preferred_blood_types': ['A+', 'B+', 'O+', 'AB+', 'O-', 'A-', 'B-', 'AB-'],
      'contact_person': {
        'name': 'Dr. Anura Jayasinghe',
        'phone': '+94771234567',
        'email': 'anura.j@redcross.lk',
      },
    },
    {
      'id': 'bae86081-9f7a-41e1-8ee0-4a3489c88de1',
      'camp_name': 'Youth For Life Blood Campaign - BMICH',
      'venue_name': 'BMICH Exhibition Hall B',
      'address': 'Bauddhaloka Mawatha, Colombo 07',
      'city': 'Colombo',
      'status': 'SCHEDULED',
      'target_units': 180,
      'target_unit_type': 'WHOLE_BLOOD',
      'location': '6.9010,79.8735',
      'geo_location': {'lat': 6.9010, 'lng': 79.8735},
      'start_time': '2026-11-12T09:00:00+05:30',
      'end_time': '2026-11-12T16:00:00+05:30',
      'district': {'district': 'Colombo'},
      'province': {'province': 'Western'},
      'preferred_blood_types': ['A+', 'B+', 'O+', 'AB+'],
      'contact_person': {
        'name': 'Rtr. Kavindu Perera',
        'phone': '+94773456789',
        'email': 'kavindu@rotaract3220.org',
      },
    },
    {
      'id': '37f783ba-af7c-475a-8533-04c4f5d8d3a3',
      'camp_name': 'Negombo Coastal Community Blood Camp',
      'venue_name': 'Negombo Municipal Council Ground Hall',
      'address': 'Beach Road, Negombo',
      'city': 'Gampaha',
      'status': 'SCHEDULED',
      'target_units': 120,
      'target_unit_type': 'WHOLE_BLOOD',
      'location': '7.2088,79.8358',
      'geo_location': {'lat': 7.2088, 'lng': 79.8358},
      'start_time': '2026-11-04T09:00:00+05:30',
      'end_time': '2026-11-04T15:00:00+05:30',
      'district': {'district': 'Gampaha'},
      'province': {'province': 'Western'},
      'preferred_blood_types': ['A+', 'B+', 'O+', 'AB+'],
      'contact_person': {
        'name': 'Rotarian Sunil Fernando',
        'phone': '+94712223344',
        'email': 'sunil@rotarycolombo.org',
      },
    },
    {
      'id': 'c37f9ece-bbf9-4a76-929e-5b66950c6f56',
      'camp_name': 'Kandy Hills Annual Blood Drive',
      'venue_name': 'Kandy City Centre Level 3 Auditorium',
      'address': 'Dalada Veediya, Kandy',
      'city': 'Kandy',
      'status': 'SCHEDULED',
      'target_units': 250,
      'target_unit_type': 'WHOLE_BLOOD',
      'location': '7.2936,80.6350',
      'geo_location': {'lat': 7.2936, 'lng': 80.6350},
      'start_time': '2026-11-08T09:00:00+05:30',
      'end_time': '2026-11-08T17:00:00+05:30',
      'district': {'district': 'Kandy'},
      'province': {'province': 'Central'},
      'preferred_blood_types': ['A+', 'B+', 'O+', 'AB+'],
      'contact_person': {
        'name': 'Lion Dr. Mahesh Bandara',
        'phone': '+94778901234',
        'email': 'mahesh.b@lionsdist306.lk',
      },
    },
    {
      'id': '512cbf61-8748-4c9a-b74c-66066fa6eae8',
      'camp_name': 'Southern Pearl Blood Donation Drive',
      'venue_name': 'Galle Fort Community Center',
      'address': 'Church Street, Galle Fort',
      'city': 'Galle',
      'status': 'SCHEDULED',
      'target_units': 150,
      'target_unit_type': 'WHOLE_BLOOD',
      'location': '6.0329,80.2168',
      'geo_location': {'lat': 6.0329, 'lng': 80.2168},
      'start_time': '2026-11-14T09:00:00+05:30',
      'end_time': '2026-11-14T15:00:00+05:30',
      'district': {'district': 'Galle'},
      'province': {'province': 'Southern'},
      'preferred_blood_types': ['A+', 'B+', 'O+', 'AB+'],
      'contact_person': {
        'name': 'Chathura De Silva',
        'phone': '+94765432100',
        'email': 'chathura@sarvodaya.org',
      },
    },
    {
      'id': '9bf1cdba-d9d7-459c-b833-66f450deab30',
      'camp_name': 'Northern Hope Blood Camp - Jaffna',
      'venue_name': 'Jaffna Central College Memorial Hall',
      'address': 'Central College Road, Jaffna',
      'city': 'Jaffna',
      'status': 'SCHEDULED',
      'target_units': 140,
      'target_unit_type': 'WHOLE_BLOOD',
      'location': '9.6647,80.0167',
      'geo_location': {'lat': 9.6647, 'lng': 80.0167},
      'start_time': '2026-11-18T09:00:00+05:30',
      'end_time': '2026-11-18T16:00:00+05:30',
      'district': {'district': 'Jaffna'},
      'province': {'province': 'Northern'},
      'preferred_blood_types': ['A+', 'B+', 'O+', 'AB+'],
      'contact_person': {
        'name': 'Leo Tharmalingam Sivakumar',
        'phone': '+94776543219',
        'email': 'sivakumar@leo306a1.lk',
      },
    },
    {
      'id': '01697996-1d11-41cf-ba10-2a06112ee616',
      'camp_name': 'Rajarata Life Saver Camp - Anuradhapura',
      'venue_name': 'Public Library Hall, Anuradhapura',
      'address': 'Main Street, Anuradhapura',
      'city': 'Anuradhapura',
      'status': 'SCHEDULED',
      'target_units': 160,
      'target_unit_type': 'WHOLE_BLOOD',
      'location': '8.3314,80.4037',
      'geo_location': {'lat': 8.3314, 'lng': 80.4037},
      'start_time': '2026-11-20T09:00:00+05:30',
      'end_time': '2026-11-20T17:00:00+05:30',
      'district': {'district': 'Anuradhapura'},
      'province': {'province': 'North Central'},
      'preferred_blood_types': ['A+', 'B+', 'O+', 'AB+'],
      'contact_person': {
        'name': 'Scout Leader Nimal Rathnayake',
        'phone': '+94718889900',
        'email': 'nimal@slscout.org',
      },
    },
    {
      'id': '3b7f3488-76d2-4419-a0a8-6a6fe10f8a96',
      'camp_name': 'Wayamba Regional Blood Camp - Kurunegala',
      'venue_name': 'Kurunegala Town Hall Auditorium',
      'address': 'Negombo Road, Kurunegala',
      'city': 'Kurunegala',
      'status': 'SCHEDULED',
      'target_units': 130,
      'target_unit_type': 'WHOLE_BLOOD',
      'location': '7.4863,80.3623',
      'geo_location': {'lat': 7.4863, 'lng': 80.3623},
      'start_time': '2026-11-22T09:00:00+05:30',
      'end_time': '2026-11-22T15:00:00+05:30',
      'district': {'district': 'Kurunegala'},
      'province': {'province': 'North Western'},
      'preferred_blood_types': ['A+', 'B+', 'O+', 'AB+'],
      'contact_person': {
        'name': 'Priyantha Alwis',
        'phone': '+94779991122',
        'email': 'priyantha@ymcasrilanka.org',
      },
    },
    {
      'id': '4e306b51-f2df-4104-963d-3508ba7297ab',
      'camp_name': 'Eastern Sunshine Blood Drive - Batticaloa',
      'venue_name': 'Batticaloa Municipal Pavilion',
      'address': 'Bar Road, Batticaloa',
      'city': 'Batticaloa',
      'status': 'SCHEDULED',
      'target_units': 120,
      'target_unit_type': 'WHOLE_BLOOD',
      'location': '7.7170,81.7000',
      'geo_location': {'lat': 7.7170, 'lng': 81.7000},
      'start_time': '2026-11-25T09:00:00+05:30',
      'end_time': '2026-11-25T16:00:00+05:30',
      'district': {'district': 'Batticaloa'},
      'province': {'province': 'Eastern'},
      'preferred_blood_types': ['A+', 'B+', 'O+', 'AB+'],
      'contact_person': {
        'name': 'Mohamed Rameez',
        'phone': '+94754443322',
        'email': 'rameez@redcrescent.lk',
      },
    },
    {
      'id': '28633cc7-799c-40f2-b425-23919891dc34',
      'camp_name': 'Uva Highlands Emergency Blood Drive - Badulla',
      'venue_name': 'Badulla Simon Pieris Memorial Hall',
      'address': 'Lower Street, Badulla',
      'city': 'Badulla',
      'status': 'SCHEDULED',
      'target_units': 150,
      'target_unit_type': 'WHOLE_BLOOD',
      'location': '6.9934,81.0550',
      'geo_location': {'lat': 6.9934, 'lng': 81.0550},
      'start_time': '2026-11-28T09:00:00+05:30',
      'end_time': '2026-11-28T17:00:00+05:30',
      'district': {'district': 'Badulla'},
      'province': {'province': 'Uva'},
      'preferred_blood_types': ['A+', 'B+', 'O+', 'AB+'],
      'contact_person': {
        'name': 'Officer Damith Jayakody',
        'phone': '+94772221199',
        'email': 'damith@stjohn.lk',
      },
    },
  ];

  // State
  bool _isLoading = true;
  List<Map<String, dynamic>> _allCamps = [];
  List<Map<String, dynamic>> _filteredCamps = [];
  Map<String, dynamic>? _selectedCamp;

  // Track Confirmed Camps for this donor
  final Set<String> _confirmedCampIds = {};
  bool _isConfirming = false;
  bool _isCancelling = false;

  // Donor Current Location
  LatLng? _userLocation;
  bool _isFetchingLocation = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  String? get _donorIdentifier {
    final user = widget.userData;
    final donorId = user['donor_id']?.toString();
    if (donorId != null && donorId.isNotEmpty) return donorId;
    final userId = user['user_id']?.toString() ?? user['id']?.toString();
    if (userId != null && userId.isNotEmpty) return userId;
    return null;
  }

  /// Only show camps that have not ended yet:
  /// - End date is after today: show camp
  /// - End date is today and end time is after current time: show camp
  /// - Do not show ended, completed or cancelled camps
  bool _isCampActive(Map<String, dynamic> camp) {
    final status = (camp['status'] ?? '').toString().toUpperCase();
    if (status == 'COMPLETED' || status == 'CANCELLED') {
      return false;
    }

    final endTimeStr = camp['end_time']?.toString();
    if (endTimeStr != null && endTimeStr.isNotEmpty) {
      try {
        final endTime = DateTime.parse(endTimeStr).toLocal();
        final now = DateTime.now();
        if (!endTime.isAfter(now)) {
          return false;
        }
      } catch (_) {}
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    // Pre-populate with fallback active camps so pins appear immediately
    _allCamps = _fallbackCamps.where((camp) => _isCampActive(camp)).toList();
    _filteredCamps = List.from(_allCamps);

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

    // 1. Fetch live camps from backend with donor ID to resolve confirmation status
    try {
      final res = await ApiService.getBloodCamps(
        limit: 100,
        donorId: _donorIdentifier,
      ).timeout(
        const Duration(seconds: 5),
      );
      final rawData = res['data'] as List<dynamic>? ?? [];
      final parsed = rawData
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((camp) => _isCampActive(camp) && _getCampLatLng(camp) != null)
          .toList();

      if (parsed.isNotEmpty && mounted) {
        setState(() {
          _allCamps = parsed;
          _filteredCamps = parsed;
          for (final camp in _allCamps) {
            final campId = camp['id']?.toString();
            final status = camp['confirmation_status']?.toString();
            if (campId != null && status == 'confirmed') {
              _confirmedCampIds.add(campId);
            }
          }
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
        _filteredCamps = _allCamps.where((camp) => _isCampActive(camp)).toList();
      } else {
        _filteredCamps = _allCamps.where((camp) {
          if (!_isCampActive(camp)) return false;
          final name = (camp['camp_name'] ?? '').toString().toLowerCase();
          final venue = (camp['venue_name'] ?? '').toString().toLowerCase();
          final city = (camp['city'] ?? '').toString().toLowerCase();
          final address = (camp['address'] ?? '').toString().toLowerCase();
          final district = (camp['district'] is Map
                  ? camp['district']['district']
                  : camp['district'] ?? '')
              .toString()
              .toLowerCase();
          final province = (camp['province'] is Map
                  ? camp['province']['province']
                  : camp['province'] ?? '')
              .toString()
              .toLowerCase();
          return name.contains(q) ||
              venue.contains(q) ||
              city.contains(q) ||
              address.contains(q) ||
              district.contains(q) ||
              province.contains(q);
        }).toList();
      }
    });
  }

  void _selectCamp(Map<String, dynamic> camp) {
    setState(() {
      _selectedCamp = camp;
    });

    final campId = camp['id']?.toString();
    if (campId != null && _donorIdentifier != null) {
      _checkConfirmationStatus(campId);
    }

    final pos = _getCampLatLng(camp);
    if (pos != null) {
      _mapController.move(pos, 13.5);
    }
  }

  void _checkConfirmationStatus(String campId) {
    if (campId.isEmpty || _donorIdentifier == null) return;
    ApiService.checkCampConfirmation(campId: campId, donorId: _donorIdentifier!).then((confirmed) {
      if (mounted) {
        setState(() {
          if (confirmed) {
            _confirmedCampIds.add(campId);
            if (_selectedCamp != null && _selectedCamp!['id'] == campId) {
              _selectedCamp!['confirmation_status'] = 'confirmed';
            }
          } else {
            _confirmedCampIds.remove(campId);
            if (_selectedCamp != null && _selectedCamp!['id'] == campId && _selectedCamp!['confirmation_status'] == 'confirmed') {
              _selectedCamp!['confirmation_status'] = 'cancelled';
            }
          }
        });
      }
    });
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

  /// Confirm Participation
  Future<void> _handleConfirmParticipation(
    Map<String, dynamic> camp, [
    StateSetter? setModalState,
  ]) async {
    final donorId = _donorIdentifier;
    final campId = camp['id']?.toString() ?? '';
    final campName = camp['camp_name']?.toString() ?? 'Blood Donation Camp';

    if (campId.isEmpty || donorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in with a valid donor profile to confirm participation.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setModalState?.call(() {
      _isConfirming = true;
    });
    setState(() {
      _isConfirming = true;
    });

    try {
      await ApiService.confirmCampVisit(
        campId: campId,
        donorId: donorId,
      );

      if (!mounted) return;
      _confirmedCampIds.add(campId);
      camp['confirmation_status'] = 'confirmed';

      setModalState?.call(() {
        _isConfirming = false;
      });
      setState(() {
        _isConfirming = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Participation confirmed for $campName!'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setModalState?.call(() {
        _isConfirming = false;
      });
      setState(() {
        _isConfirming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm participation: $e'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Cancel Participation
  Future<void> _handleCancelParticipation(
    Map<String, dynamic> camp, [
    StateSetter? setModalState,
  ]) async {
    final donorId = _donorIdentifier;
    final campId = camp['id']?.toString() ?? '';
    final campName = camp['camp_name']?.toString() ?? 'Blood Donation Camp';

    if (campId.isEmpty || donorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in with a valid donor profile to cancel participation.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setModalState?.call(() {
      _isCancelling = true;
    });
    setState(() {
      _isCancelling = true;
    });

    try {
      await ApiService.cancelCampVisit(
        campId: campId,
        donorId: donorId,
      );

      if (!mounted) return;
      _confirmedCampIds.remove(campId);
      camp['confirmation_status'] = 'cancelled';

      setModalState?.call(() {
        _isCancelling = false;
      });
      setState(() {
        _isCancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Participation cancelled for $campName'),
          backgroundColor: AppTheme.warningAmber,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setModalState?.call(() {
        _isCancelling = false;
      });
      setState(() {
        _isCancelling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel participation: $e'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  String _formatCampTime(String? startStr, String? endStr) {
    if (startStr == null || startStr.isEmpty) return 'Date & Time not specified';
    try {
      final start = DateTime.parse(startStr).toLocal();
      final datePart = DateFormat('EEEE, dd MMMM yyyy').format(start);
      final startHour = DateFormat('hh:mm a').format(start);
      if (endStr != null && endStr.isNotEmpty) {
        final end = DateTime.parse(endStr).toLocal();
        final endHour = DateFormat('hh:mm a').format(end);
        return '$datePart\n$startHour - $endHour';
      }
      return '$datePart at $startHour';
    } catch (_) {
      return startStr;
    }
  }

  /// Show Full Camp Details Modal matching province & district filtering section
  void _showCampFullDetailsModal(Map<String, dynamic> camp) {
    final campName = camp['camp_name']?.toString() ?? 'Blood Donation Camp';
    final venueName = camp['venue_name']?.toString() ?? 'Venue not specified';
    final address = camp['address']?.toString() ?? '';
    final city = camp['city']?.toString() ?? '';
    final postalCode = camp['postal_code']?.toString() ?? '';
    final status = camp['status']?.toString() ?? 'SCHEDULED';
    final targetUnits = camp['target_units']?.toString() ?? '100';
    final targetUnitType = (camp['target_unit_type'] ?? 'WHOLE_BLOOD').toString().replaceAll('_', ' ');

    final startTimeStr = camp['start_time']?.toString();
    final endTimeStr = camp['end_time']?.toString();
    final formattedTime = _formatCampTime(startTimeStr, endTimeStr);

    // Hospital / Org info
    final hospital = camp['hospital'] as Map<String, dynamic>?;
    final organization = camp['organization'] as Map<String, dynamic>?;
    final provinceObj = camp['province'] as Map<String, dynamic>?;
    final districtObj = camp['district'] as Map<String, dynamic>?;
    final campId = camp['id']?.toString() ?? '';

    // Contact person info
    Map<String, dynamic>? contactPerson;
    final cp = camp['contact_person'];
    if (cp is Map) {
      contactPerson = Map<String, dynamic>.from(cp);
    } else if (cp is String && cp.isNotEmpty) {
      try {
        contactPerson = Map<String, dynamic>.from(jsonDecode(cp));
      } catch (_) {}
    }

    // Preferred blood types
    List<String> bloodTypes = [];
    final pbt = camp['preferred_blood_types'];
    if (pbt is List) {
      bloodTypes = pbt.map((e) => e.toString()).toList();
    } else if (pbt is String && pbt.isNotEmpty) {
      try {
        final decoded = jsonDecode(pbt);
        if (decoded is List) {
          bloodTypes = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isConfirmed = _confirmedCampIds.contains(campId) || camp['confirmation_status'] == 'confirmed';

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
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
                  child: Column(
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: status == 'SCHEDULED'
                                              ? AppTheme.successBackground
                                              : AppTheme.warningBackground,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: status == 'SCHEDULED'
                                                ? AppTheme.successGreen
                                                : AppTheme.warningAmber,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      if (isConfirmed) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppTheme.successGreen),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.successGreen),
                                              SizedBox(width: 4),
                                              Text(
                                                'Confirmed',
                                                style: TextStyle(
                                                  color: AppTheme.successGreen,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    campName,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Body Content
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          children: [
                            // Date & Time Box
                            _buildDetailSection(
                              icon: Icons.calendar_month_rounded,
                              iconColor: AppTheme.primaryCrimson,
                              title: 'Date & Timing',
                              child: Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Venue & Location
                            _buildDetailSection(
                              icon: Icons.location_on_rounded,
                              iconColor: const Color(0xFF0284C7),
                              title: 'Venue & Location',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    venueName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (address.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      address,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (city.isNotEmpty) city,
                                      if (districtObj?['district'] != null) districtObj!['district'],
                                      if (provinceObj?['province'] != null) '${provinceObj!['province']} Province',
                                      if (postalCode.isNotEmpty) 'Postal: $postalCode',
                                    ].join(' • '),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Target Units & Needs
                            _buildDetailSection(
                              icon: Icons.water_drop_rounded,
                              iconColor: AppTheme.primaryCrimson,
                              title: 'Collection Target',
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.favorite_rounded, size: 18, color: AppTheme.primaryCrimson),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$targetUnits Units Target',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primaryCrimson,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Chip(
                                    label: Text(targetUnitType),
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    labelStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (bloodTypes.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _buildDetailSection(
                                icon: Icons.bloodtype_rounded,
                                iconColor: const Color(0xFFDC2626),
                                title: 'Preferred Blood Types',
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: bloodTypes.map((bt) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.borderSubtle),
                                      ),
                                      child: Text(
                                        bt,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppTheme.primaryCrimson,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],

                            // Hospital & Organizers
                            if (hospital != null || organization != null) ...[
                              const SizedBox(height: 14),
                              _buildDetailSection(
                                icon: Icons.local_hospital_rounded,
                                iconColor: const Color(0xFF16A34A),
                                title: 'Organizing Partners',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (hospital != null) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.business_rounded, size: 16, color: AppTheme.textSecondary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              hospital['name'] ?? 'Associated Hospital',
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    if (organization != null) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.groups_rounded, size: 16, color: AppTheme.textSecondary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              organization['legal_name'] ?? 'Supporting Organization',
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            // Contact Person
                            if (contactPerson != null) ...[
                              const SizedBox(height: 14),
                              _buildDetailSection(
                                icon: Icons.person_pin_rounded,
                                iconColor: const Color(0xFF8B5CF6),
                                title: 'Camp Coordinator',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (contactPerson['name'] != null)
                                      Text(
                                        contactPerson['name'].toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    if (contactPerson['phone'] != null) ...[
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () {
                                          final phone = contactPerson?['phone'].toString();
                                          if (phone != null) {
                                            launchUrl(Uri.parse('tel:$phone'));
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(Icons.phone_rounded, size: 15, color: Color(0xFF2563EB)),
                                            const SizedBox(width: 6),
                                            Text(
                                              contactPerson['phone'].toString(),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (contactPerson['email'] != null) ...[
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () {
                                          final email = contactPerson?['email'].toString();
                                          if (email != null) {
                                            launchUrl(Uri.parse('mailto:$email'));
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(Icons.email_outlined, size: 15, color: Color(0xFF2563EB)),
                                            const SizedBox(width: 6),
                                            Text(
                                              contactPerson['email'].toString(),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 22),

                            // Confirm / Cancel Participation Action Buttons
                            if (isConfirmed) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.successBackground,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      'Participation Confirmed',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.successGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _isCancelling
                                    ? null
                                    : () async {
                                        await _handleCancelParticipation(camp, setModalState);
                                      },
                                icon: _isCancelling
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.errorRed,
                                        ),
                                      )
                                    : const Icon(Icons.cancel_outlined, size: 22, color: AppTheme.errorRed),
                                label: Text(
                                  _isCancelling ? 'Cancelling...' : 'Cancel Participation',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.errorRed,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ] else ...[
                              ElevatedButton.icon(
                                onPressed: _isConfirming
                                    ? null
                                    : () async {
                                        await _handleConfirmParticipation(camp, setModalState);
                                      },
                                icon: _isConfirming
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.how_to_reg_rounded, size: 22),
                                label: Text(
                                  _isConfirming ? 'Confirming...' : 'Confirm Participation',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Prominent Google Maps Live Directions Button
                            ElevatedButton.icon(
                              onPressed: () {
                                _openDirectionsInGoogleMaps(camp);
                              },
                              icon: const Icon(Icons.directions_rounded, size: 22),
                              label: const Text(
                                'Get Live Directions (Google Maps)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryCrimson,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  /// Builds the rich "At-A-Glance" Card shown at the bottom when a camp marker is tapped
  Widget _buildAtAGlanceCard(Map<String, dynamic> camp) {
    final campName = camp['camp_name']?.toString() ?? 'Blood Donation Camp';
    final venue = camp['venue_name']?.toString() ?? 'Venue';
    final city = camp['city']?.toString() ?? '';
    final status = camp['status']?.toString() ?? 'SCHEDULED';
    final targetUnits = camp['target_units']?.toString() ?? '100';
    final startTime = camp['start_time']?.toString() ?? '';
    final endTime = camp['end_time']?.toString() ?? '';
    final campId = camp['id']?.toString() ?? '';

    final isConfirmed = _confirmedCampIds.contains(campId) || camp['confirmation_status'] == 'confirmed';

    String timingSummary = '';
    if (startTime.isNotEmpty) {
      try {
        final dt = DateTime.parse(startTime).toLocal();
        final startPart = DateFormat('EEE, dd MMM • hh:mm a').format(dt);
        if (endTime.isNotEmpty) {
          final endDt = DateTime.parse(endTime).toLocal();
          final endPart = DateFormat('hh:mm a').format(endDt);
          timingSummary = '$startPart - $endPart';
        } else {
          timingSummary = startPart;
        }
      } catch (_) {
        timingSummary = startTime;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? const Color(0xFFDCFCE7)
                      : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isConfirmed ? Icons.how_to_reg_rounded : Icons.bloodtype_rounded,
                  color: isConfirmed ? AppTheme.successGreen : AppTheme.primaryCrimson,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: status == 'SCHEDULED'
                                ? AppTheme.successBackground
                                : AppTheme.warningBackground,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: status == 'SCHEDULED'
                                  ? AppTheme.successGreen
                                  : AppTheme.warningAmber,
                            ),
                          ),
                        ),
                        if (isConfirmed) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.successGreen),
                            ),
                            child: const Text(
                              'Confirmed',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.successGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      campName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [venue, city].where((s) => s.isNotEmpty).join(', '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                onPressed: () {
                  setState(() {
                    _selectedCamp = null;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Details badges
          Row(
            children: [
              if (timingSummary.isNotEmpty) ...[
                const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    timingSummary,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$targetUnits Units',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.errorRed,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Confirm / Cancel Action at a glance
          if (isConfirmed) ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Participation Confirmed',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _isCancelling
                      ? null
                      : () => _handleCancelParticipation(camp),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    side: const BorderSide(color: AppTheme.errorRed),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.errorRed),
                        )
                      : const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConfirming
                    ? null
                    : () => _handleConfirmParticipation(camp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 1,
                ),
                icon: _isConfirming
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.how_to_reg_rounded, size: 18),
                label: Text(
                  _isConfirming ? 'Confirming...' : 'Confirm Participation',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Directions & Full Details buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDirectionsInGoogleMaps(camp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCrimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text(
                    'Directions',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCampFullDetailsModal(camp),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderSubtle, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2563EB)),
                  label: const Text(
                    'Full Details',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
      final campId = camp['id']?.toString() ?? '';
      final isConfirmed = _confirmedCampIds.contains(campId) || camp['confirmation_status'] == 'confirmed';

      markers.add(
        Marker(
          point: pos,
          width: isSelected ? 52.0 : 44.0,
          height: isSelected ? 52.0 : 44.0,
          child: GestureDetector(
            onTap: () {
              _selectCamp(camp);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? const Color(0xFF059669)
                        : (isSelected ? const Color(0xFF991B1B) : AppTheme.primaryCrimson),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: isSelected ? 3.0 : 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isConfirmed
                            ? const Color(0xFF059669).withValues(alpha: 0.5)
                            : (isSelected
                                ? AppTheme.primaryCrimson.withValues(alpha: 0.6)
                                : Colors.black26),
                        blurRadius: isSelected ? 10 : 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isConfirmed ? Icons.how_to_reg_rounded : Icons.bloodtype_rounded,
                      color: Colors.white,
                      size: isSelected ? 26 : 22,
                    ),
                  ),
                ),
                if (isConfirmed)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ),
              ],
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

          // 5. Selected Camp At-a-Glance Card at Bottom
          if (_selectedCamp != null)
            Positioned(
              bottom: 20,
              left: 14,
              right: 14,
              child: _buildAtAGlanceCard(_selectedCamp!),
            ),

          // 6. Map Floating Action Buttons (Right Side, above the card if visible)
          Positioned(
            right: 16,
            bottom: _selectedCamp != null ? 230 : 24,
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
