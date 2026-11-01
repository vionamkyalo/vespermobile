import 'package:flutter/material.dart';

import '../../features/alerts/models/alerts.dart';
import '../theme/app_colors.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    required this.onAcknowledge,
    this.busy = false,
  });

  final Alert alert;
  final VoidCallback onAcknowledge;
  final bool busy;

  static const _label = TextStyle(
    color: AppColors.navy,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final acknowledged = alert.isAcknowledged;
    final distance = alert.distanceKm;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        border: Border.all(
          color: acknowledged
              ? const Color(0xFFD8D8D8)
              : const Color(0xFF5CE2F6),
          width: acknowledged ? 1.5 : 2,
        ),
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 3,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(alert.zoneName, style: _label)),
              Text(_formatTime(alert.createdAt), style: _label),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (distance != null) ...[
                Text('${distance.toStringAsFixed(1)} km away.', style: _label),
                const SizedBox(width: 16),
              ],
              const Text('Confidence', style: _label),
              const SizedBox(width: 7),
              Text(
                '${(alert.confidence * 100).round()}%',
                style: const TextStyle(color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: acknowledged || busy ? null : onAcknowledge,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: acknowledged
                    ? AppColors.cyan
                    : Colors.transparent,
                foregroundColor: AppColors.navy,
                disabledBackgroundColor: acknowledged
                    ? AppColors.cyan
                    : Colors.transparent,
                disabledForegroundColor: AppColors.navy,
                side: BorderSide(
                  color: AppColors.cyan,
                  width: acknowledged ? 0 : 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.navy,
                      ),
                    )
                  : Text(
                      acknowledged ? 'Acknowledged' : 'Acknowledge alert',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour.$minute ${dateTime.hour >= 12 ? 'pm' : 'am'}';
  }
}
