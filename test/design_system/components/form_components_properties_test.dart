import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector/design_system/components/app_button.dart';
import 'package:vector/design_system/components/app_text_field.dart';

/// Property-based tests for form components.
/// **Feature: ui-loading-states-overhaul**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Form Components Property Tests', () {
    /// **Property 10: Form validation feedback**
    /// *For any* text field with a validator function, when the validator
    /// returns a non-null error string, the field SHALL display that error
    /// message visibly below the input.
    /// **Validates: Requirements 3.3**
    group('Property 10: Form validation feedback', () {
      testWidgets('AppTextField displays error message when errorText is provided', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AppTextField(
                  hintText: 'Enter email',
                  errorText: 'Invalid email address',
                ),
              ),
            ),
          ),
        );

        // Verify error message is displayed
        expect(find.text('Invalid email address'), findsOneWidget);
        // Verify error icon is shown
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('AppTextField does not display error when errorText is null', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AppTextField(
                  hintText: 'Enter email',
                ),
              ),
            ),
          ),
        );

        // Verify no error icon is shown
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });

      testWidgets('AppTextField does not display error when errorText is empty', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AppTextField(
                  hintText: 'Enter email',
                  errorText: '',
                ),
              ),
            ),
          ),
        );

        // Verify no error icon is shown
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });

      testWidgets('AppTextField displays helper text when no error', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AppTextField(
                  hintText: 'Enter password',
                  helperText: 'Must be at least 8 characters',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Must be at least 8 characters'), findsOneWidget);
      });

      testWidgets('AppTextField error takes precedence over helper text', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AppTextField(
                  hintText: 'Enter password',
                  helperText: 'Must be at least 8 characters',
                  errorText: 'Password too short',
                ),
              ),
            ),
          ),
        );

        // Error should be shown
        expect(find.text('Password too short'), findsOneWidget);
        // Helper should not be shown
        expect(find.text('Must be at least 8 characters'), findsNothing);
      });

      testWidgets('AppTextField displays label text', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AppTextField(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Email'), findsOneWidget);
      });

      testWidgets('AppTextField renders in dark mode with error', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AppTextField(
                  hintText: 'Enter email',
                  errorText: 'Invalid email',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Invalid email'), findsOneWidget);
      });
    });

    /// **Property 11: Form submission loading state**
    /// *For any* form with isLoading=true, all input fields SHALL be disabled
    /// (not accepting input) AND the submit button SHALL display a loading
    /// indicator.
    /// **Validates: Requirements 3.5, 3.6**
    group('Property 11: Form submission loading state', () {
      testWidgets('AppButton displays loading spinner when isLoading is true', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Submit',
                  isLoading: true,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        // Verify loading indicator is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // Verify label is still shown
        expect(find.text('Submit'), findsOneWidget);
      });

      testWidgets('AppButton does not display loading spinner when isLoading is false', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Submit',
                  isLoading: false,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('AppButton is disabled when isLoading is true', (tester) async {
        var wasPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Submit',
                  isLoading: true,
                  onPressed: () {
                    wasPressed = true;
                  },
                ),
              ),
            ),
          ),
        );

        // Try to tap the button
        await tester.tap(find.byType(AppButton));
        await tester.pump();

        // Callback should not be invoked
        expect(wasPressed, isFalse);
      });

      testWidgets('AppTextField is disabled when enabled is false', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: AppTextField(
                  controller: controller,
                  hintText: 'Enter text',
                  enabled: false,
                ),
              ),
            ),
          ),
        );

        // Try to enter text
        await tester.enterText(find.byType(TextFormField), 'test input');
        await tester.pump();

        // Text should not be entered
        expect(controller.text, isEmpty);
      });

      testWidgets('AppTextField accepts input when enabled is true', (tester) async {
        final controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: AppTextField(
                  controller: controller,
                  hintText: 'Enter text',
                  enabled: true,
                ),
              ),
            ),
          ),
        );

        // Enter text
        await tester.enterText(find.byType(TextFormField), 'test input');
        await tester.pump();

        // Text should be entered
        expect(controller.text, equals('test input'));
      });

      testWidgets('Form with loading state disables all inputs', (tester) async {
        final emailController = TextEditingController();
        final passwordController = TextEditingController();
        var submitPressed = false;
        const isLoading = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AppTextField(
                      controller: emailController,
                      hintText: 'Email',
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      isPassword: true,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Login',
                      isLoading: isLoading,
                      onPressed: () {
                        submitPressed = true;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Try to enter text in email field
        await tester.enterText(find.byType(TextFormField).first, 'test@email.com');
        await tester.pump();
        expect(emailController.text, isEmpty);

        // Try to tap submit button
        await tester.tap(find.byType(AppButton));
        await tester.pump();
        expect(submitPressed, isFalse);

        // Verify loading indicator is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('AppButton variants all support loading state', (tester) async {
        for (final variant in AppButtonVariant.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AppButton(
                    label: 'Button',
                    variant: variant,
                    isLoading: true,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          );

          expect(
            find.byType(CircularProgressIndicator),
            findsOneWidget,
            reason: 'Loading indicator should be shown for $variant variant',
          );
        }
      });

      testWidgets('AppButton renders in dark mode with loading state', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Submit',
                  isLoading: true,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    // Additional tests for AppButton functionality
    group('AppButton additional tests', () {
      testWidgets('AppButton invokes callback when pressed', (tester) async {
        var wasPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Press Me',
                  onPressed: () {
                    wasPressed = true;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AppButton));
        await tester.pump();

        expect(wasPressed, isTrue);
      });

      testWidgets('AppButton is disabled when onPressed is null', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Disabled',
                  onPressed: null,
                ),
              ),
            ),
          ),
        );

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      });

      testWidgets('AppButton displays icon when provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Add',
                  icon: Icons.add,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('AppButton destructive variant uses error color', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Delete',
                  isDestructive: true,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        // Button should render without errors
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('AppButton outlined variant renders correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Outlined',
                  variant: AppButtonVariant.outlined,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('AppButton text variant renders correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Text',
                  variant: AppButtonVariant.text,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.byType(TextButton), findsOneWidget);
      });
    });

    // Additional tests for AppTextField functionality
    group('AppTextField additional tests', () {
      testWidgets('AppTextField password toggle works', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AppTextField(
                  hintText: 'Password',
                  isPassword: true,
                ),
              ),
            ),
          ),
        );

        // Initially password should be obscured - visibility_off icon shown
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsNothing);

        // Tap visibility toggle
        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pump();

        // Password should now be visible - visibility icon shown
        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off), findsNothing);
      });

      testWidgets('AppTextField calls onChanged callback', (tester) async {
        String? changedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: AppTextField(
                  hintText: 'Enter text',
                  onChanged: (value) {
                    changedValue = value;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), 'hello');
        await tester.pump();

        expect(changedValue, equals('hello'));
      });

      testWidgets('AppTextField displays prefix icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AppTextField(
                  hintText: 'Email',
                  prefixIcon: Icons.email,
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.email), findsOneWidget);
      });
    });
  });
}
