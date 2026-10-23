import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../alerts/alerts_screen.dart';
import '../forms/inspection_form_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  List<Widget> get _tabs => [
        const AlertsScreen(),
        ReportsScreen(onStartNewForm: () => _goTo(2)), // 2 = Forms tab
        const InspectionFormScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.cyan, width: 3)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                _NavItem(
                  label: 'Alerts',
                  asset: 'assets/images/notification.png',
                  selected: _index == 0,
                  onTap: () => _goTo(0),
                ),
                _NavItem(
                  label: 'Reports',
                  asset: 'assets/images/reports_icon.png',
                  selected: _index == 1,
                  onTap: () => _goTo(1),
                ),
                _NavItem(
                  label: 'Forms',
                  asset: 'assets/images/forms_icon.png',
                  selected: _index == 2,
                  onTap: () => _goTo(2),
                ),
                _NavItem(
                  label: 'Profile',
                  asset: 'assets/images/profile.png',
                  selected: _index == 3,
                  onTap: () => _goTo(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.cyan : AppColors.navy;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ImageIcon(AssetImage(asset), color: color, size: 32),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}