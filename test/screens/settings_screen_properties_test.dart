import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vector/providers/api_auth_provider.dart';
import 'package:vector/providers/theme_provider.dart';
import 'package:vector/screens/settings_screen.dart';
import 'package:vector/design_system/components/app_button.dart';
import 'package:vector/design_system/components/app_list_tile.dart';

/// Mock ApiAuthProvider for testing
class MockApiAuthProvider extends ChangeNotifier implements ApiAuthProvider {
  bool _isLoading = false;
  bool _logoutCalled = false;

  @override
  bool get isLoading => _isLoading;

  bool get logoutCalled => _logoutCalled;

  void reset() {
    _logoutCalled = false;
    _isLoading = false;
  }

  @override
  Future<void> logout() async {
    _logoutCalled = true;
    notifyListeners();
  }

  // Stub implementations for other ApiAuthProvider methods
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock ThemeProvider for testing
class MockThemeProvider extends ChangeNotifier implements ThemeProvider {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Property-based tests for Settings Screen.
/// **Feature: ui-loading-states-overhaul**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiAuthProvider mockAuthProvider;
  late MockThemeProvider mockThemeProvider;

  setUp(() {
    mockAuthProvider = MockApiAuthProvider();
    mockThemeProvider = MockThemeProvider();
  });

  Widget buildTestWidget({Widget? child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ApiAuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: child ?? const SettingsScreen(),
        ),
      ),
    );
  }

  group('Settings Screen Property Tests', () {
    /// **Property 14: Settings section organization**
    /// *For any* SettingsScreen, the widget tree SHALL contain section headers
    /// for Account, Notifications, Chat, Media, and About sections in a
    /// scrollable layout.
    /// **Validates: Requirements 7.1**
    group('Property 14: Settings section organization', () {
      testWidgets('SettingsScreen contains all required section headers', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        
        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Verify all required section headers are present
        expect(find.text('Account'), findsOneWidget);
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Chat'), findsOneWidget);
        expect(find.text('Media'), findsOneWidget);
        expect(find.text('About'), findsOneWidget);
      });

      testWidgets('SettingsScreen is scrollable', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Verify SingleChildScrollView is present
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('SettingsScreen sections are in correct order', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Get all text widgets
        final accountFinder = find.text('Account');
        final notificationsFinder = find.text('Notifications');
        final chatFinder = find.text('Chat');
        final mediaFinder = find.text('Media');
        final aboutFinder = find.text('About');

        // Verify all sections exist
        expect(accountFinder, findsOneWidget);
        expect(notificationsFinder, findsOneWidget);
        expect(chatFinder, findsOneWidget);
        expect(mediaFinder, findsOneWidget);
        expect(aboutFinder, findsOneWidget);

        // Get positions
        final accountPos = tester.getTopLeft(accountFinder);
        final notificationsPos = tester.getTopLeft(notificationsFinder);
        final chatPos = tester.getTopLeft(chatFinder);
        final mediaPos = tester.getTopLeft(mediaFinder);
        final aboutPos = tester.getTopLeft(aboutFinder);

        // Verify order (each section should be below the previous one)
        expect(accountPos.dy, lessThan(notificationsPos.dy));
        expect(notificationsPos.dy, lessThan(chatPos.dy));
        expect(chatPos.dy, lessThan(mediaPos.dy));
        expect(mediaPos.dy, lessThan(aboutPos.dy));
      });

      testWidgets('SettingsScreen Account section contains expected items', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Account section items
        expect(find.text('Account Information'), findsOneWidget);
        expect(find.text('Privacy & Security'), findsOneWidget);
        expect(find.text('Blocked Users'), findsOneWidget);
      });

      testWidgets('SettingsScreen Notifications section contains expected items', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Notifications section items
        expect(find.text('Push Notifications'), findsOneWidget);
        expect(find.text('Background Permissions'), findsOneWidget);
      });

      testWidgets('SettingsScreen Chat section contains expected items', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Chat section items
        expect(find.text('Read Receipts'), findsOneWidget);
        expect(find.text('Typing Indicators'), findsOneWidget);
        expect(find.text('Dark Mode'), findsOneWidget);
      });

      testWidgets('SettingsScreen Media section contains expected items', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Media section items
        expect(find.text('Media Gallery'), findsOneWidget);
        expect(find.text('Storage Statistics'), findsOneWidget);
      });

      testWidgets('SettingsScreen About section contains expected items', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // About section items
        expect(find.text('About Vector'), findsOneWidget);
        expect(find.text('Help & Support'), findsOneWidget);
      });

      testWidgets('SettingsScreen uses AppListTile components', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Verify AppListTile widgets are used
        expect(find.byType(AppListTile), findsWidgets);
      });

      testWidgets('SettingsScreen renders in dark mode', (tester) async {
        mockThemeProvider.setThemeMode(ThemeMode.dark);
        
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ApiAuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
            ],
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const Scaffold(
                body: SettingsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // All sections should still be visible
        expect(find.text('Account'), findsOneWidget);
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Chat'), findsOneWidget);
        expect(find.text('Media'), findsOneWidget);
        expect(find.text('About'), findsOneWidget);
      });
    });

    /// **Property 15: Logout confirmation dialog**
    /// *For any* logout action trigger, the system SHALL display a confirmation
    /// dialog before executing the logout; canceling the dialog SHALL NOT
    /// execute logout.
    /// **Validates: Requirements 7.5**
    group('Property 15: Logout confirmation dialog', () {
      testWidgets('Logout button is styled as destructive action', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to the logout button
        final logoutButton = find.widgetWithText(AppButton, 'Logout');
        await tester.scrollUntilVisible(logoutButton, 100);
        await tester.pumpAndSettle();

        expect(logoutButton, findsOneWidget);

        // Verify it's an AppButton with destructive styling
        final appButton = tester.widget<AppButton>(logoutButton);
        expect(appButton.isDestructive, isTrue);
      });

      testWidgets('Tapping logout shows confirmation dialog', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to and tap the logout button
        final logoutButton = find.widgetWithText(AppButton, 'Logout');
        await tester.scrollUntilVisible(logoutButton, 100);
        await tester.pumpAndSettle();
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();

        // Verify dialog is shown
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Logout'), findsWidgets); // Title and button
        expect(find.text('Are you sure you want to logout? You will need to sign in again to access your messages.'), findsOneWidget);
      });

      testWidgets('Confirmation dialog has Cancel and Logout buttons', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to and tap the logout button
        final logoutButton = find.widgetWithText(AppButton, 'Logout');
        await tester.scrollUntilVisible(logoutButton, 100);
        await tester.pumpAndSettle();
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();

        // Verify dialog buttons
        expect(find.text('Cancel'), findsOneWidget);
        // Find Logout text in dialog (there will be multiple - button and title)
        expect(find.text('Logout'), findsWidgets);
      });

      testWidgets('Canceling dialog does NOT execute logout', (tester) async {
        mockAuthProvider.reset();
        
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to and tap the logout button
        final logoutButton = find.widgetWithText(AppButton, 'Logout');
        await tester.scrollUntilVisible(logoutButton, 100);
        await tester.pumpAndSettle();
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify logout was NOT called
        expect(mockAuthProvider.logoutCalled, isFalse);
        
        // Dialog should be dismissed
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('Confirming dialog executes logout', (tester) async {
        mockAuthProvider.reset();
        
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to and tap the logout button
        final logoutButton = find.widgetWithText(AppButton, 'Logout');
        await tester.scrollUntilVisible(logoutButton, 100);
        await tester.pumpAndSettle();
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();

        // Find and tap the Logout button in the dialog (not the title)
        // The dialog has a TextButton with 'Logout' text - find it by looking for TextButton
        final dialogLogoutButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Logout'),
        );
        await tester.tap(dialogLogoutButton);
        await tester.pumpAndSettle();

        // Verify logout was called
        expect(mockAuthProvider.logoutCalled, isTrue);
      });

      testWidgets('Tapping outside dialog does NOT execute logout', (tester) async {
        mockAuthProvider.reset();
        
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to and tap the logout button
        final logoutButton = find.widgetWithText(AppButton, 'Logout');
        await tester.scrollUntilVisible(logoutButton, 100);
        await tester.pumpAndSettle();
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();

        // Tap outside the dialog (on the barrier)
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Verify logout was NOT called
        expect(mockAuthProvider.logoutCalled, isFalse);
      });
    });
  });
}
