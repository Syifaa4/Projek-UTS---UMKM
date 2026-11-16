import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

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
        // Chrome: popup bawaan Firebase, tanpa Client ID manual
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // Android/iOS: alur native Firebase
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
      // Setelah ini StreamBuilder di main.dart otomatis pindah ke HomePage
    } on FirebaseAuthException catch (e) {
      // Pengguna menutup popup: bukan error, abaikan saja
      if (e.code != 'popup-closed-by-user' &&
          e.code != 'cancelled-popup-request' &&
          e.code != 'web-context-canceled') {
        setState(() => _error = 'Firebase menolak login: ${e.code}');
      }
    } catch (e) {
      setState(() => _error = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront, size: 80, color: warna.primary),
                  const SizedBox(height: 16),
                  Text(
                    'UMKM Copilot',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aplikasi menyiapkan, pemilik memutuskan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: warna.onSurfaceVariant),
                  ),
                  const SizedBox(height: 40),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: warna.error),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _masukGoogle,
                      icon: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        _loading ? 'Memproses...' : 'Masuk dengan Google',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}