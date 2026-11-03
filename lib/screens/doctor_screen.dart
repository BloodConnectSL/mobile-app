import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../widgets/prana_logo.dart';
import 'login_screen.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});
  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final _identifier = TextEditingController(),
      _hb = TextEditingController(),
      _bp = TextEditingController(),
      _note = TextEditingController(),
      _days = TextEditingController();
  Map<String, dynamic>? _donor;
  List<dynamic> _recent = [];
  bool _busy = false, _camera = false;
  String _outcome = 'CLEARED';
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_identifier, _hb, _bp, _note, _days]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService.management('/doctor/screenings');
      if (mounted) setState(() => _recent = r['data'] as List? ?? []);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _find() async {
    if (_identifier.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _camera = false;
      _donor = null;
    });
    try {
      final r = await ApiService.management(
        '/staff/scan/${Uri.encodeComponent(_identifier.text.trim())}',
      );
      if (mounted) {
        setState(() => _donor = Map<String, dynamic>.from(r['data'] as Map));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiService.management(
        '/doctor/screenings',
        method: 'POST',
        body: {
          'donor_id': _donor!['donor_id'],
          'outcome': _outcome,
          'hemoglobin_level': double.tryParse(_hb.text) ?? 0,
          'blood_pressure': _bp.text.trim(),
          'note': _note.text.trim(),
          'defer_days': int.tryParse(_days.text) ?? 0,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _outcome == 'CLEARED'
                ? 'Clinical clearance saved for 12 hours'
                : 'Deferral saved',
          ),
        ),
      );
      setState(() {
        _donor = null;
        _identifier.clear();
        _hb.clear();
        _bp.clear();
        _note.clear();
        _days.clear();
      });
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _input(String title, TextEditingController c, {bool number = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextField(
          controller: c,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(labelText: title),
        ),
      );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Prana · Doctor'),
      actions: [
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
        IconButton(
          tooltip: 'Log out',
          icon: const Icon(Icons.logout),
          onPressed: () async {
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
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Row(
            children: [
              PranaLogo(size: 48),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Donor screening',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Review the donor, enter measured values, and record your clinical decision.',
          ),
          _input('NIC, donor pass reference or signed QR', _identifier),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _find,
                  child: const Text('Find donor'),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _camera = !_camera),
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scan QR',
              ),
            ],
          ),
          if (_camera)
            SizedBox(
              height: 240,
              child: MobileScanner(
                onDetect: (capture) {
                  if (_busy || !_camera) return;
                  for (final b in capture.barcodes) {
                    final raw = b.rawValue;
                    if (raw != null && raw.isNotEmpty) {
                      _identifier.text = raw;
                      _find();
                      break;
                    }
                  }
                },
              ),
            ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_donor != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _donor!['full_name']?.toString() ?? 'Donor',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${_donor!['blood_group'] ?? ''} · ${_donor!['qr_ref_id'] ?? ''}',
                    ),
                    Text(_donor!['eligibility_message']?.toString() ?? ''),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _outcome,
                      decoration: const InputDecoration(
                        labelText: 'Clinical decision',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'CLEARED',
                          child: Text('Clear to donate'),
                        ),
                        DropdownMenuItem(
                          value: 'DEFERRED',
                          child: Text('Defer donation'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _outcome = v!),
                    ),
                    if (_outcome == 'CLEARED') ...[
                      _input('Measured hemoglobin (g/dL)', _hb, number: true),
                      _input('Measured blood pressure', _bp),
                    ] else
                      _input(
                        'Deferral days (0 = ongoing)',
                        _days,
                        number: true,
                      ),
                    _input(
                      _outcome == 'CLEARED'
                          ? 'Clinical / reassessment note'
                          : 'Reason for deferral',
                      _note,
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: const Text('Save decision'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Recent screening decisions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No screening decisions yet.'),
            ),
          for (final r in _recent)
            Card(
              child: ListTile(
                leading: Icon(
                  r['outcome'] == 'CLEARED'
                      ? Icons.check_circle_outline
                      : Icons.pause_circle_outline,
                ),
                title: Text(r['outcome'].toString()),
                subtitle: Text('${r['created_at']}\n${r['note'] ?? ''}'),
                trailing: Text(r['consumed_at'] != null ? 'Used' : 'Current'),
              ),
            ),
        ],
      ),
    ),
  );
}
