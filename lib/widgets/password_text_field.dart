import 'package:flutter/material.dart';
import 'custom_text_field.dart';

class PasswordTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final bool enabled;

  const PasswordTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.prefixIcon,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      obscureText: _obscureText,
      validator: widget.validator,
      prefixIcon: widget.prefixIcon,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: widget.enabled ? _togglePasswordVisibility : null,
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      ),
    );
  }
}
