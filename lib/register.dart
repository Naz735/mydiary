import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _userCtrl   = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _answerCtrl = TextEditingController();

  final _securityQuestions = [
    "What is your pet's name?",
    "What is your mother's maiden name?",
    "What was the name of your first school?",
    "What is your favorite food?",
  ];

  String? _selectedQuestion;

  /* 6(register.dart → _register()) for saving new account and secret answer */
  Future<void> _register() async {
    if (_selectedQuestion == null || _answerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a question and answer')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _userCtrl.text.trim());
    await prefs.setString('password', _passCtrl.text.trim());
    await prefs.setString('secret_question', _selectedQuestion!);
    await prefs.setString('secret_answer', _answerCtrl.text.trim().toLowerCase());
    await prefs.setBool('loggedIn', false);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Image.asset('assets/logo-nb.png', width: 120, height: 120),
            const SizedBox(height: 20),
            TextField(controller: _userCtrl, decoration: const InputDecoration(labelText: 'Username')),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            /* 5(register.dart → DropdownButtonFormField) for choosing secret question */
            DropdownButtonFormField<String>(
              value: _selectedQuestion,
              decoration: const InputDecoration(labelText: 'Select Secret Question'),
              items: _securityQuestions
                  .map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
              onChanged: (val) => setState(() => _selectedQuestion = val),
            ),
            TextField(controller: _answerCtrl, decoration: const InputDecoration(labelText: 'Secret Answer')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: const Text('Register')),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Already have an account? Log in')),
          ],
        ),
      ),
    );
  }
}
