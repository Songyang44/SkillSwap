import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/signup_page.dart';
import '../pages/profile_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.session != null) {
       Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage()),
        );
      } else {
        setState(() {
          _errorText = '未知错误，登录失败';
        });
      }
    } on AuthException catch (error) {
      setState(() {
        _errorText = error.message;
      });
    } catch (error) {
      setState(() {
        _errorText = '发生错误：$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: borderRadius),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(borderRadius: borderRadius),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  backgroundColor: Colors.green,
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignupPage()),
                  );
              },
              child: const Text('No account？Go to Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
