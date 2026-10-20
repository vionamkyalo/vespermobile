import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ReportItem {
  const ReportItem({
    required this.type, 
    required this.title,
    required this.received,
    required this.officer,
    required this.zone,
    required this.notes,
  });

  final String type;
  final String title;
  final String received;
  final String officer;
  final String zone;
  final String notes;
}

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report});

  final ReportItem report;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.title,
            style: const TextStyle(
              color: AppColors.fieldBlue,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Colors.white, height: 1, thickness: 1),
          const SizedBox(height: 12),
          _Line(label: 'Received', value: report.received),
          _Line(label: 'Officer', value: report.officer),
          _Line(label: 'Zone', value: report.zone),
          const SizedBox(height: 8),
          const Text(
            'Officer notes',
            style: TextStyle(
              color: AppColors.fieldBlue,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report.notes,
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: ' - $value',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}