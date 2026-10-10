import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shopping/pages/accueilPage.dart';
import 'package:shopping/pages/connexion.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDA400),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox(height: 160),
          Image.asset('assets/Splash Screen.png', fit: BoxFit.cover),
          const SizedBox(height: 18),

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
                        if (value == null || !value.contains('@')) {
                          return 'Veuillez entrer un email valide';
                        }
                        return null;
                      },
                      // onSaved: (value) => email = value,
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.words,
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
                        if (value.length <= 8) {
                          return 'Le mot de passe doit contenir au moins 8 caractères';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)){
                          return 'Le mot de passe doit contenir au moins une majuscule';
                        }
                        if(!RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=;'/\\\[\]~`]''').hasMatch(value)) {
                          return 'Le mot de passe doit contenir au moins un \n caractère spécial';
                        }
                        if(!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Le mot de passe doit contenir au moins\n un chiffre';
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Inscription validée avec succès !'),
                              ),
                            );
                            Navigator.push(context, MaterialPageRoute(builder: ((context) => const AccueilPage())));
                          }
                        },
                        child: Text(
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
                            Navigator.push(context, MaterialPageRoute(builder: (context)=> const Connexion()));
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
