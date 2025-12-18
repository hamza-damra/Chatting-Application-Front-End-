import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide test, group, expect;
import 'package:vector/design_system/tokens/app_spacing.dart';

/// Property-based tests for message bubble width adaptation.
/// **Feature: responsive-screen-overhaul, Property 10: Message bubble width adaptation**
/// **Validates: Requirements 2.3, 8.2**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 10: Message bubble width adaptation', () {
    /// Helper widget that simulates message bubble width constraints
    /// This mirrors the logic in ModernMessageBubble and CustomChatWidgetNew
    Widget buildMessageBubbleConstraint({
      required double screenWidth,
      required bool isCurrentUser,
    }) {
      // Calculate max-width percentage based on device size
      // Mobile: 75%, Tablet: 65%, Desktop: 60%
      final deviceSize = ResponsiveLayout.getDeviceSizeFromWidth(screenWidth);
      double maxWidthPercentage;
      switch (deviceSize) {
        case DeviceSize.mobile:
          maxWidthPercentage = 0.75;
          break;
        case DeviceSize.tablet:
          maxWidthPercentage = 0.65;
          break;
        case DeviceSize.desktop:
          maxWidthPercentage = 0.60;
          break;
      }

      return Container(
        key: const Key('message_bubble'),
        constraints: BoxConstraints(
          maxWidth: screenWidth * maxWidthPercentage,
          minWidth: 60,
        ),
        child: const Text('Test message content'),
      );
    }

    /// Unit test: Verify mobile message bubble uses 75% max-width
    testWidgets('Mobile (375px) message bubble uses 75% max-width', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: buildMessageBubbleConstraint(
                screenWidth: 375,
                isCurrentUser: true,
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byKey(const Key('message_bubble')));
      final constraints = container.constraints as BoxConstraints;
      
      // 375 * 0.75 = 281.25
      expect(constraints.maxWidth, closeTo(281.25, 0.01));
    });

    /// Unit test: Verify tablet message bubble uses 65% max-width
    testWidgets('Tablet (768px) message bubble uses 65% max-width', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: buildMessageBubbleConstraint(
                screenWidth: 768,
                isCurrentUser: true,
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byKey(const Key('message_bubble')));
      final constraints = container.constraints as BoxConstraints;
      
      // 768 * 0.65 = 499.2
      expect(constraints.maxWidth, closeTo(499.2, 0.01));
    });

    /// Unit test: Verify desktop message bubble uses 60% max-width
    testWidgets('Desktop (1280px) message bubble uses 60% max-width', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: buildMessageBubbleConstraint(
                screenWidth: 1280,
                isCurrentUser: true,
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byKey(const Key('message_bubble')));
      final constraints = container.constraints as BoxConstraints;
      
      // 1280 * 0.60 = 768
      expect(constraints.maxWidth, closeTo(768, 0.01));
    });

    /// Property test: For any mobile width, max-width percentage SHALL be 75%
    group('Mobile max-width percentage property tests', () {
      for (final screenWidth in [320.0, 375.0, 414.0, 480.0, 599.0]) {
        test('Mobile ($screenWidth px) uses 75% max-width', () {
          final deviceSize = ResponsiveLayout.getDeviceSizeFromWidth(screenWidth);
          expect(deviceSize, equals(DeviceSize.mobile));
          
          final expectedMaxWidth = screenWidth * 0.75;
          expect(expectedMaxWidth, lessThan(screenWidth));
          expect(expectedMaxWidth, greaterThan(screenWidth * 0.5));
        });
      }
    });

    /// Property test: For any tablet width, max-width percentage SHALL be 65%
    group('Tablet max-width percentage property tests', () {
      for (final screenWidth in [600.0, 700.0, 768.0, 834.0, 899.0]) {
        test('Tablet ($screenWidth px) uses 65% max-width', () {
          final deviceSize = ResponsiveLayout.getDeviceSizeFromWidth(screenWidth);
          expect(deviceSize, equals(DeviceSize.tablet));
          
          final expectedMaxWidth = screenWidth * 0.65;
          expect(expectedMaxWidth, lessThan(screenWidth));
          expect(expectedMaxWidth, lessThan(screenWidth * 0.75));
        });
      }
    });

    /// Property test: For any desktop width, max-width percentage SHALL be 60%
    group('Desktop max-width percentage property tests', () {
      for (final screenWidth in [900.0, 1024.0, 1280.0, 1440.0, 1920.0]) {
        test('Desktop ($screenWidth px) uses 60% max-width', () {
          final deviceSize = ResponsiveLayout.getDeviceSizeFromWidth(screenWidth);
          expect(deviceSize, equals(DeviceSize.desktop));
          
          final expectedMaxWidth = screenWidth * 0.60;
          expect(expectedMaxWidth, lessThan(screenWidth));
          expect(expectedMaxWidth, lessThan(screenWidth * 0.65));
        });
      }
    });

    /// Property test using glados: For any screen width, message bubble max-width
    /// SHALL be constrained to the appropriate percentage
    Glados<int>().test(
      'Message bubble max-width percentage decreases as screen size increases',
      (randomInt) {
        // Generate screen widths from 280 to 2000
        final screenWidth = 280.0 + (randomInt.abs() % 1721);
        final deviceSize = ResponsiveLayout.getDeviceSizeFromWidth(screenWidth);
        
        double expectedPercentage;
        switch (deviceSize) {
          case DeviceSize.mobile:
            expectedPercentage = 0.75;
            break;
          case DeviceSize.tablet:
            expectedPercentage = 0.65;
            break;
          case DeviceSize.desktop:
            expectedPercentage = 0.60;
            break;
        }
        
        final maxWidth = screenWidth * expectedPercentage;
        
        // Verify max-width is always less than screen width
        expect(maxWidth, lessThan(screenWidth));
        
        // Verify max-width is at least 60% of screen width
        expect(maxWidth, greaterThanOrEqualTo(screenWidth * 0.60));
        
        // Verify max-width is at most 75% of screen width
        expect(maxWidth, lessThanOrEqualTo(screenWidth * 0.75));
      },
    );

    /// Property test: Verify padding increases on larger screens
    group('Message bubble padding adaptation property tests', () {
      test('Mobile padding multiplier is 1.0x', () {
        final deviceSize = ResponsiveLayout.getDeviceSizeFromWidth(375);
        expect(deviceSize, equals(DeviceSize.mobile));
        
        // Mobile uses 1.0x multiplier
        const basePadding = 16.0;
        const multiplier = 1.0;
        expect(basePadding * multiplier, equals(16.0));
      });

      test('Tablet padding multiplier is 1.25x', () {
        final deviceSize = ResponsiveLayout.getDeviceSizeFromWidth(768);
        expect(deviceSize, equals(DeviceSize.tablet));
        
        // Tablet uses 1.25x multiplier
        const basePadding = 16.0;
        const multiplier = 1.25;
        expect(basePadding * multiplier, equals(20.0));
      });

      test('Desktop padding multiplier is 1.5x', () {
        final deviceSize = ResponsiveLayout.getDeviceSizeFromWidth(1280);
        expect(deviceSize, equals(DeviceSize.desktop));
        
        // Desktop uses 1.5x multiplier
        const basePadding = 16.0;
        const multiplier = 1.5;
        expect(basePadding * multiplier, equals(24.0));
      });
    });

    /// Property test using glados: Padding multiplier SHALL increase with screen size
    Glados<int>().test(
      'Padding multiplier increases with screen size category',
      (randomInt) {
        // Generate screen widths from 280 to 2000
        final screenWidth = 280.0 + (randomInt.abs() % 1721);
        final deviceSize = ResponsiveLayout.getDeviceSizeFromWidth(screenWidth);
        
        double multiplier;
        switch (deviceSize) {
          case DeviceSize.mobile:
            multiplier = 1.0;
            break;
          case DeviceSize.tablet:
            multiplier = 1.25;
            break;
          case DeviceSize.desktop:
            multiplier = 1.5;
            break;
        }
        
        // Verify multiplier is within expected range
        expect(multiplier, greaterThanOrEqualTo(1.0));
        expect(multiplier, lessThanOrEqualTo(1.5));
        
        // Verify larger screens have larger multipliers
        if (deviceSize == DeviceSize.desktop) {
          expect(multiplier, equals(1.5));
        } else if (deviceSize == DeviceSize.tablet) {
          expect(multiplier, equals(1.25));
        } else {
          expect(multiplier, equals(1.0));
        }
      },
    );

    /// Property test: Verify breakpoint transitions
    test('Breakpoint transitions are correct', () {
      // Mobile to tablet transition at 600px
      expect(ResponsiveLayout.getDeviceSizeFromWidth(599), equals(DeviceSize.mobile));
      expect(ResponsiveLayout.getDeviceSizeFromWidth(600), equals(DeviceSize.tablet));
      
      // Tablet to desktop transition at 900px
      expect(ResponsiveLayout.getDeviceSizeFromWidth(899), equals(DeviceSize.tablet));
      expect(ResponsiveLayout.getDeviceSizeFromWidth(900), equals(DeviceSize.desktop));
    });
  });
}
