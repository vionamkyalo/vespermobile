import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/report_card.dart';
import '../../core/widgets/vesper_logo.dart';
import 'view_models/reports_view_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.onStartNewForm});

  final VoidCallback? onStartNewForm;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _filters = ReportsViewModel.filters;
  String _filter = _filters.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReportsViewModel>().load();
    });
  }

  Widget _body(ReportsViewModel vm) {
    final items = vm.itemsFor(_filter);

    if (vm.loading && !vm.hasAnyReports) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null && !vm.hasAnyReports) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.error!, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton(onPressed: vm.load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.load,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No reports yet')),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: items.length,
              itemBuilder: (_, i) => ReportCard(report: items[i]),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportsViewModel>();

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
            Expanded(child: _body(vm)),
          ],
        ),
      ),
    );
  }
}
