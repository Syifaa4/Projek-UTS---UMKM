import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class _Setoran {
  _Setoran(this.ket, this.nominal, this.tgl);
  final String ket;
  final int nominal;
  final DateTime tgl;
}

class TabunganPage extends StatefulWidget {
  const TabunganPage({super.key});

  @override
  State<TabunganPage> createState() => _TabunganPageState();
}

class _TabunganPageState extends State<TabunganPage> {
  static const _target = 5000000;
  final _mulai = DateTime(2026, 10, 1);
  final _tenggat = DateTime(2026, 12, 31);

  final _riwayat = <_Setoran>[
    _Setoran('Saldo awal dana cadangan', 2556000, DateTime(2026, 10, 2)),
    _Setoran('Bonus penjualan akhir pekan', 100000, DateTime(2026, 10, 24)),
    _Setoran('Sisihan harian', 50000, DateTime(2026, 11, 8)),
    _Setoran('Sisihan mingguan (10% untung)', 124000, DateTime(2026, 11, 9)),
    _Setoran('Sisihan untung harian', 50000, DateTime(2026, 11, 14)),
  ];

  int get _terkumpul => _riwayat.fold(0, (s, e) => s + e.nominal);

  Future<void> _tambah() async {
    final s = await showModalBottomSheet<_Setoran>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SetoranSheet(),
    );
    if (s != null && mounted) setState(() => _riwayat.add(s));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    final sec = TextStyle(color: c.textSecondary, fontSize: 12);
    final sekarang = DateTime.now();
    final sisaHari = _tenggat.difference(sekarang).inDays.clamp(1, 9999);
    final totalHari = _tenggat.difference(_mulai).inDays;
    final lewat = (sekarang.difference(_mulai).inDays / totalHari).clamp(0.0, 1.0);
    final seharusnya = _target * lewat;
    final onTrack = _terkumpul >= seharusnya;
    final pct = (_terkumpul / _target).clamp(0.0, 1.0);
    final sisaTarget = (_target - _terkumpul).clamp(0, _target);
    final perHari = sisaTarget / sisaHari;
    final urut = [..._riwayat]..sort((a, b) => b.tgl.compareTo(a.tgl));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(14),
          radius: 20,
          child: Row(children: [
            Icon(Icons.verified_user_outlined, color: c.warning, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  'Aplikasi hanya mencatat, tidak menyimpan uang Anda. Uang tetap di rekening atau laci kas Anda.',
                  style: const TextStyle(fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Muncul(
          child: GlassCard(
            blur: true,
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Pill(onTrack ? 'On track' : 'Tertinggal',
                    warna: onTrack ? c.masuk : c.warning,
                    ikon: onTrack ? Icons.check_circle_outline : Icons.schedule),
              ),
              const SizedBox(height: 10),
              const Text('Renovasi etalase warung',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Target ${tglPendek(_tenggat)} • $sisaHari hari lagi', style: sec),
              const SizedBox(height: 18),
              RingProgress(
                nilai: pct,
                ukuran: 170,
                tebal: 14,
                warna: c.accent,
                jalur: c.chip,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${(pct * 100).round()}%',
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                  Text('TERCAPAI',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary)),
                ]),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Terkumpul', style: sec),
                    Text(rp(_terkumpul),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: c.isDark ? c.accent : c.brand)),
                    Text('dari ${rp(_target)}', style: sec.copyWith(fontSize: 11)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Sisa kebutuhan', style: sec),
                  Text(rp(sisaTarget),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _mini(context, Icons.calendar_today_outlined, 'Per hari', rp(perHari)),
          const SizedBox(width: 8),
          _mini(context, Icons.history, 'Setoran akhir',
              urut.isEmpty ? '-' : rp(urut.first.nominal)),
          const SizedBox(width: 8),
          _mini(context, Icons.savings_outlined, 'Total setoran', '${_riwayat.length} kali'),
        ]),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _tambah,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Catat setoran baru'),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(14),
          radius: 20,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lock_outline, size: 20, color: c.info),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  'Dana cadangan tidak dipakai untuk rekomendasi restock. Kas belanja Anda dilindungi supaya modal harian tidak terpakai untuk hal lain.',
                  style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.45)),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        SectionTitle('Riwayat setoran',
            ikon: Icons.receipt_long_outlined,
            trailing: Text('Geser untuk hapus', style: sec)),
        const SizedBox(height: 10),
        for (final s in urut)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Dismissible(
              key: ObjectKey(s),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                    color: c.keluar.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.delete_outline, color: c.keluar),
              ),
              onDismissed: (_) {
                setState(() => _riwayat.remove(s));
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(
                    content: const Text('Setoran dihapus'),
                    action: SnackBarAction(
                        label: 'Urungkan',
                        onPressed: () => setState(() => _riwayat.add(s))),
                  ));
              },
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                radius: 20,
                child: Row(children: [
                  IconTile(
                      ukuran: 40,
                      warna: c.masuk,
                      child: Icon(Icons.south_west, size: 18, color: c.masuk)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.ket,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(tglPendek(s.tgl), style: sec.copyWith(fontSize: 11)),
                    ]),
                  ),
                  Text('+ ${rp(s.nominal)}',
                      style: TextStyle(color: c.masuk, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _mini(BuildContext context, IconData ikon, String judul, String nilai) {
    final c = context.dg;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        radius: 20,
        child: Column(children: [
          Icon(ikon, size: 18, color: c.info),
          const SizedBox(height: 6),
          Text(judul, style: TextStyle(color: c.textSecondary, fontSize: 11)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(nilai,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ]),
      ),
    );
  }
}

class _SetoranSheet extends StatefulWidget {
  const _SetoranSheet();

  @override
  State<_SetoranSheet> createState() => _SetoranSheetState();
}

class _SetoranSheetState extends State<_SetoranSheet> {
  final _nominal = TextEditingController();
  final _ket = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _nominal.dispose();
    _ket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SheetBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Catat setoran baru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(
            controller: _nominal,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            decoration: dekorasi(context, 'Nominal', prefix: 'Rp ', error: _err),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final n in [20000, 50000, 100000])
              ActionChip(
                  label: Text('+${n ~/ 1000}rb'),
                  onPressed: () => setState(() {
                        _nominal.text = '$n';
                        _err = null;
                      })),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _ket,
            decoration: dekorasi(context, 'Catatan (opsional)',
                hint: 'Contoh: sisihan untung beras'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(_nominal.text.replaceAll('.', '').trim());
              if (n == null || n <= 0) {
                setState(() => _err = 'Perlu dicek: nominal belum benar');
                return;
              }
              Navigator.pop(
                  context,
                  _Setoran(_ket.text.trim().isEmpty ? 'Sisihan kas warung' : _ket.text.trim(),
                      n, DateTime.now()));
            },
            child: const Text('Simpan setoran'),
          ),
        ]),
      );
}