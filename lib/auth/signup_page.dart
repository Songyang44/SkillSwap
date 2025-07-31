import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signin_page.dart'; // 确保导入登录页

class SignupPage extends StatefulWidget {
  final VoidCallback? onSignupSuccess;

  const SignupPage({super.key, this.onSignupSuccess});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
       if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
      } else {
        setState(() {
          _errorText = '注册失败，未知错误';
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 邮箱输入框
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: borderRadius),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            // 密码输入框
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: borderRadius),
              ),
              obscureText: true,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            // 注册按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign Up'),
              ),
            ),
            const SizedBox(height: 16),
            // 底部跳转登录按钮
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text('Already have an account? Go to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
