import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../widgets/prana_logo.dart';

class DigitalPassScreen extends StatefulWidget {
  const DigitalPassScreen({
    super.key,
    required this.name,
    required this.reference,
  });
  final String name, reference;
  @override
  State<DigitalPassScreen> createState() => _DigitalPassScreenState();
}

class _DigitalPassScreenState extends State<DigitalPassScreen> {
  Timer? _timer, _ticker;
  String? _token, _error;
  DateTime? _expires;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 90), (_) => _refresh());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ApiService.management('/donors/me/pass-token');
      if (mounted) {
        setState(() {
          _token = r['data']['pass_token'].toString();
          _expires = DateTime.now().add(
            Duration(seconds: (r['data']['expires_in_seconds'] as num).toInt()),
          );
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Prana donor pass')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PranaLogo(size: 64),
            const SizedBox(height: 20),
            Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (_token != null && _expires!.isAfter(DateTime.now()))
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: QrImageView(data: _token!, size: 240),
              )
            else if (_busy)
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            SelectableText(
              widget.reference,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            const Text(
              'Show this pass to the screening doctor or donation staff. The secure QR refreshes automatically.',
              textAlign: TextAlign.center,
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            TextButton.icon(
              onPressed: _busy ? null : _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh secure pass'),
            ),
          ],
        ),
      ),
    ),
  );
}
