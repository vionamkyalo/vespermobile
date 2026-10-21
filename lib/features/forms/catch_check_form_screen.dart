import 'package:flutter/material.dart';
import '../../core/widgets/vesper_logo.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/buttons.dart';
import '../../core/theme/app_colors.dart';

class CatchCheckFormScreen extends StatefulWidget {
  const CatchCheckFormScreen({super.key});

  @override
  State<CatchCheckFormScreen> createState() => _CatchCheckFormScreenState();
}

class _CatchCheckFormScreenState extends State<CatchCheckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _officerController = TextEditingController();
  final _durationController = TextEditingController();
  final _rigIdentifierController = TextEditingController();
  final _fishTypeController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected values
  String _selectedZone = 'Binga';
  final List<String> _zones = ['Binga', 'Kariba', 'Changa', 'Mlibizi'];

  // Current Form Screen Dropdown Selector State
  String _currentForm = 'Catch';
  final List<String> _formsList = ['Catch', 'Inspection', 'Violation'];

  @override
  void dispose() {
    _officerController.dispose();
    _durationController.dispose();
    _rigIdentifierController.dispose();
    _fishTypeController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const VesperLogo(height: 32),
            
            // Styled Dropdown to change the Form layout directly
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentForm,
                  dropdownColor: AppColors.navy,
                  icon: const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _currentForm = newValue);
                      // Route navigation switch matching your design choices
                      if (newValue == 'Inspection') {
                        Navigator.pushNamed(context, '/forms/inspection');
                      } else if (newValue == 'Violation') {
                        Navigator.pushNamed(context, '/forms/violation');
                      }
                    }
                  },
                  items: _formsList.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text('$value '),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Catch check Form',
                style: TextStyle(color: AppColors.navy, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              VesperTextField(
                label: 'Officer',
                controller: _officerController,
                hint: 'Enter officer name',
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Zone', style: TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedZone,
                        dropdownColor: AppColors.navy,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.cyan),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedZone = newValue);
                          }
                        },
                        items: _zones.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              VesperTextField(
                label: 'Catch duration (Number of nights)',
                controller: _durationController,
                hint: 'Enter number of nights',
              ),
              const SizedBox(height: 16),
              VesperTextField(
                label: 'Rig Identifier',
                controller: _rigIdentifierController,
                hint: 'Enter rig identifier',
              ),
              const SizedBox(height: 16),
              VesperTextField(
                label: 'Type of fish',
                controller: _fishTypeController,
                hint: 'Enter fish type',
              ),
              const SizedBox(height: 16),
              VesperTextField(
                label: 'Catch Weight( kg per night)',
                controller: _weightController,
                hint: 'Enter weight in kg',
              ),
              const SizedBox(height: 16),
              VesperTextField(
                label: 'Notes',
                controller: _notesController,
                hint: 'Add extra details here',
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Submit',
                onPressed: () {},
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
