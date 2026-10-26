import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class BloodCampsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialUserData;

  const BloodCampsScreen({
    super.key,
    this.initialUserData,
  });

  @override
  State<BloodCampsScreen> createState() => _BloodCampsScreenState();
}

class _BloodCampsScreenState extends State<BloodCampsScreen> {
  // Reference data
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];

  // Selected filters
  String? _selectedProvinceId;
  String? _selectedProvinceName;
  String? _selectedDistrictId;
  String? _selectedDistrictName;

  // Search
  final TextEditingController _searchController = TextEditingController();

  // Camp list & pagination
  List<Map<String, dynamic>> _camps = [];
  bool _isLoadingGeo = false;
  bool _isLoadingCamps = false;
  String? _errorMessage;

  int _currentPage = 1;
  final int _pageSize = 4; // Paginated in small chunks for easy page-by-page browsing
  int _totalCount = 0;
  int _totalPages = 1;

  // Track confirmed camp IDs for current donor
  final Set<String> _confirmedCampIds = {};
  bool _isConfirming = false;
  bool _isCancelling = false;

  String? get _donorIdentifier {
    final user = widget.initialUserData;
    if (user == null) return null;
    final donorId = user['donor_id']?.toString();
    if (donorId != null && donorId.isNotEmpty) return donorId;
    final userId = user['user_id']?.toString() ?? user['id']?.toString();
    if (userId != null && userId.isNotEmpty) return userId;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialGeoData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 1. Load Provinces and optional default province/district from user profile
  Future<void> _loadInitialGeoData() async {
    setState(() {
      _isLoadingGeo = true;
      _errorMessage = null;
    });

    try {
      final provinces = await ApiService.getProvinces();
      setState(() {
        _provinces = provinces;
        _isLoadingGeo = false;
      });

      // Check if user has an existing province in profile
      final userProvinceId = widget.initialUserData?['province_id']?.toString();
      final userDistrictId = widget.initialUserData?['district_id']?.toString();

      if (userProvinceId != null && userProvinceId.isNotEmpty) {
        final matchedProvince = _provinces.firstWhere(
          (p) => p['id']?.toString() == userProvinceId,
          orElse: () => {},
        );
        if (matchedProvince.isNotEmpty) {
          _onProvinceSelected(userProvinceId, matchedProvince['province']?.toString(), defaultDistrictId: userDistrictId);
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingGeo = false;
        _errorMessage = 'Failed to load reference regions: $e';
      });
    }
  }

  /// When Province changes
  Future<void> _onProvinceSelected(String? provinceId, String? provinceName, {String? defaultDistrictId}) async {
    setState(() {
      _selectedProvinceId = provinceId;
      _selectedProvinceName = provinceName;
      _selectedDistrictId = null;
      _selectedDistrictName = null;
      _districts = [];
      _camps = [];
      _totalCount = 0;
      _totalPages = 1;
      _currentPage = 1;
    });

    if (provinceId == null || provinceId.isEmpty) return;

    try {
      final districts = await ApiService.getDistricts(provinceId: provinceId);
      setState(() {
        _districts = districts;
      });

      // Auto-select district if passed from profile
      if (defaultDistrictId != null && defaultDistrictId.isNotEmpty) {
        final matchedDistrict = _districts.firstWhere(
          (d) => d['id']?.toString() == defaultDistrictId,
          orElse: () => {},
        );
        if (matchedDistrict.isNotEmpty) {
          _onDistrictSelected(defaultDistrictId, matchedDistrict['district']?.toString());
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load districts: $e')),
      );
    }
  }

  /// When District changes
  void _onDistrictSelected(String? districtId, String? districtName) {
    setState(() {
      _selectedDistrictId = districtId;
      _selectedDistrictName = districtName;
      _currentPage = 1;
    });
    _fetchCamps();
  }

  /// Fetch camps matching selected province, district, search text and page
  Future<void> _fetchCamps({int page = 1}) async {
    if (_selectedProvinceId == null && _selectedDistrictId == null) {
      setState(() {
        _camps = [];
        _totalCount = 0;
        _totalPages = 1;
      });
      return;
    }

    setState(() {
      _isLoadingCamps = true;
      _errorMessage = null;
      _currentPage = page;
    });

    try {
      final res = await ApiService.getBloodCamps(
        provinceId: _selectedProvinceId,
        districtId: _selectedDistrictId,
        search: _searchController.text.trim(),
        donorId: _donorIdentifier,
        page: _currentPage,
        limit: _pageSize,
      );

      final rawData = res['data'] as List<dynamic>? ?? [];
      final total = res['total'] is int
          ? res['total'] as int
          : (res['total'] is num ? (res['total'] as num).toInt() : rawData.length);
      final totalPages = res['total_pages'] is int
          ? res['total_pages'] as int
          : (total > 0 ? (total / _pageSize).ceil() : 1);

      setState(() {
        _camps = rawData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        for (final camp in _camps) {
          final campId = camp['id']?.toString();
          final status = camp['confirmation_status']?.toString();
          if (campId != null && status == 'confirmed') {
            _confirmedCampIds.add(campId);
          } else if (campId != null && status == 'cancelled') {
            _confirmedCampIds.remove(campId);
          }
        }
        _totalCount = total;
        _totalPages = totalPages > 0 ? totalPages : 1;
        _isLoadingCamps = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCamps = false;
        _errorMessage = 'Failed to load blood camps: $e';
      });
    }
  }

  /// Launch Google Maps Directions from donor's current live location with loading spinner
  Future<void> _openDirectionsInGoogleMaps(Map<String, dynamic> camp) async {
    double? destLat;
    double? destLng;

    // 1. Check geo_location json object
    final geo = camp['geo_location'];
    if (geo != null) {
      if (geo is Map) {
        destLat = (geo['lat'] is num) ? (geo['lat'] as num).toDouble() : double.tryParse('${geo['lat']}');
        destLng = (geo['lng'] is num) ? (geo['lng'] as num).toDouble() : double.tryParse('${geo['lng']}');
      } else if (geo is String && geo.isNotEmpty) {
        try {
          final decoded = jsonDecode(geo);
          if (decoded is Map) {
            destLat = double.tryParse('${decoded['lat']}');
            destLng = double.tryParse('${decoded['lng']}');
          }
        } catch (_) {}
      }
    }

    // 2. Check location string "lat,lng" fallback
    if (destLat == null || destLng == null) {
      final locStr = camp['location']?.toString();
      if (locStr != null && locStr.contains(',')) {
        final parts = locStr.split(',');
        destLat = double.tryParse(parts[0].trim());
        destLng = double.tryParse(parts[1].trim());
      }
    }

    if (destLat == null || destLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordinates are not available for this camp location.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Show red spinner dialog while Google Maps is loading
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
      // 3. Try to get donor's live phone GPS location
      Position? userPos;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            userPos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (_) {
        // Permission denied or timeout — fallback to opening destination directly in maps
      }

      // 4. Build Google Maps URL
      Uri mapsUri;
      if (userPos != null) {
        mapsUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=${userPos.latitude},${userPos.longitude}&destination=$destLat,$destLng&travelmode=driving',
        );
      } else {
        mapsUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$destLat,$destLng',
        );
      }

      // Small delay to allow the dialog animation and ensure smooth UX
      await Future.delayed(const Duration(milliseconds: 650));

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

  /// Show Full Camp Details Modal
  void _showCampDetailsModal(Map<String, dynamic> camp) {
    final campName = camp['camp_name'] ?? 'Blood Donation Camp';
    final venueName = camp['venue_name'] ?? 'Venue';
    final address = camp['address'] ?? '';
    final city = camp['city'] ?? '';
    final postalCode = camp['postal_code'] ?? '';
    final status = camp['status'] ?? 'SCHEDULED';
    final targetUnits = camp['target_units']?.toString() ?? '100';
    final targetUnitType = (camp['target_unit_type'] ?? 'WHOLE_BLOOD').toString().replaceAll('_', ' ');

    final startTimeStr = camp['start_time']?.toString();
    final endTimeStr = camp['end_time']?.toString();
    String formattedTime = 'Date & Time not specified';
    try {
      if (startTimeStr != null) {
        final start = DateTime.parse(startTimeStr).toLocal();
        final datePart = DateFormat('EEEE, dd MMMM yyyy').format(start);
        final startHour = DateFormat('hh:mm a').format(start);
        if (endTimeStr != null) {
          final end = DateTime.parse(endTimeStr).toLocal();
          final endHour = DateFormat('hh:mm a').format(end);
          formattedTime = '$datePart\n$startHour - $endHour';
        } else {
          formattedTime = '$datePart at $startHour';
        }
      }
    } catch (_) {}

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

    // Hospital / Org info
    final hospital = camp['hospital'] as Map<String, dynamic>?;
    final organization = camp['organization'] as Map<String, dynamic>?;
    final provinceObj = camp['province'] as Map<String, dynamic>?;
    final districtObj = camp['district'] as Map<String, dynamic>?;
    final campId = camp['id']?.toString() ?? '';

    // Check confirmation status in background if not known
    void Function(void Function())? modalSetStateFn;
    if (campId.isNotEmpty && _donorIdentifier != null) {
      ApiService.checkCampConfirmation(campId: campId, donorId: _donorIdentifier!).then((confirmed) {
        if (mounted) {
          setState(() {
            if (confirmed) {
              _confirmedCampIds.add(campId);
              camp['confirmation_status'] = 'confirmed';
            } else {
              _confirmedCampIds.remove(campId);
              if (camp['confirmation_status'] == 'confirmed') {
                camp['confirmation_status'] = 'cancelled';
              }
            }
          });
          modalSetStateFn?.call(() {});
        }
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            modalSetStateFn = setModalState;
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
                              const SizedBox(height: 8),
                              Text(
                                campName,
                                style: const TextStyle(
                                  fontSize: 20,
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
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

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
                                    fontSize: 14,
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

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
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
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
                                            fontSize: 14,
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
                                            fontSize: 14,
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
                          const SizedBox(height: 16),
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
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_rounded, size: 14, color: AppTheme.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        contactPerson['phone'].toString(),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (contactPerson['email'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.email_outlined, size: 14, color: AppTheme.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        contactPerson['email'].toString(),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

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
                                    final donorId = _donorIdentifier;
                                    if (campId.isEmpty || donorId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please log in with a valid donor profile to cancel participation.'),
                                          backgroundColor: AppTheme.errorRed,
                                        ),
                                      );
                                      return;
                                    }

                                    setModalState(() {
                                      _isCancelling = true;
                                    });

                                    try {
                                      await ApiService.cancelCampVisit(
                                        campId: campId,
                                        donorId: donorId,
                                      );

                                      if (!mounted) return;
                                      setModalState(() {
                                        _confirmedCampIds.remove(campId);
                                        _isCancelling = false;
                                      });
                                      setState(() {
                                        _confirmedCampIds.remove(campId);
                                        camp['confirmation_status'] = 'cancelled';
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
                                      setModalState(() {
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.errorRed,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    final donorId = _donorIdentifier;
                                    if (campId.isEmpty || donorId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please log in with a valid donor profile to confirm participation.'),
                                          backgroundColor: AppTheme.errorRed,
                                        ),
                                      );
                                      return;
                                    }

                                    setModalState(() {
                                      _isConfirming = true;
                                    });

                                    try {
                                      await ApiService.confirmCampVisit(
                                        campId: campId,
                                        donorId: donorId,
                                      );

                                      if (!mounted) return;
                                      setModalState(() {
                                        _confirmedCampIds.add(campId);
                                        _isConfirming = false;
                                      });
                                      setState(() {
                                        _confirmedCampIds.add(campId);
                                        camp['confirmation_status'] = 'confirmed';
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
                                      setModalState(() {
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryCrimson,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Blood Donation Camps'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Fixed Top Filter Area
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Notification/Instruction Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryCrimson.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.primaryCrimson, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select the province and district to see available camps',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Province & District Dropdowns Row
                if (_isLoadingGeo)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                else
                  Row(
                    children: [
                      // Province Dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedProvinceId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Province',
                            labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            prefixIcon: const Icon(Icons.map_outlined, size: 20, color: AppTheme.primaryCrimson),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          hint: const Text('Choose Province', style: TextStyle(fontSize: 13)),
                          items: _provinces.map((p) {
                            final id = p['id']?.toString() ?? '';
                            final name = p['province']?.toString() ?? 'Province';
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            final match = _provinces.firstWhere(
                              (p) => p['id']?.toString() == val,
                              orElse: () => {},
                            );
                            _onProvinceSelected(val, match['province']?.toString());
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      // District Dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDistrictId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'District',
                            labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            prefixIcon: const Icon(Icons.location_city_rounded, size: 20, color: AppTheme.primaryCrimson),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          hint: Text(
                            _selectedProvinceId == null ? 'Select Province' : 'Choose District',
                            style: const TextStyle(fontSize: 13),
                          ),
                          items: _districts.map((d) {
                            final id = d['id']?.toString() ?? '';
                            final name = d['district']?.toString() ?? 'District';
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                          onChanged: _selectedProvinceId == null
                              ? null
                              : (val) {
                                  final match = _districts.firstWhere(
                                    (d) => d['id']?.toString() == val,
                                    orElse: () => {},
                                  );
                                  _onDistrictSelected(val, match['district']?.toString());
                                },
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search camps by name, venue or city...',
                    hintStyle: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchCamps(page: 1);
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                  ),
                  onSubmitted: (_) => _fetchCamps(page: 1),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderSubtle),

          // Camps List & Pagination Body
          Expanded(
            child: _buildCampsBody(),
          ),

          // Pagination Bar (page 1, 2, 3...)
          if (_selectedProvinceId != null && _totalCount > 0)
            _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildCampsBody() {
    if (_selectedProvinceId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  size: 48,
                  color: AppTheme.primaryCrimson,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Explore Upcoming Camps',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select your province and district from the dropdowns above to see all available blood camps.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingCamps) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryCrimson),
            SizedBox(height: 14),
            Text(
              'Loading blood camps...',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.errorRed),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchCamps(page: _currentPage),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCrimson,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_camps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy_rounded, size: 54, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              const Text(
                'No Blood Camps Found',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty
                    ? 'No camps matched "${_searchController.text.trim()}". Try clearing search filters.'
                    : 'There are currently no scheduled blood donation drives in this district.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filterDescription = [
      if (_selectedDistrictName != null) _selectedDistrictName,
      if (_selectedProvinceName != null) '${_selectedProvinceName!} Province',
    ].join(', ');

    return Column(
      children: [
        if (filterDescription.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: Row(
              children: [
                const Icon(Icons.place_rounded, size: 16, color: AppTheme.primaryCrimson),
                const SizedBox(width: 6),
                Text(
                  'Showing camps in $filterDescription',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_totalCount found',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            itemCount: _camps.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final camp = _camps[index];
              return _buildCampCard(camp);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCampCard(Map<String, dynamic> camp) {
    final campName = camp['camp_name'] ?? 'Blood Donation Camp';
    final venueName = camp['venue_name'] ?? 'Venue';
    final city = camp['city'] ?? '';
    final targetUnits = camp['target_units']?.toString() ?? '100';
    final targetUnitType = (camp['target_unit_type'] ?? 'WHOLE_BLOOD').toString().replaceAll('_', ' ');

    String formattedDate = '';
    String formattedTime = '';
    final startTimeStr = camp['start_time']?.toString();
    final endTimeStr = camp['end_time']?.toString();
    try {
      if (startTimeStr != null) {
        final start = DateTime.parse(startTimeStr).toLocal();
        formattedDate = DateFormat('EEE, dd MMM yyyy').format(start);
        final startH = DateFormat('hh:mm a').format(start);
        if (endTimeStr != null) {
          final end = DateTime.parse(endTimeStr).toLocal();
          final endH = DateFormat('hh:mm a').format(end);
          formattedTime = '$startH - $endH';
        } else {
          formattedTime = startH;
        }
      }
    } catch (_) {}

    final hospital = camp['hospital'] as Map<String, dynamic>?;
    final organizerName = hospital?['name'] ?? (camp['organization'] as Map<String, dynamic>?)?['legal_name'];
    final campId = camp['id']?.toString() ?? '';
    final isConfirmed = _confirmedCampIds.contains(campId) || camp['confirmation_status'] == 'confirmed';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCampDetailsModal(camp),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Status badge & Target units
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.successGreen),
                            SizedBox(width: 4),
                            Text(
                              'SCHEDULED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.successGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isConfirmed) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 13, color: Color(0xFF15803D)),
                              SizedBox(width: 3),
                              Text(
                                'Participation Confirmed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$targetUnits Units Target',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryCrimson,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Camp Name
              Text(
                campName,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 8),

              // Venue & Location
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [venueName, if (city.isNotEmpty) city].join(', '),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Date & Time
              if (formattedDate.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '$formattedDate • $formattedTime',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

              if (organizerName != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        organizerName.toString(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              const SizedBox(height: 10),

              // Footer: Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unit: $targetUnitType',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0284C7),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _openDirectionsInGoogleMaps(camp),
                        icon: const Icon(Icons.directions_rounded, size: 17),
                        label: const Text('Directions', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryCrimson,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showCampDetailsModal(camp),
                        icon: const Icon(Icons.info_outline_rounded, size: 17),
                        label: const Text('Details', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Page-wise Pagination Bar with 1, 2, 3 buttons
  Widget _buildPaginationBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Prev Button
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _currentPage > 1
                  ? () => _fetchCamps(page: _currentPage - 1)
                  : null,
            ),

            // Numbered Page Buttons
            Row(
              children: List.generate(_totalPages, (i) {
                final pageNum = i + 1;
                final isCurrent = pageNum == _currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _fetchCamps(page: pageNum),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrent ? AppTheme.primaryCrimson : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent
                            ? null
                            : Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Text(
                        '$pageNum',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Next Button
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _currentPage < _totalPages
                  ? () => _fetchCamps(page: _currentPage + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
