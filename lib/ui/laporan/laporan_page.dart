import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  static const _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _nama = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const _jual = [1100000, 1250000, 1050000, 1300000, 1480000, 1850000, 1520000];
  int _pilih = 5;
  bool? _sudahSisih;

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    final nama =
        (FirebaseAuth.instance.currentUser?.displayName ?? 'Juragan').split(' ').first;
    final sec = TextStyle(color: c.textSecondary, fontSize: 12);
    final maks = _jual.reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        Row(children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  border: Border.all(color: c.cardBorder),
                  borderRadius: BorderRadius.circular(99)),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: c.warning),
                const SizedBox(width: 8),
                const Text('9 Nov - 15 Nov 2026',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                Icon(Icons.expand_more, size: 18, color: c.textSecondary),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),

        Muncul(
          child: GlassCard(
            blur: true,
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.auto_stories_outlined, size: 18, color: c.warning),
                const SizedBox(width: 8),
                Text('CERITA PEKAN INI',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                        color: c.warning)),
              ]),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(style: const TextStyle(height: 1.5, fontSize: 14), children: [
                  TextSpan(text: 'Pak/Bu $nama, '),
                  const TextSpan(text: 'pekan ini toko untung kasar '),
                  TextSpan(
                      text: 'Rp 1.240.000',
                      style: TextStyle(fontWeight: FontWeight.w800, color: c.masuk)),
                  const TextSpan(text: ' dari omzet Rp 9.850.000. Minyak Goreng dan Beras jadi penyumbang terbesar.'),
                ]),
              ),
              const SizedBox(height: 10),
              Pill('+14% dari pekan lalu', warna: c.masuk, ikon: Icons.trending_up),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        Row(children: [
          _metrik(context, 'Total omzet', 'Rp 9.850.000', '164 transaksi', c.masuk),
          const SizedBox(width: 10),
          _metrik(context, 'Uang keluar', 'Rp 8.610.000', 'Kulakan & operasional', c.keluar),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _metrik(context, 'Untung kasar', 'Rp 1.240.000', 'Margin rata-rata 12,6%',
              c.isDark ? c.accent : c.warning),
          const SizedBox(width: 10),
          _metrik(context, 'Saldo kas', 'Rp 4.850.000', 'Akhir pekan', c.info),
        ]),
        const SizedBox(height: 14),

        // Grafik
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Penjualan harian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text('Ketuk batang untuk melihat nilainya', style: sec),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _pilih = i),
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 26,
                          height: 100 * _jual[i] / maks,
                          decoration: BoxDecoration(
                            color: i == _pilih ? c.accent : c.chip,
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_hari[i],
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: i == _pilih ? FontWeight.w800 : FontWeight.w500,
                                color: i == _pilih ? c.textPrimary : c.textSecondary)),
                      ]),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: c.chip, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(Icons.verified_outlined, size: 18, color: c.warning),
                const SizedBox(width: 8),
                Text(_nama[_pilih],
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(rp(_jual[_pilih]),
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Saran sisihan
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconTile(
                  ukuran: 38,
                  warna: c.masuk,
                  child: Icon(Icons.savings_outlined, size: 20, color: c.masuk)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Saran sisihan dana cadangan',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
                'Untung pekan ini Rp 1.240.000. Disarankan menyisihkan 10% (Rp 124.000). Keputusan tetap di tangan Anda.',
                style: TextStyle(color: c.textSecondary, height: 1.45)),
            const SizedBox(height: 12),
            if (_sudahSisih == true)
              Row(children: [
                Icon(Icons.task_alt, color: c.masuk),
                const SizedBox(width: 8),
                Text('Tercatat. Kas Anda makin sehat.',
                    style: TextStyle(color: c.masuk, fontWeight: FontWeight.w700)),
              ])
            else ...[
              const Text('Sudah disisihkan?', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                    onPressed: () => setState(() => _sudahSisih = true),
                    child: const Text('Ya, sudah'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    onPressed: () => setState(() => _sudahSisih = false),
                    child: Text(_sudahSisih == false ? 'Ingatkan besok' : 'Belum'),
                  ),
                ),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 12),

        // Terlaris
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionTitle('Produk terlaris', ikon: Icons.star_outline),
            const SizedBox(height: 12),
            _terlaris(context, 1, 'Minyak Goreng 2L', 'Omzet Rp 2.380.000', '68 terjual'),
            _terlaris(context, 2, 'Mie Instan Goreng', 'Omzet Rp 440.200', '142 bks'),
            _terlaris(context, 3, 'Telur Ayam Negeri', 'Omzet Rp 1.260.000', '45 kg'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: c.keluar.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber_rounded, color: c.keluar, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Gula Pasir 1kg berputar lambat (8 bks terjual). Pertimbangkan mengurangi pesanan berikutnya.',
                      style: const TextStyle(fontSize: 13, height: 1.4)),
                ),
              ]),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _metrik(BuildContext context, String judul, String nilai, String ket, Color w) {
    final c = context.dg;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        radius: 20,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(judul, style: TextStyle(color: c.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(nilai,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: w)),
          ),
          const SizedBox(height: 2),
          Text(ket, style: TextStyle(color: c.textSecondary, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _terlaris(BuildContext context, int no, String nama, String omzet, String qty) {
    final c = context.dg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        CircleAvatar(
            radius: 15,
            backgroundColor: no == 1 ? c.accent : c.chip,
            child: Text('$no',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: no == 1 ? c.onAccent : c.textPrimary))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nama, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(omzet, style: TextStyle(color: c.masuk, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
        Pill(qty, warna: c.info),
      ]),
    );
  }
}