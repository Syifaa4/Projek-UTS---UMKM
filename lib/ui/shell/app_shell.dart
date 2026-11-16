import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/seed_service.dart';
import '../beranda/beranda_page.dart';
import '../input/input_page.dart';
import '../katalog/katalog_page.dart';
import '../laporan/laporan_page.dart';
import '../restock/restock_page.dart';
import '../tabungan/tabungan_page.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/glass.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  static const _judul = ['DAGIRA', 'Input', 'Restock', 'Laporan', 'Tabungan'];

  Future<void> _isiData(User user) async {
    Navigator.pop(context);
    final m = ScaffoldMessenger.of(context);
    try {
      await SeedService().isiDataContoh(user.uid, email: user.email);
      m.showSnackBar(const SnackBar(content: Text('Data contoh 30 hari terisi!')));
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _bukaKatalog() {
    Navigator.pop(context); // tutup drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KatalogPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final c = context.dg;

    final halaman = [
      BerandaPage(onTinjau: () => setState(() => _index = 2)),
      const InputPage(),
      const RestockPage(),
      const LaporanPage(),
      const TabunganPage(),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: Text(_judul[_index])),
      drawer: Drawer(
        backgroundColor: c.card,
        child: SafeArea(
          child: Column(children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: c.brand),
              accountName: Text(user.displayName ?? 'Pemilik',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              accountEmail: Text(user.email ?? '',
                  style: const TextStyle(color: Colors.white70)),
              currentAccountPicture: CircleAvatar(
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person) : null,
              ),
            ),
            ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('Katalog produk'),
                onTap: _bukaKatalog),
            ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Produk saya'),
                onTap: () => Navigator.pop(context)),
            ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: const Text('Supplier'),
                onTap: () => Navigator.pop(context)),
            ListTile(
                leading: const Icon(Icons.science_outlined),
                title: const Text('Isi data contoh 30 hari'),
                onTap: () => _isiData(user)),
            const Spacer(),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Mode gelap'),
              value: context.watch<ThemeController>().isDark,
              onChanged: (v) => context.read<ThemeController>().setGelap(v),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: c.keluar),
              title: Text('Keluar', style: TextStyle(color: c.keluar)),
              onTap: () => FirebaseAuth.instance.signOut(),
            ),
          ]),
        ),
      ),
      body: IndexedStack(index: _index, children: halaman),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GlassCard(
            blur: true,
            radius: 32,
            padding: EdgeInsets.zero,
            child: NavigationBar(
              height: 64,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Beranda'),
                NavigationDestination(icon: Icon(Icons.edit_note), label: 'Input'),
                NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Restock'),
                NavigationDestination(icon: Icon(Icons.insights), label: 'Laporan'),
                NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: 'Tabungan'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}