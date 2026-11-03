import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _busy = false, _requested = false;
  String? _error;
  bool? _health;
  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    try {
      final r = await ApiService.management('/donors/me/consents');
      if (mounted) {
        setState(() => _health = r['data']['health_consent'] == true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _consent() async {
    setState(() => _busy = true);
    try {
      final r = await ApiService.management(
        '/donors/me/consents',
        method: 'PATCH',
        body: {'health_consent': !_health!},
      );
      if (mounted) {
        setState(() => _health = r['data']['health_consent'] == true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ApiService.management('/donors/me/export');
      final text = const JsonEncoder.withIndent('  ').convert(r['data']);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Your Prana data'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(child: SelectableText(text)),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Copy JSON export'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _request() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request account deletion?'),
        content: const Text(
          'An administrator reviews your request and removes identifying account details. Donation safety records may be retained in de-identified form.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit request'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiService.management(
        '/donors/me/deletion-request',
        method: 'POST',
        body: {},
      );
      if (mounted) setState(() => _requested = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy & my data')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'You control your information',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        const Text(
          'Prana is an independent community blood donation project. Your NIC and verified phone identify your account. Your profile, camp participation and donation records support donation coordination. Doctors use screening records to record clinical decisions. We do not sell donor data.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Location access is optional and helps find nearby camps. A location permission prompt appears when you request that feature. Prana is not affiliated with NBTS or Raktha.',
        ),
        const SizedBox(height: 24),
        Text(
          'Health screening consent',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'Allow authorized Doctors to record screening measurements and clinical decisions. Withdrawing stops new screenings; existing safety records remain available for review.',
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _busy || _health == null ? null : _consent,
          child: Text(
            _health == null
                ? 'Loading consent…'
                : _health!
                ? 'Withdraw screening consent'
                : 'Allow health screening',
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _export,
          icon: const Icon(Icons.download),
          label: const Text('Export my data'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _busy || _requested ? null : _request,
          icon: const Icon(Icons.person_remove_outlined),
          label: Text(
            _requested
                ? 'Deletion request submitted'
                : 'Request account deletion',
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
    ),
  );
}
