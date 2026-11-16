import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class _Produk {
  const _Produk(this.nama, this.emoji, this.harga);
  final String nama, emoji;
  final int harga;
}

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  static const _produk = [
    _Produk('Minyak Goreng 2L', '🧴', 34000),
    _Produk('Beras Ramos 5kg', '🌾', 72000),
    _Produk('Gula Pasir 1kg', '🍬', 17500),
    _Produk('Mie Instan Goreng', '🍜', 3500),
    _Produk('Teh Celup Kotak', '🍵', 7000),
    _Produk('Kopi Sachet Renceng', '☕', 15000),
  ];

  int _tab = 0;
  late final List<int> _qty = List.filled(_produk.length, 0);
  final _nominal = TextEditingController();
  final _ket = TextEditingController();
  final _omzet = TextEditingController();
  String? _kategori, _errNominal, _errOmzet;

  int get _items => _qty.fold(0, (a, b) => a + b);
  int get _total {
    var t = 0;
    for (var i = 0; i < _produk.length; i++) {
      t += _qty[i] * _produk[i].harga;
    }
    return t;
  }

  static const _kategoriList = [
    'Transportasi', 'Listrik & Air', 'Gaji / Upah', 'Kemasan', 'Belanja Stok', 'Lainnya'
  ];

  // Tebakan kategori dari kata kunci (tanpa AI)
  String? _tebak(String teks) {
    final s = teks.toLowerCase();
    const peta = {
      'Transportasi': ['bensin', 'ojek', 'parkir', 'tol', 'antar'],
      'Listrik & Air': ['listrik', 'token', 'pdam', 'air'],
      'Gaji / Upah': ['gaji', 'upah', 'bon'],
      'Kemasan': ['plastik', 'kardus', 'kantong', 'kemasan'],
      'Belanja Stok': ['kulakan', 'stok', 'beli barang'],
    };
    for (final e in peta.entries) {
      if (e.value.any((k) => s.contains(k))) return e.key;
    }
    return null;
  }

  int? _angka(String s) => int.tryParse(s.replaceAll('.', '').trim());

  void _snack(String t, {SnackBarAction? aksi}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(t), action: aksi));
  }

  void _tambah(int i, int d) {
    if (_qty[i] + d < 0) return;
    setState(() => _qty[i] += d);
    if (d > 0) {
      _snack('${_produk[i].nama} +1',
          aksi: SnackBarAction(label: 'Urungkan', onPressed: () => setState(() => _qty[i]--)));
    }
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: ChipTabs(
          labels: const ['Penjualan', 'Pengeluaran', 'Omzet saja'],
          index: _tab,
          onChanged: (v) => setState(() => _tab = v),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Icon(Icons.cloud_done_outlined, size: 16, color: c.masuk),
          const SizedBox(width: 6),
          Text('Tersinkron • siap offline',
              style: TextStyle(color: c.textSecondary, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 8),
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
    return Column(children: [
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 176),
          itemCount: _produk.length,
          itemBuilder: (_, i) {
            final p = _produk[i];
            final aktif = _qty[i] > 0;
            return GlassCard(
              padding: const EdgeInsets.all(12),
              radius: 22,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconTile(
                      warna: c.accent,
                      child: Text(p.emoji, style: const TextStyle(fontSize: 24))),
                  const Spacer(),
                  if (aktif) Pill('${_qty[i]}', warna: c.warning),
                ]),
                const SizedBox(height: 8),
                Text(p.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(rp(p.harga),
                    style: TextStyle(
                        color: c.isDark ? c.accent : c.warning,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
                const Spacer(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  tombolBulat(context, Icons.remove, aktif ? () => _tambah(i, -1) : null),
                  Text('${_qty[i]}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: aktif ? c.textPrimary : c.textSecondary)),
                  tombolBulat(context, Icons.add, () => _tambah(i, 1), utama: true),
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
                Text('$_items item dipilih',
                    style: TextStyle(color: c.textSecondary, fontSize: 12)),
                Text(rp(_total),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ]),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _items == 0
                  ? null
                  : () {
                      _snack('Penjualan $_items barang (${rp(_total)}) tersimpan');
                      setState(() => _qty.fillRange(0, _qty.length, 0));
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
    final tebakan = _tebak(_ket.text);
    final terpilih = _kategori ?? tebakan;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
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
                _snack('Pengeluaran ${rp(n)} (${terpilih ?? 'Belum dikategori'}) tersimpan');
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
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