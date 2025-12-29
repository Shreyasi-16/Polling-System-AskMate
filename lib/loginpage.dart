import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'RegistrationPage.dart';
import 'add_poll_page.dart';
import 'pollPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'user';
  bool _loading = false;

  Future<void> _login() async {
    final email = _email.text.trim();
    final pass = _password.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter email and password')));
      return;
    }

    setState(() => _loading = true);
    try {
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (q.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No account found. Please register first.')));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrationPage(
              prefillEmail: email,
              prefillRole: _role,
            ),
          ),
        );
        return;
      }

      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      final roleFromDb = doc.data()?['role'] ?? 'user';

      if (roleFromDb != _role) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selected role ($_role) does not match account role ($roleFromDb)',
            ),
          ),
        );
        await FirebaseAuth.instance.signOut();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', roleFromDb);
      await prefs.setString('uid', cred.user!.uid);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              roleFromDb == 'admin' ? const AddPollPage() : const PollPage(),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
             SizedBox(
          child: Image.asset("assets/login.png",
              width: 300, height: 300, fit: BoxFit.cover)  ,
        ),

             

              // 🔹 Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF213448),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please sign in to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _field(
                      controller: _email,
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      controller: _password,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscure: true,
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        const Text(
                          'Role:',
                          style: TextStyle(fontWeight: FontWeight.w600,color:const Color.fromARGB(255, 18, 56, 96),)
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _role,
                          underline: Container(),
                          items: const [
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('User'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _role = v!),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 18, 56, 96),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegistrationPage(
                                prefillEmail: _email.text.trim(),
                                prefillRole: _role,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Don’t have an account? Sign Up',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 18, 56, 96),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF5F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
