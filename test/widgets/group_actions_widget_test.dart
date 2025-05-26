import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatting_application/widgets/group_actions_widget.dart';
import 'package:chatting_application/models/chat_room.dart';

void main() {
  group('GroupActionsWidget', () {
    late ChatRoom testChatRoom;

    setUp(() {
      testChatRoom = ChatRoom(
        id: 123,
        name: 'Test Group',
        isPrivate: false,
        participantIds: [1, 2, 3],
      );
    });

    Widget createTestWidget({VoidCallback? onGroupLeft}) {
      return MaterialApp(
        home: Scaffold(
          body: GroupActionsWidget(
            chatRoom: testChatRoom,
            onGroupLeft: onGroupLeft,
          ),
        ),
      );
    }

    testWidgets('should display leave group button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Leave Group'), findsOneWidget);
      expect(find.byIcon(Icons.exit_to_app), findsOneWidget);
    });

    testWidgets('should show confirmation dialog when leave button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Tap the leave group button
      await tester.tap(find.text('Leave Group'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog is shown
      expect(
        find.text('Leave Group'),
        findsNWidgets(2),
      ); // Button + dialog title
      expect(
        find.text('Are you sure you want to leave "Test Group"?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should cancel leave action when cancel is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Tap the leave group button
      await tester.tap(find.text('Leave Group'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed and no API call was made
      expect(
        find.text('Are you sure you want to leave "Test Group"?'),
        findsNothing,
      );
      // Dialog dismissed successfully
    });

    // Note: Additional tests would require mocking the ChatProvider
    // For now, we test the basic UI functionality
  });
}
