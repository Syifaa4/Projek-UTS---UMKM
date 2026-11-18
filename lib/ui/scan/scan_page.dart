import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../data/scan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

enum _Fase { pilih, baca, periksa }

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ScanService _service = DemoScanService();
  _Fase _fase = _Fase.pilih;
  bool _penjualan = true;
  List<BarisScan> _baris = [];

  Future<void> _mulai(bool jual, {bool manual = false}) async {
    setState(() {
      _penjualan = jual;
      _fase = manual ? _Fase.periksa : _Fase.baca;
      if (manual) _baris = [];
    });
    if (manual) return;
    final hasil = await _service.baca(penjualan: jual);
    if (!mounted) return;
    final s = context.read<AppStore>();
    for (final b in hasil) {
      b.produkId = s.cocokkan(b.nama)?.id;
    }
    setState(() {
      _baris = hasil;
      _fase = _Fase.periksa;
    });
  }

  Future<void> _edit(BarisScan? b) async {
    final baru = b ?? BarisScan(nama: '', qty: 1, harga: 0);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BarisSheet(baris: baru),
    );
    if (ok == true && mounted) {
      setState(() {
        if (b == null) _baris.add(baru);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan struk / catatan')),
      body: switch (_fase) {
        _Fase.pilih => _pilih(context),
        _Fase.baca => _baca(context),
        _Fase.periksa => _periksa(context),
      },
    );
  }

  Widget _pilih(BuildContext context) {
    final c = context.dg;
    Widget kartu(IconData ikon, String judul, String sub, VoidCallback aksi) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: aksi,
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                IconTile(warna: c.accent, ukuran: 52, child: Icon(ikon, color: c.warning)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(judul, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(sub, style: TextStyle(color: c.textSecondary, fontSize: 12)),
                  ]),
                ),
                Icon(Icons.chevron_right, color: c.textSecondary),
              ]),
            ),
          ),
        );
    return ListView(padding: const EdgeInsets.all(16), children: [
      Center(
        child: Image.asset('assets/images/mascot-main.png',
            height: 150,
            errorBuilder: (_, _, _) => Icon(Icons.smart_toy_outlined, size: 90, color: c.accent)),
      ),
      const SizedBox(height: 8),
      const Text('Foto, lalu periksa',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('Hasil bacaan tidak pernah langsung tersimpan. Anda periksa dulu.',
          textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary)),
      const SizedBox(height: 20),
      kartu(Icons.menu_book_outlined, 'Catatan penjualan',
          'Buku tulis atau nota penjualan', () => _mulai(true)),
      kartu(Icons.receipt_long_outlined, 'Struk belanja supplier',
          'Stok bertambah, uang keluar tercatat', () => _mulai(false)),
      TextButton(
          onPressed: () => _mulai(true, manual: true),
          child: const Text('Tidak mau scan, isi manual')),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: c.warning.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 18, color: c.warning),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
                'MODE DEMO: yang tampil adalah contoh hasil baca, bukan membaca foto Anda. Pembacaan foto sungguhan memakai AI dan menyusul.',
                style: TextStyle(fontSize: 12, height: 1.4)),
          ),
        ]),
      ),
    ]);
  }

  Widget _baca(BuildContext context) {
    final c = context.dg;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text('Membaca isi nota...', style: TextStyle(fontWeight: FontWeight.w700)),
        Text('Mohon tunggu sebentar', style: TextStyle(color: c.textSecondary)),
      ]),
    );
  }

  Widget _periksa(BuildContext context) {
    final c = context.dg;
    final s = context.watch<AppStore>();
    final total = _baris.fold<int>(0, (a, b) => a + b.qty * b.harga);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          Expanded(
            child: Text(
                _penjualan ? 'Periksa penjualan' : 'Periksa belanja supplier',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          TextButton.icon(
              onPressed: () => _edit(null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah baris')),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Ketuk baris untuk mengubah. Baris kuning perlu dicek.',
              style: TextStyle(color: c.textSecondary, fontSize: 12)),
        ),
      ),
      Expanded(
        child: _baris.isEmpty
            ? Center(
                child: Text('Belum ada baris. Tekan Tambah baris.',
                    style: TextStyle(color: c.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                itemCount: _baris.length,
                itemBuilder: (_, i) {
                  final b = _baris[i];
                  final p = b.produkId == null ? null : s.cari(b.produkId!);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _edit(b),
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        radius: 18,
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(b.nama.isEmpty ? '(belum diisi)' : b.nama,
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Wrap(spacing: 6, children: [
                                Pill(p == null ? 'Produk baru' : 'Cocok: ${p.nama}',
                                    warna: p == null ? c.info : c.masuk),
                                if (b.ragu) Pill('Perlu dicek', warna: c.warning),
                              ]),
                              const SizedBox(height: 4),
                              Text('${b.qty} × ${rp(b.harga)} = ${rp(b.qty * b.harga)}',
                                  style: TextStyle(color: c.textSecondary, fontSize: 12)),
                            ]),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: c.keluar),
                            onPressed: () => setState(() => _baris.removeAt(i)),
                          ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: GlassCard(
          blur: true,
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_baris.length} baris', style: TextStyle(color: c.textSecondary, fontSize: 12)),
                Text(rp(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ]),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _baris.isEmpty
                  ? null
                  : () {
                      final m = ScaffoldMessenger.of(context);
                      final hasil = s.simpanScan(_baris, penjualanMode: _penjualan);
                      Navigator.pop(context);
                      m.showSnackBar(SnackBar(content: Text(hasil)));
                    },
              child: Text(_penjualan ? 'Simpan penjualan' : 'Simpan belanja'),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _BarisSheet extends StatefulWidget {
  const _BarisSheet({required this.baris});
  final BarisScan baris;

  @override
  State<_BarisSheet> createState() => _BarisSheetState();
}

class _BarisSheetState extends State<_BarisSheet> {
  late final _nama = TextEditingController(text: widget.baris.nama);
  late final _qty = TextEditingController(text: '${widget.baris.qty}');
  late final _harga = TextEditingController(text: widget.baris.harga == 0 ? '' : '${widget.baris.harga}');
  late String? _produkId = widget.baris.produkId;
  String? _err;

  @override
  void dispose() {
    _nama.dispose();
    _qty.dispose();
    _harga.dispose();
    super.dispose();
  }

  int _n(String s) => int.tryParse(s.replaceAll('.', '').trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final c = context.dg;
    return SheetBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ubah baris', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        TextField(controller: _nama, decoration: dekorasi(context, 'Nama barang')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  decoration: dekorasi(context, 'Jumlah'))),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
                  controller: _harga,
                  keyboardType: TextInputType.number,
                  decoration: dekorasi(context, 'Harga satuan', prefix: 'Rp '))),
        ]),
        const SizedBox(height: 12),
        Text('Cocokkan dengan produk', style: TextStyle(color: c.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 4, children: [
          ChoiceChip(
              label: const Text('Produk baru'),
              selected: _produkId == null,
              onSelected: (_) => setState(() => _produkId = null)),
          for (final p in s.produk.where((e) => e.aktif))
            ChoiceChip(
                label: Text(p.nama),
                selected: _produkId == p.id,
                onSelected: (_) => setState(() => _produkId = p.id)),
        ]),
        if (_err != null)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_err!, style: TextStyle(color: c.keluar))),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            if (_nama.text.trim().isEmpty || _n(_qty.text) <= 0) {
              setState(() => _err = 'Perlu dicek: nama atau jumlah belum benar');
              return;
            }
            widget.baris
              ..nama = _nama.text.trim()
              ..qty = _n(_qty.text)
              ..harga = _n(_harga.text)
              ..produkId = _produkId
              ..ragu = false;
            Navigator.pop(context, true);
          },
          child: const Text('Simpan baris'),
        ),
      ]),
    );
  }
}