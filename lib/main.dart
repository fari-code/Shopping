import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shopping/screens/connexion.dart';
import 'package:shopping/screens/inscription.dart';
import 'package:shopping/screens/search.dart';
import 'package:shopping/screens/shopping.dart';
import 'package:shopping/screens/splashPage.dart';

import 'data/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
      routes: {
        '/splash': (context) => const SplashPage(),
        '/connexion': (context) => const Connexion(),
        '/inscription': (context) => const Inscription(),
        '/search': (context) => const Search(),
        '/shopping': (context) => ShoppingPage(
          repository: MockShoppingRepository(),
          icons: ShoppingIcons.defaults(),
          currency: "€",
        ),
        '/home': (context) => ShoppingPage(
          repository: MockShoppingRepository(),
          icons: ShoppingIcons.defaults(),
          currency: "€",
        ),
      },
    );
  }
}
