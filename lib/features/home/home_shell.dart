import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../alerts/view_models/alerts_view_model.dart';
import '../alerts/alerts_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final List<Widget> _tabs = [
  ChangeNotifierProvider(
    create: (_) => AlertsViewModel(),
    child: const AlertsScreen(),
  ),
  const ReportsScreen(),
  const _FormsTab(),
  const ProfileScreen(),
];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_photo_outlined),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            label: 'Forms',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _FormsTab extends StatelessWidget {
  const _FormsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forms')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _formTile(
            context,
            'Inspection report',
            'Complete an inspection',
            Icons.fact_check_outlined,
            '/forms/inspection',
          ),
          _formTile(
            context,
            'Violation form',
            'Record a violation',
            Icons.warning_amber_outlined,
            '/forms/violation',
          ),
          _formTile(
            context,
            'Catch check',
            'Complete a catch check',
            Icons.checklist_outlined,
            '/forms/catch-check',
          ),
        ],
      ),
    );
  }

  Widget _formTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String route,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}