import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector/design_system/components/app_button.dart';
import 'package:vector/design_system/components/app_text_field.dart';
import 'package:vector/design_system/components/app_list_tile.dart';
import 'package:vector/design_system/components/app_avatar.dart';
import 'package:vector/design_system/components/app_badge.dart';
import 'package:vector/design_system/components/app_card.dart';
import 'package:vector/design_system/components/search_bar_widget.dart';
import 'package:vector/design_system/states/empty_state_view.dart';
import 'package:vector/design_system/states/error_state_view.dart';
import 'package:vector/design_system/states/offline_banner.dart';

/// Property-based tests for accessibility.
/// **Feature: ui-loading-states-overhaul**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Accessibility Property Tests', () {
    /// **Property 18: Interactive element semantics**
    /// *For any* interactive widget (button, text field, toggle), the widget
    /// SHALL have a non-empty semantic label for accessibility.
    /// **Validates: Requirements 9.2**
    group('Property 18: Interactive element semantics', () {
      testWidgets('AppButton has semantic label from label property', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Submit',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );
        final semantics = tester.getSemantics(find.byType(AppButton));
        expect(semantics.label, contains('Submit'));
      });

      testWidgets('AppButton uses custom semanticLabel when provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Submit',
                  semanticLabel: 'Submit form button',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );
        final semantics = tester.getSemantics(find.byType(AppButton));
        expect(semantics.label, contains('Submit form button'));
      });

      testWidgets('AppTextField has semantic label from labelText', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AppTextField(
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                ),
              ),
            ),
          ),
        );
        final semantics = tester.getSemantics(find.byType(AppTextField));
        expect(semantics.label, contains('Email Address'));
      });

      testWidgets('AppListTile has semantic label from title', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppListTile(
                title: 'Settings',
                onTap: () {},
              ),
            ),
          ),
        );
        final semantics = tester.getSemantics(find.byType(AppListTile));
        expect(semantics.label, contains('Settings'));
      });

      testWidgets('AppAvatar has semantic label from name', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(child: AppAvatar(name: 'John Doe')),
            ),
          ),
        );
        final semantics = tester.getSemantics(find.byType(AppAvatar));
        expect(semantics.label, contains('John Doe'));
      });


      testWidgets('AppBadge has semantic label for count', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Center(child: AppBadge.count(count: 5))),
          ),
        );
        final semantics = tester.getSemantics(find.byType(AppBadge));
        expect(semantics.label, contains('5 items'));
      });

      testWidgets('SearchBarWidget has semantic label', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SearchBarWidget(hintText: 'Search chats')),
          ),
        );
        final semantics = tester.getSemantics(find.byType(SearchBarWidget));
        expect(semantics.label, contains('Search'));
      });

      testWidgets('ErrorStateView retry button has semantic label', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStateView(message: 'Error', onRetry: () {}),
            ),
          ),
        );
        final semanticsWidgets = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Retry loading',
        );
        expect(semanticsWidgets, findsOneWidget);
      });

      testWidgets('OfflineBanner retry button has semantic label', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: OfflineBanner(isOffline: true, onRetry: () {})),
          ),
        );
        final semanticsWidgets = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Retry connection',
        );
        expect(semanticsWidgets, findsOneWidget);
      });
    });


    /// **Property 19: Touch target minimum size**
    /// *For any* tappable widget, the effective touch target area SHALL be
    /// at least 44x44 logical pixels.
    /// **Validates: Requirements 9.6**
    group('Property 19: Touch target minimum size', () {
      testWidgets('AppButton small size meets minimum touch target', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(label: 'Small', size: AppButtonSize.small, onPressed: () {}),
              ),
            ),
          ),
        );
        final buttonSize = tester.getSize(find.byType(AppButton));
        expect(buttonSize.height, greaterThanOrEqualTo(44.0));
      });

      testWidgets('AppButton medium size meets minimum touch target', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(label: 'Medium', size: AppButtonSize.medium, onPressed: () {}),
              ),
            ),
          ),
        );
        final buttonSize = tester.getSize(find.byType(AppButton));
        expect(buttonSize.height, greaterThanOrEqualTo(44.0));
      });

      testWidgets('AppButton large size meets minimum touch target', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppButton(label: 'Large', size: AppButtonSize.large, onPressed: () {}),
              ),
            ),
          ),
        );
        final buttonSize = tester.getSize(find.byType(AppButton));
        expect(buttonSize.height, greaterThanOrEqualTo(44.0));
      });


      testWidgets('AppListTile meets minimum touch target height', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: AppListTile(title: 'Settings', onTap: () {})),
          ),
        );
        final tileSize = tester.getSize(find.byType(AppListTile));
        expect(tileSize.height, greaterThanOrEqualTo(44.0));
      });

      testWidgets('SearchBarWidget meets minimum touch target height', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SearchBarWidget(hintText: 'Search')),
          ),
        );
        final containerFinder = find.descendant(
          of: find.byType(SearchBarWidget),
          matching: find.byType(Container),
        ).first;
        final containerSize = tester.getSize(containerFinder);
        expect(containerSize.height, greaterThanOrEqualTo(44.0));
      });

      testWidgets('EmptyStateView action button meets minimum touch target', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyStateView(
                icon: Icons.chat_bubble_outline,
                title: 'No chats',
                actionLabel: 'Start Chat',
                onAction: () {},
              ),
            ),
          ),
        );
        final buttonSize = tester.getSize(find.byType(ElevatedButton));
        expect(buttonSize.height, greaterThanOrEqualTo(44.0));
      });

      testWidgets('ErrorStateView retry button meets minimum touch target', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ErrorStateView(message: 'Error', onRetry: () {})),
          ),
        );
        // Find the SizedBox that wraps the button with minTouchTarget height
        final sizedBoxFinder = find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == 44.0,
        );
        expect(sizedBoxFinder, findsOneWidget);
      });
    });

    /// **Property 17: Text scaling layout integrity**
    /// *For any* screen rendered with textScaleFactor up to 2.0, the layout
    /// SHALL NOT have overflow errors and all text SHALL remain readable.
    /// **Validates: Requirements 9.1**
    group('Property 17: Text scaling layout integrity', () {
      testWidgets('AppButton handles 200% text scaling without overflow', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
                child: child!,
              );
            },
            home: Scaffold(
              body: Center(
                child: AppButton(label: 'Submit Button', onPressed: () {}),
              ),
            ),
          ),
        );
        // No overflow errors should occur
        expect(tester.takeException(), isNull);
        expect(find.text('Submit Button'), findsOneWidget);
      });

      testWidgets('AppTextField handles 200% text scaling without overflow', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
                child: child!,
              );
            },
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AppTextField(labelText: 'Email Address', hintText: 'Enter email'),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Email Address'), findsOneWidget);
      });

      testWidgets('EmptyStateView handles 200% text scaling without overflow', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
                child: child!,
              );
            },
            home: Scaffold(
              body: EmptyStateView(
                icon: Icons.chat_bubble_outline,
                title: 'No chats yet',
                description: 'Start a conversation',
                actionLabel: 'New Chat',
                onAction: () {},
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('No chats yet'), findsOneWidget);
      });

      testWidgets('ErrorStateView handles 200% text scaling without overflow', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
                child: child!,
              );
            },
            home: Scaffold(
              body: ErrorStateView(message: 'Something went wrong', onRetry: () {}),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Something went wrong'), findsOneWidget);
      });

      testWidgets('AppListTile handles 200% text scaling without overflow', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
                child: child!,
              );
            },
            home: Scaffold(
              body: AppListTile(
                title: 'Settings',
                subtitle: 'Configure your preferences',
                leadingIcon: Icons.settings,
                onTap: () {},
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Settings'), findsOneWidget);
      });
    });
  });
}
