import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/vesper_logo.dart';
import 'models/alerts.dart';
import 'view_models/alerts_view_model.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, this.viewModel});

  final AlertsViewModel? viewModel;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late final AlertsViewModel _viewModel = widget.viewModel ?? AlertsViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                children: [
                  const VesperLogo(height: 40),
                  const SizedBox(height: 28),
                  const Text(
                    'My alerts',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _FilterButton(
                          label: 'Assigned - ${_viewModel.assignedCount}',
                          selected: !_viewModel.showAllZones,
                          onPressed: _viewModel.showAssigned,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: _FilterButton(
                          label: 'All zones-${_viewModel.allZonesCount}',
                          selected: _viewModel.showAllZones,
                          onPressed: _viewModel.selectAllZones,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 44),
                  if (_viewModel.visibleAlerts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('No alerts to show.')),
                    )
                  else
                    ..._viewModel.visibleAlerts.map(
                      (alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _AlertCard(
                          alert: alert,
                          onAcknowledge: () => _viewModel.acknowledgeAlert(alert.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: selected ? AppColors.cyan : AppColors.navy,
            foregroundColor: selected ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
        ),
      );
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onAcknowledge});

  final Alert alert;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final acknowledged = alert.isAcknowledged;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        border: Border.all(
          color: acknowledged ? const Color(0xFFD8D8D8) : const Color(0xFF5CE2F6),
          width: acknowledged ? 1.5 : 2,
        ),
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 3, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.zoneName,
                  style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
                ),
              ),
              Text(_formatTime(alert.createdAt),
                  style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${alert.distanceKm.toStringAsFixed(1)} km away.',
                  style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              const Text('Confidence',
                  style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600)),
              const SizedBox(width: 7),
              Text('${alert.confidence.toStringAsFixed(2)}%',
                  style: const TextStyle(color: Colors.black)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: acknowledged ? null : onAcknowledge,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: acknowledged ? AppColors.cyan : Colors.transparent,
                foregroundColor: AppColors.navy,
                disabledBackgroundColor: AppColors.cyan,
                disabledForegroundColor: AppColors.navy,
                side: BorderSide(color: AppColors.cyan, width: acknowledged ? 0 : 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                acknowledged ? 'Acknowledged' : 'Acknowledge alert',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour.$minute ${dateTime.hour >= 12 ? 'pm' : 'am'}';
  }
}