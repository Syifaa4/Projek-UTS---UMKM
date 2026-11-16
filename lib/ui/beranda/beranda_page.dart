import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key, required this.onTinjau});
  final VoidCallback onTinjau;

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  bool _sembunyi = false;

  String _t(String s) => _sembunyi ? 'Rp ••••••' : s;

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    final nama =
        (FirebaseAuth.instance.currentUser?.displayName ?? 'Juragan').split(' ').first;
    final angka = c.isDark ? c.accent : c.brand;
    final sec = TextStyle(color: c.textSecondary, fontSize: 12);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        Muncul(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Halo, $nama 👋',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(tanggalId(DateTime.now()), style: sec),
          ]),
        ),
        const SizedBox(height: 16),
        Muncul(
          urutan: 1,
          child: GlassCard(
            blur: true,
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('SALDO KAS SAAT INI',
                    style: sec.copyWith(letterSpacing: 1, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _sembunyi = !_sembunyi),
                  child: Icon(_sembunyi ? Icons.visibility_off : Icons.visibility,
                      size: 20, color: c.textSecondary),
                ),
              ]),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(_t('Rp 4.850.000'),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: angka)),
              ),
              const SizedBox(height: 8),
              Pill('+8,2% dari pekan lalu', warna: c.masuk, ikon: Icons.trending_up),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.accent.withValues(alpha: 0.35)),
                ),
                child: Row(children: [
                  Icon(Icons.shield_outlined, size: 18, color: c.warning),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Kas tersedia untuk belanja',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  Text(_t('Rp 1.200.000'),
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900, color: angka)),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Muncul(
          urutan: 2,
          child: Row(children: [
            _mini(context, Icons.south_west, 'Uang masuk', _t('Rp 850.000'), c.masuk),
            const SizedBox(width: 8),
            _mini(context, Icons.north_east, 'Uang keluar', _t('Rp 210.000'), c.keluar),
            const SizedBox(width: 8),
            _mini(context, Icons.bar_chart, 'Untung', _t('Rp 1,24 jt'),
                c.isDark ? c.accent : c.warning),
          ]),
        ),
        const SizedBox(height: 12),
        Muncul(
          urutan: 3,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconTile(
                    warna: c.accent,
                    child: Icon(Icons.priority_high, color: c.warning)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Perlu keputusan Anda',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                Pill('2 barang', warna: c.keluar),
              ]),
              const SizedBox(height: 10),
              Text(
                  'Minyak Goreng dan Beras mulai menipis. Rekomendasi sudah dicocokkan dengan kas belanja Anda.',
                  style: TextStyle(color: c.textSecondary, height: 1.4)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: widget.onTinjau,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Tinjau restok sekarang'),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Muncul(
          urutan: 4,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dana cadangan warung',
                      style: TextStyle(
                          color: c.masuk, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Renovasi rak & etalase',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(_t('Rp 2,88 jt / Rp 5 jt'), style: sec),
                ]),
              ),
              RingProgress(
                nilai: 0.576,
                ukuran: 60,
                tebal: 7,
                warna: c.masuk,
                jalur: c.chip,
                child: const Text('58%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _mini(BuildContext context, IconData ikon, String judul, String nilai,
      Color warna) {
    final c = context.dg;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        radius: 20,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(ikon, size: 15, color: warna),
            const SizedBox(width: 4),
            Expanded(
              child: Text(judul,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: warna, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(nilai,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: warna)),
          ),
          Text('Hari ini', style: TextStyle(color: c.textSecondary, fontSize: 11)),
        ]),
      ),
    );
  }
}