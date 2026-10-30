import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/vesper_logo.dart';
import 'view_models/violation_form_view_model.dart';

class ViolationFormScreen extends StatefulWidget {
  const ViolationFormScreen({super.key});

  @override
  State<ViolationFormScreen> createState() => _ViolationFormScreenState();
}

class _ViolationFormScreenState extends State<ViolationFormScreen> {
  late final _officerController = TextEditingController(
    text: context.read<ViolationFormViewModel>().officerName,
  );
  final _violationsController = TextEditingController();
  final _rigsController = TextEditingController();
  final _notesController = TextEditingController();

  StreamSubscription<String>? _noticeSubscription;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<ViolationFormViewModel>();
    _noticeSubscription = viewModel.notices.listen(_showNotice);
    final initial = viewModel.initialNotice;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNotice(initial));
    }
  }

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 8)),
      );
  }

  @override
  void dispose() {
    _noticeSubscription?.cancel();
    _officerController.dispose();
    _violationsController.dispose();
    _rigsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();

    final viewModel = context.read<ViolationFormViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final submitted = await viewModel.submit();
    if (!mounted) return;

    if (!submitted) {
      final message = viewModel.errorMessage;
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    _violationsController.clear();
    _rigsController.clear();
    _notesController.clear();

    final outcome = viewModel.lastOutcome;
    final message = switch (outcome) {
      SubmitOutcome.sent => 'Report sent to the server.',
      SubmitOutcome.rejected =>
        'The server did not accept this report: '
            '${viewModel.rejectionReason ?? 'unknown reason'}. '
            'It is kept on this phone.',
      _ => 'Saved on the phone',
    };

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: outcome == SubmitOutcome.sent ? 4 : 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ViolationFormViewModel>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const _Header(),
            const SizedBox(height: 12),
            const Text(
              'Violation Form',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Officer'),
            _FormTextField(
              controller: _officerController,
              readOnly: true,
              errorText: viewModel.officerError,
              textCapitalization: TextCapitalization.words,
            ),
            const _FieldLabel('Zone'),
            _OptionDropdown(
              value: viewModel.zone,
              options: ViolationFormViewModel.zoneOptions,
              onChanged: viewModel.updateZone,
            ),
            const _FieldLabel('Violation type'),
            _OptionDropdown(
              value: viewModel.violationType,
              options: ViolationFormViewModel.violationTypeOptions.keys
                  .toList(),
              onChanged: viewModel.updateViolationType,
            ),
            const _FieldLabel('Violations found'),
            _FormTextField(
              controller: _violationsController,
              onChanged: viewModel.updateViolationsFound,
              errorText: viewModel.violationsFoundError,
              minLines: 3,
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            const _FieldLabel('Rigs observed'),
            _FormTextField(
              controller: _rigsController,
              onChanged: viewModel.updateRigsObserved,
              errorText: viewModel.rigsObservedError,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const _FieldLabel('Notes'),
            _FormTextField(
              controller: _notesController,
              onChanged: viewModel.updateNotes,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            _SubmitButton(
              isLoading: viewModel.isSubmitting,
              onPressed: _onSubmit,
            ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VesperLogo(showText: false),
        const Spacer(),
        FormTypeSelector(
          current: 'Violation',
          onSelected: (type) {
            switch (type) {
              case 'Inspection':
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.inspectionForm,
                );
                break;

              case 'Catch check':
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.catchCheckForm,
                );
                break;
            }
          },
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({String? errorText}) {
  final shape = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  );

  return InputDecoration(
    filled: true,
    fillColor: AppColors.sky,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    errorText: errorText,
    border: shape,
    enabledBorder: shape,
    focusedBorder: shape.copyWith(
      borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
    ),
    errorBorder: shape.copyWith(
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: shape.copyWith(
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
  );
}

class _FormTextField extends StatelessWidget {
  const _FormTextField({
    required this.controller,
    this.onChanged,
    this.readOnly = false,
    this.errorText,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final String? errorText;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: AppColors.ink),
      decoration: _fieldDecoration(errorText: errorText),
    );
  }
}

class _OptionDropdown extends StatelessWidget {
  const _OptionDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.sky,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.ink),
          style: const TextStyle(color: AppColors.ink, fontSize: 16),
          dropdownColor: AppColors.white,
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.white,
                ),
              )
            : const Text(
                'Submit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
