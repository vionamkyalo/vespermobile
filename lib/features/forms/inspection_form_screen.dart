import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/vesper_logo.dart';
import 'view_models/inspection_form_view_model.dart';

class InspectionFormScreen extends StatefulWidget {
  const InspectionFormScreen({super.key, this.onFormTypeSelected});

  final ValueChanged<String>? onFormTypeSelected;

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _officer = TextEditingController();
  final _rigs = TextEditingController();
  final _coords = TextEditingController();
  final _notes = TextEditingController();

  String? _zone;
  InspectionType _type = InspectionType.site;
  InspectionOutcome _outcome = InspectionOutcome.activityConsistent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<InspectionFormViewModel>().load();
      await _fillLocation();
    });
  }

  @override
  void dispose() {
    _officer.dispose();
    _rigs.dispose();
    _coords.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _fillLocation() async {
    if (!mounted) return;
    final value = await context.read<InspectionFormViewModel>().locate();
    if (value != null && mounted) _coords.text = value;
  }

  String? _zoneValue(List<String> names) {
    if (names.isEmpty) return null;
    return names.contains(_zone) ? _zone : names.first;
  }

  String? _rigsValidator(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a number';
    if (n < 0 || n > 1000) return 'Enter 0 to 1000';
    return null;
  }

  String? _coordsValidator(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Tap the location icon or type e.g. -16.52, 28.76';
    }
    return InspectionFormViewModel.parseCoordinates(v) == null
        ? 'Use the format: latitude, longitude'
        : null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<InspectionFormViewModel>();
    final names = [for (final z in vm.zones) z.name];
    final zone = _zoneValue(names);
    final coords = InspectionFormViewModel.parseCoordinates(_coords.text);
    if (zone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No zone available to inspect.')),
      );
      return;
    }
    if (coords == null) return;

    final result = await vm.submit(
      zoneName: zone,
      type: _type,
      outcome: _outcome,
      rigs: int.parse(_rigs.text.trim()),
      latitude: coords.lat,
      longitude: coords.lng,
      notes: _notes.text,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (result.status == SubmitStatus.rejected) return;

    _rigs.clear();
    _notes.clear();
    if (result.status == SubmitStatus.sent) {
    }
    _fillLocation();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InspectionFormViewModel>();
    final names = [for (final z in vm.zones) z.name];
    final zoneValue = _zoneValue(names);

    if (_officer.text != vm.officerName) _officer.text = vm.officerName;

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
                  if (vm.loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (vm.loadError != null) ...[
                    Text(
                      vm.loadError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    TextButton(
                      onPressed: () => vm.load(),
                      child: const Text('Try again'),
                    ),
                  ] else ...[
                    VesperField(
                      label: 'Officer',
                      controller: _officer,
                      readOnly: true,
                    ),
                    if (zoneValue == null)
                      const Padding(
                        padding: EdgeInsets.only(left: 12, bottom: 14),
                        child: Text(
                          'No active zones yet. Ask a coordinator to activate zones.',
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    else
                      VesperDropdown(
                        label: 'Zone',
                        value: zoneValue,
                        items: names,
                        onChanged: (v) => setState(() => _zone = v),
                      ),
                    VesperDropdown(
                      label: 'Inspection type',
                      value: _type.label,
                      items: [for (final t in InspectionType.values) t.label],
                      onChanged: (v) => setState(() {
                        _type = InspectionType.values.firstWhere(
                          (t) => t.label == v,
                          orElse: () => _type,
                        );
                      }),
                    ),
                    VesperDropdown(
                      label: 'Outcome',
                      value: _outcome.label,
                      items: [
                        for (final o in InspectionOutcome.values) o.label,
                      ],
                      onChanged: (v) => setState(() {
                        _outcome = InspectionOutcome.values.firstWhere(
                          (o) => o.label == v,
                          orElse: () => _outcome,
                        );
                      }),
                    ),
                    VesperField(
                      label: 'Rigs observed',
                      controller: _rigs,
                      keyboardType: TextInputType.number,
                      validator: _rigsValidator,
                    ),
                    VesperField(
                      label: 'Coordinates',
                      controller: _coords,
                      validator: _coordsValidator,
                      suffixIcon: vm.locating
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: _fillLocation,
                            ),
                    ),
                    if (vm.locationError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 12),
                        child: Text(
                          vm.locationError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    VesperField(
                      label: 'Notes',
                      controller: _notes,
                      maxLines: 6,
                      validator: (v) => (v ?? '').length > 2000
                          ? 'Keep notes under 2000 characters'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: vm.submitting ? 'Sending…' : 'Submit',
                      onPressed: vm.submitting ? () {} : _submit,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}