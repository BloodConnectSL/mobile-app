import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';

typedef Json = Map<String, dynamic>;

class ManagementScreen extends StatefulWidget {
  final Json userData;
  const ManagementScreen({super.key, required this.userData});
  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  String _page = 'Overview';
  bool _loading = true;
  String? _error;
  List<dynamic> _rows = [];
  Json _overview = {}, _membership = {};
  List<dynamic> _hospitals = [], _organizations = [], _users = [], _types = [];
  String get _role => widget.userData['role']?.toString() ?? '';
  bool get _system => _role == 'SYSTEM_ADMIN' || _role == 'PLATFORM_ADMIN';
  bool get _superadmin => _role == 'SYSTEM_ADMIN';
  List<String> get _pages => [
    'Overview',
    'Camps',
    'People',
    if (_system) ...['Hospitals', 'Organizations'],
    if (_system || _role == 'HOSPITAL_ADMIN') ...['Inventory', 'Requests'],
    if (_system) ...['Audit', 'Deletion requests'],
  ];
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final results = await Future.wait([
        ApiService.getCurrentUser(),
        ApiService.management('/manage/hospitals'),
        ApiService.management('/manage/organizations'),
        ApiService.management('/manage/users'),
        ApiService.getBloodTypes(),
      ]);
      _membership = Json.from((results[0] as Json)['membership'] as Map);
      _hospitals = (results[1] as Json)['data'] as List<dynamic>? ?? [];
      _organizations = (results[2] as Json)['data'] as List<dynamic>? ?? [];
      _users = (results[3] as Json)['data'] as List<dynamic>? ?? [];
      _types = results[4] as List<dynamic>;
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    await _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final path = _page == 'Overview'
          ? '/manage/overview'
          : _page == 'People'
          ? '/manage/users'
          : _page == 'Deletion requests'
          ? '/manage/deletion-requests'
          : _page == 'Audit'
          ? '/manage/audit'
          : '/manage/${_page.toLowerCase()}';
      final result = await ApiService.management(path);
      if (mounted) {
        setState(() {
          if (_page == 'Overview') {
            _overview = Json.from(result['data'] as Map);
          } else {
            _rows = result['data'] as List<dynamic>? ?? [];
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _mutate(
    String path,
    Json data, {
    String method = 'PATCH',
  }) async {
    try {
      await ApiService.management(path, method: method, body: data);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Changes saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Map<String, String> _options(List<dynamic> rows, String field) => {
    for (final r in rows)
      r['id'].toString(): (r[field] ?? r['username'] ?? r['id']).toString(),
  };
  Future<void> _form(
    String title,
    List<_Input> fields,
    Future<void> Function(Json) submit, {
    Json initial = const {},
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EditScreen(
          title: title,
          fields: fields,
          initial: initial,
          submit: submit,
        ),
      ),
    );
    if (mounted) await _initialize();
  }

  Future<void> _campForm([Json? row]) async {
    final fields = [
      _Input('camp_name', 'Camp name'),
      _Input('venue_name', 'Venue'),
      _Input('address', 'Address'),
      _Input('city', 'City'),
      _Input('start_time', 'Starts', date: true),
      _Input('end_time', 'Ends', date: true),
      _Input('target_units', 'Target donations', number: true),
      _Input('latitude', 'Latitude', number: true),
      _Input('longitude', 'Longitude', number: true),
      if (_system)
        _Input(
          'org_id',
          'Organization',
          options: _options(_organizations, 'legal_name'),
          required: false,
        ),
      if (_system || _role == 'ORG_ADMIN')
        _Input(
          'hospital_id',
          'Partner hospital',
          options: _options(_hospitals, 'name'),
          required: false,
        ),
    ];
    final initial = row == null
        ? <String, dynamic>{}
        : {
            ...row,
            'latitude': row['geo_location']?['lat'],
            'longitude': row['geo_location']?['lng'],
          };
    await _form(row == null ? 'Create camp' : 'Edit camp', fields, (
      data,
    ) async {
      final payload = {
        ...data,
        'org_id': data['org_id'] ?? _membership['OrgID'],
        'hospital_id': data['hospital_id'] ?? _membership['HospitalID'],
        'start_time': DateTime.parse(
          data['start_time'].toString(),
        ).toUtc().toIso8601String(),
        'end_time': DateTime.parse(
          data['end_time'].toString(),
        ).toUtc().toIso8601String(),
        'target_units': int.parse(data['target_units'].toString()),
        'latitude': double.parse(data['latitude'].toString()),
        'longitude': double.parse(data['longitude'].toString()),
      };
      await ApiService.management(
        '/manage/camps${row == null ? '' : '/${row['id']}'}',
        method: row == null ? 'POST' : 'PUT',
        body: payload,
      );
    }, initial: initial);
  }

  Future<void> _personForm() async {
    final roles = _system
        ? [
            if (_superadmin) 'SYSTEM_ADMIN',
            if (_superadmin) 'PLATFORM_ADMIN',
            'ORG_ADMIN',
            'HOSPITAL_ADMIN',
            'ORG_STAFF',
            'HOSPITAL_STAFF',
            'DOCTOR',
          ]
        : _role == 'ORG_ADMIN'
        ? ['ORG_STAFF']
        : ['HOSPITAL_STAFF', 'DOCTOR'];
    await _form(
      'Add team member',
      [
        _Input(
          'role',
          'Role',
          options: {for (final r in roles) r: r.replaceAll('_', ' ')},
        ),
        _Input('username', 'Username'),
        _Input('first_name', 'First name'),
        _Input('last_name', 'Last name'),
        _Input('phone', 'Phone'),
        _Input('password', 'Initial password', password: true),
        if (_system) ...[
          _Input(
            'hospital_id',
            'Hospital (hospital roles)',
            options: _options(_hospitals, 'name'),
            required: false,
          ),
          _Input(
            'org_id',
            'Organization (organization roles)',
            options: _options(_organizations, 'legal_name'),
            required: false,
          ),
        ],
      ],
      (data) async {
        const endpoints = {
          'SYSTEM_ADMIN': '/admins/system',
          'PLATFORM_ADMIN': '/manage/platform-admins',
          'DOCTOR': '/manage/doctors',
          'ORG_ADMIN': '/admins/org',
          'HOSPITAL_ADMIN': '/admins/hospital',
          'ORG_STAFF': '/staff/org',
          'HOSPITAL_STAFF': '/staff/hospital',
        };
        await ApiService.management(
          endpoints[data['role']]!,
          method: 'POST',
          body: {
            ...data,
            'org_id': data['org_id'] ?? _membership['OrgID'],
            'hospital_id': data['hospital_id'] ?? _membership['HospitalID'],
          },
        );
      },
    );
  }

  Future<void> _entityForm() async {
    final hospital = _page == 'Hospitals';
    await _form(
      hospital ? 'Register hospital' : 'Register organization',
      hospital
          ? [
              _Input('name', 'Hospital name'),
              _Input(
                'type',
                'Type',
                options: {
                  'PUBLIC': 'Public',
                  'PRIVATE': 'Private',
                  'MILITARY': 'Military',
                },
              ),
              _Input('license_number', 'License number'),
              _Input('address', 'Address'),
              _Input('city', 'City'),
              _Input('phone', 'Phone'),
              _Input('lat', 'Latitude', number: true),
              _Input('lng', 'Longitude', number: true),
            ]
          : [
              _Input('legal_name', 'Legal name'),
              _Input('acronym', 'Short name'),
              _Input('org_id', 'Organization code'),
              _Input('registration_number', 'Registration number'),
              _Input(
                'type',
                'Type',
                options: {
                  'NGO': 'NGO',
                  'GOVERNMENT': 'Government',
                  'CORPORATE': 'Corporate',
                  'OTHER': 'Other',
                },
              ),
              _Input('email', 'Email'),
              _Input('phone', 'Phone'),
            ],
      (data) async {
        await ApiService.management(
          hospital ? '/hospitals' : '/organizations',
          method: 'POST',
          body: {
            ...data,
            'phone': [data['phone']],
            if (hospital)
              'location': {
                'lat': double.parse(data['lat'].toString()),
                'lng': double.parse(data['lng'].toString()),
              },
          },
        );
      },
    );
  }

  Future<void> _requestForm() async {
    await _form(
      'Request blood',
      [
        _Input(
          'blood_type_id',
          'Blood group',
          options: _options(_types, 'display_name'),
        ),
        _Input('units_requested', 'Units requested', number: true),
        _Input(
          'priority',
          'Priority',
          options: {
            'ROUTINE': 'Routine',
            'URGENT': 'Urgent',
            'CRITICAL': 'Critical',
          },
        ),
        _Input(
          'component_type',
          'Component',
          options: {
            'WHOLE_BLOOD': 'Whole blood',
            'RBC': 'Red cells',
            'PLASMA': 'Plasma',
            'PLATELET': 'Platelets',
          },
        ),
      ],
      (data) async {
        await ApiService.management(
          '/manage/requests',
          method: 'POST',
          body: {
            ...data,
            'units_requested': int.parse(data['units_requested'].toString()),
          },
        );
      },
    );
  }

  Future<void> _attendance(Json row) async {
    try {
      final r = await ApiService.management(
        '/manage/camps/${row['id']}/attendees',
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Camp attendance')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final a in r['data'] as List<dynamic>)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${a['donor']?['user']?['first_name'] ?? ''} ${a['donor']?['user']?['last_name'] ?? ''}',
                      ),
                      subtitle: Text(
                        a['donor']?['blood_type']?['display_name']
                                ?.toString() ??
                            '',
                      ),
                      trailing: Text(a['status'].toString()),
                    ),
                  ),
                if ((r['data'] as List).isEmpty)
                  const Text('No attendance confirmations yet.'),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _assign(Json row) async {
    try {
      final response = await ApiService.management(
        '/manage/camps/${row['id']}/staff',
      );
      final selected = (response['data'] as List<dynamic>? ?? [])
          .map((r) => r['user_id'].toString())
          .toSet();
      if (!mounted) return;
      final changed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, update) => AlertDialog(
            title: const Text('Assign camp staff'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final u in _users.where(
                      (u) => u['role'] == 'ORG_STAFF',
                    ))
                      CheckboxListTile(
                        title: Text(u['username']?.toString() ?? ''),
                        value: selected.contains(u['id']),
                        onChanged: (value) => update(() {
                          if (value == true) {
                            selected.add(u['id'].toString());
                          } else {
                            selected.remove(u['id'].toString());
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save assignments'),
              ),
            ],
          ),
        ),
      );
      if (changed == true) {
        await ApiService.management(
          '/manage/camps/${row['id']}/staff',
          method: 'PUT',
          body: {'staff_ids': selected.toList()},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _inventory(Json row) async {
    const transitions = {
      'PENDING_TEST': ['AVAILABLE', 'DISCARDED'],
      'AVAILABLE': ['RESERVED', 'USED', 'EXPIRED', 'DISCARDED'],
      'RESERVED': ['AVAILABLE', 'USED', 'DISCARDED'],
    };
    await _form(
      'Update blood unit',
      [
        _Input(
          'status',
          'Status',
          options: {
            for (final s in transitions[row['status']] ?? <String>[])
              s: s.replaceAll('_', ' '),
          },
        ),
        _Input(
          'expiration_date',
          'Validated expiry (required to release)',
          date: true,
          required: false,
        ),
      ],
      (data) async {
        await ApiService.management(
          '/manage/inventory/${row['id']}/status',
          method: 'PATCH',
          body: {
            ...data,
            if (data['expiration_date'] != null)
              'expiration_date': DateTime.parse(
                data['expiration_date'].toString(),
              ).toUtc().toIso8601String(),
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Prana · $_page'),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: _load,
        ),
      ],
    ),
    drawer: Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.bloodtype, color: Color(0xFFB71C1C)),
              title: Text(
                widget.userData['first_name']?.toString() ?? 'Workspace',
              ),
              subtitle: Text(_role.replaceAll('_', ' ')),
            ),
            const Divider(),
            for (final p in _pages)
              ListTile(
                selected: _page == p,
                title: Text(p),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _page = p);
                  _load();
                },
              ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () async {
                await SessionService.clearSession();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
    floatingActionButton:
        (_page == 'Camps' ||
            _page == 'People' ||
            _system && (_page == 'Hospitals' || _page == 'Organizations') ||
            _page == 'Requests' && _role == 'HOSPITAL_ADMIN')
        ? FloatingActionButton.extended(
            onPressed: () => _page == 'Camps'
                ? _campForm()
                : _page == 'People'
                ? _personForm()
                : _page == 'Requests'
                ? _requestForm()
                : _entityForm(),
            icon: const Icon(Icons.add),
            label: Text(
              _page == 'Camps'
                  ? 'Create camp'
                  : _page == 'People'
                  ? 'Add team member'
                  : _page == 'Requests'
                  ? 'Request blood'
                  : 'Register',
            ),
          )
        : null,
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: _page == 'Overview'
                  ? [
                      Text(
                        'Your community, at a glance',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      for (final e in _overview.entries)
                        Card(
                          child: ListTile(
                            title: Text(e.key.replaceAll('_', ' ')),
                            trailing: Text(
                              e.value.toString(),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ),
                    ]
                  : [
                      if (_rows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(36),
                          child: Text('No records in this view.'),
                        ),
                      for (final r in _rows) _record(Json.from(r as Map)),
                    ],
            ),
          ),
  );
  Widget _record(Json r) {
    if (_page == 'Camps') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r['camp_name']?.toString() ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${r['venue_name'] ?? ''}\n${r['start_time'] ?? ''}\n${r['status'] ?? ''}',
              ),
              Wrap(
                spacing: 12,
                children: [
                  TextButton(
                    onPressed: () => _attendance(r),
                    child: const Text('Attendance'),
                  ),
                  if (!['COMPLETED', 'CANCELLED'].contains(r['status'])) ...[
                    TextButton(
                      onPressed: () => _campForm(r),
                      child: const Text('Edit'),
                    ),
                    if (r['org_id'] != null)
                      TextButton(
                        onPressed: () => _assign(r),
                        child: const Text('Assign staff'),
                      ),
                    PopupMenuButton<String>(
                      tooltip: 'Change camp status',
                      onSelected: (s) => _mutate(
                        '/manage/camps/${r['id']}/status',
                        {'status': s},
                      ),
                      itemBuilder: (_) => [
                        if (r['status'] == 'SCHEDULED')
                          const PopupMenuItem(
                            value: 'ONGOING',
                            child: Text('Start camp'),
                          ),
                        if (r['status'] == 'ONGOING')
                          const PopupMenuItem(
                            value: 'COMPLETED',
                            child: Text('Complete camp'),
                          ),
                        const PopupMenuItem(
                          value: 'CANCELLED',
                          child: Text('Cancel camp'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }
    if (_page == 'Deletion requests') {
      return Card(
        child: ListTile(
          title: Text('${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'),
          subtitle: Text(
            '${r['username'] ?? ''} · ${r['deletion_requested_at']}',
          ),
          trailing: Wrap(
            children: [
              TextButton(
                onPressed: () => _mutate(
                  '/manage/deletion-requests/${r['id']}/reject',
                  {},
                  method: 'POST',
                ),
                child: const Text('Reject'),
              ),
              TextButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Approve deletion?'),
                      content: const Text(
                        'This removes identifying account details and revokes access.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await _mutate(
                      '/manage/deletion-requests/${r['id']}/approve',
                      {},
                      method: 'POST',
                    );
                  }
                },
                child: const Text('Approve'),
              ),
            ],
          ),
        ),
      );
    }
    if (_page == 'People') {
      return Card(
        child: ListTile(
          title: Text('${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'),
          subtitle: Text(
            '${r['username'] ?? ''} · ${r['role'] ?? ''}\n${r['status']}',
          ),
          trailing: _system && r['id'] != widget.userData['user_id']
              ? IconButton(
                  tooltip: r['status'] == 'ACTIVE' ? 'Suspend' : 'Activate',
                  icon: Icon(
                    r['status'] == 'ACTIVE' ? Icons.block : Icons.check_circle,
                  ),
                  onPressed: () => _mutate('/manage/users/${r['id']}', {
                    'status': r['status'] == 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE',
                  }),
                )
              : null,
        ),
      );
    }
    if (_page == 'Hospitals' || _page == 'Organizations') {
      return Card(
        child: ListTile(
          title: Text((r['name'] ?? r['legal_name'] ?? '').toString()),
          subtitle: Text('${r['city'] ?? r['email'] ?? ''}\n${r['status']}'),
          trailing: PopupMenuButton<String>(
            tooltip: 'Update approval',
            onSelected: (s) => _mutate(
              '/manage/${_page.toLowerCase()}/${r['id']}/status',
              {'status': s},
            ),
            itemBuilder: (_) => [
              for (final s
                  in _page == 'Hospitals'
                      ? ['ACTIVE', 'SUSPENDED', 'INACTIVE']
                      : ['APPROVED', 'REJECTED', 'SUSPENDED'])
                PopupMenuItem(value: s, child: Text(s)),
            ],
          ),
        ),
      );
    }
    if (_page == 'Inventory') {
      return Card(
        child: ListTile(
          title: Text(
            '${r['blood_type']?['display_name'] ?? 'Blood'} · ${r['volume_ml']} mL',
          ),
          subtitle: Text(
            '${r['component_type']} · ${r['status']}\nExpires: ${r['expiration_date'] ?? 'not yet validated'}',
          ),
          trailing:
              ['PENDING_TEST', 'AVAILABLE', 'RESERVED'].contains(r['status'])
              ? IconButton(
                  tooltip: 'Update unit',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _inventory(r),
                )
              : null,
        ),
      );
    }
    if (_page == 'Requests') {
      return Card(
        child: ListTile(
          title: Text(
            '${r['blood_type']?['display_name'] ?? ''} · ${r['units_requested']} units',
          ),
          subtitle: Text(
            '${r['requesting_hospital']?['name'] ?? ''}\n${r['priority']} · ${r['status']}',
          ),
          trailing: r['status'] == 'PENDING'
              ? PopupMenuButton<String>(
                  tooltip: 'Close request',
                  onSelected: (s) => _mutate(
                    '/manage/requests/${r['id']}/status',
                    {'status': s},
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'FULFILLED',
                      child: Text('Mark fulfilled'),
                    ),
                    const PopupMenuItem(
                      value: 'CANCELLED',
                      child: Text('Cancel request'),
                    ),
                  ],
                )
              : null,
        ),
      );
    }
    return Card(
      child: ListTile(
        title: Text(r['action']?.toString() ?? ''),
        subtitle: Text('${r['resource']}\n${r['created_at']}'),
      ),
    );
  }
}

class _Input {
  final String name, label;
  final bool number, password, date, required;
  final Map<String, String>? options;
  const _Input(
    this.name,
    this.label, {
    this.number = false,
    this.password = false,
    this.date = false,
    this.required = true,
    this.options,
  });
}

class _EditScreen extends StatefulWidget {
  final String title;
  final List<_Input> fields;
  final Json initial;
  final Future<void> Function(Json) submit;
  const _EditScreen({
    required this.title,
    required this.fields,
    required this.initial,
    required this.submit,
  });
  @override
  State<_EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<_EditScreen> {
  final _key = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Json _selected = {};
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      if (f.options != null) {
        _selected[f.name] = widget.initial[f.name];
      } else {
        _controllers[f.name] = TextEditingController(
          text: widget.initial[f.name]?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = <String, dynamic>{
        ..._selected,
        for (final e in _controllers.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      };
      await widget.submit(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final f in widget.fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: f.options != null
                  ? DropdownButtonFormField<String>(
                      initialValue: _selected[f.name]?.toString(),
                      isExpanded: true,
                      decoration: InputDecoration(labelText: f.label),
                      items: [
                        for (final e in f.options!.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ],
                      onChanged: (v) => _selected[f.name] = v,
                      validator: (v) => f.required && (v == null || v.isEmpty)
                          ? 'Please choose ${f.label.toLowerCase()}'
                          : null,
                    )
                  : TextFormField(
                      controller: _controllers[f.name],
                      readOnly: f.date,
                      obscureText: f.password,
                      keyboardType: f.number
                          ? const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            )
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: f.label,
                        suffixIcon: f.date
                            ? const Icon(Icons.calendar_month)
                            : null,
                      ),
                      onTap: f.date
                          ? () async {
                              final day = await showDatePicker(
                                context: context,
                                initialDate:
                                    DateTime.tryParse(
                                      _controllers[f.name]!.text,
                                    )?.toLocal() ??
                                    DateTime.now(),
                                firstDate: DateTime(2026),
                                lastDate: DateTime(2040),
                              );
                              if (day == null || !context.mounted) return;
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                _controllers[f.name]!.text = DateTime(
                                  day.year,
                                  day.month,
                                  day.day,
                                  time.hour,
                                  time.minute,
                                ).toIso8601String();
                              }
                            }
                          : null,
                      validator: (v) {
                        if (f.required && (v == null || v.trim().isEmpty)) {
                          return 'Please enter ${f.label.toLowerCase()}';
                        }
                        if (f.number &&
                            v != null &&
                            v.isNotEmpty &&
                            double.tryParse(v) == null) {
                          return 'Enter a valid number';
                        }
                        if (f.password && v != null && v.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                    ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Save changes'),
          ),
        ],
      ),
    ),
  );
}
