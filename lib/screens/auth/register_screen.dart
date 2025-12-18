import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/api_auth_provider.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_text_field.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _register() async {
    _clearError();
    
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<ApiAuthProvider>(context, listen: false);

      final fullName =
          "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";
      final username =
          _emailController.text.split('@')[0]; // Generate username from email

      final success = await authProvider.register(
        username: username,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: fullName,
      );

      if (!success && mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colors = isDark ? const DarkAppColors() : const LightAppColors();
        
        setState(() {
          _errorMessage = authProvider.error ?? 'Registration failed';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: colors.textOnPrimary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: colors.textOnPrimary),
                  ),
                ),
              ],
            ),
            backgroundColor: colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            margin: const EdgeInsets.all(AppSpacing.lg),
          ),
        );
      } else if (mounted) {
        Navigator.pop(context); // Go back to login screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<ApiAuthProvider>(context);
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
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
                    child: _buildResponsiveRegisterForm(
                      authProvider,
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


  Widget _buildResponsiveRegisterForm(
    ApiAuthProvider authProvider,
    ThemeData theme,
    bool isTablet,
    bool isLandscape,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final colors = isDark ? const DarkAppColors() : const LightAppColors();
    
    final containerPadding = isLandscape ? AppSpacing.xl : (isTablet ? AppSpacing.huge : AppSpacing.xxxl);
    final fieldSpacing = isLandscape ? AppSpacing.lg : AppSpacing.xl;
    final sectionSpacing = isLandscape ? AppSpacing.xl : AppSpacing.xxxl;
    final isLoading = authProvider.isLoading;

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
              Icons.person_add_rounded,
              size: isLandscape ? 40 : 60,
              color: colors.primary,
            ),
            SizedBox(height: isLandscape ? AppSpacing.sm : AppSpacing.lg),

            // Title
            Text(
              'Join Vector',
              textAlign: TextAlign.center,
              style: (isLandscape
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
            ),
            SizedBox(height: sectionSpacing),

            // Error Banner
            if (_errorMessage != null) ...[
              _buildErrorBanner(colors),
              SizedBox(height: fieldSpacing),
            ],

            // First Name Field
            AppTextField(
              controller: _firstNameController,
              labelText: 'First Name',
              hintText: 'Enter your first name',
              prefixIcon: Icons.person_outline,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              semanticLabel: 'First name input field',
              onChanged: (_) => _clearError(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
            ),
            SizedBox(height: fieldSpacing),

            // Last Name Field
            AppTextField(
              controller: _lastNameController,
              labelText: 'Last Name',
              hintText: 'Enter your last name',
              prefixIcon: Icons.person_outline,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              semanticLabel: 'Last name input field',
              onChanged: (_) => _clearError(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your last name';
                }
                return null;
              },
            ),
            SizedBox(height: fieldSpacing),

            // Email Field
            AppTextField(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              semanticLabel: 'Email input field',
              onChanged: (_) => _clearError(),
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
            SizedBox(height: fieldSpacing),


            // Password Field
            AppTextField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              isPassword: true,
              prefixIcon: Icons.lock_outline,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              semanticLabel: 'Password input field',
              onChanged: (_) => _clearError(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            SizedBox(height: fieldSpacing),

            // Confirm Password Field
            AppTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
              isPassword: true,
              prefixIcon: Icons.lock_outline,
              enabled: !isLoading,
              textInputAction: TextInputAction.done,
              semanticLabel: 'Confirm password input field',
              onChanged: (_) => _clearError(),
              onSubmitted: (_) => _register(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            SizedBox(height: sectionSpacing),

            // Register Button
            AppButton(
              label: 'Register',
              onPressed: isLoading ? null : _register,
              isLoading: isLoading,
              expanded: true,
              size: isLandscape ? AppButtonSize.medium : AppButtonSize.large,
              semanticLabel: 'Register button',
            ),
            SizedBox(height: isLandscape ? AppSpacing.lg : AppSpacing.xxl),

            // Login Link
            _buildResponsiveLoginLink(theme, isLandscape, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.error, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: colors.error,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: colors.error, size: AppSpacing.iconSm),
            onPressed: _clearError,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
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
              'Already have an account?',
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
