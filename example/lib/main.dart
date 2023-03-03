import 'package:ar_quido/ar_quido.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _recognizedImage;

  void _onImageDetected(String? imageName) {
    if (imageName != null && _recognizedImage != imageName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recognized image: $imageName'),
          duration: const Duration(milliseconds: 2500),
        ),
      );
    }
    setState(() {
      _recognizedImage = imageName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Stack(
          children: [
            ARQuidoView(
              referenceImageNames: const ['applandroid'],
              onImageDetected: _onImageDetected,
            ),
          ],
        ),
      ),
    );
  }
}
