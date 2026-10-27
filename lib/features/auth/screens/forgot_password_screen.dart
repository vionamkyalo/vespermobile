import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/inputs.dart';
import '../../../core/widgets/vesper_logo.dart';
import '../viewmodel/sign_in_view_model.dart';

void _notice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    context.read<SignInViewModel>().clearError(notify: false);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final viewModel = context.read<SignInViewModel>();
    if (viewModel.busy) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await viewModel.forgotPassword(_email.text.trim());
    if (!mounted) return;
    if (!ok) {
      _notice(context, viewModel.error ?? 'Could not send the code');
      return;
    }
    _notice(
      context,
      'If an account exists for that email, a code is on its way.',
    );
    _openReset();
  }

  void _openReset() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResetPasswordScreen(email: _email.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignInViewModel>();

    return _AuthCard(
      formKey: _formKey,
      title: 'Forgot password',
      subtitle:
          'Enter your email address and we will email you a 6-digit code to reset your password.',
      children: [
        VesperTextField(
          label: 'Email',
          controller: _email,
          hint: 'you@example.org',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          validator: viewModel.validateEmail,
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: 26),
        PrimaryButton(label: 'Send code', busy: viewModel.busy, onPressed: _send),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: _openReset,
            child: const Text(
              'I already have a code',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Back to sign in',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}



class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SignInViewModel>().clearError(notify: false);
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final viewModel = context.read<SignInViewModel>();
    if (viewModel.busy) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await viewModel.resetPassword(
      email: widget.email,
      code: _code.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    if (!ok) {
      _notice(context, viewModel.error ?? 'Could not change your password');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context)
      ..pop()
      ..pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Password changed. Sign in with your new password.'),
        ),
      );
  }

  Future<void> _resend() async {
    final viewModel = context.read<SignInViewModel>();
    if (viewModel.busy) return;
    final ok = await viewModel.forgotPassword(widget.email);
    if (!mounted) return;
    _notice(
      context,
      ok
          ? 'A new code is on its way.'
          : (viewModel.error ?? 'Could not send a new code'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignInViewModel>();

    return _AuthCard(
      formKey: _formKey,
      title: 'Choose a new password',
      subtitle: 'Enter the 6-digit code we sent to ${widget.email}.',
      children: [
        VesperTextField(
          label: 'Code',
          controller: _code,
          hint: '6-digit code',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          validator: viewModel.validateResetCode,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: viewModel.busy ? null : _resend,
            child: const Text(
              'Resend code',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        VesperTextField(
          label: 'New password',
          controller: _password,
          obscureText: viewModel.passwordHidden,
          textInputAction: TextInputAction.next,
          validator: viewModel.validateNewPassword,
          suffix: IconButton(
            tooltip: viewModel.passwordHidden ? 'Show password' : 'Hide password',
            icon: Icon(
              viewModel.passwordHidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.white,
            ),
            onPressed: viewModel.togglePasswordVisibility,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'At least 12 characters, with a capital letter, a small letter and a number.',
          style: TextStyle(color: AppColors.navy, fontSize: 12),
        ),
        const SizedBox(height: 16),
        VesperTextField(
          label: 'Confirm new password',
          controller: _confirm,
          obscureText: viewModel.passwordHidden,
          textInputAction: TextInputAction.done,
          validator: (v) => v != _password.text ? 'Passwords do not match' : null,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 26),
        PrimaryButton(
          label: 'Save new password',
          busy: viewModel.busy,
          onPressed: _save,
        ),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Back',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.formKey,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VesperLogo(height: 34, showText: false),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                decoration: BoxDecoration(
                  color: AppColors.sky,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ...children,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}