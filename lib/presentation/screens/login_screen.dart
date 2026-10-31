import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit(bool isSignUp) async {
    setState(() { _loading = true; _error = null; });
    try {
      if (isSignUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wb_sunny, size: 64, color: Colors.orange),
              const SizedBox(height: 8),
              const Text('Kigali Weather', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              if (_loading)
                const CircularProgressIndicator()
              else ...[
                FilledButton(
                  onPressed: () => _submit(false),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Sign In'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _submit(true),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Create Account'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
