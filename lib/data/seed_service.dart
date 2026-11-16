import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  SeedService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  String _tgl(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  Future<void> isiDataContoh(String usahaId, {String? email}) async {
    final usaha = _db.collection('usaha').doc(usahaId);
    final batch = _db.batch();
    final rnd = Random(42);

    batch.set(_db.collection('users').doc(usahaId), {
      'nama': 'Pemilik Demo',
      'email': email,
      'role': 'pemilik',
      'usahaId': usahaId,
    });

    batch.set(usaha, {
      'nama': 'Warung Berkah (Demo)',
      'saldoAwal': 3000000,
      'batasAmanKas': 500000,
      'jendelaHari': 7,
      'hariCakupan': 14,
      'ambangLonjakan': 3,
    });

    final supplier = [
      {'id': 's1', 'nama': 'Toko Grosir Makmur', 'nomorWa': '6281200000001'},
      {'id': 's2', 'nama': 'Agen Sembako Jaya', 'nomorWa': '6281200000002'},
    ];
    for (final s in supplier) {
      batch.set(usaha.collection('supplier').doc(s['id']), s);
    }

    // rataJual = rata-rata penjualan harian untuk simulasi
    final produk = [
      {'id': 'p1', 'nama': 'Minyak Goreng 2L', 'satuan': 'pcs', 'hargaBeli': 32000, 'hargaJual': 36000, 'idSupplier': 's1', 'leadTimeHari': 2, 'hariCadangan': 3, 'kelipatanPesan': 6, 'stok': 8, 'rataJual': 3.0},
      {'id': 'p2', 'nama': 'Beras 5kg', 'satuan': 'karung', 'hargaBeli': 60000, 'hargaJual': 68000, 'idSupplier': 's2', 'leadTimeHari': 3, 'hariCadangan': 3, 'kelipatanPesan': 4, 'stok': 30, 'rataJual': 2.0},
      {'id': 'p3', 'nama': 'Gula 1kg', 'satuan': 'pcs', 'hargaBeli': 14000, 'hargaJual': 16000, 'idSupplier': 's1', 'leadTimeHari': 2, 'hariCadangan': 3, 'kelipatanPesan': 10, 'stok': 5, 'rataJual': 2.0},
      {'id': 'p4', 'nama': 'Mie Instan (dus)', 'satuan': 'dus', 'hargaBeli': 95000, 'hargaJual': 110000, 'idSupplier': 's2', 'leadTimeHari': 2, 'hariCadangan': 3, 'kelipatanPesan': 2, 'stok': 4, 'rataJual': 1.5},
      {'id': 'p5', 'nama': 'Teh Celup (box)', 'satuan': 'box', 'hargaBeli': 9000, 'hargaJual': 11000, 'idSupplier': 's1', 'leadTimeHari': 2, 'hariCadangan': 3, 'kelipatanPesan': 12, 'stok': 20, 'rataJual': 0.5},
    ];

    final hariIni = DateTime.now();
    final awalHari = DateTime(hariIni.year, hariIni.month, hariIni.day);

    for (final p in produk) {
      final rata = p['rataJual'] as double;
      final data = Map<String, dynamic>.from(p)..remove('rataJual');
      batch.set(usaha.collection('produk').doc(p['id'] as String), data);

      for (int i = 0; i < 30; i++) {
        final tgl = awalHari.subtract(Duration(days: i));
        final jumlah = max(0, (rata + rnd.nextInt(3) - 1).round());
        if (jumlah == 0) continue;
        batch.set(
          usaha.collection('penjualan').doc('${p['id']}_${_tgl(tgl)}'),
          {
            'tanggal': Timestamp.fromDate(tgl),
            'idProduk': p['id'],
            'jumlah': jumlah,
            'nominal': jumlah * (p['hargaJual'] as int),
            'diinputOleh': 'seed',
            'status': 'Diproses',
          },
        );
      }
    }

    await batch.commit();
  }
}