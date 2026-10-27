import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../alerts/alerts_screen.dart';
import '../alerts/view_models/alerts_view_model.dart';
import '../auth/viewmodel/sign_in_view_model.dart';
import '../forms/catch_check_form_screen.dart';
import '../forms/inspection_form_screen.dart';
import '../forms/violation_form_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/view_models/profile_view_model.dart';
import '../reports/reports_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  Widget _buildTabRoot(int index) {
    switch (index) {
      case 0:
        return ChangeNotifierProvider(
          create: (_) => AlertsViewModel(),
          child: const AlertsScreen(),
        );
      case 1:
        return const ReportsScreen();
      case 2:
        return const _FormsTab();
      case 3:
        return ChangeNotifierProvider(
          create: (_) => ProfileViewModel(),
          child: const ProfileScreen(),
        );
      default:
        throw StateError('Unknown tab index: $index');
    }
  }

  Route<dynamic>? _generateTabRoute(int tabIndex, RouteSettings settings) {
    WidgetBuilder? builder;

    switch (settings.name) {
      case '/':
        builder = (_) => _buildTabRoot(tabIndex);
        break;
      case AppRoutes.inspectionForm:
        builder = (_) => const InspectionFormScreen();
        break;
      case AppRoutes.violationForm:
        builder = (_) => const ViolationFormScreen();
        break;
      case AppRoutes.catchCheckForm:
        builder = (_) => const CatchCheckFormScreen();
        break;
    }

    if (builder == null) {
      return null;
    }

    return MaterialPageRoute<dynamic>(settings: settings, builder: builder);
  }

  void _goTo(int index) {
    if (_index == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }

    setState(() {
      _index = index;
    });
  }

  Widget _buildTabNavigator(int index) {
    return NavigatorPopHandler<Object?>(
      enabled: _index == index,
      onPopWithResult: (result) {
        _navigatorKeys[index].currentState?.pop(result);
      },
      child: Navigator(
        key: _navigatorKeys[index],
        initialRoute: '/',
        onGenerateRoute: (settings) {
          return _generateTabRoute(index, settings);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: List.generate(_navigatorKeys.length, _buildTabNavigator),
      ),
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

class _FormsTab extends StatelessWidget {
  const _FormsTab();

  Future<void> _logout(BuildContext context) async {
    final viewModel = context.read<SignInViewModel>();
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    await viewModel.logout();
    rootNavigator.pushNamedAndRemoveUntil(AppRoutes.signIn, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forms'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: const Text('Inspection form'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.inspectionForm);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.report_outlined),
            title: const Text('Violation form'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.violationForm);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Catch check form'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.catchCheckForm);
            },
          ),
        ],
      ),
    );
  }
}