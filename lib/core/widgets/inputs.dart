import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class VesperField extends StatelessWidget {
  const VesperField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: _decoration(),
      ),
    );
  }
}

class VesperDropdown extends StatelessWidget {
  const VesperDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
        dropdownColor: AppColors.fieldBlue,
        style: const TextStyle(fontSize: 18, color: Colors.black),
        decoration: _decoration(),
        items: [
          for (final i in items) DropdownMenuItem(value: i, child: Text(i)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class FormTypeSelector extends StatelessWidget {
  const FormTypeSelector({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final String current;
  final ValueChanged<String> onSelected;

  static const types = ['Inspection', 'Catch check', 'Violation'];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 44),
      itemBuilder: (_) => [
        for (final t in types) PopupMenuItem(value: t, child: Text(t)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

InputDecoration _decoration() => InputDecoration(
      filled: true,
      fillColor: AppColors.fieldBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}


class PillDropdown extends StatelessWidget {
  const PillDropdown({
    super.key,
    required this.current,
    required this.items,
    required this.onSelected,
  });

  final String current;
  final List<String> items;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 48),
      itemBuilder: (_) => [
        for (final i in items) PopupMenuItem(value: i, child: Text(i)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}