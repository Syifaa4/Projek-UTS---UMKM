import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/state_view.dart';

class ProdukKatalog {
  ProdukKatalog({
    required this.id,
    required this.nama,
    required this.harga,
    required this.gambar,
  });
  final int id;
  final String nama, gambar;
  final double harga;

  factory ProdukKatalog.fromJson(Map<String, dynamic> j) => ProdukKatalog(
        id: j['id'] as int,
        nama: j['title'] as String,
        harga: (j['price'] as num).toDouble(),
        gambar: (j['thumbnail'] ?? '') as String,
      );
}

class KatalogService {
  Future<List<ProdukKatalog>> ambil(String kata) async {
    final uri = kata.isEmpty
        ? Uri.parse('https://dummyjson.com/products/category/groceries')
        : Uri.parse(
            'https://dummyjson.com/products/search?q=${Uri.encodeQueryComponent(kata)}');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Server error ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['products'] as List)
        .map((e) => ProdukKatalog.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class KatalogPage extends StatefulWidget {
  const KatalogPage({super.key});

  @override
  State<KatalogPage> createState() => _KatalogPageState();
}

class _KatalogPageState extends State<KatalogPage> {
  final _service = KatalogService();
  final _cari = TextEditingController();
  late Future<List<ProdukKatalog>> _data = _service.ambil('');

  void _muat() => setState(() => _data = _service.ambil(_cari.text.trim()));

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dg;
    return Scaffold(
      appBar: AppBar(title: const Text('Katalog produk')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _cari,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _muat(),
            decoration: dekorasi(context, 'Cari produk').copyWith(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward), onPressed: _muat),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<ProdukKatalog>>(
            future: _data,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return StateView(
                  gambar: 'assets/images/no-internet.png',
                  judul: 'Tidak ada koneksi',
                  pesan: 'Periksa internet Anda, lalu coba lagi.',
                  tombol: 'Coba lagi',
                  aksi: _muat,
                );
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return const StateView(
                  gambar: 'assets/images/not-found.png',
                  judul: 'Produk tidak ditemukan',
                  pesan: 'Coba kata kunci lain.',
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 226),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  return GlassCard(
                    padding: const EdgeInsets.all(10),
                    radius: 20,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                color: c.chip,
                                child: Image.network(p.gambar,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                        Icons.image_not_supported_outlined)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(p.nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('\$${p.harga.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: c.isDark ? c.accent : c.warning,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 34,
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  textStyle: const TextStyle(fontSize: 12)),
                              onPressed: () => ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(SnackBar(
                                    content: Text(
                                        '${p.nama} ditambahkan ke produk saya'))),
                              child: const Text('Tambah ke produk saya'),
                            ),
                          ),
                        ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}