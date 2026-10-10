import 'package:flutter/material.dart';
import 'package:shopping/pages/connexion.dart';
import 'package:shopping/pages/inscription.dart';
import 'pages/splashPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      debugShowCheckedModeBanner: false,
      home: const SplashPage(),           // première page affichée
      routes: {
        '/home': (context) => const Connexion(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Accueil')),
    );
  }
}