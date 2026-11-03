import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../genui_parser.dart';
import '../genui_renderer.dart';

/// Interactive GenUI Sandbox & Developer Playground.
/// Allows live testing, inspection, and accessibility scaling of any GenUI component payload.
class GenUiPlaygroundSheet extends StatefulWidget {
  const GenUiPlaygroundSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const GenUiPlaygroundSheet(),
    );
  }

  @override
  State<GenUiPlaygroundSheet> createState() => _GenUiPlaygroundSheetState();
}

class _GenUiPlaygroundSheetState extends State<GenUiPlaygroundSheet> {
  late TextEditingController _jsonController;
  String _selectedPreset = 'Trend Chart';
  double _textScale = 1.0;
  bool _forceDark = true;
  // ignore: unused_field
  String? _parseError;

  static const Map<String, String> _presets = {
    'Trend Chart': '''
```json
{
  "type": "trend_chart",
  "title": "30-Day Systolic Pressure Trend",
  "metricType": "bp",
  "dataPoints": [128.0, 126.0, 122.0, 120.0, 118.0],
  "labels": ["W1", "W2", "W3", "W4", "Current"],
  "summary": "Consistent downward trajectory reaching optimal target range."
}
```''',
    'Cardiac ECG Pulse': '''
```json
{
  "type": "pulse_card",
  "title": "Resting Heart Rate",
  "value": "74",
  "unit": "BPM",
  "status": "normal"
}
```''',
    'Blood Pressure Card': '''
```json
{
  "type": "blood_pressure_card",
  "title": "Evening BP Reading",
  "value": "122/78",
  "unit": "mmHg",
  "status": "normal",
  "subtitle": "Home monitoring cuff"
}
```''',
    'Lab Results Panel': '''
```json
{
  "type": "lab_results_card",
  "panelName": "Comprehensive Lipid Profile",
  "collectionDate": "Oct 3, 2026",
  "labProvider": "Quest Diagnostics",
  "analytes": [
    {
      "name": "Total Cholesterol",
      "value": "188",
      "unit": "mg/dL",
      "referenceRange": "< 200 mg/dL",
      "status": "normal"
    },
    {
      "name": "HDL (Good)",
      "value": "56",
      "unit": "mg/dL",
      "referenceRange": "> 40 mg/dL",
      "status": "optimal"
    },
    {
      "name": "LDL (Bad)",
      "value": "112",
      "unit": "mg/dL",
      "referenceRange": "< 100 mg/dL",
      "status": "borderline"
    }
  ],
  "clinicalNote": "Lipid markers demonstrate favorable cardiovascular response to lifestyle modifications."
}
```''',
    'Risk Assessment Gauge': '''
```json
{
  "type": "risk_gauge_card",
  "title": "10-Year ASCVD Risk Score",
  "scorePercentage": 8.5,
  "riskLevel": "low",
  "categoryDescription": "American Heart Association Risk Model",
  "contributingFactors": [
    "Systolic BP controlled at 120 mmHg",
    "Non-smoker status",
    "Optimal fasting glucose"
  ],
  "recommendation": "Maintain aerobic physical activity and heart-healthy dietary patterns."
}
```''',
    'Doctor Consultation Checklist': '''
```json
{
  "type": "doctor_checklist_card",
  "title": "Physician Consultation Guide",
  "appointmentFocus": "Annual Cardiology & Vitals Review",
  "checklistItems": [
    {
      "question": "Are my current resting BP averages safely within my personal target?",
      "category": "Blood Pressure"
    },
    {
      "question": "Should we perform a repeat fasting lipid panel in 6 months?",
      "category": "Lab Review"
    },
    {
      "question": "Can I continue moderate aerobic exercise 4 times weekly?",
      "category": "Lifestyle"
    }
  ]
}
```''',
    'Medication Intake Card': '''
```json
{
  "type": "medication_intake_card",
  "medicationName": "Amlodipine Besylate",
  "dosage": "5 mg",
  "scheduledTime": "08:00 AM",
  "frequency": "Daily",
  "instructions": "Take once daily in morning with or without food."
}
```''',
  };

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController(text: _presets['Trend Chart']);
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _loadPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      _jsonController.text = _presets[preset] ?? '';
      _parseError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final previewContent = _jsonController.text;
    final parsedComponents = GenUiParser.parseComponents(previewContent);

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        decoration: BoxDecoration(
          color: _forceDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: _forceDark ? const Color(0xFF2A365C) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: _forceDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Top Header: Title, Dark Toggle, Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.aiGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.science_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GenUI Sandbox & Inspector',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _forceDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Dart 3 Pattern Matching & Accessible Component Testbench',
                          style: TextStyle(
                            fontSize: 11,
                            color: _forceDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _forceDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: _forceDark ? Colors.amber : const Color(0xFF64748B),
                    ),
                    tooltip: 'Toggle Theme',
                    onPressed: () => setState(() => _forceDark = !_forceDark),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: _forceDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 16),

            // Toolbar: Preset Selector & Text Scaler
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _forceDark ? const Color(0xFF1C2541) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _forceDark ? const Color(0xFF2A365C) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedPreset,
                          isExpanded: true,
                          dropdownColor: _forceDark ? const Color(0xFF1C2541) : Colors.white,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _forceDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          items: _presets.keys.map((name) {
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) _loadPreset(val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Font Scaling Pill (Accessibility testing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _forceDark ? const Color(0xFF1C2541) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _forceDark ? const Color(0xFF2A365C) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.text_fields_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            value: _textScale,
                            dropdownColor: _forceDark ? const Color(0xFF1C2541) : Colors.white,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _forceDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            items: const [
                              DropdownMenuItem(value: 1.0, child: Text('1.0x Scale')),
                              DropdownMenuItem(value: 1.25, child: Text('1.25x Scale')),
                              DropdownMenuItem(value: 1.5, child: Text('1.5x Scale')),
                              DropdownMenuItem(value: 2.0, child: Text('2.0x Scale')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _textScale = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Main Content: Split View (Live Preview on top, JSON editor below)
            Expanded(
              child: Theme(
                data: _forceDark ? ThemeData.dark() : ThemeData.light(),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(_textScale),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: [
                      // Component Inspector Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LIVE COMPONENT PREVIEW (${parsedComponents.length} RESOLVED)',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: _forceDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          if (parsedComponents.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Dart 3: ${parsedComponents.first.runtimeType}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Live Rendered Card
                      GenUiRenderer(content: previewContent),

                      const SizedBox(height: 20),

                      // Raw Payload Editor Header
                      Text(
                        'RAW PAYLOAD (EDIT TO TEST INSTANT RENDERING)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: _forceDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Code Editor Field
                      Container(
                        decoration: BoxDecoration(
                          color: _forceDark ? const Color(0xFF060D1F) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _forceDark ? const Color(0xFF2A365C) : const Color(0xFF334155),
                          ),
                        ),
                        child: TextField(
                          controller: _jsonController,
                          maxLines: 10,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF38BDF8),
                            height: 1.4,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                          ),
                          onChanged: (text) {
                            setState(() {
                              _parseError = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
