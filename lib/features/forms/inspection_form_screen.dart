import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/vesper_logo.dart';

class InspectionFormScreen extends StatefulWidget {
  const InspectionFormScreen({super.key, this.onFormTypeSelected});

  final ValueChanged<String>? onFormTypeSelected;

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  static const _zones = ['Binga', 'Kariba', 'Siavonga', 'Sinazongwe', 'Mlibizi'];

  final _formKey = GlobalKey<FormState>();
  final _officer = TextEditingController();
  final _rigs = TextEditingController();
  final _coords = TextEditingController();
  final _notes = TextEditingController();
  String _zone = _zones.first;

  @override
  void dispose() {
    _officer.dispose();
    _rigs.dispose();
    _coords.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'officer': _officer.text.trim(),
      'zone': _zone,
      'rigs_observed': int.tryParse(_rigs.text.trim()) ?? 0,
      'coordinates': _coords.text.trim(),
      'notes': _notes.text.trim(),
    };
    debugPrint('Inspection submitted: $data'); 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inspection submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      const VesperLogo(),
                      const Spacer(),
                      FormTypeSelector(
                        current: 'Inspection',
                        onSelected: (t) => widget.onFormTypeSelected?.call(t),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Inspection Form',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  VesperField(
                    label: 'Officer',
                    controller: _officer,
                    validator: _required,
                  ),
                  VesperDropdown(
                    label: 'Zone',
                    value: _zone,
                    items: _zones,
                    onChanged: (v) => setState(() => _zone = v ?? _zone),
                  ),
                  VesperField(
                    label: 'Rigs observed',
                    controller: _rigs,
                    keyboardType: TextInputType.number,
                    validator: _required,
                  ),
                  VesperField(
                    label: 'Coordinates',
                    controller: _coords,
                    validator: _required,
                  ),
                  VesperField(
                    label: 'Notes',
                    controller: _notes,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(label: 'Submit', onPressed: _submit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}