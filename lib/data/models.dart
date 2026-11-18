class Supplier {
  Supplier({required this.id, required this.nama, this.wa = ''});
  final String id;
  String nama, wa;
}

class Produk {
  Produk({
    required this.id,
    required this.nama,
    this.emoji = '📦',
    this.satuan = 'pcs',
    this.hargaBeli = 0,
    this.hargaJual = 0,
    this.stok = 0,
    this.supplierId = '',
    this.leadTime = 2,
    this.hariCadangan = 3,
    this.kelipatan = 1,
    this.aktif = true,
  });
  final String id;
  String nama, emoji, satuan, supplierId;
  int hargaBeli, hargaJual, stok, leadTime, hariCadangan, kelipatan;
  bool aktif;
}

class Penjualan {
  Penjualan(this.tgl, this.produkId, this.qty, this.nominal);
  final DateTime tgl;
  final String produkId;
  final int qty, nominal;
}

class Trx {
  Trx({
    required this.id,
    required this.tgl,
    required this.masuk,
    required this.kategori,
    required this.ket,
    required this.nominal,
    this.direncanakan = false,
  });
  final String id;
  final DateTime tgl;
  final bool masuk;
  final String kategori, ket;
  int nominal;
  bool direncanakan;
}

class Rekom {
  Rekom({
    required this.id,
    required this.produkId,
    required this.qty,
    required this.harga,
    required this.sisaHari,
    required this.spike,
    required this.tgl,
  });
  final String id, produkId;
  final double sisaHari;
  final bool spike;
  final DateTime tgl;
  int qty, harga;
  String status = 'menunggu'; // menunggu | disetujui | ditolak
  String order = ''; // '' | Siap kirim | Terkirim | Diterima
  String? alasan, trxId;
  DateTime? waktuTolak;
  int get total => qty * harga;
}

class Setoran {
  Setoran(this.ket, this.nominal, this.tgl);
  final String ket;
  final int nominal; // negatif = dana dipakai
  final DateTime tgl;
}

class Tujuan {
  Tujuan({
    required this.id,
    required this.nama,
    required this.emoji,
    required this.jenis,
    required this.target,
    required this.mulai,
    this.tenggat,
  });
  final String id;
  String nama, emoji, jenis; // jenis: Usaha | Pribadi
  int target;
  final DateTime mulai;
  DateTime? tenggat;
  final List<Setoran> setoran = [];
  int get terkumpul => setoran.fold(0, (a, s) => a + s.nominal);
}

class LogEntry {
  LogEntry(this.tgl, this.aksi, this.hasil);
  final DateTime tgl;
  final String aksi, hasil;
}