import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_poll_page.dart';
import 'pollPage.dart';

class RegistrationPage extends StatefulWidget {
  final String? prefillEmail;
  final String? prefillRole;

  const RegistrationPage({super.key, this.prefillEmail, this.prefillRole});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _role = 'user';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillEmail != null) _email.text = widget.prefillEmail!;
    if (widget.prefillRole != null) _role = widget.prefillRole!;
  }

  Future<void> _register() async {
    final email = _email.text.trim();
    final pass = _password.text;
    final confirm = _confirm.text;

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _loading = true);

    try {
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account already exists. Please login.')),
        );
        return;
      }

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'email': email,
        'role': _role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', _role);
      await prefs.setString('uid', cred.user!.uid);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => _role == 'admin'
              ? const AddPollPage()
              : const PollPage(),
        ),
        (r) => false,
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
              // 🔹 Illustration placeholder
              SizedBox(
          child: Image.asset("assets/signup.png",
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
                      'Register',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color:const Color.fromARGB(255, 18, 56, 96),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Create your account',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
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
                    _field(
                      controller: _confirm,
                      label: 'Confirm Password',
                      icon: Icons.lock_reset,
                      obscure: true,
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        const Text(
                          'Role:',
                          style: TextStyle(fontWeight: FontWeight.w600,color:const Color.fromARGB(255, 18, 56, 96),),
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
                          backgroundColor: const Color(0xFF213448),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _loading ? null : _register,
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Already have an account? Login',
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
