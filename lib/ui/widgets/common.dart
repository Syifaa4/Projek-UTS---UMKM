import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

String rp(num v) {
  final neg = v < 0;
  final s = v.abs().round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${neg ? '-' : ''}Rp $b';
}

String rpSingkat(num v) => v >= 1000000
    ? 'Rp ${(v / 1000000).toStringAsFixed(2).replaceAll('.', ',')} jt'
    : rp(v);

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];
String tanggalId(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';
String tglPendek(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// Label kecil berwarna (status, badge).
class Pill extends StatelessWidget {
  const Pill(this.teks, {super.key, required this.warna, this.ikon});
  final String teks;
  final Color warna;
  final IconData? ikon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (ikon != null) ...[
            Icon(ikon, size: 13, color: warna),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(teks,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: warna, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

/// Kotak ikon/emoji berlatar warna lembut.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.child, required this.warna, this.ukuran = 44});
  final Widget child;
  final Color warna;
  final double ukuran;

  @override
  Widget build(BuildContext context) => Container(
        width: ukuran,
        height: ukuran,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.teks, {super.key, this.ikon, this.trailing});
  final String teks;
  final IconData? ikon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    return Row(children: [
      if (ikon != null) ...[
        Icon(ikon, size: 18, color: c.textSecondary),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: Text(teks,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

/// Animasi muncul halus (fade + geser), sekali saja, ringan.
class Muncul extends StatelessWidget {
  const Muncul({super.key, required this.child, this.urutan = 0});
  final Widget child;
  final int urutan;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + 70 * urutan.clamp(0, 6)),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, t, ch) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: ch),
      ),
    );
  }
}

/// Cincin progres (tanpa package).
class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.nilai,
    required this.ukuran,
    required this.warna,
    required this.jalur,
    this.tebal = 10,
    this.child,
  });
  final double nilai, ukuran, tebal;
  final Color warna, jalur;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: ukuran,
        height: ukuran,
        child: CustomPaint(
          painter: _RingPainter(nilai.clamp(0.0, 1.0), tebal, warna, jalur),
          child: Center(child: child),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.nilai, this.tebal, this.warna, this.jalur);
  final double nilai, tebal;
  final Color warna, jalur;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.width - tebal) / 2;
    final pusat = Offset(size.width / 2, size.height / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tebal
      ..strokeCap = StrokeCap.round
      ..color = jalur;
    canvas.drawCircle(pusat, r, p);
    p.color = warna;
    canvas.drawArc(Rect.fromCircle(center: pusat, radius: r), -math.pi / 2,
        2 * math.pi * nilai, false, p);
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.nilai != nilai || o.warna != warna || o.jalur != jalur;
}

/// Tab berbentuk pil.
class ChipTabs extends StatelessWidget {
  const ChipTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.counts,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final List<int>? counts;

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: c.chip, borderRadius: BorderRadius.circular(99)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == index ? c.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  counts == null ? labels[i] : '${labels[i]} (${counts![i]})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: i == index ? FontWeight.w800 : FontWeight.w600,
                    color: i == index ? c.onAccent : c.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

Widget tombolBulat(BuildContext context, IconData ikon, VoidCallback? aksi,
    {bool utama = false}) {
  final c = context.dg;
  return Material(
    color: utama ? c.accent : c.chip,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: aksi,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(ikon,
            size: 20, color: utama ? c.onAccent : c.textPrimary),
      ),
    ),
  );
}

InputDecoration dekorasi(BuildContext context, String label,
    {String? prefix, String? error, String? hint}) {
  final c = context.dg;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefix,
    errorText: error,
    filled: true,
    fillColor: c.chip,
    labelStyle: TextStyle(color: c.textSecondary),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  );
}

/// Pembungkus bottom sheet (aman dari keyboard).
class SheetBox extends StatelessWidget {
  const SheetBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: c.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4)),
              ),
              child,
            ]),
          ),
        ),
      ),
    );
  }
}