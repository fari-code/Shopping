import 'package:flutter/material.dart';
class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDA400),
      appBar: AppBar(
        backgroundColor: Color(0xFFFDA400) ,
        title: const Text('Accueil'),
      ),
      body: const Center(
        child: Text(
          'Bienvenue à l\'accueil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}