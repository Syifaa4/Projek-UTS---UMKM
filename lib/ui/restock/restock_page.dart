import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_store.dart';
import '../../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/state_view.dart';

class RestockPage extends StatefulWidget {
  const RestockPage({super.key});

  @override
  State<RestockPage> createState() => _RestockPageState();
}

class _RestockPageState extends State<RestockPage> {
  static const _status = ['menunggu', 'disetujui', 'ditolak'];
  int _tab = 0;

  void _snack(String t) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _bukaWa(AppStore s, Rekom r) async {
    final p = s.cari(r.produkId)!;
    final sp = s.supplierOf(p);
    if (sp == null || sp.wa.isEmpty) {
      _snack('Nomor WhatsApp supplier belum diisi (menu Supplier)');
      return;
    }
    final url = Uri.parse('https://wa.me/${sp.wa}?text=${Uri.encodeComponent(s.pesanWa(r))}');
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _snack('WhatsApp tidak bisa dibuka di perangkat ini');
  }

  Future<void> _setujui(AppStore s, Rekom r) async {
    final p = s.cari(r.produkId)!;
    final kirim = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WaSheet(
        supplier: s.supplierOf(p)?.nama ?? '-',
        pesan: s.pesanWa(r),
        total: r.total,
        kasSisa: s.kasTersedia - r.total,
      ),
    );
    if (kirim != true || !mounted) return;
    s.setujui(r);
    await _bukaWa(s, r);
  }

  Future<void> _ubah(AppStore s, Rekom r) async {
    final p = s.cari(r.produkId)!;
    final hasil = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UbahSheet(rekom: r, produk: p),
    );
    if (hasil != null && mounted) s.ubahQty(r, hasil);
  }

  Future<void> _tolak(AppStore s, Rekom r) async {
    final alasan = await showDialog<String>(
        context: context, builder: (_) => const _TolakDialog());
    if (alasan != null && mounted) s.tolak(r, alasan);
  }

  Future<void> _terima(AppStore s, Rekom r) async {
    final p = s.cari(r.produkId)!;
    final hasil = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TerimaSheet(rekom: r, produk: p),
    );
    if (hasil != null && mounted) {
      s.tandaiDiterima(r, hasil[0], hasil[1]);
      _snack('Stok ${p.nama} bertambah ${hasil[0]} ${p.satuan}');
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
        pesan: 'Keputusan restok hanya bisa dilakukan pemilik. Ubah peran di Beranda.',
      );
    }
    final counts = [for (final x in _status) s.rekom.where((e) => e.status == x).length];
    final daftar = s.rekom.where((e) => e.status == _status[_tab]).toList();
    final kas = s.kasTersedia;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        const Text('Persetujuan restok',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text('Aplikasi menyiapkan, pemilik memutuskan.',
            style: TextStyle(color: c.textSecondary, fontSize: 13)),
        const SizedBox(height: 14),
        GlassCard(
          blur: true,
          child: Row(children: [
            IconTile(
                warna: c.accent,
                child: Icon(Icons.account_balance_wallet_outlined, color: c.warning)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('KAS BELANJA TERSEDIA',
                    style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(rp(kas),
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: c.isDark ? c.accent : c.brand)),
              ]),
            ),
            Flexible(
              child: Pill(s.rencanaKeluar == 0 ? 'Aman' : 'Terencana ${rpSingkat(s.rencanaKeluar)}',
                  warna: kas > 0 ? c.masuk : c.keluar, ikon: Icons.verified_user_outlined),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        ChipTabs(
          labels: const ['Menunggu', 'Disetujui', 'Ditolak'],
          counts: counts,
          index: _tab,
          onChanged: (v) => setState(() => _tab = v),
        ),
        const SizedBox(height: 14),
        if (daftar.isEmpty)
          StateView(
            gambar: _tab == 0 ? 'assets/images/growth.png' : 'assets/images/not-found.png',
            judul: _tab == 0 ? 'Semua stok aman' : 'Belum ada data',
            pesan: _tab == 0
                ? 'Tidak ada yang perlu dipesan. Robot akan menghitung ulang otomatis saat ada penjualan.'
                : 'Daftar ini masih kosong.',
            tombol: _tab == 0 ? 'Jalankan robot' : null,
            aksi: _tab == 0
                ? () {
                    final n = s.jalankanRobot();
                    _snack('Robot selesai: $n rekomendasi baru');
                  }
                : null,
          )
        else
          for (final r in daftar)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Muncul(
                child: switch (_tab) {
                  0 => _kartu(context, s, r),
                  1 => _disetujui(context, s, r),
                  _ => _ditolak(context, s, r),
                },
              ),
            ),
      ],
    );
  }

  Widget _kartu(BuildContext context, AppStore s, Rekom r) {
    final c = context.dg;
    final p = s.cari(r.produkId)!;
    final kas = s.kasTersedia;
    final kasPos = kas < 0 ? 0 : kas;
    final kurang = r.total > kas;
    final k = p.kelipatan < 1 ? 1 : p.kelipatan;
    final maxQty = r.harga <= 0 ? r.qty : ((kasPos ~/ r.harga) ~/ k) * k;
    final tahap1 = (((r.qty / 2).ceil() + k - 1) ~/ k) * k;
    final bisaTahap = tahap1 > 0 && tahap1 < r.qty && tahap1 * r.harga <= kasPos;
    final sec = TextStyle(color: c.textSecondary, fontSize: 12);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconTile(
              ukuran: 58,
              warna: c.accent,
              child: Text(p.emoji, style: const TextStyle(fontSize: 28))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Pill('Sisa ${p.stok} ${p.satuan} (~${r.sisaHari.ceil()} hari)',
                  warna: r.sisaHari <= 3 ? c.keluar : c.warning),
              const SizedBox(height: 6),
              Text(p.nama, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.local_shipping_outlined, size: 14, color: c.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(s.supplierOf(p)?.nama ?? '-',
                        style: sec, overflow: TextOverflow.ellipsis)),
              ]),
              if (r.spike) ...[
                const SizedBox(height: 6),
                Pill('Penjualan hari ini melonjak', warna: c.info, ikon: Icons.trending_up),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            Row(children: [
              Icon(Icons.calculate_outlined, size: 18, color: c.info),
              const SizedBox(width: 6),
              Text('Usulan jumlah', style: sec),
              const Spacer(),
              Text('${r.qty} ${p.satuan}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: c.info)),
            ]),
            const Divider(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Estimasi biaya', style: sec),
                Text(rp(r.total),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ]),
              const Spacer(),
              Flexible(
                child: Pill(kurang ? 'Kas kurang ${rp(r.total - kas)}' : 'Kas cukup',
                    warna: kurang ? c.keluar : c.masuk,
                    ikon: kurang ? Icons.warning_amber_rounded : Icons.check_circle_outline),
              ),
            ]),
          ]),
        ),
        if (kurang) ...[
          const SizedBox(height: 12),
          Text('PILIHAN SESUAI KAS',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: c.warning)),
          const SizedBox(height: 8),
          if (maxQty > 0)
            _opsi(context, '1', 'Pesan $maxQty ${p.satuan} saja (${rp(maxQty * r.harga)})',
                'Sesuai kas yang ada', () => s.ubahQty(r, maxQty)),
          if (bisaTahap) ...[
            const SizedBox(height: 8),
            _opsi(context, '2',
                'Pesan 2 tahap ($tahap1 sekarang, ${r.qty - tahap1} nanti)',
                'Arus kas lebih ringan', () {
              final sisa = r.qty - tahap1;
              s.ubahQty(r, tahap1);
              _snack('Tahap 2 ($sisa ${p.satuan}) ingat dipesan lagi nanti');
            }),
          ],
          if (maxQty <= 0 && !bisaTahap)
            Text('Kas belum cukup untuk memesan barang ini. Kurangi dana tabungan atau tunggu penjualan.',
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
        ],
        const SizedBox(height: 14),
        Row(children: [
          if (!kurang) ...[
            Expanded(
              flex: 5,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48), padding: EdgeInsets.zero),
                onPressed: () => _setujui(s, r),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Setujui'),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 4,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () => _ubah(s, r),
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Ubah'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: EdgeInsets.zero,
                  foregroundColor: c.keluar,
                  side: BorderSide(color: c.keluar.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () => _tolak(s, r),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Tolak'),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _disetujui(BuildContext context, AppStore s, Rekom r) {
    final c = context.dg;
    final p = s.cari(r.produkId)!;
    const langkah = ['Siap kirim', 'Terkirim', 'Diterima'];
    final idx = langkah.indexOf(r.order);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconTile(warna: c.accent, child: Text(p.emoji, style: const TextStyle(fontSize: 22))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('${r.qty} ${p.satuan} • ${rp(r.total)} • ${s.supplierOf(p)?.nama ?? '-'}',
                  style: TextStyle(color: c.textSecondary, fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          for (var i = 0; i < 3; i++) ...[
            Expanded(
              child: Column(children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: i <= idx ? c.accent : c.chip,
                  child: Icon(i < idx ? Icons.check : Icons.circle,
                      size: i < idx ? 16 : 8, color: i <= idx ? c.onAccent : c.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(langkah[i],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == idx ? FontWeight.w800 : FontWeight.w500,
                        color: i <= idx ? c.textPrimary : c.textSecondary)),
              ]),
            ),
          ],
        ]),
        const SizedBox(height: 14),
        if (r.order == 'Siap kirim')
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () => _bukaWa(s, r),
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('Buka WhatsApp'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                onPressed: () => s.tandaiTerkirim(r),
                child: const Text('Tandai terkirim'),
              ),
            ),
          ])
        else if (r.order == 'Terkirim')
          FilledButton.icon(
            onPressed: () => _terima(s, r),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Barang sudah diterima'),
          )
        else
          Row(children: [
            Icon(Icons.task_alt, color: c.masuk),
            const SizedBox(width: 8),
            Text('Selesai. Stok sudah bertambah.',
                style: TextStyle(color: c.masuk, fontWeight: FontWeight.w700)),
          ]),
      ]),
    );
  }

  Widget _ditolak(BuildContext context, AppStore s, Rekom r) {
    final c = context.dg;
    final p = s.cari(r.produkId)!;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Row(children: [
        IconTile(warna: c.accent, child: Text(p.emoji, style: const TextStyle(fontSize: 22))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('Alasan: ${r.alasan ?? '-'}',
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
          ]),
        ),
        TextButton(onPressed: () => s.pulihkan(r), child: const Text('Pulihkan')),
      ]),
    );
  }

  Widget _opsi(BuildContext context, String no, String judul, String sub, VoidCallback aksi) {
    final c = context.dg;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: aksi,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border.all(color: c.cardBorder), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          CircleAvatar(
              radius: 13,
              backgroundColor: c.accent.withValues(alpha: 0.25),
              child: Text(no,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(judul, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(sub, style: TextStyle(color: c.masuk, fontSize: 11)),
            ]),
          ),
          Icon(Icons.chevron_right, color: c.textSecondary),
        ]),
      ),
    );
  }
}

class _WaSheet extends StatelessWidget {
  const _WaSheet(
      {required this.supplier, required this.pesan, required this.total, required this.kasSisa});
  final String supplier, pesan;
  final int total, kasSisa;

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    return SheetBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pesan siap dikirim',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('WhatsApp akan terbuka dengan pesan sudah terisi. Anda yang menekan kirim.',
            style: TextStyle(color: c.textSecondary, fontSize: 13)),
        const SizedBox(height: 14),
        Row(children: [
          Icon(Icons.storefront_outlined, color: c.info, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(supplier, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(16)),
          child: Text(pesan, style: const TextStyle(height: 1.45, fontSize: 13)),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total ${rp(total)}', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('Sisa kas ${rp(kasSisa)}',
              style: TextStyle(color: c.masuk, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25A862), foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.send),
          label: const Text('Kirim lewat WhatsApp'),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        ),
      ]),
    );
  }
}

class _UbahSheet extends StatefulWidget {
  const _UbahSheet({required this.rekom, required this.produk});
  final Rekom rekom;
  final Produk produk;

  @override
  State<_UbahSheet> createState() => _UbahSheetState();
}

class _UbahSheetState extends State<_UbahSheet> {
  late int _qty = widget.rekom.qty;

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    final s = context.read<AppStore>();
    final k = widget.produk.kelipatan < 1 ? 1 : widget.produk.kelipatan;
    final total = _qty * widget.rekom.harga;
    final kurang = total > s.kasTersedia;
    return SheetBox(
      child: Column(children: [
        Text('Ubah jumlah ${widget.produk.nama}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        if (k > 1)
          Text('Kelipatan pesan $k ${widget.produk.satuan}',
              style: TextStyle(color: c.textSecondary, fontSize: 12)),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          tombolBulat(context, Icons.remove, _qty > k ? () => setState(() => _qty -= k) : null),
          SizedBox(
            width: 120,
            child: Column(children: [
              Text('$_qty', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
              Text(widget.produk.satuan, style: TextStyle(color: c.textSecondary)),
            ]),
          ),
          tombolBulat(context, Icons.add, () => setState(() => _qty += k), utama: true),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(
                child: Text('Biaya ${rp(total)}',
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            Pill(kurang ? 'Kas kurang' : 'Kas cukup', warna: kurang ? c.keluar : c.masuk),
          ]),
        ),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: () => Navigator.pop(context, _qty), child: const Text('Simpan jumlah')),
      ]),
    );
  }
}

class _TerimaSheet extends StatefulWidget {
  const _TerimaSheet({required this.rekom, required this.produk});
  final Rekom rekom;
  final Produk produk;

  @override
  State<_TerimaSheet> createState() => _TerimaSheetState();
}

class _TerimaSheetState extends State<_TerimaSheet> {
  late final _qty = TextEditingController(text: '${widget.rekom.qty}');
  late final _harga = TextEditingController(text: '${widget.rekom.harga}');
  String? _err;

  @override
  void dispose() {
    _qty.dispose();
    _harga.dispose();
    super.dispose();
  }

  int _n(String s) => int.tryParse(s.replaceAll('.', '').trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return SheetBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Barang diterima: ${widget.produk.nama}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        TextField(
          controller: _qty,
          keyboardType: TextInputType.number,
          decoration: dekorasi(context, 'Jumlah diterima (${widget.produk.satuan})'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _harga,
          keyboardType: TextInputType.number,
          decoration: dekorasi(context, 'Harga aktual per ${widget.produk.satuan}',
              prefix: 'Rp ', error: _err),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            final q = _n(_qty.text), h = _n(_harga.text);
            if (q <= 0 || h <= 0) {
              setState(() => _err = 'Perlu dicek: jumlah atau harga belum benar');
              return;
            }
            Navigator.pop(context, [q, h]);
          },
          child: const Text('Simpan penerimaan'),
        ),
      ]),
    );
  }
}

class _TolakDialog extends StatefulWidget {
  const _TolakDialog();

  @override
  State<_TolakDialog> createState() => _TolakDialogState();
}

class _TolakDialogState extends State<_TolakDialog> {
  String _pilih = 'Masih banyak stok';
  static const _alasan = ['Masih banyak stok', 'Kas kurang', 'Harga naik', 'Lainnya'];

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Tolak rekomendasi?'),
        content: Wrap(spacing: 8, runSpacing: 4, children: [
          for (final a in _alasan)
            ChoiceChip(
                label: Text(a),
                selected: _pilih == a,
                onSelected: (_) => setState(() => _pilih = a)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, _pilih), child: const Text('Tolak')),
        ],
      );
}