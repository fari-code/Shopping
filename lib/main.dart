import 'package:flutter/material.dart';
import 'package:shopping/screens/inscription.dart';
import 'package:shopping/screens/search.dart';
// import 'package:shopping/screens/connexion.dart';
// import 'package:shopping/screens/inscription.dart';
import 'package:shopping/screens/shopping.dart';
import 'package:shopping/screens/splashPage.dart';


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
        '/home': (context) => ShoppingPage(repository: MockShoppingRepository(),
          icons: ShoppingIcons.defaults(),
          currency: "€",),
        // '/home': (context) => Inscription(),
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