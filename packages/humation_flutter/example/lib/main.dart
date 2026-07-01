import 'package:flutter/material.dart';
import 'package:humation_flutter/humation_flutter.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A seed always renders the same avatar.
              const HumationAvatar(seed: 'felix', size: 160),
              const SizedBox(height: 24),
              // Or pick parts and colours. Slots are constants; colours take a
              // Flutter Color or a hex string.
              const HumationAvatar(
                selections: {
                  HumationSlot.head: 'wavy-medium',
                  HumationSlot.body: 'hoodie',
                },
                colors: {HumationColorSlot.hair: Color(0xFF4A3728)},
                size: 96,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
