import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/api_auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/password_text_field.dart';
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

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<ApiAuthProvider>(context, listen: false);

      final success = await authProvider.login(
        usernameOrEmail:
            _usernameOrEmailController.text.trim(), // Can be email or username
        password: _passwordController.text,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Login failed'),
            backgroundColor: Colors.red,
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
                      maxWidth: isTablet ? 500 : double.infinity,
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
    final containerPadding = isLandscape ? 20.0 : (isTablet ? 40.0 : 32.0);
    final fieldSpacing = isLandscape ? 16.0 : 20.0;
    final sectionSpacing = isLandscape ? 20.0 : 32.0;
    final buttonHeight = isLandscape ? 48.0 : 56.0;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
                    color: theme.colorScheme.onSurface,
                  ),
            ),
            SizedBox(height: isLandscape ? 4 : 8),
            Text(
              'Sign in to your account',
              textAlign: TextAlign.center,
              style: (isLandscape
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            SizedBox(height: sectionSpacing),

            // Username or Email Field with responsive container
            _buildResponsiveInputField(
              child: CustomTextField(
                label: 'Username or Email',
                hint: 'Enter your username or email',
                controller: _usernameOrEmailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username or email';
                  }
                  return null;
                },
              ),
              theme: theme,
              isLandscape: isLandscape,
            ),
            SizedBox(height: fieldSpacing),

            // Password Field with responsive container
            _buildResponsiveInputField(
              child: PasswordTextField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                prefixIcon: const Icon(Icons.lock_outline),
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
              theme: theme,
              isLandscape: isLandscape,
            ),
            SizedBox(height: isLandscape ? 12 : 16),

            // Responsive Remember Me & Forgot Password
            _buildResponsiveOptionsRow(theme, isLandscape),
            SizedBox(height: sectionSpacing),

            // Responsive Login Button
            CustomButton(
              text: 'Sign In',
              onPressed: _login,
              isLoading: authProvider.isLoading,
              height: buttonHeight,
              borderRadius: isLandscape ? 12 : 16,
            ),
            SizedBox(height: isLandscape ? 16 : 24),

            // Responsive Register Link
            _buildResponsiveRegisterLink(theme, isLandscape),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveInputField({
    required Widget child,
    required ThemeData theme,
    required bool isLandscape,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(isLandscape ? 12 : 16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: isLandscape ? 6 : 8,
            offset: Offset(0, isLandscape ? 1 : 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildResponsiveOptionsRow(ThemeData theme, bool isLandscape) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me with responsive styling
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isLandscape ? 2 : 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: isLandscape ? 0.8 : 0.9,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    'Remember me',
                    style: (isLandscape
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Forgot Password with responsive styling
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isLandscape ? 6 : 8),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 8 : 12,
                  vertical: isLandscape ? 4 : 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isLandscape ? 6 : 8),
                ),
              ),
              child: Text(
                'Forgot Password?',
                style: (isLandscape
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveRegisterLink(ThemeData theme, bool isLandscape) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(isLandscape ? 12 : 16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ),
          SizedBox(width: isLandscape ? 6 : 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 8 : 12,
                vertical: isLandscape ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isLandscape ? 6 : 8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'Register',
                style: (isLandscape
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
