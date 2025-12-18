import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/api_auth_provider.dart';
import '../../design_system/components/app_button.dart';
import '../../design_system/components/app_text_field.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _login() async {
    _clearError();
    
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<ApiAuthProvider>(context, listen: false);

      final success = await authProvider.login(
        usernameOrEmail:
            _usernameOrEmailController.text.trim(),
        password: _passwordController.text,
      );

      if (!success && mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colors = isDark ? const DarkAppColors() : const LightAppColors();
        
        setState(() {
          _errorMessage = authProvider.error ?? 'Login failed';
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Modern Header Section
                        _buildResponsiveHeader(theme, isTablet, isLandscape),

                        SizedBox(height: isLandscape ? 24 : 32),

                        // Modern Login Form
                        _buildResponsiveLoginForm(
                          authProvider,
                          theme,
                          isTablet,
                          isLandscape,
                        ),
                      ],
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

  Widget _buildResponsiveHeader(
    ThemeData theme,
    bool isTablet,
    bool isLandscape,
  ) {
    final logoSize = isLandscape ? 40.0 : (isTablet ? 70.0 : 60.0);
    final containerPadding = isLandscape ? 20.0 : (isTablet ? 40.0 : 32.0);
    final iconPadding = isLandscape ? 12.0 : (isTablet ? 24.0 : 20.0);

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(isLandscape ? 16 : 24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: isLandscape ? 12 : 20,
            offset: Offset(0, isLandscape ? 4 : 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App Logo with responsive sizing
          Container(
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.chat_rounded,
              size: logoSize,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: isLandscape ? 12 : 20),

          // App Name with responsive typography
          Text(
            'Vector',
            textAlign: TextAlign.center,
            style: (isLandscape
                    ? theme.textTheme.headlineMedium
                    : theme.textTheme.headlineLarge)
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.2,
                ),
          ),
          SizedBox(height: isLandscape ? 4 : 8),

          // Tagline with responsive typography
          Text(
            'Connect with friends and family',
            textAlign: TextAlign.center,
            style: (isLandscape
                    ? theme.textTheme.bodyMedium
                    : theme.textTheme.bodyLarge)
                ?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveLoginForm(
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
            // Welcome Text with responsive typography
            Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: (isLandscape
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
            ),
            SizedBox(height: isLandscape ? AppSpacing.xs : AppSpacing.sm),
            Text(
              'Sign in to your account',
              textAlign: TextAlign.center,
              style: (isLandscape
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            SizedBox(height: sectionSpacing),

            // Error Banner (shown when there's an error)
            if (_errorMessage != null) ...[
              _buildErrorBanner(colors),
              SizedBox(height: fieldSpacing),
            ],

            // Username or Email Field using AppTextField
            AppTextField(
              controller: _usernameOrEmailController,
              labelText: 'Username or Email',
              hintText: 'Enter your username or email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.person_outline,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              semanticLabel: 'Username or email input field',
              onChanged: (_) => _clearError(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your username or email';
                }
                return null;
              },
            ),
            SizedBox(height: fieldSpacing),

            // Password Field using AppTextField with password mode
            AppTextField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              isPassword: true,
              prefixIcon: Icons.lock_outline,
              enabled: !isLoading,
              textInputAction: TextInputAction.done,
              semanticLabel: 'Password input field',
              onChanged: (_) => _clearError(),
              onSubmitted: (_) => _login(),
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
            SizedBox(height: isLandscape ? AppSpacing.md : AppSpacing.lg),

            // Responsive Remember Me & Forgot Password
            _buildResponsiveOptionsRow(theme, isLandscape, isLoading, colors),
            SizedBox(height: sectionSpacing),

            // Login Button using AppButton with loading state
            AppButton(
              label: 'Sign In',
              onPressed: isLoading ? null : _login,
              isLoading: isLoading,
              expanded: true,
              size: isLandscape ? AppButtonSize.medium : AppButtonSize.large,
              semanticLabel: 'Sign in button',
            ),
            SizedBox(height: isLandscape ? AppSpacing.lg : AppSpacing.xxl),

            // Responsive Register Link
            _buildResponsiveRegisterLink(theme, isLandscape, colors),
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

  Widget _buildResponsiveOptionsRow(ThemeData theme, bool isLandscape, bool isLoading, AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me with responsive styling
        Flexible(
          child: Semantics(
            label: 'Remember me checkbox',
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isLandscape ? 2 : 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: isLandscape ? 0.8 : 0.9,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: isLoading ? null : (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                      activeColor: colors.primary,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Remember me',
                      style: (isLandscape
                              ? theme.textTheme.bodySmall
                              : theme.textTheme.bodyMedium)
                          ?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Forgot Password with responsive styling
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isLandscape ? AppSpacing.radiusSm : AppSpacing.radiusMd),
            ),
            child: TextButton(
              onPressed: isLoading ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? AppSpacing.sm : AppSpacing.md,
                  vertical: isLandscape ? AppSpacing.xs : AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isLandscape ? AppSpacing.radiusSm : AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                'Forgot Password?',
                style: (isLandscape
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveRegisterLink(ThemeData theme, bool isLandscape, AppColors colors) {
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
              "Don't have an account?",
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
            label: 'Register for a new account',
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
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
                  'Register',
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
