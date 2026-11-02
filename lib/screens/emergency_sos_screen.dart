import 'package:flutter/material.dart';
import 'package:mobile_app/theme.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _sosSent = false;

  final List<Map<String, dynamic>> _emergencyContacts = [
    {'name': 'National Blood Bank', 'number': '+94 11 2 691 196', 'type': 'Hospital'},
    {'name': 'BloodConnectSL Hotline', 'number': '+94 76 000 1111', 'type': 'Support'},
    {'name': 'Suwa Seriya (1990)', 'number': '1990', 'type': 'Ambulance'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerSOS() {
    setState(() => _sosSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('SOS Alert sent! Help is on the way.'),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetSOS() => setState(() => _sosSent = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        title: const Text(
          'Emergency SOS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Use this only in genuine emergencies. Misuse may delay help to others.',
                      style: TextStyle(color: Color(0xFFE65100), fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Pulsing SOS button
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _sosSent ? 1.0 : _pulseAnimation.value,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _sosSent ? _resetSOS : _triggerSOS,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _sosSent ? const Color(0xFF2E7D32) : AppTheme.primaryRed,
                    boxShadow: [
                      BoxShadow(
                        color: (_sosSent ? const Color(0xFF2E7D32) : AppTheme.primaryRed).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _sosSent ? Icons.check : Icons.emergency,
                        color: Colors.white,
                        size: 56,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _sosSent ? 'SENT ✓' : 'SOS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              _sosSent ? 'Tap again to cancel' : 'Hold to send SOS alert\nto nearby donors & hospitals',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
            ),

            const SizedBox(height: 40),

            // What happens
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What happens when you press SOS?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                  const SizedBox(height: 14),
                  _sosStep('1', 'Your blood type & location are shared with nearby donors'),
                  _sosStep('2', 'Hospitals within 10 km are instantly notified'),
                  _sosStep('3', 'BloodConnectSL coordinators are called immediately'),
                  _sosStep('4', 'You receive ETA & contact details of responders'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Emergency contacts
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
            ),
            const SizedBox(height: 12),

            ..._emergencyContacts.map((contact) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.phone, color: AppTheme.primaryRed, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                          Text(contact['number'] as String,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(contact['type'] as String,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sosStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: const BoxDecoration(color: AppTheme.primaryRed, shape: BoxShape.circle),
            child: Center(
              child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
