import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// A customizable text field component with visual states,
/// inline validation, and password visibility toggle.
///
/// Requirements: 3.2, 3.3, 3.4
class AppTextField extends StatefulWidget {
  /// Controller for the text field.
  final TextEditingController? controller;

  /// Hint text displayed when the field is empty.
  final String? hintText;

  /// Label text displayed above the field.
  final String? labelText;

  /// Error message to display below the field.
  final String? errorText;

  /// Helper text displayed below the field when no error.
  final String? helperText;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether this is a password field with visibility toggle.
  final bool isPassword;

  /// Callback when text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when field is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Validator function for form validation.
  final String? Function(String?)? validator;

  /// Keyboard type for the field.
  final TextInputType? keyboardType;

  /// Text input action.
  final TextInputAction? textInputAction;

  /// Focus node for the field.
  final FocusNode? focusNode;

  /// Whether to autofocus this field.
  final bool autofocus;

  /// Maximum number of lines.
  final int maxLines;

  /// Prefix icon.
  final IconData? prefixIcon;

  /// Suffix icon (ignored if isPassword is true).
  final IconData? suffixIcon;

  /// Callback when suffix icon is tapped.
  final VoidCallback? onSuffixTap;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.isPassword = false,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.semanticLabel,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();

    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final borderColor = _getBorderColor(colors, hasError);
    final fillColor = widget.enabled ? colors.surface : colors.surfaceElevated;

    return Semantics(
      textField: true,
      enabled: widget.enabled,
      label: widget.semanticLabel ?? widget.labelText ?? widget.hintText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.labelText != null) ...[
            Text(
              widget.labelText!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: hasError ? colors.error : colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            obscureText: widget.isPassword && _obscureText,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofocus: widget.autofocus,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            style: TextStyle(
              fontSize: 16,
              color: widget.enabled ? colors.textPrimary : colors.textTertiary,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 16,
                color: colors.textTertiary,
              ),
              filled: true,
              fillColor: fillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: hasError
                          ? colors.error
                          : (_isFocused ? colors.primary : colors.textTertiary),
                      size: AppSpacing.iconLg,
                    )
                  : null,
              suffixIcon: _buildSuffixIcon(colors, hasError),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: borderColor, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: hasError ? colors.error : colors.outline,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: hasError ? colors.error : colors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: colors.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: colors.error, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: colors.outline.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              // Don't show error text in the default location
              // We handle it ourselves below
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: colors.error,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.error,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (widget.helperText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.helperText!,
              style: TextStyle(
                fontSize: 12,
                color: colors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildSuffixIcon(AppColors colors, bool hasError) {
    if (widget.isPassword) {
      return Semantics(
        button: true,
        label: _obscureText ? 'Show password' : 'Hide password',
        child: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: hasError
                ? colors.error
                : (_isFocused ? colors.primary : colors.textTertiary),
            size: AppSpacing.iconLg,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      );
    }

    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: hasError
              ? colors.error
              : (_isFocused ? colors.primary : colors.textTertiary),
          size: AppSpacing.iconLg,
        ),
        onPressed: widget.onSuffixTap,
      );
    }

    return null;
  }

  Color _getBorderColor(AppColors colors, bool hasError) {
    if (hasError) return colors.error;
    if (!widget.enabled) return colors.outline.withValues(alpha: 0.5);
    if (_isFocused) return colors.primary;
    return colors.outline;
  }
}
