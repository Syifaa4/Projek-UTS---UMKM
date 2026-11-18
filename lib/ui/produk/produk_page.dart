import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/state_view.dart';

int _n(String s) => int.tryParse(s.replaceAll('.', '').trim()) ?? 0;

Future<void> showProdukSheet(BuildContext context, {Produk? edit, String? namaAwal}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProdukForm(edit: edit, namaAwal: namaAwal),
  );
}

class ProdukPage extends StatelessWidget {
  const ProdukPage({super.key});

  Future<void> _koreksi(BuildContext context, AppStore s, Produk p) async {
    final ctrl = TextEditingController(text: '${p.stok}');
    final hasil = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Koreksi stok ${p.nama}'),
        content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: dekorasi(context, 'Stok sebenarnya (${p.satuan})')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, _n(ctrl.text)),
              child: const Text('Simpan')),
        ],
      ),
    );
    ctrl.dispose();
    if (hasil != null) s.koreksiStok(p, hasil);
  }

  Future<void> _hapus(BuildContext context, AppStore s, Produk p) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('${p.nama} akan dihapus. Jika sudah punya riwayat penjualan, produk hanya diarsipkan agar laporan tidak rusak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ya != true || !context.mounted) return;
    final terhapus = s.hapusProduk(p);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content: Text(terhapus ? 'Produk dihapus' : 'Produk diarsipkan (punya riwayat)')));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final c = context.dg;
    final aktif = s.produk.where((p) => p.aktif).toList();
    final arsip = s.produk.where((p) => !p.aktif).toList();

    Widget tile(Produk p) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            radius: 20,
            child: Row(children: [
              IconTile(
                  warna: c.accent,
                  child: Text(p.emoji, style: const TextStyle(fontSize: 22))),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => showProdukSheet(context, edit: p),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.nama,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: p.aktif ? c.textPrimary : c.textSecondary)),
                    Text('Stok ${p.stok} ${p.satuan} • Jual ${rp(p.hargaJual)} • Beli ${rp(p.hargaBeli)}',
                        style: TextStyle(color: c.textSecondary, fontSize: 12)),
                  ]),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      showProdukSheet(context, edit: p);
                    case 'stok':
                      _koreksi(context, s, p);
                    case 'arsip':
                      p.aktif = !p.aktif;
                      s.simpan();
                    case 'hapus':
                      _hapus(context, s, p);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  const PopupMenuItem(value: 'stok', child: Text('Koreksi stok fisik')),
                  PopupMenuItem(value: 'arsip', child: Text(p.aktif ? 'Arsipkan' : 'Aktifkan lagi')),
                  const PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                ],
              ),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk saya'),
        actions: [
          IconButton(
            tooltip: 'Supplier',
            icon: const Icon(Icons.local_shipping_outlined),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SupplierPage())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        onPressed: () => showProdukSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah produk'),
      ),
      body: s.produk.isEmpty
          ? const StateView(
              gambar: 'assets/images/not-found.png',
              judul: 'Belum ada produk',
              pesan: 'Tekan Tambah produk untuk mulai. Cocok untuk makanan, fashion, buah, atau apa pun.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              children: [
                for (final p in aktif) tile(p),
                if (arsip.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('DIARSIPKAN',
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: c.textSecondary)),
                  const SizedBox(height: 8),
                  for (final p in arsip) tile(p),
                ],
              ],
            ),
    );
  }
}

class _ProdukForm extends StatefulWidget {
  const _ProdukForm({this.edit, this.namaAwal});
  final Produk? edit;
  final String? namaAwal;

  @override
  State<_ProdukForm> createState() => _ProdukFormState();
}

class _ProdukFormState extends State<_ProdukForm> {
  late final _nama = TextEditingController(text: widget.edit?.nama ?? widget.namaAwal ?? '');
  late final _jual = TextEditingController(text: widget.edit == null ? '' : '${widget.edit!.hargaJual}');
  late final _beli = TextEditingController(text: widget.edit == null ? '' : '${widget.edit!.hargaBeli}');
  late final _stok = TextEditingController(text: '${widget.edit?.stok ?? 0}');
  late final _satuan = TextEditingController(text: widget.edit?.satuan ?? 'pcs');
  late final _lead = TextEditingController(text: '${widget.edit?.leadTime ?? 2}');
  late final _cad = TextEditingController(text: '${widget.edit?.hariCadangan ?? 3}');
  late final _kel = TextEditingController(text: '${widget.edit?.kelipatan ?? 1}');
  late String _emoji = widget.edit?.emoji ?? '📦';
  late String _supplierId = widget.edit?.supplierId ?? '';
  String? _err;

  static const _emojis = [
    '📦', '🧴', '🌾', '🍬', '🍜', '🍵', '☕', '🥤', '🍎', '🥬',
    '🍗', '👕', '👗', '👟', '🎒', '💄', '🧼', '🔧', '📱', '🍞'
  ];
  static const _satuanList = ['pcs', 'kg', 'liter', 'bks', 'dus', 'lusin', 'ikat', 'porsi', 'pasang'];

  @override
  void dispose() {
    for (final x in [_nama, _jual, _beli, _stok, _satuan, _lead, _cad, _kel]) {
      x.dispose();
    }
    super.dispose();
  }

  void _simpan() {
    final nama = _nama.text.trim();
    if (nama.isEmpty) {
      setState(() => _err = 'Nama produk belum diisi');
      return;
    }
    if (_n(_jual.text) <= 0) {
      setState(() => _err = 'Harga jual belum benar');
      return;
    }
    final s = context.read<AppStore>();
    final satuan = _satuan.text.trim().isEmpty ? 'pcs' : _satuan.text.trim();
    final kel = _n(_kel.text) < 1 ? 1 : _n(_kel.text);
    if (widget.edit == null) {
      s.tambahProduk(Produk(
        id: s.idBaru('p'), nama: nama, emoji: _emoji, satuan: satuan,
        hargaBeli: _n(_beli.text), hargaJual: _n(_jual.text), stok: _n(_stok.text),
        supplierId: _supplierId, leadTime: _n(_lead.text), hariCadangan: _n(_cad.text),
        kelipatan: kel,
      ));
    } else {
      final p = widget.edit!;
      p.nama = nama;
      p.emoji = _emoji;
      p.satuan = satuan;
      p.hargaBeli = _n(_beli.text);
      p.hargaJual = _n(_jual.text);
      p.stok = _n(_stok.text);
      p.supplierId = _supplierId;
      p.leadTime = _n(_lead.text);
      p.hariCadangan = _n(_cad.text);
      p.kelipatan = kel;
      s.simpan();
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    final s = context.watch<AppStore>();
    return SheetBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.edit == null ? 'Tambah produk' : 'Ubah produk',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        TextField(controller: _nama, decoration: dekorasi(context, 'Nama produk', hint: 'Contoh: Kaos Polos M Hitam')),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final e in _emojis)
            InkWell(
              onTap: () => setState(() => _emoji = e),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: e == _emoji ? c.accent.withValues(alpha: 0.3) : Colors.transparent,
                    border: Border.all(color: e == _emoji ? c.accent : c.cardBorder),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _beli,
                  keyboardType: TextInputType.number,
                  decoration: dekorasi(context, 'Harga beli', prefix: 'Rp '))),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
                  controller: _jual,
                  keyboardType: TextInputType.number,
                  decoration: dekorasi(context, 'Harga jual', prefix: 'Rp '))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _stok,
                  keyboardType: TextInputType.number,
                  decoration: dekorasi(context, 'Stok sekarang'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _satuan, decoration: dekorasi(context, 'Satuan'))),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          for (final u in _satuanList)
            ActionChip(label: Text(u), onPressed: () => setState(() => _satuan.text = u)),
        ]),
        const SizedBox(height: 12),
        Text('Supplier', style: TextStyle(color: c.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          ChoiceChip(
              label: const Text('Tanpa supplier'),
              selected: _supplierId.isEmpty,
              onSelected: (_) => setState(() => _supplierId = '')),
          for (final sp in s.supplier)
            ChoiceChip(
                label: Text(sp.nama),
                selected: _supplierId == sp.id,
                onSelected: (_) => setState(() => _supplierId = sp.id)),
        ]),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Pengaturan restok (opsional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          children: [
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _lead,
                      keyboardType: TextInputType.number,
                      decoration: dekorasi(context, 'Lama kirim (hari)'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _cad,
                      keyboardType: TextInputType.number,
                      decoration: dekorasi(context, 'Hari cadangan'))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _kel,
                      keyboardType: TextInputType.number,
                      decoration: dekorasi(context, 'Kelipatan'))),
            ]),
            const SizedBox(height: 8),
          ],
        ),
        if (_err != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_err!, style: TextStyle(color: c.keluar))),
        FilledButton(onPressed: _simpan, child: const Text('Simpan produk')),
      ]),
    );
  }
}

// ======================= SUPPLIER =======================

class SupplierPage extends StatelessWidget {
  const SupplierPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final c = context.dg;
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        onPressed: () => _form(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah supplier'),
      ),
      body: s.supplier.isEmpty
          ? const StateView(
              gambar: 'assets/images/not-found.png',
              judul: 'Belum ada supplier',
              pesan: 'Tambahkan supplier supaya pesan WhatsApp bisa langsung dikirim.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              children: [
                for (final sp in s.supplier)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      radius: 20,
                      child: Row(children: [
                        IconTile(
                            warna: c.info,
                            child: Icon(Icons.local_shipping_outlined, color: c.info)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _form(context, edit: sp),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(sp.nama, style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              sp.wa.isEmpty
                                  ? Pill('Kontak kosong, lengkapi', warna: c.warning)
                                  : Text('WhatsApp ${sp.wa}',
                                      style: TextStyle(color: c.textSecondary, fontSize: 12)),
                            ]),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: c.keluar),
                          onPressed: () => s.hapusSupplier(sp),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }

  void _form(BuildContext context, {Supplier? edit}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupplierForm(edit: edit),
    );
  }
}

class _SupplierForm extends StatefulWidget {
  const _SupplierForm({this.edit});
  final Supplier? edit;

  @override
  State<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<_SupplierForm> {
  late final _nama = TextEditingController(text: widget.edit?.nama ?? '');
  late final _wa = TextEditingController(text: widget.edit?.wa ?? '');
  String? _err;

  @override
  void dispose() {
    _nama.dispose();
    _wa.dispose();
    super.dispose();
  }

  String _normal(String x) {
    var d = x.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('0')) d = '62${d.substring(1)}';
    return d;
  }

  @override
  Widget build(BuildContext context) {
    return SheetBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.edit == null ? 'Tambah supplier' : 'Ubah supplier',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        TextField(controller: _nama, decoration: dekorasi(context, 'Nama supplier')),
        const SizedBox(height: 10),
        TextField(
          controller: _wa,
          keyboardType: TextInputType.phone,
          decoration: dekorasi(context, 'Nomor WhatsApp',
              hint: '0812... (otomatis jadi 62812...)', error: _err),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            if (_nama.text.trim().isEmpty) {
              setState(() => _err = 'Nama belum diisi');
              return;
            }
            final s = context.read<AppStore>();
            final wa = _normal(_wa.text);
            if (widget.edit == null) {
              s.tambahSupplier(Supplier(id: s.idBaru('s'), nama: _nama.text.trim(), wa: wa));
            } else {
              widget.edit!.nama = _nama.text.trim();
              widget.edit!.wa = wa;
              s.simpan();
            }
            Navigator.pop(context);
          },
          child: const Text('Simpan supplier'),
        ),
      ]),
    );
  }
}