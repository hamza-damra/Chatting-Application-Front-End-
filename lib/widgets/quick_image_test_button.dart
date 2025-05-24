import 'package:flutter/material.dart';
import '../domain/models/message_model.dart';
import '../utils/logger.dart';
import '../screens/debug_image_screen.dart';

/// A quick test button that can be added to any screen to verify image fixes
class QuickImageTestButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool showResults;

  const QuickImageTestButton({
    super.key,
    this.label,
    this.icon,
    this.showResults = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _runQuickTest(context),
      icon: Icon(icon ?? Icons.bug_report),
      label: Text(label ?? 'Test Image Fix'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _runQuickTest(BuildContext context) {
    AppLogger.i('QuickImageTest', 'Running quick image fix verification...');

    // Test message type parsing
    final testResults = <String, bool>{};
    
    // Test cases that should work now
    final testCases = [
      ('image/jpeg', MessageContentType.image),
      ('image/png', MessageContentType.image),
      ('image/gif', MessageContentType.image),
      ('video/mp4', MessageContentType.video),
      ('audio/mpeg', MessageContentType.audio),
      ('application/pdf', MessageContentType.file),
      ('TEXT', MessageContentType.text),
      ('IMAGE', MessageContentType.image),
    ];

    bool allTestsPassed = true;
    final results = <String>[];

    for (final (input, expected) in testCases) {
      final actual = MessageModel.parseMessageType(input);
      final passed = actual == expected;
      testResults[input] = passed;
      
      if (!passed) {
        allTestsPassed = false;
      }
      
      final status = passed ? '✅' : '❌';
      final result = '$status $input → $actual';
      results.add(result);
      
      AppLogger.i('QuickImageTest', 'Test: $input → Expected: $expected, Got: $actual, Passed: $passed');
    }

    // Show results
    if (showResults) {
      _showTestResults(context, allTestsPassed, results);
    }

    // Log summary
    AppLogger.i('QuickImageTest', 'Quick test completed. All tests passed: $allTestsPassed');
  }

  void _showTestResults(BuildContext context, bool allPassed, List<String> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              allPassed ? Icons.check_circle : Icons.error,
              color: allPassed ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(allPassed ? 'All Tests Passed!' : 'Some Tests Failed'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                allPassed 
                    ? 'Image display fix is working correctly!'
                    : 'There may be issues with the image display fix.',
                style: TextStyle(
                  color: allPassed ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Test Results:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: results.map((result) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        result,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!allPassed)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugImageScreen(),
                  ),
                );
              },
              child: const Text('Open Debug Tools'),
            ),
        ],
      ),
    );
  }
}

/// A floating action button version for easy access
class QuickImageTestFAB extends StatelessWidget {
  const QuickImageTestFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DebugImageScreen(),
          ),
        );
      },
      icon: const Icon(Icons.image_search),
      label: const Text('Image Debug'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );
  }
}

/// A simple widget that shows the current parsing status
class ImageFixStatusWidget extends StatelessWidget {
  const ImageFixStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Test a few key cases
    final imageJpegWorks = MessageModel.parseMessageType('image/jpeg') == MessageContentType.image;
    final imagePngWorks = MessageModel.parseMessageType('image/png') == MessageContentType.image;
    final videoMp4Works = MessageModel.parseMessageType('video/mp4') == MessageContentType.video;
    
    final allWorking = imageJpegWorks && imagePngWorks && videoMp4Works;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: allWorking ? Colors.green[50] : Colors.red[50],
        border: Border.all(
          color: allWorking ? Colors.green : Colors.red,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            allWorking ? Icons.check_circle : Icons.error,
            color: allWorking ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            allWorking 
                ? 'Image fix working ✅'
                : 'Image fix needs attention ❌',
            style: TextStyle(
              color: allWorking ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
