import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../data/models.dart';
import '../produk/produk_page.dart';
import '../scan/scan_page.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  int _tab = 0;
  final Map<String, int> _qty = {};
  final _nominal = TextEditingController();
  final _ket = TextEditingController();
  final _omzet = TextEditingController();
  String? _kategori, _errNominal, _errOmzet;

  static const _kategoriList = [
    'Transportasi', 'Listrik & Air', 'Gaji / Upah', 'Kemasan', 'Belanja Stok', 'Lainnya'
  ];

  int? _angka(String s) => int.tryParse(s.replaceAll('.', '').trim());

  void _snack(String t, {SnackBarAction? aksi}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(t), action: aksi));
  }

  void _ubahQty(AppStore s, Produk p, int d) {
    final now = _qty[p.id] ?? 0;
    if (d > 0 && now >= p.stok) {
      _snack('Stok ${p.nama} tinggal ${p.stok} ${p.satuan}. Koreksi di Produk saya jika tidak sesuai.');
      return;
    }
    if (now + d < 0) return;
    setState(() => _qty[p.id] = now + d);
  }

  @override
  void dispose() {
    _nominal.dispose();
    _ket.dispose();
    _omzet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: ChipTabs(
          labels: const ['Penjualan', 'Pengeluaran', 'Omzet saja'],
          index: _tab,
          onChanged: (v) => setState(() => _tab = v),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ScanPage())),
              icon: Icon(Icons.document_scanner_outlined, size: 18, color: c.warning),
              label: const Text('Scan struk / catatan'),
            ),
          ),
        ]),
      ),
      Expanded(
        child: switch (_tab) {
          0 => _penjualan(context),
          1 => _pengeluaran(context),
          _ => _omzetSaja(context),
        },
      ),
    ]);
  }

  Widget _penjualan(BuildContext context) {
    final c = context.dg;
    final s = context.watch<AppStore>();
    final list = s.produk.where((p) => p.aktif).toList();
    var items = 0, total = 0;
    for (final p in list) {
      final q = _qty[p.id] ?? 0;
      items += q;
      total += q * p.hargaJual;
    }
    return Column(children: [
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 184),
          itemCount: list.length + 1,
          itemBuilder: (_, i) {
            if (i == list.length) {
              return GestureDetector(
                onTap: () => showProdukSheet(context),
                child: GlassCard(
                  radius: 22,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_circle_outline, size: 36, color: c.warning),
                    const SizedBox(height: 8),
                    const Text('Tambah produk',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                ),
              );
            }
            final p = list[i];
            final q = _qty[p.id] ?? 0;
            return GlassCard(
              padding: const EdgeInsets.all(12),
              radius: 22,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconTile(
                      warna: c.accent,
                      child: Text(p.emoji, style: const TextStyle(fontSize: 24))),
                  const Spacer(),
                  if (q > 0) Pill('$q', warna: c.warning),
                ]),
                const SizedBox(height: 8),
                Text(p.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(rp(p.hargaJual),
                    style: TextStyle(
                        color: c.isDark ? c.accent : c.warning,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
                Text('Stok ${p.stok} ${p.satuan}',
                    style: TextStyle(color: c.textSecondary, fontSize: 11)),
                const Spacer(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  tombolBulat(context, Icons.remove, q > 0 ? () => _ubahQty(s, p, -1) : null),
                  Text('$q',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: q > 0 ? c.textPrimary : c.textSecondary)),
                  tombolBulat(context, Icons.add, () => _ubahQty(s, p, 1), utama: true),
                ]),
              ]),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        child: GlassCard(
          blur: true,
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$items item dipilih',
                    style: TextStyle(color: c.textSecondary, fontSize: 12)),
                Text(rp(total),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ]),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: items == 0
                  ? null
                  : () {
                      final t = s.catatPenjualan(Map.of(_qty));
                      _snack('Penjualan ${rp(t)} tersimpan. Stok dan saldo diperbarui.');
                      setState(_qty.clear);
                    },
              child: const Text('Simpan penjualan'),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _pengeluaran(BuildContext context) {
    final c = context.dg;
    final s = context.read<AppStore>();
    final tebakan = AppStore.tebakKategori(_ket.text);
    final terpilih = _kategori ?? tebakan;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Catat uang keluar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(
              controller: _nominal,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              decoration: dekorasi(context, 'Nominal', prefix: 'Rp ', error: _errNominal),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              for (final n in [10000, 25000, 50000, 100000])
                ActionChip(
                    label: Text(rp(n)),
                    onPressed: () => setState(() {
                          _nominal.text = '$n';
                          _errNominal = null;
                        })),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _ket,
              onChanged: (_) => setState(() => _kategori = null),
              decoration: dekorasi(context, 'Keterangan', hint: 'Contoh: beli bensin antar pesanan'),
            ),
            const SizedBox(height: 12),
            if (tebakan != null && _kategori == null)
              Row(children: [
                Icon(Icons.auto_awesome, size: 16, color: c.warning),
                const SizedBox(width: 6),
                Expanded(
                    child: Text('Ditebak: $tebakan. Sudah pas?',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                TextButton(
                    onPressed: () => setState(() => _kategori = tebakan),
                    child: const Text('Ya')),
              ]),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final k in _kategoriList)
                ChoiceChip(
                    label: Text(k),
                    selected: terpilih == k,
                    onSelected: (_) => setState(() => _kategori = k)),
            ]),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final n = _angka(_nominal.text);
                if (n == null || n <= 0) {
                  setState(() => _errNominal = 'Perlu dicek: nominal belum benar');
                  return;
                }
                final kat = terpilih ?? 'Lainnya';
                s.catatPengeluaran(n, kat, _ket.text.trim());
                _snack('Pengeluaran ${rp(n)} ($kat) tersimpan');
                setState(() {
                  _nominal.clear();
                  _ket.clear();
                  _kategori = null;
                  _errNominal = null;
                });
              },
              child: const Text('Simpan pengeluaran'),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _omzetSaja(BuildContext context) {
    final c = context.dg;
    final s = context.read<AppStore>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Totalan akhir hari',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Cocok kalau sedang sibuk dan hanya mencatat omzet harian. Stok tidak berubah.',
                style: TextStyle(color: c.textSecondary, height: 1.4)),
            const SizedBox(height: 14),
            TextField(
              controller: _omzet,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              decoration: dekorasi(context, 'Omzet hari ini', prefix: 'Rp ', error: _errOmzet),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final n = _angka(_omzet.text);
                if (n == null || n <= 0) {
                  setState(() => _errOmzet = 'Perlu dicek: nominal belum benar');
                  return;
                }
                s.catatOmzet(n);
                _snack('Omzet ${rp(n)} tersimpan sebagai uang masuk');
                setState(() {
                  _omzet.clear();
                  _errOmzet = null;
                });
              },
              child: const Text('Simpan uang masuk'),
            ),
          ]),
        ),
      ],
    );
  }
}