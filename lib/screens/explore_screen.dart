import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Explore",
          style: TextStyle(
            color: Colors.black54,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
