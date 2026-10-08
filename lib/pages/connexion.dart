import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Connexion extends StatefulWidget {
  const Connexion({super.key});

  @override
  State<Connexion> createState() => _ConnexionState();
}

class _ConnexionState extends State<Connexion> {
  final TextEditingController password = TextEditingController();
  final TextEditingController nom = TextEditingController();
  final TextEditingController prenom = TextEditingController();
  final TextEditingController email = TextEditingController();
  bool obscurePassword = true;
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title:Center(
      //   child: Text('Connexion'),
      // ) ,
      // backgroundColor: Colors.transparent,),

      body: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox(height: 160),
          Image.asset('assets/Splash Screen.png', fit: BoxFit.cover),
          const SizedBox(height: 22),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),

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
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            labelStyle: GoogleFonts.poppins(
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: nom,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            labelStyle: GoogleFonts.poppins(
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
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      labelStyle: GoogleFonts.poppins(
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
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.words,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: '********',
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
                      labelStyle: GoogleFonts.poppins(
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
                      onPressed: () {},
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
                          color: Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
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

                  // Padding(
                  //   padding: EdgeInsetsGeometry.all(20),
                  //   child: TextFormField(
                  //     controller: nom,
                  //     keyboardType: TextInputType.text,
                  //
                  //     decoration: InputDecoration(
                  //       prefixIcon: Icon(Icons.person),
                  //
                  //       label: Text("Nom"),
                  //       focusedBorder: OutlineInputBorder(
                  //         borderSide: BorderSide(
                  //           width: 2,
                  //           color: Colors.black,
                  //           style: BorderStyle.solid,
                  //         ),
                  //       ),
                  //       border: OutlineInputBorder(
                  //         borderSide: BorderSide(
                  //           width: 2,
                  //           color: Colors.black,
                  //           style: BorderStyle.solid,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  //
                  // Padding(
                  //   padding: EdgeInsetsGeometry.all(20),
                  //   child: TextFormField(
                  //     controller: prenom,
                  //     keyboardType: TextInputType.text,
                  //
                  //     decoration: InputDecoration(
                  //       prefixIcon: Icon(Icons.person),
                  //
                  //       label: Text("Prenom"),
                  //       focusedBorder: OutlineInputBorder(
                  //         borderSide: BorderSide(
                  //           width: 2,
                  //           color: Colors.black,
                  //           style: BorderStyle.solid,
                  //         ),
                  //       ),
                  //       border: OutlineInputBorder(
                  //         borderSide: BorderSide(
                  //           width: 2,
                  //           color: Colors.black,
                  //           style: BorderStyle.solid,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  //
                  // Padding(
                  //   padding: EdgeInsetsGeometry.all(20),
                  //   child: TextFormField(
                  //     controller: email,
                  //     keyboardType: TextInputType.emailAddress,
                  //
                  //     decoration: InputDecoration(
                  //       prefixIcon: Icon(Icons.email),
                  //
                  //       label: Text("Email"),
                  //       focusedBorder: OutlineInputBorder(
                  //         borderSide: BorderSide(
                  //           width: 2,
                  //           color: Colors.black,
                  //           style: BorderStyle.solid,
                  //         ),
                  //       ),
                  //       border: OutlineInputBorder(
                  //         borderSide: BorderSide(
                  //           width: 2,
                  //           color: Colors.black,
                  //           style: BorderStyle.solid,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  //
                  // Padding(
                  //   padding: EdgeInsetsGeometry.all(20),
                  //   child: TextFormField(
                  //     controller: password,
                  //     keyboardType: TextInputType.visiblePassword,
                  //     obscureText: obscurePassword,
                  //     decoration: InputDecoration(
                  //       prefixIcon: Icon(Icons.lock),
                  //       suffixIcon: IconButton(
                  //         onPressed: () {
                  //           setState(() {
                  //             obscurePassword = !obscurePassword;
                  //           });
                  //         },
                  //         icon: Icon(
                  //           obscurePassword
                  //               ? Icons.visibility_off
                  //               : Icons.visibility,
                  //         ),
                  //       ),
                  //       label: Text("Mot de Passe"),
                  //       focusedBorder: OutlineInputBorder(
                  //         borderSide: BorderSide(
                  //           width: 2,
                  //           color: Colors.black,
                  //           style: BorderStyle.solid,
                  //         ),
                  //       ),
                  //       border: OutlineInputBorder(
                  //         borderSide: BorderSide(
                  //           width: 2,
                  //           color: Colors.black,
                  //           style: BorderStyle.solid,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  //
                  // SizedBox(height: 15),
                  //
                  // Padding(
                  //   padding: EdgeInsetsGeometry.all(20),
                  //   child: SizedBox(
                  //     width: double.infinity,
                  //     child: ElevatedButton(
                  //       onPressed: () {},
                  //       style: ElevatedButton.styleFrom(
                  //         padding: const EdgeInsets.symmetric(vertical: 16),
                  //         backgroundColor: Colors.black,
                  //         foregroundColor: Colors.white,
                  //         elevation: 2,
                  //
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(0),
                  //         ),
                  //       ),
                  //       child: Text(
                  //         "S'inscrire",
                  //         style: TextStyle(
                  //           fontSize: 16,
                  //           fontWeight: FontWeight.bold,
                  //           letterSpacing: 0.5,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
