import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatting_application/widgets/video_player_widget.dart';

void main() {
  group('VideoPlayerWidget Tests', () {
    testWidgets('VideoPlayerWidget shows loading initially', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerWidget(
              videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
            ),
          ),
        ),
      );

      // Verify that loading indicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('VideoThumbnail shows play button', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoThumbnail(
              videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
              heroTag: 'test-video',
            ),
          ),
        ),
      );

      // Verify that play button is shown
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });

    testWidgets('VideoThumbnail navigates to video player on tap', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoThumbnail(
              videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
              heroTag: 'test-video',
            ),
          ),
        ),
      );

      // Tap the video thumbnail
      await tester.tap(find.byType(VideoThumbnail));
      await tester.pumpAndSettle();

      // Verify that we navigated to a new screen with an AppBar
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
    });
  });
}
