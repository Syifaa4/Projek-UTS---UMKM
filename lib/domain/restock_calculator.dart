enum RestockStatus {
  aman,            // belum perlu pesan
  perluRestock,    // sudah masuk titik pesan ulang
  jarangLaku,      // rata-rata jual 0
  dataBelumCukup,  // data < 3 hari
  tidakPerlu,      // jumlah pesan <= 0
}

class RestockInput {
  final double stokSekarang;
  final double totalJual7Hari;
  final int hariDataTersedia;
  final double penjualanHariIni;
  final int leadTimeHari;
  final int hariCadangan;
  final int hariCakupan;
  final int kelipatanPesan;
  final double hargaBeli;
  final double kasTersedia;
  final double ambangLonjakan;
  final int jendelaHari;

  const RestockInput({
    required this.stokSekarang,
    required this.totalJual7Hari,
    required this.hariDataTersedia,
    required this.penjualanHariIni,
    required this.leadTimeHari,
    required this.hariCadangan,
    required this.hariCakupan,
    required this.kelipatanPesan,
    required this.hargaBeli,
    required this.kasTersedia,
    this.ambangLonjakan = 3,
    this.jendelaHari = 7,
  });
}

class RestockResult {
  final RestockStatus status;
  final double rataJualHarian;
  final double? sisaHariStok;
  final int titikPesanUlang;
  final int jumlahUsulan;
  final double perkiraanBiaya;
  final bool kasKurang;
  final bool lonjakan;

  const RestockResult({
    required this.status,
    this.rataJualHarian = 0,
    this.sisaHariStok,
    this.titikPesanUlang = 0,
    this.jumlahUsulan = 0,
    this.perkiraanBiaya = 0,
    this.kasKurang = false,
    this.lonjakan = false,
  });

  bool get perluKartuKeputusan => status == RestockStatus.perluRestock;
}

class RestockCalculator {
  const RestockCalculator();

  RestockResult hitung(RestockInput i) {
    if (i.hariDataTersedia < 3) {
      return const RestockResult(status: RestockStatus.dataBelumCukup);
    }

    final rata = i.totalJual7Hari / i.jendelaHari;
    final titik = i.leadTimeHari + i.hariCadangan;

    if (rata <= 0) {
      return RestockResult(
        status: RestockStatus.jarangLaku,
        titikPesanUlang: titik,
      );
    }

    final sisaHari = i.stokSekarang / rata;

    if (sisaHari > titik) {
      return RestockResult(
        status: RestockStatus.aman,
        rataJualHarian: rata,
        sisaHariStok: sisaHari,
        titikPesanUlang: titik,
      );
    }

    final mentah = (rata * i.hariCakupan) - i.stokSekarang;
    if (mentah <= 0) {
      return RestockResult(
        status: RestockStatus.tidakPerlu,
        rataJualHarian: rata,
        sisaHariStok: sisaHari,
        titikPesanUlang: titik,
      );
    }

    final k = i.kelipatanPesan < 1 ? 1 : i.kelipatanPesan;
    final jumlah = (mentah / k).ceil() * k;
    final biaya = jumlah * i.hargaBeli;

    return RestockResult(
      status: RestockStatus.perluRestock,
      rataJualHarian: rata,
      sisaHariStok: sisaHari,
      titikPesanUlang: titik,
      jumlahUsulan: jumlah,
      perkiraanBiaya: biaya,
      kasKurang: biaya > i.kasTersedia,
      lonjakan: i.penjualanHariIni > i.ambangLonjakan * rata,
    );
  }
}