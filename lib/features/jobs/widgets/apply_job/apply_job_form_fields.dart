import 'package:flutter/material.dart';

import 'apply_job_colors.dart';

class ApplyInputField extends StatelessWidget {
  final String label;
  final String hint;
  final bool isTextArea;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool readOnly;

  const ApplyInputField({
    super.key,
    required this.label,
    required this.hint,
    this.isTextArea = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: applyBrown,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          maxLines: isTextArea ? 4 : 1,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
            filled: true,
            fillColor: readOnly
                ? Colors.grey[100]
                : applyFieldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

class ApplyDateField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool readOnly;

  const ApplyDateField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: applyBrown,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
            filled: true,
            fillColor: readOnly
                ? Colors.grey[100]
                : applyFieldBackground,
            suffixIcon: Icon(
              Icons.calendar_month_rounded,
              color: readOnly ? Colors.grey : applyDarkBrown,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
