// lib/features/auth/widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? hintText;
  final IconData? prefixIcon;

  const CustomTextField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.hintText,
    this.prefixIcon,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final bool showToggle = widget.isPassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label di atas input
        Text(
          widget.label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        // Input Field
        TextField(
          controller: widget.controller,
          obscureText: showToggle ? _obscure : false,
          keyboardType: widget.keyboardType,
          style: const TextStyle(color: AppColors.textMain),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              color: AppColors.textAccent,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),

            // Prefix icon (opsional)
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: AppColors.textAccent,
                  )
                : null,

            // Suffix icon toggle password
            suffixIcon: showToggle
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textAccent,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,

            // Border saat tidak fokus
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.inputBorder,
              ),
            ),

            // Border saat fokus
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.buttonMain,
                width: 1.5,
              ),
            ),

            // Border saat error
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}