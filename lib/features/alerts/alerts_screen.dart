import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/alert_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/vesper_logo.dart';
import 'view_models/alerts_view_model.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AlertsViewModel>().load(),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _acknowledge(String id) async {
    final error = await context.read<AlertsViewModel>().acknowledge(id);
    if (error != null) _showMessage(error);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AlertsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => vm.load(refresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                      label: 'Assigned - ${vm.assignedCount}',
                      selected: vm.tab == AlertsTab.assigned,
                      onPressed: () => vm.selectTab(AlertsTab.assigned),
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: _FilterButton(
                      label: 'All zones - ${vm.zoneCount}',
                      selected: vm.tab == AlertsTab.allZones,
                      onPressed: () => vm.selectTab(AlertsTab.allZones),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 44),
              ..._body(vm),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(AlertsViewModel vm) {
    switch (vm.state) {
      case AlertsLoadState.loading:
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case AlertsLoadState.error:
        return [
          _Message(text: vm.error ?? 'Could not load alerts.'),
          PrimaryButton(label: 'Try again', onPressed: vm.load),
        ];
      case AlertsLoadState.ready:
        if (vm.visibleAlerts.isEmpty) {
          return const [_Message(text: 'No alerts to show.')];
        }
        return [
          for (final alert in vm.visibleAlerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: AlertCard(
                alert: alert,
                busy: vm.isAcknowledging(alert.id),
                onAcknowledge: () => _acknowledge(alert.id),
              ),
            ),
        ];
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(child: Text(text, textAlign: TextAlign.center)),
  );
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
