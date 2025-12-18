import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// A customizable search bar component with loading indicator,
/// clear button, and search icon.
///
/// The search bar expands to fill available width while respecting
/// maximum width constraints on larger screens.
///
/// Requirements: 4.2, 8.4
class SearchBarWidget extends StatefulWidget {
  /// Controller for the search text field.
  final TextEditingController? controller;

  /// Hint text displayed when the field is empty.
  final String hintText;

  /// Whether the search is currently loading.
  final bool isLoading;

  /// Callback when the clear button is tapped.
  final VoidCallback? onClear;

  /// Callback when the text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when the search is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Whether the search bar is enabled.
  final bool enabled;

  /// Whether to autofocus the search field.
  final bool autofocus;

  /// Custom padding around the search bar.
  final EdgeInsetsGeometry? padding;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Maximum width constraint for the search bar.
  /// If null, the search bar will expand to fill available width.
  final double? maxWidth;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.isLoading = false,
    this.onClear,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.padding,
    this.semanticLabel,
    this.maxWidth,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();

    final effectivePadding =
        widget.padding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        );

    // Get responsive max width - use provided maxWidth or calculate based on screen size
    final responsiveMaxWidth =
        widget.maxWidth ??
        ResponsiveLayout.value<double>(
          context: context,
          mobile: double.infinity,
          tablet: ResponsiveMaxWidths.chatList,
          desktop: ResponsiveMaxWidths.chatList,
        );

    return Semantics(
      textField: true,
      label: widget.semanticLabel ?? 'Search',
      child: Center(
        child: Padding(
          padding: effectivePadding,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: Container(
              height: 44,
              constraints: BoxConstraints(maxWidth: responsiveMaxWidth),
              decoration: BoxDecoration(color: colors.surfaceHighest),
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: 16, color: colors.textPrimary),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  filled: false,
                  isDense: false,
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: colors.textTertiary,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 12,
                  ),
                  prefixIcon:
                      widget.isLoading
                          ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colors.textTertiary,
                                ),
                              ),
                            ),
                          )
                          : Padding(
                            padding: const EdgeInsets.only(
                              left: 12.0,
                              right: 8.0,
                            ),
                            child: Icon(
                              Icons.search,
                              color: colors.textTertiary,
                              size: 20,
                            ),
                          ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 44,
                  ),
                  suffixIcon:
                      _hasText && widget.enabled
                          ? IconButton(
                            icon: Icon(
                              Icons.close,
                              color: colors.textTertiary,
                              size: 18,
                            ),
                            onPressed: _handleClear,
                            splashRadius: 16,
                          )
                          : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
