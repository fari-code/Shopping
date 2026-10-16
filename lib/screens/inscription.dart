import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopping/screens/accueilPage.dart';
import 'package:shopping/screens/connexion.dart';
import 'package:sqflite/sqflite.dart';

import '../data/password_service.dart';
import '../data/utilisateur_repository.dart';
import '../models/utilisateur.dart';

class Inscription extends StatefulWidget {
  const Inscription({super.key});

  @override
  State<Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController password = TextEditingController();
  final TextEditingController nom = TextEditingController();
  final TextEditingController prenom = TextEditingController();
  final TextEditingController email = TextEditingController();
  bool obscurePassword = true;
  bool isOn = false;
  final SqliteUtilisateurRepository _repository = SqliteUtilisateurRepository();

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

  Future<void> _inscrire() async {
    // 1. Vérifier les champs du formulaire.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final emailSaisi = email.text.trim().toLowerCase();

    try {
      // 2. Vérifier si l'adresse e-mail existe déjà.
      final existant = await _repository.trouverParEmail(emailSaisi);

      if (existant != null) {
        if (!mounted) return;

        afficherSnackBar(
          message: 'Cette adresse e-mail est déjà utilisée.',
          succes: false,
        );
        return;
      }

      // 3. Hacher le mot de passe avant de l'enregistrer.
      final hash = await PasswordService.hashPassword(password.text);

      // 4. Créer l'utilisateur.
      final utilisateur = Utilisateur(
        nom: nom.text.trim(),
        prenom: prenom.text.trim(),
        email: emailSaisi,
        passwordHash: hash,
      );

      // 5. Enregistrer l'utilisateur dans SQLite.
      await _repository.ajouter(utilisateur);

      if (!mounted) return;

      // 6. Afficher le message de succès.
      afficherSnackBar(
        message: 'Inscription réussie ! Connectez-vous.',
        succes: true,
      );

      // 7. Laisser le temps de lire le message.
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // 8. Ouvrir la page de connexion.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Connexion()),
      );
    } on DatabaseException {
      if (!mounted) return;

      afficherSnackBar(
        message:
            'Impossible d’enregistrer le compte. '
            'Vérifiez si cet e-mail est déjà utilisé.',
        succes: false,
      );
    } catch (e,stackTrace) {
      if (!mounted) return;

      // afficherSnackBar(
      //   message: 'Une erreur est survenue pendant l’inscription.',
      //   succes: false,
      // );
      debugPrint('ERREUR INSCRIPTION : $e');
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
    nom.dispose();
    prenom.dispose();
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
          // SizedBox(height: 160),
          Image.asset('assets/Splash Screen.png', fit: BoxFit.cover),
          // const SizedBox(height: 18),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),

              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Switch(
                        value: isOn,
                        inactiveTrackColor: const Color(0xFF222222),
                        activeThumbColor: const Color(0xFFFDA400),
                        onChanged: (value) {
                          setState(() {
                            isOn = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 42),
                    Text(
                      'Hi!',
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    Text(
                      'Create your account',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    // SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: prenom,
                            validator: ((value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer vôtre prenom'; // Message d'erreur affiché
                              }
                              return null;
                            }),
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'First Name',
                              hintStyle: GoogleFonts.poppins(
                                color: Color(0xFF79797B),
                                fontSize: 11.54,
                                fontWeight: FontWeight.w500,
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: nom,

                            validator: ((value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer vôtre nom'; // Message d'erreur affiché
                              }
                              return null;
                            }),
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'Last Name',
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),
                    TextFormField(
                      controller: email,
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
                      // onSaved: (value) => email = value,
                      keyboardType: TextInputType.emailAddress,

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
                      keyboardType: TextInputType.visiblePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre mot de passe';
                        }
                        if (value.length < 8) {
                          return 'Le mot de passe doit contenir au moins 8 caractères';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Le mot de passe doit contenir au moins une majuscule';
                        }
                        if (!RegExp(
                          r'''[!@#$%^&*(),.?":{}|<>_\-+=;'/\\\[\]~`]''',
                        ).hasMatch(value)) {
                          return 'Le mot de passe doit contenir au moins un \n caractère spécial';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Le mot de passe doit contenir au moins\n un chiffre';
                        }

                        return null;
                      },

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
                        onPressed: _isLoading ? null : _inscrire,
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
                                'Sign Up',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
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
                          'Already have an account? ',
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
                                builder: (context) => const Connexion(),
                              ),
                            );
                          },
                          child: Text(
                            'Login',
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
