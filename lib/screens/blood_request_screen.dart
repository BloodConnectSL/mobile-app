import 'package:flutter/material.dart';
import 'package:mobile_app/theme.dart';

class BloodRequestScreen extends StatefulWidget {
  const BloodRequestScreen({super.key});

  @override
  State<BloodRequestScreen> createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen> {
  String _selectedBloodType = 'A+';
  String _selectedUrgency = 'Urgent';
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _bloodTypes = [
    'A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'
  ];

  final List<Map<String, dynamic>> _urgencyLevels = [
    {'label': 'Critical', 'color': const Color(0xFFD32F2F), 'icon': Icons.emergency},
    {'label': 'Urgent', 'color': const Color(0xFFE64A19), 'icon': Icons.priority_high},
    {'label': 'Moderate', 'color': const Color(0xFFF57C00), 'icon': Icons.schedule},
    {'label': 'Scheduled', 'color': const Color(0xFF388E3C), 'icon': Icons.event_available},
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        title: const Text(
          'Blood Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryRed, Color(0xFFB71C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bloodtype, color: Colors.white, size: 36),
                  SizedBox(height: 12),
                  Text(
                    'Submit a Blood Request',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Fill in the details below and we\'ll alert\nnearby donors immediately.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            _sectionLabel('Blood Type Needed'),
            const SizedBox(height: 12),

            // Blood type grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _bloodTypes.map((type) {
                final selected = type == _selectedBloodType;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBloodType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 66,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryRed : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppTheme.primaryRed : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        type,
                        style: TextStyle(
                          color: selected ? Colors.white : AppTheme.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),
            _sectionLabel('Urgency Level'),
            const SizedBox(height: 12),

            ..._urgencyLevels.map((level) {
              final selected = level['label'] == _selectedUrgency;
              final color = level['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _selectedUrgency = level['label'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? color.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? color : Colors.grey.shade200,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(level['icon'] as IconData, color: color, size: 22),
                      const SizedBox(width: 14),
                      Text(
                        level['label'] as String,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          color: selected ? color : AppTheme.textDark,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      if (selected) Icon(Icons.check_circle, color: color, size: 20),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
            _sectionLabel('Hospital / Location'),
            const SizedBox(height: 10),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'e.g. National Hospital, Colombo',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primaryRed),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryRed, width: 2)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),
            _sectionLabel('Additional Notes'),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any additional info for donors...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryRed, width: 2)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Blood request for $_selectedBloodType sent! Alerting nearby donors...'),
                      backgroundColor: AppTheme.primaryRed,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  'Submit Request',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark));
  }
}
