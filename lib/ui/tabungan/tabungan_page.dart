import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/state_view.dart';

int _n(String s) => int.tryParse(s.replaceAll('.', '').trim()) ?? 0;

class TabunganPage extends StatelessWidget {
  const TabunganPage({super.key});

  void _tujuanForm(BuildContext context, {Tujuan? edit}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TujuanForm(edit: edit),
    );
  }

  void _dana(BuildContext context, Tujuan t, bool pakai) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DanaSheet(t: t, pakai: pakai),
    );
  }

  void _riwayat(BuildContext context, Tujuan t) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RiwayatSheet(t: t),
    );
  }

  Future<void> _hapus(BuildContext context, AppStore s, Tujuan t) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus tujuan?'),
        content: Text(
            'Dana tercatat ${rp(t.terkumpul)} akan kembali menjadi kas biasa. Riwayat setoran ikut terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ya == true) s.hapusTujuan(t);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final c = context.dg;
    final sec = TextStyle(color: c.textSecondary, fontSize: 12);
    final kas = s.kasTersedia < 0 ? 0 : s.kasTersedia;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(14),
          radius: 20,
          child: Row(children: [
            Icon(Icons.verified_user_outlined, color: c.warning, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                  'Aplikasi hanya mencatat, tidak menyimpan uang Anda. Uang tetap di rekening atau laci kas Anda.',
                  style: TextStyle(fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Muncul(
          child: GlassCard(
            blur: true,
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TOTAL DANA TERCATAT',
                  style: sec.copyWith(letterSpacing: 1, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(rp(s.totalTabungan),
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: c.isDark ? c.accent : c.brand)),
              const SizedBox(height: 8),
              Text('Dana ini dikunci dari kas belanja. Kas tersedia untuk restok sekarang ${rp(kas)}.',
                  style: sec.copyWith(height: 1.4)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _tujuanForm(context),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Tambah tujuan'),
        ),
        const SizedBox(height: 14),
        if (s.tujuan.isEmpty)
          StateView(
            gambar: 'assets/images/growth.png',
            judul: 'Belum ada tujuan',
            pesan: 'Buat tujuan pertama: umroh, bayar supplier, biaya pendidikan, atau lainnya.',
            tombol: 'Buat tujuan pertama',
            aksi: () => _tujuanForm(context),
          )
        else
          for (final t in s.tujuan)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Muncul(child: _kartu(context, s, t)),
            ),
        const SizedBox(height: 4),
        GlassCard(
          padding: const EdgeInsets.all(14),
          radius: 20,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lock_outline, size: 20, color: c.info),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  'Semua dana tujuan tidak dipakai untuk rekomendasi restok. Tujuan berlabel Pribadi tetap dikunci supaya uang pribadi tidak terpakai belanja stok.',
                  style: sec.copyWith(fontSize: 12.5, height: 1.45)),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _kartu(BuildContext context, AppStore s, Tujuan t) {
    final c = context.dg;
    final sec = TextStyle(color: c.textSecondary, fontSize: 12);
    final pct = t.target <= 0 ? 0.0 : (t.terkumpul / t.target).clamp(0.0, 1.0).toDouble();
    final tercapai = t.terkumpul >= t.target;

    bool? onTrack;
    int? perHari, sisaHari;
    if (t.tenggat != null) {
      final total = t.tenggat!.difference(t.mulai).inDays;
      final lewat = total <= 0
          ? 1.0
          : (s.hariIni.difference(t.mulai).inDays / total).clamp(0.0, 1.0).toDouble();
      onTrack = t.terkumpul >= t.target * lewat;
      sisaHari = t.tenggat!.difference(s.hariIni).inDays;
      final sh = sisaHari < 1 ? 1 : sisaHari;
      final butuh = t.target - t.terkumpul;
      perHari = butuh <= 0 ? 0 : (butuh / sh).ceil();
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconTile(warna: c.accent, child: Text(t.emoji, style: const TextStyle(fontSize: 24))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, children: [
                Pill(t.jenis, warna: t.jenis == 'Usaha' ? c.info : c.warning),
                if (tercapai)
                  Pill('Tercapai', warna: c.masuk, ikon: Icons.celebration_outlined)
                else if (onTrack != null)
                  Pill(onTrack ? 'On track' : 'Tertinggal',
                      warna: onTrack ? c.masuk : c.warning,
                      ikon: onTrack ? Icons.check_circle_outline : Icons.schedule),
              ]),
            ]),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'ubah':
                  _tujuanForm(context, edit: t);
                case 'riwayat':
                  _riwayat(context, t);
                case 'hapus':
                  _hapus(context, s, t);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ubah', child: Text('Ubah')),
              PopupMenuItem(value: 'riwayat', child: Text('Riwayat')),
              PopupMenuItem(value: 'hapus', child: Text('Hapus')),
            ],
          ),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(rp(t.terkumpul),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: c.isDark ? c.accent : c.brand)),
          Text('dari ${rp(t.target)}', style: sec),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: c.chip,
            color: c.accent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.tenggat == null
              ? '${(pct * 100).round()}% tercapai • tanpa tenggat'
              : '${(pct * 100).round()}% • tenggat ${tglPendek(t.tenggat!)} (${sisaHari! < 0 ? 'lewat' : '$sisaHari hari lagi'})'
                  '${tercapai ? '' : ' • butuh ${rp(perHari!)}/hari'}',
          style: sec,
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: () => _dana(context, t, false),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Setor'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: t.terkumpul > 0 ? () => _dana(context, t, true) : null,
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: const Text('Pakai dana'),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _DanaSheet extends StatefulWidget {
  const _DanaSheet({required this.t, required this.pakai});
  final Tujuan t;
  final bool pakai;

  @override
  State<_DanaSheet> createState() => _DanaSheetState();
}

class _DanaSheetState extends State<_DanaSheet> {
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
  Widget build(BuildContext context) {
    final c = context.dg;
    final s = context.read<AppStore>();
    final kas = s.kasTersedia < 0 ? 0 : s.kasTersedia;
    return SheetBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.pakai ? 'Pakai dana ${widget.t.nama}' : 'Setor ke ${widget.t.nama}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
            widget.pakai
                ? 'Dana tercatat ${rp(widget.t.terkumpul)}. Dana yang dipakai tercatat sebagai uang keluar.'
                : 'Kas tersedia ${rp(kas)}. Setoran dikunci dari kas belanja.',
            style: TextStyle(color: c.textSecondary, fontSize: 13)),
        const SizedBox(height: 14),
        TextField(
          controller: _nominal,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          decoration: dekorasi(context, 'Nominal', prefix: 'Rp ', error: _err),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final n in [20000, 50000, 100000, 500000])
            ActionChip(
                label: Text(rpSingkat(n)),
                onPressed: () => setState(() {
                      _nominal.text = '$n';
                      _err = null;
                    })),
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: _ket,
          decoration: dekorasi(context, widget.pakai ? 'Dipakai untuk apa?' : 'Catatan (opsional)'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            final n = _n(_nominal.text);
            final err = widget.pakai
                ? s.pakaiDana(widget.t, n, _ket.text.trim())
                : s.setor(widget.t, n, _ket.text.trim());
            if (err != null) {
              setState(() => _err = err);
              return;
            }
            final m = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            m.showSnackBar(SnackBar(
                content: Text(widget.pakai ? 'Dana dipakai ${rp(n)}' : 'Setoran ${rp(n)} tercatat')));
          },
          child: Text(widget.pakai ? 'Catat pemakaian' : 'Simpan setoran'),
        ),
      ]),
    );
  }
}

class _RiwayatSheet extends StatelessWidget {
  const _RiwayatSheet({required this.t});
  final Tujuan t;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final c = context.dg;
    final urut = [...t.setoran]..sort((a, b) => b.tgl.compareTo(a.tgl));
    return SheetBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Riwayat ${t.nama}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (urut.isEmpty) Text('Belum ada setoran.', style: TextStyle(color: c.textSecondary)),
        for (final x in urut)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(x.ket, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(tglPendek(x.tgl)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('${x.nominal >= 0 ? '+' : '-'} ${rp(x.nominal.abs())}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: x.nominal >= 0 ? c.masuk : c.keluar)),
              IconButton(
                icon: Icon(Icons.delete_outline, color: c.keluar, size: 20),
                onPressed: () => s.hapusSetoran(t, x),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _TujuanForm extends StatefulWidget {
  const _TujuanForm({this.edit});
  final Tujuan? edit;

  @override
  State<_TujuanForm> createState() => _TujuanFormState();
}

class _TujuanFormState extends State<_TujuanForm> {
  late final _nama = TextEditingController(text: widget.edit?.nama ?? '');
  late final _target = TextEditingController(text: widget.edit == null ? '' : '${widget.edit!.target}');
  late String _emoji = widget.edit?.emoji ?? '🎯';
  late String _jenis = widget.edit?.jenis ?? 'Usaha';
  late DateTime? _tenggat = widget.edit?.tenggat;
  String? _err;

  static const _preset = [
    ('Umroh', '🕋', 'Pribadi'),
    ('Bayar supplier', '🏪', 'Usaha'),
    ('Biaya pendidikan', '🎓', 'Pribadi'),
    ('Dana darurat', '🛡️', 'Usaha'),
    ('Renovasi toko', '🔨', 'Usaha'),
    ('Liburan', '🏖️', 'Pribadi'),
  ];
  static const _emojis = ['🎯', '🕋', '🏪', '🎓', '🛡️', '🔨', '🏖️', '🏠', '🚗', '💍', '👶', '🎁'];

  @override
  void dispose() {
    _nama.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final hariIni = context.read<AppStore>().hariIni;
    final d = await showDatePicker(
      context: context,
      initialDate: _tenggat ?? hariIni.add(const Duration(days: 90)),
      firstDate: hariIni,
      lastDate: hariIni.add(const Duration(days: 3650)),
    );
    if (d != null) setState(() => _tenggat = d);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    return SheetBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.edit == null ? 'Tujuan baru' : 'Ubah tujuan',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (widget.edit == null) ...[
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final p in _preset)
              ActionChip(
                label: Text('${p.$2} ${p.$1}'),
                onPressed: () => setState(() {
                  _nama.text = p.$1;
                  _emoji = p.$2;
                  _jenis = p.$3;
                }),
              ),
          ]),
          const SizedBox(height: 12),
        ],
        TextField(controller: _nama, decoration: dekorasi(context, 'Nama tujuan')),
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
          const Text('Jenis: ', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          ChoiceChip(
              label: const Text('Usaha'),
              selected: _jenis == 'Usaha',
              onSelected: (_) => setState(() => _jenis = 'Usaha')),
          const SizedBox(width: 8),
          ChoiceChip(
              label: const Text('Pribadi'),
              selected: _jenis == 'Pribadi',
              onSelected: (_) => setState(() => _jenis = 'Pribadi')),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _target,
          keyboardType: TextInputType.number,
          decoration: dekorasi(context, 'Target nominal', prefix: 'Rp '),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _pilihTanggal,
              icon: const Icon(Icons.event, size: 18),
              label: Text(_tenggat == null ? 'Pilih tenggat (opsional)' : tglPendek(_tenggat!)),
            ),
          ),
          if (_tenggat != null)
            TextButton(onPressed: () => setState(() => _tenggat = null), child: const Text('Tanpa tenggat')),
        ]),
        if (_err != null)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_err!, style: TextStyle(color: c.keluar))),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            final nama = _nama.text.trim();
            final target = _n(_target.text);
            if (nama.isEmpty || target <= 0) {
              setState(() => _err = 'Perlu dicek: nama atau target belum benar');
              return;
            }
            final s = context.read<AppStore>();
            if (widget.edit == null) {
              s.tambahTujuan(
                  nama: nama, emoji: _emoji, jenis: _jenis, target: target, tenggat: _tenggat);
            } else {
              final t = widget.edit!;
              t.nama = nama;
              t.emoji = _emoji;
              t.jenis = _jenis;
              t.target = target;
              t.tenggat = _tenggat;
              s.simpan();
            }
            Navigator.pop(context);
          },
          child: const Text('Simpan tujuan'),
        ),
      ]),
    );
  }
}