import 'package:flutter/material.dart';

class TestSquircle extends StatelessWidget {
  const TestSquircle({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(400, 240), // width, height
        shape: ContinuousRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(125)),
        ),
      ),
      onPressed: () {},
      child: Text('Test Squircle'),
    );
  }
}
