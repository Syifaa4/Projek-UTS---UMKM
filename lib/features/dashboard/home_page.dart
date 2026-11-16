import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/seed_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = false;

  Future<void> _isiData() async {
    final user = FirebaseAuth.instance.currentUser!;
    setState(() => _loading = true);
    try {
      await SeedService().isiDataContoh(user.uid, email: user.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data contoh 30 hari terisi!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Halo, ${user.displayName ?? user.email ?? 'Pemilik'}'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _isiData,
            icon: const Icon(Icons.science),
            label: Text(_loading ? 'Mengisi...' : 'Isi data contoh 30 hari'),
          ),
        ],
      ),
    );
  }
}