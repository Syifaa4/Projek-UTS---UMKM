import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class _Item {
  _Item({
    required this.nama,
    required this.emoji,
    required this.satuan,
    required this.sisaLabel,
    required this.sisaHari,
    required this.hargaBeli,
    required this.qty,
    required this.supplier,
    required this.wa,
    this.spike = '',
    this.status = 'menunggu',
    this.lama = false,
  });
  final String nama, emoji, satuan, sisaLabel, supplier, wa, spike;
  final int sisaHari, hargaBeli;
  final bool lama; // sudah dipesan sebelumnya, tidak dihitung ke kas hari ini
  int qty;
  String status;
  String? alasan;
  int get total => qty * hargaBeli;
}

class RestockPage extends StatefulWidget {
  const RestockPage({super.key});

  @override
  State<RestockPage> createState() => _RestockPageState();
}

class _RestockPageState extends State<RestockPage> {
  static const _kas = 1200000;
  int _tab = 0;

  final _items = <_Item>[
    _Item(
      nama: 'Minyak Goreng 2L', emoji: '🧴', satuan: 'dus',
      sisaLabel: 'Sisa 3 pouch', sisaHari: 4, hargaBeli: 105000, qty: 10,
      supplier: 'Agen Sembako Makmur', wa: '6281200000001',
      spike: 'Penjualan naik 35% pekan ini',
    ),
    _Item(
      nama: 'Beras Pandan Wangi 5kg', emoji: '🌾', satuan: 'karung',
      sisaLabel: 'Sisa 2 karung', sisaHari: 3, hargaBeli: 68000, qty: 8,
      supplier: 'Agen Beras Sumber Rejeki', wa: '6281200000002',
    ),
    _Item(
      nama: 'Gula Pasir 1kg', emoji: '🍬', satuan: 'dus',
      sisaLabel: 'Sisa 6 kg', sisaHari: 5, hargaBeli: 140000, qty: 3,
      supplier: 'Agen Berkah Jaya', wa: '6281200000003',
      status: 'disetujui', lama: true,
    ),
  ];

  static const _status = ['menunggu', 'disetujui', 'ditolak'];

  int get _terpakai => _items
      .where((e) => e.status == 'disetujui' && !e.lama)
      .fold(0, (s, e) => s + e.total);
  int get _kasSisa => _kas - _terpakai;

  void _snack(String t) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _setujui(_Item i) async {
    final pesan =
        'Halo Kak ${i.supplier}, saya mau pesan: ${i.nama} ${i.qty} ${i.satuan}. '
        'Mohon info total dan estimasi pengiriman. Terima kasih.';
    final kirim = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WaSheet(item: i, pesan: pesan, kasSisa: _kasSisa - i.total),
    );
    if (kirim != true || !mounted) return;
    setState(() => i.status = 'disetujui');
    final url = Uri.parse('https://wa.me/${i.wa}?text=${Uri.encodeComponent(pesan)}');
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _snack('WhatsApp tidak bisa dibuka di perangkat ini');
  }

  Future<void> _ubah(_Item i) async {
    final hasil = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UbahSheet(item: i, kasSisa: _kasSisa),
    );
    if (hasil != null && mounted) setState(() => i.qty = hasil);
  }

  Future<void> _tolak(_Item i) async {
    final alasan = await showDialog<String>(
        context: context, builder: (_) => const _TolakDialog());
    if (alasan != null && mounted) {
      setState(() {
        i.status = 'ditolak';
        i.alasan = alasan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    final counts = [for (final s in _status) _items.where((e) => e.status == s).length];
    final daftar = _items.where((e) => e.status == _status[_tab]).toList();

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
                Text(rp(_kasSisa),
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: c.isDark ? c.accent : c.brand)),
              ]),
            ),
            Pill(_terpakai == 0 ? 'Aman' : 'Terpakai ${rpSingkat(_terpakai)}',
                warna: _kasSisa > 0 ? c.masuk : c.keluar, ikon: Icons.verified_user_outlined),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(children: [
              Icon(Icons.inventory_2_outlined, size: 56, color: c.textSecondary),
              const SizedBox(height: 12),
              Text(_tab == 0 ? 'Semua stok aman' : 'Belum ada data',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_tab == 0 ? 'Tidak ada yang perlu dipesan hari ini.' : 'Daftar masih kosong.',
                  style: TextStyle(color: c.textSecondary)),
            ]),
          )
        else
          for (final i in daftar)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Muncul(
                  child: _tab == 0
                      ? _kartu(context, i)
                      : _ringkas(context, i)),
            ),
      ],
    );
  }

  Widget _kartu(BuildContext context, _Item i) {
    final c = context.dg;
    final kurang = i.total > _kasSisa;
    final selisih = i.total - _kasSisa;
    final maxQty = _kasSisa ~/ i.hargaBeli;
    final tahap1 = (i.qty / 2).ceil();
    final sec = TextStyle(color: c.textSecondary, fontSize: 12);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconTile(
              ukuran: 58,
              warna: c.accent,
              child: Text(i.emoji, style: const TextStyle(fontSize: 28))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Pill('${i.sisaLabel} (${i.sisaHari} hari)',
                  warna: i.sisaHari <= 3 ? c.keluar : c.warning),
              const SizedBox(height: 6),
              Text(i.nama,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.local_shipping_outlined, size: 14, color: c.textSecondary),
                const SizedBox(width: 4),
                Expanded(child: Text(i.supplier, style: sec, overflow: TextOverflow.ellipsis)),
              ]),
              if (i.spike.isNotEmpty) ...[
                const SizedBox(height: 6),
                Pill(i.spike, warna: c.info, ikon: Icons.trending_up),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: c.chip, borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            Row(children: [
              Icon(Icons.psychology_outlined, size: 18, color: c.info),
              const SizedBox(width: 6),
              Text('Usulan jumlah', style: sec),
              const Spacer(),
              Text('${i.qty} ${i.satuan}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: c.info)),
            ]),
            const Divider(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Estimasi biaya', style: sec),
                Text(rp(i.total),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ]),
              const Spacer(),
              Pill(kurang ? 'Kas kurang ${rp(selisih)}' : 'Kas cukup',
                  warna: kurang ? c.keluar : c.masuk,
                  ikon: kurang ? Icons.warning_amber_rounded : Icons.check_circle_outline),
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
            _opsi(context, '1', 'Pesan $maxQty ${i.satuan} saja (${rp(maxQty * i.hargaBeli)})',
                'Sesuai kas yang ada', () => setState(() => i.qty = maxQty)),
          if (tahap1 * i.hargaBeli <= _kasSisa && tahap1 > 0) ...[
            const SizedBox(height: 8),
            _opsi(context, '2', 'Pesan 2 tahap ($tahap1 sekarang, ${i.qty - tahap1} nanti)',
                'Arus kas lebih ringan', () {
              setState(() => i.qty = tahap1);
              _snack('Tahap 2 (${i.qty} ${i.satuan}) ingat dipesan lagi nanti');
            }),
          ],
        ],
        const SizedBox(height: 14),
        Row(children: [
          if (!kurang) ...[
            Expanded(
              flex: 5,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48), padding: EdgeInsets.zero),
                onPressed: () => _setujui(i),
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
              onPressed: () => _ubah(i),
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
              onPressed: () => _tolak(i),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Tolak'),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _opsi(BuildContext context, String no, String judul, String sub,
      VoidCallback aksi) {
    final c = context.dg;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: aksi,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: c.cardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          CircleAvatar(
              radius: 13,
              backgroundColor: c.accent.withValues(alpha: 0.25),
              child: Text(no, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
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

  Widget _ringkas(BuildContext context, _Item i) {
    final c = context.dg;
    final ditolak = i.status == 'ditolak';
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Row(children: [
        IconTile(warna: c.accent, child: Text(i.emoji, style: const TextStyle(fontSize: 22))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i.nama, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(
                ditolak
                    ? 'Alasan: ${i.alasan ?? '-'}'
                    : '${i.qty} ${i.satuan} • ${i.supplier}',
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
          ]),
        ),
        if (ditolak)
          TextButton(
              onPressed: () => setState(() => i.status = 'menunggu'),
              child: const Text('Pulihkan'))
        else
          Pill(i.lama ? 'Terkirim' : 'Siap kirim',
              warna: i.lama ? c.masuk : c.info),
      ]),
    );
  }
}

class _WaSheet extends StatelessWidget {
  const _WaSheet({required this.item, required this.pesan, required this.kasSisa});
  final _Item item;
  final String pesan;
  final int kasSisa;

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
          Expanded(
              child: Text(item.supplier,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: c.chip, borderRadius: BorderRadius.circular(16)),
          child: Text(pesan, style: const TextStyle(height: 1.45, fontSize: 13)),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total ${rp(item.total)}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
        ),
      ]),
    );
  }
}

class _UbahSheet extends StatefulWidget {
  const _UbahSheet({required this.item, required this.kasSisa});
  final _Item item;
  final int kasSisa;

  @override
  State<_UbahSheet> createState() => _UbahSheetState();
}

class _UbahSheetState extends State<_UbahSheet> {
  late int _qty = widget.item.qty;

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    final total = _qty * widget.item.hargaBeli;
    final kurang = total > widget.kasSisa;
    return SheetBox(
      child: Column(children: [
        Text('Ubah jumlah ${widget.item.nama}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          tombolBulat(context, Icons.remove, _qty > 1 ? () => setState(() => _qty--) : null),
          SizedBox(
            width: 120,
            child: Column(children: [
              Text('$_qty',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
              Text(widget.item.satuan, style: TextStyle(color: c.textSecondary)),
            ]),
          ),
          tombolBulat(context, Icons.add, () => setState(() => _qty++), utama: true),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: c.chip, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(
                child: Text('Biaya ${rp(total)}',
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            Pill(kurang ? 'Kas kurang' : 'Kas cukup',
                warna: kurang ? c.keluar : c.masuk),
          ]),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pop(context, _qty),
          child: const Text('Simpan jumlah'),
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
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, _pilih),
              child: const Text('Tolak')),
        ],
      );
}