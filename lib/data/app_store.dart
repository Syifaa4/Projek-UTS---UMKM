import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/restock_calculator.dart';
import '../ui/widgets/common.dart' show rp;
import 'models.dart';
import 'scan_service.dart';

class StokInfo {
  StokInfo(this.p, this.r);
  final Produk p;
  final RestockResult r;
}

class TopProduk {
  TopProduk(this.p, this.qty, this.omzet);
  final Produk p;
  final int qty, omzet;
}

class AppStore extends ChangeNotifier {
  AppStore() {
    isiDemo();
  }

  bool pemilik = true;
  int saldoAwal = 0;
  int batasAman = 500000, hariCakupan = 14, masaTahanTolak = 3, persenSisih = 10;
  double ambang = 3;

  final produk = <Produk>[];
  final supplier = <Supplier>[];
  final penjualan = <Penjualan>[];
  final trx = <Trx>[];
  final rekom = <Rekom>[];
  final tujuan = <Tujuan>[];
  final log = <LogEntry>[];
  DateTime? terakhirRobot;
  int _seq = 0;

  // ---------- util ----------
  String idBaru(String p) => '$p${++_seq}';
  DateTime get hariIni {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _hari(int mundur) => hariIni.subtract(Duration(days: mundur));
  bool _sama(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  bool _dalam7(DateTime t) => !t.isBefore(_hari(6));

  void simpan() => notifyListeners();
  void setPemilik(bool v) {
    pemilik = v;
    notifyListeners();
  }

  void _log(String aksi, String hasil, {bool unik = false}) {
    if (unik &&
        log.take(15).any((e) =>
            e.aksi == aksi && e.hasil == hasil && _sama(e.tgl, DateTime.now()))) {
      return;
    }
    log.insert(0, LogEntry(DateTime.now(), aksi, hasil));
    if (log.length > 150) log.removeLast();
  }

  void catatLog(String aksi, String hasil) {
    _log(aksi, hasil);
    notifyListeners();
  }

  Produk? cari(String id) {
    for (final p in produk) {
      if (p.id == id) return p;
    }
    return null;
  }

  Supplier? supplierOf(Produk p) {
    for (final s in supplier) {
      if (s.id == p.supplierId) return s;
    }
    return null;
  }

  // ---------- data contoh ----------
  void isiDemo() {
    produk.clear();
    supplier.clear();
    penjualan.clear();
    trx.clear();
    rekom.clear();
    tujuan.clear();
    log.clear();
    terakhirRobot = null;
    _seq = 100;
    pemilik = true;
    saldoAwal = 2905000;
    batasAman = 500000;
    hariCakupan = 14;
    masaTahanTolak = 3;
    persenSisih = 10;
    ambang = 3;

    supplier.addAll([
      Supplier(id: 's1', nama: 'Toko Grosir Makmur', wa: '6281200000001'),
      Supplier(id: 's2', nama: 'Agen Sembako Jaya', wa: '6281200000002'),
      Supplier(id: 's3', nama: 'CV Berkah Snack', wa: ''),
    ]);

    final data = <(Produk, double)>[
      (Produk(id: 'p1', nama: 'Minyak Goreng 2L', emoji: '🧴', satuan: 'pcs', hargaBeli: 32000, hargaJual: 36000, stok: 8, supplierId: 's1', kelipatan: 6), 3.0),
      (Produk(id: 'p2', nama: 'Beras 5kg', emoji: '🌾', satuan: 'karung', hargaBeli: 60000, hargaJual: 68000, stok: 3, supplierId: 's2', leadTime: 3, kelipatan: 4), 2.0),
      (Produk(id: 'p3', nama: 'Gula 1kg', emoji: '🍬', satuan: 'pcs', hargaBeli: 14000, hargaJual: 16000, stok: 5, supplierId: 's1', kelipatan: 10), 2.0),
      (Produk(id: 'p4', nama: 'Mie Instan', emoji: '🍜', satuan: 'dus', hargaBeli: 95000, hargaJual: 110000, stok: 12, supplierId: 's2', kelipatan: 2), 1.5),
      (Produk(id: 'p5', nama: 'Teh Celup', emoji: '🍵', satuan: 'box', hargaBeli: 9000, hargaJual: 11000, stok: 20, supplierId: 's1', kelipatan: 12), 0.5),
      (Produk(id: 'p6', nama: 'Kerupuk', emoji: '🍘', satuan: 'bks', hargaBeli: 8000, hargaJual: 10000, stok: 15, supplierId: 's3'), 0.0),
    ];
    final rnd = Random(7);
    for (final (p, avg) in data) {
      produk.add(p);
      if (avg <= 0) continue;
      for (var i = 1; i <= 30; i++) {
        final q = max(0, (avg + rnd.nextInt(3) - 1).round());
        if (q == 0) continue;
        penjualan.add(Penjualan(_hari(i), p.id, q, q * p.hargaJual));
      }
    }

    Trx tx(int hari, bool masuk, String kat, String ket, int n) => Trx(
        id: idBaru('t'), tgl: _hari(hari), masuk: masuk, kategori: kat, ket: ket, nominal: n);
    trx.addAll([
      tx(0, true, 'Penjualan', 'Penjualan pagi', 850000),
      tx(0, false, 'Transportasi', 'Bensin antar pesanan', 210000),
      tx(1, true, 'Penjualan', 'Penjualan kemarin', 1450000),
      tx(1, false, 'Transportasi', 'Parkir dan ojek', 45000),
      tx(2, true, 'Penjualan', 'Penjualan 2 hari lalu', 1320000),
      tx(3, false, 'Belanja Stok', 'Kulakan sembako', 640000),
      tx(4, false, 'Listrik & Air', 'Token listrik', 180000),
    ]);

    Tujuan tj(String nama, String emoji, String jenis, int target, int mulai,
        int? sisa, int awal) {
      final t = Tujuan(
          id: idBaru('g'), nama: nama, emoji: emoji, jenis: jenis, target: target,
          mulai: _hari(mulai),
          tenggat: sisa == null ? null : hariIni.add(Duration(days: sisa)));
      t.setoran.add(Setoran('Setoran awal', awal - 100000, _hari(20)));
      t.setoran.add(Setoran('Sisihan pekan lalu', 100000, _hari(3)));
      return t;
    }

    tujuan.addAll([
      tj('Umroh', '🕋', 'Pribadi', 20000000, 60, 500, 2400000),
      tj('Bayar supplier', '🏪', 'Usaha', 3000000, 40, 40, 600000),
      tj('Biaya pendidikan', '🎓', 'Pribadi', 10000000, 30, null, 450000),
    ]);

    _log('Demo', 'Data contoh dimuat');
    jalankanRobot();
  }

  // ---------- kas ----------
  int get saldo {
    var t = saldoAwal;
    for (final x in trx) {
      if (x.direncanakan) continue;
      t += x.masuk ? x.nominal : -x.nominal;
    }
    return t;
  }

  int get rencanaKeluar => trx
      .where((x) => x.direncanakan && !x.masuk)
      .fold(0, (a, x) => a + x.nominal);
  int get totalTabungan => tujuan.fold(0, (a, t) => a + t.terkumpul);
  int get kasTersedia => saldo - rencanaKeluar - batasAman - totalTabungan;

  int get masukHariIni => trx
      .where((x) => x.masuk && !x.direncanakan && _sama(x.tgl, hariIni))
      .fold(0, (a, x) => a + x.nominal);
  int get keluarHariIni => trx
      .where((x) => !x.masuk && !x.direncanakan && _sama(x.tgl, hariIni))
      .fold(0, (a, x) => a + x.nominal);

  // ---------- laporan ----------
  int omzetHari(DateTime d) {
    var t = 0;
    for (final s in penjualan) {
      if (_sama(s.tgl, d)) t += s.nominal;
    }
    for (final x in trx) {
      if (x.masuk && x.kategori == 'Omzet harian' && _sama(x.tgl, d)) t += x.nominal;
    }
    return t;
  }

  int _omzetRange(int dari, int sampai) {
    var t = 0;
    for (var i = dari; i <= sampai; i++) {
      t += omzetHari(_hari(i));
    }
    return t;
  }

  int get omzet7 => _omzetRange(0, 6);
  double? get pertumbuhan {
    final lalu = _omzetRange(7, 13);
    return lalu == 0 ? null : (omzet7 - lalu) / lalu * 100;
  }

  int get untung7 {
    var t = 0;
    for (final s in penjualan) {
      if (!_dalam7(s.tgl)) continue;
      t += s.nominal - s.qty * (cari(s.produkId)?.hargaBeli ?? 0);
    }
    return t;
  }

  int get keluar7 => trx
      .where((x) => !x.masuk && !x.direncanakan && _dalam7(x.tgl))
      .fold(0, (a, x) => a + x.nominal);

  List<TopProduk> get terlaris {
    final qty = <String, int>{}, om = <String, int>{};
    for (final s in penjualan) {
      if (!_dalam7(s.tgl)) continue;
      qty[s.produkId] = (qty[s.produkId] ?? 0) + s.qty;
      om[s.produkId] = (om[s.produkId] ?? 0) + s.nominal;
    }
    final out = <TopProduk>[];
    qty.forEach((id, q) {
      final p = cari(id);
      if (p != null) out.add(TopProduk(p, q, om[id] ?? 0));
    });
    out.sort((a, b) => b.qty.compareTo(a.qty));
    return out.take(3).toList();
  }

  /// Narasi laporan: template. Tempat sambungan AI opsional.
  String get cerita {
    final t = terlaris, g = pertumbuhan;
    final b = StringBuffer(
        'Pekan ini omzet toko ${rp(omzet7)} dengan untung kasar ${rp(untung7)}.');
    if (t.isNotEmpty) {
      b.write(' ${t.first.p.nama} paling laris (${t.first.qty} ${t.first.p.satuan}).');
    }
    if (g != null) {
      b.write(g >= 0
          ? ' Omzet naik ${g.round()}% dari pekan lalu.'
          : ' Omzet turun ${g.abs().round()}% dari pekan lalu.');
    }
    final k = rekom.where((r) => r.status == 'menunggu').length;
    if (k > 0) b.write(' Ada $k rekomendasi restok menunggu keputusan Anda.');
    return b.toString();
  }

  // ---------- hitung restok ----------
  RestockResult hitungProduk(Produk p) {
    var total7 = 0, hariIniQty = 0;
    final hariAda = <String>{};
    for (final s in penjualan) {
      if (s.produkId != p.id) continue;
      hariAda.add('${s.tgl.year}-${s.tgl.month}-${s.tgl.day}');
      if (_dalam7(s.tgl)) total7 += s.qty;
      if (_sama(s.tgl, hariIni)) hariIniQty += s.qty;
    }
    final kas = kasTersedia < 0 ? 0 : kasTersedia;
    return const RestockCalculator().hitung(RestockInput(
      stokSekarang: p.stok.toDouble(),
      totalJual7Hari: total7.toDouble(),
      hariDataTersedia: hariAda.length,
      penjualanHariIni: hariIniQty.toDouble(),
      leadTimeHari: p.leadTime,
      hariCadangan: p.hariCadangan,
      hariCakupan: hariCakupan,
      kelipatanPesan: p.kelipatan,
      hargaBeli: p.hargaBeli.toDouble(),
      kasTersedia: kas.toDouble(),
      ambangLonjakan: ambang,
    ));
  }

  List<StokInfo> get stokMenipis {
    final out = <StokInfo>[];
    for (final p in produk) {
      if (!p.aktif) continue;
      final r = hitungProduk(p);
      if (r.sisaHariStok != null) out.add(StokInfo(p, r));
    }
    out.sort((a, b) => a.r.sisaHariStok!.compareTo(b.r.sisaHariStok!));
    return out;
  }

  /// ROBOT RESTOK. Mengembalikan jumlah rekomendasi baru.
  int jalankanRobot() {
    var baru = 0;
    for (final p in produk) {
      if (!p.aktif) continue;
      final r = hitungProduk(p);
      if (r.status == RestockStatus.dataBelumCukup) {
        _log('Hitung restok', '${p.nama}: data belum cukup', unik: true);
        continue;
      }
      if (r.status == RestockStatus.jarangLaku) {
        _log('Hitung restok', '${p.nama}: jarang laku, tidak direkomendasikan', unik: true);
        continue;
      }
      if (!r.perluKartuKeputusan) continue;

      final ganda = rekom.any((x) =>
          x.produkId == p.id &&
          (x.status == 'menunggu' ||
              (x.status == 'disetujui' && x.order != 'Diterima')));
      if (ganda) {
        _log('Rekomendasi ganda dilewati', p.nama, unik: true);
        continue;
      }
      final ditahan = rekom.any((x) =>
          x.produkId == p.id &&
          x.status == 'ditolak' &&
          x.waktuTolak != null &&
          hariIni.difference(DateTime(x.waktuTolak!.year, x.waktuTolak!.month,
                      x.waktuTolak!.day)).inDays < masaTahanTolak);
      if (ditahan) {
        _log('Rekomendasi ditahan', '${p.nama}: baru ditolak', unik: true);
        continue;
      }
      final sp = supplierOf(p);
      if (sp == null || sp.wa.isEmpty) {
        _log('Kontak supplier kosong', '${p.nama}: lengkapi di menu Supplier', unik: true);
        continue;
      }
      if (r.lonjakan) {
        _log('Lonjakan penjualan', '${p.nama}: jumlah tidak dinaikkan otomatis', unik: true);
      }
      rekom.add(Rekom(
        id: idBaru('r'), produkId: p.id, qty: r.jumlahUsulan, harga: p.hargaBeli,
        sisaHari: r.sisaHariStok ?? 0, spike: r.lonjakan, tgl: DateTime.now()));
      baru++;
    }
    terakhirRobot = DateTime.now();
    _log('Robot restok', '$baru rekomendasi baru');
    notifyListeners();
    return baru;
  }

  // ---------- keputusan restok ----------
  void ubahQty(Rekom r, int q) {
    r.qty = q;
    notifyListeners();
  }

  void setujui(Rekom r) {
    final p = cari(r.produkId);
    if (p == null) return;
    r.status = 'disetujui';
    r.order = 'Siap kirim';
    final t = Trx(
        id: idBaru('t'), tgl: DateTime.now(), masuk: false, kategori: 'Belanja Stok',
        ket: 'Pesanan ${p.nama} ${r.qty} ${p.satuan}', nominal: r.total, direncanakan: true);
    trx.add(t);
    r.trxId = t.id;
    _log('Keputusan pemilik',
        'Setuju pesan ${p.nama} ${r.qty} ${p.satuan}. Pesan WhatsApp disiapkan, transaksi direncanakan ${rp(r.total)}');
    notifyListeners();
  }

  void tolak(Rekom r, String alasan) {
    r.status = 'ditolak';
    r.alasan = alasan;
    r.waktuTolak = DateTime.now();
    _log('Keputusan pemilik',
        'Tolak ${cari(r.produkId)?.nama ?? ''}: $alasan. Rekomendasi serupa ditahan $masaTahanTolak hari');
    notifyListeners();
  }

  void pulihkan(Rekom r) {
    r.status = 'menunggu';
    r.alasan = null;
    r.waktuTolak = null;
    notifyListeners();
  }

  void tandaiTerkirim(Rekom r) {
    r.order = 'Terkirim';
    _log('Pesanan', '${cari(r.produkId)?.nama ?? ''} ditandai terkirim');
    notifyListeners();
  }

  void tandaiDiterima(Rekom r, int qty, int harga) {
    final p = cari(r.produkId);
    if (p == null) return;
    p.stok += qty;
    p.hargaBeli = harga;
    r.order = 'Diterima';
    for (final t in trx) {
      if (t.id == r.trxId) {
        t.direncanakan = false;
        t.nominal = qty * harga;
      }
    }
    _log('Barang diterima',
        '${p.nama} +$qty ${p.satuan}. Stok bertambah, transaksi selesai ${rp(qty * harga)}');
    jalankanRobot();
  }

  String pesanWa(Rekom r) {
    final p = cari(r.produkId)!;
    final s = supplierOf(p);
    return 'Halo Kak ${s?.nama ?? ''}, saya mau pesan: ${p.nama} ${r.qty} ${p.satuan}. '
        'Mohon info total dan estimasi pengiriman. Terima kasih.';
  }

  // ---------- input harian ----------
  int catatPenjualan(Map<String, int> qty) {
    var total = 0, item = 0;
    qty.forEach((id, q) {
      final p = cari(id);
      if (q <= 0 || p == null) return;
      if (q > p.stok) {
        _log('Perlu dicek', '${p.nama}: terjual $q tetapi stok ${p.stok}. Cek stok fisik');
      }
      penjualan.add(Penjualan(hariIni, id, q, q * p.hargaJual));
      p.stok = max(0, p.stok - q);
      total += q * p.hargaJual;
      item += q;
    });
    if (item == 0) return 0;
    trx.add(Trx(
        id: idBaru('t'), tgl: DateTime.now(), masuk: true, kategori: 'Penjualan',
        ket: '$item barang', nominal: total));
    _log('Buku harian', 'Penjualan $item barang ${rp(total)} dicatat. Stok dan saldo diperbarui');
    jalankanRobot();
    return total;
  }

  void catatPengeluaran(int n, String kategori, String ket) {
    trx.add(Trx(
        id: idBaru('t'), tgl: DateTime.now(), masuk: false, kategori: kategori,
        ket: ket.isEmpty ? kategori : ket, nominal: n));
    _log('Buku harian', 'Pengeluaran ${rp(n)} ($kategori) dicatat');
    jalankanRobot();
  }

  void catatOmzet(int n) {
    trx.add(Trx(
        id: idBaru('t'), tgl: DateTime.now(), masuk: true, kategori: 'Omzet harian',
        ket: 'Omzet saja (stok tidak berubah)', nominal: n));
    _log('Buku harian', 'Omzet ${rp(n)} dicatat tanpa mengubah stok');
    jalankanRobot();
  }

  /// Tebakan kategori dari kata kunci (cadangan non-AI).
  static String? tebakKategori(String teks) {
    final s = teks.toLowerCase();
    const peta = {
      'Transportasi': ['bensin', 'ojek', 'parkir', 'tol', 'antar'],
      'Listrik & Air': ['listrik', 'token', 'pdam', 'air'],
      'Gaji / Upah': ['gaji', 'upah', 'bon'],
      'Kemasan': ['plastik', 'kardus', 'kantong', 'kemasan'],
      'Belanja Stok': ['kulakan', 'stok', 'beli barang'],
    };
    for (final e in peta.entries) {
      if (e.value.any(s.contains)) return e.key;
    }
    return null;
  }

  // ---------- produk dan supplier ----------
  void tambahProduk(Produk p) {
    produk.add(p);
    _log('Produk', '${p.nama} ditambahkan');
    notifyListeners();
  }

  /// true = dihapus, false = diarsipkan karena punya riwayat.
  bool hapusProduk(Produk p) {
    final punyaRiwayat = penjualan.any((s) => s.produkId == p.id) ||
        rekom.any((r) => r.produkId == p.id);
    if (punyaRiwayat) {
      p.aktif = false;
      _log('Produk', '${p.nama} diarsipkan (punya riwayat)');
      notifyListeners();
      return false;
    }
    produk.remove(p);
    _log('Produk', '${p.nama} dihapus');
    notifyListeners();
    return true;
  }

  void koreksiStok(Produk p, int n) {
    _log('Koreksi stok', '${p.nama}: ${p.stok} menjadi $n ${p.satuan}');
    p.stok = n;
    jalankanRobot();
  }

  void tambahSupplier(Supplier s) {
    supplier.add(s);
    notifyListeners();
  }

  void hapusSupplier(Supplier s) {
    for (final p in produk) {
      if (p.supplierId == s.id) p.supplierId = '';
    }
    supplier.remove(s);
    notifyListeners();
  }

  // ---------- scan ----------
  String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Produk? cocokkan(String nama) {
    final n = _norm(nama);
    if (n.isEmpty) return null;
    for (final p in produk) {
      if (!p.aktif) continue;
      final q = _norm(p.nama);
      if (q == n || q.contains(n) || n.contains(q)) return p;
    }
    return null;
  }

  String simpanScan(List<BarisScan> baris, {required bool penjualanMode}) {
    final jual = <String, int>{};
    var total = 0, item = 0;
    for (final b in baris) {
      if (b.qty <= 0 || b.nama.trim().isEmpty) continue;
      var p = b.produkId == null ? null : cari(b.produkId!);
      if (p == null) {
        p = Produk(
          id: idBaru('p'),
          nama: b.nama.trim(),
          hargaBeli: penjualanMode ? (b.harga * 0.8).round() : b.harga,
          hargaJual: penjualanMode ? b.harga : (b.harga * 1.15).round(),
          stok: 0,
        );
        produk.add(p);
      }
      if (penjualanMode) {
        jual[p.id] = (jual[p.id] ?? 0) + b.qty;
      } else {
        p.stok += b.qty;
        p.hargaBeli = b.harga;
        total += b.qty * b.harga;
        item += b.qty;
      }
    }
    if (penjualanMode) {
      final t = catatPenjualan(jual);
      return 'Penjualan hasil scan ${rp(t)} tersimpan';
    }
    if (item > 0) {
      trx.add(Trx(
          id: idBaru('t'), tgl: DateTime.now(), masuk: false, kategori: 'Belanja Stok',
          ket: 'Dari scan nota ($item barang)', nominal: total));
      _log('Scan nota', 'Belanja $item barang ${rp(total)} tersimpan, stok bertambah');
    }
    jalankanRobot();
    return 'Belanja ${rp(total)} tersimpan, stok bertambah';
  }

  // ---------- tabungan ----------
  Tujuan tambahTujuan({
    required String nama,
    required String emoji,
    required String jenis,
    required int target,
    DateTime? tenggat,
  }) {
    final t = Tujuan(
        id: idBaru('g'), nama: nama, emoji: emoji, jenis: jenis, target: target,
        mulai: hariIni, tenggat: tenggat);
    tujuan.add(t);
    _log('Tabungan', 'Tujuan "$nama" dibuat, target ${rp(target)}');
    notifyListeners();
    return t;
  }

  String? setor(Tujuan t, int n, String ket) {
    if (n <= 0) return 'Perlu dicek: nominal belum benar';
    final kas = kasTersedia < 0 ? 0 : kasTersedia;
    if (n > kas) return 'Melebihi kas tersedia (${rp(kas)})';
    t.setoran.add(Setoran(ket.isEmpty ? 'Setoran' : ket, n, DateTime.now()));
    _log('Tabungan', 'Setor ${rp(n)} ke ${t.nama}. Kas belanja berkurang ${rp(n)}');
    jalankanRobot();
    return null;
  }

  String? pakaiDana(Tujuan t, int n, String ket) {
    if (n <= 0) return 'Perlu dicek: nominal belum benar';
    if (n > t.terkumpul) return 'Melebihi dana terkumpul (${rp(t.terkumpul)})';
    final k = ket.isEmpty ? 'Dana dipakai' : ket;
    t.setoran.add(Setoran('Dipakai: $k', -n, DateTime.now()));
    trx.add(Trx(
        id: idBaru('t'), tgl: DateTime.now(), masuk: false, kategori: 'Dana: ${t.nama}',
        ket: k, nominal: n));
    _log('Tabungan', 'Dana ${t.nama} dipakai ${rp(n)} ($k), tercatat uang keluar');
    jalankanRobot();
    return null;
  }

  void hapusTujuan(Tujuan t) {
    tujuan.remove(t);
    _log('Tabungan', 'Tujuan "${t.nama}" dihapus. Dana kembali jadi kas biasa');
    jalankanRobot();
  }

  void hapusSetoran(Tujuan t, Setoran s) {
    t.setoran.remove(s);
    jalankanRobot();
  }
}