import 'package:flutter/material.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_text_field.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _resetSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _resetSent = true;
          _isLoading = false;
        });

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colors = isDark ? const DarkAppColors() : const LightAppColors();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: colors.textOnPrimary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text('Password reset email sent'),
                ),
              ],
            ),
            backgroundColor: colors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            margin: const EdgeInsets.all(AppSpacing.lg),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.secondary.withValues(alpha: 0.02),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getHorizontalPadding(constraints.maxWidth),
                    vertical: _getVerticalPadding(
                      constraints.maxHeight,
                      isLandscape,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? ResponsiveMaxWidths.authForm : double.infinity,
                    ),
                    child: _buildResponsiveForgotPasswordForm(
                      theme,
                      isTablet,
                      isLandscape,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _getHorizontalPadding(double screenWidth) {
    if (screenWidth > 600) return 48.0; // Tablet
    if (screenWidth > 400) return 24.0; // Large phone
    return 16.0; // Small phone
  }

  double _getVerticalPadding(double screenHeight, bool isLandscape) {
    if (isLandscape) return 16.0;
    if (screenHeight > 800) return 32.0; // Tall screen
    return 16.0; // Standard screen
  }

  Widget _buildResponsiveForgotPasswordForm(
    ThemeData theme,
    bool isTablet,
    bool isLandscape,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();
    
    final containerPadding = isLandscape ? AppSpacing.xl : (isTablet ? AppSpacing.huge : AppSpacing.xxxl);
    final sectionSpacing = isLandscape ? AppSpacing.xl : AppSpacing.xxxl;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(isLandscape ? AppSpacing.radiusLg : AppSpacing.radiusXxl),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.1),
            blurRadius: isLandscape ? 12 : 20,
            offset: Offset(0, isLandscape ? 4 : 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Icon
            Icon(
              Icons.lock_reset_rounded,
              size: isLandscape ? 40 : 60,
              color: colors.primary,
            ),
            SizedBox(height: isLandscape ? AppSpacing.sm : AppSpacing.lg),

            // Title
            Text(
              'Reset Your Password',
              textAlign: TextAlign.center,
              style: (isLandscape
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
            ),
            SizedBox(height: isLandscape ? AppSpacing.sm : AppSpacing.lg),

            // Description
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              textAlign: TextAlign.center,
              style: (isLandscape
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            SizedBox(height: sectionSpacing),

            if (!_resetSent) ...[
              _buildEmailForm(colors, isLandscape, sectionSpacing),
            ] else ...[
              _buildSuccessMessage(theme, colors, isLandscape),
            ],

            SizedBox(height: isLandscape ? AppSpacing.lg : AppSpacing.xxl),

            // Back to Login Link
            if (!_resetSent)
              _buildResponsiveLoginLink(theme, isLandscape, colors),
          ],
        ),
      ),
    );
  }


  Widget _buildEmailForm(AppColors colors, bool isLandscape, double sectionSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field
        AppTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          enabled: !_isLoading,
          textInputAction: TextInputAction.done,
          semanticLabel: 'Email input field',
          onSubmitted: (_) => _resetPassword(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        SizedBox(height: sectionSpacing),

        // Reset Button
        AppButton(
          label: 'Reset Password',
          onPressed: _isLoading ? null : _resetPassword,
          isLoading: _isLoading,
          expanded: true,
          size: isLandscape ? AppButtonSize.medium : AppButtonSize.large,
          semanticLabel: 'Reset password button',
        ),
      ],
    );
  }

  Widget _buildSuccessMessage(ThemeData theme, AppColors colors, bool isLandscape) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isLandscape ? AppSpacing.lg : AppSpacing.xl),
          decoration: BoxDecoration(
            color: colors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: colors.success.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: colors.success,
                size: isLandscape ? 36 : 48,
              ),
              SizedBox(height: isLandscape ? AppSpacing.sm : AppSpacing.lg),
              Text(
                'Password Reset Email Sent',
                style: (isLandscape
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.titleLarge)
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.success,
                    ),
              ),
              SizedBox(height: isLandscape ? AppSpacing.xs : AppSpacing.sm),
              Text(
                'We\'ve sent a password reset link to ${_emailController.text}. Please check your email and follow the instructions to reset your password.',
                textAlign: TextAlign.center,
                style: (isLandscape
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(height: isLandscape ? AppSpacing.lg : AppSpacing.xxl),

        // Back to Login Button
        AppButton(
          label: 'Back to Login',
          onPressed: () {
            Navigator.pop(context);
          },
          expanded: true,
          size: isLandscape ? AppButtonSize.medium : AppButtonSize.large,
          semanticLabel: 'Back to login button',
        ),
      ],
    );
  }

  Widget _buildResponsiveLoginLink(ThemeData theme, bool isLandscape, AppColors colors) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(isLandscape ? AppSpacing.radiusMd : AppSpacing.radiusLg),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              'Remember your password?',
              style: (isLandscape
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
          SizedBox(width: isLandscape ? AppSpacing.sm : AppSpacing.sm),
          Semantics(
            button: true,
            label: 'Go to login screen',
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? AppSpacing.sm : AppSpacing.md,
                  vertical: isLandscape ? 3 : AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isLandscape ? AppSpacing.radiusSm : AppSpacing.radiusMd),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Login',
                  style: (isLandscape
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
