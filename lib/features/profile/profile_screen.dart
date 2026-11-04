import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/sync/services/sync_service.dart';
import '../../core/theme/app_colors.dart';
import 'models/user_profile.dart';
import 'view_models/profile_view_model.dart';
import 'view_models/waiting_reports_view_model.dart';
import 'waiting_reports_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _onSignOut(BuildContext context) async {
    final viewModel = context.read<ProfileViewModel>();
    final navigator = Navigator.of(context, rootNavigator: true);

    await viewModel.signOut();

    navigator.pushNamedAndRemoveUntil(AppRoutes.signIn, (_) => false);
  }

  Future<void> _openWaitingReports(BuildContext context) async {
    final viewModel = context.read<ProfileViewModel>();
    final sync = context.read<SyncService>();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => WaitingReportsViewModel(sync: sync),
          child: const WaitingReportsScreen(),
        ),
      ),
    );

    await viewModel.refreshWaiting();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final user = viewModel.user;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const _Header(),
            const SizedBox(height: 16),
            if (user != null) ...[
              _UserCard(user: user),
              const SizedBox(height: 16),
              _ContactCard(user: user),
              const SizedBox(height: 16),
            ],
            _StatusCard(
              waitingSummary: viewModel.waitingSummary,
              onManageLocation: viewModel.manageLocation,
              onOpenWaiting: () => _openWaitingReports(context),
            ),
            const SizedBox(height: 16),
            const _InfoNote(),
            const SizedBox(height: 24),
            _SignOutButton(onPressed: () => _onSignOut(context)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    return Row(
      children: [
        if (canGoBack)
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_left, color: AppColors.navy, size: 32),
            ),
          ),
        const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _NavyCard extends StatelessWidget {
  const _NavyCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return _NavyCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.sky,
            child: Text(
              user.initials,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.role,
                  style: const TextStyle(color: AppColors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return _NavyCard(
      child: Column(
        children: [
          _InfoRow(label: 'Phone', value: user.phone),
          Divider(height: 24, color: AppColors.white.withValues(alpha: 0.4)),
          _InfoRow(label: 'Email', value: user.email),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.white, fontSize: 16),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.waitingSummary,
    required this.onManageLocation,
    required this.onOpenWaiting,
  });

  final String waitingSummary;
  final VoidCallback onManageLocation;
  final VoidCallback onOpenWaiting;

  @override
  Widget build(BuildContext context) {
    return _NavyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LinkRow(
            label: 'Location access',
            action: 'Manage',
            onTap: onManageLocation,
          ),
          Divider(height: 28, color: AppColors.white.withValues(alpha: 0.4)),
          _LinkRow(
            label: 'Reports waiting to send',
            action: 'Open',
            onTap: onOpenWaiting,
          ),
          const SizedBox(height: 4),
          Text(
            waitingSummary,
            style: const TextStyle(color: AppColors.cyan, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.action,
    required this.onTap,
  });

  final String label;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.white, fontSize: 15),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              action,
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    return const _NavyCard(
      child: Text(
        'Your phone keeps a copy of everything you write until the server '
        'confirms it. Signing out with unsent reports keeps them on this '
        'phone',
        style: TextStyle(color: AppColors.white, fontSize: 14, height: 1.4),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Sign out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
