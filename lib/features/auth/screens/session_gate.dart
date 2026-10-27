import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/vesper_logo.dart';
import '../viewmodel/sign_in_view_model.dart';


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