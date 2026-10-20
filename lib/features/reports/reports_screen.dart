import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/report_card.dart';
import '../../core/widgets/vesper_logo.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.onStartNewForm});

  final VoidCallback? onStartNewForm;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _filters = ['Violations', 'Inspections', 'Catch checks'];
  String _filter = _filters.first;

  static const _reports = [
    ReportItem(
      type: 'Violations',
      title: 'Violation - Unregistered rig',
      received: '10 Nov 2025 10.00pm',
      officer: 'Mbilizi Mwedzi',
      zone: 'Binga cluster 2',
      notes:
          'The total number of rigs were 120 with 30 being unregistered. All 30 rigs were impounded.',
    ),
    ReportItem(
      type: 'Violations',
      title: 'Violation - Unlicensed rig',
      received: '15 Oct 2025 10.00pm',
      officer: 'Mbilizi Mwedzi',
      zone: 'Binga cluster 2',
      notes:
          'The total number of rigs were 100 with 50 being unregistered. All 50 rigs were impounded.',
    ),
        ReportItem(
      type: 'Inspections',
      title: 'Inspection - Binga cluster 2',
      received: '12 Nov 2025 09.30am',
      officer: 'Mbilizi Mwedzi',
      zone: 'Binga cluster 2',
      notes:
          'Routine patrol. 85 rigs observed, 78 with valid licences. 7 rigs issued warnings for missing lights.',
    ),
    ReportItem(
      type: 'Inspections',
      title: 'Inspection - Siavonga cluster 1',
      received: '02 Nov 2025 08.15pm',
      officer: 'Mbilizi Mwedzi',
      zone: 'Siavonga cluster 1',
      notes:
          'Night inspection. 64 rigs observed, all registered. No violations recorded.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _reports.where((r) => r.type == _filter).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VesperLogo(),
                  const SizedBox(height: 16),
                  const Text(
                    'My reports',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AccentButton(
                        label: 'Start new form',
                        onPressed: widget.onStartNewForm,
                      ),
                      PillDropdown(
                        current: _filter,
                        items: _filters,
                        onSelected: (v) => setState(() => _filter = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('No reports yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: visible.length,
                      itemBuilder: (_, i) => ReportCard(report: visible[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}