import 'package:flutter/material.dart';
import 'package:polyboard/polyboard.dart';

final keyboard = PolyboardController(
  defaultMode: PolyboardMode.on,
  logger: (m) => debugPrint('[polyboard] $m'),
);

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'polyboard',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2563EB)),
      builder: Polyboard.builder(controller: keyboard),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('polyboard demo')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Tap a field, then type with the on-screen keyboard. '
                    'Switch languages with the globe key; drag the handle to '
                    'move the keyboard top/bottom.'),
                SizedBox(height: 20),
                PolyboardTextField(
                  decoration: InputDecoration(
                    labelText: 'Text (EN / HI / AR / RU)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                PolyboardTextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Number (numeric pad)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
