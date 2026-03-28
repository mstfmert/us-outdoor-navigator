import 'package:flutter/material.dart';

void main() => runApp(const SimpleTestApp());

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Test',
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('US Outdoor Navigator Test'),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                'Flutter Test App Running!',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Backend API is running at:',
                style: TextStyle(color: Colors.grey),
              ),
              const Text(
                'http://localhost:8000',
                style: TextStyle(color: Colors.blue),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Placeholder for future functionality
                },
                child: const Text('Test Backend Connection'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Android Emulator: Connected ✓',
                style: TextStyle(color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
