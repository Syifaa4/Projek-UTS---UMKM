import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/state_view.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  static const _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  int _pilih = 6;
  bool? _sudahSisih;

  void _snack(String t) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _sudah(AppStore s, int saran) async {
    if (s.tujuan.isEmpty) {
      _snack('Buat tujuan tabungan dulu di tab Tabungan.');
      return;
    }
    final pilih = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SheetBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Disisihkan ke tujuan mana?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (var i = 0; i < s.tujuan.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(s.tujuan[i].emoji, style: const TextStyle(fontSize: 24)),
              title: Text(s.tujuan[i].nama),
              subtitle: Text(s.tujuan[i].jenis),
              onTap: () => Navigator.pop(context, i),
            ),
        ]),
      ),
    );
    if (pilih == null || !mounted) return;
    final err = s.setor(s.tujuan[pilih], saran, 'Sisihan mingguan (${s.persenSisih}% untung)');
    if (err != null) {
      _snack(err);
    } else {
      setState(() => _sudahSisih = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final c = context.dg;
    if (!s.pemilik) {
      return const StateView(
        gambar: 'assets/images/not-found.png',
        judul: 'Khusus pemilik',
        pesan: 'Laporan keuangan hanya bisa dilihat pemilik. Ubah peran di Beranda.',
      );
    }
    final sec = TextStyle(color: c.textSecondary, fontSize: 12);
    final tgl = [for (var i = 6; i >= 0; i--) s.hariIni.subtract(Duration(days: i))];
    final jual = [for (final d in tgl) s.omzetHari(d)];
    var maks = jual.reduce((a, b) => a > b ? a : b);
    if (maks == 0) maks = 1;
    final saran = s.untung7 > 0 ? (s.untung7 * s.persenSisih / 100).round() : 0;
    final kritis = s.stokMenipis.where((x) => x.r.perluKartuKeputusan).toList();
    final g = s.pertumbuhan;

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
                Text('${tglPendek(tgl.first)} - ${tglPendek(tgl.last)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: s.cerita));
              s.catatLog('Laporan mingguan', 'Ringkasan disalin pemilik');
              _snack('Ringkasan laporan disalin');
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin'),
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
              Text(s.cerita, style: const TextStyle(height: 1.5, fontSize: 14)),
              if (g != null) ...[
                const SizedBox(height: 10),
                Pill('${g >= 0 ? '+' : ''}${g.round()}% dari pekan lalu',
                    warna: g >= 0 ? c.masuk : c.keluar,
                    ikon: g >= 0 ? Icons.trending_up : Icons.trending_down),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _metrik(context, 'Total omzet', rp(s.omzet7), 'Pekan ini', c.masuk),
          const SizedBox(width: 10),
          _metrik(context, 'Uang keluar', rp(s.keluar7), 'Selesai dibayar', c.keluar),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _metrik(context, 'Untung kasar', rp(s.untung7), 'Jual dikurangi beli',
              c.isDark ? c.accent : c.warning),
          const SizedBox(width: 10),
          _metrik(context, 'Saldo kas', rp(s.saldo), 'Saat ini', c.info),
        ]),
        const SizedBox(height: 14),
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
                          height: 8 + 92 * jual[i] / maks,
                          decoration: BoxDecoration(
                            color: i == _pilih ? c.accent : c.chip,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_hari[tgl[i].weekday - 1],
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
              decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(Icons.verified_outlined, size: 18, color: c.warning),
                const SizedBox(width: 8),
                Text(tglPendek(tgl[_pilih]), style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(rp(jual[_pilih]), style: const TextStyle(fontWeight: FontWeight.w900)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
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
                child: Text('Saran sisihan dana',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
                saran == 0
                    ? 'Belum ada untung pekan ini untuk disisihkan.'
                    : 'Untung pekan ini ${rp(s.untung7)}. Disarankan menyisihkan ${s.persenSisih}% (${rp(saran)}). Keputusan tetap di tangan Anda.',
                style: TextStyle(color: c.textSecondary, height: 1.45)),
            if (saran > 0) ...[
              const SizedBox(height: 12),
              if (_sudahSisih == true)
                Row(children: [
                  Icon(Icons.task_alt, color: c.masuk),
                  const SizedBox(width: 8),
                  Text('Tercatat di Tabungan.',
                      style: TextStyle(color: c.masuk, fontWeight: FontWeight.w700)),
                ])
              else ...[
                const Text('Sudah disisihkan?', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                      onPressed: () => _sudah(s, saran),
                      child: const Text('Ya, sudah'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () => setState(() => _sudahSisih = false),
                      child: Text(_sudahSisih == false ? 'Ingatkan besok' : 'Belum'),
                    ),
                  ),
                ]),
              ],
            ],
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionTitle('Produk terlaris', ikon: Icons.star_outline),
            const SizedBox(height: 12),
            if (s.terlaris.isEmpty) Text('Belum ada penjualan pekan ini.', style: sec),
            for (var i = 0; i < s.terlaris.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  CircleAvatar(
                      radius: 15,
                      backgroundColor: i == 0 ? c.accent : c.chip,
                      child: Text('${i + 1}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: i == 0 ? c.onAccent : c.textPrimary))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.terlaris[i].p.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('Omzet ${rp(s.terlaris[i].omzet)}',
                          style: TextStyle(color: c.masuk, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  Pill('${s.terlaris[i].qty} ${s.terlaris[i].p.satuan}', warna: c.info),
                ]),
              ),
            if (kritis.isNotEmpty) ...[
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
                        'Perlu perhatian: ${kritis.map((x) => x.p.nama).join(', ')} hampir habis.',
                        style: const TextStyle(fontSize: 13, height: 1.4)),
                  ),
                ]),
              ),
            ],
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
            child: Text(nilai, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: w)),
          ),
          const SizedBox(height: 2),
          Text(ket, style: TextStyle(color: c.textSecondary, fontSize: 11)),
        ]),
      ),
    );
  }
}