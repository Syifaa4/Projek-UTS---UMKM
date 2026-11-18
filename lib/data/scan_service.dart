class BarisScan {
  BarisScan({
    required this.nama,
    required this.qty,
    required this.harga,
    this.ragu = false,
    this.produkId,
  });
  String nama;
  int qty, harga;
  bool ragu;
  String? produkId; // null = produk baru
}

/// Kontrak pembaca foto. Nanti diganti GeminiScanService (firebase_ai)
/// tanpa mengubah layar mana pun.
abstract class ScanService {
  Future<List<BarisScan>> baca({required bool penjualan});
}

/// MODE DEMO: mengembalikan contoh hasil baca, bukan membaca foto sungguhan.
class DemoScanService implements ScanService {
  @override
  Future<List<BarisScan>> baca({required bool penjualan}) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (penjualan) {
      return [
        BarisScan(nama: 'Minyak goreng 2L', qty: 2, harga: 36000),
        BarisScan(nama: 'Beras 5 kg', qty: 1, harga: 68000),
        BarisScan(nama: 'Gula 1 kg', qty: 3, harga: 16000, ragu: true),
        BarisScan(nama: 'Permen jahe', qty: 5, harga: 500, ragu: true),
      ];
    }
    return [
      BarisScan(nama: 'Minyak goreng 2L', qty: 12, harga: 31500),
      BarisScan(nama: 'Gula 1 kg', qty: 20, harga: 14000, ragu: true),
      BarisScan(nama: 'Kerupuk udang', qty: 10, harga: 8000),
    ];
  }
}