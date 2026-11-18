import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  String? _error;

  Future<void> _masukGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = GoogleAuthProvider();
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code != 'popup-closed-by-user' &&
          e.code != 'cancelled-popup-request' &&
          e.code != 'web-context-canceled') {
        setState(() => _error = 'Login gagal (${e.code}). Coba lagi.');
      }
    } catch (e) {
      setState(() => _error = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/images/mascot-main.png',
                    height: 190,
                    errorBuilder: (_, _, _) => Icon(Icons.storefront,
                        size: 100, color: c.accent)),
                const SizedBox(height: 12),
                Image.asset('assets/images/logo.png',
                    height: 70,
                    errorBuilder: (_, _, _) => const Text('DAGIRA',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900))),
                const SizedBox(height: 8),
                Text('Usaha tertata, keputusan lebih cerdas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.textSecondary)),
                const SizedBox(height: 36),
                if (_error != null) ...[
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.keluar)),
                  const SizedBox(height: 14),
                ],
                FilledButton.icon(
                  onPressed: _loading ? null : _masukGoogle,
                  icon: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.login),
                  label: Text(_loading ? 'Memproses...' : 'Masuk dengan Google'),
                ),
                const SizedBox(height: 14),
                Text('Aplikasi hanya mencatat, tidak menyimpan uang Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.textSecondary, fontSize: 12)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}