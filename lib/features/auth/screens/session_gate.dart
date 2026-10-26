import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/vesper_logo.dart';
import '../viewmodel/sign_in_view_model.dart';

/// The splash screen: a white page with the logo for at least 3 seconds.
///
/// While it is showing, it checks whether the officer signed in before and
/// still has saved tokens. After the 3 seconds it opens home if they do, or
/// the sign-in screen if they do not.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  static const minimumDuration = Duration(seconds: 3);

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    final viewModel = context.read<SignInViewModel>();

    // Both run at the same time, so the screen stays 3 seconds at most,
    // unless the network check itself takes longer.
    final results = await Future.wait<Object?>([
      viewModel.restoreSession(),
      Future<void>.delayed(SessionGate.minimumDuration),
    ]);
    if (!mounted) return;

    final signedIn = results.first == true;
    Navigator.of(context).pushReplacementNamed(
      signedIn ? AppRoutes.home : AppRoutes.signIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: VesperLogo(height: 80)),
    );
  }
}