import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopping/screens/shopping.dart';
import 'package:shopping/screens/inscription.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/password_service.dart';
import '../data/utilisateur_repository.dart';
import '../models/utilisateur.dart';

class Connexion extends StatefulWidget {
  const Connexion({super.key});

  @override
  State<Connexion> createState() => _ConnexionState();
}

class _ConnexionState extends State<Connexion> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController password = TextEditingController();
  final TextEditingController email = TextEditingController();
  bool obscurePassword = true;
  bool isOn = false;

  bool _isLoading = false;

  void afficherSnackBar({required String message, required bool succes}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          duration: const Duration(seconds: 3),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: succes
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFE53935),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: succes
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                        : const Color(0xFFE53935).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    succes ? Icons.check_circle_rounded : Icons.error_rounded,
                    color: succes
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE53935),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Future<void> _connecter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final emailSaisi = email.text.trim().toLowerCase();
    final passwordSaisi = password.text;
    bool success = false;

    try {
      // 1. Essayer la connexion via Firebase Auth
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailSaisi,
          password: passwordSaisi,
        );
        success = true;
      } catch (e) {
        debugPrint('Firebase login note: $e');
      }

      // 2. Si Firebase échoue (ou hors-ligne), essayer SQLite
      if (!success) {
        try {
          final SqliteUtilisateurRepository repository = SqliteUtilisateurRepository();
          final Utilisateur? utilisateur = await repository.trouverParEmail(emailSaisi);

          if (utilisateur != null) {
            final motDePasseCorrect = await PasswordService.verifyPassword(
              passwordSaisi,
              utilisateur.passwordHash,
            );
            if (motDePasseCorrect) {
              success = true;
            }
          }
        } catch (e) {
          debugPrint('SQLite login note: $e');
        }
      }

      if (!mounted) return;

      if (!success) {
        afficherSnackBar(
          message: 'E-mail ou mot de passe incorrect.',
          succes: false,
        );
        return;
      }

      afficherSnackBar(
        message: 'Connexion réussie ! Bienvenue.',
        succes: true,
      );

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ShoppingPage(
            repository: MockShoppingRepository(),
            icons: ShoppingIcons.defaults(),
            currency: "€",
          ),
        ),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('ERREUR CONNEXION : $e');
      debugPrint('DÉTAILS : $stackTrace');
      afficherSnackBar(
        message: 'Erreur : $e',
        succes: false,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    password.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDA400),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/Splash Screen.png', fit: BoxFit.cover),
          const SizedBox(height: 18),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 42),
                    Text(
                      'Welcome!',
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    Text(
                      'Login to your Account',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final emailValue = value?.trim() ?? '';

                        if (emailValue.isEmpty) {
                          return 'Veuillez entrer votre adresse e-mail';
                        }

                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(emailValue)) {
                          return 'Veuillez entrer un e-mail valide';
                        }

                        return null;
                      },
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintStyle: GoogleFonts.poppins(
                          color: Color(0xFF79797B),
                          fontSize: 11.54,
                          fontWeight: FontWeight.w500,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            width: 1,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: password,
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre mot de passe';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        hintText: '********',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          iconSize: 18,
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        hintStyle: GoogleFonts.poppins(
                          color: Color(0xFF79797B),
                          fontSize: 11.54,
                          fontWeight: FontWeight.w500,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            width: 1,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B2B2B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isLoading ? null : _connecter,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          child: Text(
                            "Forgot Pasword?",
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Colors.white, thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Colors.white, thickness: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Text(
                        'Sign Up With Social Media',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // TODO : connexion Google
                          },
                          child: Image.asset(
                            'assets/google.png',
                            width: 28,
                            height: 28,
                          ),
                        ),
                        const SizedBox(width: 32),
                        GestureDetector(
                          onTap: () {
                            // TODO : connexion Apple
                          },
                          child: Image.asset(
                            'assets/apple.png',
                            width: 28,
                            height: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Yet to create an account? ',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Inscription(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign UP',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
