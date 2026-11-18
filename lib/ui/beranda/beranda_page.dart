import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key, required this.onGoto});
  final ValueChanged<int> onGoto;

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  bool _sembunyi = false, _rincian = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final c = context.dg;
    final nama = (FirebaseAuth.instance.currentUser?.displayName ?? 'Juragan')
        .split(' ')
        .first;
    final angka = c.isDark ? c.accent : c.brand;
    final sec = TextStyle(color: c.textSecondary, fontSize: 12);
    final tutup = _sembunyi || !s.pemilik;
    String t(int v) => tutup ? 'Rp ••••••' : rp(v);

    final menunggu = s.rekom.where((r) => r.status == 'menunggu').toList();
    final estimasi = menunggu.fold<int>(0, (a, r) => a + r.total);
    final menipis = s.stokMenipis.take(4).toList();
    final totalTarget = s.tujuan.fold<int>(0, (a, x) => a + x.target);
    final pct = totalTarget == 0
        ? 0.0
        : (s.totalTabungan / totalTarget).clamp(0.0, 1.0).toDouble();
    final jam = s.terakhirRobot;
    final jamTeks = jam == null
        ? '-'
        : '${jam.hour.toString().padLeft(2, '0')}.${jam.minute.toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        Muncul(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Halo, $nama 👋',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(tanggalId(DateTime.now()), style: sec),
              ]),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () => s.setPemilik(!s.pemilik),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    border: Border.all(color: c.cardBorder),
                    borderRadius: BorderRadius.circular(99)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, size: 9, color: s.pemilik ? c.masuk : c.info),
                  const SizedBox(width: 6),
                  Text(s.pemilik ? 'Pemilik' : 'Staf',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Icon(Icons.swap_horiz, size: 16, color: c.textSecondary),
                ]),
              ),
            ),
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
                if (s.pemilik)
                  GestureDetector(
                    onTap: () => setState(() => _sembunyi = !_sembunyi),
                    child: Icon(_sembunyi ? Icons.visibility_off : Icons.visibility,
                        size: 20, color: c.textSecondary),
                  ),
              ]),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(t(s.saldo),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: angka)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.accent.withValues(alpha: 0.35)),
                ),
                child: Column(children: [
                  Row(children: [
                    Icon(Icons.shield_outlined, size: 18, color: c.warning),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Kas tersedia untuk belanja',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _rincian = !_rincian),
                      child: Icon(Icons.info_outline, size: 20, color: c.textSecondary),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(t(s.kasTersedia),
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w900, color: angka)),
                      ),
                    ),
                    const Spacer(),
                    Text('Dapat dipakai restok', style: sec),
                  ]),
                  if (_rincian) ...[
                    const Divider(height: 22),
                    _baris('Saldo kas', t(s.saldo), sec),
                    _baris('Batas aman kas', '- ${t(s.batasAman)}', sec),
                    _baris('Dana tabungan terkunci', '- ${t(s.totalTabungan)}', sec),
                    _baris('Pesanan terencana', '- ${t(s.rencanaKeluar)}', sec),
                  ],
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Muncul(
          urutan: 2,
          child: Row(children: [
            _mini(context, Icons.south_west, 'Uang masuk', t(s.masukHariIni), 'Hari ini', c.masuk),
            const SizedBox(width: 8),
            _mini(context, Icons.north_east, 'Uang keluar', t(s.keluarHariIni), 'Hari ini', c.keluar),
            const SizedBox(width: 8),
            _mini(context, Icons.bar_chart, 'Untung kasar', t(s.untung7), 'Pekan ini',
                c.isDark ? c.accent : c.warning),
          ]),
        ),
        const SizedBox(height: 12),
        if (s.pemilik)
          Muncul(
            urutan: 3,
            child: menunggu.isEmpty
                ? GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Image.asset('assets/images/growth.png',
                          height: 56,
                          errorBuilder: (_, _, _) =>
                              Icon(Icons.check_circle_outline, size: 40, color: c.masuk)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Tidak ada keputusan tertunda. Semua stok aman.',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  )
                : GlassCard(
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
                        Pill('${menunggu.length} barang', warna: c.keluar),
                      ]),
                      const SizedBox(height: 10),
                      Text(
                          '${menunggu.map((r) => s.cari(r.produkId)?.nama ?? '').take(2).join(' dan ')} perlu dipesan. Rekomendasi sudah dicocokkan dengan kas belanja Anda.',
                          style: TextStyle(color: c.textSecondary, height: 1.4)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: c.chip, borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          Icon(Icons.circle, size: 9, color: c.keluar),
                          const SizedBox(width: 8),
                          const Text('Estimasi biaya',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const Spacer(),
                          Text(rp(estimasi),
                              style: TextStyle(fontWeight: FontWeight.w800, color: c.info)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => widget.onGoto(2),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Tinjau restok sekarang'),
                      ),
                    ]),
                  ),
          ),
        if (s.pemilik) const SizedBox(height: 16),
        Muncul(
          urutan: 4,
          child: SectionTitle('Stok cepat menipis', ikon: Icons.inventory_2_outlined),
        ),
        const SizedBox(height: 10),
        if (menipis.isEmpty)
          Text('Belum ada data penjualan yang cukup.', style: sec)
        else
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: menipis.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final x = menipis[i];
                final sisa = x.r.sisaHariStok!;
                final titik = x.r.titikPesanUlang;
                final kritis = sisa <= titik;
                final waspada = sisa <= titik * 1.6;
                final w = kritis ? c.keluar : (waspada ? c.warning : c.masuk);
                final label = kritis ? 'Kritis' : (waspada ? 'Waspada' : 'Aman');
                return SizedBox(
                  width: 236,
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    radius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Text('${x.p.emoji} ${x.p.nama}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 6),
                          Pill(label, warna: w),
                        ]),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Sisa ${x.p.stok} ${x.p.satuan}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('Habis ~${sisa.ceil()} hari',
                              style: TextStyle(
                                  color: w, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        Muncul(
          urutan: 5,
          child: GestureDetector(
            onTap: () => widget.onGoto(4),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Dana tabungan',
                        style: TextStyle(
                            color: c.masuk, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(s.tujuan.isEmpty ? 'Belum ada tujuan' : '${s.tujuan.length} tujuan',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${t(s.totalTabungan)} / ${t(totalTarget)}', style: sec),
                  ]),
                ),
                RingProgress(
                  nilai: pct,
                  ukuran: 60,
                  tebal: 7,
                  warna: c.masuk,
                  jalur: c.chip,
                  child: Text('${(pct * 100).round()}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Muncul(
          urutan: 6,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconTile(
                  ukuran: 38,
                  warna: c.accent,
                  child: Icon(Icons.lightbulb_outline, size: 20, color: c.warning)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('CERITA TOKO PEKAN INI',
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: c.warning)),
                  const SizedBox(height: 4),
                  Text(tutup ? 'Ringkasan keuangan disembunyikan.' : s.cerita,
                      style: TextStyle(color: c.textSecondary, height: 1.45)),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.smart_toy_outlined, size: 14, color: c.textSecondary),
          const SizedBox(width: 6),
          Text('Robot terakhir menghitung $jamTeks', style: sec.copyWith(fontSize: 11)),
          TextButton(
            onPressed: () {
              final n = s.jalankanRobot();
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(SnackBar(content: Text('Robot selesai: $n rekomendasi baru')));
            },
            child: const Text('Jalankan'),
          ),
        ]),
      ],
    );
  }

  Widget _baris(String k, String v, TextStyle sec) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: sec),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      );

  Widget _mini(BuildContext context, IconData ikon, String judul, String nilai,
      String ket, Color warna) {
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
          Text(ket, style: TextStyle(color: c.textSecondary, fontSize: 11)),
        ]),
      ),
    );
  }
}