import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class PengaturanPage extends StatelessWidget {
  const PengaturanPage({super.key});

  Widget _param(BuildContext context, String judul, String ket, String nilai,
      VoidCallback kurang, VoidCallback tambah) {
    final c = context.dg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(judul, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(ket, style: TextStyle(color: c.textSecondary, fontSize: 12)),
          ]),
        ),
        tombolBulat(context, Icons.remove, kurang),
        SizedBox(
          width: 84,
          child: Text(nilai,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ),
        tombolBulat(context, Icons.add, tambah, utama: true),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final tema = context.watch<ThemeController>();
    final c = context.dg;

    Widget bagian(String judul) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Text(judul.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: c.textSecondary)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
        bagian('Tampilan'),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            SwitchListTile(
              title: const Text('Mode gelap'),
              value: tema.isDark,
              onChanged: tema.setGelap,
            ),
            SwitchListTile(
              title: const Text('Huruf besar'),
              subtitle: const Text('Lebih nyaman dibaca'),
              value: tema.besar,
              onChanged: tema.setBesar,
            ),
          ]),
        ),
        bagian('Peran'),
        GlassCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            title: const Text('Mode pemilik'),
            subtitle: const Text('Staf tidak melihat saldo, laporan, dan keputusan restok'),
            value: s.pemilik,
            onChanged: s.setPemilik,
          ),
        ),
        bagian('Aturan hitung robot'),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: [
            _param(context, 'Hari cakupan stok', 'Pesan untuk berapa hari ke depan',
                '${s.hariCakupan} hari', () {
              s.hariCakupan = (s.hariCakupan - 1).clamp(3, 60);
              s.simpan();
            }, () {
              s.hariCakupan = (s.hariCakupan + 1).clamp(3, 60);
              s.simpan();
            }),
            const Divider(height: 1),
            _param(context, 'Batas aman kas', 'Kas yang tidak boleh dipakai belanja',
                rpSingkat(s.batasAman), () {
              s.batasAman = (s.batasAman - 100000).clamp(0, 50000000);
              s.simpan();
            }, () {
              s.batasAman = (s.batasAman + 100000).clamp(0, 50000000);
              s.simpan();
            }),
            const Divider(height: 1),
            _param(context, 'Ambang lonjakan', 'Penjualan hari ini dianggap melonjak',
                '${s.ambang.toStringAsFixed(1)}× rata-rata', () {
              s.ambang = (s.ambang - 0.5).clamp(1.5, 10.0);
              s.simpan();
            }, () {
              s.ambang = (s.ambang + 0.5).clamp(1.5, 10.0);
              s.simpan();
            }),
            const Divider(height: 1),
            _param(context, 'Persen sisihan', 'Saran sisihan dari untung pekanan',
                '${s.persenSisih}%', () {
              s.persenSisih = (s.persenSisih - 1).clamp(0, 50);
              s.simpan();
            }, () {
              s.persenSisih = (s.persenSisih + 1).clamp(0, 50);
              s.simpan();
            }),
            const Divider(height: 1),
            _param(context, 'Masa tahan penolakan', 'Rekomendasi serupa ditahan',
                '${s.masaTahanTolak} hari', () {
              s.masaTahanTolak = (s.masaTahanTolak - 1).clamp(0, 14);
              s.simpan();
            }, () {
              s.masaTahanTolak = (s.masaTahanTolak + 1).clamp(0, 14);
              s.simpan();
            }),
          ]),
        ),
        bagian('Data'),
        GlassCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('Isi ulang data contoh'),
            subtitle: const Text('Mengembalikan semua data ke kondisi awal demo'),
            onTap: () async {
              final ya = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Isi ulang data contoh?'),
                  content: const Text('Semua perubahan Anda di aplikasi ini akan diganti data contoh.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Isi ulang')),
                  ],
                ),
              );
              if (ya == true && context.mounted) {
                s.isiDemo();
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(const SnackBar(content: Text('Data contoh dimuat ulang')));
              }
            },
          ),
        ),
        bagian('Tentang'),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Text(
              'DAGIRA membantu mencatat penjualan dan kas, menyiapkan rekomendasi restok, dan menyusun laporan. '
              'Perhitungan memakai rumus rata-rata biasa, bukan prediksi AI. Aplikasi hanya mencatat dan tidak menyimpan uang Anda. '
              'Keterbatasan versi ini: data tersimpan di memori perangkat dan hilang saat aplikasi ditutup, '
              'dan pembacaan scan masih berupa contoh.',
              style: TextStyle(color: c.textSecondary, height: 1.5, fontSize: 13)),
        ),
      ]),
    );
  }
}