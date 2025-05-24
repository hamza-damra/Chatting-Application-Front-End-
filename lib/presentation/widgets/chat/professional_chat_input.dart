import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Professional chat input widget with modern design and smooth animations
class ProfessionalChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSendMessage;
  final VoidCallback? onAttachmentPressed;
  final Function(String)? onChanged;
  final Function(bool)? onTypingChanged;
  final bool isEnabled;
  final bool isAttachmentUploading;
  final String hintText;
  final int maxLines;
  final int minLines;

  const ProfessionalChatInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    this.onAttachmentPressed,
    this.onChanged,
    this.onTypingChanged,
    this.isEnabled = true,
    this.isAttachmentUploading = false,
    this.hintText = 'Type a message...',
    this.maxLines = 6,
    this.minLines = 1,
  });

  @override
  State<ProfessionalChatInput> createState() => _ProfessionalChatInputState();
}

class _ProfessionalChatInputState extends State<ProfessionalChatInput>
    with TickerProviderStateMixin {
  late AnimationController _focusAnimationController;
  late AnimationController _sendButtonAnimationController;
  late Animation<double> _focusAnimation;
  late Animation<double> _sendButtonScaleAnimation;

  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Initialize animations
    _focusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _focusAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _sendButtonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _sendButtonAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Setup focus listener
    _focusNode.addListener(_onFocusChanged);

    // Setup text controller listener
    widget.controller.addListener(_onTextChanged);

    // Initialize text state
    _hasText = widget.controller.text.isNotEmpty;
    if (_hasText) {
      _sendButtonAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _focusAnimationController.dispose();
    _sendButtonAnimationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _focusAnimationController.forward();
    } else {
      _focusAnimationController.reverse();
    }
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;

    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });

      if (hasText) {
        _sendButtonAnimationController.forward();
      } else {
        _sendButtonAnimationController.reverse();
      }

      // Notify typing status
      widget.onTypingChanged?.call(hasText);
    }

    // Call the onChanged callback
    widget.onChanged?.call(widget.controller.text);
  }

  void _handleSendMessage() {
    if (_hasText && widget.isEnabled) {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Trigger send animation
      _sendButtonAnimationController.reverse().then((_) {
        _sendButtonAnimationController.forward();
      });

      widget.onSendMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(
                  isDark ? 51 : 26,
                ), // 0.2 : 0.1 opacity
                blurRadius: 8 + (_focusAnimation.value * 4),
                offset: Offset(0, -2 - (_focusAnimation.value * 2)),
                spreadRadius: _focusAnimation.value * 1,
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                if (widget.onAttachmentPressed != null)
                  _buildAttachmentButton(theme, isDark),

                const SizedBox(width: 8),

                // Message input field
                Expanded(child: _buildInputField(theme, isDark)),

                const SizedBox(width: 8),

                // Send button
                _buildSendButton(theme, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentButton(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              widget.isEnabled && !widget.isAttachmentUploading
                  ? widget.onAttachmentPressed
                  : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  _isFocused
                      ? theme.colorScheme.primary.withAlpha(26)
                      : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    _isFocused
                        ? theme.colorScheme.primary.withAlpha(77)
                        : Colors.transparent,
                width: 1,
              ),
            ),
            child:
                widget.isAttachmentUploading
                    ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    )
                    : Icon(
                      Icons.attach_file_rounded,
                      color:
                          _isFocused
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(ThemeData theme, bool isDark) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              _isFocused
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withAlpha(77),
          width: _isFocused ? 1.5 : 0.8,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.isEnabled,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.newline,
        onSubmitted: (_) => _handleSendMessage(),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildSendButton(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _sendButtonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _sendButtonScaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _hasText && widget.isEnabled ? _handleSendMessage : null,
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        _hasText && widget.isEnabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow:
                        _hasText && widget.isEnabled
                            ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withAlpha(77),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color:
                        _hasText && widget.isEnabled
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
