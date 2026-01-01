import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'register.dart';
import 'reset_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;

  /* 3(login.dart → _login()) for checking username/password and navigating to HomePage */
  Future<void> _login() async {
    final prefs      = await SharedPreferences.getInstance();
    final storedUser = prefs.getString('username');
    final storedPass = prefs.getString('password');

    if (_userCtrl.text == storedUser && _passCtrl.text == storedPass) {
      await prefs.setBool('loggedIn', true);
      Fluttertoast.showToast(msg: "Welcome, ${_userCtrl.text}!");
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      /* 4(login.dart → setState(_error)) for showing error message on login failure */
      setState(() => _error = 'Invalid username or password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Image.asset('assets/logo-nb.png', width: 120, height: 120),
            const SizedBox(height: 30),
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _login, child: const Text('Login')),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                    child: const Text("Register")),
                const Text('|'),
                TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPwPage())),
                    child: const Text("Forgot password?")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
