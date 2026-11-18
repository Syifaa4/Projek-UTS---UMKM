import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.gambar,
    required this.judul,
    required this.pesan,
    this.tombol,
    this.aksi,
    this.tinggi = 150,
  });

  final String gambar, judul, pesan;
  final String? tombol;
  final VoidCallback? aksi;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(gambar,
              height: tinggi,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.image_not_supported_outlined, size: 64, color: c.textSecondary)),
          const SizedBox(height: 16),
          Text(judul,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(pesan,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, height: 1.4)),
          if (tombol != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(160, 46)),
              onPressed: aksi,
              child: Text(tombol!),
            ),
          ],
        ]),
      ),
    );
  }
}