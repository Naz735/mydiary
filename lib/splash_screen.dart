import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        /* 25(splash_screen.dart → Image.asset) for displaying logo on splash */
        child: Image(
          image : AssetImage('assets/logo-nb.png'),
          width : 150,
          height: 150,
        ),
      ),
    );
  }
}
