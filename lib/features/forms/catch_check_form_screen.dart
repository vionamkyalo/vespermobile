import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/vesper_logo.dart';
import 'view_models/catch_check_form_view_model.dart';

class CatchCheckFormScreen extends StatelessWidget {
  const CatchCheckFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CatchCheckFormViewModel(),
      child: const _CatchCheckFormView(),
    );
  }
}

class _CatchCheckFormView extends StatefulWidget {
  const _CatchCheckFormView();

  @override
  State<_CatchCheckFormView> createState() => _CatchCheckFormViewState();
}

class _CatchCheckFormViewState extends State<_CatchCheckFormView> {
  final _formKey = GlobalKey<FormState>();
  final _officerController = TextEditingController();
  final _nightsController = TextEditingController();
  final _rigIdentifierController = TextEditingController();
  final _fishTypeController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _officerController.dispose();
    _nightsController.dispose();
    _rigIdentifierController.dispose();
    _fishTypeController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _openForm(String type) {
    switch (type) {
      case 'Inspection':
        Navigator.pushReplacementNamed(context, AppRoutes.inspectionForm);
        break;

      case 'Violation':
        Navigator.pushReplacementNamed(context, AppRoutes.violationForm);
        break;
    }
  }

  Future<void> _submit(CatchCheckFormViewModel viewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final saved = await viewModel.submit(
      officer: _officerController.text,
      nights: _nightsController.text,
      rigIdentifier: _rigIdentifierController.text,
      fishType: _fishTypeController.text,
      weightPerNight: _weightController.text,
      notes: _notesController.text,
    );

    if (!mounted || !saved) return;

    _formKey.currentState?.reset();
    for (final controller in [
      _officerController,
      _nightsController,
      _rigIdentifierController,
      _fishTypeController,
      _weightController,
      _notesController,
    ]) {
      controller.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(viewModel.message ?? 'Saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CatchCheckFormViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VesperLogo(showText: false),
                      const Spacer(),
                      FormTypeSelector(
                        current: 'Catch check',
                        onSelected: _openForm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Catch check Form',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  VesperField(
                    label: 'Officer',
                    controller: _officerController,
                    validator: viewModel.validateOfficer,
                  ),
                  VesperDropdown(
                    label: 'Zone',
                    value: viewModel.zone,
                    items: CatchCheckFormViewModel.zoneOptions,
                    onChanged: viewModel.updateZone,
                  ),
                  VesperField(
                    label: 'Catch duration (Number of nights)',
                    controller: _nightsController,
                    keyboardType: TextInputType.number,
                    validator: viewModel.validateNights,
                  ),
                  VesperField(
                    label: 'Rig Identifier',
                    controller: _rigIdentifierController,
                    validator: viewModel.validateRigIdentifier,
                  ),
                  VesperField(
                    label: 'Type of fish',
                    controller: _fishTypeController,
                    validator: viewModel.validateFishType,
                  ),
                  VesperField(
                    label: 'Catch Weight (kg per night)',
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: viewModel.validateWeight,
                  ),
                  VesperField(
                    label: 'Notes',
                    controller: _notesController,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: 'Submit',
                    busy: viewModel.isSubmitting,
                    onPressed: () => _submit(viewModel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}